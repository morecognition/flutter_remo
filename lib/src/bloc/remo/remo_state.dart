part of 'remo_bloc.dart';

abstract class RemoState {}

/// Initial and final state.
class Disconnected extends RemoState {}

/// Connection procedure has been started.
class Connecting extends RemoState {}

/// Successful connection to the device.
class Connected extends RemoState {}

/// Successful connection to the device.
class ConnectionError extends RemoState {}

/// Disconnection procedure has been started.
class Disconnecting extends RemoState {}

class StartingTransmission extends RemoState {}

class TransmissionStarted extends RemoState {
  TransmissionStarted(this.rmsDataStream, this.imuDataStream);
  final Stream<RmsData> rmsDataStream;
  final Stream<ImuData> imuDataStream;
}

class StoppingTransmission extends RemoState {}

class TransmissionStopped extends RemoState {}
