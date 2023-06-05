import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_remo/src/bloc/bluetooth/impl/bluetooth_reactive_ble.dart';

/// Template used by a class used to discover Bluetooth devices and connect to them. Made to decouple the application from the Bluetooth library used.
abstract class Bluetooth {
  /// Starts discovering Bluetooth devices.
  Stream<DeviceInfos> startDiscovery();

  /// Starts the connection with a Bluetooth device, given the address.
  Future<Stream<ConnectionStates>> startConnection(String address);

  /// Gets the stream containing data coming from the Bluetooth device.
  Stream<List<int>>? getInputStream();

  /// Starts disconnecting a previously connected Bluetooth device.
  Stream<ConnectionStates> startDisconnection();

  /// Sends a message to a previously connected Bluetooth device.
  bool sendMessage(Uint8List message);

  Future<bool> sendAsyncMessage(Uint8List message);

  Future<bool> isDeviceConnected();

  factory Bluetooth() {
    //return BluetoothSerial();
    return BluetoothReactiveBLE();
  }
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
