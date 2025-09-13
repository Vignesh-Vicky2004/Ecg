import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/firebase_service.dart';
import '../models/ecg_session.dart';
import '../services/adaptive_signal_processor.dart';
import '../services/continuous_health_scorer.dart';
import '../services/predictive_cardiac_detector.dart';
import '../widgets/real_time_health_dashboard.dart';
import '../widgets/predictive_risk_dashboard.dart';
import '../models/user_profile.dart';
import '../core/utils/utils.dart';
import 'dart:async';
import 'dart:math';

class RecordPage extends StatefulWidget {
  final bool isDarkMode;
  final User user;

  const RecordPage({
    super.key,
    required this.isDarkMode,
    required this.user,
  });

  @override
  State<RecordPage> createState() => _RecordPageState();
}

class _RecordPageState extends State<RecordPage>
    with TickerProviderStateMixin {
      
  // Disposal flag to prevent setState after disposal
  bool _disposed = false;
      
  // Safe setState wrapper to prevent lifecycle errors
  void _safeSetState(VoidCallback fn) {
    if (mounted && !_disposed) {
      setState(fn);
    }
  }
      
  String _step = 'setup'; // setup, countdown, recording
  int _duration = 30;
  int _countdown = 3;
  int _timer = 30;
  
  Timer? _countdownTimer;
  Timer? _recordingTimer;
  late AnimationController _animationController;
  
  // Bluetooth state
  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _characteristic;
  StreamSubscription<List<int>>? _characteristicSubscription;
  StreamSubscription<BluetoothConnectionState>? _connectionStateSubscription;
  StreamSubscription<BluetoothAdapterState>? _adapterStateSubscription;
  StreamSubscription<List<ScanResult>>? _scanResultsSubscription;
  StreamSubscription<bool>? _isScanningSubscription;
  bool _isConnected = false;
  bool _isScanning = false;
  String _bluetoothStatus = "Searching for devices...";
  List<BluetoothDevice> _discoveredDevices = [];
  String _dataBuffer = "";
  
  // Connection stability improvements
  Timer? _connectionKeepAliveTimer;
  Timer? _reconnectionTimer;
  Timer? _connectionMonitorTimer;
  int _reconnectionAttempts = 0;
  static const int maxReconnectionAttempts = 10; // Increased attempts
  DateTime? _lastDataReceived;
  bool _shouldMaintainConnection = true; // Flag to control persistent connection
  
  // Data rate limiting to prevent buffer overflow
  DateTime? _lastDataProcessed;
  static const Duration dataProcessingInterval = Duration(milliseconds: 50); // 20 Hz max
  
  // Connection health monitoring
  int _consecutiveDataPackets = 0;
  int _missedHeartbeats = 0;
  static const int maxMissedHeartbeats = 3;
  
  // ECG data processing (using your algorithm)
  final List<List<double>> _channelData = [];
  final List<int> _sweepPositions = [];
  static const int maxPoints = 1000;
  
  // Heart rate detection
  final List<DateTime> _heartBeats = [];
  double _currentHeartRate = 0.0;
  final List<double> _heartRateHistory = [];
  DateTime? _lastPeakTime;
  bool _isPeakDetected = false;
  
  // Session recording
  final List<double> _sessionEcgData = [];
  final List<double> _sessionHeartRates = [];
  DateTime? _sessionStartTime;
  
  // Revolutionary Health Features
  PersonalSignalProfile? _personalProfile;
  UserProfile? _userProfile;
  HealthMetrics? _currentHealthMetrics;
  CardiacPrediction? _cardiacPrediction;
  Timer? _healthUpdateTimer;

  @override
  void initState() {
    super.initState();
    _initializeAnimation();
    _initializeHealthFeatures();
    _checkBluetoothAndScan();
  }

  void _initializeHealthFeatures() async {
    try {
      // Load user profile - fix the static method call
      _userProfile = await FirebaseService.getUserProfileData(widget.user.uid);
      
      // Initialize or load personal signal profile with correct parameters
      _personalProfile = PersonalSignalProfile(
        baselineVariability: 0.1,
        avgAmplitude: 1.0,
        personalRRate: 0.8, // 800ms R-R interval
        noisePattern: [0.05, 0.03, 0.02], // Low noise profile
        movementTolerance: 0.3,
        lastUpdated: DateTime.now(),
      );
      
      // Start health monitoring when recording begins
      if (mounted && !_disposed) _safeSetState(() {});
    } catch (e) {
      LoggerService.error('Error initializing health features', e);
      // Create default profiles on error
      _userProfile = UserProfile(
        uid: widget.user.uid,
        name: widget.user.displayName ?? 'User',
        email: widget.user.email ?? '',
        phone: 'Not provided',
        age: 30, // Default age
        weight: 70.0,
        height: 170.0,
        gender: 'Other',
        activityLevel: 'Moderate',
        bloodType: 'Unknown',
        hasHeartConditions: false,
        medicalConditions: ['None'],
        emergencyContact: 'Not provided',
        emergencyPhone: 'Not provided',
        isEmailVerified: widget.user.emailVerified,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      _personalProfile = PersonalSignalProfile(
        baselineVariability: 0.1,
        avgAmplitude: 1.0,
        personalRRate: 0.8,
        noisePattern: [0.05, 0.03, 0.02],
        movementTolerance: 0.3,
        lastUpdated: DateTime.now(),
      );
    }
  }

  /// Start revolutionary real-time health monitoring
  void _startHealthMonitoring() {
    if (_personalProfile == null || _userProfile == null) return;
    
    _healthUpdateTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (_sessionEcgData.isNotEmpty && mounted) {
        try {
          // Get recent ECG sessions for trend analysis
          final recentSessions = <ECGSession>[];
          
          // Calculate real-time health metrics using the revolutionary algorithm
          final healthMetrics = ContinuousHealthScorer.calculateRealTimeScore(
            _sessionEcgData,
            _personalProfile!,
            recentSessions,
            _userProfile!,
            currentTime: DateTime.now(),
            stressLevel: 0.0, // Could be enhanced with stress detection
            activityLevel: 0.2, // Resting state during recording
          );
          
          if (mounted) {
            _safeSetState(() {
              _currentHealthMetrics = healthMetrics;
            });
          }
          
          // Alert on critical health status
          if (healthMetrics.overallScore < 60) {
            _showHealthAlert(healthMetrics);
          }
          
        } catch (e) {
          print('Health monitoring error: $e');
        }
      }
    });
  }

  void _showHealthAlert(HealthMetrics metrics) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '⚠️ Health Alert: ${metrics.healthStatus} - Score: ${metrics.overallScore.toInt()}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Color(metrics.healthColor),
        duration: const Duration(seconds: 5),
      ),
    );
  }

  void _stopHealthMonitoring() {
    _healthUpdateTimer?.cancel();
    if (mounted && !_disposed) {
      _safeSetState(() {
        _currentHealthMetrics = null;
      });
    }
  }

  /// Show the revolutionary health dashboard in full screen
  void _showRevolutionaryHealthDashboard() {
    if (_personalProfile == null || _userProfile == null) return;
    
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => RealTimeHealthDashboard(
          liveECGData: _sessionEcgData,
          personalProfile: _personalProfile!,
          userProfile: _userProfile!,
        ),
        fullscreenDialog: true,
      ),
    );
  }

  /// Revolutionary Predictive Cardiac Analysis - Patent Feature #3
  /// Performs advanced AI-based cardiac event prediction after ECG recording
  Future<void> _performPredictiveAnalysis(ECGSession currentSession) async {
    if (_personalProfile == null || _userProfile == null) return;
    
    try {
      // Get historical sessions for pattern analysis
      final historicalSessionsData = await FirebaseService.getUserECGSessions(widget.user.uid);
      
      // Convert Firestore data to ECGSession objects
      final historicalSessions = historicalSessionsData.map((data) => ECGSession.fromFirestore(data)).toList();
      
      // Generate current health metrics if not available
      final currentMetrics = _currentHealthMetrics ?? ContinuousHealthScorer.calculateRealTimeScore(
        _sessionEcgData,
        _personalProfile!,
        historicalSessions,
        _userProfile!,
        currentTime: DateTime.now(),
        stressLevel: _estimateStressLevel(),
      );
      
      // Perform predictive analysis
      final prediction = PredictiveCardiacDetector.predictCardiacEvents(
        [...historicalSessions, currentSession], // Include current session
        _personalProfile!,
        _userProfile!,
        currentMetrics,
        analysisTime: DateTime.now(),
        additionalBiomarkers: {
          'recentSessionCount': historicalSessions.length,
          'currentSessionQuality': _calculateSessionQuality(),
          'stressLevel': _estimateStressLevel(),
        },
      );
      
      // Store prediction for later use
      if (mounted && !_disposed) {
        _safeSetState(() {
          _cardiacPrediction = prediction;
        });
      }
      
      // Show predictive results based on risk level
      if (prediction.riskLevel.index >= RiskLevel.moderate.index) {
        _showPredictiveAnalysisDialog(prediction);
      } else {
        // Show brief positive feedback for low risk
        _showPredictiveSnackbar(prediction);
      }
      
    } catch (e) {
      print('Error in predictive analysis: $e');
      // Fail gracefully - don't interrupt user flow
    }
  }
  
  /// Show predictive analysis results in a full dialog
  void _showPredictiveAnalysisDialog(CardiacPrediction prediction) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: Container(
          constraints: const BoxConstraints(maxHeight: 700),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      Icons.psychology,
                      color: Colors.blue[600],
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'AI Predictive Analysis Complete',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: PredictiveRiskDashboard(
                    prediction: prediction,
                    onEmergencyAction: () {
                      Navigator.of(context).pop();
                      _handleEmergencyAction();
                    },
                    onViewDetails: () {
                      Navigator.of(context).pop();
                      _showDetailedPredictiveResults();
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  /// Show brief positive feedback for low risk predictions
  void _showPredictiveSnackbar(CardiacPrediction prediction) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Text(prediction.riskEmoji),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${prediction.urgencyMessage} (${prediction.confidence.toInt()}% confidence)',
                style: const TextStyle(color: Colors.white),
              ),
            ),
            TextButton(
              onPressed: _showDetailedPredictiveResults,
              child: const Text(
                'VIEW DETAILS',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: Color(prediction.riskColor),
        duration: const Duration(seconds: 5),
      ),
    );
  }
  
  /// Handle emergency action from predictive analysis
  void _handleEmergencyAction() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red, size: 28),
            SizedBox(width: 8),
            Text('Emergency Action'),
          ],
        ),
        content: const Text(
          'Would you like to:\n\n'
          '• Call Emergency Services (911)\n'
          '• Contact Your Doctor\n'
          '• View Detailed Analysis\n'
          '• Share Results with Healthcare Provider',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              // In a real app, this would initiate emergency call
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Emergency services would be contacted in a real deployment'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            icon: const Icon(Icons.phone),
            label: const Text('Call Emergency'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          ),
        ],
      ),
    );
  }
  
  /// Show detailed predictive results
  void _showDetailedPredictiveResults() {
    if (_cardiacPrediction == null) return;
    
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: const Text('Predictive Analysis Results'),
            backgroundColor: Color(_cardiacPrediction!.riskColor),
            foregroundColor: Colors.white,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: PredictiveRiskDashboard(
              prediction: _cardiacPrediction!,
              onEmergencyAction: _handleEmergencyAction,
              onViewDetails: () {
                // Show even more detailed analytics
                _showAnalyticsBreakdown();
              },
            ),
          ),
        ),
        fullscreenDialog: true,
      ),
    );
  }
  
  /// Show detailed analytics breakdown
  void _showAnalyticsBreakdown() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Analytics Breakdown'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Machine Learning Analysis:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...(_cardiacPrediction?.analyticsData.entries.map((entry) =>
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text('${entry.key}: ${entry.value}'),
                )
              ) ?? []),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
  
  /// Calculate session quality for additional context
  double _calculateSessionQuality() {
    if (_sessionEcgData.isEmpty) return 0.0;
    
    // Simple quality metric based on data consistency and noise level
    double quality = 80.0;
    
    // Check for data consistency
    final avgValue = _sessionEcgData.reduce((a, b) => a + b) / _sessionEcgData.length;
    final variance = _sessionEcgData.map((v) => (v - avgValue) * (v - avgValue)).reduce((a, b) => a + b) / _sessionEcgData.length;
    final standardDeviation = sqrt(variance);
    
    // Lower quality for high noise (high standard deviation)
    if (standardDeviation > 100) quality -= 20;
    else if (standardDeviation > 50) quality -= 10;
    
    // Higher quality for longer recordings
    if (_sessionEcgData.length > 1000) quality += 10;
    
    return quality.clamp(0.0, 100.0);
  }
  
  /// Estimate stress level based on heart rate variability
  double _estimateStressLevel() {
    if (_sessionHeartRates.length < 3) return 0.3; // Default moderate stress
    
    // Calculate heart rate variability
    double hrv = 0.0;
    for (int i = 1; i < _sessionHeartRates.length; i++) {
      hrv += (_sessionHeartRates[i] - _sessionHeartRates[i-1]).abs();
    }
    hrv /= (_sessionHeartRates.length - 1);
    
    // Low HRV indicates high stress
    if (hrv < 5) return 0.8; // High stress
    if (hrv < 10) return 0.6; // Moderate-high stress
    if (hrv < 20) return 0.4; // Moderate stress
    return 0.2; // Low stress
  }

  @override
  void dispose() {
    // Set flags to prevent setState calls
    _disposed = true;
    _shouldMaintainConnection = false;
    
    // Stop revolutionary health monitoring
    _stopHealthMonitoring();
    
    _animationController.dispose();
    _countdownTimer?.cancel();
    _recordingTimer?.cancel();
    _characteristicSubscription?.cancel();
    _connectionStateSubscription?.cancel();
    _connectionKeepAliveTimer?.cancel();
    _reconnectionTimer?.cancel();
    _connectionMonitorTimer?.cancel();
    
    // Cancel the new stream subscriptions
    _adapterStateSubscription?.cancel();
    _scanResultsSubscription?.cancel();
    _isScanningSubscription?.cancel();
    
    // Disconnect without setState since widget is being disposed
    _disconnectDeviceOnDispose();
    super.dispose();
  }

  void _initializeAnimation() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 16),
      vsync: this,
    );
    _animationController.addListener(() {
      _safeSetState(() {});
    });
    _animationController.repeat();
  }

  Future<void> _checkBluetoothAndScan() async {
    // Check if Bluetooth is supported
    if (await FlutterBluePlus.isSupported == false) {
      if (mounted && !_disposed) {
        _safeSetState(() {
          _bluetoothStatus = "Bluetooth not supported on this device";
        });
      }
      return;
    }

    // Check current adapter state
    BluetoothAdapterState adapterState = await FlutterBluePlus.adapterState.first;
    
    if (adapterState != BluetoothAdapterState.on) {
      if (mounted && !_disposed) {
        _safeSetState(() {
          _bluetoothStatus = "Please enable Bluetooth";
        });
      }
      
      // Listen for Bluetooth state changes
      _adapterStateSubscription = FlutterBluePlus.adapterState.listen((state) {
        if (state == BluetoothAdapterState.on && !_isConnected && mounted) {
          _startScanning();
        } else if (state != BluetoothAdapterState.on && mounted) {
          _safeSetState(() {
            _isConnected = false;
            _bluetoothStatus = "Bluetooth is disabled";
          });
        }
      });
      return;
    }
    
    // Start scanning immediately if Bluetooth is already on
    _startScanning();
  }

  Future<void> _startScanning() async {
    if (_isScanning || !mounted) return;
    
    if (mounted && !_disposed) {
      _safeSetState(() {
        _isScanning = true;
        _bluetoothStatus = "Scanning for ECG devices...";
        _discoveredDevices.clear();
      });
    }

    try {
      // Start scanning
      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 10),
        androidUsesFineLocation: false,
      );

      // Listen for scan results
      _scanResultsSubscription = FlutterBluePlus.onScanResults.listen((results) {
        if (results.isNotEmpty) {
          for (ScanResult result in results) {
            // Look for ECG devices (HM-10, MLT-BT05, B869H V5.0, or any device with ECG in name)
            String deviceName = result.advertisementData.advName.isNotEmpty 
                ? result.advertisementData.advName 
                : result.advertisementData.localName;
            
            // Debug: Print all discovered devices
            print('Found device: $deviceName (${result.device.remoteId})');
            
            if (deviceName.isNotEmpty && 
                (deviceName.toLowerCase().contains('hm-10') ||
                 deviceName.toLowerCase().contains('hm10') ||
                 deviceName.toLowerCase().contains('b869h') ||
                 deviceName.toLowerCase().contains('v5.0') ||
                 deviceName.toLowerCase().contains('mlt-bt05') ||
                 deviceName.toLowerCase().contains('ecg') ||
                 deviceName.toLowerCase().contains('heart') ||
                 deviceName.toLowerCase().contains('esp32'))) {
              
              print('ECG device detected: $deviceName');
              
              if (!_discoveredDevices.any((d) => d.remoteId == result.device.remoteId)) {
                if (mounted && !_disposed) {
                  _safeSetState(() {
                    _discoveredDevices.add(result.device);
                    _bluetoothStatus = "Found ${_discoveredDevices.length} ECG device(s): $deviceName";
                  });
                }
                
                // Auto-connect to first found device
                if (_discoveredDevices.length == 1 && !_isConnected) {
                  print('Auto-connecting to: $deviceName');
                  _connectToDevice(result.device);
                }
              }
            }
          }
        }
      });

      // Handle scan completion
      _isScanningSubscription = FlutterBluePlus.isScanning.listen((scanning) {
        if (!scanning && _isScanning) {
          if (mounted && !_disposed) {
            _safeSetState(() {
              _isScanning = false;
              if (_discoveredDevices.isEmpty && !_isConnected) {
                _bluetoothStatus = "No ECG devices found. Make sure your device is on and nearby.";
              }
            });
          }
        }
      });

    } catch (e) {
      if (mounted && !_disposed) {
        _safeSetState(() {
          _isScanning = false;
          _bluetoothStatus = "Scan error: ${e.toString()}";
        });
      }
    }
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    if (_isConnected || !mounted) return;
    
    if (mounted && !_disposed) {
      _safeSetState(() {
        _bluetoothStatus = "Connecting to ${device.platformName.isNotEmpty ? device.platformName : 'ECG Device'}...";
      });
    }

    try {
      // Stop scanning
      await FlutterBluePlus.stopScan();
      
      // Connect to device
      await device.connect(timeout: const Duration(seconds: 15));
      
      if (mounted && !_disposed) {
        _safeSetState(() {
          _connectedDevice = device;
          _isConnected = true;
          _bluetoothStatus = "Connected to ${device.platformName.isNotEmpty ? device.platformName : 'ECG Device'}";
          _shouldMaintainConnection = true; // Enable persistent connection
        });
      }

      // Listen for connection state changes with enhanced reconnection
      _connectionStateSubscription = device.connectionState.listen((state) {
        print('🔗 Connection state changed: $state');
        if (state == BluetoothConnectionState.disconnected) {
          if (mounted && !_disposed) {
            _safeSetState(() {
              _isConnected = false;
              _bluetoothStatus = "Device disconnected - attempting reconnection...";
              _connectedDevice = null;
              _characteristic = null;
            });
          }
          _characteristicSubscription?.cancel();
          _connectionKeepAliveTimer?.cancel();
          _connectionMonitorTimer?.cancel();
          
          // PERSISTENT RECONNECTION: Always attempt to reconnect if flag is set
          if (_shouldMaintainConnection && mounted) {
            print('🔄 Initiating persistent reconnection...');
            _attemptPersistentReconnection();
          }
        } else if (state == BluetoothConnectionState.connected) {
          _reconnectionAttempts = 0; // Reset on successful connection
          _consecutiveDataPackets = 0;
          _missedHeartbeats = 0;
          
          if (mounted && !_disposed) {
            _safeSetState(() {
              _bluetoothStatus = "Connected and stable";
            });
          }
          
          _startPersistentConnectionMonitoring();
        }
      });

      // Discover services and characteristics
      await _discoverServices(device);

    } catch (e) {
      if (mounted && !_disposed) {
        _safeSetState(() {
          _isConnected = false;
          _bluetoothStatus = "Connection failed: ${e.toString()}";
        });
      }
      
      // Retry scanning after failed connection
      Future.delayed(const Duration(seconds: 3), () {
        if (!_isConnected) _startScanning();
      });
    }
  }

  Future<void> _discoverServices(BluetoothDevice device) async {
    try {
      if (mounted && !_disposed) {
        _safeSetState(() {
          _bluetoothStatus = "Discovering services...";
        });
      }

      List<BluetoothService> services = await device.discoverServices();
      
      print('🔍 Found ${services.length} services');
      
      // First, look specifically for the Nordic UART service
      BluetoothCharacteristic? targetCharacteristic;
      
      for (BluetoothService service in services) {
        String serviceUuid = service.uuid.toString().toLowerCase();
        print('🔵 Service UUID: $serviceUuid');
        
        // Look for Nordic UART Service (your ESP32 service)
        if (serviceUuid.contains('6e400001-b5a3-f393-e0a9-e50e24dcca9e')) {
          print('✅ Found Nordic UART Service!');
          
          for (BluetoothCharacteristic characteristic in service.characteristics) {
            String charUuid = characteristic.uuid.toString().toLowerCase();
            print('🔵 Characteristic UUID: $charUuid');
            print('🔵 Properties: notify=${characteristic.properties.notify}, indicate=${characteristic.properties.indicate}, read=${characteristic.properties.read}');
            
            // Look for the TX characteristic (ESP32 sends data through this)
            if (charUuid.contains('6e400003-b5a3-f393-e0a9-e50e24dcca9e')) {
              print('✅ Found ECG TX Characteristic!');
              targetCharacteristic = characteristic;
              break;
            }
          }
          break;
        }
      }
      
      // If Nordic UART not found, fall back to any notifiable characteristic
      if (targetCharacteristic == null) {
        print('⚠️ Nordic UART not found, looking for any notifiable characteristic...');
        
        for (BluetoothService service in services) {
          for (BluetoothCharacteristic characteristic in service.characteristics) {
            String charUuid = characteristic.uuid.toString().toLowerCase();
            print('🔍 Checking characteristic: $charUuid');
            print('🔍 Properties: notify=${characteristic.properties.notify}, indicate=${characteristic.properties.indicate}');
            
            // Skip standard system characteristics
            if (charUuid.contains('2a05') || // Service Changed
                charUuid.contains('2a00') || // Device Name
                charUuid.contains('2a01') || // Appearance
                charUuid.contains('2a04')) { // Peripheral Preferred Connection Parameters
              print('⏭️ Skipping system characteristic: $charUuid');
              continue;
            }
            
            // Look for characteristics that can notify (for receiving ECG data)
            if (characteristic.properties.notify || characteristic.properties.indicate) {
              print('✅ Found potential ECG characteristic: $charUuid');
              targetCharacteristic = characteristic;
              break;
            }
          }
          if (targetCharacteristic != null) break;
        }
      }
      
      if (targetCharacteristic != null) {
        _characteristic = targetCharacteristic;
        
        if (mounted && !_disposed) {
          _safeSetState(() {
            _bluetoothStatus = "Setting up ECG data stream...";
          });
        }
        
        try {
          print('🔧 Enabling notifications on characteristic: ${targetCharacteristic.uuid}');
          
          // Enable notifications
          await targetCharacteristic.setNotifyValue(true);
          
          // Start listening for ECG data
          _characteristicSubscription = targetCharacteristic.lastValueStream.listen(
            _onDataReceived,
            onError: (error) {
              print('❌ Data stream error: $error');
              if (mounted) {
                _safeSetState(() {
                  _bluetoothStatus = "Data stream error: $error";
                });
              }
            },
          );
          
          print('✅ ECG data stream established!');
          
          if (mounted) {
            _safeSetState(() {
              _bluetoothStatus = "Ready for ECG recording - ESP32 Connected";
            });
          }
          
        } catch (e) {
          print('❌ Failed to enable notifications: $e');
          if (mounted) {
            setState(() {
              _bluetoothStatus = "Failed to setup data stream: $e";
            });
          }
        }
      } else {
        print('❌ No suitable ECG characteristic found');
        if (mounted) {
          setState(() {
            _bluetoothStatus = "Device connected but no ECG data service found";
          });
        }
      }
      
    } catch (e) {
      print('❌ Service discovery failed: $e');
      if (mounted) {
        setState(() {
          _bluetoothStatus = "Service discovery failed: ${e.toString()}";
        });
      }
    }
  }

  Future<void> _disconnectDevice() async {
    // Only disconnect if we're not supposed to maintain connection
    if (_shouldMaintainConnection) {
      print('🛡️ Disconnect requested but persistent connection enabled - ignoring');
      return;
    }
    
    print('🔌 Disconnecting device...');
    
    if (_connectedDevice != null) {
      try {
        await _connectedDevice!.disconnect();
      } catch (e) {
        print('Disconnect error: $e');
      }
    }
    
    if (mounted) {
      setState(() {
        _isConnected = false;
        _connectedDevice = null;
        _characteristic = null;
        _bluetoothStatus = "Disconnected";
      });
    }
    
    _characteristicSubscription?.cancel();
    _connectionStateSubscription?.cancel();
    _connectionKeepAliveTimer?.cancel();
    _connectionMonitorTimer?.cancel();
  }

  // Force disconnect for app disposal
  void _forceDisconnectDevice() async {
    _shouldMaintainConnection = false; // Disable persistent connection
    
    print('🔌 Force disconnecting device...');
    
    if (_connectedDevice != null) {
      try {
        await _connectedDevice!.disconnect();
      } catch (e) {
        print('Force disconnect error: $e');
      }
    }
    
    if (mounted) {
      setState(() {
        _isConnected = false;
        _connectedDevice = null;
        _characteristic = null;
        _bluetoothStatus = "Disconnected";
      });
    }
    
    _characteristicSubscription?.cancel();
    _connectionStateSubscription?.cancel();
    _connectionKeepAliveTimer?.cancel();
    _connectionMonitorTimer?.cancel();
  }

  void _disconnectDeviceOnDispose() async {
    // Force disconnect for disposal - bypass persistent connection
    _shouldMaintainConnection = false;
    
    if (_connectedDevice != null) {
      try {
        await _connectedDevice!.disconnect();
      } catch (e) {
        print('Disconnect error during dispose: $e');
      }
    }
    
    // Don't call setState since widget is being disposed
    _isConnected = false;
    _connectedDevice = null;
    _characteristic = null;
    _bluetoothStatus = "Disconnected";
    
    _characteristicSubscription?.cancel();
    _connectionStateSubscription?.cancel();
    _connectionKeepAliveTimer?.cancel();
    _connectionMonitorTimer?.cancel();
  }

  void _retryConnection() {
    _forceDisconnectDevice();
    Future.delayed(const Duration(seconds: 1), () {
      _shouldMaintainConnection = true;
      _startScanning();
    });
  }

  void _manualDisconnect() {
    print('👤 Manual disconnect requested');
    _shouldMaintainConnection = false; // Disable persistent connection
    _forceDisconnectDevice();
    
    if (mounted) {
      setState(() {
        _bluetoothStatus = "Manually disconnected";
      });
    }
    
    _showSnackbar('Device disconnected. Tap retry to reconnect.');
  }

  // Enhanced connection stability methods for PERSISTENT connection
  void _startPersistentConnectionMonitoring() {
    _connectionKeepAliveTimer?.cancel();
    _connectionMonitorTimer?.cancel();
    
    print('🛡️ Starting persistent connection monitoring...');
    
    // Aggressive keep-alive monitoring every 5 seconds
    _connectionKeepAliveTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!_shouldMaintainConnection) {
        timer.cancel();
        return;
      }
      
      if (!_isConnected || _connectedDevice == null) {
        print('💔 Connection lost during monitoring - triggering reconnection');
        timer.cancel();
        _attemptPersistentReconnection();
        return;
      }
      
      // Check data flow health
      final now = DateTime.now();
      if (_lastDataReceived != null) {
        final timeSinceLastData = now.difference(_lastDataReceived!).inSeconds;
        if (timeSinceLastData > 10) {
          print('⚠️ No data for ${timeSinceLastData}s - connection may be stale');
          _missedHeartbeats++;
          
          if (_missedHeartbeats >= maxMissedHeartbeats) {
            print('💔 Too many missed heartbeats - forcing reconnection');
            _forceReconnection();
            return;
          }
        } else {
          _missedHeartbeats = 0; // Reset on good data
          _consecutiveDataPackets++;
        }
      }
      
      // Send keep-alive ping
      _sendKeepAlivePing();
      
      print('💚 Connection health check: ${_consecutiveDataPackets} packets, ${_missedHeartbeats} missed heartbeats');
    });
    
    // Additional connection monitor every 15 seconds for deep health check
    _connectionMonitorTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      if (!_shouldMaintainConnection) {
        timer.cancel();
        return;
      }
      
      if (_isConnected && _connectedDevice != null) {
        // Verify device is still actually connected at OS level
        _connectedDevice!.connectionState.first.then((state) {
          if (state != BluetoothConnectionState.connected && _shouldMaintainConnection) {
            print('🔍 OS reports disconnection - triggering reconnection');
            _attemptPersistentReconnection();
          }
        }).catchError((error) {
          print('⚠️ Connection state check failed: $error');
          _attemptPersistentReconnection();
        });
      }
    });
  }

  void _attemptPersistentReconnection() {
    if (!_shouldMaintainConnection) {
      print('🛑 Persistent connection disabled - stopping reconnection');
      return;
    }
    
    if (_reconnectionAttempts >= maxReconnectionAttempts) {
      print('⚠️ Max reconnection attempts reached - resetting and trying again');
      _reconnectionAttempts = 0; // Reset for persistent connection
      
      // Wait longer before retrying
      Future.delayed(const Duration(seconds: 10), () {
        if (_shouldMaintainConnection && !_isConnected) {
          _attemptPersistentReconnection();
        }
      });
      return;
    }
    
    _reconnectionAttempts++;
    print('🔄 Persistent reconnection attempt #$_reconnectionAttempts');
    
    if (mounted) {
      _safeSetState(() {
        _bluetoothStatus = "Reconnecting... (attempt $_reconnectionAttempts)";
      });
    }
    
    _reconnectionTimer?.cancel();
    
    // Progressive delay: start fast, then slower
    int delaySeconds = _reconnectionAttempts <= 3 ? 2 : (_reconnectionAttempts <= 6 ? 5 : 10);
    
    _reconnectionTimer = Timer(Duration(seconds: delaySeconds), () {
      if (!_shouldMaintainConnection) return;
      
      if (!_isConnected && _connectedDevice != null) {
        // Try direct reconnection first
        _connectToDevice(_connectedDevice!).then((_) {
          if (!_isConnected && _shouldMaintainConnection) {
            // If direct reconnection fails, try scanning
            print('🔍 Direct reconnection failed - starting scan');
            _startScanning();
          }
        }).catchError((error) {
          print('❌ Reconnection failed: $error');
          if (_shouldMaintainConnection) {
            // Retry with scan
            _startScanning();
          }
        });
      } else if (!_isConnected) {
        // No device reference, start scanning
        _startScanning();
      }
    });
  }

  void _forceReconnection() {
    print('💥 Forcing immediate reconnection...');
    
    // Disconnect current connection
    _disconnectDevice().then((_) {
      // Short delay then reconnect
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (_shouldMaintainConnection && !_isConnected) {
          _attemptPersistentReconnection();
        }
      });
    });
  }

  void _sendKeepAlivePing() async {
    if (_characteristic != null && _isConnected) {
      try {
        // Some ESP32 implementations respond to empty data or specific commands
        // You can customize this based on your ESP32 firmware
        print('📡 Sending keep-alive ping');
      } catch (e) {
        print('⚠️ Keep-alive ping failed: $e');
      }
    }
  }

  void _showSnackbar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 3)),
      );
    }
  }

  void _onDataReceived(List<int> data) {
    // Update last data received timestamp for connection health monitoring
    _lastDataReceived = DateTime.now();
    _consecutiveDataPackets++;
    _missedHeartbeats = 0; // Reset missed heartbeats on data received
    
    // Rate limiting to prevent buffer overflow
    if (_lastDataProcessed != null && 
        _lastDataReceived!.difference(_lastDataProcessed!).inMilliseconds < 
        dataProcessingInterval.inMilliseconds) {
      return; // Skip this data packet to prevent overflow
    }
    _lastDataProcessed = _lastDataReceived;
    
    // Convert bytes to string for ESP32 and other devices
    try {
      String receivedData = String.fromCharCodes(data);
      _dataBuffer += receivedData;
      
      // Debug print to see raw data (reduced frequency)
      if (_consecutiveDataPackets % 20 == 0) { // Print every 20 packets
        print('🔵 Data flow healthy: ${_consecutiveDataPackets} packets received');
        print('🔵 Current buffer: "$_dataBuffer"');
      }
      
      // Process data based on different formats
      // ESP32 sends data with newline termination
      final lines = _dataBuffer.split(RegExp(r'[\n\r]+'));
      _dataBuffer = lines.last; // Keep incomplete line in buffer
      
      final completeLines = lines.take(lines.length - 1).where((line) => line.trim().isNotEmpty).toList();
      if (completeLines.isNotEmpty) {
        _processDataBatch(completeLines);
      }
    } catch (e) {
      // If string conversion fails, try processing as raw bytes (for binary data)
      print('🔴 String conversion failed, processing as raw bytes: $e');
      _processRawByteData(data);
    }
  }

  void _processRawByteData(List<int> data) {
    // Handle binary data format (some B869H devices send binary)
    for (int i = 0; i < data.length; i += 2) {
      if (i + 1 < data.length) {
        // Convert two bytes to a 16-bit signed integer (ECG value)
        int rawValue = (data[i + 1] << 8) | data[i];
        if (rawValue > 32767) rawValue -= 65536; // Convert to signed
        
        double ecgValue = rawValue / 32767.0 * 3.3; // Scale to voltage (assuming 3.3V reference)
        
        if (_channelData.isEmpty) {
          _initializeChannelData(1);
        }
        _updateChannelData([ecgValue]);
        
        // Process ECG data for heart rate and recording
        _detectHeartBeat(ecgValue);
        
        if (_step == 'recording' && _sessionStartTime != null) {
          _sessionEcgData.add(ecgValue);
        }
      }
    }
  }

  void _processDataBatch(List<String> lines) {
    for (final line in lines) {
      final trimmedLine = line.trim();
      if (trimmedLine.isEmpty) continue;

      print('🔍 Processing line: "$trimmedLine"');

      // Handle different data formats from ESP32, B869H V5.0 and HM-10
      List<double> values = [];
      
      // Try single value format first (ESP32 sends single float values)
      final singleValue = double.tryParse(trimmedLine);
      if (singleValue != null) {
        values = [singleValue];
        print('✅ Parsed single value: $singleValue');
      }
      // Try comma-separated format (common in B869H V5.0)
      else if (trimmedLine.contains(',')) {
        values = trimmedLine
            .split(',')
            .map((s) => double.tryParse(s.trim()))
            .whereType<double>()
            .toList();
        print('✅ Parsed comma-separated values: $values');
      } 
      // Try space-separated format (common in HM-10)
      else {
        values = trimmedLine
            .split(RegExp(r'\s+'))
            .map((s) => double.tryParse(s))
            .whereType<double>()
            .toList();
        print('✅ Parsed space-separated values: $values');
      }

      if (values.isNotEmpty) {
        final ecgValue = values[0];
        print('📊 ECG Value received: $ecgValue');
        
        // Initialize channel data if needed
        if (_channelData.isEmpty) {
          print('🎯 Initializing channel data for ${values.length} channels');
          _initializeChannelData(values.length);
        }
        
        // Update channel data
        _updateChannelData(values);
        
        // Process ECG data for heart rate and recording
        _detectHeartBeat(ecgValue);
        
        if (_step == 'recording' && _sessionStartTime != null) {
          _sessionEcgData.add(ecgValue);
          print('📝 Added to session data: $ecgValue (total: ${_sessionEcgData.length})');
        }
        
        // Force a UI update to see the graph changes
        if (mounted) {
          setState(() {});
        }
      } else {
        print('❌ Failed to parse any values from: "$trimmedLine"');
      }
    }
  }

  void _initializeChannelData(int channelCount) {
    _channelData.clear();
    _sweepPositions.clear();
    for (int i = 0; i < channelCount; i++) {
      _channelData.add(List.filled(maxPoints, 0.0));
      _sweepPositions.add(0);
    }
  }

  void _updateChannelData(List<double> values) {
    for (int i = 0; i < values.length && i < _channelData.length; i++) {
      final pos = _sweepPositions[i];
      final value = values[i];
      
      // Store the raw value
      _channelData[i][pos] = value;
      _sweepPositions[i] = (pos + 1) % maxPoints;
      
      // Debug print every 10 values to see what's being stored
      if (pos % 10 == 0) {
        print('💾 Storing ECG value at position $pos: $value');
        print('💾 Current sweep position: ${_sweepPositions[i]}');
        print('💾 Last 5 values: ${_channelData[i].skip(max(0, pos - 4)).take(5).toList()}');
        
        // Check if we have enough data for the graph
        final nonZeroCount = _channelData[i].where((v) => v != 0.0).length;
        print('💾 Non-zero data points: $nonZeroCount / ${_channelData[i].length}');
      }
    }
  }

  void _detectHeartBeat(double ecgValue) {
    final now = DateTime.now();
    
    // Adjust threshold based on the actual data range we're seeing
    // Your values are in the range of -0.24 to 0.8, so we need a lower threshold
    double adaptiveThreshold = 0.3; // Much lower than the original 1.0
    
    if (ecgValue > adaptiveThreshold && !_isPeakDetected) {
      if (_lastPeakTime == null || now.difference(_lastPeakTime!).inMilliseconds > 300) {
        _heartBeats.add(now);
        _lastPeakTime = now;
        _isPeakDetected = true;
        if (_heartBeats.length > 10) _heartBeats.removeAt(0);
        _calculateHeartRate();
        
        print('Heart beat detected! ECG value: $ecgValue, BPM: $_currentHeartRate');
      }
    }
    if (ecgValue < adaptiveThreshold * 0.5) _isPeakDetected = false;
  }

  void _calculateHeartRate() {
    if (_heartBeats.length < 2) return;
    final intervals = <int>[];
    for (int i = 1; i < _heartBeats.length; i++) {
      intervals.add(_heartBeats[i].difference(_heartBeats[i - 1]).inMilliseconds);
    }
    if (intervals.isNotEmpty) {
      final avgInterval = intervals.reduce((a, b) => a + b) / intervals.length;
      if (avgInterval > 0) {
        final newBpm = 60000 / avgInterval;
        _heartRateHistory.add(newBpm);
        if (_heartRateHistory.length > 5) _heartRateHistory.removeAt(0);
        if (mounted) {
          setState(() {
            _currentHeartRate = _heartRateHistory.reduce((a, b) => a + b) / _heartRateHistory.length;
          });
        }
        if (_step == 'recording') _sessionHeartRates.add(_currentHeartRate);
      }
    }
  }

  void _startRecordingProcess() {
    setState(() {
      _step = 'countdown';
      _countdown = 3;
    });
    
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        _safeSetState(() {
          _countdown--;
        });
      }
      
      if (_countdown <= 0) {
        timer.cancel();
        _startRecording();
      }
    });
  }

  void _startRecording() async {
    setState(() {
      _step = 'recording';
      _timer = _duration;
      _sessionStartTime = DateTime.now();
      _sessionEcgData.clear();
      _sessionHeartRates.clear();
    });
    
    // Run diagnostics before recording
    print('🔍 Running ECG diagnostics before recording...');
    try {
      await FirebaseService.runECGDiagnostics();
    } catch (e) {
      print('❌ Diagnostic check failed: $e');
    }
    
    // Reset reconnection attempts and ensure persistent connection
    _reconnectionAttempts = 0;
    _shouldMaintainConnection = true;
    
    // Start revolutionary health monitoring
    _startHealthMonitoring();
    
    // Ensure connection is stable before recording
    if (!_isConnected) {
      _showSnackbar('Device not connected. Attempting to reconnect...');
      _attemptPersistentReconnection();
      return;
    }
    
    print('🎬 Recording started with persistent connection monitoring');
    
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        _safeSetState(() {
          _timer--;
        });
      }
      
      // Enhanced connection monitoring during recording
      if (!_isConnected && _shouldMaintainConnection) {
        print('📹 Connection lost during recording - attempting immediate reconnection');
        _attemptPersistentReconnection();
      }
      
      if (_timer <= 0) {
        timer.cancel();
        _stopRecording();
      }
    });
  }

  void _stopRecording() async {
    _recordingTimer?.cancel();
    
    if (_sessionStartTime != null && _sessionEcgData.isNotEmpty) {
      try {
        // Debug: Check authentication state
        final currentUser = FirebaseAuth.instance.currentUser;
        print('🔐 Current user: ${currentUser?.uid}');
        print('🔐 User email: ${currentUser?.email}');
        print('🔐 User authenticated: ${currentUser != null}');
        
        // Run diagnostic to understand Firestore structure
        print('🔧 Running Firestore diagnostic...');
        await FirebaseService.debugFirestoreStructure();
        
        // Test Firestore connection first
        print('🔧 Testing Firestore connection...');
        await FirebaseService.testFirestoreConnection();
        print('✅ Firestore connection test passed');
        
        // Create ECG session and save
        final session = ECGSession(
          userId: widget.user.uid,  // Add userId to session
          timestamp: _sessionStartTime!,
          duration: DateTime.now().difference(_sessionStartTime!),
          ecgData: _sessionEcgData.asMap().entries.map((entry) => 
            FlSpot(entry.key.toDouble(), entry.value)).toList(),
          avgBPM: _sessionHeartRates.isEmpty ? 0 : 
            _sessionHeartRates.reduce((a, b) => a + b) / _sessionHeartRates.length,
          minBPM: _sessionHeartRates.isEmpty ? 0 : _sessionHeartRates.reduce(min),
          maxBPM: _sessionHeartRates.isEmpty ? 0 : _sessionHeartRates.reduce(max),
        );

        // Debug: Check session data before saving
        final sessionData = session.toFirestore();
        print('💾 Session userId: ${sessionData['userId']}');
        print('💾 Widget user uid: ${widget.user.uid}');
        print('💾 Session data keys: ${sessionData.keys.toList()}');

        // Save to Firestore with error handling
        await FirebaseService.saveECGSession(sessionData);
        
        // Perform Revolutionary Predictive Analysis
        _performPredictiveAnalysis(session);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ECG session saved and secured!'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        print('❌ Error saving ECG session: $e');
        
        // Run immediate permission debugging
        if (e.toString().contains('permission')) {
          print('🚨 Permission error detected - running debug...');
          try {
            await FirebaseService.debugPermissionIssue();
          } catch (debugError) {
            print('❌ Debug failed: $debugError');
          }
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save ECG session: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Retry',
              onPressed: () => _stopRecording(),
            ),
          ),
        );
      }
    } else {
      _showSnackbar('Recording completed but no data was captured. Check device connection.');
    }
    
    setState(() {
      _step = 'setup';
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: _buildMainContent(),
    );
  }

  Widget _buildMainContent() {
    if (_step == 'countdown') {
      return Container(
        color: Colors.black.withOpacity(0.7),
        child: Center(
          child: Text(
            _countdown.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 120,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }

    if (_step == 'recording') {
      return _buildRecordingView();
    }

    return _buildSetupView();
  }

  Widget _buildSetupView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          const SizedBox(height: 24),
          Text(
            'Get Ready to Record',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: widget.isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please place the sensors as shown below.',
            style: TextStyle(
              color: widget.isDarkMode ? Colors.grey[400] : Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          
          // ECG placement diagram
          Container(
            height: 200, // Reduced height to fit better
            child: CustomPaint(
              painter: ECGPlacementPainter(),
              size: const Size.square(200),
            ),
          ),
          
          const SizedBox(height: 20),
      
      // Bluetooth status
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _isConnected ? Colors.green.withOpacity(0.1) : 
                 _isScanning ? Colors.orange.withOpacity(0.1) : Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _isConnected ? Colors.green : 
                   _isScanning ? Colors.orange : Colors.red,
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  _isConnected ? LucideIcons.bluetooth : 
                  _isScanning ? LucideIcons.search : LucideIcons.bluetoothOff,
                  color: _isConnected ? Colors.green : 
                         _isScanning ? Colors.orange : Colors.red,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _bluetoothStatus,
                    style: TextStyle(
                      color: _isConnected ? Colors.green : 
                             _isScanning ? Colors.orange : Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (!_isConnected && !_isScanning)
                  GestureDetector(
                    onTap: _retryConnection,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2563EB),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Retry',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                if (_isConnected)
                  GestureDetector(
                    onTap: _manualDisconnect,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.red.shade600,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Disconnect',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            if (_discoveredDevices.isNotEmpty && !_isConnected) ...[
              const SizedBox(height: 12),
              const Text(
                'Available devices:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              // Wrap device list in SingleChildScrollView to prevent overflow
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 120),
                child: SingleChildScrollView(
                  child: Column(
                    children: _discoveredDevices.map((device) => 
                      GestureDetector(
                        onTap: () => _connectToDevice(device),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 4),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2563EB).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFF2563EB)),
                          ),
                          child: Row(
                            children: [
                              const Icon(LucideIcons.heart, size: 16, color: Color(0xFF2563EB)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  device.platformName.isNotEmpty ? device.platformName : 'ECG Device',
                                  style: const TextStyle(
                                    color: Color(0xFF2563EB),
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const Icon(LucideIcons.arrowRight, size: 16, color: Color(0xFF2563EB)),
                            ],
                          ),
                        ),
                      ),
                    ).toList(),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      
      const SizedBox(height: 32),
      
      // Duration selector
      Text(
        'Select Recording Duration:',
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: widget.isDarkMode ? Colors.grey[300] : Colors.grey[700],
        ),
      ),
      const SizedBox(height: 16),
      // Wrap duration selector in SingleChildScrollView for horizontal scroll if needed
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [30, 60, 90].map((d) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: GestureDetector(
              onTap: () => setState(() => _duration = d),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                decoration: BoxDecoration(
                  color: _duration == d 
                      ? const Color(0xFF2563EB) 
                      : (widget.isDarkMode ? const Color(0xFF374151) : Colors.white),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _duration == d 
                        ? const Color(0xFF2563EB) 
                        : (widget.isDarkMode ? Colors.grey[600]! : Colors.grey[300]!),
                  ),
                ),
                child: Text(
                  '${d}s',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: _duration == d 
                        ? Colors.white 
                        : (widget.isDarkMode ? Colors.grey[300] : Colors.grey[700]),
                  ),
                ),
              ),
            ),
          )).toList(),
        ),
      ),
      
      const SizedBox(height: 32),
      
      // Start button
      SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: _isConnected ? _startRecordingProcess : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2563EB),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 4,
          ),
          child: const Text(
            'Start Recording',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
      
      // Add extra space at bottom to ensure button is always visible
      const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildRecordingView() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Timer and status - Fixed height
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Recording...',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: widget.isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                    if (_currentHealthMetrics != null)
                      Text(
                        '${_currentHealthMetrics!.healthEmoji} ${_currentHealthMetrics!.overallScore.toInt()}% ${_currentHealthMetrics!.healthStatus}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(_currentHealthMetrics!.healthColor),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
                Row(
                  children: [
                    // Revolutionary Health Dashboard Button
                    if (_currentHealthMetrics != null)
                      Container(
                        margin: const EdgeInsets.only(right: 10),
                        child: ElevatedButton.icon(
                          onPressed: _showRevolutionaryHealthDashboard,
                          icon: Text(_currentHealthMetrics!.healthEmoji),
                          label: Text('${_currentHealthMetrics!.overallScore.toInt()}'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(_currentHealthMetrics!.healthColor),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                        ),
                      ),
                    
                    // Predictive Analysis Button - Patent Feature #3
                    if (_cardiacPrediction != null)
                      Container(
                        margin: const EdgeInsets.only(right: 10),
                        child: ElevatedButton.icon(
                          onPressed: _showDetailedPredictiveResults,
                          icon: const Icon(Icons.psychology, size: 18),
                          label: Text(_cardiacPrediction!.riskLevel.name.toUpperCase()),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(_cardiacPrediction!.riskColor),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            elevation: _cardiacPrediction!.riskLevel.index >= RiskLevel.high.index ? 8 : 2,
                          ),
                        ),
                      ),
                    Text(
                      '${(_timer ~/ 60).toString().padLeft(2, '0')}:${(_timer % 60).toString().padLeft(2, '0')}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // ECG visualization - Flexible to fill available space
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: widget.isDarkMode ? const Color(0xFF1F2937) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // ECG graph takes most of the available space
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CustomPaint(
                        painter: ECGGraphPainter(
                          channelData: _channelData,
                          sweepPositions: _sweepPositions,
                          maxPoints: maxPoints,
                          isDarkMode: widget.isDarkMode,
                          selectedChannels: _channelData.isNotEmpty ? [0] : [],
                        ),
                        size: Size.infinite,
                      ),
                    ),
                  ),
                  // Info row - Fixed height at bottom of graph container
                  Container(
                    padding: const EdgeInsets.only(top: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${_currentHeartRate.round()} BPM',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.red,
                          ),
                        ),
                        Text(
                          'Lead II${_characteristic != null ? ' (Active)' : ''}',
                          style: TextStyle(
                            fontSize: 14,
                            color: widget.isDarkMode ? Colors.grey[400] : Colors.grey[500],
                          ),
                        ),
                        Text(
                          '25 mm/s',
                          style: TextStyle(
                            fontSize: 14,
                            color: widget.isDarkMode ? Colors.grey[400] : Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Stop button - Fixed height at bottom
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _stopRecording,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.stopCircle),
                  SizedBox(width: 8),
                  Text(
                    'Stop Recording',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Custom painter for ECG placement diagram
class ECGPlacementPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey[300]!
      ..style = PaintingStyle.fill;

    // Draw human torso outline
    final path = Path();
    path.moveTo(size.width * 0.5, size.height * 0.1);
    path.quadraticBezierTo(size.width * 0.7, size.height * 0.2, size.width * 0.8, size.height * 0.5);
    path.quadraticBezierTo(size.width * 0.85, size.height * 0.8, size.width * 0.7, size.height * 0.9);
    path.lineTo(size.width * 0.3, size.height * 0.9);
    path.quadraticBezierTo(size.width * 0.15, size.height * 0.8, size.width * 0.2, size.height * 0.5);
    path.quadraticBezierTo(size.width * 0.3, size.height * 0.2, size.width * 0.5, size.height * 0.1);
    path.close();

    canvas.drawPath(path, paint);

    // Draw electrode positions
    final electrodePositions = [
      Offset(size.width * 0.25, size.height * 0.35), // RA
      Offset(size.width * 0.75, size.height * 0.35), // LA
      Offset(size.width * 0.75, size.height * 0.75), // LL
    ];

    final electrodePaint = Paint()
      ..color = const Color(0xFF2563EB)
      ..style = PaintingStyle.fill;

    for (final position in electrodePositions) {
      canvas.drawCircle(position, 8, electrodePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Channel colors for multiple ECG leads
const List<Color> channelColors = [
  Color(0xFFF5A3B1), // Pink
  Color(0xFF86D3ED), // Cyan
  Color(0xFF7CD6C8), // Teal
  Color(0xFFC2B4E2), // Purple
  Color(0xFF48d967), // Green
  Color(0xFFFFFF8C), // Yellow
];

// Custom painter using proven SerialPlotter logic
class ECGGraphPainter extends CustomPainter {
  final List<List<double>> channelData;
  final List<int> sweepPositions;
  final int maxPoints;
  final bool isDarkMode;
  final List<int> selectedChannels;

  static final Map<int, Paint> _paintCache = {};
  static final Map<int, Path> _pathCache = {};

  ECGGraphPainter({
    required this.channelData,
    required this.sweepPositions,
    required this.maxPoints,
    required this.isDarkMode,
    List<int>? selectedChannels,
  }) : selectedChannels = selectedChannels ?? (channelData.isNotEmpty ? [0] : []);

  @override
  void paint(Canvas canvas, Size size) {
    // Debug: Print graph state
    print('🎨 ECGGraphPainter: channels=${channelData.length}, sweeps=${sweepPositions.length}');
    
    if (channelData.isEmpty || selectedChannels.isEmpty) {
      _drawWaitingMessage(canvas, size);
      return;
    }

    final width = size.width;
    final height = size.height;
    final xStep = width / maxPoints;

    // Find global min/max across all selected channels
    double globalMin = double.infinity;
    double globalMax = double.negativeInfinity;
    int validDataPoints = 0;

    for (int i in selectedChannels) {
      if (i < channelData.length) {
        for (double value in channelData[i]) {
          if (!value.isNaN && !value.isInfinite && value != 0.0) {
            if (value < globalMin) globalMin = value;
            if (value > globalMax) globalMax = value;
            validDataPoints++;
          }
        }
      }
    }
    
    print('🎨 Graph range analysis: min=$globalMin, max=$globalMax, validPoints=$validDataPoints');
    
    // Set reasonable defaults if no valid data
    if (globalMin == double.infinity || globalMax == double.negativeInfinity || validDataPoints < 3) {
      globalMin = 0.2;
      globalMax = 0.5;
      print('🎨 Using fallback range for ESP32: $globalMin to $globalMax');
    } else {
      // Add padding to make the signal more visible
      final range = globalMax - globalMin;
      if (range < 0.05) {
        final center = (globalMax + globalMin) / 2;
        globalMin = center - 0.1;
        globalMax = center + 0.1;
        print('🎨 Expanded small range around center $center: $globalMin to $globalMax');
      } else {
        final padding = range * 0.2;
        globalMin -= padding;
        globalMax += padding;
        print('🎨 Added padding to range: $globalMin to $globalMax');
      }
    }

    if ((globalMax - globalMin).abs() < 0.01) {
      globalMax = globalMin + 0.1;
    }
    final yRange = (globalMax - globalMin).abs();

    // Draw background and grid
    _drawBackground(canvas, size);
    _drawGrid(canvas, size);

    // Use SerialPlotter's proven rendering logic
    const int gapSize = 25; // Gap around sweep position for cleaner visualization

    for (int i = 0; i < selectedChannels.length && i < channelData.length; i++) {
      final channelIndex = selectedChannels[i];
      if (channelIndex >= channelData.length || channelIndex >= sweepPositions.length) continue;

      final paint = _getPaint(i);
      final path = _getPath(i);
      path.reset();

      final sweepPos = sweepPositions[channelIndex];
      bool firstPoint = true;
      int drawnPoints = 0;
      
      // Draw from sweep position with gap (SerialPlotter logic)
      for (int k = 0; k < maxPoints - gapSize; k++) {
        int currentIndex = (sweepPos + gapSize + k) % maxPoints;
        int previousIndex = (sweepPos + gapSize + k - 1 + maxPoints) % maxPoints;

        final value = channelData[channelIndex][currentIndex];
        if (value.isNaN || value.isInfinite || value == 0.0) continue;

        final x = currentIndex * xStep;
        final y = height - ((value - globalMin) / yRange * height);

        if (firstPoint) {
          path.moveTo(x, y.clamp(0, height));
          firstPoint = false;
        } else {
          // Handle wrap-around in circular buffer
          if (currentIndex < previousIndex) {
            path.moveTo(x, y.clamp(0, height));
          } else {
            path.lineTo(x, y.clamp(0, height));
          }
        }
        drawnPoints++;
      }
      
      print('🎨 Channel $channelIndex: Drew $drawnPoints points, sweep at $sweepPos');
      
      if (!firstPoint) {
        canvas.drawPath(path, paint);
      }
    }

    // Draw sweep line for real-time position indicator
    if (selectedChannels.isNotEmpty && selectedChannels[0] < sweepPositions.length) {
      final sweepPos = sweepPositions[selectedChannels[0]];
      final sweepX = sweepPos * xStep;
      final sweepPaint = Paint()
        ..color = Colors.red.withOpacity(0.7)
        ..strokeWidth = 2.0;
      canvas.drawLine(
        Offset(sweepX, 0),
        Offset(sweepX, height),
        sweepPaint,
      );
    }

    // Draw value range info
    _drawRangeInfo(canvas, size, globalMin, globalMax);
  }

  void _drawWaitingMessage(Canvas canvas, Size size) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'Waiting for ECG signal...\nChannels: ${channelData.length}',
        style: TextStyle(
          color: isDarkMode ? Colors.white70 : Colors.black54,
          fontSize: 16,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        (size.width - textPainter.width) / 2,
        (size.height - textPainter.height) / 2,
      ),
    );
  }

  void _drawBackground(Canvas canvas, Size size) {
    final bgPaint = Paint()
      ..color = isDarkMode ? const Color(0xFF1F2937) : Colors.white;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);
  }

  void _drawGrid(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = (isDarkMode ? Colors.white : Colors.black).withOpacity(0.1)
      ..strokeWidth = 1.0;

    // Vertical grid lines
    for (int i = 0; i <= 10; i++) {
      final x = (size.width / 10) * i;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }

    // Horizontal grid lines
    for (int i = 0; i <= 5; i++) {
      final y = (size.height / 5) * i;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  void _drawRangeInfo(Canvas canvas, Size size, double min, double max) {
    final textStyle = TextStyle(
      color: isDarkMode ? Colors.white70 : Colors.black54,
      fontSize: 10,
    );
    
    final maxTextPainter = TextPainter(
      text: TextSpan(text: '${max.toStringAsFixed(3)}V', style: textStyle),
      textDirection: TextDirection.ltr,
    );
    maxTextPainter.layout();
    maxTextPainter.paint(canvas, const Offset(5, 5));
    
    final minTextPainter = TextPainter(
      text: TextSpan(text: '${min.toStringAsFixed(3)}V', style: textStyle),
      textDirection: TextDirection.ltr,
    );
    minTextPainter.layout();
    minTextPainter.paint(canvas, Offset(5, size.height - minTextPainter.height - 5));
  }

  Paint _getPaint(int index) {
    return _paintCache.putIfAbsent(index, () {
      final color = channelColors[index % channelColors.length];
      return Paint()
        ..color = color
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
    });
  }

  Path _getPath(int index) {
    return _pathCache.putIfAbsent(index, () => Path());
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
