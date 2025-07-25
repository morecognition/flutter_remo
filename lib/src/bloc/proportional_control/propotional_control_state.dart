part of 'proportional_control_bloc.dart';

abstract class PropotionalControlState {}

class Inactive extends PropotionalControlState {}

abstract class BaseValueProportionalControlState
    extends PropotionalControlState {
  BaseValueProportionalControlState(this.baseValueStream);
  final Stream<double> baseValueStream;
}

class ReadyToRecordBaseValue extends BaseValueProportionalControlState {
  ReadyToRecordBaseValue(super.baseValueStream);
}

class RecordingBaseValue extends BaseValueProportionalControlState {
  RecordingBaseValue(super.baseValueStream, this.progressStream);
  final Stream<double> progressStream;
}

class PostBaseValue extends PropotionalControlState {}

abstract class MvcProportionalControlState extends PropotionalControlState {
  MvcProportionalControlState(this.mvcStream);

  final Stream<double> mvcStream;
}

class ReadyToRecordMvc extends MvcProportionalControlState {
  ReadyToRecordMvc(super.mvcStream);
}

class RecordingMvc extends MvcProportionalControlState {
  RecordingMvc(super.mvcStream, this.progressStream);
  final Stream<double> progressStream;
}

class PostMvcValue extends PropotionalControlState {}

abstract class FeedbackProportionalControlState
    extends PropotionalControlState {
  FeedbackProportionalControlState(this.cyclicFeedbackStream);
  Stream<double> cyclicFeedbackStream;
}

class ReadyToStart extends FeedbackProportionalControlState {
  ReadyToStart(super.cyclicFeedbackStream);
}

class Active extends FeedbackProportionalControlState {
  Active(super.cyclicFeedbackStream, this.repetitionsStream, this.baseValue,
      this.mvc);
  final Stream<int> repetitionsStream;
  final double baseValue;
  final double mvc;
}
