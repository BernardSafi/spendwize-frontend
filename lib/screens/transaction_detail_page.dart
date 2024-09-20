import 'package:flutter/material.dart';
import 'transaction_page.dart';

class TransactionDetailPage extends StatelessWidget {
  final Transaction transaction;

  TransactionDetailPage({required this.transaction});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Gradient background
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF003366), Color(0xFF008080), Color(0xFF87CEEB)], // Same gradient as HomePage
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          Column(
            children: [
              AppBar(
                title: Text('Transaction Details'),
                backgroundColor: Colors.transparent, // Transparent AppBar to show gradient
                elevation: 0,
                iconTheme: IconThemeData(color: Colors.white), // Makes back arrow white
                titleTextStyle: TextStyle(
                  color: Colors.white, // Makes title text white
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: _buildTransactionDetails(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionDetails() {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      color: Colors.white.withOpacity(0.85), // Semi-transparent card to show background
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Transaction Overview',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            Divider(color: Colors.grey.shade300),
            _buildCommonDetails(),
            Divider(color: Colors.grey.shade300),
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
        _buildTextField(
          label: 'Description',
          value: transaction.description,
          icon: Icons.description,
        ),
        SizedBox(height: 12),
        _buildTextField(
          label: 'Amount',
          value: '${transaction.amount} ${transaction.currency}',
          icon: Icons.attach_money,
        ),
        SizedBox(height: 12),
        _buildTextField(
          label: 'Date',
          value: _getFormattedDate(transaction.date),
          icon: Icons.date_range,
        ),
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
            _buildTextField(
              label: 'Type',
              value: transaction.type,
              icon: Icons.category,
            ),
            SizedBox(height: 12),
            _buildTextField(
              label: 'Subtype',
              value: transaction.subtype ?? 'N/A',
              icon: Icons.subdirectory_arrow_right,
            ),
          ],
        );

      case 'transfer':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTextField(
              label: 'From Account',
              value: transaction.fromAccount ?? 'N/A',
              icon: Icons.account_balance_wallet,
            ),
            SizedBox(height: 12),
            _buildTextField(
              label: 'To Account',
              value: transaction.toAccount ?? 'N/A',
              icon: Icons.account_balance_wallet_outlined,
            ),
          ],
        );

      case 'exchange':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTextField(
              label: 'Exchanged Amount',
              value: '${transaction.amount ?? 0} ${transaction.currency}',
              icon: Icons.currency_exchange,
            ),
            SizedBox(height: 12),
            _buildTextField(
              label: 'Exchange Rate',
              value: '${transaction.exchangeRate ?? 0}',
              icon: Icons.swap_vert,
            ),
          ],
        );

      default:
        return Center(child: Text('Unknown transaction type'));
    }
  }

  Widget _buildTextField({required String label, required String value, required IconData icon}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.blueAccent),
            SizedBox(width: 12),
            Text(
              '$label:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        SizedBox(height: 8),
        TextFormField(
          initialValue: value,
          readOnly: true,
          // Apply multiline behavior for 'Description' field only
          maxLines: label == 'Description' ? 5 : 1,  // 5 lines max for large descriptions
          minLines: label == 'Description' ? 3 : 1,  // Minimum 3 lines for better visibility
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white.withOpacity(0.85),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          ),
          style: TextStyle(fontSize: 18),
        ),
      ],
    );
  }

  String _getFormattedDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
