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
  static const int rmsDataCode = 44; // D
  static const int identifierDataCode = 63; // ?
  static const int realtimeDataCode = 82; // R
  static const int acquisitionModeDataCode = 83; // S
  static const int activateSensorModeDataCode = 65; // A

  // Remo's emg channels.
  static const int channels = 8;

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
      in _bluetooth.startConnection(event.address)) {
        switch (state) {
          case ConnectionStates.disconnected:
            emit(Disconnected());
            break;
          case ConnectionStates.connected:
          Uint8List message = Uint8List.fromList([
              63, // ?
              65, // A
              0001, // counter
              02, //
              68, // D ( RMS )
            ]);
            await _bluetooth.sendMessage(message);
            remoDataStream = _bluetooth.getInputStream()!;
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
  void _startDisconnecting(OnDisconnectDevice event,
      Emitter<RemoState> emit) async {
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

  void _startTransmission(OnStartTransmission _,
      Emitter<RemoState> emit) async {
    emit(StartingTransmission());

    // send sensor aquisition message
    List<int> message = [
      identifierDataCode, // ?
      acquisitionModeDataCode, // S
      0000, // counter
      00
    ];
    _bluetooth.sendMessage(message);
    await _bluetooth.sendMessage(message);

    dataController = StreamController<RemoData>();
    dataStream = dataController.stream.asBroadcastStream();

    if (remoDataStream != null) {
      // Getting data from Remo.
      remoStreamSubscription = remoDataStream!.listen(
            (dataBytes) {
          print("Sto leggendo ${dataBytes.toString()} bytes");
          if (dataBytes.isNotEmpty && dataBytes.first == rmsDataCode) {
            ByteData byteArray = Uint8List
                .fromList(dataBytes)
                .buffer
                .asByteData();
            // Converting the data coming from Remo.
            //// EMG.
            List<double> emg = List.filled(channels, 0);
            for (int byteIndex = 8, emgIndex = 0;
            emgIndex < channels;
            byteIndex += 4, ++emgIndex) {
              emg[emgIndex] = byteArray.getInt32(byteIndex) / 1000;
            }
            //// Accelerometer.
            //// Gyroscope.
            //// Magnetometer.
            // Number 3 is because we are considering accelerations in the 3 dimensions of space.
            List<double> acceleration = List.filled(3, 0);
            List<double> angularVelocity = List.filled(3, 0);
            List<double> magneticField = List.filled(3, 0);
            /*for (int byteIndex = 24, index = 0;
                index < 3;
                byteIndex += 2, ++index) {
              acceleration[index] = byteArray.getInt16(byteIndex) / 100;
              angularVelocity[index] = byteArray.getInt16(byteIndex + 6) / 100;
              magneticField[index] = byteArray.getInt16(byteIndex + 12) / 100;
            }*/

            /// Finally.
            dataController.add(
              RemoData(
                emg: emg,
                acceleration: Vector3(
                  acceleration[0],
                  acceleration[1],
                  acceleration[2],
                ),
                angularVelocity: Vector3(
                  angularVelocity[0],
                  angularVelocity[1],
                  angularVelocity[2],
                ),
                magneticField: Vector3(
                  magneticField[0],
                  magneticField[1],
                  magneticField[2],
                ),
              ),
            );
          }
          // send ack
          final ack = _buildACKMessage(dataBytes);
          _bluetooth.sendMessage(ack);
        },
        onError: (error) {
          print("Errore subscribe");
        },
        onDone: () {
          dataController.close();
        },
      );

      emit(TransmissionStarted(dataStream));
    } else {
      emit(ConnectionError());
    }
  }


  List<int> _buildACKMessage(List<int> message) {
    if (message.length >= 3) {
      final ok = [2, 79, 75]; // OK
      var ack = message.take(
          3); // take identifier, command and counter from message
      return List.from(ack)..addAll(ok); // return ack + ok
    }
    return message;
  }

  void _stopTransmission(OnStopTransmission _, Emitter<RemoState> emit) async {
    emit(StoppingTransmission());
    remoStreamSubscription?.cancel();
    emit(TransmissionStopped());
  }

  void _resetTransmission(OnResetTransmission _,
      Emitter<RemoState> emit) async {
    if (await _bluetooth.isDeviceConnected()) {
      emit(Connected());
    } else {
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
    return "${emg[0]},${emg[1]},${emg[2]},${emg[3]},${emg[4]},${emg[5]},${emg[6]},${emg[7]},${acceleration
        .x},${acceleration.y},${acceleration.z},${angularVelocity
        .x},${angularVelocity.y},${angularVelocity.z},${magneticField
        .x},${magneticField.y},${magneticField.z}\n";
  }
}
