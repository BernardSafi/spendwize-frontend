import 'package:flutter/material.dart';
import 'transaction_page.dart';

class TransactionDetailPage extends StatelessWidget {
  final Transaction transaction;

  TransactionDetailPage({required this.transaction});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Transaction Details'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _buildTransactionDetails(),
      ),
    );
  }

  Widget _buildTransactionDetails() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Transaction Type: ${transaction.type.toUpperCase()}',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            _buildCommonDetails(),
            SizedBox(height: 16),
            _buildSpecificDetails(),
          ],
        ),
      ),
    );
  }

  Widget _buildCommonDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Description: ${transaction.description}', style: TextStyle(fontSize: 18)),
        SizedBox(height: 8),
        Text('Amount: ${transaction.amount} ${transaction.currency}', style: TextStyle(fontSize: 18)),
        SizedBox(height: 8),
        Text('Date: ${_getFormattedDate(transaction.date)}', style: TextStyle(fontSize: 18)),
      ],
    );
  }

  Widget _buildSpecificDetails() {
    switch (transaction.type) {
      case 'income':
      case 'expense':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Type: ${transaction.type}', style: TextStyle(fontSize: 18)),
            SizedBox(height: 8),
            Text('Subtype: ${transaction.subtype ?? 'N/A'}', style: TextStyle(fontSize: 18)),
          ],
        );

      case 'transfer':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('From Account: ${transaction.fromAccount ?? 'N/A'}', style: TextStyle(fontSize: 18)),
            SizedBox(height: 8),
            Text('To Account: ${transaction.toAccount ?? 'N/A'}', style: TextStyle(fontSize: 18)),
          ],
        );

      case 'exchange':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Exchanged Amount: ${transaction.amount ?? 0} ${transaction.currency}', style: TextStyle(fontSize: 18)),
            SizedBox(height: 8),
            Text('Exchange Rate: ${transaction.exchangeRate ?? 0}', style: TextStyle(fontSize: 18)),
          ],
        );

      default:
        return Center(child: Text('Unknown transaction type'));
    }
  }

  String _getFormattedDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
