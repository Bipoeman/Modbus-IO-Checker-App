import 'dart:developer';

import 'package:bloc/bloc.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:meta/meta.dart';

part 'bluetooth_receive_event.dart';
part 'bluetooth_receive_state.dart';

class BluetoothReceiveBloc extends Bloc<BluetoothReceiveEvent, BluetoothReceiveState> {
  BluetoothReceiveBloc() : super(BluetoothReceiveInitial()) {
    on<BluetoothReceiveEvent>((event, emit) {
      // TODO: implement event handler
    });

    on<SelectDevice>(
      (event, emit) {
        emit(BluetoothReceiveInitial());
      },
    );

    on<ConnectToDevice>((event, emit) async {
      emit(BluetoothConnecting(connectingDevice: event.device));
      BluetoothConnection connection = await BluetoothConnection.toAddress(event.device.address).onError(
        (error, stackTrace) async {
          log("$error");
          emit(BluetoothConnectionFailed(
            failedDevice: event.device,
          ));

          return BluetoothConnection.toAddress(event.device.address);
        },
      );

      if (connection.isConnected) {
        log("${connection.isConnected}");
        emit(BluetoothConnected(connectedDevice: event.device, connection: connection));
      } else {
        emit(BluetoothConnectionFailed(
          failedDevice: event.device,
        ));
      }
      // else if (status.){

      // }
    });
  }
}
