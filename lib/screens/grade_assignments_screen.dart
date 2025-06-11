import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/AssessmentService.dart';

class EnterMarksScreen extends StatefulWidget {
  const EnterMarksScreen({super.key});

  @override
  State<EnterMarksScreen> createState() => _EnterMarksScreenState();
}

class _EnterMarksScreenState extends State<EnterMarksScreen> {
  final _formKey = GlobalKey<FormState>();
  final _assessmentService = AssessmentService();

  String? _selectedClass;
  String? _selectedSection;
  String? _selectedExam;
  String? _selectedSubject;

  final List<String> _classes = [
    'Class 1',
    'Class 2',
    'Class 3',
    'Class 4'
        'Class 5',
    'Class 6',
    'Class 7',
    'Class 8',
    'Class 9',
    'Class 10',
  ];
  final List<String> _sections = ['A', 'B', 'C'];
  final List<String> _exams = ['FA1', 'Mid-Term', 'FA2', 'Final'];
  final List<String> _subjects = ['Maths', 'Science', 'English'];

  List<Map<String, dynamic>> _students = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    if (_selectedClass == null || _selectedSection == null) return;

    setState(() => _isLoading = true);
    try {
      final students = await _assessmentService.getStudentsByClassAndSection(
        _selectedClass!,
        _selectedSection!,
      );

      setState(() {
        _students = students
            .map((student) => {
                  ...student,
                  'controller': TextEditingController(),
                  'grade': '-',
                })
            .toList();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading students: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _calculateGrade(int marks) {
    if (marks >= 90) return 'A+';
    if (marks >= 80) return 'A';
    if (marks >= 70) return 'B';
    if (marks >= 60) return 'C';
    if (marks >= 50) return 'D';
    return 'F';
  }

  Future<void> _submitMarks() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        for (var student in _students) {
          final marks = int.parse(student['controller'].text);
          final grade = _calculateGrade(marks);

          await _assessmentService.saveAssessmentDetails(
            studentId: student['id'],
            examType: _selectedExam!,
            subject: _selectedSubject!,
            marks: marks,
            grade: grade,
            className: _selectedClass!,
            section: _selectedSection!,
          );

          setState(() {
            student['grade'] = grade;
          });
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  'Marks submitted successfully!',
                  style: GoogleFonts.poppins(),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting marks: $e'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    for (var student in _students) {
      student['controller'].dispose();
    }
    super.dispose();
  }

  Widget _buildDropdown(
    String label,
    List<String> items,
    String? selectedValue,
    void Function(String?) onChanged,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: Colors.indigo[900],
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: selectedValue,
              items: items
                  .map((item) => DropdownMenuItem(
                        value: item,
                        child: Text(item, style: GoogleFonts.poppins()),
                      ))
                  .toList(),
              onChanged: (value) {
                onChanged(value);
                if (label == 'Class' || label == 'Section') {
                  _loadStudents();
                }
              },
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.indigo[100]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.indigo[100]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.indigo[400]!),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              validator: (value) => value == null ? 'Required' : null,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Grade Assessment', style: GoogleFonts.poppins()),
        backgroundColor: Colors.indigo[900],
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.indigo[900]!, Colors.indigo[50]!],
            stops: const [0.0, 0.3],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Assessment Details',
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.indigo[900],
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildDropdown(
                            'Class',
                            _classes,
                            _selectedClass,
                            (val) => setState(() => _selectedClass = val),
                          ),
                          _buildDropdown(
                            'Section',
                            _sections,
                            _selectedSection,
                            (val) => setState(() => _selectedSection = val),
                          ),
                          _buildDropdown(
                            'Exam Type',
                            _exams,
                            _selectedExam,
                            (val) => setState(() => _selectedExam = val),
                          ),
                          _buildDropdown(
                            'Subject',
                            _subjects,
                            _selectedSubject,
                            (val) => setState(() => _selectedSubject = val),
                          ),
                        ],
                      ),
                    ),
                  ).animate().fadeIn().slideY(),
                  const SizedBox(height: 20),
                  if (_isLoading)
                    const Center(child: CircularProgressIndicator())
                  else if (_students.isEmpty)
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Center(
                          child: Text(
                            'Select Class and Section to view students',
                            style: GoogleFonts.poppins(
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                      ),
                    )
                  else
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Student Marks',
                              style: GoogleFonts.poppins(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.indigo[900],
                              ),
                            ),
                            const SizedBox(height: 16),
                            ..._students.map(
                              (student) => Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 3,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            student['name'],
                                            style: GoogleFonts.poppins(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          Text(
                                            'Roll No: ${student['rollNo']}',
                                            style: GoogleFonts.poppins(
                                              color: Colors.grey[600],
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      flex: 2,
                                      child: TextFormField(
                                        controller: student['controller'],
                                        keyboardType: TextInputType.number,
                                        style: GoogleFonts.poppins(),
                                        decoration: InputDecoration(
                                          labelText: 'Marks',
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 8,
                                          ),
                                        ),
                                        validator: (value) {
                                          if (value == null || value.isEmpty)
                                            return 'Required';
                                          final number = int.tryParse(value);
                                          if (number == null ||
                                              number < 0 ||
                                              number > 100) return 'Invalid';
                                          return null;
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: student['grade'] == '-'
                                            ? Colors.grey[200]
                                            : student['grade'] == 'F'
                                                ? Colors.red[100]
                                                : Colors.green[100],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Center(
                                        child: Text(
                                          student['grade'],
                                          style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.bold,
                                            color: student['grade'] == '-'
                                                ? Colors.grey[600]
                                                : student['grade'] == 'F'
                                                    ? Colors.red[900]
                                                    : Colors.green[900],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                        .animate()
                        .fadeIn()
                        .slideY(delay: const Duration(milliseconds: 200)),
                  const SizedBox(height: 20),
                  if (_students.isNotEmpty)
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submitMarks,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[600],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white)
                            : Text(
                                'Submit Grades',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    )
                        .animate()
                        .fadeIn()
                        .slideY(delay: const Duration(milliseconds: 400)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
