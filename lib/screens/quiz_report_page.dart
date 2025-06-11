import 'dart:io';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MaterialApp(
    home: QuizReportPage(
      subjectData: {'title': 'Mathematics'},
      topicData: {'title': 'Algebra'},
    ),
  ));
}

class QuizReportPage extends StatefulWidget {
  final Map<String, dynamic> subjectData;
  final Map<String, dynamic> topicData;

  const QuizReportPage(
      {super.key, required this.subjectData, required this.topicData});

  @override
  _QuizReportPageState createState() => _QuizReportPageState();
}

class _QuizReportPageState extends State<QuizReportPage> {
  List<Map<String, dynamic>> _questions = [];
  List<int?> _selectedAnswers = [];
  int _score = 0;

  @override
  void initState() {
    super.initState();
    // Sample data
    _questions = [
      {
        'question': 'What is the capital of France?',
        'options': ['Berlin', 'London', 'Paris', 'Madrid'],
        'correctAnswer': 2,
        'explanation': 'Paris is the capital city of France.',
      },
      {
        'question': 'Which planet is known as the Red Planet?',
        'options': ['Earth', 'Mars', 'Jupiter', 'Saturn'],
        'correctAnswer': 1,
        'explanation': 'Mars is often called the Red Planet.',
      },
      {
        'question': 'Who wrote "Hamlet"?',
        'options': [
          'Charles Dickens',
          'William Shakespeare',
          'Mark Twain',
          'Jane Austen'
        ],
        'correctAnswer': 1,
        'explanation': '"Hamlet" was written by William Shakespeare.',
      },
    ];
    // Simulate user answers (e.g., user chose Paris, Mars, and Mark Twain)
    _selectedAnswers = [2, 1, 2];
    // Calculate score
    _score = 0;
    for (int i = 0; i < _questions.length; i++) {
      if (_selectedAnswers[i] == _questions[i]['correctAnswer']) {
        _score++;
      }
    }
    setState(() {});
  }

  Future<void> _downloadQuizPdfReport() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text(
              'MCQ Quiz Report',
              style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Text(
              'Subject: ${widget.subjectData['title'] ?? widget.subjectData['name'] ?? ''}'),
          pw.Text(
              'Topic: ${widget.topicData['title'] ?? widget.topicData['name'] ?? ''}'),
          pw.SizedBox(height: 16),
          pw.Text('Score: $_score / ${_questions.length}'),
          pw.SizedBox(height: 16),
          ...List.generate(_questions.length, (index) {
            final q = _questions[index];
            final correct = q['correctAnswer'] as int? ?? 0;
            final selected = _selectedAnswers[index];
            return pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 16),
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Q${index + 1}: ${q['question']}',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 4),
                  ...List.generate((q['options'] as List).length, (optIdx) {
                    final isCorrect = optIdx == correct;
                    final isSelected = selected == optIdx;
                    return pw.Row(
                      children: [
                        if (isCorrect)
                          pw.Text('✔ ',
                              style: pw.TextStyle(color: PdfColors.green))
                        else if (isSelected)
                          pw.Text('✗ ',
                              style: pw.TextStyle(color: PdfColors.red))
                        else
                          pw.Text('   '),
                        pw.Text(q['options'][optIdx]),
                      ],
                    );
                  }),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Your Answer: ${selected != null ? q['options'][selected] : 'Not answered'}',
                    style: pw.TextStyle(
                      color:
                          selected == correct ? PdfColors.green : PdfColors.red,
                    ),
                  ),
                  pw.Text(
                    'Correct Answer: ${q['options'][correct]}',
                    style: const pw.TextStyle(color: PdfColors.green),
                  ),
                  if (q['explanation'] != null &&
                      q['explanation'].toString().isNotEmpty)
                    pw.Padding(
                      padding: const pw.EdgeInsets.only(top: 4),
                      child: pw.Text('Explanation: ${q['explanation']}',
                          style: const pw.TextStyle(
                              fontSize: 10, color: PdfColors.blue)),
                    ),
                ],
              ),
            );
          }),
        ],
      ),
    );

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/mcq_quiz_report.pdf');
    await file.writeAsBytes(await pdf.save());

    // Optionally open the PDF
    await OpenFilex.open(file.path);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PDF report downloaded!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quiz Report'),
        backgroundColor: Colors.blue[900],
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Summary Card
            Card(
              color: Colors.blue[50],
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    const Icon(Icons.assignment_turned_in,
                        color: Colors.blue, size: 40),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Subject: ${widget.subjectData['title'] ?? ''}',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          Text(
                            'Topic: ${widget.topicData['title'] ?? ''}',
                            style: const TextStyle(fontSize: 15),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Score: $_score / ${_questions.length}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: _score == _questions.length
                                  ? Colors.green
                                  : Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.download, color: Colors.blue),
                      tooltip: 'Download PDF Report',
                      onPressed: _downloadQuizPdfReport,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Questions & Answers',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: _questions.length,
                itemBuilder: (context, index) {
                  final q = _questions[index];
                  final correct = q['correctAnswer'] as int? ?? 0;
                  final selected = _selectedAnswers[index];
                  final isCorrect = selected == correct;
                  return Card(
                    color: isCorrect ? Colors.green[50] : Colors.red[50],
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    margin: const EdgeInsets.only(bottom: 16),
                    elevation: 1,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                isCorrect ? Icons.check_circle : Icons.cancel,
                                color: isCorrect ? Colors.green : Colors.red,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Q${index + 1}: ${q['question']}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ...List.generate((q['options'] as List).length,
                              (optIdx) {
                            final optionIsCorrect = optIdx == correct;
                            final optionIsSelected = selected == optIdx;
                            return Row(
                              children: [
                                if (optionIsCorrect)
                                  const Icon(Icons.check,
                                      color: Colors.green, size: 16)
                                else if (optionIsSelected)
                                  const Icon(Icons.close,
                                      color: Colors.red, size: 16)
                                else
                                  const SizedBox(width: 16),
                                const SizedBox(width: 4),
                                Text(q['options'][optIdx]),
                              ],
                            );
                          }),
                          const SizedBox(height: 8),
                          Text(
                            'Your Answer: ${selected != null ? q['options'][selected] : 'Not answered'}',
                            style: TextStyle(
                              color: isCorrect ? Colors.green : Colors.red,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            'Correct Answer: ${q['options'][correct]}',
                            style: const TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.w500),
                          ),
                          if (q['explanation'] != null &&
                              q['explanation'].toString().isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                'Explanation: ${q['explanation']}',
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.blue),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
