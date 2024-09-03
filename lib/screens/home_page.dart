import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  // Sample balances (replace these with actual data from your backend or state management)
  final double currentUSDBalance = 150.0; // Replace with actual USD balance
  final double currentLBPBalance = 300000.0; // Replace with actual LBP balance
  final double currentUSDSavings = 50.0; // Replace with actual USD savings balance
  final double currentLBPSavings = 100000.0; // Replace with actual LBP savings balance

  @override
  Widget build(BuildContext context) {
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
                  title: Text('SpendWize'),
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  actions: [
                    IconButton(
                      icon: Icon(Icons.account_circle),
                      onPressed: () {
                        // Navigate to profile settings
                      },
                    ),
                  ],
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          Text(
                            'Welcome back, [User\'s Name]!',
                            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          SizedBox(height: 20),
                          Card(
                            elevation: 4,
                            color: Colors.white.withOpacity(0.85),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                children: [
                                  Text('Current Balances', style: TextStyle(fontSize: 20)),
                                  SizedBox(height: 10),
                                  Text('USD: \$${currentUSDBalance.toStringAsFixed(2)}', style: TextStyle(fontSize: 18)),
                                  Text('LBP: LBP ${currentLBPBalance.toStringAsFixed(0)}', style: TextStyle(fontSize: 18)),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: 20),
                          Card(
                            elevation: 4,
                            color: Colors.white.withOpacity(0.85),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                children: [
                                  Text('Current Savings', style: TextStyle(fontSize: 20)),
                                  SizedBox(height: 10),
                                  Text('Savings USD: \$${currentUSDSavings.toStringAsFixed(2)}', style: TextStyle(fontSize: 18)),
                                  Text('Savings LBP: LBP ${currentLBPSavings.toStringAsFixed(0)}', style: TextStyle(fontSize: 18)),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              ElevatedButton(
                                onPressed: () {
                                  // Add income action
                                },
                                child: Text('Add Income'),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  // Add expense action
                                },
                                child: Text('Add Expense'),
                              ),
                            ],
                          ),
                          SizedBox(height: 40),
                          Text('Recent Transactions', style: TextStyle(fontSize: 20, color: Colors.white)),
                          // Scrollable ListView for recent transactions
                          Container(
                            height: 250, // Set a fixed height for scrolling
                            child: ListView.builder(
                              itemCount: 5, // Replace with actual transaction count
                              itemBuilder: (context, index) {
                                return ListTile(
                                  title: Text('Transaction ${index + 1}', style: TextStyle(color: Colors.white)),
                                  subtitle: Text('Details of transaction ${index + 1}', style: TextStyle(color: Colors.white)),
                                  trailing: Text('-\$[Amount]', style: TextStyle(color: Colors.white)), // Replace with actual amount
                                );
                              },
                            ),
                          ),
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
              backgroundColor: Colors.transparent, // Make BottomNavigationBar transparent
              elevation: 0, // Remove shadow
              selectedItemColor: Colors.white, // Set selected item text color to white
              items: [
                BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
                BottomNavigationBarItem(icon: Icon(Icons.receipt), label: 'Transactions'),
                BottomNavigationBarItem(icon: Icon(Icons.show_chart), label: 'Reports'),
                BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
              ],
              currentIndex: 0, // Set the current index based on the selected tab
              onTap: (index) {
                // Handle navigation based on the selected index
              },
              type: BottomNavigationBarType.fixed, // Prevent shifting when changing tabs
            ),
          ),
        ],
      ),
    );
  }
}
