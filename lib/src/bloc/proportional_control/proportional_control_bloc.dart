import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_remo/flutter_remo.dart';

part 'proportional_control_event.dart';
part 'propotional_control_state.dart';

class ProportionalControlBloc
    extends Bloc<ProportionalControlEvent, PropotionalControlState> {
  static const baseValueRecordingTime = Duration(seconds: 5);
  static const mvcRecordingTime = Duration(seconds: 3);
  static const progressStreamUpdateFrequency = Duration(milliseconds: 16);

  final StreamController<double> _baseValueStreamController =
      StreamController<double>();
  final StreamController<double> _mvcStreamController =
      StreamController<double>();

  double _mvc = 0;
  double _baseValue = 0;

  StreamSubscription<RmsData>? _rmsStreamSubscription;

  ProportionalControlBloc() : super(Inactive()) {
    on<StartRecordingBaseValue>(_recordBaseValue);
    on<StartRecordingMvc>(_recordMvc);
    on<StartProportionalControl>(_startProportionalControl);
    on<StopOperations>(_stopOperations);
  }

  void _recordBaseValue(StartRecordingBaseValue event,
      Emitter<PropotionalControlState> emit) async {
    _rmsStreamSubscription?.cancel();

    _rmsStreamSubscription = event.rmsDataStream.listen((rmsData) {
      _baseValue = (_baseValue + rmsData.emg.sum()) / 2;

      _baseValueStreamController.add(_baseValue);
    });

    var startTime = DateTime.now();
    var progressStream = Stream.periodic(
        progressStreamUpdateFrequency,
        (_) => clampDouble(
            DateTime.now().difference(startTime).inMilliseconds /
                baseValueRecordingTime.inMilliseconds,
            0,
            1));

    emit(RecordingBaseValue(_baseValueStreamController.stream, progressStream));
    await Future.delayed(baseValueRecordingTime);

    _rmsStreamSubscription?.cancel();

    emit(ReadyToRecordMvc());
  }

  void _recordMvc(
      StartRecordingMvc event, Emitter<PropotionalControlState> emit) async {
    _rmsStreamSubscription?.cancel();
    var values = List<double>.empty(growable: true);

    _rmsStreamSubscription = event.rmsDataStream.listen((rmsData) {
      values.add(rmsData.emg.sum());

      var percentile = values.percentile(95);
      var topValues = values
        .where((value) => value >- percentile)
        .toList();

      _mvc = topValues.average();
      _mvcStreamController.add(_mvc);
    });

    var startTime = DateTime.now();
    var progressStream = Stream.periodic(
        progressStreamUpdateFrequency,
        (_) => clampDouble(
            DateTime.now().difference(startTime).inMilliseconds /
                mvcRecordingTime.inMilliseconds,
            0,
            1));

    emit(RecordingMvc(_mvcStreamController.stream, progressStream));
    await Future.delayed(mvcRecordingTime);

    _rmsStreamSubscription?.cancel();
    emit(ReadyToStart());
  }

  void _startProportionalControl(
      StartProportionalControl event, Emitter<PropotionalControlState> emit) {
    _rmsStreamSubscription?.cancel();

    var outputStream = event.rmsDataStream
        .map((rmsData) {
          var denominator = _mvc - _baseValue;

          if(denominator <= 0.0001) {
            return 0.0;
          }

          var normalized = (rmsData.emg.sum() - _baseValue) / denominator;
          return clampDouble(normalized, 0, 1);
        });

    emit(Active(outputStream, _baseValue, _mvc));
  }

  void _stopOperations(
      StopOperations event, Emitter<PropotionalControlState> emit) {
    _rmsStreamSubscription?.cancel();
    emit(Inactive());
  }

  @override
  Future<void> close() {
    _rmsStreamSubscription?.cancel();

    return super.close();
  }
}
