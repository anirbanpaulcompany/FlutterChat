import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_page.dart';
import 'chat_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('jwtToken');

  runApp(MaterialApp(
    title: 'Flutter Chat Demo',
    theme: ThemeData(
      primarySwatch: Colors.deepPurple,
    ),
    home: token != null ? ChatPage() : LoginPage(),
  ));
}

