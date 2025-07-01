part of 'proportional_control_bloc.dart';

abstract class ProportionalControlEvent {}

class StartRecordingBaseValue extends ProportionalControlEvent {
  StartRecordingBaseValue(this.rmsDataStream);
  final Stream<RmsData> rmsDataStream;
}

class PrepareRecordingMvc extends ProportionalControlEvent {}

class StartRecordingMvc extends ProportionalControlEvent {
  StartRecordingMvc(this.rmsDataStream);
  final Stream<RmsData> rmsDataStream;
}

class PrepareProportionalControl extends ProportionalControlEvent {}

class StartProportionalControl extends ProportionalControlEvent {
  StartProportionalControl(this.rmsDataStream);
  final Stream<RmsData> rmsDataStream;
}

class StopOperations extends ProportionalControlEvent {}