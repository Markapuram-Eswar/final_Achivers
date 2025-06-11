import 'package:flutter/material.dart';
import '../services/TestService.dart';

class CreateTestScreen extends StatefulWidget {
  const CreateTestScreen({super.key});

  @override
  State<CreateTestScreen> createState() => _CreateTestScreenState();
}

class _CreateTestScreenState extends State<CreateTestScreen> {
  final TestService _testService = TestService();
  final List<String> _subjects = [
    'Mathematics',
    'Physics',
    'Chemistry',
    'Biology',
    'Computer Science'
  ];
  final List<String> _classes = ['6th', '7th', '8th', '9th', '10th'];
  final List<String> _sections = ['A', 'B', 'C'];
  String _selectedSubject = 'Mathematics';
  String _selectedClass = '10th';
  String _selectedSection = 'A';
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  final TextEditingController _durationController =
      TextEditingController(text: '60');
  final TextEditingController _maxMarksController =
      TextEditingController(text: '100');

  final List<Map<String, dynamic>> _questions = [];

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  void _addQuestion() {
    showDialog(
      context: context,
      builder: (context) => _QuestionTypeDialog(
        onSelectType: (type) {
          Navigator.pop(context);
          showDialog(
            context: context,
            builder: (context) => type == QuestionType.multipleChoice
                ? _AddMultipleChoiceDialog(
                    onAdd: (question) {
                      setState(() {
                        _questions.add({...question, 'type': 'multipleChoice'});
                      });
                      /* Backend TODO: Save MCQ question to backend (API call, database write) */
                    },
                  )
                : type == QuestionType.fillBlanks
                    ? _AddFillBlanksDialog(
                        onAdd: (question) {
                          setState(() {
                            _questions.add({...question, 'type': 'fillBlanks'});
                          });
                          /* Backend TODO: Save fill-in-the-blanks question to backend (API call, database write) */
                        },
                      )
                    : _AddVocalQuestionDialog(
                        onAdd: (question) {
                          setState(() {
                            _questions.add({...question, 'type': 'vocal'});
                          });
                          /* Backend TODO: Save vocal question to backend (API call, database write) */
                        },
                        initialQuestion: null,
                      ),
          );
        },
      ),
    );
  }

  void _editQuestion(int index) {
    final question = _questions[index];
    showDialog(
      context: context,
      builder: (context) => question['type'] == 'multipleChoice'
          ? _AddMultipleChoiceDialog(
              initialQuestion: question,
              onAdd: (updatedQuestion) {
                setState(() {
                  _questions[index] = {
                    ...updatedQuestion,
                    'type': 'multipleChoice'
                  };
                });
              },
            )
          : _AddFillBlanksDialog(
              initialQuestion: question,
              onAdd: (updatedQuestion) {
                setState(() {
                  _questions[index] = {
                    ...updatedQuestion,
                    'type': 'fillBlanks'
                  };
                });
              },
            ),
    );
  }

  void _deleteQuestion(int index) {
    setState(() {
      _questions.removeAt(index);
    });
  }

  Future<void> _createTest() async {
    if (_questions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one question'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      await _testService.createTest(
        subject: _selectedSubject,
        classLevel: _selectedClass,
        section: _selectedSection,
        date: _selectedDate,
        time:
            '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}',
        duration: int.parse(_durationController.text),
        maxMarks: int.parse(_maxMarksController.text),
        questions: _questions,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Test created successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating test: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildQuestionCard(Map<String, dynamic> question, int index) {
    switch (question['type']) {
      case 'multipleChoice':
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            title: Text(
              'Q${index + 1}: ${question['question']}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                ...List.generate(
                  question['options'].length,
                  (optionIndex) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Text(
                          '${String.fromCharCode(65 + optionIndex)}. ',
                          style: TextStyle(
                            color: (question['correctOptions'] as List<int>)
                                    .contains(optionIndex)
                                ? Colors.green
                                : Colors.black87,
                            fontWeight:
                                (question['correctOptions'] as List<int>)
                                        .contains(optionIndex)
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                          ),
                        ),
                        Text(
                          question['options'][optionIndex],
                          style: TextStyle(
                            color: (question['correctOptions'] as List<int>)
                                    .contains(optionIndex)
                                ? Colors.green
                                : Colors.black87,
                            fontWeight:
                                (question['correctOptions'] as List<int>)
                                        .contains(optionIndex)
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _editQuestion(index),
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _deleteQuestion(index),
                ),
              ],
            ),
          ),
        );

      case 'fillBlanks':
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            title: Text(
              'Q${index + 1}: Fill in the blanks',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Text(question['sentence'] ?? question['question']),
                const SizedBox(height: 4),
                Text(
                  'Answer: ${question['answer']}',
                  style: const TextStyle(color: Colors.green),
                ),
                if (question['hint'] != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Hint: ${question['hint']}',
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      color: Colors.orange[800],
                    ),
                  ),
                ],
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _editQuestion(index),
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _deleteQuestion(index),
                ),
              ],
            ),
          ),
        );

      case 'vocal':
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            title: Text(
              'Q${index + 1}: Vocal Response',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Text(question['question']),
                const SizedBox(height: 4),
                if (question['sampleAnswer'] != null) ...[
                  const Text(
                    'Sample Answer:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(question['sampleAnswer']),
                ],
                if (question['keywords'] != null &&
                    question['keywords'].isNotEmpty) ...[
                  const SizedBox(height: 4),
                  const Text(
                    'Keywords:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(question['keywords'].join(', ')),
                ],
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _editQuestion(index),
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _deleteQuestion(index),
                ),
              ],
            ),
          ),
        );

      default:
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            title: Text('Q${index + 1}: Unknown Question Type'),
            subtitle: const Text('This question type is not supported'),
            trailing: IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _deleteQuestion(index),
            ),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.blue[900],
        title: const Text(
          'Create Test',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Test Details'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    DropdownButtonFormField<String>(
                      value: _selectedSubject,
                      decoration: const InputDecoration(
                        labelText: 'Subject',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.book_outlined),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      isExpanded: true,
                      items: _subjects.map((String subject) {
                        return DropdownMenuItem<String>(
                          value: subject,
                          child: Text(
                            subject,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedSubject = newValue!;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedClass,
                            decoration: const InputDecoration(
                              labelText: 'Class',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.school_outlined),
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                            ),
                            isExpanded: true,
                            items: _classes.map((String className) {
                              return DropdownMenuItem<String>(
                                value: className,
                                child: Text(
                                  className,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              setState(() {
                                _selectedClass = newValue!;
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
                              prefixIcon: Icon(Icons.group_outlined),
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                            ),
                            isExpanded: true,
                            items: _sections.map((String section) {
                              return DropdownMenuItem<String>(
                                value: section,
                                child: Text(
                                  'Section $section',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              setState(() {
                                _selectedSection = newValue!;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            _buildSectionTitle('Schedule'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    ListTile(
                      title: Text(
                        '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                      ),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () => _selectDate(context),
                    ),
                    const Divider(),
                    ListTile(
                      title: Text(_selectedTime.format(context)),
                      trailing: const Icon(Icons.access_time),
                      onTap: () => _selectTime(context),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            _buildSectionTitle('Test Configuration'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextField(
                      controller: _durationController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Duration (minutes)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _maxMarksController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Maximum Marks',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            _buildSectionTitle('Questions'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _questions.length,
                      itemBuilder: (context, index) {
                        return _buildQuestionCard(_questions[index], index);
                      },
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text('Add Question'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[900],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: _addQuestion,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            _buildSectionTitle('Instructions'),
            const Card(
              child: TextField(
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Enter test instructions...',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(16),
                ),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: _createTest,
                child: const Text(
                  'Create Test',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }
}

enum QuestionType {
  multipleChoice,
  fillBlanks,
  vocal,
}

class _QuestionTypeDialog extends StatelessWidget {
  final Function(QuestionType) onSelectType;

  const _QuestionTypeDialog({required this.onSelectType});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select Question Type'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.radio_button_checked),
            title: const Text('Multiple Choice'),
            onTap: () => onSelectType(QuestionType.multipleChoice),
          ),
          ListTile(
            leading: const Icon(Icons.short_text),
            title: const Text('Fill in the Blanks'),
            onTap: () => onSelectType(QuestionType.fillBlanks),
          ),
          ListTile(
            leading: const Icon(Icons.mic),
            title: const Text('Vocal'),
            onTap: () => onSelectType(QuestionType.vocal),
          ),
        ],
      ),
    );
  }
}

class _AddMultipleChoiceDialog extends StatefulWidget {
  final Function(Map<String, dynamic>) onAdd;
  final Map<String, dynamic>? initialQuestion;

  const _AddMultipleChoiceDialog({
    required this.onAdd,
    this.initialQuestion,
  });

  @override
  State<_AddMultipleChoiceDialog> createState() =>
      _AddMultipleChoiceDialogState();
}

class _AddMultipleChoiceDialogState extends State<_AddMultipleChoiceDialog> {
  late TextEditingController _questionController;
  late List<TextEditingController> _optionControllers;
  late List<bool> _correctOptions;

  @override
  void initState() {
    super.initState();
    _questionController = TextEditingController(
      text: widget.initialQuestion?['question'] ?? '',
    );
    _optionControllers = List.generate(
      4,
      (index) => TextEditingController(
        text: widget.initialQuestion?['options']?[index] ?? '',
      ),
    );
    _correctOptions = List.generate(
      4,
      (index) =>
          widget.initialQuestion?['correctOptions']?.contains(index) ?? false,
    );
  }

  @override
  void dispose() {
    _questionController.dispose();
    for (var controller in _optionControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
          widget.initialQuestion == null ? 'Add Question' : 'Edit Question'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _questionController,
              decoration: const InputDecoration(
                labelText: 'Question',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            ...List.generate(
              4,
              (index) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Checkbox(
                      value: _correctOptions[index],
                      onChanged: (value) {
                        setState(() {
                          _correctOptions[index] = value!;
                        });
                      },
                    ),
                    Expanded(
                      child: TextField(
                        controller: _optionControllers[index],
                        decoration: InputDecoration(
                          labelText:
                              'Option ${String.fromCharCode(65 + index)}',
                          border: const OutlineInputBorder(),
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
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_questionController.text.isEmpty ||
                _optionControllers
                    .any((controller) => controller.text.isEmpty) ||
                !_correctOptions.contains(true)) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                      'Please fill all fields and select at least one correct answer'),
                  backgroundColor: Colors.red,
                ),
              );
              return;
            }
            final List<int> correctOptionIndices = [];
            for (int i = 0; i < _correctOptions.length; i++) {
              if (_correctOptions[i]) {
                correctOptionIndices.add(i);
              }
            }
            widget.onAdd({
              'question': _questionController.text,
              'options': _optionControllers.map((c) => c.text).toList(),
              'correctOptions': correctOptionIndices,
            });
            Navigator.pop(context);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _AddFillBlanksDialog extends StatefulWidget {
  final Function(Map<String, dynamic>) onAdd;
  final Map<String, dynamic>? initialQuestion;

  const _AddFillBlanksDialog({
    required this.onAdd,
    this.initialQuestion,
  });

  @override
  State<_AddFillBlanksDialog> createState() => _AddFillBlanksDialogState();
}

class _AddVocalQuestionDialog extends StatefulWidget {
  final Function(Map<String, dynamic>) onAdd;
  final Map<String, dynamic>? initialQuestion;

  const _AddVocalQuestionDialog({
    required this.onAdd,
    this.initialQuestion,
  });

  @override
  State<_AddVocalQuestionDialog> createState() =>
      _AddVocalQuestionDialogState();
}

class _AddVocalQuestionDialogState extends State<_AddVocalQuestionDialog> {
  late TextEditingController _questionController;
  late TextEditingController _keywordsController;
  String _selectedLanguage = 'English';
  final List<String> _languages = [
    'English',
    'Telugu',
    'Tamil',
    'Malayalam',
    'Hindi'
  ];

  @override
  void initState() {
    super.initState();
    _questionController = TextEditingController(
      text: widget.initialQuestion?['question'] ?? '',
    );
    _keywordsController = TextEditingController(
      text: widget.initialQuestion?['keywords']?.join(', ') ?? '',
    );
    _selectedLanguage = widget.initialQuestion?['language'] ?? 'English';
  }

  @override
  void dispose() {
    _questionController.dispose();
    _keywordsController.dispose();
    super.dispose();
  }

  void _saveQuestion() {
    if (_questionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a question')),
      );
      return;
    }

    final keywords = _keywordsController.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    widget.onAdd({
      'question': _questionController.text.trim(),
      'language': _selectedLanguage,
      'keywords': keywords,
    });
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Vocal Question'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<String>(
              value: _selectedLanguage,
              decoration: const InputDecoration(
                labelText: 'Preferred Language',
                border: OutlineInputBorder(),
              ),
              items: _languages
                  .map((language) => DropdownMenuItem(
                        value: language,
                        child: Text(language),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedLanguage = value!;
                });
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _questionController,
              decoration: const InputDecoration(
                labelText: 'Question',
                border: OutlineInputBorder(),
                hintText: 'Ask your question here',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _keywordsController,
              decoration: const InputDecoration(
                labelText: 'Keywords (comma separated)',
                border: OutlineInputBorder(),
                hintText: 'key1, key2, key3',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saveQuestion,
          child: const Text('Add Question'),
        ),
      ],
    );
  }
}

class _AddFillBlanksDialogState extends State<_AddFillBlanksDialog> {
  late TextEditingController _sentenceController;
  late TextEditingController _answerController;
  late TextEditingController _hintController;
  late TextEditingController _jumbledLettersController;

  @override
  void initState() {
    super.initState();
    _sentenceController = TextEditingController(
      text: widget.initialQuestion?['question'] ??
          widget.initialQuestion?['sentence'] ??
          '',
    );
    _answerController = TextEditingController(
      text: widget.initialQuestion?['answer'] ?? '',
    );
    _hintController = TextEditingController(
      text: widget.initialQuestion?['hint'] ?? '',
    );
    _jumbledLettersController = TextEditingController(
      text: widget.initialQuestion?['jumbledLetters']?.join(', ') ?? '',
    );
  }

  @override
  void dispose() {
    _sentenceController.dispose();
    _answerController.dispose();
    _hintController.dispose();
    _jumbledLettersController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initialQuestion == null
          ? 'Add Fill in the Blanks'
          : 'Edit Fill in the Blanks'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _sentenceController,
              decoration: const InputDecoration(
                labelText: 'Question',
                border: OutlineInputBorder(),
                hintText: 'What is the capital of France?',
                alignLabelWithHint: true,
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _answerController,
              decoration: const InputDecoration(
                labelText: 'Answer',
                border: OutlineInputBorder(),
                hintText: 'Paris',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _hintController,
              decoration: const InputDecoration(
                labelText: 'Hint (optional)',
                border: OutlineInputBorder(),
                hintText: 'Think of the Eiffel Tower',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _jumbledLettersController,
              decoration: const InputDecoration(
                labelText: 'Jumbled Letters (comma separated, optional)',
                border: OutlineInputBorder(),
                hintText: 'P, A, R, I, S',
                helperText: 'Enter letters that will be jumbled for the answer',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_sentenceController.text.isEmpty ||
                _answerController.text.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content:
                      Text('Please fill in the question and answer fields'),
                  backgroundColor: Colors.red,
                ),
              );
              return;
            }
            widget.onAdd({
              'question': _sentenceController.text,
              'answer': _answerController.text,
              'hint':
                  _hintController.text.isNotEmpty ? _hintController.text : null,
              'jumbledLetters': _jumbledLettersController.text
                  .split(',')
                  .map((e) => e.trim())
                  .where((e) => e.isNotEmpty)
                  .toList(),
            });
            Navigator.pop(context);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
