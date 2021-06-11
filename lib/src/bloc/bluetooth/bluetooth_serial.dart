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
      if (result.device.name != null && result.device.address != null) {
        _devices.add(result);
        infoStreamController.add(
          DeviceInfos(
            result.device.name,
            result.device.address,
          ),
        );
      }
    }, onDone: () => infoStreamController.close());

    return namesStream;
  }

  @override
  Stream<ConnectionStates> startConnection() {
    if (selectedDeviceInfos == null) {
      throw ArgumentError();
    }

    // Init connection state stream.
    connectionStatesController = StreamController<ConnectionStates>();
    Stream<ConnectionStates> statesStream = connectionStatesController.stream;

    // Init data stream.
    //remoOutputController = StreamController<Uint8List>();

    BluetoothConnection.toAddress(selectedDeviceInfos.address)
        .then((connection) {
      _connectedDevice = connection;
      _connectedDevice.input.listen((data) {
        if (shouldWriteData) {
          _buffer.write(data);
        }
      });

      startRemoTransmission();
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

  @override
  Stream<ConnectionStates> startDisconnection() {
    if (selectedDeviceInfos == null) {
      throw ArgumentError();
    }
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

  @override
  void startTransmission() {
    _buffer.clear();
    shouldWriteData = true;
  }

  @override
  String stopTransmission() {
    shouldWriteData = false;
    return _buffer.toString();
  }

  static final BluetoothSerial _singleton = BluetoothSerial._internal();

  factory BluetoothSerial() {
    return _singleton;
  }

  BluetoothSerial._internal();

  @override
  DeviceInfos selectedDeviceInfos;

  BluetoothConnection _connectedDevice;

  FlutterBluetoothSerial _bluetoothSerial = FlutterBluetoothSerial.instance;

  /// Collection containing handles to the discovered devices.
  List<BluetoothDiscoveryResult> _devices = <BluetoothDiscoveryResult>[];

  /// Names of the discovered devices will be given through this stream.
  StreamController<DeviceInfos> infoStreamController;

  /// Updates on the connection status will be given through this stream.
  StreamController<ConnectionStates> connectionStatesController;

  /// Data coming from the device will be given through this stream.
  //StreamController<Uint8List> remoOutputController;

  StringBuffer _buffer = StringBuffer();
  bool shouldWriteData = false;
}
