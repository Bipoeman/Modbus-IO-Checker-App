part of 'bluetooth_receive_bloc.dart';

@immutable
sealed class BluetoothReceiveState {}

final class BluetoothReceiveInitial extends BluetoothReceiveState {}

final class BluetoothSelectDevice extends BluetoothReceiveState {}

final class BluetoothConnecting extends BluetoothReceiveState {
  BluetoothConnecting({required this.connectingDevice});
  final BluetoothDevice connectingDevice;
}

final class BluetoothConnectionFailed extends BluetoothReceiveState {
  BluetoothConnectionFailed({required this.failedDevice});

  final BluetoothDevice failedDevice;
}

final class BluetoothConnected extends BluetoothReceiveState {
  BluetoothConnected({required this.connectedDevice, required this.connection});
  final BluetoothConnection connection;
  final BluetoothDevice connectedDevice;
}
