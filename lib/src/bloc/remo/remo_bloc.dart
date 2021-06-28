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
    yield TransmissionStarted();
  }

  Stream<RemoState> _stopTransmission() async* {
    // TODO: waiting for M.Porro to allow stopping the data transmission.
  }

  /// All the actual bluetooth actions are handled here.
  final Bluetooth _bluetooth = Bluetooth();
}
