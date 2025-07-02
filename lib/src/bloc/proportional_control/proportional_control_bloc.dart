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

  static const repetitionThresholds = [0.15, 0.85];

  final StreamController<double> _baseValueStreamController =
      StreamController<double>.broadcast();
  final StreamController<double> _mvcStreamController =
      StreamController<double>.broadcast();
  final StreamController<int> _repetitionsStreamController =
      StreamController<int>.broadcast();

  double _mvc = 0;
  double _baseValue = 0;

  StreamSubscription<RmsData>? _rmsStreamSubscription;
  StreamSubscription<double>? _outputStreamSubscription;

  ProportionalControlBloc() : super(Inactive()) {
    on<StartRecordingBaseValue>(_recordBaseValue);
    on<PrepareRecordingMvc>(_prepareMvc);
    on<StartRecordingMvc>(_recordMvc);
    on<PrepareProportionalControl>(_preparePropotionalControl);
    on<StartProportionalControl>(_startProportionalControl);
    on<StopOperations>(_stopOperations);
  }

  void _recordBaseValue(StartRecordingBaseValue event,
      Emitter<PropotionalControlState> emit) async {
    _clearSubscriptions();

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

    emit(PostBaseValue());
  }

  void _prepareMvc(
      PrepareRecordingMvc event, Emitter<PropotionalControlState> emit) {
    _clearSubscriptions();
    emit(ReadyToRecordMvc());
  }

  void _recordMvc(
      StartRecordingMvc event, Emitter<PropotionalControlState> emit) async {
    _clearSubscriptions();
    var values = List<double>.empty(growable: true);

    _rmsStreamSubscription = event.rmsDataStream.listen((rmsData) {
      values.add(rmsData.emg.sum());

      var percentile = values.percentile(95);
      var topValues = values.where((value) => value > -percentile).toList();

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
    emit(PostMvcValue());
  }

  void _preparePropotionalControl(
      PrepareProportionalControl event, Emitter<PropotionalControlState> emit) {
    _clearSubscriptions();
    emit(ReadyToStart());
  }

  void _startProportionalControl(
      StartProportionalControl event, Emitter<PropotionalControlState> emit) {
    _clearSubscriptions();

    var outputStream = event.rmsDataStream.map((rmsData) {
      var denominator = _mvc - _baseValue;

      if (denominator <= 0.0001) {
        return 0.0;
      }

      var normalized = (rmsData.emg.sum() - _baseValue) / denominator;
      return clampDouble(normalized, 0, 1);
    }).asBroadcastStream();

    var repetitions = 0;
    var repetitionPhaseUp = true;
    outputStream.listen((feedback) {
      if (repetitionPhaseUp && feedback >= repetitionThresholds[1]) {
        repetitionPhaseUp = false;
        return;
      }

      if (!repetitionPhaseUp && feedback <= repetitionThresholds[0]) {
        _repetitionsStreamController.add(++repetitions);
        repetitionPhaseUp = true;
        return;
      }
    });

    emit(Active(
        outputStream, _repetitionsStreamController.stream, _baseValue, _mvc));
  }

  void _stopOperations(
      StopOperations event, Emitter<PropotionalControlState> emit) {
    _clearSubscriptions();
    emit(Inactive());
  }

  @override
  Future<void> close() {
    _clearSubscriptions();
    return super.close();
  }

  void _clearSubscriptions() {
    _rmsStreamSubscription?.cancel();
    _outputStreamSubscription?.cancel();
  }
}
