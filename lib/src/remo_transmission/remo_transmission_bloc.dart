import 'dart:async';
import 'dart:typed_data';

import 'package:bloc/bloc.dart';
import 'package:flutter_remo/src/bluetooth/bluetooth.dart';
import 'package:meta/meta.dart';

part 'remo_transmission_event.dart';
part 'remo_transmission_state.dart';

/// Contains the functionalities to get data from an already paired Remo device.
class RemoTransmissionBloc
    extends Bloc<RemoTransmissionEvent, RemoTransmissionState> {
  RemoTransmissionBloc() : super(RemoTransmissionInitial());

  @override
  Stream<RemoTransmissionState> mapEventToState(
    RemoTransmissionEvent event,
  ) async* {
    if (event is OnStartTransmission) {
      yield* _startTransmission();
    } else if (event is OnStopTransmission) {
      yield* _stopTransmission();
    }
  }

  Stream<RemoTransmissionState> _startTransmission() async* {
    yield TransmissionStarted();
    remoDataStream = _bluetooth.startTransmission().listen((remoData) {
      _buffer.writeAll(remoData);
    });
  }

  Stream<RemoTransmissionState> _stopTransmission() async* {
    yield StoppingTransmission();
    remoDataStream.cancel();
    _bluetooth.stopTransmission();
    yield NewDataReceived(_buffer.toString());
  }

  StringBuffer _buffer = StringBuffer();
  StreamSubscription<Uint8List> remoDataStream;

  /// All the actual bluetooth actions are handled here.
  final Bluetooth _bluetooth = Bluetooth();
}
