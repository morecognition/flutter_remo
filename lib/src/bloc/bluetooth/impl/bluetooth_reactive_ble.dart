import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import '../bluetooth.dart';

/// Implementation of the abstract class Bluetooth which uses the Flutter Reactive BLE library.
class BluetoothReactiveBLE implements Bluetooth {

  BluetoothReactiveBLE._internal();

  static final BluetoothReactiveBLE _singleton = BluetoothReactiveBLE
      ._internal();

  factory BluetoothReactiveBLE() {
    return _singleton;
  }

  late StreamSubscription<ConnectionStateUpdate> _connection;
  late Stream<ConnectionStateUpdate> _currentConnectionStream;
  late QualifiedCharacteristic _txCharacteristic;
  late QualifiedCharacteristic _rxCharacteristic;
  bool _connected = false;


  final flutterReactiveBle = FlutterReactiveBle();
  final Uuid _remoServiceUUID = Uuid.parse(
      "49535343-fe7d-4ae5-8fa9-9fafd205e455");
  final Uuid _remoCharacteristicTxUUID = Uuid.parse(
      "49535343-8841-43f4-a8d4-ecbe34729bb3");
  final Uuid _remoCharacteristicRxUUID = Uuid.parse(
      "49535343-1e4d-4bd9-ba61-23c647249616");


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
    await flutterReactiveBle.writeCharacteristicWithResponse(
        _txCharacteristic, value: message).onError((error, stackTrace) =>
        print(error));
    return true;
  }

  @override
  bool sendMessage(Uint8List message) {
    print(
        "send data to device ->  $message - ${String.fromCharCodes(message)}");
    flutterReactiveBle.writeCharacteristicWithoutResponse(
        _txCharacteristic, value: message);
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
      final device = await flutterReactiveBle.scanForDevices(
          withServices: [_remoServiceUUID], scanMode: ScanMode.lowLatency)
          .timeout(Duration(seconds: 10))
          .firstWhere((element) => element.name.startsWith("More"),
          orElse: null);

      if (device != null) {
        // connect to device
        _currentConnectionStream =
            flutterReactiveBle.connectToAdvertisingDevice(
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
      } else {
        connectionStatesController.add(ConnectionStates.disconnected);
      }
    }catch(_){
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
    }
    );
    return statesStream;
  }

  @override
  Stream<DeviceInfos> startDiscovery() {
    StreamController<DeviceInfos> infoStreamController =
    StreamController<DeviceInfos>.broadcast();
    Stream<DeviceInfos> namesStream = infoStreamController.stream;
    flutterReactiveBle.scanForDevices(
        withServices: [_remoServiceUUID], scanMode: ScanMode.lowLatency)
        .listen((device) {
      if (device.name.isNotEmpty && device.name.startsWith("More")) {
        infoStreamController.add(
          DeviceInfos(
            device.name,
            device.id,
          ),
        );
        print("Trovato Remo con id: ${device.id}");
      }
    }, onDone: () => infoStreamController.close());
    return namesStream;
  }

  @override
  Future<List<int>> readData() async {
    return flutterReactiveBle.readCharacteristic(_rxCharacteristic);
  }
}