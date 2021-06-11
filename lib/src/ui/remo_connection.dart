import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_remo/flutter_remo.dart';
import 'package:permission_handler/permission_handler.dart';

/// The procedure to pair remo with the device.
class RemoConnection extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _RemoConnectionState();
}

class _RemoConnectionState extends State<RemoConnection> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Connecting Remo"),
      ),
      body: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) => BluetoothBloc(),
          ),
          BlocProvider(
            create: (context) => RemoConnectionBloc(),
          ),
        ],
        child: Stepper(
          type: StepperType.horizontal,
          onStepContinue: () {
            // Go to the next step up to the last one.
            if ((_currentStep + 1) < 4) {
              setState(() {
                _stepStates[_currentStep] = StepState.complete;
                _stepStates[++_currentStep] = StepState.editing;
              });
              // In the last step simply go to the next page.
            } else {
              Navigator.pop(context);
            }
          },
          onStepCancel: () {
            // On cancel go to the previous step down to the first one.
            if ((_currentStep - 1) >= 0) {
              setState(
                () {
                  _stepStates[_currentStep] = StepState.complete;
                  _stepStates[--_currentStep] = StepState.editing;
                },
              );
              // In the first step just go to the previous page.
            } else {
              Navigator.pop(context);
            }
          },
          onStepTapped: (index) {
            // when the step is tapped move to that step.
            setState(() {
              _stepStates[_currentStep] = StepState.complete;
              _currentStep = index;
              _stepStates[_currentStep] = StepState.editing;
            });
          },
          currentStep: _currentStep,
          steps: [
            Step(
              title: Text(''),
              isActive: true,
              state: _stepStates[0],
              content: SizedBox(
                height: MediaQuery.of(context).size.height * 0.6,
                child: _WearRemoStep(),
              ),
            ),
            Step(
              title: Text(''),
              isActive: true,
              state: _stepStates[1],
              content: SizedBox(
                height: MediaQuery.of(context).size.height * 0.6,
                child: _TurnOnBluetoothStep(),
              ),
            ),
            Step(
              title: Text(''),
              isActive: true,
              state: _stepStates[2],
              content: SizedBox(
                height: MediaQuery.of(context).size.height * 0.6,
                child: _BluetoothStep(),
              ),
            ),
            Step(
              title: Text(''),
              isActive: true,
              state: _stepStates[3],
              content: SizedBox(
                height: MediaQuery.of(context).size.height * 0.6,
                child: _ConnectRemoStep(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<StepState> _stepStates = [
    StepState.editing,
    StepState.indexed,
    StepState.indexed,
    StepState.indexed,
  ];

  /// Stores an index to the currently visualized widget.
  int _currentStep = 0;
}

class _WearRemoStep extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text("Wear Remo and turn it on"),
        Container(
          padding: EdgeInsets.all(10),
          child: Image.asset('assets/wear_remo.png'),
        ),
      ],
    );
  }
}

class _BluetoothStep extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _BluetoothState();
  }
}

class _BluetoothState extends State<_BluetoothStep> {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BluetoothBloc, BluetoothState>(
      builder: (context, state) {
        Widget _widget;
        if (state is DiscoveredDevices) {
          _widget = RefreshIndicator(
            onRefresh: () async {
              // When the widget is scrolled down a refresh event is sent to the bloc.
              BlocProvider.of<BluetoothBloc>(context).add(OnStartDiscovery());
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: List.generate(
                state.deviceNames.length,
                (index) {
                  return ListTile(
                    title: Text(state.deviceNames[index]),
                    subtitle: Text(state.deviceAddresses[index]),
                    onTap: () {
                      // When the text button is pressed, tell the block which device it has to connect to.
                      BlocProvider.of<RemoConnectionBloc>(context).add(
                        OnSelectDevice(
                          state.deviceNames[index],
                          state.deviceAddresses[index],
                        ),
                      );
                      // And mark it as selected.
                      setState(() {
                        _selectedIndex = index;
                      });
                    },
                    selected: () {
                      if (_selectedIndex == index) {
                        return true;
                      } else {
                        return false;
                      }
                    }(),
                    selectedTileColor: Theme.of(context).accentColor,
                  );
                },
              ),
            ),
          );
        } else if (state is DiscoveringDevices) {
          _widget = const Center(child: CircularProgressIndicator());
        } else if (state is DiscoveryError) {
          _widget = const Center(child: Text("Discovery error."));
        } else if (state is BluetoothInitial) {
          _widget = Center(
            child: MaterialButton(
              color: Theme.of(context).accentColor,
              shape: CircleBorder(),
              child: Padding(
                padding: EdgeInsets.all(30),
                child: Text("Discover"),
              ),
              onPressed: () async {
                if (await Permission.locationWhenInUse.request().isGranted) {
                  BlocProvider.of<BluetoothBloc>(context)
                      .add(OnStartDiscovery());
                }
              },
            ),
          );
        }
        return _widget;
      },
    );
  }

  int _selectedIndex = 0;
}

class _ConnectRemoStep extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset('assets/wear_remo.png'),
        BlocBuilder<RemoConnectionBloc, RemoConnectionState>(
          builder: (context, state) {
            Widget widget;
            if (state is Connected) {
              widget = Column(
                children: [
                  Text(state.deviceName),
                  TextButton(
                    style: TextButton.styleFrom(
                        backgroundColor: Theme.of(context).accentColor),
                    onPressed: () {
                      BlocProvider.of<RemoConnectionBloc>(context)
                          .add(OnDisconnectDevice());
                    },
                    child: Text("Disconnect"),
                  ),
                ],
              );
            } else if (state is Disconnected) {
              widget = Column(
                children: [
                  Text(state.deviceName),
                  FlatButton(
                    color: Theme.of(context).accentColor,
                    onPressed: () {
                      BlocProvider.of<RemoConnectionBloc>(context)
                          .add(OnConnectDevice());
                    },
                    child: Text("Connect"),
                  ),
                ],
              );
            } else if (state is Connecting || state is Disconnecting) {
              widget = Column(
                children: [
                  Text(state.deviceName),
                  CircularProgressIndicator(),
                ],
              );
            }
            return widget;
          },
        ),
      ],
    );
  }
}

class _TurnOnBluetoothStep extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('Turn on bluetooth on your device'),
        Image.asset('assets/bluetooth.png'),
      ],
    );
  }
}
