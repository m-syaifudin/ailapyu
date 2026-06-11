// A custom widget for the chat bubble with the image.
import 'package:frontend/models/chat_message_model.dart';
import 'package:flutter/material.dart';
import 'package:markdown_widget/markdown_widget.dart';

const String aiProfileImage = 'images/ai_character.png'; 
const Color primaryTeal = Color(0xFF2A8C93);

class ChatBubble extends StatelessWidget {
  final ChatMessage message;
  const ChatBubble({Key? key, required this.message}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
      child: Row(
        mainAxisAlignment: message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start, // Align items to the top
        children: [
          if (!message.isUser)
            Padding(
              padding: const EdgeInsets.only(right: 10.0, top: 4.0),
              child: const CircleAvatar(
                radius: 18,
                backgroundImage: AssetImage(aiProfileImage),
              ),
            ),
          
          // Flexible prevents the container from overflowing the Row
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                // FIX: AI response gets a clean, soft background instead of solid teal
                color: message.isUser ? Colors.grey[200] : Colors.grey[50],
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: message.isUser ? const Radius.circular(16) : Radius.zero,
                  bottomRight: message.isUser ? Radius.zero : const Radius.circular(16),
                ),
                border: message.isUser 
                    ? null 
                    : Border.all(color: Colors.grey[200]!, width: 1), // Subtle border for AI
              ),
              child: !message.isUser 
                  ? MarkdownBlock(                  
                      data: message.text,
                      config: MarkdownConfig(
                        configs: [
                          // FIX: Dark charcoal text on light gray background for ultimate readability
                          PConfig(
                            textStyle: const TextStyle(
                              color: Colors.black87, 
                              fontSize: 15,
                              height: 1.4,
                            ),
                          ),

                          // FIX: Headings styled cleanly with brand teal accent
                          H3Config(
                            style: const TextStyle(
                              color: primaryTeal,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),

                          // Inline code styles (e.g., `main.dart`)
                          CodeConfig(
                            style: TextStyle(
                              color: Colors.red[700], // Distinct color for inline keywords
                              fontFamily: 'monospace',
                              fontSize: 14,
                              backgroundColor: Colors.grey[200], // Subtle backing for inline tags
                            ),
                          ),
                          
                          // Code Block Container (e.g., code snippets)
                          PreConfig(
                            padding: const EdgeInsets.all(14),
                            margin: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E1E1E), // Deep dark background for code blocks
                              borderRadius: BorderRadius.circular(8),
                            ),
                            // Markdown_widget handles syntax highlighting natively via code style wrapper
                            wrapper: (child, code, language) {
                              return SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: child,
                              );
                            },
                          ),         
                        ],
                      ),
                    )
                  : Text(
                      message.text,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 16,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}