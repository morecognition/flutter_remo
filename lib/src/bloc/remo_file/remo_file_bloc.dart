import 'dart:async';
import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:csv/csv.dart';
import 'package:flutter_remo/flutter_remo.dart';
import 'package:meta/meta.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:vector_math/vector_math.dart' show Vector3;

part 'remo_file_event.dart';
part 'remo_file_state.dart';

class RemoFileBloc extends Bloc<RemoFileEvent, RemoFileState> {
  RemoFileBloc() : super(RemoFileInitial()) {
    on<StartRecording>(_startRecording);
    on<StopRecording>(_stopRecording);
    on<DiscardRecord>(_discardRecord);
    on<SaveRecord>(_saveRecord);
    on<OpenRecord>(_openRecord);
    on<Reset>(_reset);
  }

  void _startRecording(
      StartRecording event, Emitter<RemoFileState> emit) async {
    tmpDirectory = await getTemporaryDirectory();
    Directory? directory;
    if (Platform.isAndroid) {
      if(await Directory(androidDownloadPath).exists()) {
        directory = Directory('$androidDownloadPath/$remorderFolderName');
      } else {
        directory = Directory('$androidAlternativeDownloadPath/$remorderFolderName');
      }
        
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
    emit(SavingRecord());

    final String newFilePath =
        '${externalStorageDirectory.path}/${event.fileName}.csv';
    File tmpFile = File(tmpFilePath);
    File newFile = await tmpFile.copy(newFilePath);
    emit(RecordSaved(newFile));
    emit(RemoFileReady());
  }

  void _openRecord(OpenRecord event, Emitter<RemoFileState> emit) async {
    var file = File(event.filePath);

    var data = const CsvToListConverter()
        .convert(await file.readAsString(), eol: '\n')
        .map((list) => list.cast<double>());

    var remoData = data.map<RemoData>(_csvLineToRemoData).toList();
    emit(RecordOpened(remoData, event.filePath));
  }

  void _reset(Reset event, Emitter<RemoFileState> emit) async {
    remoStreamSubscription.cancel();
    emit(RemoFileInitial());
  }

  RemoData _csvLineToRemoData(List<double> line) {
    return RemoData(
        emg: line.take(8).toList(),
        acceleration: Vector3(line[8], line[9], line[10]),
        angularVelocity: Vector3(line[11], line[12], line[13]),
        magneticField: Vector3(line[14], line[15], line[16]));
  }

  late Stream<RemoData> remoDataStream;
  late StreamSubscription<RemoData> remoStreamSubscription;
  late IOSink fileSink;
  late String tmpFilePath;
  late Directory tmpDirectory;
  late Directory externalStorageDirectory;

  static const String androidDownloadPath = '/storage/emulated/0/Downloads/';
  static const String androidAlternativeDownloadPath = '/storage/emulated/0/Download/';
  static const String remorderFolderName = 'remorder';
}
