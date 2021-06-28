import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

import 'bluetooth.dart';

/// Implementation of the abstract class Bluetooth which uses the Flutter Bluetooth Serial library.
class BluetoothSerial implements Bluetooth {
  @override
  Stream<DeviceInfos> startDiscovery() {
    StreamController<DeviceInfos> infoStreamController =
        StreamController<DeviceInfos>();
    Stream<DeviceInfos> namesStream = infoStreamController.stream;

    _bluetoothSerial.startDiscovery().listen((result) {
      // For some reason the name of some devices can be null or empty. Better to avoid those edge cases to prevent segfault.
      if (result.device!.name != null && result.device!.address != null) {
        infoStreamController.add(
          DeviceInfos(
            result.device!.name!,
            result.device!.address!,
          ),
        );
      }
    }, onDone: () => infoStreamController.close());

    return namesStream;
  }

  @override
  Stream<ConnectionStates> startConnection(String address) {
    // Init connection state stream.
    StreamController<ConnectionStates> connectionStatesController =
        StreamController<ConnectionStates>();
    Stream<ConnectionStates> statesStream = connectionStatesController.stream;

    BluetoothConnection.toAddress(address).then(
      (connection) {
        _connectedDevice = connection;
        connectionStatesController.add(ConnectionStates.connected);
        connectionStatesController.close();
      },
      onError: (_) {
        connectionStatesController.add(ConnectionStates.error);
        connectionStatesController.close();
      },
    );
    connectionStatesController.add(ConnectionStates.connecting);
    return statesStream;
  }

  /// Allows to send a message to the connected device.
  bool sendMessage(Uint8List message) {
    try {
      _connectedDevice.output.add(message);
    } catch (StateError) {
      return false;
    }
    return true;
  }

  @override
  Stream<ConnectionStates> startDisconnection() {
    // Init stream.
    StreamController<ConnectionStates> connectionStatesController =
        StreamController<ConnectionStates>();
    Stream<ConnectionStates> statesStream = connectionStatesController.stream;

    _connectedDevice.finish().then((value) {
      _connectedDevice.close();
      _connectedDevice.dispose();
      connectionStatesController.add(ConnectionStates.disconnected);
      connectionStatesController.close();
    });

    connectionStatesController.add(ConnectionStates.disconnecting);
    return statesStream;
  }

  static final BluetoothSerial _singleton = BluetoothSerial._internal();

  factory BluetoothSerial() {
    return _singleton;
  }

  BluetoothSerial._internal();

  late BluetoothConnection _connectedDevice;

  FlutterBluetoothSerial _bluetoothSerial = FlutterBluetoothSerial.instance;
}
