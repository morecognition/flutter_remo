import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_remo/flutter_remo.dart';
import 'package:permission_handler/permission_handler.dart';

class WearRemoStep extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("1/4"),
      ),
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Wear Remo and turn it on"),
            Container(
              padding: EdgeInsets.all(10),
              child: Image.asset(
                'assets/wear_remo.png',
                package: 'flutter_remo',
              ),
            ),
            SizedBox(height: 20),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TurnOnBluetoothStep(),
                  ),
                );
              },
              style: TextButton.styleFrom(
                  backgroundColor: Theme.of(context).accentColor),
              child: Text('NEXT'),
            ),
          ],
        ),
      ),
    );
  }
}

class TurnOnBluetoothStep extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("2/4"),
      ),
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Turn on bluetooth on your device'),
            Image.asset(
              'assets/bluetooth.png',
              package: 'flutter_remo',
            ),
            SizedBox(height: 20),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BluetoothStep(),
                  ),
                );
              },
              style: TextButton.styleFrom(
                  backgroundColor: Theme.of(context).accentColor),
              child: Text('NEXT'),
            ),
          ],
        ),
      ),
    );
  }
}

class BluetoothStep extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("3/4"),
      ),
      body: BlocBuilder<BluetoothBloc, BluetoothState>(
        builder: (context, bluetoothState) {
          late Widget _widget;
          if (bluetoothState is DiscoveredDevices) {
            _widget = RefreshIndicator(
              onRefresh: () async {
                // When the widget is scrolled down a refresh event is sent to the bloc.
                BlocProvider.of<BluetoothBloc>(context).add(OnStartDiscovery());
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children:
                    List.generate(bluetoothState.deviceNames.length, (index) {
                  return ListTile(
                    title: Text(bluetoothState.deviceNames[index]),
                    subtitle: Text(bluetoothState.deviceAddresses[index]),
                    onTap: () {
                      // When the text button is pressed, tell the block which device it has to connect to.
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RemoConnectionStep(
                              bluetoothAddress:
                                  bluetoothState.deviceAddresses[index]),
                        ),
                      );
                    },
                  );
                }),
              ),
            );
          } else if (bluetoothState is DiscoveringDevices) {
            _widget = const Center(child: CircularProgressIndicator());
          } else if (bluetoothState is DiscoveryError) {
            _widget = const Center(child: Text("Discovery error."));
          } else if (bluetoothState is BluetoothInitial) {
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
      ),
    );
  }
}

class RemoConnectionStep extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('')),
      body: ,
    );
  }

  const RemoConnectionStep({Key? key, required this.bluetoothAddress})
      : super(key: key);
  final String bluetoothAddress;
}
