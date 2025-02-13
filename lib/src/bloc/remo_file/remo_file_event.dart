part of 'remo_file_bloc.dart';

@immutable
abstract class RemoFileEvent {}

class StartRecording extends RemoFileEvent {
  final Stream<RemoData> remoDataStream;

  StartRecording(this.remoDataStream);
}

class StopRecording extends RemoFileEvent {}

class SaveRecord extends RemoFileEvent {
  SaveRecord(this.fileName);
  final String fileName;
}

class OpenRecord extends RemoFileEvent {
  OpenRecord(this.filePath);
  final String filePath;
}

class DiscardRecord extends RemoFileEvent {}

class Reset extends RemoFileEvent {}
