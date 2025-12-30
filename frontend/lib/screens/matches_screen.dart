import 'package:flutter/material.dart';
import 'package:frontend/models/user_model.dart';
import 'package:frontend/screens/chat_screen.dart';

class MatchesScreen extends StatelessWidget {
  const MatchesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Dummy data for matched users
    final List<User> matches = [
      User(name: 'Grace', age: 29, imageUrl: 'https://i.pravatar.cc/300?img=6'),
      User(name: 'Heidi', age: 24, imageUrl: 'https://i.pravatar.cc/300?img=7'),
      User(name: 'Ivan', age: 32, imageUrl: 'https://i.pravatar.cc/300?img=8'),
    ];

    return Scaffold(
      body: ListView.builder(
        itemCount: matches.length,
        itemBuilder: (context, index) {
          final user = matches[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundImage: NetworkImage(user.imageUrl),
            ),
            title: Text(user.name),
            subtitle: Text('${user.age} years old'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatScreen(user: user),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
