import 'package:flutter/material.dart';
import 'package:frontend/services/api_config.dart';
import 'package:http/http.dart' as http;
import 'package:frontend/models/chat_message_model.dart';
import 'package:frontend/widgets/chat_bubble_widget.dart';
import 'dart:convert';

const Color primaryTeal = Color(0xFF2A8C93);
const String aiProfileImage = 'images/ai_character.png'; 

void main() => runApp(const AilapyuApp());

class AilapyuApp extends StatelessWidget {
  const AilapyuApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Lap Yu',
      theme: ThemeData(
        primarySwatch: Colors.teal, // This will handle many colors automatically
        primaryColor: primaryTeal,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      // Set the default homepage
      home: const ChatHomeScreen(), 
    );
  }
}

class ChatHomeScreen extends StatefulWidget {
  const ChatHomeScreen({Key? key}) : super(key: key);

  @override
  State<ChatHomeScreen> createState() => _ChatHomeScreenState();
}

class _ChatHomeScreenState extends State<ChatHomeScreen> {
  // Controller to read and clear the text field
  final TextEditingController _messageController = TextEditingController();
  
  List<Map<String, String>> _messages = [];

 
  bool _isLoading = false;


Future<void> askQuestion() async {
  final userText = _messageController.text.trim();
  if (userText.isEmpty) return;

  _messageController.clear();

  final aiIndex = _messages.length - 1;

 setState(() {
    _isLoading = true;
    _messages.add({'sender': 'user', 'text': userText});
    _messages.add({'sender': 'ai', 'text': ''});  // ✅ new map every time
  });


  final client = http.Client();
  final request = http.Request('POST', Uri.parse(ApiConfig.baseUrl));

  request.headers['Content-Type'] = 'application/json';
  request.body = jsonEncode({'message': userText});

  final response = await client.send(request); // ← returns a Stream

  response.stream
    .transform(utf8.decoder)    // bytes → String
    .transform(const LineSplitter()) 
    .where((line) => line.isNotEmpty) 
    .listen(
      (line) {
        setState(() {
          _messages[aiIndex]['text'] = (_messages[aiIndex]['text'] ?? '') + line;
        });
      },
      onDone: () {
        setState(() => _isLoading = false);
        client.close();
      },
    );
}
  
  


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Lap Yu'),
        centerTitle: true,
        backgroundColor: primaryTeal,
        // The AI character is the APP LOGO here, small and circular.
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: const CircleAvatar(
            backgroundImage: AssetImage(aiProfileImage),
          ),
        ),
      ),
      body: Column(
        children: <Widget>[
          // 1. CHAT MESSAGE AREA
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final ChatMessage message = ChatMessage(
                  text: _messages[index]['text']!,
                  isUser: _messages[index]['sender'] == 'user',
                );
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  // ChatBubble is a custom widget defined below
                  child: ChatBubble(message: message),
                );
              },
            ),
          ),
          // 2. MESSAGE INPUT BAR
          Container(
            padding: const EdgeInsets.all(10),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Ask me anything...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                FloatingActionButton(
                  onPressed: () {
                    // Logic to send message and get AI response.
                    askQuestion(); 
                  },
                  backgroundColor: primaryTeal,
                  mini: true,
                  child: const Icon(Icons.send, size: 18),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


