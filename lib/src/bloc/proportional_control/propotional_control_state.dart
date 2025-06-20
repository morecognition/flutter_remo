part of 'proportional_control_bloc.dart';

abstract class PropotionalControlState {}

class Inactive extends PropotionalControlState {}
class RecordingBaseValue extends PropotionalControlState {}
class RecordingMvc extends PropotionalControlState {}

class Active extends PropotionalControlState {
  Active(this.cyclicFeedbackStream);
  final Stream<double> cyclicFeedbackStream;
}