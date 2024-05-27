import 'package:flutter/material.dart';
import 'package:flutter_webrtc_app/screens/user_list_screen.dart';
import '../services/signalling.service.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
   SignallingService.instance.init(websocketUrl: 'http://192.168.6.64:5000', selfCallerID: '');
  }

  void _register() {
    final name = _nameController.text;
    if (name.isNotEmpty) {
      SignallingService.instance.register(name);
       SignallingService.instance.init(websocketUrl: 'http://192.168.6.64:5000', selfCallerID: name);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => UserListScreen(selfCallerId: name),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('P2P Call App')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: 'Enter your name'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _register,
              child: Text('Register'),
            ),
          ],
        ),
      ),
    );
  }
}
