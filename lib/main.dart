import 'dart:convert';
import 'dart:developer';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:modbus_io_checker/controllers/bloc/bluetooth_receive_bloc.dart';
import 'package:sizer/sizer.dart';

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
  TextEditingController nameTextController = TextEditingController();
  TextEditingController addressTextController = TextEditingController();
  TextEditingController modeTextController = TextEditingController();
  String getDataState = "";
  List<BluetoothDevice> devices = [];

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    // Get current state
    FlutterBluetoothSerial.instance.state.then(
      (value) {
        log(value.stringValue);
      },
    );
    FlutterBluetoothSerial.instance.getBondedDevices().then((getDevices) {
      setState(() {
        devices = getDevices;
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
    return Sizer(builder: (context, oritentation, deviceType) {
      return BlocProvider(
        create: (context) => BluetoothReceiveBloc(),
        child: BlocConsumer<BluetoothReceiveBloc, BluetoothReceiveState>(
          listener: (context, state) async {
            // TODO: implement listener
            if (state is BluetoothConnected) {
              state.connection.input!.listen(
                (event) async {
                  String dataString = String.fromCharCodes(event).trim();
                  log("state = $getDataState data = $dataString length = ${dataString.length}");
                  if (getDataState == "name") {
                    nameTextController.text = dataString;
                    getDataState = "address";
                    state.connection.output.add(Uint8List.fromList(utf8.encode("address=?\r\n")));
                    await state.connection.output.allSent;
                  } else if (getDataState == "address") {
                    if (getDataState.isEmpty) return;
                    addressTextController.text = dataString;
                    getDataState = "mode";
                    state.connection.output.add(Uint8List.fromList(utf8.encode("mode=?\r\n")));
                    await state.connection.output.allSent;
                  } else if (getDataState == "mode") {
                    if (getDataState.isEmpty) return;

                    modeTextController.text = dataString;
                    getDataState = "";
                    setState(() {});
                  }
                },
              );
            }
          },
          builder: (context, state) {
            return Theme(
              data: Theme.of(context).copyWith(
                  listTileTheme: ListTileThemeData(
                selectedColor: Theme.of(context).colorScheme.onSecondary,
                selectedTileColor: Theme.of(context).colorScheme.primary,
              )),
              child: Scaffold(
                // drawer: Drawer(
                //   child: SafeArea(
                //     child: Container(
                //       margin: const EdgeInsets.only(top: 32),
                //       child: Column(
                //         children: [
                //           ListTile(
                //             title: const Text("Control"),
                //             onTap: () {},
                //           ),
                //           ListTile(
                //             title: const Text("Bluetooth Device"),
                //             onTap: () {
                //               BlocProvider.of<BluetoothReceiveBloc>(context).add(SelectDevice());
                //               Navigator.pop(context);
                //             },
                //           ),
                //         ],
                //       ),
                //     ),
                //   ),
                // ),
                appBar: AppBar(
                  backgroundColor: Theme.of(context).colorScheme.inversePrimary,
                  title: Text(widget.title),
                  actions: [
                    IconButton(
                      onPressed: () {
                        FlutterBluetoothSerial.instance.getBondedDevices().then((getDevices) => setState(() => devices = getDevices));
                        BlocProvider.of<BluetoothReceiveBloc>(context).add(SelectDevice());
                      },
                      icon: const Icon(Icons.bluetooth),
                    ),
                  ],
                ),
                body: BlocBuilder<BluetoothReceiveBloc, BluetoothReceiveState>(
                  builder: (context, state) {
                    if (state is BluetoothReceiveInitial) {
                      return Center(
                        child: ListView.builder(
                          itemCount: devices.length,
                          itemBuilder: (context, index) {
                            return ListTile(
                              onTap: () {
                                BlocProvider.of<BluetoothReceiveBloc>(context).add(ConnectToDevice(device: devices[index]));
                              },
                              selected: devices[index].isConnected,
                              title: Text("${devices[index].name}"),
                              subtitle: Text(devices[index].address),
                              leading: devices[index].isConnected ? const Icon(Icons.bluetooth) : null,
                            );
                          },
                        ),
                      );
                    } else if (state is BluetoothConnecting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (state is BluetoothConnectionFailed) {
                      return const Center(child: Text("Connection Failed"));
                    } else if (state is BluetoothConnected) {
                      return RefreshIndicator(
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                          child: Container(
                            height: 100.h,
                            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            child: DefaultTextStyle(
                              style: const TextStyle(fontSize: 18, color: Colors.black),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      SizedBox(width: 25.w, child: const Text("Name : ")),
                                      Flexible(
                                        child: TextField(
                                          controller: nameTextController,
                                          decoration: InputDecoration(
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 8.sp),
                                  Row(
                                    children: [
                                      SizedBox(width: 25.w, child: const Text("Address : ")),
                                      Flexible(
                                        child: TextField(
                                          controller: addressTextController,
                                          decoration: InputDecoration(
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 8.sp),
                                  Row(
                                    children: [
                                      SizedBox(width: 25.w, child: const Text("Mode : ")),
                                      Flexible(
                                        child: TextField(
                                          controller: modeTextController,
                                          decoration: InputDecoration(
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        onRefresh: () async {
                          getDataState = "name";
                          state.connection.output.add(Uint8List.fromList(utf8.encode("name=?\r\n")));
                          await state.connection.output.allSent;

                          // await Future.delayed(const Duration(seconds: 1));
                          // getDataState = "mode";
                          // state.connection.output.add(Uint8List.fromList(utf8.encode("mode=?\r\n")));
                          // await state.connection.output.allSent;
                        },
                      );
                    }
                    return const Center(
                      child: Text("Hello World"),
                    );
                  },
                ),
                floatingActionButton: FloatingActionButton(
                  onPressed: () async {
                    if (state is BluetoothConnected) {
                      getDataState = "name";
                      state.connection.output.add(Uint8List.fromList(utf8.encode("name=?\r\n")));
                      await state.connection.output.allSent;
                    }
                  },
                  tooltip: 'Increment',
                  child: const Icon(Icons.refresh),
                ),
              ),
            );
          },
        ),
      );
    });
  }
}
