import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'login_page.dart';


class ChatPage extends StatelessWidget {
  const ChatPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Chat'),
            const SizedBox(width: 8), 
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: Colors.green, 
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10.0), 
            child: IconButton(
              icon: Icon(Icons.logout, color: Colors.red), 
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.remove('jwtToken');
                await prefs.remove('messages');

                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                );             
              },
            ),
          ),
        ],
      ),
      body: Container(
        color: Colors.black, 
        child: ChatScreen(),
      ),
    );
  }
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  List<String> _messages = [];
  late WebSocketChannel _channel;

  @override
  void initState() {
    super.initState();
    _channel = WebSocketChannel.connect(Uri.parse('wss://echo.websocket.events'));
    _fetchMessages();
    _channel.stream.listen((data) {
      String message = data.toString();
      if (!message.contains('echo.websocket.events')) {
        setState(() {
          _messages.add('Server: $message');
          _saveMessagesLocally(_messages);
        });
      }
    });
  }

  @override
  void dispose() {
    _channel.sink.close();
    super.dispose();
  }

  Future<void> _sendMessage(String message) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwtToken');


    if (token == null) {
      return;
    }

//just for github page

    if (token == '123') {
        setState(() {
        _messages.add('You: $message');
        _saveMessagesLocally(_messages);
        });
      _channel.sink.add(message);
      _messageController.clear();
    }

    final url = Uri.parse('http://localhost:1337/chats');

    try {
      final response = await http.post(
        url,
        body: {'text': message, 'token': token},
      );

      if (response.statusCode == 200 ) {
        setState(() {
          _messages.add('You: $message');
          _saveMessagesLocally(_messages);
        });
        _channel.sink.add(message);
        _messageController.clear();
      } else {
        print('Failed to send message');
      }
    } catch (error) {
      print('Error sending message');
    }
  }

  Future<void> _fetchMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final savedMessages = prefs.getStringList('messages');

    if (savedMessages != null) {
      setState(() {
        _messages = savedMessages;
      });
    }

    final url = Uri.parse('http://localhost:1337/chats');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final dynamic responseBody = jsonDecode(response.body);

        if (responseBody is List<dynamic>) {
          setState(() {
            _messages.addAll(responseBody.map((msg) => msg['text'] != null ? 'Server: ${msg['text']}' : ''));
          });
          _saveMessagesLocally(_messages);
        } else if (responseBody is Map<String, dynamic>) {
          setState(() {
            if (responseBody['text'] != null) {
              _messages.add('Server: ${responseBody['text']}');
            }
          });
          _saveMessagesLocally(_messages);
        } else {
          print('Invalid response format');
        }
      } else {
        print('Failed to fetch messages');
      }
    } catch (error) {
      print('Error fetching messages');
    }
  }

  Future<void> _saveMessagesLocally(List<String> messages) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('messages', messages);
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: _messages.length,
            itemBuilder: (context, index) {
              final message = _messages[index];
              final isServerMessage = message.startsWith('Server:');
              return Align(
                alignment: isServerMessage ? Alignment.centerLeft : Alignment.centerRight,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isServerMessage ? Colors.purple : Colors.yellow,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    message,
                    style: TextStyle(
                      color: isServerMessage ? Colors.white : Colors.black,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0), 
                  child: TextField(
                    controller: _messageController,
                    style: TextStyle(color: Colors.white), 
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      hintStyle: TextStyle(color: Colors.white), 
                      filled: true,
                      fillColor: Colors.grey[900],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30), 
                        borderSide: BorderSide.none, 
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.send),
                onPressed: () {
                  final message = _messageController.text.trim();
                  if (message.isNotEmpty) {
                    _sendMessage(message);
                  }
                },
                color: Colors.white, 
                iconSize: 30, 
              ),
            ],
          ),
        ),
      ],
    );
  }
}
