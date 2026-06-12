import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/pages/chat_page.dart';
import 'package:frontend/pages/login_page.dart';
import 'package:frontend/services/api_config.dart';
import 'package:frontend/widgets/thinking_indicator.dart';
import 'package:http/http.dart' as http;
import 'package:frontend/models/chat_message_model.dart';
import 'package:frontend/widgets/chat_bubble_widget.dart';
import 'dart:convert';

const Color primaryTeal = Color(0xFF2A8C93);

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Lap Yu',
      theme: ThemeData(
        primarySwatch: Colors.teal, // This will handle many colors automatically
        primaryColor: primaryTeal,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const AppConfigurationWrapper(),
    );
  }
}

class AppConfigurationWrapper extends StatefulWidget {
  const AppConfigurationWrapper({super.key});

  @override
  State<AppConfigurationWrapper> createState() => _AppConfigurationWrapperState();
}

class _AppConfigurationWrapperState extends State<AppConfigurationWrapper> {
  String? _userId; // Holds the global session ID

  @override
  Widget build(BuildContext context) {
    // If we don't have a sessionId yet, show the input screen
    if (_userId == null) {
      return LoginPage(
        onLoginIdEntered: (id) {
          setState(() {
            _userId = id;
          });
        },
      );
    }

    // Once we have the sessionId, load the main Chat Screen
    return ChatPage(userId: _userId!);
  }
}



