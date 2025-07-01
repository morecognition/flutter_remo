part of 'remo_file_bloc.dart';

@immutable
abstract class RemoFileState {}

class RemoFileInitial extends RemoFileState {}

class RemoFileInitError extends RemoFileState {}

class RemoFileReady extends RemoFileState {}

class Recording extends RemoFileState {}

class RecordingComplete extends RemoFileState {}

class RecordDiscarded extends RemoFileState {}

class SavingRecord extends RemoFileState {}

class RecordSaved extends RemoFileState {}

class RmsRecordOpened extends RemoFileState {
  RmsRecordOpened(this.rmsData, this.filePath);
  final List<RmsData> rmsData;
  final String filePath;
}