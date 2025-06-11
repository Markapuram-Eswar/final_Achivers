import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class FeePaymentsScreen extends StatefulWidget {
  const FeePaymentsScreen({super.key});

  @override
  State<FeePaymentsScreen> createState() => _FeePaymentsScreenState();
}

class _FeePaymentsScreenState extends State<FeePaymentsScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _paymentMethodController =
      TextEditingController();
  final TextEditingController _transactionIdController =
      TextEditingController();
  final TextEditingController _remarksController = TextEditingController();

  String _selectedStudent = 'Select Student';
  String _selectedMonth = DateFormat('MMMM yyyy').format(DateTime.now());
  final List<String> _paymentMethods = [
    'UPI',
    'Credit Card',
    'Debit Card',
    'Net Banking',
    'Cash'
  ];

  // Sample data - in a real app, this would come from an API
  final List<Map<String, dynamic>> _students = [
    {'id': '1', 'name': 'Rahul Sharma', 'class': '10A'},
    {'id': '2', 'name': 'Priya Patel', 'class': '10B'},
    {'id': '3', 'name': 'Amit Kumar', 'class': '9A'},
  ];

  final List<Map<String, dynamic>> _paymentHistory = [
    {
      'id': '1',
      'studentId': '1',
      'amount': 2500.0,
      'month': 'May 2025',
      'status': 'Paid',
      'date': '2025-05-15',
      'paymentMethod': 'UPI',
      'transactionId': 'TXN123456',
    },
    {
      'id': '2',
      'studentId': '1',
      'amount': 2500.0,
      'month': 'April 2025',
      'status': 'Paid',
      'date': '2025-04-10',
      'paymentMethod': 'Net Banking',
      'transactionId': 'TXN789012',
    },
  ];

  bool _showPaymentForm = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _amountController.dispose();
    _paymentMethodController.dispose();
    _transactionIdController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  Future<void> _selectMonth(BuildContext context) async {}

  void _processPayment() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      // Simulate API call
      /* Backend TODO: Process payment via backend (API call, payment gateway integration, database update) */
      Future.delayed(const Duration(seconds: 2), () {
        setState(() {
          _isLoading = false;
          _showPaymentForm = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Payment processed successfully!'),
            backgroundColor: Colors.green[700],
            behavior: SnackBarBehavior.floating,
          ),
        );

        // Reset form
        _formKey.currentState!.reset();
        _selectedStudent = 'Select Student';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fee Payments'),
        backgroundColor: Colors.blue[900],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with total summary
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          const Text(
                            'Total Fees Overview',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildStatCard(
                                  'Total Paid', '₹5,000', Colors.green),
                              _buildStatCard(
                                  'Pending', '₹2,500', Colors.orange),
                              _buildStatCard('Overdue', '₹0', Colors.red),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Payment Form or Toggle Button
                  if (!_showPaymentForm)
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            _showPaymentForm = true;
                          });
                        },
                        icon: const Icon(Icons.add_circle_outline),
                        label: const Text('Record New Payment'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[700],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    )
                  else
                    _buildPaymentForm(),

                  const SizedBox(height: 24),

                  // Payment History
                  const Text(
                    'Payment History',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ..._paymentHistory
                      .map((payment) => _buildPaymentCard(payment)),
                ],
              ),
            ),
    );
  }

  Widget _buildStatCard(String title, String amount, Color color) {
    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          amount,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentForm() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Record New Payment',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      setState(() {
                        _showPaymentForm = false;
                      });
                    },
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 16),

              // Student Dropdown
              DropdownButtonFormField<String>(
                value: _selectedStudent,
                decoration: const InputDecoration(
                  labelText: 'Select Student',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem(
                    value: 'Select Student',
                    child: Text('Select Student'),
                  ),
                  ..._students.map((student) {
                    return DropdownMenuItem(
                      value: student['id'],
                      child: Text('${student['name']} (${student['class']})'),
                    );
                  }),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedStudent = value!;
                  });
                },
                validator: (value) {
                  if (value == null || value == 'Select Student') {
                    return 'Please select a student';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Month Picker
              InkWell(
                onTap: () => _selectMonth(context),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Select Month',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(_selectedMonth),
                ),
              ),

              const SizedBox(height: 16),

              // Amount
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Amount (₹)',
                  border: OutlineInputBorder(),
                  prefixText: '₹ ',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an amount';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Payment Method
              DropdownButtonFormField<String>(
                value: _paymentMethodController.text.isEmpty
                    ? null
                    : _paymentMethodController.text,
                decoration: const InputDecoration(
                  labelText: 'Payment Method',
                  border: OutlineInputBorder(),
                  hintText: 'Select payment method',
                ),
                items: _paymentMethods.map((method) {
                  return DropdownMenuItem(
                    value: method,
                    child: Text(method),
                  );
                }).toList(),
                onChanged: (value) {
                  _paymentMethodController.text = value!;
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a payment method';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Transaction ID
              TextFormField(
                controller: _transactionIdController,
                decoration: const InputDecoration(
                  labelText: 'Transaction ID',
                  border: OutlineInputBorder(),
                  hintText: 'Enter transaction/reference number',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a transaction ID';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Remarks
              TextFormField(
                controller: _remarksController,
                decoration: const InputDecoration(
                  labelText: 'Remarks (Optional)',
                  border: OutlineInputBorder(),
                  hintText: 'Any additional notes',
                ),
                maxLines: 2,
              ),

              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _processPayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Record Payment',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentCard(Map<String, dynamic> payment) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: Colors.grey[300]!,
          width: 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.green[50],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.receipt,
            color: Colors.green[700],
            size: 28,
          ),
        ),
        title: Text(
          '₹${payment['amount']}',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              '${payment['month']} • ${payment['paymentMethod']}',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 4),
            Text(
              'TXN: ${payment['transactionId']}',
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: payment['status'] == 'Paid'
                ? Colors.green[50]
                : Colors.orange[50],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            payment['status'],
            style: TextStyle(
              color: payment['status'] == 'Paid'
                  ? Colors.green[700]
                  : Colors.orange[700],
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ),
        onTap: () {
          // Show payment details dialog
          _showPaymentDetails(payment);
        },
      ),
    );
  }

  void _showPaymentDetails(Map<String, dynamic> payment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Payment Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Student', 'Rahul Sharma (10A)'),
              const SizedBox(height: 8),
              _buildDetailRow('Amount', '₹${payment['amount']}'),
              const SizedBox(height: 8),
              _buildDetailRow('Month', payment['month']),
              const SizedBox(height: 8),
              _buildDetailRow('Payment Method', payment['paymentMethod']),
              const SizedBox(height: 8),
              _buildDetailRow('Transaction ID', payment['transactionId']),
              const SizedBox(height: 8),
              _buildDetailRow('Date', payment['date']),
              const SizedBox(height: 8),
              _buildDetailRow('Status', payment['status'], isStatus: true),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isStatus = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          const Text(':  '),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: isStatus ? FontWeight.bold : FontWeight.normal,
                color: isStatus
                    ? value == 'Paid'
                        ? Colors.green
                        : Colors.orange
                    : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
