import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:spendwize_frontend/constants.dart';

class ExchangePage extends StatefulWidget {
  @override
  _ExchangePageState createState() => _ExchangePageState();
}

final storage = FlutterSecureStorage();

Future<String?> getToken() async {
  return await storage.read(key: 'token');
}

class _ExchangePageState extends State<ExchangePage> {
  double currentUSDBalance = 0.0;
  double currentLBPBalance = 0.0;
  String selectedCurrencyTo = 'LBP'; // Currency being exchanged to
  double exchangeRate = 0.0; // For storing the exchange rate
  DateTime? _selectedDate; // Variable to store the selected date
  TextEditingController amountController = TextEditingController();
  bool _isLoading = false;

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
  }

  Future<void> getWalletBalance() async {
    String? token = await storage.read(key: 'token');

    final response = await http.get(
      Uri.parse(walletBalanceEndpoint), // Replace with your actual endpoint
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
    } else {
      print('Failed to retrieve wallet balance: ${response.statusCode}');
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

  Future<void> exchangeCurrency() async {
    setState(() {
      _isLoading = true;
    });

    // Get token and validate input
    String? token = await getToken();
    double amount = double.tryParse(amountController.text) ?? 0.0;

    if (amount <= 0 || exchangeRate <= 0) {
      // Show SnackBar for invalid input
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a valid amount and exchange rate')),
      );

      // Reset loading state and return early
      setState(() {
        _isLoading = false;
      });
      return;
    }

    String fromAccount;
    String toAccount;

    // Determine from_account and to_account based on selectedCurrencyTo
    if (selectedCurrencyTo == 'LBP') {
      fromAccount = 'wallet_usd';
      toAccount = 'wallet_lbp';
    } else {
      fromAccount = 'wallet_lbp';
      toAccount = 'wallet_usd';
    }
    print(fromAccount);
    print(toAccount);

    try {
      print(currencyExchangeEndpoint);
      // Perform the API request
      final response = await http.post(
        Uri.parse(currencyExchangeEndpoint), // Replace with your actual exchange endpoint
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'from_account': fromAccount,
          'to_account': toAccount,
          'amount': amount, // Send the original amount
          'exchange_rate': exchangeRate, // Send exchange rate
          'date': _selectedDate != null ? DateFormat('yyyy-MM-dd').format(_selectedDate!) : null,
        }),
      );

      setState(() {
        _isLoading = false;
      });
      print(response.statusCode);
      if (response.statusCode == 201) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Exchange successful')),
        );
        fetchBalances(); // Update balances after exchange
      } else {
        // Show failure message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Exchange failed. Please try again.')),
        );
      }
    } catch (e) {
      // Handle error and reset loading state
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred: $e')),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final isKeyboardOpen = mediaQuery.viewInsets.bottom != 0; // Check if keyboard is open

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
                  automaticallyImplyLeading: false,
                  title: Text('SpendWize', style: TextStyle(color: Colors.white)),
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  leading: IconButton(
                    icon: Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(height: 20),
                          _buildBalanceCard('Current Balance', currentUSDBalance, currentLBPBalance),
                          SizedBox(height: 20),
                          _buildExchangeSection(isKeyboardOpen),
                          SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Show Bottom Navigation Bar only when keyboard is closed
          if (!isKeyboardOpen)
            Align(
              alignment: Alignment.bottomCenter,
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
    );
  }

  Widget _buildBalanceCard(String title, double usdBalance, double lbpBalance) {
    return Card(
      elevation: 4,
      color: Colors.white.withOpacity(0.85),
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(title, style: TextStyle(fontSize: 20)),
            SizedBox(height: 10),
            Text('USD: ${usdBalance.toStringAsFixed(2)} \$', style: TextStyle(fontSize: 18)),
            Text('LBP: ${NumberFormat('#,##0', 'en_US').format(lbpBalance)} LBP', style: const TextStyle(fontSize: 18)),
          ],
        ),
      ),
    );
  }

  Widget _buildExchangeSection(bool isKeyboardOpen) {
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
                  hintText: 'Enter Amount to Transfer',
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
          ],
        ),
        SizedBox(height: 20),
        Text(
          'Select currency to transfer to',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
        ),
        SizedBox(height: 10),
        DropdownButtonFormField<String>(
          value: selectedCurrencyTo,
          onChanged: (String? newValue) {
            setState(() {
              selectedCurrencyTo = newValue!;
            });
          },
          items: <String>['LBP', 'USD']
              .map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
          decoration: InputDecoration(
            hintText: 'Select Currency To Transfer',
            filled: true,
            fillColor: Colors.white.withOpacity(0.85),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        SizedBox(height: 20),
        TextField(
          keyboardType: TextInputType.number,
          onChanged: (value) {
            setState(() {
              exchangeRate = double.tryParse(value) ?? 0.0;
            });
          },
          decoration: InputDecoration(
            hintText: 'Enter Exchange Rate',
            filled: true,
            fillColor: Colors.white.withOpacity(0.85),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          ),
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
        SizedBox(
          width: double.infinity, // Makes the button take the full width
          child: ElevatedButton(
            onPressed: _isLoading ? null : exchangeCurrency,
            child: _isLoading
                ? CircularProgressIndicator(color: Colors.white)
                : Text(
              'Exchange',
              style: TextStyle(color: Colors.black),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.85),
              padding: EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }
}
