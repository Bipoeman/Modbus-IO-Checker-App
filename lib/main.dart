import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Modbus IO Checker',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'MODBUS IO Checker'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String state = "";
  List<BluetoothDevice> devices = [];
  void _incrementCounter() {
    setState(() {});
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    // Get current state
    FlutterBluetoothSerial.instance.state.then(
      (value) {
        log("${value.stringValue}");
      },
    );
    FlutterBluetoothSerial.instance.getBondedDevices().then((_devices) {
      setState(() {
        devices = _devices;
      });
    });
  }

  @override
  void dispose() {
    FlutterBluetoothSerial.instance.setPairingRequestHandler(null);
    // _collectingTask?.dispose();
    // _discoverableTimeoutTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Builder(builder: (context) {
          if (state == "loading") {
            return CircularProgressIndicator();
          }
          return RefreshIndicator(
            onRefresh: () async {
              Future.delayed(Duration(seconds: 2));
            },
            child: ListView.builder(
              itemCount: devices.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text("${devices[index].name}"),
                  subtitle: Text("${devices[index].address}"),
                  leading: devices[index].isConnected
                      ? Icon(Icons.bluetooth)
                      : Icon(Icons.bluetooth_disabled),
                  trailing: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text("Connect"),
                    onPressed: () {
                      // FlutterBluetoothSerial.instance.
                      BluetoothConnection.toAddress(devices[index].address)
                          .then(
                        (value) {
                          log("${value.toString()}");
                        },
                      );
                    },
                  ),
                );
              },
            ),
          );
        }),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {},
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
