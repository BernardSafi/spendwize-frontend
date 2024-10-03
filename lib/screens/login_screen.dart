import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'register_screen.dart'; // Import the RegisterScreen
import 'home_page.dart'; // Import your HomeScreen
import 'dart:convert';
import 'package:spendwize_frontend/constants.dart';
class LoginScreen extends StatelessWidget {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final storage = FlutterSecureStorage();

  Future<void> login(BuildContext context) async {
    final response = await http.post(
      Uri.parse(loginEndpoint),
      headers: {'Content-Type': 'application/json'},
      body: '{"email": "${emailController.text}", "password": "${passwordController.text}"}',
    );

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body); // Decode the JSON response
      final token = jsonResponse['token']; // Adjust according to your response structure
      await storage.write(key: 'token', value: token); // Save the token

      // Navigate to the HomeScreen
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => HomePage()),
      );
    } else {
      String errorMessage;
      try {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        errorMessage = responseData['error']; // Adjust the key based on your API response structure
      } catch (e) {
        errorMessage = 'Registration failed. Please try again.'; // Fallback if JSON decoding fails
      }
      _showDialog(context, 'Error', 'Registration failed: $errorMessage', false);
    }
  }

  void _showDialog(BuildContext context, String title, String message, bool isSuccess) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: Colors.white.withOpacity(0.9),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isSuccess ? Icons.check_circle : Icons.error,
                  color: isSuccess ? Color(0xFF003366) : Color(0xFF003366), // Updated colors
                  size: 48,
                ),
                SizedBox(height: 16),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isSuccess ? Color(0xFF003366) : Color(0xFF003366), // Updated colors
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.black87),
                ),
                SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF003366),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 14, horizontal: 32),
                  ),
                  child: Text('OK', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        );
      },
    );
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
      extendBodyBehindAppBar: true, // This allows the body to extend behind the AppBar
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Login', style: TextStyle(color: Colors.white)),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF003366), Color(0xFF008080), Color(0xFF87CEEB)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: SingleChildScrollView(
              child: Card(
                color: Colors.white.withOpacity(0.85),
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Login',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(height: 20),
                      TextField(
                        controller: emailController,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Color(0xFF008080)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Color(0xFF003366)),
                          ),
                          labelStyle: TextStyle(color: Colors.grey),
                          focusedErrorBorder: InputBorder.none,
                        ),
                        cursorColor: Color(0xFF003366),
                      ),
                      SizedBox(height: 20),
                      TextField(
                        controller: passwordController,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: Icon(Icons.lock),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Color(0xFF008080)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Color(0xFF003366)),
                          ),
                          labelStyle: TextStyle(color: Colors.grey),
                          focusedErrorBorder: InputBorder.none,
                        ),
                        obscureText: true,
                        cursorColor: Color(0xFF003366),
                      ),
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () => login(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF003366),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Text('Login', style: TextStyle(color: Colors.white)),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => RegisterScreen()),
                          );
                        },
                        child: Text(
                          "Don't have an account? Register",
                          style: TextStyle(color: Color(0xFF003366)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
    );
  }
}
