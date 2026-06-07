// A custom widget for the chat bubble with the image.
import 'package:frontend/models/chat_message_model.dart';
import 'package:flutter/material.dart';

// Assume image_0.png is in your assets folder.
const String aiProfileImage = 'images/ai_character.png'; 
const Color primaryTeal = Color(0xFF2A8C93);

class ChatBubble extends StatelessWidget {
  final ChatMessage message;
  const ChatBubble({Key? key, required this.message}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      // 1. Align based on sender.
      mainAxisAlignment: message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        // 2. Add AI avatar if it's an AI message.
        if (!message.isUser)
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: const CircleAvatar(
              radius: 18,
              backgroundImage: AssetImage(aiProfileImage), // image_0.png
            ),
          ),
        // 3. The actual text container.
        Container(
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: message.isUser ? Colors.grey[200] : primaryTeal,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: message.isUser ? const Radius.circular(16) : Radius.zero,
              bottomRight: message.isUser ? Radius.zero : const Radius.circular(16),
            ),
          ),
          child: Text(
            message.text,
            style: TextStyle(
              color: message.isUser ? Colors.black87 : Colors.white,
              fontSize: 16,
            ),
          ),
        ),
      ],
    );
  }
}