import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:faramas/config/app_colors.dart';

class PaymentDetailsPopup extends StatelessWidget {
  final Map<String, String> payment;

  const PaymentDetailsPopup({Key? key, required this.payment})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Use actual payment data passed in
    final Map<String, String> details = {
      'Order ID': payment['order_id'] ?? 'N/A',
      'Last Payment Date': payment['last_payment_date'] ?? 'N/A',
      'Next Payment Date': payment['next_payment_date'] ?? 'N/A',
      'Create Date': payment['created'] ?? 'N/A',
      'Amount': payment['amount'] ?? 'Tsh 0',
      'Interval': payment['interval'] ?? 'N/A',
      'Is Paid': payment['is_paid'] ?? 'N/A',
      'Is Generated': payment['is_generated'] ?? 'N/A',
      'Payment Gateway URL': payment['payment_gateway_url'] ?? 'N/A',
      'Reference': payment['reference'] ?? 'N/A',
      'Results': payment['result'] ?? 'N/A',
    };

    Widget buildRow(String key, String value, {bool copyable = false}) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              flex: 4,
              child: Text(
                '$key:',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
            Expanded(
              flex: 5,
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                ),
              ),
            ),
            if (copyable)
              IconButton(
                icon: const Icon(Icons.copy, size: 20, color: Colors.grey),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: value));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('$key copied to clipboard')),
                  );
                },
              ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 5,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const Text(
            'Transaction Details',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 12),
          buildRow('Order ID', details['Order ID']!, copyable: true),
          buildRow('Last Payment Date', details['Last Payment Date']!),
          buildRow('Next Payment Date', details['Next Payment Date']!),
          buildRow('Create Date', details['Create Date']!),
          buildRow('Amount', details['Amount']!),
          buildRow('Interval', details['Interval']!),
          buildRow('Is Paid', details['Is Paid']!),
          buildRow('Is Generated', details['Is Generated']!),
          buildRow('Payment Gateway URL', details['Payment Gateway URL']!),
          buildRow('Reference', details['Reference']!, copyable: true),
          buildRow('Results', details['Results']!),
          const SizedBox(height: 16),
          Center(
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Close',
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
