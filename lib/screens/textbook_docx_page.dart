import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';

class TextbookDocxPage extends StatefulWidget {
  const TextbookDocxPage({Key? key}) : super(key: key);

  @override
  State<TextbookDocxPage> createState() => _TextbookDocxPageState();
}

class _TextbookDocxPageState extends State<TextbookDocxPage> {
  bool _downloading = false;
  String? _error;

  Future<void> _downloadAndOpenDocx() async {
    setState(() {
      _downloading = true;
      _error = null;
    });
    try {
      final ref =
          FirebaseStorage.instance.ref().child('textbook/document.docx');
      final url = await ref.getDownloadURL();
      final httpClient = HttpClient();
      final request = await httpClient.getUrl(Uri.parse(url));
      final response = await request.close();
      final bytes = await consolidateHttpClientResponseBytes(response);
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/document.docx');
      await file.writeAsBytes(bytes);
      await OpenFilex.open(file.path);
    } catch (e) {
      setState(() {
        _error = 'Failed to load document: $e';
      });
    } finally {
      setState(() {
        _downloading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Textbook DOCX')),
      body: Center(
        child: _downloading
            ? const CircularProgressIndicator()
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Tap below to view your DOCX textbook:'),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.file_open),
                    label: const Text('Open DOCX Textbook'),
                    onPressed: _downloadAndOpenDocx,
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 20),
                    Text(_error!, style: const TextStyle(color: Colors.red)),
                  ]
                ],
              ),
      ),
    );
  }
}
