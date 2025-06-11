import 'package:flutter/material.dart';

class DuePaymentsScreen extends StatefulWidget {
  const DuePaymentsScreen({super.key});

  @override
  State<DuePaymentsScreen> createState() => _DuePaymentsScreenState();
}

class _DuePaymentsScreenState extends State<DuePaymentsScreen> {
  String _selectedPaymentMethod = '';
  bool _isProcessing = false;
  final double _amountDue = 12500.0; // Example amount in INR

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Icon(
            Icons.check_circle,
            color: Colors.green,
            size: 80,
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Payment Successful!',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 10),
              Text(
                'Your payment has been processed successfully.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
          actions: [
            Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text(
                  'Done',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPaymentMethodCard(String title, String icon, bool isSelected) {
    return Card(
      elevation: isSelected ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected
            ? const BorderSide(color: Colors.blue, width: 2)
            : BorderSide.none,
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Image.network(
            icon,
            width: 32,
            height: 32,
            errorBuilder: (context, error, stackTrace) => Icon(
              Icons.payment,
              size: 28,
              color: Colors.grey[600],
            ),
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        trailing: isSelected
            ? const Icon(Icons.check_circle, color: Colors.blue)
            : null,
        onTap: () {
          setState(() {
            _selectedPaymentMethod = title;
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Make Payment'),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Amount Due Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Text(
                      'Amount Due',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '₹${_amountDue.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Due Date: 05 June 2025',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
            // Payment Methods
            const Text(
              'Select Payment Method',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            // Popular Payment Methods
            const Row(
              children: [
                Text(
                  'Popular',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey,
                  ),
                ),
                Expanded(
                  child: Divider(
                    indent: 15,
                    endIndent: 10,
                    thickness: 1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            _buildPaymentMethodCard(
              'UPI',
              'https://cdn-icons-png.flaticon.com/512/825/825454.png', // UPI icon
              _selectedPaymentMethod == 'UPI',
            ),
            const SizedBox(height: 12),
            _buildPaymentMethodCard(
              'Credit/Debit Card',
              'https://cdn-icons-png.flaticon.com/512/196/196578.png', // Card icon
              _selectedPaymentMethod == 'Credit/Debit Card',
            ),
            const SizedBox(height: 12),
            _buildPaymentMethodCard(
              'Net Banking',
              'https://cdn-icons-png.flaticon.com/512/888/888457.png', // Bank icon
              _selectedPaymentMethod == 'Net Banking',
            ),
            const SizedBox(height: 12),
            _buildPaymentMethodCard(
              'Wallets',
              'https://cdn-icons-png.flaticon.com/512/888/888454.png', // Wallet icon
              _selectedPaymentMethod == 'Wallets',
            ),
            const SizedBox(height: 30),
            // Pay Now Button
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _selectedPaymentMethod.isEmpty || _isProcessing
                    ? null
                    : () async {
                        setState(() => _isProcessing = true);
                        // Simulate payment processing
                        /* Backend TODO: Process payment via backend (API call, payment gateway integration, database update) */
                        await Future.delayed(const Duration(seconds: 2));
                        setState(() => _isProcessing = false);
                        _showSuccessDialog();
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 3,
                ),
                child: _isProcessing
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'PAY NOW',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 20),
            // Note
            const Text(
              'Note: This is a demo payment screen. No real transaction will be processed.',
              style: TextStyle(color: Colors.grey, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
