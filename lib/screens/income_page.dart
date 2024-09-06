import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:spendwize_frontend/constants.dart'; // Your API endpoints/constants file

class AddIncomePage extends StatefulWidget {
  @override
  _AddIncomePageState createState() => _AddIncomePageState();
}

class _AddIncomePageState extends State<AddIncomePage> {
  final storage = FlutterSecureStorage();

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _amountController = TextEditingController();
  String _selectedCurrency = 'USD';
  String _selectedIncomeType = 'Salary'; // Default income type
  bool _isLoading = false;

  // Predefined income types (you can adjust these to match your DB)
  final List<String> incomeTypes = ['Salary', 'Bonus', 'Investment', 'Freelance', 'Other'];

  // Function to get token from storage
  Future<String?> getToken() async {
    return await storage.read(key: 'token');
  }

  // Function to submit the income to the backend
  Future<void> addIncome() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      String? token = await getToken();
      final response = await http.post(
        Uri.parse(addIncomeEndpoint),  // Replace with your actual API endpoint for adding income
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'amount': _amountController.text,
          'currency': _selectedCurrency,
          'income_type': _selectedIncomeType,
        }),
      );

      setState(() {
        _isLoading = false;
      });

      if (response.statusCode == 200) {
        // Success response handling
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Income added successfully!')),
        );
        Navigator.pop(context); // Go back after successful submission
      } else {
        // Error response handling
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add income. Please try again.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, // No back arrow
        title: Text('Add Income'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
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
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Amount',
                      labelStyle: TextStyle(color: Colors.white),
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.8),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter an amount';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    value: _selectedCurrency,
                    items: ['USD', 'LBP'].map((currency) {
                      return DropdownMenuItem<String>(
                        value: currency,
                        child: Text(currency),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      setState(() {
                        _selectedCurrency = newValue!;
                      });
                    },
                    decoration: InputDecoration(
                      labelText: 'Currency',
                      labelStyle: TextStyle(color: Colors.white),
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.8),
                    ),
                  ),
                  SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    value: _selectedIncomeType,
                    items: incomeTypes.map((type) {
                      return DropdownMenuItem<String>(
                        value: type,
                        child: Text(type),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      setState(() {
                        _selectedIncomeType = newValue!;
                      });
                    },
                    decoration: InputDecoration(
                      labelText: 'Income Type',
                      labelStyle: TextStyle(color: Colors.white),
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.8),
                    ),
                  ),
                  SizedBox(height: 40),
                  ElevatedButton(
                    onPressed: _isLoading ? null : addIncome,
                    child: _isLoading
                        ? CircularProgressIndicator(color: Colors.white)
                        : Text('Add Income'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.85),
                      padding: EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
