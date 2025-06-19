part of 'remo_file_bloc.dart';

@immutable
abstract class RemoFileEvent {}

class StartRecording extends RemoFileEvent {
  final Stream<RmsData> rmsDataStream;
  final Stream<ImuData> imuDataStream;

  StartRecording(this.rmsDataStream, this.imuDataStream);
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
