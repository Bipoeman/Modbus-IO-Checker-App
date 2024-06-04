part of 'bluetooth_receive_bloc.dart';

@immutable
sealed class BluetoothReceiveEvent {}

class SelectDevice extends BluetoothReceiveEvent {}

class ConnectToDevice extends BluetoothReceiveEvent {
  ConnectToDevice({required this.device});
  final BluetoothDevice device;
}

class DisconnectDevice extends BluetoothReceiveEvent {
  DisconnectDevice({required this.device});
  final BluetoothDevice device;
}

class SendMessage extends BluetoothReceiveEvent {
  SendMessage({required this.message});
  final String message;
}

class ReceiveMessage extends BluetoothReceiveEvent {
  ReceiveMessage({required this.message});
  final String message;
}
