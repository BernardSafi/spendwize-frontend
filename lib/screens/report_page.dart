import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import 'package:spendwize_frontend/constants.dart';

class Transaction {
  final String id;
  final String type;
  final String description;
  final double amount;
  final String currency;
  final DateTime date;
  final String? subtype;
  final String? fromAccount;
  final String? toAccount;
  final double? exchangeRate;

  Transaction({
    required this.id,
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
          ? double.tryParse(json['amount']) ?? 0.0
          : (json['amount'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'],
      subtype: json['subtype'] ?? 'no type',
      fromAccount: json['from_account'] ?? 'no account',
      toAccount: json['to_account'] ?? 'no account',
      exchangeRate: json['exchange_rate'] != null
          ? double.tryParse(json['exchange_rate'].toString())
          : null,
    );
  }
}

class ReportPage extends StatefulWidget {
  const ReportPage({Key? key}) : super(key: key);

  @override
  _ReportPageState createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  final storage = FlutterSecureStorage();
  List<Transaction> transactions = [];
  String selectedCurrency = 'USD'; // Default currency filter for pie charts
  String selectedYear = DateTime.now().year.toString(); // Default year
  bool isLoading = true;
  DateTime? startDate;
  DateTime? endDate;

  // Define colors for different subtypes of income
  final Map<String, Color> incomeColors = {
    'Salary': Colors.green,
    'Bonus': Colors.lightGreen,
    'Investment': Colors.teal,
    'Freelance': Colors.blue,
    'Other': Colors.grey,
  };

  // Define colors for the given subtypes of expenses
  final Map<String, Color> expenseColors = {
    'Groceries': Colors.red,
    'Rent': Colors.orange,
    'Bills': Colors.yellow,
    'Transportation': Colors.green,
    'Healthcare': Colors.teal,
    'Entertainment': Colors.blue,
    'Clothing': Colors.purple,
    'Education': Colors.pink,
    'Travel': Colors.brown,
    'Personal Care': Colors.cyan,
    'Insurance': Colors.indigo,
    'Other': Colors.grey,
  };

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    startDate = DateTime(now.year, now.month, 1); // Beginning of the current month
    endDate = DateTime(now.year, now.month + 1, 0); // End of the current month
    fetchTransactions(); // Fetch transactions when the page loads
  }

  Future<void> fetchTransactions() async {
    String? token = await storage.read(key: 'token');
    try {
      final response = await http.get(
        Uri.parse(transactionEndpoint),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 201) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          transactions = data
              .map((transactionJson) => Transaction.fromJson(transactionJson))
              .toList();
          isLoading = false;
        });
      } else {
        print('Failed to load transactions: ${response.statusCode}');
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching transactions: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  // Filter transactions based on the selected date range
  List<Transaction> getTransactionsByDateRange() {
    return transactions.where((transaction) {
      if (startDate != null && transaction.date.isBefore(startDate!)) {
        return false;
      }
      if (endDate != null && transaction.date.isAfter(endDate!)) {
        return false;
      }
      return true;
    }).toList();
  }

  // Function to get transactions filtered by type and currency
  List<Transaction> getFilteredTransactions(String type) {
    return getTransactionsByDateRange()
        .where((transaction) =>
    transaction.type == type && transaction.currency == selectedCurrency)
        .toList();
  }

  // Prepare pie chart data for income or expenses based on subtype
  List<PieChartSectionData> getPieChartData(
      List<Transaction> filteredTransactions, Map<String, Color> subtypeColors) {
    // Group transactions by subtype and count the number of transactions for each subtype
    Map<String, int> subtypeCounts = {};

    for (var transaction in filteredTransactions) {
      if (transaction.subtype != null) {
        subtypeCounts[transaction.subtype!] =
            (subtypeCounts[transaction.subtype!] ?? 0) + 1;
      }
    }

    int totalTransactions =
    subtypeCounts.values.fold(0, (sum, count) => sum + count);

    return subtypeCounts.entries.map((entry) {
      double percentage = (entry.value / totalTransactions) * 100;

      final color = subtypeColors[entry.key] ?? Colors.grey;

      return PieChartSectionData(
        color: color,
        value: percentage,
        title: '${percentage.toStringAsFixed(1)}%', // Display percentage with 1 decimal
        radius: 50,
        titleStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  // Generate legend for subtypes
  Widget buildLegend(Map<String, Color> subtypeColors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: subtypeColors.entries.map((entry) {
        return Row(
          children: [
            Container(
              width: 16,
              height: 16,
              color: entry.value,
            ),
            const SizedBox(width: 8),
            Text(entry.key), // Show the subtype name
          ],
        );
      }).toList(),
    );
  }

  // Show date picker dialog
  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        startDate = picked.start;
        endDate = picked.end;
      });
    }
  }

  // Function to get transactions for the bar chart based on currency and year
  List<Transaction> getBarChartTransactions() {
    return transactions.where((transaction) {
      return transaction.currency == selectedCurrency &&
          transaction.date.year.toString() == selectedYear;
    }).toList();
  }

  List<BarChartGroupData> getIncomeBarChartData() {
    final List<Transaction> filteredTransactions = getBarChartTransactions();
    Map<int, double> incomeByMonth = {};

    for (var transaction in filteredTransactions) {
      if (transaction.type == 'income') {
        int month = transaction.date.month;
        incomeByMonth[month] = (incomeByMonth[month] ?? 0) + transaction.amount;
      }
    }

    List<BarChartGroupData> barGroups = [];
    for (int month = 1; month <= 12; month++) {
      barGroups.add(
        BarChartGroupData(
          x: month - 1,
          barRods: [
            BarChartRodData(
              toY: incomeByMonth[month] ?? 0,
              color: Colors.green,
              width: 20,
            ),
          ],
        ),
      );
    }
    return barGroups;
  }

// Function to generate bar chart data for expenses
  List<BarChartGroupData> getExpenseBarChartData() {
    final List<Transaction> filteredTransactions = getBarChartTransactions();
    Map<int, double> expensesByMonth = {};

    for (var transaction in filteredTransactions) {
      if (transaction.type == 'expense') {
        int month = transaction.date.month;
        expensesByMonth[month] = (expensesByMonth[month] ?? 0) + transaction.amount;
      }
    }

    List<BarChartGroupData> barGroups = [];
    for (int month = 1; month <= 12; month++) {
      barGroups.add(
        BarChartGroupData(
          x: month - 1,
          barRods: [
            BarChartRodData(
              toY: expensesByMonth[month] ?? 0,
              color: Colors.red,
              width: 20,
            ),
          ],
        ),
      );
    }
    return barGroups;
  }

  @override
  Widget build(BuildContext context) {
    final DateFormat dateFormat = DateFormat('dd-MM-yyyy');
    return Scaffold(
      body: Stack(
        children: [
          // Gradient background
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF003366), Color(0xFF008080), Color(0xFF87CEEB)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          // Main content
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  AppBar(
                    title: const Text(
                      "Reports",
                      style: TextStyle(color: Colors.white), // Change AppBar text color to white
                    ),
                    backgroundColor: Colors.transparent, // Make AppBar transparent
                    elevation: 0, // Remove shadow
                    iconTheme: const IconThemeData(color: Colors.white), // Change back arrow color to white
                  ),
                   isLoading
                    ? Center(
                        child: CircularProgressIndicator(
                        color: Colors.white, // Change loading indicator color to white
                        ),)
                      : Column(
                    children: [
                      // Date range selection and currency dropdown in one row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          ElevatedButton(
                            onPressed: () => _selectDateRange(context),
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.black, // Set the text color to black
                            ),
                            child: const Text("Select Date Range"),
                          ),

                          Row(
                            children: [
                              const Text(
                                "Select Currency:",
                                style: TextStyle(color: Colors.white), // Change text color to white
                              ),
                              const SizedBox(width: 10),
                              DropdownButton<String>(
                                value: selectedCurrency,
                                items: const [
                                  DropdownMenuItem(value: 'USD', child: Text('USD')),
                                  DropdownMenuItem(value: 'LBP', child: Text('LBP')),
                                ],
                                onChanged: (String? newValue) {
                                  setState(() {
                                    selectedCurrency = newValue!;
                                  });
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Start Date and End Date text
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Start Date: ${startDate != null ? dateFormat.format(startDate!) : 'Not selected'}',
                            style: const TextStyle(color: Colors.white), // Change text color to white
                          ),
                          const SizedBox(width: 20),
                          Text(
                            'End Date: ${endDate != null ? dateFormat.format(endDate!) : 'Not selected'}',
                            style: const TextStyle(color: Colors.white), // Change text color to white
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Income Pie Chart with Legend
                      const Text(
                        "Income Distribution",
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white), // Change text color to white
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 5,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            SizedBox(
                              height: 200,
                              child: PieChart(
                                PieChartData(
                                  sections: getPieChartData(
                                    getFilteredTransactions('income'),
                                    incomeColors,
                                  ),
                                ),
                              ),
                            ),
                            buildLegend(incomeColors),
                          ],
                        ),
                      ),

                      // Expense Pie Chart with Legend
                      const SizedBox(height: 20),
                      const Text(
                        "Expense Distribution",
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white), // Change text color to white
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 5,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            SizedBox(
                              height: 200,
                              child: PieChart(
                                PieChartData(
                                  sections: getPieChartData(
                                    getFilteredTransactions('expense'),
                                    expenseColors,
                                  ),
                                ),
                              ),
                            ),
                            buildLegend(expenseColors),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Year selector for bar chart
                      Row(
                        children: [
                          const Text(
                            "Select Year:",
                            style: TextStyle(color: Colors.white), // Change text color to white
                          ),
                          const SizedBox(width: 10),
                          DropdownButton<String>(
                            value: selectedYear,
                            items: List.generate(10, (index) {
                              final year = DateTime.now().year - index;
                              return DropdownMenuItem<String>(
                                value: year.toString(),
                                child: Text(year.toString(), style: const TextStyle(color: Colors.black)), // Change text color to white
                              );
                            }),
                            onChanged: (String? newValue) {
                              setState(() {
                                selectedYear = newValue!;
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Monthly Income and Expenses header
                      const Text(
                        "Monthly Income and Expenses",
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white), // Change text color to white
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          "Selected Year: $selectedYear",
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.white), // Change text color to white
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 5,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(16.0),
                        child: SizedBox(
                          height: 300,
                          child: BarChart(
                            BarChartData(
                              barGroups: getIncomeBarChartData(),
                              titlesData: FlTitlesData(
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (value, meta) {
                                      switch (value.toInt()) {
                                        case 0:
                                          return const Text('Jan', style: TextStyle(color: Colors.black)); // Bar chart label color
                                        case 1:
                                          return const Text('Feb', style: TextStyle(color: Colors.black)); // Bar chart label color
                                        case 2:
                                          return const Text('Mar', style: TextStyle(color: Colors.black)); // Bar chart label color
                                        case 3:
                                          return const Text('Apr', style: TextStyle(color: Colors.black)); // Bar chart label color
                                        case 4:
                                          return const Text('May', style: TextStyle(color: Colors.black)); // Bar chart label color
                                        case 5:
                                          return const Text('Jun', style: TextStyle(color: Colors.black)); // Bar chart label color
                                        case 6:
                                          return const Text('Jul', style: TextStyle(color: Colors.black)); // Bar chart label color
                                        case 7:
                                          return const Text('Aug', style: TextStyle(color: Colors.black)); // Bar chart label color
                                        case 8:
                                          return const Text('Sep', style: TextStyle(color: Colors.black)); // Bar chart label color
                                        case 9:
                                          return const Text('Oct', style: TextStyle(color: Colors.black)); // Bar chart label color
                                        case 10:
                                          return const Text('Nov', style: TextStyle(color: Colors.black)); // Bar chart label color
                                        case 11:
                                          return const Text('Dec', style: TextStyle(color: Colors.black)); // Bar chart label color
                                        default:
                                          return const Text('');
                                      }
                                    },
                                  ),
                                ),
                                topTitles: AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 5,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(16.0),
                        child: SizedBox(
                          height: 300,
                          child: BarChart(
                            BarChartData(
                              barGroups: getExpenseBarChartData(),
                              titlesData: FlTitlesData(
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (value, meta) {
                                      switch (value.toInt()) {
                                        case 0:
                                          return const Text('Jan', style: TextStyle(color: Colors.black)); // Bar chart label color
                                        case 1:
                                          return const Text('Feb', style: TextStyle(color: Colors.black)); // Bar chart label color
                                        case 2:
                                          return const Text('Mar', style: TextStyle(color: Colors.black)); // Bar chart label color
                                        case 3:
                                          return const Text('Apr', style: TextStyle(color: Colors.black)); // Bar chart label color
                                        case 4:
                                          return const Text('May', style: TextStyle(color: Colors.black)); // Bar chart label color
                                        case 5:
                                          return const Text('Jun', style: TextStyle(color: Colors.black)); // Bar chart label color
                                        case 6:
                                          return const Text('Jul', style: TextStyle(color: Colors.black)); // Bar chart label color
                                        case 7:
                                          return const Text('Aug', style: TextStyle(color: Colors.black)); // Bar chart label color
                                        case 8:
                                          return const Text('Sep', style: TextStyle(color: Colors.black)); // Bar chart label color
                                        case 9:
                                          return const Text('Oct', style: TextStyle(color: Colors.black)); // Bar chart label color
                                        case 10:
                                          return const Text('Nov', style: TextStyle(color: Colors.black)); // Bar chart label color
                                        case 11:
                                          return const Text('Dec', style: TextStyle(color: Colors.black)); // Bar chart label color
                                        default:
                                          return const Text('');
                                      }
                                    },
                                  ),
                                ),
                                topTitles: AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }












}
