import 'dart:async';
import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:csv/csv.dart';
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
    on<OpenRmsRecord>(_openRmsRecord);
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
      var rmsTmpFileName = uuid.v4();
      var imuTmpFileName = uuid.v4();
      rmsTmpFilePath = '${tmpDirectory.path}/$rmsTmpFileName.csv';
      imuTmpFilePath = '${tmpDirectory.path}/$imuTmpFileName.csv';
    }
    rmsDataStream = event.rmsDataStream;
    imuDataStream = event.imuDataStream;

    File rmsTmpCsvFile = File(rmsTmpFilePath);
    File imuTmpCsvFile = File(imuTmpFilePath);
    
    rmsFileSink = rmsTmpCsvFile.openWrite();
    rmsStreamSubscription = rmsDataStream.listen(
      (rmsData) {
        rmsFileSink.write(rmsData.toCsvString());
      },
    );

    imuFileSink = imuTmpCsvFile.openWrite();
    imuStreamSubscription = imuDataStream.listen(
          (imuData) {
        imuFileSink.write(imuData.toCsvString());
      },
    );
    
    emit(Recording());
  }

  void _stopRecording(StopRecording event, Emitter<RemoFileState> emit) {
    rmsStreamSubscription.cancel();
    imuStreamSubscription.cancel();
    
    rmsFileSink.close();
    imuFileSink.close();
    
    emit(RecordingComplete(File(rmsTmpFilePath), File(imuTmpFilePath)));
  }

  void _discardRecord(DiscardRecord event, Emitter<RemoFileState> emit) {
    emit(RecordDiscarded());
    emit(RemoFileReady());
  }

  void _saveRecord(SaveRecord event, Emitter<RemoFileState> emit) async {
    emit(SavingRecord());

    final String rmsNewFilePath = '${externalStorageDirectory.path}/${event.fileName}_$rmsFileSuffix.csv';
    final String imuNewFilePath = '${externalStorageDirectory.path}/${event.fileName}_$imuFileSuffix.csv';
    
    File rmsTmpFile = File(rmsTmpFilePath);
    File rmsNewFile = await rmsTmpFile.copy(rmsNewFilePath);

    File imuTmpFile = File(imuTmpFilePath);
    File imuNewFile = await imuTmpFile.copy(imuNewFilePath);
    
    emit(RecordSaved(rmsNewFile, imuNewFile));
    emit(RemoFileReady());
  }

  void _openRmsRecord(OpenRmsRecord event, Emitter<RemoFileState> emit) async {
    var file = File(event.filePath);

    var data = const CsvToListConverter()
        .convert(await file.readAsString(), eol: '\n')
        .map((list) => list.cast<double>());

    var rmsData = data.map<RmsData>(_csvLineToRmsData).toList();
    emit(RmsRecordOpened(rmsData, event.filePath));
  }

  void _reset(Reset event, Emitter<RemoFileState> emit) async {
    rmsStreamSubscription.cancel();
    emit(RemoFileInitial());
  }

  RmsData _csvLineToRmsData(List<double> line) {
    return RmsData(
        emg: line.take(8).toList(),
        timestamp: line[8]
    );
  }

  late Stream<RmsData> rmsDataStream;
  late StreamSubscription<RmsData> rmsStreamSubscription;

  late Stream<ImuData> imuDataStream;
  late StreamSubscription<ImuData> imuStreamSubscription;

  late IOSink rmsFileSink;
  late IOSink imuFileSink;
  late String rmsTmpFilePath;
  late String imuTmpFilePath;
  late Directory tmpDirectory;
  late Directory externalStorageDirectory;

  static const String androidDownloadPath = '/storage/emulated/0/Downloads/';
  static const String androidAlternativeDownloadPath = '/storage/emulated/0/Download/';
  static const String remorderFolderName = 'remorder';
  static const String rmsFileSuffix = 'rms';
  static const String imuFileSuffix = 'imu';
}
