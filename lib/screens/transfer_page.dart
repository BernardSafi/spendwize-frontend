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
  String selectedCurrency = 'USD';
  DateTime? _selectedDate;


  bool isTransferReversed = false; // Variable to track transfer direction
  TextEditingController amountController = TextEditingController(); // Controller for the amount input


  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    fetchBalances();
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

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate)
      setState(() {
        _selectedDate = picked;
      });
  }

  Future<void> transferFunds(String action, String currency) async {
    String? token = await getToken();
    print(action);
    print(currency);

    String? transferEndpoint;

    // Determine the transfer endpoint based on the action and currency
    if (action == 'Transfer to Savings' && currency == 'USD') {
      transferEndpoint = walletToSavingsUSD; // Replace with your actual endpoint
    } else if (action == 'Transfer to Wallet' && currency == 'USD') {
      transferEndpoint = savingsToWalletUSD; // Replace with your actual endpoint
    } else if (action == 'Transfer to Savings' && currency == 'LBP') {
      transferEndpoint = walletToSavingsLBP; // Replace with your actual endpoint
    } else if (action == 'Transfer to Wallet' && currency == 'LBP') {
      transferEndpoint = savingsToWalletLBP; // Replace with your actual endpoint
    } else {
      // Handle invalid action/currency combination
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invalid transfer action or currency')),
      );
      return;
    }

    // Get the amount from the text field
    String? amountText = amountController.text;
    double? amount = double.tryParse(amountText); // Convert the text to a double

    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    print(transferEndpoint);
    print(amount);

    try {
      final response = await http.post(
        Uri.parse(transferEndpoint),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'amount': amount,
          'date': _selectedDate != null ? DateFormat('yyyy-MM-dd').format(_selectedDate!) : null,
        }),
      );

      print(response.statusCode);

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Transfer successful')),
        );
        fetchBalances(); // Update the balances after the transfer
      } else {
        String errorMessage = 'Transfer failed. Please try again.';
        if (response.body.isNotEmpty) {
          // Optionally extract a more specific error message
          final Map<String, dynamic> errorResponse = jsonDecode(response.body);
          if (errorResponse['message'] != null) {
            errorMessage = errorResponse['message'];
          }
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    } catch (e) {
      // Handle any exceptions that may occur
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred: $e')),
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
                  selectedItemColor: Colors.black,
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
        // Date Picker Section
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () => _selectDate(context),
                child: Text(
                  _selectedDate == null
                      ? 'Select Date'
                      : 'Date: ${DateFormat('yyyy-MM-dd').format(_selectedDate!)}',
                  style: TextStyle(color: Colors.black),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.85),
                  padding: EdgeInsets.symmetric(vertical: 16),
                ),
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
                  String selectedAction = 'Transfer to Savings'; // or 'Transfer to Wallet'
                  if(isTransferReversed){
                    selectedAction='Transfer to Wallet';
                  }
                  print(selectedAction);
                  transferFunds(selectedAction, selectedCurrency);
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
