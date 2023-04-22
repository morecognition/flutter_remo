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
  late Stream<Uint8List> _receivedDataStream;
  late QualifiedCharacteristic _txCharacteristic;
  bool _scanning = false;
  bool _connected = false;


  final flutterReactiveBle = FlutterReactiveBle();
  final Uuid _remoServiceUUID = Uuid.parse(
      "49535343-fe7d-4ae5-8fa9-9fafd205e455");
  final Uuid _remoCharacteristicRxTxUUID = Uuid.parse(
      "49535343-1e4d-4bd9-ba61-23c647249616");

  // ONLY FOR TEST
  // todo remeve them
  final String androidDeviceID = "44:B7:D0:79:5C:39";
  final String iosDeviceID = "36019A2B-85D8-8B8D-4A89-ED245D55A7A5";


  @override
  Stream<Uint8List>? getInputStream() {
    return _receivedDataStream;
  }

  @override
  Future<bool> isDeviceConnected() {
    return  Future.value(_connected);
  }

  @override
  bool sendMessage(Uint8List message) {
    if(_txCharacteristic != null) {
      flutterReactiveBle.writeCharacteristicWithoutResponse(
          _txCharacteristic, value: message);
      return true;
    }
    return false;
  }

  @override
  Stream<ConnectionStates> startConnection(String address) {
    // Init connection state stream.
    StreamController<ConnectionStates> connectionStatesController =
    StreamController<ConnectionStates>();
    Stream<ConnectionStates> statesStream = connectionStatesController.stream;
    _currentConnectionStream = flutterReactiveBle.connectToDevice(id: androidDeviceID);

    _connection = _currentConnectionStream.listen((event) {
      var id = event.deviceId.toString();
      print(id);
      switch (event.connectionState) {
        case DeviceConnectionState.connecting:
          connectionStatesController.add(ConnectionStates.connecting);
          break;
        case DeviceConnectionState.connected:
          connectionStatesController.add(ConnectionStates.connected);
          _connected = true;
          _txCharacteristic = QualifiedCharacteristic(serviceId: _remoServiceUUID, characteristicId: _remoCharacteristicRxTxUUID, deviceId: event.deviceId);
          _receivedDataStream = flutterReactiveBle.subscribeToCharacteristic(_txCharacteristic).map((event) => event as Uint8List);
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
        withServices: [], scanMode: ScanMode.lowLatency).listen((device) {
          if(device.name.isNotEmpty && device.name.startsWith("REMO")) {
            infoStreamController.add(
              DeviceInfos(
                device.name,
                device.name, // to do change with mac address
              ),
            );
            print("Trovato Remo con id: ${device.id}");
          }
    }, onDone: () => infoStreamController.close());
    return namesStream;
  }
}