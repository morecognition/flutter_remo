part of 'remo_file_bloc.dart';

@immutable
abstract class RemoFileEvent {}

class StartRecording extends RemoFileEvent {
  final Stream<RmsData> rmsDataStream;
  final Stream<ImuData> imuDataStream;

  StartRecording(this.rmsDataStream, this.imuDataStream);
}

class StartRecordingBiofeedback extends RemoFileEvent {
  final Stream<double> cyclicFeedbackStream;
  final Stream<int> repetitionsStream;
  final double baseValue;
  final double mvc;

  StartRecordingBiofeedback(this.cyclicFeedbackStream, this.repetitionsStream, this.baseValue, this.mvc);
}

class StopRecording extends RemoFileEvent {}

class SaveRecord extends RemoFileEvent {
  SaveRecord(this.fileName);
  final String fileName;
}

class OpenRmsRecord extends RemoFileEvent {
  OpenRmsRecord(this.filePath);
  final String filePath;
}

class DiscardRecord extends RemoFileEvent {}

class Reset extends RemoFileEvent {}
