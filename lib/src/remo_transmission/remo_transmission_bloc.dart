import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:bloc/bloc.dart';
import 'package:flutter_bluetooth/flutter_bluetooth.dart';
import 'package:meta/meta.dart';
import 'package:path_provider/path_provider.dart';

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
    String filename = DateTime.now().toString() + ".txt";
    Directory directory = await getApplicationDocumentsDirectory();

    String filepath = directory.path + filename;

    File file = new File(filepath);
    print(filepath);
    yield TransmissionStarted();
    remoDataStream = _bluetooth.startTransmission().listen((remoData) {
      file.writeAsString(remoData.toString(),
          mode: FileMode.append, flush: true);
    });
  }

  Stream<RemoTransmissionState> _stopTransmission() async* {
    yield StoppingTransmission();
    remoDataStream.cancel();
    _bluetooth.stopTransmission();
    yield RemoTransmissionInitial();
  }

  StreamSubscription<Uint8List> remoDataStream;

  /// All the actual bluetooth actions are handled here.
  final FlutterBluetooth _bluetooth = FlutterBluetooth();
}
