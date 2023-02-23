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
  RemoBloc() : super(Disconnected()) {
    on<OnConnectDevice>(_startConnecting);
    on<OnDisconnectDevice>(_startDisconnecting);
    on<OnStartTransmission>(_startTransmission);
    on<OnStopTransmission>(_stopTransmission);
    on<OnResetTransmission>(_resetTransmission);
    on<OnSwitchTransmissionMode>(_switchTransmissionMode);
  }

  void _switchTransmissionMode(
      OnSwitchTransmissionMode _, Emitter<RemoState> emit) {
    switch (transmissionMode) {
      case TransmissionMode.rms:
        transmissionMode = TransmissionMode.rawImu;
        break;
      case TransmissionMode.rawImu:
        transmissionMode = TransmissionMode.rms;
        break;
    }
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
            // TODO: these 2 messages should eventually go to the start transmission function, if the device firmware will be updated.
            late int acquisitionMode;
            switch (transmissionMode) {
              case TransmissionMode.rms:
                acquisitionMode = 50;
                break;
              case TransmissionMode.rawImu:
                acquisitionMode = 51;
                break;
            }
            // Message to set acquisition mode.
            Uint8List message = Uint8List.fromList([
              65, // A
              84, // T
              83, // S
              49, // 1 for acquisition mode
              61, // = for write
              acquisitionMode, // 2 for RMS
              13, // CR
              10, // LF
            ]);
            _bluetooth.sendMessage(message);

            Future.delayed(Duration(milliseconds: 10));

            // Message to set operating mode.
            Uint8List message2 = Uint8List.fromList([
              65, // A
              84, // T
              83, // S
              50, // 2 for operating mode
              61, // = for write
              50, // 2 transmission mode
              13, // CR
              10, // LF
            ]);
            _bluetooth.sendMessage(message2);

            remoDataStream = _bluetooth.getInputStream()!;

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
            isTransmissionEnabled = false;
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

    if(remoDataStream != null) {
      // Getting data from Remo.
      remoStreamSubscription = remoDataStream!.listen(
            (dataBytes) {
          if (isTransmissionEnabled && dataBytes.length == 41) {
            ByteData byteArray = dataBytes.buffer.asByteData();
            // Converting the data coming from Remo.
            //// EMG.
            List<double> emg = List.filled(channels, 0);
            for (int byteIndex = 8, emgIndex = 0;
            emgIndex < channels;
            byteIndex += 2, ++emgIndex) {
              switch (transmissionMode) {
                case TransmissionMode.rms:
                  emg[emgIndex] = byteArray.getUint16(byteIndex) / 1000;
                  break;
                case TransmissionMode.rawImu:
                  emg[emgIndex] = byteArray.getInt16(byteIndex) / 1000;
                  break;
              }
            }
            //// Accelerometer.
            //// Gyroscope.
            //// Magnetometer.
            // Number 3 is because we are considering accelerations in the 3 dimensions of space.
            List<double> acceleration = List.filled(3, 0);
            List<double> angularVelocity = List.filled(3, 0);
            List<double> magneticField = List.filled(3, 0);
            for (int byteIndex = 24, index = 0;
            index < 3;
            byteIndex += 2, ++index) {
              acceleration[index] = byteArray.getInt16(byteIndex) / 100;
              angularVelocity[index] = byteArray.getInt16(byteIndex + 6) / 100;
              magneticField[index] = byteArray.getInt16(byteIndex + 12) / 100;
            }

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
        },
        onDone: () {
          dataController.close();
        },
      );

      isTransmissionEnabled = true;
      emit(TransmissionStarted(dataStream));
    }else{
      emit(ConnectionError());
    }
  }

  void _stopTransmission(OnStopTransmission _, Emitter<RemoState> emit) async {
    emit(StoppingTransmission());
    isTransmissionEnabled = false;
    remoStreamSubscription?.cancel();
    emit(TransmissionStopped());
  }

  void _resetTransmission(
      OnResetTransmission _, Emitter<RemoState> emit) async {
    if (await _bluetooth.isDeviceConnected()) {
      emit(Connected());
    } else {
      emit(Disconnected());
    }
  }

  // Remo's emg channels.
  static const int channels = 8;

  // Stream subscription handler.
  StreamSubscription<Uint8List>? remoStreamSubscription;
  // The controller for the stream to pass to the UI.
  StreamController<RemoData> dataController = StreamController<RemoData>();
  // The stream to pass to the UI.
  late Stream<RemoData> dataStream = dataController.stream.asBroadcastStream();

  /// All the actual bluetooth actions are handled here.
  final Bluetooth _bluetooth = Bluetooth();

  /// The stream of data coming directly from the Remo device.
  Stream<Uint8List>? remoDataStream;

  /// Flag to enable/disable the stream of parsed data.
  bool isTransmissionEnabled = false;

  TransmissionMode transmissionMode = TransmissionMode.rms;
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
