import 'dart:async';
import 'dart:typed_data';

import 'package:bloc/bloc.dart';
import 'package:flutter_remo/src/bloc/bluetooth/bluetooth.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:vector_math/vector_math.dart';

part 'remo_event.dart';

part 'remo_state.dart';

/// Allows the pairing and connection with a Remo device
class RemoBloc extends Bloc<RemoEvent, RemoState> {
  static const int RMS_IDENTIFIER_CODE = 68; // D ( RMS data identifier)
  static const int IMU_IDENTIFIER_CODE = 67; // C ( IMU data identifier)
  static const int GLOBAL_IDENTIFIER_CODE = 63; // ? (Global identifier)
  static const int REALTIME_COMMAND_CODE = 82; // R ( Realtime command )
  static const int acquisitionModeDataCode = 83; // S
  static const int activateSensorModeDataCode = 65; // A
  static const int headerLength = 8; // 8byte

  // Remo's emg channels.
  static const int channels = 8;
  bool isTransmissionStarted = false;

  // Stream subscription handler.
  StreamSubscription<List<int>>? remoStreamSubscription;

  // The controller for the stream to pass to the UI.
  late StreamController<RemoData> dataController;

  // The stream to pass to the UI.
  late Stream<RemoData> dataStream;

  /// All the actual bluetooth actions are handled here.
  final Bluetooth _bluetooth = Bluetooth();

  /// The stream of data coming directly from the Remo device.
  Stream<List<int>>? remoDataStream;

  RemoBloc() : super(Disconnected()) {
    on<OnConnectDevice>(_startConnecting);
    on<OnDisconnectDevice>(_startDisconnecting);
    on<OnStartTransmission>(_startTransmission);
    on<OnStopTransmission>(_stopTransmission);
    on<OnResetTransmission>(_resetTransmission);
  }

  /// Connects to a specific devices. The name is given by the select device event.
  void _startConnecting(OnConnectDevice event, Emitter<RemoState> emit) async {
    emit(Connecting());
    await Permission.bluetoothConnect.request();
    await Permission.bluetoothScan.request();
    await Permission.bluetooth.request();
    await Permission.locationWhenInUse.request();
    try {
      await for (ConnectionStates state
          in await _bluetooth.startConnection(event.address)) {
        //in await _bluetooth.startConnection("34:81:F4:EA:45:8C")) {
        switch (state) {
          case ConnectionStates.disconnected:
            emit(Disconnected());
            break;
          case ConnectionStates.connected:
            remoDataStream = await _bluetooth.getInputStream()!;
            _startTransmission(OnStartTransmission(), emit);
            emit(Connected());
            break;
          case ConnectionStates.connecting:
            emit(Connecting());
            break;
          case ConnectionStates.disconnecting:
            Disconnecting();
            break;
          case ConnectionStates.error:
            emit(ConnectionError());
            break;
        }
      }
    } on Exception {
      // TODO: check what specific exceptions can occur.
      emit(ConnectionError());
    }
  }

  /// Disconnects the device.
  void _startDisconnecting(
      OnDisconnectDevice event, Emitter<RemoState> emit) async {
    emit(Disconnecting());
    try {
      await for (ConnectionStates state in _bluetooth.startDisconnection()) {
        switch (state) {
          case ConnectionStates.disconnected:
            remoStreamSubscription?.cancel();
            dataController.close();
            remoDataStream = null;
            emit(Disconnected());
            break;
          case ConnectionStates.connected:
            emit(Connected());
            break;
          case ConnectionStates.connecting:
            emit(Connecting());
            break;
          case ConnectionStates.disconnecting:
            emit(Disconnecting());
            break;
          case ConnectionStates.error:
            emit(ConnectionError());
            break;
        }
      }
    } on ArgumentError {
      emit(ConnectionError());
    }
  }

  void _startTransmission(
      OnStartTransmission _, Emitter<RemoState> emit) async {
    emit(StartingTransmission());
    if(!isTransmissionStarted) {
      dataController = StreamController<RemoData>();
      dataStream = dataController.stream.asBroadcastStream();

      // data buffer used to store data from multiple packets at a time
      List<int> buffer = [];

      //we want to check if we expect a new data package
      bool waitingForData = false;
      int waitingForDataSize = 0;

      // NOTE The protocol expects packets with an 8byte header composed of | 1 byte Identifier code (char) | - |  1byte Command code (char) | - | 2 byte counter  (char) | -  | 2 byte data length (char) | - | data |

      if (remoDataStream != null) {
        // Getting data from Remo.
        remoStreamSubscription = remoDataStream?.listen(
              (dataBytes) {
            final data = Uint8List.fromList(dataBytes);
            print("Reading -> ${data.toString()}");

            if (data.isNotEmpty && waitingForData == false) {
              final declaredMessageSize = int.parse(
                  String.fromCharCodes(data.sublist(6, 8)), radix: 16);
              final packetSize = dataBytes.length - headerLength;

              print("EMG data size -> $declaredMessageSize");
              print("Packet data size -> $packetSize");

              if (declaredMessageSize > packetSize) {
                // store data into buffer
                buffer.addAll(dataBytes);
                // set waiting for data true
                waitingForData = true;
                // store data size
                waitingForDataSize = declaredMessageSize;
              } else {
                // we can manage data
                switch (data.first) {
                  case RMS_IDENTIFIER_CODE:
                    _manageRMSData(data);
                    _sendAck(data);
                    break;
                  case GLOBAL_IDENTIFIER_CODE:
                    if (data.length >= headerLength + 1 &&
                        data[1] == acquisitionModeDataCode) {
                      final message = data.sublist(headerLength);
                      final stringMessage = String.fromCharCodes(message);
                      print("Data Acquisition response -> $stringMessage");
                      if (stringMessage.contains("OK")) {
                        _sendAck(data);
                      } else {
                        emit(ConnectionError());
                      }
                    } else {
                      _sendAck(data);
                    }
                    break;
                  default:
                    print("Unmanaged packet: $data");
                    _sendAck(data);
                }
              }
            } else if (data.isNotEmpty && waitingForData) {
              // store new data into buffer
              buffer.addAll(dataBytes);

              final bufferSize = buffer.length - headerLength;
              final percentage = (bufferSize / waitingForDataSize) * 100;

              print("Buffer size -> $bufferSize, Loaded -> $percentage %");

              if (waitingForDataSize == bufferSize) {
                //manage buffered data
                if (buffer.first == RMS_IDENTIFIER_CODE) {
                  _manageRMSData(Uint8List.fromList(buffer));
                  // todo manage any other data
                }
                _sendAck(Uint8List.fromList(buffer));
                // reset buffer
                buffer.clear();
                waitingForData = false;
                waitingForDataSize = 0;
              }
            }
          },
          onError: (error) {
            print("Subscribe error");
          },
          onDone: () {
            dataController.close();
          },
        );

        // send acquisition mode message
        print("--- Sending acquisition mode message ---");
        final message = "?S000000".codeUnits;
        _bluetooth.sendMessage(Uint8List.fromList(message));

        // emit transmission started
        emit(TransmissionStarted(dataStream));
        isTransmissionStarted = true;
      } else {
        emit(ConnectionError());
      }
    }else{
      emit(TransmissionStarted(dataStream));
    }
  }

  void _manageRMSData(Uint8List data) {
    ByteData byteArray =
        data.sublist(headerLength).buffer.asByteData(); // take only data

    // Converting the data coming from Remo.
    //// EMG.
    for (int dataIndex = 0;
        dataIndex < byteArray.lengthInBytes;
        dataIndex += channels * 2) {
      List<double> emg = List.filled(channels, 0);
      for (int byteIndex = dataIndex, emgIndex = 0;
          emgIndex < channels;
          byteIndex += 2, ++emgIndex) {
        emg[emgIndex] = byteArray.getInt16(byteIndex, Endian.little) * 4500000 / (65535 * 24);
      }

      print("EMG -> $emg");

      // sends EMG data to app
      dataController.add(
        RemoData(
          emg: emg,
          acceleration: Vector3(0.0, 0.0, 0.0),
          angularVelocity: Vector3(0.0, 0.0, 0.0),
          magneticField: Vector3(0.0, 0.0, 0.0),
        ),
      );
    }
  }

  List<int> _buildACKMessage(Uint8List message) {
    if (message.length >= headerLength) {
      final ok = [48, 50, 79, 75]; // 02 + OK
      var ack = message.take(headerLength -
          2); // take identifier, command and counter from message
      print("ack header -> ${String.fromCharCodes(ack)}");
      return List.from(ack)..addAll(ok); // return ack + ok
    }
    return message;
  }

  void _sendAck(Uint8List dataBytes) {
    final ack = _buildACKMessage(dataBytes);
    print("--- Sending ack to device ---");
    _bluetooth.sendMessage(Uint8List.fromList(ack));
  }

  void _stopTransmission(OnStopTransmission _, Emitter<RemoState> emit) async {
    emit(StoppingTransmission());
    remoStreamSubscription?.cancel();
    isTransmissionStarted = false;
    emit(TransmissionStopped());
  }

  void _resetTransmission(
      OnResetTransmission _, Emitter<RemoState> emit) async {
    if (await _bluetooth.isDeviceConnected()) {
      emit(Connected());
    } else {
      isTransmissionStarted = false;
      emit(Disconnected());
    }
  }
}

enum TransmissionMode {
  rms,
  rawImu,
}

class RemoData {
  //final Uint32 timestamp;
  final List<double> emg;
  final Vector3 acceleration;
  final Vector3 angularVelocity;
  final Vector3 magneticField;

  RemoData({
    //required this.timestamp,
    required this.emg,
    required this.acceleration,
    required this.angularVelocity,
    required this.magneticField,
  });

  String toCsvString() {
    return "${emg[0]},${emg[1]},${emg[2]},${emg[3]},${emg[4]},${emg[5]},${emg[6]},${emg[7]},${acceleration.x},${acceleration.y},${acceleration.z},${angularVelocity.x},${angularVelocity.y},${angularVelocity.z},${magneticField.x},${magneticField.y},${magneticField.z}\n";
  }
}
