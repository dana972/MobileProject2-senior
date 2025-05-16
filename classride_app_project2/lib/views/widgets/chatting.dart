import 'package:flutter/material.dart';
import 'chat_screen.dart';

class ChattingWidget extends StatelessWidget {
  const ChattingWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const ChatScreen(
      chatId: 'dummy-id',
      otherUserName: 'Unknown',
    );
  }
}
