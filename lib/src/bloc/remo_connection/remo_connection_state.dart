part of 'remo_connection_bloc.dart';

abstract class RemoConnectionState {
  RemoConnectionState(this.deviceName, this.deviceAddress);
  String? deviceName;
  String? deviceAddress;
}

/// Initial and final state.
class Disconnected extends RemoConnectionState {
  Disconnected(String? deviceName, String? deviceAddress)
      : super(deviceName, deviceAddress);
}

/// Connection procedure has been started.
class Connecting extends RemoConnectionState {
  Connecting(String? deviceName, String? deviceAddress)
      : super(deviceName, deviceAddress);
}

/// Successful connection to the device.
class Connected extends RemoConnectionState {
  Connected(String? deviceName, String? deviceAddress)
      : super(deviceName, deviceAddress);
}

/// Successful connection to the device.
class ConnectionError extends RemoConnectionState {
  ConnectionError(String? deviceName, String? deviceAddress)
      : super(deviceName, deviceAddress);
}

/// New data from Remo device available.
class DataAvailable extends RemoConnectionState {
  DataAvailable(String deviceName, String deviceAddress)
      : super(deviceName, deviceAddress);
}

/// Disconnection procedure has been started.
class Disconnecting extends RemoConnectionState {
  Disconnecting(String? deviceName, String? deviceAddress)
      : super(deviceName, deviceAddress);
}
