import 'package:bitcoin_cloud_mining/services/ad_service.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import 'chatbot_screen.dart'; // added import for ChatBotScreen

class ContactSupportScreen extends StatefulWidget {
  const ContactSupportScreen({super.key});

  @override
  State<ContactSupportScreen> createState() => _ContactSupportScreenState();
}

class _ContactSupportScreenState extends State<ContactSupportScreen> {
  final AdService _adService = AdService();
  bool _adLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadNativeAd();
  }

  Future<void> _loadNativeAd() async {
    try {
      await _adService.loadNativeAd();
      setState(() {
        _adLoaded = true;
      });
    } catch (e) {
      // Optionally handle ad load error
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contact Support'),
        backgroundColor: const Color.fromARGB(255, 4, 37, 94),
      ),
      // Add floating chat button
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ChatBotScreen()),
          );
        },
        child: const Icon(Icons.chat),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.fromARGB(255, 4, 37, 94),
              Color.fromARGB(255, 165, 151, 25)
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Contact Information Section
                const Text(
                  'Contact Information',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.email, color: Colors.blue),
                          title: const Text('Email'),
                          subtitle: const Text(
                              'bitcoincloudminingformobile@gmail.com'),
                          onTap: () {
                            // Open email client
                          },
                        ),
                        const Divider(),
                        ListTile(
                          leading: const Icon(Icons.phone, color: Colors.green),
                          title: const Text('Phone'),
                          subtitle: const Text('+91 (931) 191-3606'),
                          onTap: () {
                            // Open phone dialer
                          },
                        ),
                        const Divider(),
                        const ListTile(
                          leading:
                              Icon(Icons.access_time, color: Colors.orange),
                          title: Text('Support Hours'),
                          subtitle: Text('Mon-Fri: 9 AM - 5 PM (GMT)'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // FAQ Section
                const Text(
                  'Frequently Asked Questions',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                const ExpansionTile(
                  title: Text(
                    'How do I reset my password?',
                    style: TextStyle(color: Colors.white),
                  ),
                  children: [
                    Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        "To reset your password, go to the login screen and click on 'Forgot Password'. Follow the instructions sent to your email.",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
                const ExpansionTile(
                  title: Text(
                    'How do I contact support?',
                    style: TextStyle(color: Colors.white),
                  ),
                  children: [
                    Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        'You can contact support via email, phone, or the contact form below.',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Native Ad Section
                if (_adLoaded) _adService.getNativeAd(),
                // Social Media Links
                const Text(
                  'Follow Us',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const FaIcon(FontAwesomeIcons.facebookF,
                          color: Colors.blue),
                      onPressed: () async {
                        final uri = Uri.parse(
                            'https://www.facebook.com/groups/1743859249846928');
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri);
                        }
                      },
                    ),
                    IconButton(
                      icon: const FaIcon(FontAwesomeIcons.instagram,
                          color: Colors.purple),
                      onPressed: () async {
                        final uri = Uri.parse(
                            'https://www.instagram.com/bitcoincloudmining/');
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri);
                        }
                      },
                    ),
                    IconButton(
                      icon: const FaIcon(FontAwesomeIcons.telegram,
                          color: Colors.blueAccent),
                      onPressed: () async {
                        final uri = Uri.parse('https://t.me/+v6K5Agkb5r8wMjhl');
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri);
                        }
                      },
                    ),
                    IconButton(
                      icon: const FaIcon(FontAwesomeIcons.whatsapp,
                          color: Color(0xFF25D366)),
                      onPressed: () async {
                        final uri = Uri.parse(
                            'https://chat.whatsapp.com/InL9NrT9gtuKpXRJ3Gu5A5');
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri);
                        }
                      },
                    ),
                    IconButton(
                      icon: const FaIcon(FontAwesomeIcons.youtube,
                          color: Colors.red),
                      onPressed: () async {
                        final uri = Uri.parse(
                            'https://www.youtube.com/channel/UC1V43aMm3KYUJu_J9Lx2DAw');
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri);
                        }
                      },
                    ),
                    IconButton(
                      icon: const FaIcon(FontAwesomeIcons.squareTwitter,
                          color: Colors.lightBlue),
                      onPressed: () async {
                        final uri = Uri.parse('https://x.com/bitcoinclmining');
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri);
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Insert ChatBot button below Social Media Links
                Center(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const ChatBotScreen()),
                      );
                    },
                    icon: const Icon(Icons.chat),
                    label: const Text('Chat with our Bot'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue, // Button color
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
