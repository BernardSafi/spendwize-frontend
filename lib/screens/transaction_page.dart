import 'package:flutter/material.dart';
import 'dart:convert'; // For JSON decoding
import 'package:http/http.dart' as http;
import 'income_page.dart';
import 'expense_page.dart';
import 'transfer_page.dart';
import 'exchange_page.dart';
import 'package:spendwize_frontend/constants.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TransactionPage extends StatefulWidget {
  @override
  _TransactionPageState createState() => _TransactionPageState();
}

class _TransactionPageState extends State<TransactionPage> {
  List<Transaction> transactions = []; // List of transactions to display
  List<Transaction> originalTransactions = []; // Store the original list for filtering
  String filterType = 'All'; // Default filter
  String filterCurrency = 'All'; // Default currency filter
  DateTimeRange? selectedDateRange; // Date range for filtering
  final storage = FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    fetchTransactions(); // Fetch transactions when the page is loaded
  }

  Future<void> fetchTransactions() async {
    String? token = await storage.read(key: 'token');
    try {
      final response = await http.get(
        Uri.parse(transactionEndpoint),
        headers: {
          'Authorization': 'Bearer $token', // Attach the Bearer token
          'Content-Type': 'application/json', // Specify content type
        },
      );
      print(response.statusCode);
      if (response.statusCode == 201) { // Check for 200 (OK)
        // Parse the JSON response into a list of Transaction objects
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          transactions = data
              .map((transactionJson) => Transaction.fromJson(transactionJson))
              .toList();
          originalTransactions = List.from(transactions); // Store original transactions
          applyFilters(); // Apply filters once transactions are fetched
        });
      } else {
        // Handle error response
        print('Failed to load transactions');
      }
    } catch (e) {
      print('Error fetching transactions: $e');
    }
  }

  void applyFilters() {
    // Start with the original transactions
    List<Transaction> filteredTransactions = List.from(originalTransactions);

    // Log the initial count of transactions
    print("Original transaction count: ${originalTransactions.length}");

    // Filter by currency, if it's not 'All'
    if (filterCurrency != 'All') {
      filteredTransactions = filteredTransactions
          .where((transaction) => transaction.currency == filterCurrency)
          .toList();
      print("Filtered by currency '${filterCurrency}', count: ${filteredTransactions.length}");
    } else {
      filteredTransactions = filteredTransactions
          .where((transaction) => transaction.currency == "USD"||transaction.currency == "LBP")
          .toList();
      print("Currency filter is 'All', count remains: ${filteredTransactions.length}");
    }

    // Filter by transaction type; if it's 'All', include all types
    if (filterType != 'all') {
      filteredTransactions = filteredTransactions
          .where((transaction) => transaction.type == filterType.toLowerCase())
          .toList();
      print("Filtered by type '${filterType}', count: ${filteredTransactions.length}");
    } else {
      // If filterType is 'All', include all types explicitly
      filteredTransactions = filteredTransactions
          .where((transaction) =>
      transaction.type == "income" ||
          transaction.type == "expense" ||
          transaction.type == "transfer" ||
          transaction.type == "exchange")
          .toList();
      print("Type filter is 'All', all types included, count: ${filteredTransactions.length}");
    }

    // Filter by date range
    if (selectedDateRange != null) {
      filteredTransactions = filteredTransactions
          .where((transaction) =>
      transaction.date.isAfter(selectedDateRange!.start) &&
          transaction.date.isBefore(selectedDateRange!.end))
          .toList();
      print("Filtered by date range, count: ${filteredTransactions.length}");
    }

    // Update the displayed transactions
    setState(() {
      transactions = filteredTransactions; // Use original if empty
      print("Final transaction count for display: ${transactions.length}");
    });
  }







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
    double totalIncomeUSD = transactions
        .where((transaction) => transaction.type == 'income' && transaction.currency == 'USD')
        .fold(0, (sum, transaction) => sum + transaction.amount);

    double totalIncomeLBP = transactions
        .where((transaction) => transaction.type == 'income' && transaction.currency == 'LBP')
        .fold(0, (sum, transaction) => sum + transaction.amount);

    double totalExpensesUSD = transactions
        .where((transaction) => transaction.type == 'expense' && transaction.currency == 'USD')
        .fold(0, (sum, transaction) => sum + transaction.amount);

    double totalExpensesLBP = transactions
        .where((transaction) => transaction.type == 'expense' && transaction.currency == 'LBP')
        .fold(0, (sum, transaction) => sum + transaction.amount);

    return Padding(
      padding: EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Column(
                children: [
                  Text('Total Income (USD)'),
                  Text('\$${totalIncomeUSD.toStringAsFixed(2)}',
                      style: TextStyle(color: Colors.green)),
                ],
              ),
              Column(
                children: [
                  Text('Total Income (LBP)'),
                  Text('${totalIncomeLBP.toStringAsFixed(2)} LBP',
                      style: TextStyle(color: Colors.green)),
                ],
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Column(
                children: [
                  Text('Total Expenses (USD)'),
                  Text('\$${totalExpensesUSD.toStringAsFixed(2)}',
                      style: TextStyle(color: Colors.red)),
                ],
              ),
              Column(
                children: [
                  Text('Total Expenses (LBP)'),
                  Text('${totalExpensesLBP.toStringAsFixed(2)} LBP',
                      style: TextStyle(color: Colors.red)),
                ],
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Column(
                children: [
                  Text('Net Balance (USD)'),
                  Text('\$${(totalIncomeUSD - totalExpensesUSD).toStringAsFixed(2)}'),
                ],
              ),
              Column(
                children: [
                  Text('Net Balance (LBP)'),
                  Text('${(totalIncomeLBP - totalExpensesLBP).toStringAsFixed(2)} LBP'),
                ],
              ),
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
            leading: Icon(
              _getIconForTransaction(transaction.type)['icon'],  // Use icon from the map
              color: _getIconForTransaction(transaction.type)['color'],  // Use color from the map
            ),
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

  Map<String, dynamic> _getIconForTransaction(String type) {
    switch (type) {
      case 'income':
        return {
          'icon': Icons.add_circle,
          'color': Colors.green // Green for income
        };
      case 'expense':
        return {
          'icon': Icons.remove_circle,
          'color': Colors.red // Red for expense
        };
      case 'transfer':
        return {
          'icon': Icons.compare_arrows,
          'color': Colors.blue // Blue for transfer
        };
      case 'exchange':
        return {
          'icon': Icons.sync_alt,
          'color': Colors.orange // Orange for exchange
        };
      default:
        return {
          'icon': Icons.money,
          'color': Colors.grey // Default color
        };
    }
  }


  String _getFormattedDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _openFilterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String selectedType = filterType.toLowerCase(); // Ensure it's lowercase
        DateTimeRange? selectedDateRange = this.selectedDateRange;
        String selectedCurrency = filterCurrency; // Current selected currency

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Filter Transactions'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: selectedType.isEmpty ? null : selectedType, // Use null if empty
                      decoration: InputDecoration(labelText: 'Transaction Type'),
                      items: [
                        'All',
                        'Income',
                        'Expense',
                        'Transfer',
                        'Exchange',
                      ].map((String type) => DropdownMenuItem<String>(
                        value: type.toLowerCase(), // Ensure lowercase
                        child: Text(type),
                      )).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            selectedType = newValue; // Update selectedType properly
                          });
                        }
                      },
                    ),
                    SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: selectedCurrency,
                      decoration: InputDecoration(labelText: 'Currency'),
                      items: [
                        'All',
                        'USD',
                        'LBP',
                      ].map((String currency) => DropdownMenuItem<String>(
                        value: currency, // Use the currency directly
                        child: Text(currency),
                      )).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            selectedCurrency = newValue; // Update selectedCurrency
                          });
                        }
                      },
                    ),
                    SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () async {
                        DateTimeRange? pickedRange = await showDateRangePicker(
                          context: context,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2101),
                          initialDateRange: selectedDateRange,
                        );

                        if (pickedRange != null) {
                          setState(() {
                            selectedDateRange = pickedRange; // Update date range
                          });
                        }
                      },
                      child: Text(
                          selectedDateRange == null
                              ? 'Select Date Range'
                              : 'Selected: ${selectedDateRange!.start.toLocal()} - ${selectedDateRange!.end.toLocal()}'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  child: Text('Cancel'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: Text('Apply'),
                  onPressed: () {
                    setState(() {
                      filterType = selectedType; // Update the filterType
                      filterCurrency = selectedCurrency; // Update the currency filter
                      this.selectedDateRange = selectedDateRange; // Update date range
                      applyFilters(); // Apply the filters
                    });
                    Navigator.of(context).pop(); // Close the dialog
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class Transaction {
  final String type;
  final String description;
  final double amount;
  final String currency;
  final DateTime date;

  Transaction({
    required this.type,
    required this.description,
    required this.amount,
    required this.currency,
    required this.date,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      type: json['type'] ?? 'unknown',
      description: json['description'] ?? 'No description',
      date: DateTime.tryParse(json['date'] ?? '') ?? DateTime.now(),
      amount: (json['amount'] is String)
          ? double.tryParse(json['amount']) ?? 0.0 // Convert string to double
          : (json['amount'] as num?)?.toDouble() ?? 0.0, // Handle num type
      currency: json['currency'] ?? 'USD',
    );
  }
}
