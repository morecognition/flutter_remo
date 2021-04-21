part of 'remo_transmission_bloc.dart';

@immutable
abstract class RemoTransmissionState {}

class RemoTransmissionInitial extends RemoTransmissionState {}

class TransmissionStarted extends RemoTransmissionState {}

class NewDataReceived extends RemoTransmissionState {
  NewDataReceived(this.data);
  final String data;
}

class StoppingTransmission extends RemoTransmissionState {}
