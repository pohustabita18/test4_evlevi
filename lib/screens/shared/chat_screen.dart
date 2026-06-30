import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../services/database_service.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String recipientName;
  final String senderRole;

  ChatScreen({
    required this.chatId,
    required this.recipientName,
    required this.senderRole,
  });

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final DatabaseService _dbService = DatabaseService();
  final _messageController = TextEditingController();
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    _dbService.markChatAsRead(widget.chatId, widget.senderRole);
  }

  void _send() {
    if (_messageController.text.trim().isEmpty) return;
    _dbService.sendMessage(
      widget.chatId,
      currentUserId,
      _messageController.text.trim(),
      widget.senderRole,
    );
    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.recipientName),
        backgroundColor: const Color(0xFFD2E6FF),
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _dbService.getMessages(widget.chatId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFF0F172A),
                      ),
                    ),
                  );
                }
                var messages = snapshot.data!.docs;

                if (messages.isEmpty) {
                  return const Center(
                    child: Text(
                      'Începeți o conversație nouă! 👋',
                      style: TextStyle(
                        color: Colors.black54,
                        fontSize: 15,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  itemCount: messages.length,
                  itemBuilder: (context, i) {
                    var msgData = messages[i].data() as Map<String, dynamic>;
                    bool isMe = msgData['senderId'] == currentUserId;

                    return Align(
                      alignment: isMe
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 16,
                        ),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.75,
                        ),

                        decoration: BoxDecoration(
                          color: isMe
                              ? const Color(0xFF0F172A)
                              : Colors
                                    .white, // Deep Navy pentru tine, Alb pentru restul
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(18),
                            topRight: const Radius.circular(18),
                            bottomLeft: Radius.circular(isMe ? 18 : 0),
                            bottomRight: Radius.circular(isMe ? 0 : 18),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 3,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Text(
                          msgData['text'] ?? '',
                          style: TextStyle(
                            color: isMe ? Colors.white : Colors.black87,
                            fontSize: 15,
                            height: 1.3,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          Container(
            padding: const EdgeInsets.only(
              left: 12,
              right: 12,
              bottom: 20,
              top: 10,
            ),
            color: const Color(0xFFD2E6FF),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    style: const TextStyle(color: Colors.black),
                    decoration: InputDecoration(
                      hintText: 'Scrie un mesaj...',
                      hintStyle: const TextStyle(color: Colors.black45),
                      filled: true,
                      fillColor: Colors.white, // Căsuța albă curată
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(28),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(28),
                        borderSide: const BorderSide(
                          color: Color(0xFF0F172A),
                          width: 1,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                CircleAvatar(
                  radius: 24,
                  backgroundColor: const Color(
                    0xFF0F172A,
                  ), // Deep Navy background
                  child: IconButton(
                    icon: const Icon(
                      Icons.send,
                      color: Colors.white,
                      size: 20,
                    ), // Săgeată albă
                    onPressed: _send,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
