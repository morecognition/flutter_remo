import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

import 'bluetooth.dart';

/// Implementation of the abstract class Bluetooth which uses the Flutter Bluetooth Serial library.
class BluetoothSerial implements Bluetooth {
  @override
  Stream<DeviceInfos> startDiscovery() {
    infoStreamController = StreamController<DeviceInfos>();
    Stream<DeviceInfos> namesStream = infoStreamController.stream;

    _bluetoothSerial.startDiscovery().listen((result) {
      // For some reason the name of some devices can be null or empty. Better to avoid those edge cases to prevent segfault.
      if (result.device!.name != null && result.device!.address != null) {
        _devices.add(result);
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
    connectionStatesController = StreamController<ConnectionStates>();
    Stream<ConnectionStates> statesStream = connectionStatesController.stream;

    // Init data stream.
    //remoOutputController = StreamController<Uint8List>();

    BluetoothConnection.toAddress(address)
        .then((connection) {
      _connectedDevice = connection;
      connectionStatesController.add(ConnectionStates.connected);
    });
    connectionStatesController.add(ConnectionStates.connecting);
    return statesStream;
  }

  void startRemoTransmission() {
    // Contains ASCII codes Remo firmware expects.
    Uint8List message = Uint8List.fromList([
      65, // A
      84, // T
      83, // S
      49, // 1 for acquisition mode
      61, // = for write
      50, // 2 for RMS
      13, // CR
      10, // LF
    ]);
    _connectedDevice.output.add(message);

    // Contains ASCII codes Remo firmware expects.
    Uint8List message2 = Uint8List.fromList([
      65, // A
      84, // T
      83, // S
      50, // 2 for operating mode
      61, // = for write
      50, // 2 for RMS
      13, // CR
      10, // LF
    ]);
    _connectedDevice.output.add(message2);
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
    connectionStatesController = StreamController<ConnectionStates>();
    Stream<ConnectionStates> statesStream = connectionStatesController.stream;

    _connectedDevice.finish().then((value) {
      _connectedDevice.dispose();
      connectionStatesController.add(ConnectionStates.disconnected);
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

  /// Collection containing handles to the discovered devices.
  List<BluetoothDiscoveryResult> _devices = <BluetoothDiscoveryResult>[];

  /// Names of the discovered devices will be given through this stream.
  late StreamController<DeviceInfos> infoStreamController;

  /// Updates on the connection status will be given through this stream.
  late StreamController<ConnectionStates> connectionStatesController;

}
