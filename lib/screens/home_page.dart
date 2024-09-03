import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  final double currentUSDBalance = 150.0; // Replace with actual USD balance
  final double currentLBPBalance = 300000.0; // Replace with actual LBP balance
  final double currentUSDSavings = 50.0; // Replace with actual USD savings balance
  final double currentLBPSavings = 100000.0; // Replace with actual LBP savings balance

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
                    style: TextStyle(color: Colors.white), // Set the title text color to white
                  ),
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  actions: [
                    IconButton(
                      icon: Icon(
                        Icons.account_circle,
                        color: Colors.white, // Set the user icon color to white
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
                            'Welcome back, [User\'s Name]!',
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
                              color: Colors.black, // Change text color to black
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
              'USD: \$${usdBalance.toStringAsFixed(2)}',
              style: TextStyle(fontSize: 18),
            ),
            Text(
              'LBP: LBP ${lbpBalance.toStringAsFixed(0)}',
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
        itemCount: 5, // Replace with actual transaction count
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(
              'Transaction ${index + 1}',
              style: TextStyle(color: Colors.black), // Change text color to black
            ),
            subtitle: Text(
              'Details of transaction ${index + 1}',
              style: TextStyle(color: Colors.black), // Change text color to black
            ),
            trailing: Text(
              '-\$[Amount]',
              style: TextStyle(color: Colors.black), // Change text color to black
            ), // Replace with actual amount
          );
        },
      ),
    );
  }
}
