import 'dart:async';

import 'package:flutter/material.dart';

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
        totalBtcMined += 0.000001; // simulate earnings
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
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.fromARGB(255, 4, 37, 94),
              Color.fromARGB(255, 165, 151, 25)
            ],
          ),
        ),
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              backgroundColor: const Color.fromARGB(255, 4, 37, 94),
              expandedHeight: 200,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                title: const Text('📜 About Us – Bitcoin Mining Cloud App 🚀'),
                background: Container(
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
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildListDelegate([
                _AnimatedSection(
                  delay: 300,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      "Introduction\nWelcome to Bitcoin Mining Cloud App, the ultimate gamified Bitcoin mining experience! Here, mining is not just about numbers—it's an interactive adventure filled with mini-games, power-ups, challenges, and real BTC rewards.",
                      style: textStyle,
                    ),
                  ),
                ),
                _AnimatedSection(
                  delay: 400,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: RichText(
                      text: TextSpan(
                        style: textStyle,
                        children: [
                          TextSpan(text: '🌍 Our Mission (Why We Exist)\n'),
                          TextSpan(
                              text:
                                  'At Bitcoin Mining Cloud App, we believe that cryptocurrency should be fun, accessible, and rewarding for all.\n'),
                          TextSpan(
                              text:
                                  '💎 Turn Bitcoin mining into a game that anyone can enjoy.\n'),
                          TextSpan(
                              text:
                                  '⚡ Make earning BTC engaging and rewarding.\n'),
                          TextSpan(
                              text:
                                  '🔗 Create a secure, fair, and transparent mining experience.\n'),
                        ],
                      ),
                    ),
                  ),
                ),
                _AnimatedSection(
                  delay: 500,
                  child: const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      '🔥 Why Choose Bitcoin Mining Cloud App?\n\n'
                      '🎮 Gamified Mining Experience – Tap, strategize, and mine BTC through interactive mini-games. Unlock power-ups, achievements, and leaderboard rankings.\n\n'
                      '🔐 Secure & Transparent Earnings – Your BTC earnings are stored safely with real-time transaction tracking.\n\n'
                      '💰 Fair & Fun Rewards – Earn BTC fairly with no hidden fees.\n\n'
                      '🌎 Global Crypto Community – Compete, collaborate, and trade with miners worldwide.\n\n'
                      '⚡ Power-Ups & Customization – Upgrade your mining gear and customize your rig, avatars, and skins.\n',
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
                          'Dynamic BTC Earnings Tracker: ${totalBtcMined.toStringAsFixed(8)} BTC mined globally',
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
                _AnimatedSection(
                  delay: 700,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          '👥 Meet the Team (Tap for Interactive Profiles)',
                          style: boldTextStyle,
                        ),
                        SizedBox(height: 12),
                        _TeamMember(
                          name: 'John Doe',
                          role: 'CEO',
                          description:
                              'Visionary leader with 10+ years in blockchain technology. Passionate about making crypto accessible to everyone.',
                          avatar:
                              'assets/team_member1.png.webp', // updated asset path
                        ),
                        SizedBox(height: 16),
                        _TeamMember(
                          name: 'Jane Smith',
                          role: 'Lead Developer',
                          description:
                              'Expert in blockchain development and smart contracts. Loves building scalable and secure systems.',
                          avatar:
                              'assets/team_member2.png.webp', // updated asset path
                        ),
                      ],
                    ),
                  ),
                ),
                _AnimatedSection(
                  delay: 800,
                  child: const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      '🌟 Our Vision (The Future of Bitcoin Mining Cloud App)\n\n'
                      "🔮 What's Coming Next?\n"
                      '🚀 New Mini-Games – More ways to mine BTC!\n'
                      '🎁 Daily Challenges & Rewards – Earn weekly BTC bonuses!\n'
                      '🏆 Leaderboards & Achievements – Track your progress and claim rewards!\n'
                      '🎨 Mining Rig Customization – Design your dream mining setup!',
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
                                    '“Finally, a mining app that actually lets you earn BTC!”',
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
  final String avatar;

  const _TeamMember({
    required this.name,
    required this.role,
    required this.description,
    required this.avatar,
  });

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: _FlipCard(
        front: Column(
          crossAxisAlignment: CrossAxisAlignment.end, // Align to right
          children: [
            ClipOval(
              child: Image.asset(
                avatar,
                width: 100,
                height: 100,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              name,
              textAlign: TextAlign.right,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
            Text(
              role,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 16, color: Colors.white),
            ),
          ],
        ),
        back: Column(
          crossAxisAlignment: CrossAxisAlignment.end, // Align to right
          children: [
            Text(
              description,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 14, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

class _TestimonialCard extends StatelessWidget {
  final String text;
  final int rating;

  const _TestimonialCard({required this.text, required this.rating});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color.fromARGB(
            25, 255, 255, 255), // 0.1 opacity = 25 in alpha
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(text, style: const TextStyle(fontSize: 14, color: Colors.white)),
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
