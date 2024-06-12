import 'dart:convert';
import 'dart:developer';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:modbus_io_checker/controllers/bloc/bluetooth_receive_bloc.dart';
import 'package:sizer/sizer.dart';

void main() {
  runApp(const MyApp());
}

Color statusToColor(int status) {
  return status == 0 ? Colors.grey[600]! : Colors.green[800]!;
}

Map<String, int> modeToStr = {"SLAVE": 0, "MASTER": 1};

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ISAAC Alarm Cracker',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'ISAAC Alarm Cracker'),
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
  bool isConnect = false;
  TextEditingController nameTextController = TextEditingController();
  TextEditingController addressTextController = TextEditingController();
  TextEditingController modeTextController = TextEditingController();
  List<int> pinStatus = List.generate(4, (index) => 0);
  List<int> pinNumber = [33, 26, 27, 13];
  int modeValue = 0;
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
              isConnect = state.connection.isConnected;
              if (state.connection.isConnected) {
                state.connection.output.add(Uint8List.fromList(utf8.encode("all=?\r\n")));
                await state.connection.output.allSent;
              }
              setState(() {});
              // log("Bluetooth Connected");
              state.connection.input!.listen(
                (event) async {
                  String dataString = String.fromCharCodes(event).trim();
                  if (dataString.contains("ALL")) {
                    List<String> splitted = dataString.split("\t");
                    print(splitted);
                    nameTextController.text = splitted[1];
                    addressTextController.text = splitted[2];
                    // modeTextController.text = splitted[3];
                    modeValue = modeToStr[splitted[3]]!;
                    setState(() {});
                  }
                  if (dataString.contains("PIN")) {
                    List<String> splitted = dataString.split("\t");
                    try {
                      int pinStatusNum = int.parse(splitted[1]);
                      for (int i = 0; i < pinStatus.length; i++) {
                        pinStatus[i] = (pinStatusNum >> i) & 1;
                      }
                      log("${pinStatus[0]} ${pinStatus[1]} ${pinStatus[2]} ${pinStatus[3]}");
                    } catch (e) {}
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
                          physics: const BouncingScrollPhysics(),
                          child: Container(
                            height: 100.h,
                            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                            child: DefaultTextStyle(
                              style: const TextStyle(fontSize: 18, color: Colors.black),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Device Info",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 24,
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 16.sp),
                                  Row(
                                    children: [
                                      Text(
                                        "Status : ",
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 20,
                                          color: Colors.grey[600],
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        isConnect ? "Connected" : "Not Connected",
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 20,
                                          color: isConnect ? Colors.green : Colors.red,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 16.sp),
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
                                          keyboardType: TextInputType.number,
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
                                        child: DropdownButton<int>(
                                          borderRadius: BorderRadius.circular(12),
                                          isExpanded: true,
                                          value: modeValue,
                                          onChanged: (value) {
                                            if (value != null) {
                                              modeValue = value;
                                              setState(() {});
                                            }
                                          },
                                          items: const [
                                            DropdownMenuItem(value: 1, child: Text("MASTER")),
                                            DropdownMenuItem(value: 0, child: Text("SLAVE")),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 8.sp),
                                  SizedBox(
                                    width: 100.w,
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Theme.of(context).colorScheme.primary,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                      ),
                                      child: const Text("Save Data"),
                                      onPressed: () async {
                                        state.connection.output.add(Uint8List.fromList(utf8.encode("name=${nameTextController.text}\r\n")));
                                        await state.connection.output.allSent;
                                        Future.delayed(const Duration(seconds: 1));
                                        state.connection.output.add(Uint8List.fromList(utf8.encode("address=${addressTextController.text}\r\n")));
                                        await state.connection.output.allSent;
                                        Future.delayed(const Duration(seconds: 1));
                                        state.connection.output.add(Uint8List.fromList(utf8.encode("mode=$modeValue\r\n")));
                                        await state.connection.output.allSent;
                                      },
                                    ),
                                  ),
                                  SizedBox(height: 12.sp),
                                  const Divider(),
                                  SizedBox(height: 12.sp),
                                  Text(
                                    "Pin Status",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 24,
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 8.sp),
                                  Center(
                                    child: Wrap(
                                      runSpacing: 12,
                                      spacing: 12,
                                      children: List.generate(
                                        pinNumber.length,
                                        (index) {
                                          return Container(
                                            padding: EdgeInsets.symmetric(vertical: 18.sp),
                                            width: 45.w,
                                            decoration: BoxDecoration(
                                              color: statusToColor(pinStatus[index]),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Center(
                                              child: Text(
                                                "IO${pinNumber[index]}",
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        onRefresh: () async {
                          if (state.connection.isConnected) {
                            state.connection.output.add(Uint8List.fromList(utf8.encode("all=?\r\n")));
                            await state.connection.output.allSent;
                          }
                          isConnect = state.connection.isConnected;
                          setState(() {});
                        },
                      );
                    }
                    return const Center(
                      child: Text("Hello World"),
                    );
                  },
                ),
              ),
            );
          },
        ),
      );
    });
  }
}
