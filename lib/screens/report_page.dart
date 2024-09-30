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

  // Function to generate bar chart data for income and expenses
  List<BarChartGroupData> getBarChartData() {
    final List<Transaction> filteredTransactions = getBarChartTransactions();
    Map<int, double> incomeByMonth = {};
    Map<int, double> expensesByMonth = {};

    for (var transaction in filteredTransactions) {
      int month = transaction.date.month;
      if (transaction.type == 'income') {
        incomeByMonth[month] = (incomeByMonth[month] ?? 0) + transaction.amount;
      } else if (transaction.type == 'expense') {
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
              toY: incomeByMonth[month] ?? 0,
              color: Colors.green,
              width: 20,
            ),
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
      appBar: AppBar(
        title: const Text("Reports"),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Date range selection and currency dropdown in one row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton(
                    onPressed: () => _selectDateRange(context),
                    child: const Text("Select Date Range"),
                  ),
                  Row(
                    children: [
                      const Text("Select Currency:"),
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

              // Start Date and End Date text under the Date Range and Currency dropdown
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Start Date: ${startDate != null ? dateFormat.format(startDate!) : 'Not selected'}'),
                  const SizedBox(width: 20),
                  Text('End Date: ${endDate != null ? dateFormat.format(endDate!) : 'Not selected'}'),
                ],
              ),

              const SizedBox(height: 20),

              // Income Pie Chart
              const Text(
                "Income Distribution",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
              buildLegend(incomeColors),

              // Expense Pie Chart
              const SizedBox(height: 20),
              const Text(
                "Expense Distribution",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
              buildLegend(expenseColors),

              const SizedBox(height: 20),

              // Year selector for bar chart
              Row(
                children: [
                  const Text("Select Year:"),
                  const SizedBox(width: 10),
                  DropdownButton<String>(
                    value: selectedYear,
                    items: List.generate(10, (index) {
                      final year = DateTime.now().year - index;
                      return DropdownMenuItem<String>(
                        value: year.toString(),
                        child: Text(year.toString()),
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
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  "Selected Year: $selectedYear",
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                ),
              ),

              SizedBox(
                height: 300,
                child: BarChart(
                  BarChartData(
                    barGroups: getBarChartData(),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: true),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            switch (value.toInt()) {
                              case 0:
                                return const Text('Jan');
                              case 1:
                                return const Text('Feb');
                              case 2:
                                return const Text('Mar');
                              case 3:
                                return const Text('Apr');
                              case 4:
                                return const Text('May');
                              case 5:
                                return const Text('Jun');
                              case 6:
                                return const Text('Jul');
                              case 7:
                                return const Text('Aug');
                              case 8:
                                return const Text('Sep');
                              case 9:
                                return const Text('Oct');
                              case 10:
                                return const Text('Nov');
                              case 11:
                                return const Text('Dec');
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
            ],
          ),
        ),
      ),
    );
  }






}
