import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import 'chatbot_screen.dart'; // added import for ChatBotScreen

class ContactSupportScreen extends StatelessWidget {
  const ContactSupportScreen({super.key});

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
                          subtitle: const Text('support@bitcoinminingapp.com'),
                          onTap: () {
                            // Open email client
                          },
                        ),
                        const Divider(),
                        ListTile(
                          leading: const Icon(Icons.phone, color: Colors.green),
                          title: const Text('Phone'),
                          subtitle: const Text('+1 (123) 456-7890'),
                          onTap: () {
                            // Open phone dialer
                          },
                        ),
                        const Divider(),
                        ListTile(
                          leading: const Icon(Icons.access_time,
                              color: Colors.orange),
                          title: const Text('Support Hours'),
                          subtitle: const Text('Mon-Fri: 9 AM - 5 PM (GMT)'),
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
                ExpansionTile(
                  title: const Text(
                    'How do I reset my password?',
                    style: TextStyle(color: Colors.white),
                  ),
                  children: const [
                    Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        "To reset your password, go to the login screen and click on 'Forgot Password'. Follow the instructions sent to your email.",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
                ExpansionTile(
                  title: const Text(
                    'How do I contact support?',
                    style: TextStyle(color: Colors.white),
                  ),
                  children: const [
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

                // Contact Form
                const Text(
                  'Contact Form',
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
                        TextField(
                          decoration: InputDecoration(
                            labelText: 'Name',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          decoration: InputDecoration(
                            labelText: 'Email',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          decoration: InputDecoration(
                            labelText: 'Message',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 4,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            // Handle form submission
                          },
                          child: const Text('Submit'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

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
                        final uri =
                            Uri.parse('https://facebook.com/yourchannel');
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri);
                        }
                      },
                    ),
                    IconButton(
                      icon: const FaIcon(FontAwesomeIcons.squareTwitter,
                          color: Colors.lightBlue),
                      onPressed: () async {
                        final uri =
                            Uri.parse('https://twitter.com/yourchannel');
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri);
                        }
                      },
                    ),
                    IconButton(
                      icon: const FaIcon(FontAwesomeIcons.instagram,
                          color: Colors.purple),
                      onPressed: () async {
                        final uri =
                            Uri.parse('https://instagram.com/yourchannel');
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri);
                        }
                      },
                    ),
                    IconButton(
                      icon: const FaIcon(FontAwesomeIcons.youtube,
                          color: Colors.red),
                      onPressed: () async {
                        final uri =
                            Uri.parse('https://youtube.com/yourchannel');
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri);
                        }
                      },
                    ),
                    IconButton(
                      icon: const FaIcon(FontAwesomeIcons.telegram,
                          color: Colors.blueAccent),
                      onPressed: () async {
                        final uri = Uri.parse('https://t.me/yourchannel');
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
