part of 'bluetooth_bloc.dart';

/// Classes inheriting from this are used to represent events coming from the UI.
abstract class BluetoothEvent {}

/// Starts devices discovery through bluetooth.
class OnStartDiscovery extends BluetoothEvent {}

/// Event used internally to notif the discovery of devices.
class OnDiscoveredDevices extends BluetoothEvent {
  OnDiscoveredDevices(this.deviceNames, this.deviceAddresses);
  List<String?> deviceNames;
  List<String?> deviceAddresses;
}
