import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class ChatBotScreen extends StatefulWidget {
  const ChatBotScreen({Key? key}) : super(key: key);

  @override
  _ChatBotScreenState createState() => _ChatBotScreenState();
}

class _ChatBotScreenState extends State<ChatBotScreen> {
  final List<Map<String, String>> messages = [];
  final TextEditingController _controller = TextEditingController();
  late stt.SpeechToText _speech;
  bool _isListening = false;

  // List of quick reply queries updated with additional options
  final List<String> quickReplies = [
    "How to withdraw?",
    "Mining speed?",
    "What is wallet?",
    "Tell me about BTC Rain",
    "Power-ups details",
    "Leaderboard info?",
    "Achievements info?",
    "Daily rewards?",
    "Watch ads?"
  ];

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _loadChatHistory();
  }

  Future<void> _loadChatHistory() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final history = prefs.getStringList('chat_history') ?? [];
    setState(() {
      messages.clear();
      for (var entry in history) {
        // Stored as "sender::text"
        final parts = entry.split("::");
        if (parts.length == 2) {
          messages.add({'sender': parts[0], 'text': parts[1]});
        }
      }
    });
  }

  Future<void> _saveChatHistory() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final history =
    messages.map((m) => "${m['sender']}::${m['text']}").toList();
    await prefs.setStringList('chat_history', history);
  }

  // Improved bot response with extended keywords
  String _getBotResponse(String userInput) {
    userInput = userInput.toLowerCase();
    if (userInput.contains("withdraw")) {
      return "To withdraw BTC, go to your wallet and select 'Withdraw'. The minimum is 0.0001 BTC.";
    } else if (userInput.contains("mining speed")) {
      return "Mining speed can be boosted with power-ups and upgrades!";
    } else if (userInput.contains("wallet")) {
      return "Your wallet shows your BTC balance and transaction history.";
    } else if (userInput.contains("btc rain")) {
      return "BTC Rain: Tap falling Bitcoin icons to collect free BTC! [GIF]";
    } else if (userInput.contains("power-ups")) {
      return "Power-ups include Drill Boost, Explosives, and Energy Boost.";
    } else {
      return "I'm here to help! Try asking about 'withdraw', 'mining speed', 'wallet', or 'BTC Rain'.";
    }
  }

  void _sendMessage({String? quickText}) {
    String text = quickText ?? _controller.text;
    if (text.isEmpty) return;

    setState(() {
      messages.add({'sender': 'user', 'text': text});
    });
    _saveChatHistory();

    String botResponse = _getBotResponse(text);
    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        messages.add({'sender': 'bot', 'text': botResponse});
      });
      _saveChatHistory();
    });
    if (quickText == null) _controller.clear();
  }

  Future<void> _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize();
      if (available) {
        setState(() {
          _isListening = true;
        });
        _speech.listen(onResult: (result) {
          setState(() {
            _controller.text = result.recognizedWords;
          });
        });
      }
    } else {
      setState(() {
        _isListening = false;
      });
      _speech.stop();
    }
  }

  Widget _buildQuickReplies() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: quickReplies.map((reply) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: ElevatedButton(
              onPressed: () => _sendMessage(quickText: reply),
              child: Text(reply, style: const TextStyle(fontSize: 12)),
            ),
          );
        }).toList(),
      ),
    );
  }

  // Optionally display image if response contains "[GIF]"
  Widget _buildMessage(Map<String, String> message) {
    bool isUser = message['sender'] == 'user';
    String text = message['text']!;
    if (!isUser && text.contains("[GIF]")) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              child: Image.network(
                'https://via.placeholder.com/150', // placeholder GIF image URL
                width: 150,
                height: 150,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(text.replaceAll(" [GIF]", ""),
                  style: const TextStyle(fontSize: 16)),
            ),
          ],
        ),
      );
    }

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isUser ? Colors.blue.shade200 : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(text, style: const TextStyle(fontSize: 16)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("ChatBot Support"),
        backgroundColor: Colors.blue,
      ),
      body: Column(
        children: [
          // Quick Replies Row
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: _buildQuickReplies(),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                return _buildMessage(messages[index]);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                // Voice Input Microphone Button
                IconButton(
                  icon: Icon(_isListening ? Icons.mic : Icons.mic_none),
                  onPressed: _listen,
                ),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: "Type a message...",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () => _sendMessage(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
