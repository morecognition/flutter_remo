import 'dart:async';

import 'package:bloc/bloc.dart';

import 'bluetooth.dart';

part 'bluetooth_event.dart';
part 'bluetooth_state.dart';

/// Logic to discover nearby Bluetooth devices.
class BluetoothBloc extends Bloc<BluetoothEvent, BluetoothState> {
  @override
  Stream<BluetoothState> mapEventToState(
    BluetoothEvent event,
  ) async* {
    if (event is OnStartDiscovery) {
      yield* _startDiscovery(event);
    } else if (event is OnDiscoveredDevices) {
      yield* _discoveredDevices(event);
    }
  }

  /// Starts the discovery of devices.
  Stream<BluetoothState> _startDiscovery(OnStartDiscovery event) async* {
    _deviceNames.clear();
    _deviceAddresses.clear();
    yield DiscoveringDevices();
    try {
      _bluetooth.startDiscovery().listen((info) {
        _deviceNames.add(info.name);
        _deviceAddresses.add(info.address);
        add(OnDiscoveredDevices(_deviceNames, _deviceAddresses));
      });
    } catch (_) {
      yield DiscoveryError();
    }
  }

  /// Simply returns the list of discovered devices.
  Stream<BluetoothState> _discoveredDevices(OnDiscoveredDevices event) async* {
    yield DiscoveredDevices(event.deviceNames, event.deviceAddresses);
  }

  BluetoothBloc() : super(BluetoothInitial());

  /// The list of devices discovered so far.
  List<String> _deviceNames = <String>[];

  /// The list of devices discovered so far.
  List<String> _deviceAddresses = <String>[];

  /// All the actual bluetooth actions are handled here.
  final Bluetooth _bluetooth = Bluetooth();
}
