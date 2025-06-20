part of 'proportional_control_bloc.dart';

abstract class ProportionalControlEvent {}

class StartRecordingBaseValue extends ProportionalControlEvent {
  StartRecordingBaseValue(this.rmsDataStream);
  final Stream<RmsData> rmsDataStream;
}

class StartRecordingMvc extends ProportionalControlEvent {
  StartRecordingMvc(this.rmsDataStream);
  final Stream<RmsData> rmsDataStream;
}

class StartProportionalControl extends ProportionalControlEvent {
  StartProportionalControl(this.rmsDataStream);
  final Stream<RmsData> rmsDataStream;
}

class StopOperations extends ProportionalControlEvent {}