import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; // for links to open mail

class AboutPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'About SpendWize',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF003366), Color(0xFF008080), Color(0xFF87CEEB)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                SizedBox(height: 20),

                // SpendWize Title Box
                _buildInfoBox(
                  title: 'SpendWize',
                  content:
                  'SpendWize is the ultimate financial management app designed to help you take control of your finances, '
                      'set goals, and save more effectively. Whether you\'re tracking your daily expenses, managing savings '
                      'accounts, or exchanging currencies, SpendWize has you covered.',
                ),

                SizedBox(height: 20),

                // Key Features Box
                _buildInfoBox(
                  title: 'Key Features',
                  content:
                  '- 📊 Dual Currency Management: Manage both USD and LBP wallets and savings accounts.\n'
                      '- 💰 Expense & Income Tracking: Categorize transactions to see where your money is going.\n'
                      '- 🔄 Currency Exchange: Easily convert between USD and LBP with custom exchange rates.\n'
                      '- 💳 Transfer Between Accounts: Move funds between your wallet and savings effortlessly.\n'
                      '- 📈 Detailed Reports: Generate comprehensive reports to gain insights into your spending and savings habits.',
                ),

                SizedBox(height: 20),

                // Developer Information Box
                _buildInfoBox(
                  title: 'Developer Information',
                  content:
                  'SpendWize is developed and coded by Bernard Safi, with a focus on providing an easy and intuitive '
                      'experience for managing personal finances. The goal is to empower users to make better financial decisions.',
                ),

                SizedBox(height: 20),

                // Version Information Box
                _buildInfoBox(
                  title: 'Version Information',
                  content: 'Version: 1.0\nRelease Date: October 2024',
                ),

                SizedBox(height: 20),

                // Contact & Support Box
                _buildInfoBox(
                  title: 'Contact & Support',
                  content: [
                    // Added Row for Email
                    Row(
                      children: [
                        Icon(Icons.email, color: Colors.black), // Email Icon
                        SizedBox(width: 8), // Spacing between icon and text
                        GestureDetector(
                          onTap: () async {
                            final Uri emailLaunchUri = Uri(
                              scheme: 'mailto',
                              path: 'bernard.safi@gmail.com',
                              queryParameters: {'subject': 'Feedback for SpendWize'},
                            );

                            // Use launchUrl method with Uri
                            if (await canLaunchUrl(emailLaunchUri)) {
                              await launchUrl(emailLaunchUri);
                            } else {
                              throw 'Could not launch $emailLaunchUri';
                            }
                          },
                          child: Text(
                            'bernard.safi@gmail.com',
                            style: TextStyle(fontSize: 16, color: Colors.black),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8), // Spacing between lines
                    // Added Row for TikTok
                    Row(
                      children: [
                        Icon(Icons.music_note, color: Colors.black), // Placeholder for TikTok Icon
                        SizedBox(width: 8), // Spacing between icon and text
                        Flexible( // Make text wrap
                          child: Text(
                            'Follow us on TikTok: @codewizard91',
                            style: TextStyle(fontSize: 16, color: Colors.black),
                            overflow: TextOverflow.clip, // Handle overflow
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                SizedBox(height: 20),

                // Acknowledgments Box
                _buildInfoBox(
                  title: 'Acknowledgments',
                  content:
                  'Special thanks to the SpendWize community for their valuable feedback and support in helping shape the future of the app.',
                ),

                SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoBox({required String title, required dynamic content}) {
    return Container(
      padding: EdgeInsets.all(16.0),
      margin: EdgeInsets.symmetric(vertical: 8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 8.0,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
          SizedBox(height: 10),
          Divider(color: Colors.grey[300]), // Divider line
          SizedBox(height: 10),
          // Display content (either a single string or a list of widgets)
          if (content is String)
            Text(
              content,
              style: TextStyle(fontSize: 16, color: Colors.black),
            )
          else if (content is List<Widget>)
            ...content,
        ],
      ),
    );
  }
}
