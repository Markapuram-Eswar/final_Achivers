import 'package:cloud_firestore/cloud_firestore.dart';

class AttendanceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Helper method to normalize class name
  String normalizeClassName(String className) {
    // Remove "Class" prefix if present
    String normalized = className.replaceAll('Class ', '');
    normalized = normalized.replaceAll('class ', ''); // Also handle lowercase 'class'

    // Remove "th", "st", "nd", "rd" suffixes if present
    normalized = normalized.replaceAll(RegExp(r'(th|st|nd|rd)$'), '');

    // Remove any extra spaces
    normalized = normalized.trim();

    // Convert to number and back to string to ensure consistent format
    try {
      final number = int.parse(normalized);
      return number.toString();
    } catch (e) {
      return normalized;
    }
  }

  // Get students by class and section
  Future<List<Map<String, dynamic>>> getStudentsByClassAndSection(
    String className,
    String section,
  ) async {
    try {
      final normalizedClass = normalizeClassName(className);
      print('Fetching students for class: $normalizedClass, section: $section');

      // Query with section first
      final QuerySnapshot snapshot = await _firestore
          .collection('students')
          .where('section', isEqualTo: section)
          .get();

      print('Found ${snapshot.docs.length} students in section $section');

      // Filter results to match either original or normalized class name
      final filteredDocs = snapshot.docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final studentClass = data['class']?.toString() ?? '';
        final normalizedStudentClass = normalizeClassName(studentClass);
        
        print('Comparing student class: "$studentClass" (normalized: "$normalizedStudentClass") with query class: "$normalizedClass"');
        
        return normalizedStudentClass == normalizedClass;
      }).toList();

      if (filteredDocs.isEmpty) {
        print('No students found for class: $normalizedClass, section: $section');
        return [];
      }

      print('Found ${filteredDocs.length} matching students');
      
      return filteredDocs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          'name': data['name'] ?? 'Unknown',
          'rollNo': data['rollNumber'] ?? '', // Changed from rollNo to rollNumber
          'class': data['class'] ?? normalizedClass,
          'section': data['section'] ?? section,
          'admissionNo': data['rollNumber'] ?? '', // Using rollNumber as admissionNo
          'parentName': data['fullName'] ?? '', // Changed from parentName to fullName
          'parentPhone': data['parentEmail'] ?? '', // Changed from parentPhone to parentEmail
          ...data,
        };
      }).toList();
    } catch (e) {
      print('Error getting students: $e');
      rethrow;
    }
  }

  // Mark attendance for a class
  Future<void> markAttendance({
    required String className,
    required String section,
    required String date,
    required Map<String, bool> studentAttendance, // Map of studentId to attendance status
    String? remarks,
  }) async {
    try {
      final normalizedClass = normalizeClassName(className);
      final attendanceData = {
        'date': date,
        'class': normalizedClass,
        'section': section,
        'remarks': remarks,
        'attendance': studentAttendance,
        'createdAt': FieldValue.serverTimestamp(),
      };

      // Store in attendance collection
      await _firestore.collection('attendance').add(attendanceData);

      // Update student documents with attendance summary
      await _updateStudentAttendanceSummary(studentAttendance, date);
    } catch (e) {
      print('Error marking attendance: $e');
      rethrow;
    }
  }

  // Update attendance summary in student documents
  Future<void> _updateStudentAttendanceSummary(
    Map<String, bool> studentAttendance,
    String date,
  ) async {
    try {
      for (var entry in studentAttendance.entries) {
        final studentId = entry.key;
        final isPresent = entry.value;

        final studentRef = _firestore.collection('students').doc(studentId);
        final studentDoc = await studentRef.get();
        final studentData = studentDoc.data();

        if (studentData != null) {
          final attendanceSummary = Map<String, dynamic>.from(
              studentData['attendanceSummary'] ?? {});

          // Update monthly attendance
          final month = date.substring(0, 7); // Format: YYYY-MM
          if (!attendanceSummary.containsKey(month)) {
            attendanceSummary[month] = {
              'present': 0,
              'absent': 0,
              'total': 0,
            };
          }

          final monthData = Map<String, dynamic>.from(attendanceSummary[month]);
          if (isPresent) {
            monthData['present'] = (monthData['present'] ?? 0) + 1;
          } else {
            monthData['absent'] = (monthData['absent'] ?? 0) + 1;
          }
          monthData['total'] = (monthData['total'] ?? 0) + 1;
          monthData['percentage'] = (monthData['present'] / monthData['total'] * 100)
              .toStringAsFixed(1);

          attendanceSummary[month] = monthData;

          // Update overall attendance
          final overall = Map<String, dynamic>.from(
              attendanceSummary['overall'] ?? {
                'present': 0,
                'absent': 0,
                'total': 0,
              });

          if (isPresent) {
            overall['present'] = (overall['present'] ?? 0) + 1;
          } else {
            overall['absent'] = (overall['absent'] ?? 0) + 1;
          }
          overall['total'] = (overall['total'] ?? 0) + 1;
          overall['percentage'] =
              (overall['present'] / overall['total'] * 100).toStringAsFixed(1);

          attendanceSummary['overall'] = overall;

          // Update student document
          await studentRef.update({'attendanceSummary': attendanceSummary});
        }
      }
    } catch (e) {
      print('Error updating attendance summary: $e');
      rethrow;
    }
  }

  // Get attendance for a specific date
  Future<Map<String, dynamic>?> getAttendanceByDate(
    String className,
    String section,
    String date,
  ) async {
    try {
      final normalizedClass = normalizeClassName(className);
      final QuerySnapshot snapshot = await _firestore
          .collection('attendance')
          .where('class', isEqualTo: normalizedClass)
          .where('section', isEqualTo: section)
          .where('date', isEqualTo: date)
          .get();

      if (snapshot.docs.isEmpty) return null;

      final data = snapshot.docs.first.data() as Map<String, dynamic>;
      return {
        'id': snapshot.docs.first.id,
        ...data,
      };
    } catch (e) {
      print('Error getting attendance: $e');
      rethrow;
    }
  }

  // Get attendance summary for a student
  Future<Map<String, dynamic>> getStudentAttendanceSummary(String studentId) async {
    try {
      final studentDoc = await _firestore.collection('students').doc(studentId).get();
      final studentData = studentDoc.data();

      if (studentData == null || !studentData.containsKey('attendanceSummary')) {
        return {
          'overall': {
            'present': 0,
            'absent': 0,
            'total': 0,
            'percentage': '0.0',
          },
          'monthly': {},
        };
      }

      final attendanceSummary = Map<String, dynamic>.from(studentData['attendanceSummary']);
      return {
        'overall': attendanceSummary['overall'] ?? {
          'present': 0,
          'absent': 0,
          'total': 0,
          'percentage': '0.0',
        },
        'monthly': Map<String, dynamic>.from(attendanceSummary)
          ..remove('overall'),
      };
    } catch (e) {
      print('Error getting attendance summary: $e');
      rethrow;
    }
  }

  // Get monthly attendance report for a class
  Future<List<Map<String, dynamic>>> getMonthlyAttendanceReport(
    String className,
    String section,
    String month, // Format: YYYY-MM
  ) async {
    try {
      final normalizedClass = normalizeClassName(className);
      final QuerySnapshot snapshot = await _firestore
          .collection('attendance')
          .where('class', isEqualTo: normalizedClass)
          .where('section', isEqualTo: section)
          .where('date', isGreaterThanOrEqualTo: '$month-01')
          .where('date', isLessThanOrEqualTo: '$month-31')
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();
    } catch (e) {
      print('Error getting monthly report: $e');
      rethrow;
    }
  }

  // Check if attendance is already marked for a date
  Future<Map<String, dynamic>?> checkAttendanceMarked(
    String className,
    String section,
    String date,
  ) async {
    try {
      final normalizedClass = normalizeClassName(className);
      print('Checking attendance for class: $normalizedClass, section: $section, date: $date');

      final QuerySnapshot snapshot = await _firestore
          .collection('attendance')
          .where('class', isEqualTo: normalizedClass)
          .where('section', isEqualTo: section)
          .where('date', isEqualTo: date)
          .get();

      if (snapshot.docs.isEmpty) {
        print('No attendance found for this date');
        return null;
      }

      final attendanceData = snapshot.docs.first.data() as Map<String, dynamic>;
      print('Attendance already marked for this date');
      return {
        'id': snapshot.docs.first.id,
        ...attendanceData,
      };
    } catch (e) {
      print('Error checking attendance: $e');
      rethrow;
    }
  }

  // Get all attendance records for a student (by date)
  Future<List<Map<String, dynamic>>> getStudentAttendanceRecords(String studentId) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('attendance')
          .where('attendance.$studentId', isNotEqualTo: null)
          .orderBy('date', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        // Safely handle the attendance map
        final attendance = data['attendance'] as Map<String, dynamic>?;
        if (attendance == null) {
          print('Warning: No attendance data found for document ${doc.id}');
          return {
            'date': data['date'] ?? '',
            'present': false,
            'class': data['class'] ?? '',
            'section': data['section'] ?? '',
            'remarks': data['remarks'] ?? '',
          };
        }
        
        return {
          'date': data['date'] ?? '',
          'present': attendance[studentId] ?? false,
          'class': data['class'] ?? '',
          'section': data['section'] ?? '',
          'remarks': data['remarks'] ?? '',
        };
      }).toList();
    } catch (e) {
      print('Error getting student attendance records: $e');
      rethrow;
    }
  }
} 