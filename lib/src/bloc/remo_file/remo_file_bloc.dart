import 'dart:async';
import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:flutter_remo/flutter_remo.dart';
import 'package:meta/meta.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

part 'remo_file_event.dart';
part 'remo_file_state.dart';

class RemoFileBloc extends Bloc<RemoFileEvent, RemoFileState> {
  RemoFileBloc() : super(RemoFileInitial()) {
    on<StartRecording>(_startRecording);
    on<StopRecording>(_stopRecording);
    on<DiscardRecord>(_discardRecord);
    on<SaveRecord>(_saveRecord);
    on<Reset>(_reset);
  }

  void _startRecording(
      StartRecording event, Emitter<RemoFileState> emit) async {
    tmpDirectory = await getTemporaryDirectory();
    Directory? directory;
    if (Platform.isAndroid) {
      directory = Directory('$androidDocumentsPath/$remorderFolderName');
      if(!await directory.exists()) {
        await directory.create();
      }
    } else if (Platform.isIOS) {
      directory = await getApplicationDocumentsDirectory();
    }
    if (directory != null) {
      externalStorageDirectory = directory;
      var uuid = const Uuid();
      var tmpFileName = uuid.v4();
      tmpFilePath = '${tmpDirectory.path}/$tmpFileName.csv';
    }
    remoDataStream = event.remoDataStream;

    File tmpCsvFile = File(tmpFilePath);
    fileSink = tmpCsvFile.openWrite();
    remoStreamSubscription = remoDataStream.listen(
      (remoData) {
        fileSink.write(remoData.toCsvString());
      },
    );
    emit(Recording());
  }

  void _stopRecording(StopRecording event, Emitter<RemoFileState> emit) {
    remoStreamSubscription.cancel();
    fileSink.close();
    emit(RecordingComplete(File(tmpFilePath)));
  }

  void _discardRecord(DiscardRecord event, Emitter<RemoFileState> emit) {
    emit(RecordDiscarded());
    emit(RemoFileReady());
  }

  void _saveRecord(SaveRecord event, Emitter<RemoFileState> emit) async {
    final String newFilePath =
        '${externalStorageDirectory.path}/${event.fileName}.csv';
    File tmpFile = File(tmpFilePath);
    File newFile = await tmpFile.copy(newFilePath);
    emit(RecordSaved(newFile));
    emit(RemoFileReady());
  }

  void _reset(Reset event, Emitter<RemoFileState> emit) async {
    remoStreamSubscription.cancel();
    emit(RemoFileInitial());
  }

  late Stream<RemoData> remoDataStream;
  late StreamSubscription<RemoData> remoStreamSubscription;
  late IOSink fileSink;
  late String tmpFilePath;
  late Directory tmpDirectory;
  late Directory externalStorageDirectory;

  static const String androidDocumentsPath = '/storage/emulated/0/Documents/';
  static const String remorderFolderName = 'remorder';
}
