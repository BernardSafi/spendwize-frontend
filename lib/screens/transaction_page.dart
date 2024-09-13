import 'package:flutter/material.dart';
import 'income_page.dart';
import 'expense_page.dart';
import 'transfer_page.dart';
import 'exchange_page.dart';

class TransactionPage extends StatefulWidget {
  @override
  _TransactionPageState createState() => _TransactionPageState();
}

class _TransactionPageState extends State<TransactionPage> {
  List<Transaction> transactions = []; // List of transactions to display
  String filterType = 'All'; // Default filter
  bool showUSD = true; // Filter for currency type

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Transactions'),
        actions: [
          IconButton(
            icon: Icon(Icons.filter_alt),
            onPressed: () {
              _openFilterDialog();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSummaryHeader(), // Monthly summary
          _buildTransactionList(), // Main transaction list
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Logic to navigate to a screen where users can add a new transaction
          showModalBottomSheet(
            context: context,
            builder: (BuildContext context) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  ListTile(
                    leading: Icon(Icons.add_circle, color: Colors.green),
                    title: Text('Add Income'),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => AddIncomePage()),
                      );
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.remove_circle, color: Colors.red),
                    title: Text('Add Expense'),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => AddExpensePage()),
                      );
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.compare_arrows, color: Colors.blue),
                    title: Text('Add Transfer'),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => AddTransferPage()),
                      );
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.sync_alt, color: Colors.orange),
                    title: Text('Add Exchange'),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ExchangePage()),
                      );
                    },
                  ),
                ],
              );
            },
          );
        },
        child: Icon(Icons.add),
      ),
    );
  }

  Widget _buildSummaryHeader() {
    double totalIncome = 1000; // Example: Sum of income transactions
    double totalExpenses = 700; // Example: Sum of expenses

    return Padding(
      padding: EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Column(
            children: [
              Text('Total Income'),
              Text('\$${totalIncome.toStringAsFixed(2)}', style: TextStyle(color: Colors.green)),
            ],
          ),
          Column(
            children: [
              Text('Total Expenses'),
              Text('\$${totalExpenses.toStringAsFixed(2)}', style: TextStyle(color: Colors.red)),
            ],
          ),
          Column(
            children: [
              Text('Net Balance'),
              Text('\$${(totalIncome - totalExpenses).toStringAsFixed(2)}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionList() {
    return Expanded(
      child: ListView.builder(
        itemCount: transactions.length,
        itemBuilder: (context, index) {
          Transaction transaction = transactions[index];
          return ListTile(
            leading: Icon(_getIconForTransaction(transaction.type)),
            title: Text(transaction.description),
            subtitle: Text(_getFormattedDate(transaction.date)),
            trailing: Text(
              '${transaction.amount} ${transaction.currency}',
              style: TextStyle(
                color: transaction.type == 'income' ? Colors.green : Colors.red,
              ),
            ),
            onTap: () {
              // Show transaction details
            },
          );
        },
      ),
    );
  }

  IconData _getIconForTransaction(String type) {
    switch (type) {
      case 'income':
        return Icons.arrow_downward;
      case 'expense':
        return Icons.arrow_upward;
      case 'transfer':
        return Icons.swap_horiz;
      case 'exchange':
        return Icons.sync_alt;
      default:
        return Icons.money;
    }
  }

  String _getFormattedDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _openFilterDialog() {
    // Implement filter dialog with options for date, type, and currency
  }
}

class Transaction {
  final String type;
  final String description;
  final double amount;
  final DateTime date;
  final String currency;

  Transaction({required this.type, required this.description, required this.amount, required this.date, required this.currency});
}
