import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../services/database_service.dart';

class ChatScreen extends StatelessWidget {
  final String chatId;
  final String recipientName;
  final DatabaseService _dbService = DatabaseService();
  final _messageController = TextEditingController();
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

  ChatScreen({required this.chatId, required this.recipientName});

  void _send() {
    _dbService.sendMessage(chatId, currentUserId, _messageController.text);
    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(recipientName)),
      body: Column(
        children: [
          // Zona de mesaje în timp real
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _dbService.getMessages(chatId),
              builder: (context, snapshot) {
                if (!snapshot.hasData)
                  return Center(child: CircularProgressIndicator());
                var messages = snapshot.data!.docs;

                return ListView.builder(
                  reverse: true, // Mesajele noi apar jos
                  itemCount: messages.length,
                  itemBuilder: (context, i) {
                    var msgData = messages[i].data() as Map<String, dynamic>;
                    bool isMe = msgData['senderId'] == currentUserId;

                    return Align(
                      alignment: isMe
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: EdgeInsets.symmetric(
                          vertical: 5,
                          horizontal: 10,
                        ),
                        padding: EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 14,
                        ),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.indigo : Colors.grey[300],
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(12),
                            topRight: Radius.circular(12),
                            bottomLeft: isMe
                                ? Radius.circular(12)
                                : Radius.circular(0),
                            bottomRight: isMe
                                ? Radius.circular(0)
                                : Radius.circular(12),
                          ),
                        ),
                        child: Text(
                          msgData['text'] ?? '',
                          style: TextStyle(
                            color: isMe ? Colors.white : Colors.black87,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          // Câmpul de trimis mesaj text
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Scrie un mesaj...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.send, color: Colors.indigo),
                  onPressed: _send,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
