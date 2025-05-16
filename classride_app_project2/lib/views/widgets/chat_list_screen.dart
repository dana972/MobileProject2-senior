import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../services/api_service.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatefulWidget {
  final bool isDriver;
  const ChatListScreen({super.key, required this.isDriver});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  List<Map<String, dynamic>> _chats = [];
  String _myPhone = '';

  @override
  void initState() {
    super.initState();
    _loadChats();
  }

  Future<void> _loadChats() async {
    final prefs = await SharedPreferences.getInstance();
    final phone = prefs.getString('phone_number');
    if (phone == null) return;

    _myPhone = phone;
    final chats = await ApiService.fetchChatList(phone);

    setState(() {
      _chats = chats;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView.builder(
        itemCount: _chats.length,
        itemBuilder: (context, index) {
          final chat = _chats[index];
          return ListTile(
            leading: const Icon(Icons.chat),
            title: Text(chat['other_participant_name'] ?? chat['other_participant'].toString()),
            subtitle: Text(chat['last_message'] ?? ''),
            trailing: Text(
              chat['last_message_time']?.substring(0, 10) ?? '',
              style: const TextStyle(fontSize: 12),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatScreen(
                    chatId: chat['chat_id'].toString(), // ✅ Fix: ensure it's String
                    otherUserName: chat['other_participant_name'] ?? chat['other_participant'],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
