import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/error/unified_error_handler.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/utils/utils.dart';
import 'ecg_event.dart';
import 'ecg_state.dart';

/// ECG BLoC to manage ECG device connection and recording
class ECGBloc extends Bloc<ECGEvent, ECGState> {
  // Subscriptions and timers
  StreamSubscription<List<ScanResult>>? _scanSubscription;
  StreamSubscription<BluetoothConnectionState>? _connectionSubscription;
  StreamSubscription<List<int>>? _dataSubscription;
  Timer? _scanTimer;
  Timer? _countdownTimer;
  Timer? _recordingTimer;
  Timer? _reconnectionTimer;

  ECGBloc() : super(const ECGInitial()) {
    on<ECGInitialized>(_onECGInitialized);
    on<ECGScanStarted>(_onECGScanStarted);
    on<ECGScanStopped>(_onECGScanStopped);
    on<ECGDeviceConnected>(_onECGDeviceConnected);
    on<ECGDeviceDisconnected>(_onECGDeviceDisconnected);
    on<ECGRecordingStarted>(_onECGRecordingStarted);
    on<ECGRecordingStopped>(_onECGRecordingStopped);
    on<ECGDataReceived>(_onECGDataReceived);
    on<ECGCountdownTick>(_onECGCountdownTick);
    on<ECGRecordingTick>(_onECGRecordingTick);
    on<ECGErrorOccurred>(_onECGErrorOccurred);
    on<ECGDeviceDiscovered>(_onECGDeviceDiscovered);
  }

  Future<void> _onECGInitialized(
    ECGInitialized event,
    Emitter<ECGState> emit,
  ) async {
    LoggerService.debug('Initializing ECG...');
    
    emit(const ECGLoaded(
      connectionState: BluetoothStatus.disconnected,
      recordingState: ECGRecordingState.idle,
      discoveredDevices: [],
      statusMessage: 'Ready to scan for ECG devices',
      ecgData: [],
      duration: 30,
      countdown: 3,
      recordingTime: 0,
      currentHeartRate: 0.0,
      heartRateHistory: [],
      isScanning: false,
    ));
    
    LoggerService.info('ECG initialized successfully');
  }

  Future<void> _onECGScanStarted(
    ECGScanStarted event,
    Emitter<ECGState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ECGLoaded || currentState.isScanning) return;

    try {
      LoggerService.debug('Starting ECG device scan...');
      
      emit(currentState.copyWith(
        connectionState: BluetoothStatus.scanning,
        statusMessage: 'Scanning for ECG devices...',
        isScanning: true,
        discoveredDevices: [], // Clear previous discoveries
      ));

      // Check if Bluetooth is enabled
      if (!await FlutterBluePlus.isOn) {
        throw const ECGDeviceException(
          message: 'Bluetooth is disabled. Please enable Bluetooth.',
          code: 'bluetooth-disabled',
        );
      }

      // Start scanning for devices
      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 30),
        androidUsesFineLocation: false,
      );

      // Listen for scan results
      _scanSubscription = FlutterBluePlus.scanResults.listen(
        (results) {
          final ecgDevices = <BluetoothDevice>[];
          
          for (final result in results) {
            if (_isECGDevice(result.device)) {
              ecgDevices.add(result.device);
            }
          }
          
          if (ecgDevices.isNotEmpty) {
            add(ECGDeviceDiscovered(devices: ecgDevices));
          }
        },
        onError: (error) {
          LoggerService.error('Scan error', error);
          add(ECGErrorOccurred(error: 'Scan error: $error'));
        },
      );

      // Auto-stop scanning after timeout
      _scanTimer = Timer(const Duration(seconds: 30), () {
        add(const ECGScanStopped());
      });

    } catch (error, stackTrace) {
      LoggerService.error('Failed to start ECG scan', error, stackTrace);
      final failure = ErrorHandler.handleException(
        ECGDeviceException(message: 'Failed to start scanning'),
      );
      emit(ECGError(failure: failure, previousState: currentState));
    }
  }

  Future<void> _onECGScanStopped(
    ECGScanStopped event,
    Emitter<ECGState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ECGLoaded) return;

    try {
      LoggerService.debug('Stopping ECG scan...');
      
      await FlutterBluePlus.stopScan();
      _scanSubscription?.cancel();
      _scanTimer?.cancel();

      emit(currentState.copyWith(
        connectionState: BluetoothStatus.disconnected,
        statusMessage: currentState.discoveredDevices.isEmpty 
            ? 'No ECG devices found' 
            : 'Scan completed',
        isScanning: false,
      ));

    } catch (error, stackTrace) {
      LoggerService.error('Failed to stop ECG scan', error, stackTrace);
      // Don't emit error for scan stop failures, just log
    }
  }

  Future<void> _onECGDeviceConnected(
    ECGDeviceConnected event,
    Emitter<ECGState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ECGLoaded) return;

    try {
      LoggerService.debug('Connecting to ECG device: ${event.device.platformName}');
      
      emit(currentState.copyWith(
        connectionState: BluetoothStatus.connecting,
        statusMessage: 'Connecting to ${event.device.platformName}...',
      ));

      // Stop scanning first
      await FlutterBluePlus.stopScan();
      _scanSubscription?.cancel();

      // Connect to device with timeout
      await event.device.connect(timeout: const Duration(seconds: 15));

      // Listen for connection state changes
      _connectionSubscription = event.device.connectionState.listen(
        (state) {
          if (state == BluetoothConnectionState.disconnected) {
            add(const ECGDeviceDisconnected());
          }
        },
        onError: (error) {
          LoggerService.error('Connection state error', error);
          add(ECGErrorOccurred(error: 'Connection state error: $error'));
        },
      );

      // Setup ECG data stream
      await _setupECGDataStream(event.device);

      emit(currentState.copyWith(
        connectionState: BluetoothStatus.connected,
        connectedDevice: event.device,
        statusMessage: 'Connected to ${event.device.platformName}',
        isScanning: false,
      ));

      LoggerService.info('ECG device connected successfully');

    } catch (error, stackTrace) {
      LoggerService.error('Failed to connect to ECG device', error, stackTrace);
      final failure = ErrorHandler.handleException(
        ECGDeviceException(
          message: 'Failed to connect to ECG device',
          code: 'connection-failed',
        ),
      );
      emit(ECGError(failure: failure, previousState: currentState));
    }
  }

  Future<void> _onECGDeviceDisconnected(
    ECGDeviceDisconnected event,
    Emitter<ECGState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ECGLoaded) return;

    LoggerService.debug('ECG device disconnected');
    
    // Cancel subscriptions
    _dataSubscription?.cancel();
    _connectionSubscription?.cancel();

    // Stop any ongoing recording
    if (currentState.isRecording || currentState.isCountingDown) {
      _stopRecordingTimers();
    }

    emit(currentState.clearDevice());
    
    // Attempt reconnection if we were recording
    if (currentState.isRecording) {
      _attemptReconnection(currentState);
    }
  }

  Future<void> _onECGRecordingStarted(
    ECGRecordingStarted event,
    Emitter<ECGState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ECGLoaded || !currentState.canStartRecording) return;

    LoggerService.debug('Starting ECG recording...');
    
    final duration = event.customDuration?.clamp(10, 600) ?? currentState.duration;
    
    emit(currentState.copyWith(
      recordingState: ECGRecordingState.countdown,
      duration: duration,
      countdown: 3,
      ecgData: [], // Clear previous data
      heartRateHistory: [],
      statusMessage: 'Get ready... Recording starts in 3 seconds',
    ));

    // Start countdown timer
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      add(const ECGCountdownTick());
    });
  }

  Future<void> _onECGRecordingStopped(
    ECGRecordingStopped event,
    Emitter<ECGState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ECGLoaded) return;

    LoggerService.debug('Stopping ECG recording...');
    
    _stopRecordingTimers();

    if (currentState.recordingState == ECGRecordingState.recording) {
      emit(currentState.copyWith(
        recordingState: ECGRecordingState.processing,
        statusMessage: 'Processing ECG data...',
      ));

      // Simulate processing time
      await Future.delayed(const Duration(seconds: 1));

      emit(currentState.copyWith(
        recordingState: ECGRecordingState.completed,
        statusMessage: 'ECG recording completed',
      ));
    } else {
      emit(currentState.copyWith(
        recordingState: ECGRecordingState.idle,
        statusMessage: 'Recording cancelled',
      ));
    }
  }

  Future<void> _onECGDataReceived(
    ECGDataReceived event,
    Emitter<ECGState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ECGLoaded || !currentState.isRecording) return;

    final updatedEcgData = List<double>.from(currentState.ecgData)
      ..addAll(event.data);

    // Limit data points to prevent memory issues
    while (updatedEcgData.length > 5000) {
      updatedEcgData.removeAt(0);
    }

    // Calculate heart rate (simplified)
    final heartRate = _calculateHeartRate(updatedEcgData);
    final updatedHeartRateHistory = List<double>.from(currentState.heartRateHistory);
    
    if (heartRate > 0) {
      updatedHeartRateHistory.add(heartRate);
      while (updatedHeartRateHistory.length > 100) {
        updatedHeartRateHistory.removeAt(0);
      }
    }

    emit(currentState.copyWith(
      ecgData: updatedEcgData,
      currentHeartRate: heartRate,
      heartRateHistory: updatedHeartRateHistory,
    ));
  }

  Future<void> _onECGCountdownTick(
    ECGCountdownTick event,
    Emitter<ECGState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ECGLoaded || !currentState.isCountingDown) return;

    final newCountdown = currentState.countdown - 1;

    if (newCountdown <= 0) {
      _countdownTimer?.cancel();
      
      // Start actual recording
      emit(currentState.copyWith(
        recordingState: ECGRecordingState.recording,
        countdown: 0,
        recordingTime: currentState.duration,
        statusMessage: 'Recording ECG... ${currentState.duration}s remaining',
      ));

      // Start recording timer
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        add(const ECGRecordingTick());
      });
    } else {
      emit(currentState.copyWith(
        countdown: newCountdown,
        statusMessage: 'Get ready... Recording starts in ${newCountdown}s',
      ));
    }
  }

  Future<void> _onECGRecordingTick(
    ECGRecordingTick event,
    Emitter<ECGState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ECGLoaded || !currentState.isRecording) return;

    final newRecordingTime = currentState.recordingTime - 1;

    if (newRecordingTime <= 0) {
      add(const ECGRecordingStopped());
    } else {
      emit(currentState.copyWith(
        recordingTime: newRecordingTime,
        statusMessage: 'Recording ECG... ${newRecordingTime}s remaining',
      ));
    }
  }

  Future<void> _onECGErrorOccurred(
    ECGErrorOccurred event,
    Emitter<ECGState> emit,
  ) async {
    LoggerService.error('ECG error occurred', event.error);
    
    final currentState = state;
    final previousState = currentState is ECGLoaded ? currentState : null;
    
    final failure = ECGFailure(
      message: event.error,
      code: 'ecg-error',
    );
    
    emit(ECGError(failure: failure, previousState: previousState));
  }

  Future<void> _onECGDeviceDiscovered(
    ECGDeviceDiscovered event,
    Emitter<ECGState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ECGLoaded) return;

    // Merge new devices with existing ones, avoiding duplicates
    final allDevices = <BluetoothDevice>{...currentState.discoveredDevices, ...event.devices}.toList();
    
    emit(currentState.copyWith(
      discoveredDevices: allDevices,
      statusMessage: '${allDevices.length} ECG device(s) found',
    ));
  }

  /// Helper methods

  bool _isECGDevice(BluetoothDevice device) {
    final name = device.platformName.toLowerCase();
    const ecgKeywords = ['b869h', 'v5.0', 'hm-10', 'hm10', 'ecg', 'heart', 'bioamp'];
    return ecgKeywords.any((keyword) => name.contains(keyword));
  }

  Future<void> _setupECGDataStream(BluetoothDevice device) async {
    try {
      LoggerService.debug('Setting up ECG data stream...');
      
      final services = await device.discoverServices();
      BluetoothCharacteristic? targetCharacteristic;

      // Find a characteristic that can notify (for receiving ECG data)
      for (final service in services) {
        for (final characteristic in service.characteristics) {
          if (characteristic.properties.notify || characteristic.properties.indicate) {
            // Skip standard system characteristics
            final charUuid = characteristic.uuid.toString().toLowerCase();
            if (charUuid.contains('2a05') || charUuid.contains('2a00') || 
                charUuid.contains('2a01') || charUuid.contains('2a04')) {
              continue;
            }
            
            targetCharacteristic = characteristic;
            break;
          }
        }
        if (targetCharacteristic != null) break;
      }

      if (targetCharacteristic == null) {
        throw const ECGDeviceException(
          message: 'No suitable ECG characteristic found',
          code: 'no-ecg-characteristic',
        );
      }

      // Enable notifications
      await targetCharacteristic.setNotifyValue(true);

      // Listen for ECG data
      _dataSubscription = targetCharacteristic.lastValueStream.listen(
        (data) => _processRawECGData(data),
        onError: (error) {
          LoggerService.error('ECG data stream error', error);
          add(ECGErrorOccurred(error: 'Data stream error: $error'));
        },
      );

      LoggerService.info('ECG data stream setup completed');
    } catch (error, stackTrace) {
      LoggerService.error('Failed to setup ECG data stream', error, stackTrace);
      throw ECGDeviceException(message: 'Failed to setup data stream: $error');
    }
  }

  void _processRawECGData(List<int> rawData) {
    try {
      final ecgValues = <double>[];
      
      // Convert raw bytes to ECG values
      final stringData = String.fromCharCodes(rawData);
      final lines = stringData.split('\n');
      
      for (final line in lines) {
        final trimmed = line.trim();
        if (trimmed.isEmpty) continue;
        
        // Try to parse as double
        final value = double.tryParse(trimmed);
        if (value != null) {
          ecgValues.add(value);
        } else {
          // Try to parse as integer and convert
          final intValue = int.tryParse(trimmed);
          if (intValue != null) {
            // Convert to signed if needed
            var signedValue = intValue;
            if (signedValue > 32767) signedValue -= 65536;
            
            // Scale to voltage (assuming 3.3V reference)
            final ecgValue = signedValue / 32767.0 * 3.3;
            ecgValues.add(ecgValue);
          }
        }
      }
      
      if (ecgValues.isNotEmpty) {
        add(ECGDataReceived(data: ecgValues));
      }
    } catch (error) {
      LoggerService.warning('ECG data processing error', error);
    }
  }

  double _calculateHeartRate(List<double> ecgData) {
    if (ecgData.length < 20) return 0.0;
    
    // Simple heart rate calculation based on peak detection
    final recentData = ecgData.length > 100 ? ecgData.sublist(ecgData.length - 100) : ecgData;
    final average = recentData.reduce((a, b) => a + b) / recentData.length;
    
    int peakCount = 0;
    for (int i = 1; i < recentData.length - 1; i++) {
      if (recentData[i] > average * 1.2 && 
          recentData[i] > recentData[i - 1] && 
          recentData[i] > recentData[i + 1]) {
        peakCount++;
      }
    }
    
    if (peakCount > 0) {
      // Estimate heart rate based on peak count and sampling rate
      final timeSpan = recentData.length / 100.0; // Assuming 100 Hz sampling
      final heartRate = (peakCount / timeSpan) * 60.0;
      return heartRate.clamp(40.0, 200.0);
    }
    
    return 0.0;
  }

  void _stopRecordingTimers() {
    _countdownTimer?.cancel();
    _recordingTimer?.cancel();
  }

  void _attemptReconnection(ECGLoaded previousState) {
    if (previousState.discoveredDevices.isNotEmpty) {
      LoggerService.info('Attempting ECG device reconnection...');
      _reconnectionTimer = Timer(const Duration(seconds: 5), () {
        final lastDevice = previousState.discoveredDevices.first;
        add(ECGDeviceConnected(device: lastDevice));
      });
    }
  }

  @override
  Future<void> close() {
    _scanSubscription?.cancel();
    _connectionSubscription?.cancel();
    _dataSubscription?.cancel();
    _scanTimer?.cancel();
    _countdownTimer?.cancel();
    _recordingTimer?.cancel();
    _reconnectionTimer?.cancel();
    return super.close();
  }
}