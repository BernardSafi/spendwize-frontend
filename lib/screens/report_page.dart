import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
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
  String selectedCurrency = 'USD'; // Default currency filter
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

  // Prepare line chart data for income and expenses
// Prepare line chart data for income and expenses
  List<FlSpot> getLineChartData(String type, DateTime? startDate, DateTime? endDate) {
    // Get filtered transactions based on the selected type
    List<Transaction> filteredTransactions = getFilteredTransactions(type);

    // Map to hold aggregated amounts for each day within the date range
    Map<DateTime, double> dailyAmounts = {};

    // Return an empty list if dates are null
    if (startDate == null || endDate == null) {
      return [];
    }

    // Iterate through the filtered transactions
    for (var transaction in filteredTransactions) {
      // Check if the transaction date is within the selected date range
      if (transaction.date.isAfter(startDate.subtract(Duration(days: 1))) &&
          transaction.date.isBefore(endDate.add(Duration(days: 1)))) {

        // Normalize the transaction date to midnight to handle aggregation
        DateTime normalizedDate = DateTime(transaction.date.year, transaction.date.month, transaction.date.day);

        // Aggregate amounts by date
        dailyAmounts[normalizedDate] = (dailyAmounts[normalizedDate] ?? 0) + transaction.amount;
      }
    }

    // Generate a list of dates from startDate to endDate
    List<DateTime> dateRange = [];
    for (var d = startDate; d.isBefore(endDate.add(Duration(days: 1))); d = d.add(Duration(days: 1))) {
      dateRange.add(d);
    }

    // Create a list of FlSpot based on the aggregated daily amounts
    return dateRange.map((date) {
      double amount = dailyAmounts[date] ?? 0.0; // Get the amount for the date or 0 if none
      // Use the index of the date in the dateRange as the x-value
      double xValue = dateRange.indexOf(date).toDouble();
      return FlSpot(xValue, amount); // x is the index of the date, y is aggregated amount
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Transaction Report"),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Select Currency and Date Range",
                style:
                TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Currency Selector
                  DropdownButton<String>(
                    value: selectedCurrency,
                    onChanged: (String? newValue) {
                      setState(() {
                        selectedCurrency = newValue!;
                      });
                    },
                    items: <String>['USD', 'LBP']
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),
                  // Date Range Button
                  ElevatedButton(
                    onPressed: () => _selectDateRange(context),
                    child: const Text("Select Date Range"),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Start Date: ${startDate != null ? startDate!.toLocal().toString().split(' ')[0] : 'Not selected'}",
                  ),
                  Text(
                    "End Date: ${endDate != null ? endDate!.toLocal().toString().split(' ')[0] : 'Not selected'}",
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                "Income Pie Chart",
                style:
                TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
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
              const SizedBox(height: 10),
              buildLegend(incomeColors),
              const SizedBox(height: 20),
              const Text(
                "Expenses Pie Chart",
                style:
                TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
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
              const SizedBox(height: 10),
              buildLegend(expenseColors),
              const SizedBox(height: 20),
              const Text(
                "Income and Expenses Line Chart",
                style:
                TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(
                height: 300,
                child: LineChart(
                  LineChartData(
                    borderData: FlBorderData(
                      show: true,
                      border: Border.all(
                          color: const Color(0xff37434d), width: 1),
                    ),
                    lineBarsData: [
                      LineChartBarData(
                        spots: getLineChartData('income',startDate,endDate),
                        isCurved: true,
                        color: Colors.green,
                        barWidth: 3,
                        belowBarData: BarAreaData(show: false),
                      ),
                      LineChartBarData(
                        spots: getLineChartData('expense',startDate,endDate),
                        isCurved: true,
                        color: Colors.red,
                        barWidth: 3,
                        belowBarData: BarAreaData(show: false),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
