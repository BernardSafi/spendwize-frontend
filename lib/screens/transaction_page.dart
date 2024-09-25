import 'package:flutter/material.dart';
import 'dart:convert'; // For JSON decoding
import 'package:http/http.dart' as http;
import 'income_page.dart';
import 'expense_page.dart';
import 'transfer_page.dart';
import 'exchange_page.dart';
import 'transaction_detail_page.dart';
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

          // Initially load all transactions without filtering
          filterCurrency = 'All'; // Ensure all currencies are shown by default
          filterType = 'all'; // Ensure all transaction types are shown by default
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
      // If 'All' is selected, show both 'USD' and 'LBP' transactions (no filtering)
      print("Currency filter is 'All', no currency filtering applied.");
    }

    // Filter by transaction type, but only if it's not 'All'
    if (filterType != 'all') {
      filteredTransactions = filteredTransactions
          .where((transaction) => transaction.type.toLowerCase() == filterType.toLowerCase())
          .toList();
      print("Filtered by type '${filterType}', count: ${filteredTransactions.length}");
    } else {
      // If 'All' is selected, no filtering by type
      print("Type filter is 'All', no type filtering applied.");
    }

    // Filter by date range, if selected
    if (selectedDateRange != null) {
      filteredTransactions = filteredTransactions
          .where((transaction) =>
      transaction.date.isAfter(selectedDateRange!.start) || transaction.date.isAtSameMomentAs(selectedDateRange!.start) &&
          (transaction.date.isBefore(selectedDateRange!.end.add(Duration(days: 1))) ||
              transaction.date.isAtSameMomentAs(selectedDateRange!.end)))
          .toList();

      print("Filtered by date range, count: ${filteredTransactions.length}");
    }

    // Update the displayed transactions
    setState(() {
      transactions = filteredTransactions; // Display filtered or all if no filtering
      print("Final transaction count for display: ${transactions.length}");
    });
  }


  Future<void> _deleteTransaction(Transaction transaction) async {
    String? token = await storage.read(key: 'token');

    // Show a confirmation dialog before deleting
    bool? confirmDelete = await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Delete Transaction'),
          content: Text('Are you sure you want to delete this transaction?'),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.pop(context, false);
              },
            ),
            TextButton(
              child: Text('Delete'),
              onPressed: () {
                Navigator.pop(context, true);
              },
            ),
          ],
        );
      },
    );

    // Proceed only if the user confirmed the deletion
    if (confirmDelete == true) {
      try {

        final response = await http.delete(
          Uri.parse('$transactionEndpoint/${transaction.id}'), // Append the transaction ID

          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        );
print(response.statusCode);
        if (response.statusCode == 200) {
          setState(() {
            transactions.remove(transaction); // Remove the transaction locally
            originalTransactions.remove(transaction);
          });
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Transaction deleted successfully.'),
          ));
        } else {
          print('Failed to delete transaction');
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Failed to delete transaction.'),
          ));
        }
      } catch (e) {
        print('Error deleting transaction: $e');
      }
    }
  }





  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF003366), Color(0xFF008080), Color(0xFF87CEEB)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            // Set the status bar color to transparent and blend with the app bar
            Container(
              padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
              child: AppBar(
                title: Text(
                  'Transactions',
                  style: TextStyle(color: Colors.white), // Set text color for visibility
                ),
                backgroundColor: Colors.transparent, // Make the app bar background transparent
                elevation: 0, // Remove the shadow effect
                iconTheme: IconThemeData(color: Colors.white),
                actions: [
                  IconButton(
                    icon: Icon(Icons.filter_alt, color: Colors.white), // Change icon color for visibility
                    onPressed: () {
                      _openFilterDialog();
                    },
                  ),
                ],
              ),
            ),
            _buildSummaryHeader(), // Monthly summary
            Expanded(
              child: _buildTransactionList(), // Main transaction list
            ),
          ],
        ),
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

    return Container(
      padding: EdgeInsets.all(16.0),
      margin: EdgeInsets.all(16.0), // Add margin around the box
      decoration: BoxDecoration(
        color: Colors.white, // White background
        borderRadius: BorderRadius.circular(8.0), // Rounded corners
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5), // Shadow effect
            spreadRadius: 2,
            blurRadius: 5,
            offset: Offset(0, 3), // changes position of shadow
          ),
        ],
      ),
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
    return Container(
      padding: EdgeInsets.only(top: 16.0, bottom: 16.0),
      margin: EdgeInsets.all(16.0), // Add margin around the box
      decoration: BoxDecoration(
        color: Colors.white, // White background
        borderRadius: BorderRadius.circular(8.0), // Rounded corners
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5), // Shadow effect
            spreadRadius: 2,
            blurRadius: 5,
            offset: Offset(0, 3), // changes position of shadow
          ),
        ],
      ),
      child: ListView.builder(
        shrinkWrap: true, // This ensures the ListView takes only the space it needs
        itemCount: transactions.length,
        itemBuilder: (context, index) {
          Transaction transaction = transactions[index];
          return ListTile(
            leading: Icon(
              _getIconForTransaction(transaction.type)['icon'],
              color: _getIconForTransaction(transaction.type)['color'],
            ),
            title: Text(transaction.description),
            subtitle: Text(_getFormattedDate(transaction.date)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${transaction.amount} ${transaction.currency}',
                  style: TextStyle(
                    color: transaction.type == 'income' ? Colors.green : Colors.red,
                  ),
                ),

                IconButton(
                  icon: Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    _deleteTransaction(transaction);
                  },
                ),
              ],
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TransactionDetailPage(transaction: transaction),
                ),
              );
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
  final String id; // Add the id field
  final String type;
  final String description;
  final double amount;
  final String currency;
  final DateTime date;
  final String? subtype; // For income and expense
  final String? fromAccount; // For transfers
  final String? toAccount; // For transfers
  final double? exchangeRate; // For exchanges

  Transaction({
    required this.id, // Include id in the constructor
    required this.type,
    required this.description,
    required this.amount,
    required this.currency,
    required this.date,
    this.subtype,
    this.fromAccount,
    this.toAccount,
    this.exchangeRate,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'].toString(),
      type: json['type'] ?? 'unknown',
      description: json['description'] ?? 'No description',
      date: DateTime.parse(json['date']),
      amount: (json['amount'] is String)
          ? double.tryParse(json['amount']) ?? 0.0 // Convert string to double
          : (json['amount'] as num?)?.toDouble() ?? 0.0, // Handle num type
      currency: json['currency'] ,
      subtype: json['subtype'] ?? 'no type',
      fromAccount: json['from_account'] ?? 'no account',
      toAccount: json['to_account'] ?? 'no account',
      exchangeRate: json['exchange_rate'] != null
          ? double.tryParse(json['exchange_rate'].toString()) // Ensure it's not null before parsing
          : null, // Handle null case appropriately
    );
  }
}
