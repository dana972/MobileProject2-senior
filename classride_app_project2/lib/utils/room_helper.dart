String generateChatRoomId(String user1, String user2) {
  final sorted = [user1, user2]..sort();
  return 'chat_${sorted[0]}_${sorted[1]}';
}
