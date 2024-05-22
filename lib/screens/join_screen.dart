import 'package:flutter/material.dart';
import 'call_screen.dart';
import '../services/signalling.service.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
class JoinScreen extends StatefulWidget {
   const JoinScreen({Key? key}) : super(key: key);
  @override
  State<JoinScreen> createState() => _JoinScreenState();
}

class _JoinScreenState extends State<JoinScreen> {
  dynamic incomingSDPOffer;
  final remoteCallerIdTextEditingController = TextEditingController();
final nameController = TextEditingController();
  final IO.Socket socket = SignallingService.instance.socket!;
  Map<String, String> users = {};
  String? selfCallerId;
  @override
  void initState() {
    super.initState();

    // Listen for user list updates
    socket.on('updateUserList', (data) {
      setState(() {
        users = Map<String, String>.from(data);
      });
    });
    
  }

   void _register() {
    final name = nameController.text;
    if (name.isNotEmpty) {
      socket.emit('register', name);
      selfCallerId = socket.id;
    }
  }

  void _joinCall(String calleeId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CallScreen(
          callerId: selfCallerId!,
          calleeId: calleeId,
        ),
      ),
    );
  }
 @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("P2P Call App"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Enter your name'),
            ),
            ElevatedButton(
              onPressed: _register,
              child: const Text('Register'),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final userId = users.keys.elementAt(index);
                  final userName = users.values.elementAt(index);
                  if (userId == selfCallerId) return Container(); // Hide self
                  return ListTile(
                    title: Text(userName),
                    onTap: () => _joinCall(userId),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}