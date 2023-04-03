part of 'remo_file_bloc.dart';

@immutable
abstract class RemoFileState {}

class RemoFileInitial extends RemoFileState {}

class RemoFileInitError extends RemoFileState {}

class RemoFileReady extends RemoFileState {}

class Recording extends RemoFileState {}

class RecordingComplete extends RemoFileState {
  RecordingComplete(this.file);
  final File file;
}

class RecordDiscarded extends RemoFileState {}

class RecordSaved extends RemoFileState {
  RecordSaved(this.file);
  final File file;
}
