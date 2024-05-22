import 'dart:developer';
import 'package:socket_io_client/socket_io_client.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
class SignallingService {
  // instance of Socket
  IO.Socket? socket;

  SignallingService._privateConstructor();
  static final SignallingService instance = SignallingService._privateConstructor();

  void init({required String websocketUrl}) {
    // init Socket
    socket = IO.io(websocketUrl, IO.OptionBuilder()
        .setTransports(['websocket']) // Correct the transports option
        .build());

    // listen onConnect event
    socket!.onConnect((data) {
      log("Socket connected !!");
    });

    // listen onConnectError event
    socket!.onConnectError((data) {
      log("Connect Error $data");
    });

    // connect socket
    socket!.connect();
  }
}