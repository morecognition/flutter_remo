import 'dart:async';

import 'package:bloc/bloc.dart';

part 'remo_connection_event.dart';
part 'remo_connection_state.dart';

/// Allows the pairing and connection with a Remo device
class RemoConnectionBloc
    extends Bloc<RemoConnectionEvent, RemoConnectionState> {
  RemoConnectionBloc() : super(Disconnected("Default", "Default"));

  @override
  Stream<RemoConnectionState> mapEventToState(
    RemoConnectionEvent event,
  ) async* {
    if (event is OnConnectDevice) {
      yield* _startConnecting(event);
    } else if (event is OnDisconnectDevice) {
      yield* _startDisconnecting(event);
    } else if (event is OnStartRecording) {
      yield* _startRecording(event);
    } else if (event is OnSelectDevice) {
      yield* _selectDevice(event);
    }
  }

  /// Connects to a specific devices. The name is given by the select device event.
  Stream<RemoConnectionState> _startConnecting(OnConnectDevice event) async* {
    yield Connecting(
      _bluetooth.selectedDeviceInfos.name,
      _bluetooth.selectedDeviceInfos.address,
    );
    try {
      await for (ConnectionStates state in _bluetooth.startConnection()) {
        switch (state) {
          case ConnectionStates.disconnected:
            yield Disconnected(
              _bluetooth.selectedDeviceInfos.name,
              _bluetooth.selectedDeviceInfos.address,
            );
            break;
          case ConnectionStates.connected:
            yield Connected(
              _bluetooth.selectedDeviceInfos.name,
              _bluetooth.selectedDeviceInfos.address,
            );
            break;
          case ConnectionStates.connecting:
            yield Connecting(
              _bluetooth.selectedDeviceInfos.name,
              _bluetooth.selectedDeviceInfos.address,
            );
            break;
          case ConnectionStates.disconnecting:
            Disconnecting(
              _bluetooth.selectedDeviceInfos.name,
              _bluetooth.selectedDeviceInfos.address,
            );
            break;
          case ConnectionStates.error:
            yield ConnectionError(
              _bluetooth.selectedDeviceInfos.name,
              _bluetooth.selectedDeviceInfos.address,
            );
            break;
        }
      }
    } on Exception {
      // TODO: check what specific exceptions can occur.
      yield ConnectionError(
        _bluetooth.selectedDeviceInfos.name,
        _bluetooth.selectedDeviceInfos.address,
      );
    }
  }

  /// Disconnects the device.
  Stream<RemoConnectionState> _startDisconnecting(
      OnDisconnectDevice event) async* {
    yield Disconnecting(
      _bluetooth.selectedDeviceInfos.name,
      _bluetooth.selectedDeviceInfos.address,
    );
    try {
      await for (ConnectionStates state in _bluetooth.startDisconnection()) {
        switch (state) {
          case ConnectionStates.disconnected:
            yield Disconnected(
              _bluetooth.selectedDeviceInfos.name,
              _bluetooth.selectedDeviceInfos.address,
            );
            break;
          case ConnectionStates.connected:
            yield Connected(
              _bluetooth.selectedDeviceInfos.name,
              _bluetooth.selectedDeviceInfos.address,
            );
            break;
          case ConnectionStates.connecting:
            yield Connecting(
              _bluetooth.selectedDeviceInfos.name,
              _bluetooth.selectedDeviceInfos.address,
            );
            break;
          case ConnectionStates.disconnecting:
            Disconnecting(
              _bluetooth.selectedDeviceInfos.name,
              _bluetooth.selectedDeviceInfos.address,
            );
            break;
          case ConnectionStates.error:
            yield ConnectionError(
              _bluetooth.selectedDeviceInfos.name,
              _bluetooth.selectedDeviceInfos.address,
            );
            break;
        }
      }
    } on ArgumentError {
      yield ConnectionError(
        _bluetooth.selectedDeviceInfos.name,
        _bluetooth.selectedDeviceInfos.address,
      );
    }
  }

  /// Sends a signal to the device to start the data collection.
  Stream<RemoConnectionState> _startRecording(OnStartRecording event) async* {
    // TODO
  }

  Stream<RemoConnectionState> _selectDevice(OnSelectDevice event) async* {
    _bluetooth.selectedDeviceInfos =
        DeviceInfos(event.deviceName, event.deviceAddress);
    yield Disconnected(event.deviceName, event.deviceAddress);
  }

  /// All the actual bluetooth actions are handled here.
  final Bluetooth _bluetooth = Bluetooth();
}
