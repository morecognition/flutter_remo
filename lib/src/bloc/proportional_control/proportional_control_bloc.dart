import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:flutter_remo/flutter_remo.dart';
import 'package:flutter_remo/src/utils/list_extensions.dart';

part 'proportional_control_event.dart';
part 'propotional_control_state.dart';

class ProportionalControlBloc
    extends Bloc<ProportionalControlEvent, PropotionalControlState> {
  static const baseValueRecordingTime = Duration(seconds: 5);
  static const mvcRecordingTime = Duration(seconds: 3);

  late Stream<double> outputStream;

  final List<double> _mvcs = List.filled(8, 0);
  final List<double> _baseValues = List.filled(8, 0);

  StreamSubscription<RmsData>? _rmsStreamSubscription;

  ProportionalControlBloc() : super(Inactive()) {
    on<StartRecordingBaseValue>(_recordBaseValue);
    on<StartRecordingMvc>(_recordMvc);
    on<StartProportionalControl>(_startProportionalControl);
    on<StopOperations>(_stopOperations);
  }

  void _recordBaseValue(StartRecordingBaseValue event,
      Emitter<PropotionalControlState> emit) async {
    emit(RecordingBaseValue());

    _rmsStreamSubscription?.cancel();
    _baseValues.fillRange(0, _baseValues.length, double.infinity);

    _rmsStreamSubscription = event.rmsDataStream
        .listen((rmsData) => _baseValues.setAverage(rmsData.emg));

    await Future.delayed(baseValueRecordingTime);

    _rmsStreamSubscription?.cancel();

    add(StartRecordingMvc(event.rmsDataStream));
  }

  void _recordMvc(
      StartRecordingMvc event, Emitter<PropotionalControlState> emit) async {
    emit(RecordingMvc());

    _rmsStreamSubscription?.cancel();
    _mvcs.fillRange(0, _mvcs.length, 0);

    _rmsStreamSubscription =
        event.rmsDataStream.listen((rmsData) => _mvcs.setAverage(rmsData.emg));

    await Future.delayed(mvcRecordingTime);

    _rmsStreamSubscription?.cancel();

    add(StartProportionalControl(event.rmsDataStream));
  }

  void _startProportionalControl(StartProportionalControl event,
      Emitter<PropotionalControlState> emit) {
    _rmsStreamSubscription?.cancel();

    outputStream = event.rmsDataStream
        .map((rmsData) => rmsData.emg.divide(_mvcs).average())
        .asBroadcastStream();

    emit(Active(outputStream));
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