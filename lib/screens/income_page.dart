import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart'; // To format the selected date
import 'package:spendwize_frontend/constants.dart'; // Your API endpoints/constants file

class AddIncomePage extends StatefulWidget {

  @override
  _AddIncomePageState createState() => _AddIncomePageState();
}

class _AddIncomePageState extends State<AddIncomePage> {

  final storage = FlutterSecureStorage();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  String _selectedCurrency = 'USD';
  String _selectedIncomeType = 'Salary';
  DateTime? _selectedDate; // Variable to store the selected date
  bool _isLoading = false;

  final List<String> incomeTypes = ['Salary', 'Bonus', 'Investment', 'Freelance', 'Other'];

  Future<String?> getToken() async {
    return await storage.read(key: 'token');
  }

  Future<void> addIncome() async {
    setState(() {
      _isLoading = true;
    });

    String? token = await getToken();
    final response = await http.post(
      Uri.parse(addIncomeEndpoint),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'amount': _amountController.text,
        'currency': _selectedCurrency,
        'description': _descriptionController.text,
        'income_type': _selectedIncomeType,
        'date': _selectedDate != null ? DateFormat('yyyy-MM-dd').format(_selectedDate!) : null, // Sending the selected date
      }),
    );


    setState(() {
      _isLoading = false;
    });

    if (response.statusCode == 201) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Income added successfully!')),
      );
      Navigator.pop(context);
    } else {
      // Parse the response body for error messages
      final responseData = jsonDecode(response.body);
      String errorMessage = responseData['message'] ?? 'Failed to add income. Please try again.';

      // Extract error details if available
      String errorDetails = '';
      if (responseData.containsKey('errors')) {
        responseData['errors'].forEach((key, value) {
          errorDetails += '$key: ${value.join(', ')}\n'; // Join multiple error messages
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$errorMessage\n$errorDetails')),
      );
    }
  }

  // Function to pick a date
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

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        textSelectionTheme: TextSelectionThemeData(
          cursorColor: Color(0xFF003366),
          selectionColor: Color(0xFF003366).withOpacity(0.5),
          selectionHandleColor: Color(0xFF003366),
        ),
      ),
      child: Scaffold(
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
            Column(
              children: [
                AppBar(
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
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextField(
                          controller: _amountController,
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
                            hintText: 'Select Currency',
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
                            hintText: 'Select Income Type',
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
                        TextField(
                          controller: _descriptionController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            hintText: 'Enter Description',
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
                        SizedBox(height: 40),
                        ElevatedButton(
                          onPressed: _isLoading ? null : addIncome,
                          child: _isLoading
                              ? CircularProgressIndicator(color: Colors.white)
                              : Text(
                            'Add Income',
                            style: TextStyle(color: Colors.black),
                          ),
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
          ],
        ),
      ),
    );
  }
}
