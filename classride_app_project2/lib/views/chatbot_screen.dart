import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class ChatbotScreen extends StatefulWidget {
  @override
  _ChatbotScreenState createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> _messages = [];
  String? destination;
  String? address;
  String sessionId = 'flutter-session';

  void _addMessage(String sender, String text) {
    setState(() {
      _messages.add({ 'sender': sender, 'text': text });
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(Duration(milliseconds: 300), () {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _sendMessage(String msg) async {
    _addMessage('You', msg);
    _controller.clear();

    final response = await http.post(
      Uri.parse('http://YOUR_BACKEND_URL/api/chatbot/message'),
      headers: { 'Content-Type': 'application/json' },
      body: jsonEncode({ 'message': msg, 'sessionId': sessionId }),
    );

    final data = jsonDecode(response.body);
    if (data['destination'] != null) destination = data['destination'];
    if (data['address'] != null) address = data['address'];
    _addMessage('ClassRide', data['reply'] ?? '');
  }

  Future<void> _shareLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }

      Position position = await Geolocator.getCurrentPosition();

      final response = await http.post(
        Uri.parse('http://YOUR_BACKEND_URL/api/chatbot/message'),
        headers: { 'Content-Type': 'application/json' },
        body: jsonEncode({
          'lat': position.latitude,
          'lng': position.longitude,
          'sessionId': sessionId,
        }),
      );

      final data = jsonDecode(response.body);
      if (data['address'] != null) address = data['address'];
      _addMessage('ClassRide', data['reply'] ?? '');
    } catch (e) {
      _addMessage('ClassRide', 'Location error.');
    }
  }

  void _restartChat() {
    setState(() => _messages.clear());
    _addMessage('ClassRide', 'Hello! Are you a student?');
  }

  @override
  void initState() {
    super.initState();
    _restartChat();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('ClassRide Chatbot')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isUser = msg['sender'] == 'You';
                return Container(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isUser ? Colors.blue[100] : Colors.grey[300],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text('${msg['sender']}: ${msg['text']}'),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                        hintText: 'Type a message...'
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: () => _sendMessage(_controller.text),
                ),
                IconButton(
                  icon: Icon(Icons.location_pin),
                  onPressed: _shareLocation,
                ),
                IconButton(
                  icon: Icon(Icons.restart_alt),
                  onPressed: _restartChat,
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
