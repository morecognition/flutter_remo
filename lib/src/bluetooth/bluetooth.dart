import 'dart:async';
import 'dart:typed_data';

import 'bluetooth_serial.dart';

/// Template used by a class used to discover Bluetooth devices and connect to them. Made to decouple the application from the Bluetooth library used.
abstract class Bluetooth {
  Stream<DeviceInfos> startDiscovery();
  Stream<ConnectionStates> startConnection();
  Stream<ConnectionStates> startDisconnection();
  Stream<Uint8List> startTransmission();
  void stopTransmission();

  factory Bluetooth() {
    return BluetoothSerial();
  }

  DeviceInfos selectedDeviceInfos;
}

/// Information related to a specific bluetooth device.
class DeviceInfos {
  DeviceInfos(this.name, this.address);
  String name;
  String address;
}

/// The various states a connection with a device can be in.
enum ConnectionStates {
  disconnected,
  connected,
  connecting,
  disconnecting,
  error,
}
