import 'dart:developer';
import 'package:socket_io_client/socket_io_client.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
class SignallingService {
  IO.Socket? socket;

  SignallingService._privateConstructor();
  static final SignallingService instance = SignallingService._privateConstructor();

  void init({required String websocketUrl, required String selfCallerID}) {
    socket = io(websocketUrl, {
      'transports': ['websocket'],
      'query': {'callerId': selfCallerID}
    });

   socket!.onConnect((data) {
      log("Socket connected !!");
    });

    socket!.onConnectError((data) {
      log("Connect Error $data");
    });

    socket!.connect();
  }

  void register(String name) {
    socket!.emit('register', name);
  }
   void rejectCall(String callerId) {
    socket?.emit('rejectCall', {'callerId': callerId});
  }
  void onCallRejected(Function(dynamic) callback) {
    socket!.on('callRejected', (data) {
      callback(data);
    });
  }
  void onUpdateUserList(Function(List<String>) callback) {
    socket!.on('updateUserList', (data) {
      callback(List<String>.from(data));
    });
  }
}