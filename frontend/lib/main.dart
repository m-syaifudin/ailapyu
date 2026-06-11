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
  final ScrollController _scrollController = ScrollController();
  
  List<Map<String, String>> _messages = [];

 
  bool _isLoading = false;


  Future<void> askQuestion() async {
    final userText = _messageController.text.trim();
    final client = http.Client();

    if (userText.isEmpty) return;

    _messageController.clear();
    
    final Map<String, String> aiMessage = {'sender': 'ai', 'text': ''};

    setState(() {
      _isLoading = true;
      _messages.add({'sender': 'user', 'text': userText});
      _messages.add(aiMessage); 
    });

    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

    
    try {
      final request = http.Request('POST', Uri.parse(ApiConfig.baseUrl));
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode({'message': userText});

      final response = await client.send(request);
      
      if (response.statusCode != 200) {
        setState(() {
          aiMessage['text'] = 'Server Error (${response.statusCode}). Failed to connect.';
          _isLoading = false;
        });
        client.close();
        return;
      }

      response.stream
        .transform(utf8.decoder)   
        .transform(const LineSplitter()) 
        .listen(
          (line) {            
            if (line.isNotEmpty) {
              setState(() {
                final currentText = aiMessage['text'] ?? '';
                aiMessage['text'] = currentText + line;
              });
              WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
            }
          },
          onDone: () {
            setState(() => _isLoading = false);
            client.close();
            WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
          },
          onError: (error) {
            setState(() {
              aiMessage['text'] = 'Stream Error: $error';
              _isLoading = false;
            });
            client.close();
          }
        );
    } catch (e) {
      setState(() {
        aiMessage['text'] = 'Connection Failed: $e';
        _isLoading = false;
      });
      client.close();
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }
    
  @override
  void dispose() {
    _scrollController.dispose();
    _messageController.dispose();
    super.dispose();
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
              controller: _scrollController,
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


