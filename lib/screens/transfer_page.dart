import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:spendwize_frontend/constants.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';

class AddTransferPage extends StatefulWidget {
  @override
  _TransferPageState createState() => _TransferPageState();
}

final storage = FlutterSecureStorage();

Future<String?> getToken() async {
  return await storage.read(key: 'token');
}

class _TransferPageState extends State<AddTransferPage> {
  double currentUSDBalance = 0.0;
  double currentLBPBalance = 0.0;
  double currentUSDSavings = 0.0;
  double currentLBPSavings = 0.0;
  String userName = ''; // Variable to hold the user's name

  bool isTransferReversed = false; // Variable to track transfer direction
  TextEditingController amountController = TextEditingController(); // Controller for the amount input

  @override
  void initState() {
    super.initState();
    print('Fetching balances and user details...');
    fetchBalances();
    fetchUserName(); // Fetch the user's name on initialization
  }

  @override
  void dispose() {
    amountController.dispose(); // Dispose of the controller when the widget is removed
    super.dispose();
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

  Future<void> transferFunds() async {
    String? token = await getToken();
    final transferEndpoint = isTransferReversed ? walletToSavingsLBP : savingsToWalletLBP;

    final response = await http.post(
      Uri.parse(transferEndpoint), // Replace with your transfer API endpoint
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'amount': 100000, // Example amount, can be dynamic
      }),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Transfer successful')),
      );
      fetchBalances(); // Update the balances after the transfer
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Transfer failed. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final isPortrait = mediaQuery.orientation == Orientation.portrait;
    final screenWidth = mediaQuery.size.width;

    // Check if the keyboard is open
    bool isKeyboardOpen = mediaQuery.viewInsets.bottom > 0;

    return Theme(
      data: Theme.of(context).copyWith(
        textSelectionTheme: TextSelectionThemeData(
          cursorColor: Color(0xFF003366), // Cursor color
          selectionColor: Colors.lightBlue.withOpacity(0.5), // Selection color
          selectionHandleColor: Colors.blue, // Selection handles color
        ),
      ),
      child: Scaffold(
        resizeToAvoidBottomInset: true,
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
                    automaticallyImplyLeading: false,
                    title: Text(
                      'SpendWize',
                      style: TextStyle(color: Colors.white),
                    ),
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    leading: IconButton(
                      icon: Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
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
                            _buildTransferSection(), // Transfer section
                            SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (!isKeyboardOpen) // Show bottom navigation bar only when the keyboard is closed
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: BottomNavigationBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  selectedItemColor: Colors.white,
                  unselectedItemColor: Colors.black,
                  items: const [
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
              style: const TextStyle(fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransferSection() {
    String selectedCurrency = 'USD'; // Default selected currency

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Enter Amount',
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.85),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                ),
                style: TextStyle(color: Colors.black),
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: selectedCurrency,
                items: [
                  DropdownMenuItem(value: 'USD', child: Text('USD')),
                  DropdownMenuItem(value: 'LBP', child: Text('LBP')),
                ],
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.85),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                ),
                onChanged: (String? newValue) {
                  setState(() {
                    selectedCurrency = newValue!;
                  });
                },
                style: TextStyle(color: Colors.black),
              ),
            ),
          ],
        ),
        SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: ElevatedButton.icon(
                label: Text(
                  isTransferReversed ? 'Transfer to Wallet' : 'Transfer to Savings',
                  style: TextStyle(color: Colors.black), // Change text color to black
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white, // Keep button background white
                  padding: EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: () {
                  if (amountController.text.isNotEmpty) {
                    double transferAmount = double.parse(amountController.text);
                    // Use the transferAmount and selectedCurrency for the transfer operation
                    transferFunds();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Please enter a valid amount.')),
                    );
                  }
                },
              ),
            ),
            IconButton(
              icon: Icon(Icons.swap_horiz, size: 40, color: Colors.white),
              onPressed: () {
                setState(() {
                  isTransferReversed = !isTransferReversed;
                });
              },
            ),
          ],
        ),
      ],
    );
  }
}
