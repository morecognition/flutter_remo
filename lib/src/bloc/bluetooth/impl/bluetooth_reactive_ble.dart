import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:collection/collection.dart';
import '../bluetooth.dart';

/// Implementation of the abstract class Bluetooth which uses the Flutter Reactive BLE library.
class BluetoothReactiveBLE implements Bluetooth {
  BluetoothReactiveBLE._internal();

  static final BluetoothReactiveBLE _singleton =
      BluetoothReactiveBLE._internal();

  factory BluetoothReactiveBLE() {
    return _singleton;
  }

  List<DiscoveredDevice> _foundBleUARTDevices = [];
  late StreamSubscription<DiscoveredDevice> _scanStream;
  late StreamSubscription<ConnectionStateUpdate> _connection;
  late Stream<ConnectionStateUpdate> _currentConnectionStream;
  late QualifiedCharacteristic _txCharacteristic;
  late QualifiedCharacteristic _rxCharacteristic;
  bool _connected = false;

  final flutterReactiveBle = FlutterReactiveBle();
  final Uuid _remoServiceUUID =
      Uuid.parse("49535343-fe7d-4ae5-8fa9-9fafd205e455");
  final Uuid _remoCharacteristicTxUUID =
      Uuid.parse("49535343-8841-43f4-a8d4-ecbe34729bb3");
  final Uuid _remoCharacteristicRxUUID =
      Uuid.parse("49535343-1e4d-4bd9-ba61-23c647249616");

  @override
  Stream<List<int>>? getInputStream() {
    return flutterReactiveBle.subscribeToCharacteristic(_rxCharacteristic);
  }

  @override
  Future<bool> isDeviceConnected() {
    return Future.value(_connected);
  }

  @override
  Future<bool> sendAsyncMessage(Uint8List message) async {
    await flutterReactiveBle
        .writeCharacteristicWithResponse(_txCharacteristic, value: message)
        .onError((error, stackTrace) => print(error));
    return true;
  }

  @override
  bool sendMessage(Uint8List message) {
    //print(
    //    "send data to device ->  $message - ${String.fromCharCodes(message)}");
    flutterReactiveBle.writeCharacteristicWithoutResponse(_txCharacteristic,
        value: message);
    return true;
  }

  @override
  Future<Stream<ConnectionStates>> startConnection(String address) async {
    // Init connection state stream.
    StreamController<ConnectionStates> connectionStatesController =
        StreamController<ConnectionStates>();
    Stream<ConnectionStates> statesStream = connectionStatesController.stream;
    try {
      // try to scan
      final device = await flutterReactiveBle
          .scanForDevices(
              withServices: [_remoServiceUUID], scanMode: ScanMode.lowLatency)
          .timeout(const Duration(seconds: 5))
          .firstWhere((dev) {
            if (dev.manufacturerData.isNotEmpty) {
              final macAddress =
                  _buildMACAddressFromManufacturerData(dev.manufacturerData);
              return address.contains(macAddress);
            }
            return false;
          });

      // connect to device
      _currentConnectionStream = flutterReactiveBle.connectToAdvertisingDevice(
          id: device.id,
          withServices: [_remoServiceUUID],
          prescanDuration: const Duration(seconds: 5),
          connectionTimeout: const Duration(seconds: 90));

      _connection = _currentConnectionStream.listen((event) {
        switch (event.connectionState) {
          case DeviceConnectionState.connecting:
            connectionStatesController.add(ConnectionStates.connecting);
            break;
          case DeviceConnectionState.connected:
            _connected = true;
            flutterReactiveBle.requestMtu(deviceId: device.id, mtu: 150);
            _txCharacteristic = QualifiedCharacteristic(
                serviceId: _remoServiceUUID,
                characteristicId: _remoCharacteristicTxUUID,
                deviceId: event.deviceId);
            _rxCharacteristic = QualifiedCharacteristic(
                serviceId: _remoServiceUUID,
                characteristicId: _remoCharacteristicRxUUID,
                deviceId: event.deviceId);
            connectionStatesController.add(ConnectionStates.connected);
            break;
          case DeviceConnectionState.disconnecting:
            connectionStatesController.add(ConnectionStates.disconnecting);
            break;
          case DeviceConnectionState.disconnected:
            connectionStatesController.add(ConnectionStates.disconnected);
            break;
        }
      }, onError: (error) {
        connectionStatesController.add(ConnectionStates.error);
        connectionStatesController.close();
      });
    } catch (_) {
      connectionStatesController.add(ConnectionStates.disconnected);
    }

    return statesStream;
  }

  @override
  Stream<ConnectionStates> startDisconnection() {
    StreamController<ConnectionStates> connectionStatesController =
        StreamController<ConnectionStates>();
    Stream<ConnectionStates> statesStream = connectionStatesController.stream;
    _connection.cancel().then((_) {
      _connected = false;
      connectionStatesController.add(ConnectionStates.disconnected);
    });
    return statesStream;
  }

  @override
  Stream<DeviceInfos> startDiscovery() {
    StreamController<DeviceInfos> infoStreamController =
        StreamController<DeviceInfos>.broadcast();
    Stream<DeviceInfos> namesStream = infoStreamController.stream;
    _foundBleUARTDevices = [];
    _scanStream = flutterReactiveBle.scanForDevices(withServices: [
      _remoServiceUUID
    ], scanMode: ScanMode.lowLatency).timeout(const Duration(seconds: 5),
        onTimeout: (_) {
      _scanStream.cancel();
      infoStreamController.close();
    }).listen((device) {
      if (_foundBleUARTDevices.every((element) => element.id != device.id) &&
          device.manufacturerData.isNotEmpty) {
        //print("Trovato Remo con id: ${device.id}");
        _foundBleUARTDevices.add(device);
        infoStreamController.add(
          DeviceInfos(device.id,
              _buildMACAddressFromManufacturerData(device.manufacturerData)),
        );
        infoStreamController.close();
      }
    }, onDone: () {
      infoStreamController.close();
    });
    return namesStream;
  }

  Future<List<int>> readData() async {
    return flutterReactiveBle.readCharacteristic(_rxCharacteristic);
  }

  String _buildMACAddressFromManufacturerData(Uint8List manufacturerData) {
    return manufacturerData
        .map((e) => e.toRadixString(16))
        .toList()
        .mapIndexed((index, element) {
      if (index < manufacturerData.length - 1) {
        return "$element:".toUpperCase();
      }
      return element.toUpperCase();
    }).join();
  }
}
