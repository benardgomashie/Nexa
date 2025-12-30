import 'package:flutter/material.dart';
import 'package:frontend/models/user_model.dart';

class ChatScreen extends StatelessWidget {
  final User user;

  const ChatScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(user.name),
      ),
      body: const Center(
        child: Text('Chat Screen'),
      ),
    );
  }
}
