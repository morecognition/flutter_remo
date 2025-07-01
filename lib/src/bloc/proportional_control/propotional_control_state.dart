part of 'proportional_control_bloc.dart';

abstract class PropotionalControlState {}

class Inactive extends PropotionalControlState {}

class RecordingBaseValue extends PropotionalControlState {
  RecordingBaseValue(this.baseValueStream, this.progressStream);
  final Stream<double> baseValueStream;
  final Stream<double> progressStream;
}

class ReadyToRecordMvc extends PropotionalControlState {}

class RecordingMvc extends PropotionalControlState {
  RecordingMvc(this.mvcStream, this.progressStream);
  final Stream<double> mvcStream;
  final Stream<double> progressStream;
}

class ReadyToStart extends PropotionalControlState {}

class Active extends PropotionalControlState {
  Active(this.cyclicFeedbackStream, this.baseValue, this.mvc);
  final Stream<double> cyclicFeedbackStream;
  final double baseValue;
  final double mvc;
}