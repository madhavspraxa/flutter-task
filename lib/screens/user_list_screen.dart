import 'package:flutter/material.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import './call_screen.dart';
import '../services/signalling.service.dart';
import 'package:vibration/vibration.dart';
import 'package:flutter/services.dart';

class UserListScreen extends StatefulWidget {
  final String selfCallerId;

  const UserListScreen({Key? key, required this.selfCallerId})
      : super(key: key);

  @override
  _UserListScreenState createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  dynamic incomingSDPOffer;
  List<String> users = [];

  @override
  void initState() {
    super.initState();
    SignallingService.instance.socket!.on("newCall", (data) {
      if (mounted) {
        setState(() => incomingSDPOffer = data);
        _playIncomingCallAlert();
      }
    });
    _setupSignalling();
    // SignallingService.instance.onCallRejected((data) {
    //   if (mounted && data['callerId'] == widget.selfCallerId) {
    //     setState(() => incomingSDPOffer = null);

    //     Navigator.push(
    //       context,
    //       MaterialPageRoute(
    //         builder: (_) => CallScreen(
    //           callerId: widget.selfCallerId,
    //           calleeId: data['calleeId'],
    //         ),
    //       ),
    //     ).then((_) {
    //       setState(() => incomingSDPOffer = null);
    //     });
    //   }
    // });
  }

  void _setupSignalling() {
    SignallingService.instance.onUpdateUserList((data) {
      setState(() {
        users = data;
      });
    });
  }

  Future<void> _playIncomingCallAlert() async {
    FlutterRingtonePlayer.playRingtone();
    // if (await Vibration.canVibrate) {
    Vibration.vibrate(pattern: [500, 1000, 500, 2000, 500, 3000, 500, 500]);
    HapticFeedback.vibrate();
    //}
  }

  void _stopIncomingCallAlert() {
    FlutterRingtonePlayer.stop();
  }

  _answerCall({
    required String callerId,
    required String calleeId,
    dynamic offer,
  }) {
    _stopIncomingCallAlert();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CallScreen(
          callerId: callerId,
          calleeId: calleeId,
          offer: offer,
        ),
      ),
    ).then((_) {
      setState(() => incomingSDPOffer = null);
    });
  }

  _rejectCall(String callerId, String calleeId) {
    SignallingService.instance.rejectCall(callerId, calleeId);
    setState(() => incomingSDPOffer = null);
  }

  @override
  Widget build(BuildContext context) {
    List<String> otherUsers =
        users.where((user) => user != widget.selfCallerId).toList();
    String formattedUsers = otherUsers.join(', ');
    return Scaffold(
      appBar: AppBar(
        title: Text('User List'),
      ),
      body: Stack(
        children: [
          ListView.builder(
            itemCount: otherUsers.length,
            itemBuilder: (context, index) {
              final user = otherUsers[index];
              return ListTile(
                title: Text(user),
                trailing: IconButton(
                  icon: Icon(Icons.call),
                  onPressed: () => _answerCall(
                    callerId: widget.selfCallerId,
                    calleeId: user,
                  ),
                ),
              );
            },
          ),
          if (incomingSDPOffer != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: ListTile(
                title: Text(
                  "Incoming Call from ${formattedUsers}",
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.call_end),
                      color: Colors.redAccent,
                      onPressed: () {
                        _stopIncomingCallAlert();
                        _rejectCall(
                            incomingSDPOffer["callerId"], widget.selfCallerId);
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.call),
                      color: Colors.greenAccent,
                      onPressed: () {
                        _answerCall(
                          callerId: incomingSDPOffer["callerId"],
                          calleeId: widget.selfCallerId,
                          offer: incomingSDPOffer["sdpOffer"],
                        );
                      },
                    )
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
