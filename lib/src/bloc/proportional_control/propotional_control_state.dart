part of 'proportional_control_bloc.dart';

abstract class PropotionalControlState {}

class Inactive extends PropotionalControlState {}

class RecordingBaseValue extends PropotionalControlState {
  RecordingBaseValue(this.baseValueStream, this.progressStream);
  final Stream<double> baseValueStream;
  final Stream<double> progressStream;
}

class RecordingMvc extends PropotionalControlState {
  RecordingMvc(this.mvcStream, this.progressStream);
  final Stream<double> mvcStream;
  final Stream<double> progressStream;
}

class Active extends PropotionalControlState {
  Active(this.cyclicFeedbackStream);
  final Stream<double> cyclicFeedbackStream;
}