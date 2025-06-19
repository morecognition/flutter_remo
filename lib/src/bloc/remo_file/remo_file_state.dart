part of 'remo_file_bloc.dart';

@immutable
abstract class RemoFileState {}

class RemoFileInitial extends RemoFileState {}

class RemoFileInitError extends RemoFileState {}

class RemoFileReady extends RemoFileState {}

class Recording extends RemoFileState {}

class RecordingComplete extends RemoFileState {
  RecordingComplete(this.rmsFile, this.imuFile);
  final File rmsFile;
  final File imuFile;
}

class RecordDiscarded extends RemoFileState {}

class SavingRecord extends RemoFileState {}

class RecordSaved extends RemoFileState {
  RecordSaved(this.rmsFile, this.imuFile);
  final File rmsFile;
  final File imuFile;
}

class RmsRecordOpened extends RemoFileState {
  RmsRecordOpened(this.rmsData, this.filePath);
  final List<RmsData> rmsData;
  final String filePath;
}