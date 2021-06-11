part of 'remo_transmission_bloc.dart';

@immutable
abstract class RemoTransmissionEvent {}

class OnStartTransmission extends RemoTransmissionEvent {}

class OnStopTransmission extends RemoTransmissionEvent {}
