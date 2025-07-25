part of 'proportional_control_bloc.dart';

abstract class ProportionalControlEvent {}

abstract class ActiveProportionalControlEvent extends ProportionalControlEvent {

}

class PrepareRecordingBaseValue extends ActiveProportionalControlEvent {
  PrepareRecordingBaseValue(this.rmsDataStream);
  final Stream<RmsData> rmsDataStream;
}

class StartRecordingBaseValue extends ActiveProportionalControlEvent {
  StartRecordingBaseValue(this.rmsDataStream);
  final Stream<RmsData> rmsDataStream;
}

class PrepareRecordingMvc extends ActiveProportionalControlEvent {
  PrepareRecordingMvc(this.rmsDataStream);
  final Stream<RmsData> rmsDataStream;
}

class StartRecordingMvc extends ActiveProportionalControlEvent {
  StartRecordingMvc(this.rmsDataStream);
  final Stream<RmsData> rmsDataStream;
}

class PrepareProportionalControl extends ActiveProportionalControlEvent {
  PrepareProportionalControl(this.rmsDataStream);
  final Stream<RmsData> rmsDataStream;
}

class StartProportionalControl extends ActiveProportionalControlEvent {
  StartProportionalControl(this.rmsDataStream);
  final Stream<RmsData> rmsDataStream;
}

class StopOperations extends ProportionalControlEvent {}
