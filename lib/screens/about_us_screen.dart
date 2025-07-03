import 'dart:async';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutUsScreen extends StatefulWidget {
  const AboutUsScreen({super.key});

  @override
  State<AboutUsScreen> createState() => _AboutUsScreenState();
}

class _AboutUsScreenState extends State<AboutUsScreen> {
  double totalBtcMined = 0.0;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        try {
          totalBtcMined += 0.000001; // simulate earnings
        } catch (e) {
          debugPrint('Error updating BTC mined: $e');
          // Handle error gracefully
        }
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const textStyle = TextStyle(fontSize: 16, color: Colors.white);
    const boldTextStyle = TextStyle(
        fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          color: Color.fromARGB(255, 4, 37, 94), // Changed to solid blue
        ),
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              backgroundColor: const Color.fromARGB(255, 4, 37, 94),
              expandedHeight: 200,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                title: const Text('📜 About Us – Bitcoin Cloud Mining 🚀'),
                background: Container(
                  decoration: const BoxDecoration(
                    color:
                        Color.fromARGB(255, 4, 37, 94), // Changed to solid blue
                  ),
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildListDelegate([
                const _AnimatedSection(
                  delay: 300,
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'Introduction\nWelcome to Bitcoin Cloud Mining, your trusted platform for cloud-based cryptocurrency mining. We provide a secure, efficient, and user-friendly way to mine Bitcoin through our advanced cloud infrastructure.',
                      style: textStyle,
                    ),
                  ),
                ),
                _AnimatedSection(
                  delay: 400,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: RichText(
                      text: const TextSpan(
                        style: textStyle,
                        children: [
                          TextSpan(text: '🌍 Our Mission\n'),
                          TextSpan(
                              text:
                                  'At Bitcoin Cloud Mining, we are committed to making cryptocurrency mining accessible, efficient, and profitable for everyone.\n\n'),
                          TextSpan(
                              text:
                                  '💎 Provide reliable and efficient cloud mining solutions.\n'),
                          TextSpan(
                              text:
                                  '⚡ Deliver transparent and competitive mining returns.\n'),
                          TextSpan(
                              text:
                                  '🔒 Ensure secure and timely withdrawals.\n'),
                          TextSpan(
                              text:
                                  '🌐 Make Bitcoin mining accessible globally.\n'),
                          TextSpan(
                              text:
                                  '💫 Maintain 99.9% mining facility uptime.\n'),
                        ],
                      ),
                    ),
                  ),
                ),
                const _AnimatedSection(
                  delay: 500,
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      '🔥 Why Choose Bitcoin Cloud Mining?\n\n'
                      '⚡ State-of-the-Art Mining Facilities – Advanced ASIC miners maintained in professional data centers with optimal conditions.\n\n'
                      '🔐 Secure & Transparent Operations – Track your simulated hash rate and BTC earnings in real-time through our cloud mining interface.\n\n'
                      '🎮 Simulated Bitcoin mining experience – Enjoy a rewarding gameplay experience with engaging in-app rewards.\n\n'
                      '💫 24/7 Mining Performance – Continuous operation with 99.9% uptime and professional maintenance.\n\n'
                      '🛟 24/7 Support – Dedicated customer service team available round the clock.\n\n'
                      '⚡ Withdrawals processed within 48 hours if eligible. Withdrawal requests are reviewed and processed based on eligibility.\n',
                      style: textStyle,
                    ),
                  ),
                ),
                _AnimatedSection(
                  delay: 600,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Global Mining Statistics: ${totalBtcMined.toStringAsFixed(18)} BTC (simulated) earned by players through gameplay.',
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.greenAccent),
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: totalBtcMined % 1.0, // Simulate progress
                          backgroundColor: Colors.grey[800],
                          valueColor: const AlwaysStoppedAnimation<Color>(
                              Colors.greenAccent),
                        ),
                      ],
                    ),
                  ),
                ),
                const _AnimatedSection(
                  delay: 700,
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '👥 Meet the Team (Tap for Interactive Profiles)',
                          style: boldTextStyle,
                        ),
                        SizedBox(height: 12),
                        _TeamMember(
                          name: 'Sundar Sah',
                          role: 'CEO & Founder',
                          description:
                              'Visionary entrepreneur and blockchain expert with 10+ years in simulated mining and fintech innovation.',
                        ),
                        SizedBox(height: 16),
                        _TeamMember(
                          name: 'Update This',
                          role: 'CTO',
                          description:
                              'Expert in distributed systems and mining optimization. Leading the development of next-gen simulated mining technology.',
                        ),
                      ],
                    ),
                  ),
                ),
                const _AnimatedSection(
                  delay: 800,
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      '🌟 Our Vision & Future Plans\n\n'
                      '🔮 Upcoming Developments:\n'
                      '🚀 Expanding Mining Facilities – Adding more state-of-the-art data centers\n'
                      '⚡ Enhanced Mining Efficiency – Implementing next-gen ASIC technology\n'
                      '🌐 Global Expansion – New mining facilities in renewable energy locations\n'
                      '💹 Advanced Analytics – Track your simulated hash rate and BTC earnings in real-time through our cloud mining interface.\n'
                      '🔗 Multi-Chain Support – Expanding to simulated mining of other profitable cryptocurrencies',
                      style: textStyle,
                    ),
                  ),
                ),
                _AnimatedSection(
                  delay: 900,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '💬 What Players Say',
                          style: boldTextStyle,
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 120,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: const [
                              _TestimonialCard(
                                text:
                                    '“The best crypto mining game! Super fun and rewarding!”',
                                rating: 5,
                              ),
                              _TestimonialCard(
                                text:
                                    '“I love the power-ups and daily challenges! Keeps me coming back.”',
                                rating: 5,
                              ),
                              _TestimonialCard(
                                text:
                                    '“Finally, a mining app that lets you request BTC withdrawals after reaching a minimum threshold and passing eligibility review!”',
                                rating: 5,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                _AnimatedSection(
                  delay: 1000,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        const Text(
                          '🎮 Join the Mining Revolution Today!',
                          style: boldTextStyle,
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () {
                            // Navigate to sign-up or download page
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.greenAccent,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 32, vertical: 16),
                          ),
                          child: const Text(
                            'Join Now',
                            style: TextStyle(fontSize: 18, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                const _AnimatedSection(
                  delay: 650,
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '🌐 Connect With Us',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 12),
                        Wrap(
                          spacing: 16,
                          runSpacing: 12,
                          children: [
                            _SocialMediaButton(
                              icon: Icons.camera_alt,
                              label: 'Instagram',
                              url:
                                  'https://www.instagram.com/bitcoincloudmining/',
                              color: Color(0xFF833AB4),
                            ),
                            _SocialMediaButton(
                              icon: FontAwesomeIcons.whatsapp,
                              label: 'WhatsApp',
                              url:
                                  'https://chat.whatsapp.com/InL9NrT9gtuKpXRJ3Gu5A5',
                              color: Color(0xFF25D366),
                            ),
                            _SocialMediaButton(
                              icon: Icons.send,
                              label: 'Telegram',
                              url: 'https://t.me/+v6K5Agkb5r8wMjhl',
                              color: Color(0xFF0088cc),
                            ),
                            _SocialMediaButton(
                              icon: Icons.facebook,
                              label: 'Facebook',
                              url:
                                  'https://www.facebook.com/groups/1743859249846928',
                              color: Color(0xFF4267B2),
                            ),
                            _SocialMediaButton(
                              icon: Icons.video_library,
                              label: 'YouTube',
                              url:
                                  'https://www.youtube.com/channel/UC1V43aMm3KYUJu_J9Lx2DAw',
                              color: Color(0xFFFF0000),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                const Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Text(
                    'Note: All earnings shown in this app are simulated and based on in-app gameplay. Bitcoin Cloud Mining is not a real mining operation. BTC rewards are virtual unless stated otherwise.',
                    style: TextStyle(fontSize: 12, color: Colors.white54),
                    textAlign: TextAlign.center,
                  ),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnimatedSection extends StatefulWidget {
  final Widget child;
  final int delay;
  const _AnimatedSection({required this.child, this.delay = 0});

  @override
  State<_AnimatedSection> createState() => _AnimatedSectionState();
}

class _AnimatedSectionState extends State<_AnimatedSection>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _opacityAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _opacityAnimation,
        child: widget.child,
      ),
    );
  }
}

class _TeamMember extends StatelessWidget {
  final String name;
  final String role;
  final String description;

  const _TeamMember({
    required this.name,
    required this.role,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const Icon(
            Icons.person, // Changed from person_circle to person
            size: 100,
            color: Colors.white70,
          ),
          const SizedBox(height: 8),
          Text(
            name,
            textAlign: TextAlign.right,
            style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          Text(
            role,
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 16, color: Colors.white),
          ),
          Text(
            description,
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 14, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _TestimonialCard extends StatelessWidget {
  final String text;
  final int rating;

  const _TestimonialCard({
    required this.text,
    required this.rating,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color.fromARGB(25, 255, 255, 255),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            text,
            style: const TextStyle(fontSize: 14, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Row(
            children: List.generate(
              rating,
              (index) => const Icon(Icons.star, color: Colors.yellow, size: 16),
            ),
          ),
        ],
      ),
    );
  }
}

class _FlipCard extends StatefulWidget {
  final Widget front;
  final Widget back;
  const _FlipCard({required this.front, required this.back});

  @override
  State<_FlipCard> createState() => _FlipCardState();
}

class _FlipCardState extends State<_FlipCard> {
  bool _showFront = true;

  void _toggleCard() {
    setState(() {
      _showFront = !_showFront;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggleCard,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        transitionBuilder: (child, animation) {
          final rotate = Tween(begin: 0.0, end: 1.0).animate(animation);
          return AnimatedBuilder(
            animation: rotate,
            child: child,
            builder: (context, child) {
              final angle = rotate.value * 3.1416;
              return Transform(
                transform: Matrix4.rotationY(angle),
                alignment: Alignment.center,
                child: child,
              );
            },
          );
        },
        switchInCurve: Curves.easeIn,
        switchOutCurve: Curves.easeOut,
        child: _showFront ? widget.front : widget.back,
      ),
    );
  }
}

class _SocialMediaButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String url;
  final Color color;

  const _SocialMediaButton({
    required this.icon,
    required this.label,
    required this.url,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        // ignore: deprecated_member_use
        await launchUrl(Uri.parse(url));
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: color.withAlpha(30),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
