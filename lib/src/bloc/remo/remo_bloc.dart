import 'dart:async';
import 'dart:typed_data';

import 'package:bloc/bloc.dart';
import 'package:flutter_remo/src/bloc/bluetooth/bluetooth.dart';

part 'remo_event.dart';
part 'remo_state.dart';

/// Allows the pairing and connection with a Remo device
class RemoBloc extends Bloc<RemoEvent, RemoState> {
  RemoBloc() : super(Disconnected());

  @override
  Stream<RemoState> mapEventToState(
    RemoEvent event,
  ) async* {
    if (event is OnConnectDevice) {
      yield* _startConnecting(event);
    } else if (event is OnDisconnectDevice) {
      yield* _startDisconnecting(event);
    } else if (event is OnStartTransmission) {
      yield* _startTransmission();
    } else if (event is OnStopTransmission) {
      yield* _stopTransmission();
    }
  }

  /// Connects to a specific devices. The name is given by the select device event.
  Stream<RemoState> _startConnecting(OnConnectDevice event) async* {
    yield Connecting();
    try {
      await for (ConnectionStates state
          in _bluetooth.startConnection(event.address)) {
        switch (state) {
          case ConnectionStates.disconnected:
            yield Disconnected();
            break;
          case ConnectionStates.connected:
            // TODO: these 2 messages should eventually go to the start transmission function once Maurizio Porro is done updating the firmware.
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
            _bluetooth.sendMessage(message);

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
            _bluetooth.sendMessage(message2);

            yield Connected();
            break;
          case ConnectionStates.connecting:
            yield Connecting();
            break;
          case ConnectionStates.disconnecting:
            Disconnecting();
            break;
          case ConnectionStates.error:
            yield ConnectionError();
            break;
        }
      }
    } on Exception {
      // TODO: check what specific exceptions can occur.
      yield ConnectionError();
    }
  }

  /// Disconnects the device.
  Stream<RemoState> _startDisconnecting(OnDisconnectDevice event) async* {
    yield Disconnecting();
    try {
      await for (ConnectionStates state in _bluetooth.startDisconnection()) {
        switch (state) {
          case ConnectionStates.disconnected:
            yield Disconnected();
            break;
          case ConnectionStates.connected:
            yield Connected();
            break;
          case ConnectionStates.connecting:
            yield Connecting();
            break;
          case ConnectionStates.disconnecting:
            Disconnecting();
            break;
          case ConnectionStates.error:
            yield ConnectionError();
            break;
        }
      }
    } on ArgumentError {
      yield ConnectionError();
    }
  }

  Stream<RemoState> _startTransmission() async* {
    yield StartingTransmission();
    // Allocating output stream.
    StreamController<RemoData> dataController = StreamController<RemoData>();
    Stream<RemoData> dataStream = dataController.stream;

    // Getting data from Remo.
    remoDataStream = _bluetooth.getInputStream()!;
    remoDataStream.listen(
      (dataBytes) {
        if (isTransmissionEnabled && dataBytes.length == 41) {
          // Converting the data coming from Remo.
          List<int> emg = List.filled(8, 0);
          for (int i = 0, byteIndex = 0; i < 8; ++i) {
            byteIndex = 2 * i;
            emg[i] = (dataBytes[5 + byteIndex] << 8) + dataBytes[6 + byteIndex];
          }
          dataController.add(RemoData(emg: emg));
        }
      },
      onDone: () {
        dataController.close();
      },
    );

    isTransmissionEnabled = true;
    yield TransmissionStarted(dataStream);
  }

  Stream<RemoState> _stopTransmission() async* {
    yield StoppingTransmission();
    isTransmissionEnabled = false;
    yield Connected();
  }

  /// All the actual bluetooth actions are handled here.
  final Bluetooth _bluetooth = Bluetooth();

  /// The stream of data coming directly from the Remo device.
  late final Stream<Uint8List> remoDataStream;

  /// Flag to enable/disable the stream of parsed data.
  bool isTransmissionEnabled = false;
}

class RemoData {
  //final Uint32 timestamp;
  final List<int> emg;
  //final Vector3 acceleration;
  //final Vector3 angularVelocity;
  //final Vector3 magneticField;

  RemoData({
    //required this.timestamp,
    required this.emg,
    //required this.acceleration,
    //required this.angularVelocity,
    //required this.magneticField,
  });
}
