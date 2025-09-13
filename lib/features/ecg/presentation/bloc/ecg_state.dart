import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../../../../core/bloc/base_bloc.dart';
import '../../../../core/errors/failures.dart';
import 'ecg_event.dart';

/// ECG states
abstract class ECGState extends AppState {
  const ECGState();
}

class ECGInitial extends ECGState {
  const ECGInitial();
}

class ECGLoaded extends ECGState {
  final BluetoothStatus connectionState;
  final ECGRecordingState recordingState;
  final BluetoothDevice? connectedDevice;
  final List<BluetoothDevice> discoveredDevices;
  final String statusMessage;
  final List<double> ecgData;
  final int duration;
  final int countdown;
  final int recordingTime;
  final double currentHeartRate;
  final List<double> heartRateHistory;
  final bool isScanning;

  const ECGLoaded({
    required this.connectionState,
    required this.recordingState,
    this.connectedDevice,
    required this.discoveredDevices,
    required this.statusMessage,
    required this.ecgData,
    required this.duration,
    required this.countdown,
    required this.recordingTime,
    required this.currentHeartRate,
    required this.heartRateHistory,
    required this.isScanning,
  });

  @override
  List<Object?> get props => [
        connectionState,
        recordingState,
        connectedDevice,
        discoveredDevices,
        statusMessage,
        ecgData,
        duration,
        countdown,
        recordingTime,
        currentHeartRate,
        heartRateHistory,
        isScanning,
      ];

  ECGLoaded copyWith({
    BluetoothStatus? connectionState,
    ECGRecordingState? recordingState,
    BluetoothDevice? connectedDevice,
    List<BluetoothDevice>? discoveredDevices,
    String? statusMessage,
    List<double>? ecgData,
    int? duration,
    int? countdown,
    int? recordingTime,
    double? currentHeartRate,
    List<double>? heartRateHistory,
    bool? isScanning,
  }) {
    return ECGLoaded(
      connectionState: connectionState ?? this.connectionState,
      recordingState: recordingState ?? this.recordingState,
      connectedDevice: connectedDevice ?? this.connectedDevice,
      discoveredDevices: discoveredDevices ?? this.discoveredDevices,
      statusMessage: statusMessage ?? this.statusMessage,
      ecgData: ecgData ?? this.ecgData,
      duration: duration ?? this.duration,
      countdown: countdown ?? this.countdown,
      recordingTime: recordingTime ?? this.recordingTime,
      currentHeartRate: currentHeartRate ?? this.currentHeartRate,
      heartRateHistory: heartRateHistory ?? this.heartRateHistory,
      isScanning: isScanning ?? this.isScanning,
    );
  }

  /// Clear connected device (for disconnection)
  ECGLoaded clearDevice() {
    return copyWith(
      connectedDevice: null,
      connectionState: BluetoothStatus.disconnected,
      statusMessage: 'Disconnected',
    );
  }

  /// Convenience getters
  bool get isConnected => connectionState == BluetoothStatus.connected;
  bool get isRecording => recordingState == ECGRecordingState.recording;
  bool get isCountingDown => recordingState == ECGRecordingState.countdown;
  bool get isProcessing => recordingState == ECGRecordingState.processing;
  bool get isCompleted => recordingState == ECGRecordingState.completed;
  bool get canStartRecording => isConnected && recordingState == ECGRecordingState.idle;
}

class ECGError extends ECGState {
  final Failure failure;
  final ECGLoaded? previousState;

  const ECGError({
    required this.failure,
    this.previousState,
  });

  @override
  List<Object?> get props => [failure, previousState];
}