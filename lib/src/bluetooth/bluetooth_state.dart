part of 'bluetooth_bloc.dart';

/// Classes inherithing from this, represent the various states in which
/// the bluetooth interface can be. They are used to notify the UI.
abstract class BluetoothState {}

/// Bluetooth is initialized but not much else happened.
class BluetoothInitial extends BluetoothState {}

/// Device discovery has been started.
class DiscoveringDevices extends BluetoothState {}

/// Some or all the devices have been discovered.
class DiscoveredDevices extends BluetoothState {
  DiscoveredDevices(this.deviceNames, this.deviceAddresses);
  List<String> deviceNames;
  List<String> deviceAddresses;
}

/// Unsuccessful discovery of devices.
class DiscoveryError extends BluetoothState {}
