import 'package:flutter/material.dart';
import 'fetch_student_details_screen.dart';
import '../services/Student_service.dart';
import '../services/AssessmentService.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:app_settings/app_settings.dart';

class StudentDetailsScreen extends StatefulWidget {
  const StudentDetailsScreen({super.key});

  @override
  State<StudentDetailsScreen> createState() => _StudentDetailsScreenState();
}

class _StudentDetailsScreenState extends State<StudentDetailsScreen> {
  final StudentService _studentService = StudentService();
  final AssessmentService _assessmentService = AssessmentService();
  final List<String> _classes =
      List.generate(12, (index) => 'Class ${index + 1}');
  final List<String> _sections = ['A', 'B', 'C', 'D'];

  String? _selectedClass;
  String? _selectedSection;
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _students = [];
  List<Map<String, dynamic>> _filteredStudents = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    try {
      final students = await _studentService.getAllStudents();
      if (mounted) {
        setState(() {
          _students = students;
          _filteredStudents = students;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading students: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _filterStudents(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredStudents = _students;
      } else {
        _filteredStudents = _students.where((student) {
          final name = student['name']?.toString().toLowerCase() ?? '';
          final rollNumber =
              student['rollNumber']?.toString().toLowerCase() ?? '';
          final searchQuery = query.toLowerCase();

          return name.contains(searchQuery) || rollNumber.contains(searchQuery);
        }).toList();
      }
    });
  }

  Future<void> _filterByClassAndSection() async {
    if (_selectedClass == null && _selectedSection == null) {
      setState(() {
        _filteredStudents = _students;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final students = await _assessmentService.getStudentsByClassAndSection(
        _selectedClass!,
        _selectedSection!,
      );

      if (mounted) {
        setState(() {
          _filteredStudents = students;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error filtering students: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _generateAndDownloadPDF() async {
    if (_filteredStudents.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No students selected to download')),
      );
      return;
    }

    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text('Generating PDF...'),
            ],
          ),
        ),
      );

      // Create PDF document
      final pdf = pw.Document();

      // Add content to PDF
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (context) => [
            pw.Header(
              level: 0,
              child: pw.Text(
                'Student Details - ${_selectedClass} ${_selectedSection}',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Table.fromTextArray(
              headers: ['Roll No', 'Name', 'Contact'],
              data: _filteredStudents
                  .map((student) => [
                        student['rollNo']?.toString() ?? 'N/A',
                        student['name']?.toString() ?? 'N/A',
                        student['contact']?.toString() ?? 'N/A',
                      ])
                  .toList(),
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.blue,
              ),
              cellHeight: 30,
              cellAlignments: {
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.centerLeft,
                2: pw.Alignment.centerLeft,
              },
            ),
          ],
        ),
      );

      // Request permissions
      Map<Permission, PermissionStatus> statuses = await [
        Permission.storage,
        Permission.manageExternalStorage,
      ].request();

      // Check if permissions are granted
      bool allGranted = true;
      statuses.forEach((permission, status) {
        if (!status.isGranted) {
          allGranted = false;
        }
      });

      if (!allGranted) {
        // Hide loading dialog
        Navigator.of(context).pop();
        
        // Show permission request dialog
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Storage Permission Required'),
              content: const Text(
                'This app needs storage permission to save PDF files. Please grant the permission in Settings.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    await openAppSettings();
                  },
                  child: const Text('Open Settings'),
                ),
              ],
            ),
          );
        }
        return;
      }

      // Get the directory for saving the file
      final directory = await getExternalStorageDirectory();
      if (directory == null) {
        throw Exception('Could not access storage directory');
      }

      // Create file name with timestamp
      final fileName =
          'students_${_selectedClass}_${_selectedSection}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File('${directory.path}/$fileName');

      // Save the PDF
      await file.writeAsBytes(await pdf.save());

      // Hide loading dialog
      Navigator.of(context).pop();

      // Show success message and share options
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF saved successfully at: ${file.path}'),
            action: SnackBarAction(
              label: 'Share',
              onPressed: () async {
                await Share.shareXFiles(
                  [XFile(file.path)],
                  text: 'Student Details PDF',
                );
              },
            ),
          ),
        );
      }
    } catch (e) {
      // Hide loading dialog if it's showing
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating PDF: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _navigateToFetchScreen() {
    if (_selectedClass == null || _selectedSection == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select both class and section')),
      );
      return;
    }

    _generateAndDownloadPDF();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Details'),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Class and Section Selection
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedClass,
                        decoration: const InputDecoration(
                          labelText: 'Select Class',
                          border: OutlineInputBorder(),
                        ),
                        items: _classes.map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedClass = newValue;
                            _filterByClassAndSection();
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedSection,
                        decoration: const InputDecoration(
                          labelText: 'Section',
                          border: OutlineInputBorder(),
                        ),
                        items: _sections.map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedSection = newValue;
                            _filterByClassAndSection();
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Search Bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: 'Search by Roll No or Name',
                    prefixIcon: const Icon(Icons.search),
                    border: const OutlineInputBorder(),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _filterStudents('');
                            },
                          )
                        : null,
                  ),
                  onChanged: _filterStudents,
                ),
                const SizedBox(height: 16),
                // Fetch Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _navigateToFetchScreen,
                    icon: const Icon(Icons.download),
                    label: const Text('Fetch Student Details'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Student List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredStudents.isEmpty
                    ? const Center(
                        child: Text('No students found'),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 8.0),
                        itemCount: _filteredStudents.length,
                        itemBuilder: (context, index) {
                          final student = _filteredStudents[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12.0),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.blue[100],
                                child: Text(
                                  (student['name'] ?? 'S')
                                      .substring(0, 1)
                                      .toUpperCase(),
                                  style: const TextStyle(
                                      color: Colors.blue,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                              title: Text(
                                student['name'] ?? 'No Name',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                      'Roll No: ${student['rollNumber'] ?? 'N/A'}'),
                                  Text(
                                      'Contact: ${student['contact'] ?? 'N/A'}'),
                                ],
                              ),
                              trailing:
                                  const Icon(Icons.arrow_forward_ios, size: 16),
                              onTap: () {
                                // Navigate to individual student details if needed
                              },
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
