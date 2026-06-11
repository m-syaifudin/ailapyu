import 'package:flutter/material.dart';
import 'package:frontend/api_config.dart';
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

  bool _isLoading = false; // To show a loading indicator when waiting for AI response

  // A hypothetical list of messages.
  List<Map<String, String>> _messages = [];

  // Function to send message to FastAPI
  
  // Future<void> _sendMessage() async {
  //   final userText = _messageController.text.trim();
  //   if (userText.isEmpty) return;

  //   // 1. Clear input and immediately show user message in the UI
  //   _messageController.clear();
  //   setState(() {
  //     _messages.add({'sender': 'user', 'text': userText});
  //     _isLoading = true;
  //   });

  //   try {
  //     // 2. Hit your FastAPI endpoint (Replace with your actual IP/URL)
  //     // Note: Use '10.0.2.2' if testing on an Android Emulator pointing to local host
  //     final url = Uri.parse(ApiConfig.baseUrl); 
      
  //     final response = await http.post(
  //       url,
  //       headers: {'Content-Type': 'application/json'},
  //       body: jsonEncode({'message': userText}),
  //     );

  //     print('Response status: ${response.statusCode}');

  //     if (response.statusCode == 200) {
  //       final data = jsonDecode(response.body);
        
  //       // 3. Update UI with AI response
  //       setState(() {
  //         _messages.add({'sender': 'ai', 'text': data['reply']});
  //       });
  //     } else {
  //       _showError('Failed to connect to AI server.');
  //     }
  //   } catch (e) {
  //     _showError('Error: Could not reach backend.');
  //   } finally {
  //     setState(() {
  //       _isLoading = false;
  //     });
  //   }
  // }

  Future<void> _sendMessage() async {
  final userText = _messageController.text.trim();
  if (userText.isEmpty) return;

  _messageController.clear();

  setState(() {
    _messages.add({'sender': 'user', 'text': userText});

    // placeholder AI message
    _messages.add({'sender': 'ai', 'text': ''});

    _isLoading = true;
  });

  try {
    final request = http.Request(
      'POST',
      Uri.parse(ApiConfig.baseUrl),
    );

    request.headers['Content-Type'] = 'application/json';

    request.body = jsonEncode({
      'message': userText,
    });

    final streamedResponse = await request.send();

    if (streamedResponse.statusCode == 200) {
      streamedResponse.stream
          .transform(utf8.decoder)
          .listen(
        (chunk) {
          setState(() {
            _messages.last['text'] =
                (_messages.last['text'] ?? '') + chunk;
          });
        },
        onDone: () {
          setState(() {
            _isLoading = false;
          });
        },
        onError: (e) {
          _showError('Stream error');
          setState(() {
            _isLoading = false;
          });
        },
      );
    } else {
      _showError('Failed to connect to AI server.');
      setState(() {
        _isLoading = false;
      });
    }
  } catch (e) {
    _showError('Error: Could not reach backend.');
    setState(() {
      _isLoading = false;
    });
  }
}

  void _showError(String message) {
    setState(() {
      _messages.add({'sender': 'ai', 'text': message});
    });
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
                    _sendMessage(); 
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


