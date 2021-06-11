import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:flutter_remo/src/bloc/bluetooth/bluetooth.dart';
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
    _bluetooth.startTransmission();
    yield TransmissionStarted();
  }

  Stream<RemoTransmissionState> _stopTransmission() async* {
    yield StoppingTransmission();
    String data = _bluetooth.stopTransmission();
    yield NewDataReceived(data);
  }

  //StreamSubscription<Uint8List> remoDataStream;

  /// All the actual bluetooth actions are handled here.
  final Bluetooth _bluetooth = Bluetooth();
}
