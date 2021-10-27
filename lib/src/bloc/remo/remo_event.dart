part of 'remo_bloc.dart';

abstract class RemoEvent {}

/// Starts connection to a device.
class OnConnectDevice extends RemoEvent {
  OnConnectDevice(this.address);
  final String address;
}

class OnSwitchTransmissionMode extends RemoEvent {}

/// Starts device disconnection.
class OnDisconnectDevice extends RemoEvent {}

class OnStartTransmission extends RemoEvent {}

class OnStopTransmission extends RemoEvent {}

class OnResetTransmission extends RemoEvent {}
