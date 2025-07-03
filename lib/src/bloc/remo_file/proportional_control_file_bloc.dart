import 'dart:async';
import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:flutter_remo/flutter_remo.dart';
import 'package:flutter_remo/src/utils/file_utils.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class ProportionalControlFileBloc extends Bloc<RemoFileEvent, RemoFileState> {
  late StreamSubscription<double> biofeedbackStreamSubscription;
  late StreamSubscription<int> repetitionsStreamSubscription;

  late IOSink fileSink;
  late String tmpFilePath;
  late Directory tmpDirectory;
  late Directory externalStorageDirectory;

  int lastRepetitions = 0;

  static const String fileSuffix = 'feedback';

  ProportionalControlFileBloc() : super(RemoFileInitial()) {
    on<StartRecordingBiofeedback>(_startRecording);
    on<StopRecording>(_stopRecording);
    on<DiscardRecord>(_discardRecord);
    on<SaveRecord>(_saveRecord);
    on<Reset>(_reset);
  }

  void _startRecording(
      StartRecordingBiofeedback event, Emitter<RemoFileState> emit) async {
    lastRepetitions = 0;
    tmpDirectory = await getTemporaryDirectory();
    var directory = await FileUtils.getDownloadDirectory();

    if (directory != null) {
      externalStorageDirectory = directory;
      var uuid = const Uuid();
      var tmpFileName = uuid.v4();
      tmpFilePath = '${tmpDirectory.path}/$tmpFileName.csv';
    }

    var tmpCsvFile = File(tmpFilePath);
    fileSink = tmpCsvFile.openWrite();

    _writeHeaders(fileSink, event.baseValue, event.mvc);
    biofeedbackStreamSubscription = event.cyclicFeedbackStream
        .listen((feedback) => fileSink.write("$feedback,$lastRepetitions\n"));

    repetitionsStreamSubscription = event.repetitionsStream
        .listen((repetitions) => lastRepetitions = repetitions);

    emit(Recording());
  }

  void _stopRecording(StopRecording event, Emitter<RemoFileState> emit) {
    biofeedbackStreamSubscription.cancel();
    fileSink.close();

    emit(RecordingComplete());
  }

  void _discardRecord(DiscardRecord event, Emitter<RemoFileState> emit) {
    emit(RecordDiscarded());
    emit(RemoFileReady());
  }

  void _saveRecord(SaveRecord event, Emitter<RemoFileState> emit) async {
    emit(SavingRecord());

    final String newFilePath =
        '${externalStorageDirectory.path}/${event.fileName}_$fileSuffix.csv';

    var tmpFile = File(tmpFilePath);
    await tmpFile.copy(newFilePath);

    emit(RecordSaved());
    emit(RemoFileReady());
  }

  void _reset(Reset event, Emitter<RemoFileState> emit) async {
    biofeedbackStreamSubscription.cancel();
    emit(RemoFileInitial());
  }

  void _writeHeaders(IOSink fileSink, double baseValue, double mvc) {
    fileSink.write("File version,Base value,MVC\n");
    fileSink.write("1.0,$baseValue,$mvc\n");
    fileSink.write("\n");
    fileSink.write("Biofeedback,Repetitions\n");
  }
}
