import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'quiz_report_page.dart';
import 'widgets/progress_widgets.dart';
import 'data_service.dart';
import 'data_models.dart';
import 'progress_page.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:open_filex/open_filex.dart';
import '../services/ProfileService.dart';
import 'package:lottie/lottie.dart';
import 'package:pdf/pdf.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:achiver_app/services/AssessmentService.dart';
import '../services/practice_zone_service.dart';

void main() {
  runApp(MaterialApp(
    home: ReportsZonePage(),
  ));
}

class ReportsZonePage extends StatefulWidget {
  const ReportsZonePage({super.key});

  @override
  State<ReportsZonePage> createState() => _ReportsZonePageState();
}

class _ReportsZonePageState extends State<ReportsZonePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic>? studentData;
  String? studentId;
  bool isLoading = true;
  String? errorMessage;

  // Add this for the FutureBuilder
  late Future<UserData> userDataFuture;

  // Dynamic data
  List<Map<String, dynamic>> _practiceProgress = [];
  List<Map<String, dynamic>> _quizResults = [];
  List<Map<String, dynamic>> _assessments = [];

  // Filters
  String? _selectedClass;
  String? _selectedTest;
  String? _selectedZoneType;
  DateTimeRange? _selectedDateRange;
  String? _selectedSubject;

  final List<String> _classes = [
    '1',
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
    '9',
    '10'
  ];
  final List<String> _tests = [
    'All Tests',
    'FA1',
    'FA2',
    'SA1',
    'FA3',
    'FA4',
    'SA2',
    'Mid-Term'
  ];
  final List<String> _zoneTypes = [
    'All Zones',
    'Test Zone',
    'Practice Zone',
  ];
  final List<String> _dateRanges = [
    'All Time',
    'Last 7 Days',
    'Last 30 Days',
    'Last 90 Days',
    'This Month',
    'Last Month'
  ];
  final List<String> _subjects = [
    'All Subjects',
    'Mathematics',
    'Science',
    'English',
    'Social Studies',
    'Hindi',
    'Telugu',
    'Physics',
    'Chemistry',
    'Biology',
    'Computer Science'
  ];

  // Sample data for each subject
  final Map<String, Map<String, dynamic>> _subjectData = {
    'Mathematics': {
      'timeSpent': '5h 30m',
      'completion': '78%',
      'avgScore': '85%',
      'testsTaken': '12'
    },
    'Science': {
      'timeSpent': '4h 45m',
      'completion': '65%',
      'avgScore': '82%',
      'testsTaken': '10'
    },
    'English': {
      'timeSpent': '3h 20m',
      'completion': '90%',
      'avgScore': '88%',
      'testsTaken': '8'
    },
    'Social Studies': {
      'timeSpent': '2h 50m',
      'completion': '55%',
      'avgScore': '75%',
      'testsTaken': '6'
    },
    'Hindi': {
      'timeSpent': '2h 15m',
      'completion': '70%',
      'avgScore': '80%',
      'testsTaken': '5'
    },
    'Telugu': {
      'timeSpent': '1h 50m',
      'completion': '60%',
      'avgScore': '78%',
      'testsTaken': '4'
    },
    'Physics': {
      'timeSpent': '6h 10m',
      'completion': '72%',
      'avgScore': '83%',
      'testsTaken': '14'
    },
    'Chemistry': {
      'timeSpent': '5h 55m',
      'completion': '68%',
      'avgScore': '80%',
      'testsTaken': '13'
    },
    'Biology': {
      'timeSpent': '4h 30m',
      'completion': '75%',
      'avgScore': '85%',
      'testsTaken': '11'
    },
    'Computer Science': {
      'timeSpent': '7h 20m',
      'completion': '85%',
      'avgScore': '92%',
      'testsTaken': '15'
    },
  };

  // Add these for the date picker
  DateTime get _minDate => DateTime(2020, 1, 1);
  DateTime get _maxDate => DateTime.now();

  final FirebaseService _practiceZoneService = FirebaseService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _selectedClass = _classes.first;
    _selectedTest = _tests.first;
    _selectedSubject = _subjects.first;
    _selectedZoneType = _zoneTypes.first;
    _selectedDateRange = null;
    fetchProfile();
    userDataFuture = DataService().fetchUserData();
  }

  Future<void> fetchProfile() async {
    try {
      final data = await ProfileService().getStudentProfile();
      final progressData =
          await _practiceZoneService.getProgressDetails(data['rollNumber']);
      final quizResultsData =
          await _practiceZoneService.getQuizResultsDetails(data['rollNumber']);
      print("practiceZoneData: $progressData");
      print("quizResultsData: $quizResultsData");
      print("data: \\${data['assessments']}");

      setState(() {
        studentData = data;
        _practiceProgress = progressData;
        _quizResults = quizResultsData;
        print("practiceProgress: $_practiceProgress");
        print("quizResults: $_quizResults");
        isLoading = false;
      });
      // Fetch practice zone data if Practice Zone is selected
    } catch (e) {
      Fluttertoast.showToast(msg: 'Failed to load profile: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _fetchPracticeZoneData() async {
    if (studentData == null) return;
    final studentId =
        studentData?['id'] ?? FirebaseAuth.instance.currentUser?.uid;
    if (studentId == null) return;
    final progress = await _practiceZoneService.getProgressDetails(studentId);
    print("progress: $progress");
    final quizResults =
        await _practiceZoneService.getQuizResultsDetails(studentId);
    print("quizResults: $quizResults");
    setState(() {
      _practiceProgress = progress;
      _quizResults = quizResults;
    });
  }

  List<Map<String, dynamic>> get _filteredPracticeZoneData {
    final subject = _selectedSubject;
    print("subject: $subject");
    List<Map<String, dynamic>> filtered = [];
    if (subject != null && subject != 'All Subjects') {
      filtered.addAll(_practiceProgress.where((e) {
        final s = (e['subjectName']?.toString().trim().toLowerCase() ?? '');
        print("progress subjectName: " + s);
        return s == (subject.trim().toLowerCase());
      }));
      filtered.addAll(_quizResults.where((e) {
        final s = (e['subjectName']?.toString().trim().toLowerCase() ?? '');
        print("quiz subjectName: " + s);
        return s == (subject.trim().toLowerCase());
      }));
    } else {
      filtered.addAll(_practiceProgress);
      filtered.addAll(_quizResults);
    }
    return filtered;
  }

  Future<void> _loadStudentData() async {
    setState(() {
      isLoading = true;
    });
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          errorMessage = 'User not logged in.';
          isLoading = false;
        });
        return;
      }
      studentId = user.uid;
      final doc = await FirebaseFirestore.instance
          .collection('students')
          .doc(studentId)
          .get();
      if (!doc.exists) {
        setState(() {
          errorMessage = 'Student data not found.';
          isLoading = false;
        });
        return;
      }
      studentData = doc.data();
      final assessmentService = AssessmentService();
      _assessments = await assessmentService.getStudentAssessments(studentId!);
      print("assessments: $_assessments");
      setState(() {
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to load data: $e';
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _downloadAppReportPdf() async {
    if (!mounted) return;
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    scaffoldMessenger.showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            SizedBox(width: 12),
            Text('Generating app report...'),
          ],
        ),
        duration: Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
      ),
    );
    try {
      final pdf = pw.Document();
      final now = DateTime.now();
      final formattedDate = '${now.day}/${now.month}/${now.year}';

      if (_selectedZoneType == 'All Zones') {
        // Prepare test data
        final tests = _filteredSubjectTests;
        // Prepare practice/quiz data
        final practiceData = _selectedSubject != null &&
                _selectedSubject != 'All Subjects'
            ? _practiceProgress
                .where((e) =>
                    (e['subjectName']?.toString().trim().toLowerCase() ?? '') ==
                    _selectedSubject!.trim().toLowerCase())
                .toList()
            : _practiceProgress;
        final quizData = _selectedSubject != null &&
                _selectedSubject != 'All Subjects'
            ? _quizResults
                .where((e) =>
                    (e['subjectName']?.toString().trim().toLowerCase() ?? '') ==
                    _selectedSubject!.trim().toLowerCase())
                .toList()
            : _quizResults;

        if (tests.isEmpty && practiceData.isEmpty && quizData.isEmpty) {
          if (mounted) {
            scaffoldMessenger.hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content:
                    Text('No data available for the selected subject/zones.'),
                backgroundColor: Colors.orange,
              ),
            );
          }
          return;
        }

        pdf.addPage(
          pw.MultiPage(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(32),
            build: (pw.Context context) {
              List<pw.Widget> widgets = [
                pw.Header(
                  level: 0,
                  child: pw.Text(
                    'Comprehensive Report - \\${_selectedSubject ?? ''}',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue900,
                    ),
                  ),
                ),
                pw.SizedBox(height: 16),
                pw.Text('Generated on: $formattedDate'),
                pw.SizedBox(height: 16),
              ];

              // Test Table
              widgets.add(
                pw.Text('Test Zone',
                    style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue900)),
              );
              if (tests.isEmpty) {
                widgets.add(pw.Text('No test data available.'));
              } else {
                widgets.add(
                  pw.Table.fromTextArray(
                    headers: _selectedSubject == 'All Subjects'
                        ? [
                            'Subject',
                            'Test Name',
                            'Date',
                            'Status',
                            'Max Marks',
                            'Duration',
                            'Time'
                          ]
                        : [
                            'Test Name',
                            'Date',
                            'Status',
                            'Max Marks',
                            'Duration',
                            'Time'
                          ],
                    data: tests.map((test) {
                      final row = [
                        test['testName']?.toString() ?? '',
                        test['date']?.toString() ?? '',
                        test['status']?.toString() ?? '',
                        test['maxMarks']?.toString() ?? '',
                        test['duration']?.toString() ?? '',
                        test['time']?.toString() ?? '',
                      ];
                      if (_selectedSubject == 'All Subjects') {
                        row.insert(0, test['Subject'] ?? '');
                      }
                      return row;
                    }).toList(),
                    cellStyle: const pw.TextStyle(fontSize: 12),
                    cellAlignments: _selectedSubject == 'All Subjects'
                        ? {
                            0: pw.Alignment.centerLeft,
                            1: pw.Alignment.centerLeft,
                            2: pw.Alignment.center,
                            3: pw.Alignment.center,
                            4: pw.Alignment.center,
                            5: pw.Alignment.center,
                            6: pw.Alignment.center,
                          }
                        : {
                            0: pw.Alignment.centerLeft,
                            1: pw.Alignment.center,
                            2: pw.Alignment.center,
                            3: pw.Alignment.center,
                            4: pw.Alignment.center,
                            5: pw.Alignment.center,
                          },
                    border: pw.TableBorder.all(
                      color: PdfColors.grey300,
                      width: 1,
                    ),
                    headerStyle: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                    ),
                    headerDecoration: pw.BoxDecoration(
                      color: PdfColors.blue900,
                    ),
                    headerPadding: const pw.EdgeInsets.all(8),
                    cellPadding: const pw.EdgeInsets.all(8),
                    rowDecoration: pw.BoxDecoration(
                      border: pw.Border(
                        bottom: pw.BorderSide(
                          color: PdfColors.grey200,
                          width: 1,
                        ),
                      ),
                    ),
                  ),
                );
              }

              widgets.add(pw.SizedBox(height: 24));

              // Practice Table
              widgets.add(
                pw.Text('Practice Activities',
                    style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue900)),
              );
              if (practiceData.isEmpty) {
                widgets.add(pw.Text('No practice data available.'));
              } else {
                widgets.add(
                  pw.Table.fromTextArray(
                    headers: _selectedSubject == 'All Subjects'
                        ? [
                            'Subject',
                            'Topic',
                            'Score',
                            'Percentage',
                            'Time Spent',
                            'Completed At'
                          ]
                        : [
                            'Topic',
                            'Score',
                            'Percentage',
                            'Time Spent',
                            'Completed At'
                          ],
                    data: practiceData.map((item) {
                      final row = [
                        item['topicName'] ?? item['topic'] ?? '',
                        item['score']?.toString() ?? '',
                        item['percentage']?.toString() ?? '',
                        item['timeSpent']?.toString() ?? '',
                        (item['completedAt'] is Timestamp)
                            ? (item['completedAt'] as Timestamp)
                                .toDate()
                                .toString()
                            : (item['completedAt']?.toString() ?? ''),
                      ];
                      if (_selectedSubject == 'All Subjects') {
                        row.insert(0, item['subjectName'] ?? '');
                      }
                      return row;
                    }).toList(),
                    cellStyle: const pw.TextStyle(fontSize: 12),
                    cellAlignments: _selectedSubject == 'All Subjects'
                        ? {
                            0: pw.Alignment.centerLeft,
                            1: pw.Alignment.centerLeft,
                            2: pw.Alignment.center,
                            3: pw.Alignment.center,
                            4: pw.Alignment.center,
                            5: pw.Alignment.center,
                          }
                        : {
                            0: pw.Alignment.centerLeft,
                            1: pw.Alignment.center,
                            2: pw.Alignment.center,
                            3: pw.Alignment.center,
                            4: pw.Alignment.center,
                          },
                    border: pw.TableBorder.all(
                      color: PdfColors.grey300,
                      width: 1,
                    ),
                    headerStyle: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                    ),
                    headerDecoration: pw.BoxDecoration(
                      color: PdfColors.blue900,
                    ),
                    headerPadding: const pw.EdgeInsets.all(8),
                    cellPadding: const pw.EdgeInsets.all(8),
                    rowDecoration: pw.BoxDecoration(
                      border: pw.Border(
                        bottom: pw.BorderSide(
                          color: PdfColors.grey200,
                          width: 1,
                        ),
                      ),
                    ),
                  ),
                );
              }

              widgets.add(pw.SizedBox(height: 24));

              // Quiz Table
              widgets.add(
                pw.Text('Quiz Activities',
                    style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue900)),
              );
              if (quizData.isEmpty) {
                widgets.add(pw.Text('No quiz data available.'));
              } else {
                widgets.add(
                  pw.Table.fromTextArray(
                    headers: _selectedSubject == 'All Subjects'
                        ? [
                            'Subject',
                            'Topic',
                            'Score',
                            'Percentage',
                            'Time Spent',
                            'Completed At'
                          ]
                        : [
                            'Topic',
                            'Score',
                            'Percentage',
                            'Time Spent',
                            'Completed At'
                          ],
                    data: quizData.map((item) {
                      final row = [
                        item['topicName'] ?? item['topic'] ?? '',
                        item['score']?.toString() ?? '',
                        item['percentage']?.toString() ?? '',
                        item['timeSpent']?.toString() ?? '',
                        (item['completedAt'] is Timestamp)
                            ? (item['completedAt'] as Timestamp)
                                .toDate()
                                .toString()
                            : (item['completedAt']?.toString() ?? ''),
                      ];
                      if (_selectedSubject == 'All Subjects') {
                        row.insert(0, item['subjectName'] ?? '');
                      }
                      return row;
                    }).toList(),
                    cellStyle: const pw.TextStyle(fontSize: 12),
                    cellAlignments: _selectedSubject == 'All Subjects'
                        ? {
                            0: pw.Alignment.centerLeft,
                            1: pw.Alignment.centerLeft,
                            2: pw.Alignment.center,
                            3: pw.Alignment.center,
                            4: pw.Alignment.center,
                            5: pw.Alignment.center,
                          }
                        : {
                            0: pw.Alignment.centerLeft,
                            1: pw.Alignment.center,
                            2: pw.Alignment.center,
                            3: pw.Alignment.center,
                            4: pw.Alignment.center,
                          },
                    border: pw.TableBorder.all(
                      color: PdfColors.grey300,
                      width: 1,
                    ),
                    headerStyle: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                    ),
                    headerDecoration: pw.BoxDecoration(
                      color: PdfColors.blue900,
                    ),
                    headerPadding: const pw.EdgeInsets.all(8),
                    cellPadding: const pw.EdgeInsets.all(8),
                    rowDecoration: pw.BoxDecoration(
                      border: pw.Border(
                        bottom: pw.BorderSide(
                          color: PdfColors.grey200,
                          width: 1,
                        ),
                      ),
                    ),
                  ),
                );
              }

              widgets.add(pw.SizedBox(height: 24));
              widgets.add(pw.Divider());
              widgets.add(
                pw.Center(
                  child: pw.Text(
                    'Generated by School App - $formattedDate',
                    style: pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.grey600,
                    ),
                  ),
                ),
              );
              return widgets;
            },
          ),
        );

        final output = await getTemporaryDirectory();
        final file = File(
            '${output.path}/all_zones_report_${_selectedSubject ?? 'subject'}_${DateTime.now().millisecondsSinceEpoch}.pdf');
        await file.writeAsBytes(await pdf.save());
        if (mounted) {
          scaffoldMessenger.hideCurrentSnackBar();
          await OpenFilex.open(file.path);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Report downloaded successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
        return;
      } else if (_selectedZoneType == 'Practice Zone') {
        // Practice Zone logic (practiceData and quizData only)
        final practiceData = _selectedSubject != null &&
                _selectedSubject != 'All Subjects'
            ? _practiceProgress
                .where((e) =>
                    (e['subjectName']?.toString().trim().toLowerCase() ?? '') ==
                    _selectedSubject!.trim().toLowerCase())
                .toList()
            : _practiceProgress;

        final quizData = _selectedSubject != null &&
                _selectedSubject != 'All Subjects'
            ? _quizResults
                .where((e) =>
                    (e['subjectName']?.toString().trim().toLowerCase() ?? '') ==
                    _selectedSubject!.trim().toLowerCase())
                .toList()
            : _quizResults;

        if (practiceData.isEmpty && quizData.isEmpty) {
          if (mounted) {
            scaffoldMessenger.hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    'No practice or quiz data available for the selected subject.'),
                backgroundColor: Colors.orange,
              ),
            );
          }
          return;
        }

        pdf.addPage(
          pw.MultiPage(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(32),
            build: (pw.Context context) {
              List<pw.Widget> widgets = [
                pw.Header(
                  level: 0,
                  child: pw.Text(
                    'Practice Zone Report - \\${_selectedSubject ?? ''}',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue900,
                    ),
                  ),
                ),
                pw.SizedBox(height: 16),
                pw.Text('Generated on: $formattedDate'),
                pw.SizedBox(height: 16),
              ];

              // Practice Table
              widgets.add(
                pw.Text('Practice Activities',
                    style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue900)),
              );
              if (practiceData.isEmpty) {
                widgets.add(pw.Text('No practice data available.'));
              } else {
                widgets.add(
                  pw.Table.fromTextArray(
                    headers: _selectedSubject == 'All Subjects'
                        ? [
                            'Subject',
                            'Topic',
                            'Score',
                            'Percentage',
                            'Time Spent',
                            'Completed At'
                          ]
                        : [
                            'Topic',
                            'Score',
                            'Percentage',
                            'Time Spent',
                            'Completed At'
                          ],
                    data: practiceData.map((item) {
                      final row = [
                        item['topicName'] ?? item['topic'] ?? '',
                        item['score']?.toString() ?? '',
                        item['percentage']?.toString() ?? '',
                        item['timeSpent']?.toString() ?? '',
                        (item['completedAt'] is Timestamp)
                            ? (item['completedAt'] as Timestamp)
                                .toDate()
                                .toString()
                            : (item['completedAt']?.toString() ?? ''),
                      ];
                      if (_selectedSubject == 'All Subjects') {
                        row.insert(0, item['subjectName'] ?? '');
                      }
                      return row;
                    }).toList(),
                    cellStyle: const pw.TextStyle(fontSize: 12),
                    cellAlignments: _selectedSubject == 'All Subjects'
                        ? {
                            0: pw.Alignment.centerLeft,
                            1: pw.Alignment.centerLeft,
                            2: pw.Alignment.center,
                            3: pw.Alignment.center,
                            4: pw.Alignment.center,
                            5: pw.Alignment.center,
                          }
                        : {
                            0: pw.Alignment.centerLeft,
                            1: pw.Alignment.center,
                            2: pw.Alignment.center,
                            3: pw.Alignment.center,
                            4: pw.Alignment.center,
                          },
                    border: pw.TableBorder.all(
                      color: PdfColors.grey300,
                      width: 1,
                    ),
                    headerStyle: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                    ),
                    headerDecoration: pw.BoxDecoration(
                      color: PdfColors.blue900,
                    ),
                    headerPadding: const pw.EdgeInsets.all(8),
                    cellPadding: const pw.EdgeInsets.all(8),
                    rowDecoration: pw.BoxDecoration(
                      border: pw.Border(
                        bottom: pw.BorderSide(
                          color: PdfColors.grey200,
                          width: 1,
                        ),
                      ),
                    ),
                  ),
                );
              }

              widgets.add(pw.SizedBox(height: 24));

              // Quiz Table
              widgets.add(
                pw.Text('Quiz Activities',
                    style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue900)),
              );
              if (quizData.isEmpty) {
                widgets.add(pw.Text('No quiz data available.'));
              } else {
                widgets.add(
                  pw.Table.fromTextArray(
                    headers: _selectedSubject == 'All Subjects'
                        ? [
                            'Subject',
                            'Topic',
                            'Score',
                            'Percentage',
                            'Time Spent',
                            'Completed At'
                          ]
                        : [
                            'Topic',
                            'Score',
                            'Percentage',
                            'Time Spent',
                            'Completed At'
                          ],
                    data: quizData.map((item) {
                      final row = [
                        item['topicName'] ?? item['topic'] ?? '',
                        item['score']?.toString() ?? '',
                        item['percentage']?.toString() ?? '',
                        item['timeSpent']?.toString() ?? '',
                        (item['completedAt'] is Timestamp)
                            ? (item['completedAt'] as Timestamp)
                                .toDate()
                                .toString()
                            : (item['completedAt']?.toString() ?? ''),
                      ];
                      if (_selectedSubject == 'All Subjects') {
                        row.insert(0, item['subjectName'] ?? '');
                      }
                      return row;
                    }).toList(),
                    cellStyle: const pw.TextStyle(fontSize: 12),
                    cellAlignments: _selectedSubject == 'All Subjects'
                        ? {
                            0: pw.Alignment.centerLeft,
                            1: pw.Alignment.centerLeft,
                            2: pw.Alignment.center,
                            3: pw.Alignment.center,
                            4: pw.Alignment.center,
                            5: pw.Alignment.center,
                          }
                        : {
                            0: pw.Alignment.centerLeft,
                            1: pw.Alignment.center,
                            2: pw.Alignment.center,
                            3: pw.Alignment.center,
                            4: pw.Alignment.center,
                          },
                    border: pw.TableBorder.all(
                      color: PdfColors.grey300,
                      width: 1,
                    ),
                    headerStyle: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                    ),
                    headerDecoration: pw.BoxDecoration(
                      color: PdfColors.blue900,
                    ),
                    headerPadding: const pw.EdgeInsets.all(8),
                    cellPadding: const pw.EdgeInsets.all(8),
                    rowDecoration: pw.BoxDecoration(
                      border: pw.Border(
                        bottom: pw.BorderSide(
                          color: PdfColors.grey200,
                          width: 1,
                        ),
                      ),
                    ),
                  ),
                );
              }

              widgets.add(pw.SizedBox(height: 24));
              widgets.add(pw.Divider());
              widgets.add(
                pw.Center(
                  child: pw.Text(
                    'Generated by School App - $formattedDate',
                    style: pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.grey600,
                    ),
                  ),
                ),
              );
              return widgets;
            },
          ),
        );

        final output = await getTemporaryDirectory();
        final file = File(
            '${output.path}/practice_zone_report_${_selectedSubject ?? 'subject'}_${DateTime.now().millisecondsSinceEpoch}.pdf');
        await file.writeAsBytes(await pdf.save());
        if (mounted) {
          scaffoldMessenger.hideCurrentSnackBar();
          await OpenFilex.open(file.path);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Report downloaded successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
        return;
      } else if (_selectedZoneType == 'Test Zone') {
        // Test Zone logic (test data only)
        final tests = _filteredSubjectTests;
        if (tests.isEmpty) {
          if (mounted) {
            scaffoldMessenger.hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content:
                    Text('No test data available for the selected subject.'),
                backgroundColor: Colors.orange,
              ),
            );
          }
          return;
        }

        pdf.addPage(
          pw.MultiPage(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(32),
            build: (pw.Context context) {
              return [
                pw.Header(
                  level: 0,
                  child: pw.Text(
                    'Test Zone Report - ${_selectedSubject ?? ''}',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue900,
                    ),
                  ),
                ),
                pw.SizedBox(height: 16),
                pw.Text('Generated on: $formattedDate'),
                pw.SizedBox(height: 16),
                pw.Table.fromTextArray(
                  headers: _selectedSubject == 'All Subjects'
                      ? [
                          'Subject',
                          'Test Name',
                          'Date',
                          'Status',
                          'Max Marks',
                          'Duration',
                          'Time'
                        ]
                      : [
                          'Test Name',
                          'Date',
                          'Status',
                          'Max Marks',
                          'Duration',
                          'Time'
                        ],
                  data: tests.map((test) {
                    final row = [
                      test['testName']?.toString() ?? '',
                      test['date']?.toString() ?? '',
                      test['status']?.toString() ?? '',
                      test['maxMarks']?.toString() ?? '',
                      test['duration']?.toString() ?? '',
                      test['time']?.toString() ?? '',
                    ];
                    if (_selectedSubject == 'All Subjects') {
                      row.insert(0, test['Subject'] ?? '');
                    }
                    return row;
                  }).toList(),
                  cellStyle: const pw.TextStyle(fontSize: 12),
                  cellAlignments: _selectedSubject == 'All Subjects'
                      ? {
                          0: pw.Alignment.centerLeft,
                          1: pw.Alignment.centerLeft,
                          2: pw.Alignment.center,
                          3: pw.Alignment.center,
                          4: pw.Alignment.center,
                          5: pw.Alignment.center,
                          6: pw.Alignment.center,
                        }
                      : {
                          0: pw.Alignment.centerLeft,
                          1: pw.Alignment.center,
                          2: pw.Alignment.center,
                          3: pw.Alignment.center,
                          4: pw.Alignment.center,
                          5: pw.Alignment.center,
                        },
                  border: pw.TableBorder.all(
                    color: PdfColors.grey300,
                    width: 1,
                  ),
                  headerStyle: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                  ),
                  headerDecoration: pw.BoxDecoration(
                    color: PdfColors.blue900,
                  ),
                  headerPadding: const pw.EdgeInsets.all(8),
                  cellPadding: const pw.EdgeInsets.all(8),
                  rowDecoration: pw.BoxDecoration(
                    border: pw.Border(
                      bottom: pw.BorderSide(
                        color: PdfColors.grey200,
                        width: 1,
                      ),
                    ),
                  ),
                ),
                pw.SizedBox(height: 24),
                pw.Divider(),
                pw.Center(
                  child: pw.Text(
                    'Generated by School App - $formattedDate',
                    style: pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.grey600,
                    ),
                  ),
                ),
              ];
            },
          ),
        );

        // Save the PDF to a temporary file
        final output = await getTemporaryDirectory();
        final file = File(
            '${output.path}/test_zone_report_${_selectedSubject ?? 'subject'}_${DateTime.now().millisecondsSinceEpoch}.pdf');
        await file.writeAsBytes(await pdf.save());

        if (mounted) {
          scaffoldMessenger.hideCurrentSnackBar();
          await OpenFilex.open(file.path);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Report downloaded successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        scaffoldMessenger.hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate report: \\${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<Map<String, dynamic>> get _filteredSubjectTests {
    final subjectData = studentData?['subjects'] as Map<String, dynamic>?;
    if (subjectData == null) return [];
    if (_selectedSubject == null) return [];
    if (_selectedSubject == 'All Subjects') {
      // Collect all tests from all subjects
      List<Map<String, dynamic>> allTests = [];
      subjectData.forEach((subject, data) {
        final tests = data['tests'] as List<dynamic>?;
        if (tests != null) {
          for (var test in tests) {
            final testMap = Map<String, dynamic>.from(test);
            testMap['Subject'] = subject;
            allTests.add(testMap);
          }
        }
      });
      return allTests;
    } else {
      if (!subjectData.containsKey(_selectedSubject)) return [];
      final tests = subjectData[_selectedSubject]['tests'] as List<dynamic>?;
      if (tests == null) return [];
      return tests.cast<Map<String, dynamic>>();
    }
  }

  List<Map<String, dynamic>> get _filteredAssessments {
    final selectedTest = _selectedTest ?? 'All Tests';
    final selectedClass = _selectedClass ??
        'All Classes'; // Assuming you have _selectedClass variable

    List<Map<String, dynamic>> assessments =
        (studentData?['assessments'] as List<dynamic>? ?? [])
            .cast<Map<String, dynamic>>();

    // Filter by test type
    if (selectedTest != 'All Tests') {
      assessments =
          assessments.where((a) => a['examType'] == selectedTest).toList();
    }

    // Filter by class
    if (selectedClass != 'All Classes') {
      assessments =
          assessments.where((a) => a['class'] == selectedClass).toList();
    }

    return assessments;
  }

  Future<void> _downloadSampleTablePdf() async {
    if (!mounted) return;

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    scaffoldMessenger.showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            SizedBox(width: 12),
            Text('Generating report...'),
          ],
        ),
        duration: Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
      ),
    );

    try {
      final pdf = pw.Document();
      final now = DateTime.now();
      final formattedDate = '${now.day}/${now.month}/${now.year}';
      final assessments = _filteredAssessments;
      if (assessments.isEmpty) {
        if (mounted) {
          scaffoldMessenger.hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text('No assessment data available for the selected exam.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return [
              pw.Header(
                level: 0,
                child: pw.Text(
                  'Subject Wise Performance Report',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue900,
                  ),
                ),
              ),
              pw.SizedBox(height: 16),
              pw.Text('Generated on: $formattedDate'),
              pw.SizedBox(height: 16),
              pw.Table.fromTextArray(
                headers: [
                  'Subject',
                  'Exam',
                  'Marks',
                  'Grade',
                  'Date',
                ],
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
                headerDecoration: pw.BoxDecoration(
                  color: PdfColors.blue900,
                ),
                data: assessments.map((assessment) {
                  return [
                    assessment['subject'] ?? '',
                    assessment['examType'] ?? '',
                    assessment['marks']?.toString() ?? '',
                    assessment['grade'] ?? '',
                    assessment['date']?.toString() ?? '',
                  ];
                }).toList(),
                cellStyle: const pw.TextStyle(fontSize: 12),
                cellAlignments: {
                  0: pw.Alignment.centerLeft,
                  1: pw.Alignment.center,
                  2: pw.Alignment.center,
                  3: pw.Alignment.center,
                  4: pw.Alignment.center,
                },
                border: pw.TableBorder.all(
                  color: PdfColors.grey300,
                  width: 1,
                ),
                headerPadding: const pw.EdgeInsets.all(8),
                cellPadding: const pw.EdgeInsets.all(8),
                rowDecoration: pw.BoxDecoration(
                  border: pw.Border(
                    bottom: pw.BorderSide(
                      color: PdfColors.grey200,
                      width: 1,
                    ),
                  ),
                ),
              ),
              pw.SizedBox(height: 24),
              pw.Divider(),
              pw.Center(
                child: pw.Text(
                  'Generated by School App - $formattedDate',
                  style: pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey600,
                  ),
                ),
              ),
            ];
          },
        ),
      );
      final output = await getTemporaryDirectory();
      final file = File(
          '${output.path}/subject_performance_report_${DateTime.now().millisecondsSinceEpoch}.pdf');
      await file.writeAsBytes(await pdf.save());
      if (mounted) {
        scaffoldMessenger.hideCurrentSnackBar();
        await OpenFilex.open(file.path);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Report downloaded successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        scaffoldMessenger.hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate report: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue[900]!, Colors.blue[50]!],
            stops: const [0.0, 0.3],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Text(
                      'Academic Reports',
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: Colors.blue[900],
                  indicatorWeight: 3,
                  labelColor: Colors.blue[900],
                  unselectedLabelColor: Colors.grey,
                  labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                  tabs: const [
                    Tab(text: 'Campus Reports'),
                    Tab(text: 'App Reports'),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  color: Colors.white,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // Campus Reports Tab
                      SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Card(
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Academic Performance',
                                      style: GoogleFonts.poppins(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue[900],
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      children: [
                                        Expanded(
                                          child:
                                              DropdownButtonFormField<String>(
                                            value: _selectedClass,
                                            items: _classes
                                                .map((c) => DropdownMenuItem(
                                                      value: c,
                                                      child: Text(c,
                                                          style: GoogleFonts
                                                              .poppins()),
                                                    ))
                                                .toList(),
                                            onChanged: (val) => setState(
                                                () => _selectedClass = val),
                                            decoration: InputDecoration(
                                              labelText: 'Class',
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 16),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child:
                                              DropdownButtonFormField<String>(
                                            value: _selectedTest,
                                            items: _tests
                                                .map((t) => DropdownMenuItem(
                                                      value: t,
                                                      child: Text(t,
                                                          style: GoogleFonts
                                                              .poppins()),
                                                    ))
                                                .toList(),
                                            onChanged: (val) => setState(
                                                () => _selectedTest = val),
                                            decoration: InputDecoration(
                                              labelText: 'Exam',
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 16),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ).animate().fadeIn().slideY(),
                            const SizedBox(height: 24),
                            Card(
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Subject Wise Performance',
                                          style: GoogleFonts.poppins(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blue[900],
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.info_outline),
                                          onPressed: () {
                                            // Show info dialog
                                          },
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: DataTable(
                                        headingRowColor: MaterialStateProperty
                                            .resolveWith<Color?>(
                                          (Set<MaterialState> states) =>
                                              Colors.blue[50],
                                        ),
                                        columnSpacing: 28,
                                        horizontalMargin: 12,
                                        columns: [
                                          DataColumn(
                                            label: Text('Subject',
                                                style: GoogleFonts.poppins(
                                                    fontWeight:
                                                        FontWeight.bold)),
                                          ),
                                          DataColumn(
                                            label: Text('Exam',
                                                style: GoogleFonts.poppins(
                                                    fontWeight:
                                                        FontWeight.bold)),
                                            numeric: true,
                                          ),
                                          DataColumn(
                                            label: Text('Marks',
                                                style: GoogleFonts.poppins(
                                                    fontWeight:
                                                        FontWeight.bold)),
                                            numeric: true,
                                          ),
                                          DataColumn(
                                            label: Text('Grade',
                                                style: GoogleFonts.poppins(
                                                    fontWeight:
                                                        FontWeight.bold)),
                                          ),
                                          DataColumn(
                                            label: Text('Date',
                                                style: GoogleFonts.poppins(
                                                    fontWeight:
                                                        FontWeight.bold)),
                                          ),
                                        ],
                                        rows: _filteredAssessments
                                            .map<DataRow>((assessment) {
                                          return DataRow(
                                            cells: [
                                              DataCell(Text(
                                                  assessment['subject'] ?? '',
                                                  style:
                                                      GoogleFonts.poppins())),
                                              DataCell(Text(
                                                  assessment['examType'] ?? '',
                                                  style:
                                                      GoogleFonts.poppins())),
                                              DataCell(Text(
                                                  assessment['marks']
                                                          ?.toString() ??
                                                      '',
                                                  style:
                                                      GoogleFonts.poppins())),
                                              DataCell(Text(
                                                  assessment['grade'] ?? '',
                                                  style:
                                                      GoogleFonts.poppins())),
                                              DataCell(Text(
                                                  assessment['date']
                                                          ?.toString() ??
                                                      '',
                                                  style:
                                                      GoogleFonts.poppins())),
                                            ],
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ).animate().fadeIn().slideY(
                                delay: const Duration(milliseconds: 200)),
                            const SizedBox(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: _downloadSampleTablePdf,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue[900],
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    icon: const Icon(Icons.download),
                                    label: Text(
                                      "Download Report",
                                      style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                ProgressPage()),
                                      );
                                    },
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 16),
                                      side:
                                          BorderSide(color: Colors.blue[900]!),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    icon: const Icon(Icons.bar_chart),
                                    label: Text(
                                      "View Progress",
                                      style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                              ],
                            ).animate().fadeIn().slideY(
                                delay: const Duration(milliseconds: 400)),
                          ],
                        ),
                      ),
                      // App Reports Tab
                      isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : studentData == null
                              ? const Center(child: Text('No data available'))
                              : // Progress Tab
                              FutureBuilder<UserData>(
                                  future: userDataFuture,
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return Center(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Lottie.network(
                                              'https://assets9.lottiefiles.com/packages/lf20_x62chJ.json',
                                              width: 200,
                                              height: 200,
                                            ),
                                            const SizedBox(height: 16),
                                            Text(
                                              'Loading your progress...',
                                              style: GoogleFonts.poppins(
                                                fontSize: 16,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    } else if (snapshot.hasError) {
                                      return Center(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.error_outline,
                                                size: 64,
                                                color: Colors.red[300]),
                                            const SizedBox(height: 16),
                                            Text(
                                              'Error loading data',
                                              style: GoogleFonts.poppins(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.red[900],
                                              ),
                                            ),
                                            Text(
                                              'Please try again later',
                                              style: GoogleFonts.poppins(
                                                  color: Colors.grey[600]),
                                            ),
                                          ],
                                        ),
                                      );
                                    } else if (!snapshot.hasData) {
                                      return Center(
                                        child: Text(
                                          'No data available',
                                          style:
                                              GoogleFonts.poppins(fontSize: 16),
                                        ),
                                      );
                                    }

                                    final data = snapshot.data!;
                                    return SingleChildScrollView(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // Header and Download Button
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  'App Usage Report',
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 20,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.blue[900],
                                                  ),
                                                ),
                                              ),
                                              ElevatedButton.icon(
                                                onPressed:
                                                    _downloadAppReportPdf,
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      Colors.blue[900],
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                    vertical: 12,
                                                    horizontal: 16,
                                                  ),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12),
                                                  ),
                                                ),
                                                icon: const Icon(Icons.download,
                                                    size: 20),
                                                label: Text(
                                                  'Download Report',
                                                  style: GoogleFonts.poppins(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 16),

                                          // Filter Options Card
                                          Card(
                                            elevation: 4,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                            ),
                                            child: Padding(
                                              padding: const EdgeInsets.all(16),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'Filter Options',
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.blue[900],
                                                    ),
                                                  ),
                                                  const SizedBox(height: 12),
                                                  // Subject Dropdown
                                                  DropdownButtonFormField<
                                                      String>(
                                                    value: _selectedSubject,
                                                    items: _subjects
                                                        .map((subject) =>
                                                            DropdownMenuItem(
                                                              value: subject,
                                                              child: Text(
                                                                  subject,
                                                                  style: GoogleFonts
                                                                      .poppins()),
                                                            ))
                                                        .toList(),
                                                    onChanged: (val) =>
                                                        setState(() =>
                                                            _selectedSubject =
                                                                val),
                                                    decoration: InputDecoration(
                                                      labelText: 'Subject',
                                                      border:
                                                          OutlineInputBorder(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(12),
                                                      ),
                                                      contentPadding:
                                                          const EdgeInsets
                                                              .symmetric(
                                                              horizontal: 16),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 12),
                                                  Row(
                                                    children: [
                                                      Expanded(
                                                        child:
                                                            DropdownButtonFormField<
                                                                String>(
                                                          value:
                                                              _selectedZoneType,
                                                          items: _zoneTypes
                                                              .map((type) =>
                                                                  DropdownMenuItem(
                                                                    value: type,
                                                                    child: Text(
                                                                        type,
                                                                        style: GoogleFonts
                                                                            .poppins()),
                                                                  ))
                                                              .toList(),
                                                          onChanged:
                                                              (val) async {
                                                            setState(() =>
                                                                _selectedZoneType =
                                                                    val);
                                                          },
                                                          decoration:
                                                              InputDecoration(
                                                            labelText:
                                                                'Zone Type',
                                                            border:
                                                                OutlineInputBorder(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          12),
                                                            ),
                                                            contentPadding:
                                                                const EdgeInsets
                                                                    .symmetric(
                                                                    horizontal:
                                                                        16),
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 16),
                                                      Expanded(
                                                        child: InkWell(
                                                          onTap: () async {
                                                            final DateTimeRange?
                                                                picked =
                                                                await showDateRangePicker(
                                                              context: context,
                                                              firstDate:
                                                                  _minDate,
                                                              lastDate:
                                                                  _maxDate,
                                                              currentDate:
                                                                  DateTime
                                                                      .now(),
                                                              saveText:
                                                                  'Set Date Range',
                                                              initialDateRange:
                                                                  _selectedDateRange ??
                                                                      DateTimeRange(
                                                                        start: DateTime.now().subtract(const Duration(
                                                                            days:
                                                                                7)),
                                                                        end: DateTime
                                                                            .now(),
                                                                      ),
                                                              builder: (context,
                                                                  child) {
                                                                return Theme(
                                                                  data: Theme.of(
                                                                          context)
                                                                      .copyWith(
                                                                    colorScheme:
                                                                        ColorScheme
                                                                            .light(
                                                                      primary: Colors
                                                                              .blue[
                                                                          900]!,
                                                                      onPrimary:
                                                                          Colors
                                                                              .white,
                                                                      surface:
                                                                          Colors
                                                                              .white,
                                                                      onSurface:
                                                                          Colors
                                                                              .blue[900]!,
                                                                    ),
                                                                  ),
                                                                  child: child!,
                                                                );
                                                              },
                                                            );

                                                            if (picked !=
                                                                null) {
                                                              setState(() {
                                                                _selectedDateRange =
                                                                    picked;
                                                              });
                                                            }
                                                          },
                                                          child: Container(
                                                            padding:
                                                                const EdgeInsets
                                                                    .symmetric(
                                                                    horizontal:
                                                                        16,
                                                                    vertical:
                                                                        12),
                                                            decoration:
                                                                BoxDecoration(
                                                              border: Border.all(
                                                                  color: Colors
                                                                      .grey),
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          12),
                                                            ),
                                                            child: Row(
                                                              mainAxisAlignment:
                                                                  MainAxisAlignment
                                                                      .spaceBetween,
                                                              children: [
                                                                Text(
                                                                  _selectedDateRange ==
                                                                          null
                                                                      ? 'Date Range'
                                                                      : '${_selectedDateRange!.start.day}/${_selectedDateRange!.start.month} - ${_selectedDateRange!.end.day}/${_selectedDateRange!.end.month}',
                                                                  style: GoogleFonts
                                                                      .poppins(
                                                                    color: _selectedDateRange ==
                                                                            null
                                                                        ? Colors.grey[
                                                                            600]
                                                                        : Colors
                                                                            .black,
                                                                  ),
                                                                ),
                                                                Icon(
                                                                    Icons
                                                                        .calendar_today,
                                                                    color: Colors
                                                                            .blue[
                                                                        900]),
                                                              ],
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 16),

                                          // Example test cards
                                          // Column(
                                          //   children: [
                                          //     _buildTestCard('Test 1'),
                                          //     const SizedBox(height: 12),
                                          //     _buildTestCard('Test 2'),
                                          //     // Add more tests as needed
                                          //   ],
                                          // ),

                                          //   const SizedBox(height: 16),
                                          //   UserSummary(user: data.user),
                                          //   const SizedBox(height: 16),
                                          //   TopLearners(learners: data.learners),
                                          //   const SizedBox(height: 16),
                                          //   ProgressReport(reports: data.reports),
                                          //   const SizedBox(height: 16),
                                          //   RecentAchievements(
                                          //       achievements: data.achievements),
                                          //   const SizedBox(height: 16),
                                          //   LearningProgress(
                                          //       progressList: data.progressList),
                                          //   const SizedBox(height: 16),
                                          //   QASummary(stats: data.qaStats),
                                          //   const SizedBox(height: 16),
                                          //   AchievementOverview(
                                          //       items: data.overviewItems),
                                        ]
                                            .animate(
                                                interval: const Duration(
                                                    milliseconds: 100))
                                            .fadeIn()
                                            .slideY(),
                                      ),
                                    );
                                  },
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

  Widget _buildTestCard(String testName) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              testName,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.blue[900],
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Implement view logic
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Viewing $testName')),
                    );
                  },
                  icon: const Icon(Icons.visibility),
                  label: const Text('View'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[900],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: () {
                    // TODO: Implement download logic
                    QuizReportPage(
                      subjectData: {},
                      topicData: {},
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Download for $testName started')),
                    );
                  },
                  icon: const Icon(Icons.download),
                  label: const Text('Download Report'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.blue[900],
                    side: BorderSide(color: Colors.blue[900]!),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
