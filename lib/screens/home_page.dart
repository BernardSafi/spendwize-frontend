import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:spendwize_frontend/constants.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

final storage = FlutterSecureStorage();

Future<String?> getToken() async {
  return await storage.read(key: 'token');
}

class _HomePageState extends State<HomePage> {
  double currentUSDBalance = 0.0;
  double currentLBPBalance = 0.0;
  double currentUSDSavings = 0.0;
  double currentLBPSavings = 0.0;
  String userName = ''; // Variable to hold the user's name

  @override
  void initState() {
    super.initState();
    print('Fetching balances and user details...');
    fetchBalances();
    fetchUserName(); // Fetch the user's name on initialization
  }

  Future<void> fetchBalances() async {
    await getWalletBalance();
    await getSavingsBalance();
  }

  Future<void> getSavingsBalance() async {
    String? token = await storage.read(key: 'token');

    final response = await http.get(
      Uri.parse(savingsBalanceEndpoint), // Replace with your actual savings balance API endpoint
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print(data);
      setState(() {
        currentUSDSavings = double.tryParse(data['usd_balance'].toString()) ?? 0.0;
        currentLBPSavings = double.tryParse(data['lbp_balance'].toString()) ?? 0.0;
      });

    } else {
      print('Failed to retrieve savings balance: ${response.statusCode}');
      print('Response body: ${response.body}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load savings balances. Please try again.')),
      );
    }
  }

  Future<void> getWalletBalance() async {
    String? token = await storage.read(key: 'token');


    final response = await http.get(
      Uri.parse(walletBalanceEndpoint),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        currentUSDBalance = double.tryParse(data['usd_balance'].toString()) ?? 0.0;
        currentLBPBalance = double.tryParse(data['lbp_balance'].toString()) ?? 0.0;
      });
      print("Current USD Balance: ${data['usd_balance']}");
    } else {
      print('Failed to retrieve wallet balance: ${response.statusCode}');
      print('Response body: ${response.body}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load balances. Please try again.')),
      );
    }
  }

  Future<void> fetchUserName() async {
    String? token = await storage.read(key: 'token');
    final response = await http.get(
      Uri.parse(usernameEndpoint), // Replace with your actual API URL
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      print('ok');
      final data = jsonDecode(response.body);
      setState(() {
        userName = data['name']; // Set the user's name
      });
    } else {
      print('Failed to retrieve user name: ${response.statusCode}');
      print('Response body: ${response.body}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load user name. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final isPortrait = mediaQuery.orientation == Orientation.portrait;
    final screenHeight = mediaQuery.size.height;
    final screenWidth = mediaQuery.size.width;

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF003366), Color(0xFF008080), Color(0xFF87CEEB)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              children: [
                AppBar(
                  title: Text(
                    'SpendWize',
                    style: TextStyle(color: Colors.white),
                  ),
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  actions: [
                    IconButton(
                      icon: Icon(
                        Icons.account_circle,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        // Navigate to profile settings
                      },
                    ),
                  ],
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isPortrait ? 16.0 : 32.0,
                      vertical: 16.0,
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Welcome back, ${userName.isNotEmpty ? userName : "User"}!',
                            style: TextStyle(
                              fontSize: isPortrait ? 24 : 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 20),
                          _buildBalanceCard(
                            title: 'Current Balances',
                            usdBalance: currentUSDBalance,
                            lbpBalance: currentLBPBalance,
                            screenWidth: screenWidth,
                          ),
                          SizedBox(height: 20),
                          _buildBalanceCard(
                            title: 'Current Savings',
                            usdBalance: currentUSDSavings,
                            lbpBalance: currentLBPSavings,
                            screenWidth: screenWidth,
                          ),
                          SizedBox(height: 20),
                          _buildActionButtons(),
                          SizedBox(height: 40),
                          Text(
                            'Recent Transactions',
                            style: TextStyle(
                              fontSize: isPortrait ? 20 : 24,
                              color: Colors.black,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 20),
                          _buildTransactionList(screenHeight: screenHeight),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: BottomNavigationBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              selectedItemColor: Colors.white,
              items: [
                BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
                BottomNavigationBarItem(icon: Icon(Icons.receipt), label: 'Transactions'),
                BottomNavigationBarItem(icon: Icon(Icons.show_chart), label: 'Reports'),
                BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
              ],
              currentIndex: 0,
              onTap: (index) {
                // Handle navigation based on the selected index
              },
              type: BottomNavigationBarType.fixed,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceCard({
    required String title,
    required double usdBalance,
    required double lbpBalance,
    required double screenWidth,
  }) {
    return Card(
      elevation: 4,
      color: Colors.white.withOpacity(0.85),
      child: Padding(
        padding: EdgeInsets.all(screenWidth * 0.04),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(fontSize: 20),
            ),
            SizedBox(height: 10),
            Text(
              'USD: ${usdBalance.toStringAsFixed(2)} \$',
              style: TextStyle(fontSize: 18),
            ),
            Text(
              'LBP: ${NumberFormat('#,##0', 'en_US').format(lbpBalance)} LBP',
              style: TextStyle(fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              // Add income action
            },
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Colors.white.withOpacity(0.85),
            ),
            child: Text(
              'Add Income',
              style: TextStyle(color: Colors.black),
            ),
          ),
        ),
        SizedBox(width: 20),
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              // Add expense action
            },
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Colors.white.withOpacity(0.85),
            ),
            child: Text(
              'Add Expense',
              style: TextStyle(color: Colors.black),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionList({required double screenHeight}) {
    return Container(
      height: screenHeight * 0.25,
      padding: EdgeInsets.only(bottom: screenHeight * 0.10),
      child: ListView.builder(
        itemCount: 5, // Example transaction count
        itemBuilder: (context, index) {
          return ListTile(
            title: Text('Transaction ${index + 1}'),
            subtitle: Text('Details about the transaction...'),
            trailing: Text('\$${(index + 1) * 10}'), // Example amount
            onTap: () {
              // Handle transaction tap
            },
          );
        },
      ),
    );
  }
}
