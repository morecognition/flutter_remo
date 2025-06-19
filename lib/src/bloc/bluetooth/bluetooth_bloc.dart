import 'package:bloc/bloc.dart';
import 'bluetooth.dart';

part 'bluetooth_event.dart';

part 'bluetooth_state.dart';

/// Logic to discover nearby Bluetooth devices.
class BluetoothBloc extends Bloc<BluetoothEvent, BluetoothState> {
  /// Starts the discovery of devices.
  void _startDiscovery(
      OnStartDiscovery event, Emitter<BluetoothState> emit) async {
    _deviceNames.clear();
    _deviceAddresses.clear();
    emit(DiscoveringDevices());
    try {
      _bluetooth.startDiscovery().listen(
        (info) {
          _deviceNames.add(info.name);
          _deviceAddresses.add(info.address);
        },
        onDone: () => add(
          OnDiscoveredDevices(_deviceNames, _deviceAddresses),
        ),
      );
    } on Exception {
      emit(DiscoveryError());
    }
  }

  /// Simply returns the list of discovered devices.
  void _discoveredDevices(
      OnDiscoveredDevices event, Emitter<BluetoothState> emit) async {
    emit(DiscoveredDevices(event.deviceNames, event.deviceAddresses));
  }

  void _reset(OnReset event, Emitter<BluetoothState> emit) async {
    emit(BluetoothInitial());
  }

  BluetoothBloc() : super(BluetoothInitial()) {
    on<OnReset>(_reset);
    on<OnStartDiscovery>(_startDiscovery);
    on<OnDiscoveredDevices>(_discoveredDevices);
  }

  /// The list of devices discovered so far.
  final List<String> _deviceNames = <String>[];

  /// The list of devices discovered so far.
  final List<String> _deviceAddresses = <String>[];

  /// All the actual bluetooth actions are handled here.
  final Bluetooth _bluetooth = Bluetooth();
}
