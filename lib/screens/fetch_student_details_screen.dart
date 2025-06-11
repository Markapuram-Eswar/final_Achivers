import 'package:flutter/material.dart';

class FetchStudentDetailsScreen extends StatefulWidget {
  const FetchStudentDetailsScreen({super.key});

  @override
  State<FetchStudentDetailsScreen> createState() => _FetchStudentDetailsScreenState();
}

class _FetchStudentDetailsScreenState extends State<FetchStudentDetailsScreen> {
  bool _isLoading = false;
  bool _isSuccess = false;
  String _statusMessage = 'Fetching student details...';

  @override
  void initState() {
    super.initState();
    _fetchStudentDetails();
  }

  Future<void> _fetchStudentDetails() async {
    setState(() {
      _isLoading = true;
    });

    // Simulate network request
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _isLoading = false;
      _isLoading = false;
      _isSuccess = true;
      _statusMessage = 'Student details fetched successfully!';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fetch Student Details'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _isLoading
                ? const CircularProgressIndicator()
                : Icon(
                    _isSuccess ? Icons.check_circle : Icons.error,
                    color: _isSuccess ? Colors.green : Colors.red,
                    size: 64,
                  ),
            const SizedBox(height: 24),
            Text(
              _statusMessage,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            if (!_isLoading)
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Back to Student List'),
              ),
          ],
        ),
      ),
    );
  }
}
