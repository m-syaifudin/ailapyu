import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/models/chat_message_model.dart';
import 'package:frontend/services/api_config.dart';
import 'package:frontend/widgets/chat_bubble_widget.dart';
import 'package:frontend/widgets/thinking_indicator.dart';
import 'package:http/http.dart' as http;

const Color primaryTeal = Color(0xFF2A8C93);
const String aiProfileImage = 'images/ai_character.png'; 

class ChatPage extends StatefulWidget {
  final String userId;

  const ChatPage({Key? key, required this.userId}) : super(key: key);
  

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  // Controller to read and clear the text field
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  List<Map<String, String>> _messages = [];  
  StreamSubscription<String>? _streamSubscription;
  http.Client? _currentClient;
  bool _isLoading = false;
  

  Future<void> askQuestion() async {
    final userText = _messageController.text.trim();  
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
      _currentClient = http.Client();

      final request = http.Request('POST', Uri.parse(ApiConfig.baseUrl));
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode({'userId': widget.userId,'message': userText});

      final response = await _currentClient!.send(request);
      
      if (response.statusCode != 200) {
        setState(() {
          aiMessage['text'] = 'Server Error (${response.statusCode}). Failed to connect.';
          _isLoading = false;
        });
        _cleanup();
        return;
      }

      _streamSubscription = response.stream
        .transform(utf8.decoder)   
        //.transform(const LineSplitter()) 
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
            _cleanup();
            WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
          },
          onError: (error) {
            setState(() {
              aiMessage['text'] = 'Stream Error: network error';
              _isLoading = false;
            });
            _cleanup();
          }
        );
    } catch (e) {
      setState(() {
        aiMessage['text'] = 'Connection Failed: $e';
        _isLoading = false;
      });
      _cleanup();
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

  void stopGeneration() {
  if (_isLoading) {
    setState(() {
      _isLoading = false;
      // Optional: Add a visual indicator that it was cut off     
      final Map<String, String> stopMessage = {'sender': 'ai', 'text': 'Generation stopped before response.'};
      _messages.add(stopMessage);
    });
    _cleanup();
  }
}

  void _cleanup() {
  _streamSubscription?.cancel();
  _streamSubscription = null;
  
  _currentClient?.close();
  _currentClient = null;
}
    
  @override
  void dispose() {
    _cleanup();
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

                final isAi = _messages[index]['sender'] == 'ai';
                final text = _messages[index]['text'] ?? '';

                final ChatMessage message = ChatMessage(
                  text: _messages[index]['text']!,
                  isUser: _messages[index]['sender'] == 'user',
                );

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  // ChatBubble is a custom widget defined below
                  child: 
                    !message.isUser && text.isEmpty ?
                    
                       const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text("Thinking ", style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
                            SizedBox(width: 4),
                            ThinkingIndicator(), 
                          ],
                        )
                      
                    
                    : ChatBubble(message: message),
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
                  child: Focus(
                    onKeyEvent: (FocusNode node, KeyEvent event) {
                      //(KeyDownEvent)
                      if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.enter) {

                        // 1. (Shift + Enter)
                        if (HardwareKeyboard.instance.isShiftPressed) {
                          // newline
                          return KeyEventResult.ignored; 
                        }

                        // 2. Enter android enter
                        if (event.deviceType != KeyEventDeviceType.keyboard) {
                          return KeyEventResult.ignored; 
                        }                     
                        
                        
                        // 2. Enter
                        if (_messageController.text.trim().isNotEmpty) {
                          askQuestion();
                        }                       
                        
                        return KeyEventResult.handled; 
                      }
                      
                      return KeyEventResult.ignored;
                    },
                    child: TextField(
                      controller: _messageController,
                      //textInputAction: TextInputAction.send, //make android keyboard into send
                      maxLines: null,
                      keyboardType: TextInputType.multiline,
                      textInputAction: TextInputAction.newline,
                      minLines: 1,
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
                ),
                const SizedBox(width: 10),
                FloatingActionButton(
                  onPressed: () {
                    // Logic to send message and get AI response.
                    _isLoading ? stopGeneration() : askQuestion(); 
                  },
                  backgroundColor: primaryTeal,
                  mini: true,
                  child: _isLoading ? const Icon(Icons.stop_circle, size: 18) : const Icon(Icons.send, size: 18),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}