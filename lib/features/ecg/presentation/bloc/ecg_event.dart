import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../../../../core/bloc/base_bloc.dart';

/// ECG Recording States
enum ECGRecordingState {
  idle,
  countdown,
  recording,
  processing,
  completed,
}

/// Bluetooth Connection States
enum BluetoothStatus {
  disconnected,
  scanning,
  connecting,
  connected,
  error,
}

/// ECG events
abstract class ECGEvent extends AppEvent {
  const ECGEvent();
}

class ECGInitialized extends ECGEvent {
  const ECGInitialized();
}

class ECGScanStarted extends ECGEvent {
  const ECGScanStarted();
}

class ECGScanStopped extends ECGEvent {
  const ECGScanStopped();
}

class ECGDeviceConnected extends ECGEvent {
  final BluetoothDevice device;

  const ECGDeviceConnected({required this.device});

  @override
  List<Object?> get props => [device];
}

class ECGDeviceDisconnected extends ECGEvent {
  const ECGDeviceDisconnected();
}

class ECGRecordingStarted extends ECGEvent {
  final int? customDuration;

  const ECGRecordingStarted({this.customDuration});

  @override
  List<Object?> get props => [customDuration];
}

class ECGRecordingStopped extends ECGEvent {
  const ECGRecordingStopped();
}

class ECGDataReceived extends ECGEvent {
  final List<double> data;

  const ECGDataReceived({required this.data});

  @override
  List<Object?> get props => [data];
}

class ECGCountdownTick extends ECGEvent {
  const ECGCountdownTick();
}

class ECGRecordingTick extends ECGEvent {
  const ECGRecordingTick();
}

class ECGErrorOccurred extends ECGEvent {
  final String error;

  const ECGErrorOccurred({required this.error});

  @override
  List<Object?> get props => [error];
}

class ECGDeviceDiscovered extends ECGEvent {
  final List<BluetoothDevice> devices;

  const ECGDeviceDiscovered({required this.devices});

  @override
  List<Object?> get props => [devices];
}