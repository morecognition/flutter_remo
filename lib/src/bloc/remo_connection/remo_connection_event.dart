part of 'remo_connection_bloc.dart';

abstract class RemoConnectionEvent {}

/// Starts connection to a device.
class OnConnectDevice extends RemoConnectionEvent {}

/// Starts device disconnection.
class OnDisconnectDevice extends RemoConnectionEvent {}

/// Starts the data collection.
class OnStartRecording extends RemoConnectionEvent {}

/// Used to select a specific device among the ones discovered.
class OnSelectDevice extends RemoConnectionEvent {
  OnSelectDevice(this.deviceName, this.deviceAddress);
  String? deviceAddress;
  String? deviceName;
}
