import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import './call_screen.dart';
import '../services/signalling.service.dart';

class UserListScreen extends StatefulWidget {
  final String selfCallerId;

  const UserListScreen({Key? key, required this.selfCallerId}) : super(key: key);

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
        // set SDP Offer of incoming call
        setState(() => incomingSDPOffer = data);
      }
    });
    _setupSignalling();
  }

  void _setupSignalling() {
    SignallingService.instance.onUpdateUserList((data) {
      setState(() {
        users = data;
      });
    });
  }
   _answerCall({
    required String callerId,
     required String calleeId,
    dynamic offer,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CallScreen(
          callerId: callerId,
          calleeId: calleeId,
          offer: offer,
        ),
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    List<String> otherUsers = users.where((user) => user != widget.selfCallerId).toList();
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
                        setState(() => incomingSDPOffer = null);
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