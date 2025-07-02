part of 'proportional_control_bloc.dart';

abstract class PropotionalControlState {}

class Inactive extends PropotionalControlState {}

class RecordingBaseValue extends PropotionalControlState {
  RecordingBaseValue(this.baseValueStream, this.progressStream);
  final Stream<double> baseValueStream;
  final Stream<double> progressStream;
}

class PostBaseValue extends PropotionalControlState {}

class ReadyToRecordMvc extends PropotionalControlState {}

class RecordingMvc extends PropotionalControlState {
  RecordingMvc(this.mvcStream, this.progressStream);
  final Stream<double> mvcStream;
  final Stream<double> progressStream;
}

class PostMvcValue extends PropotionalControlState {}

class ReadyToStart extends PropotionalControlState {}

class Active extends PropotionalControlState {
  Active(this.cyclicFeedbackStream, this.repetitionsStream, this.baseValue, this.mvc);
  final Stream<double> cyclicFeedbackStream;
  final Stream<int> repetitionsStream;
  final double baseValue;
  final double mvc;
}