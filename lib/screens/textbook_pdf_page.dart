import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class TextbookPdfPage extends StatefulWidget {
  const TextbookPdfPage({Key? key}) : super(key: key);

  @override
  State<TextbookPdfPage> createState() => _TextbookPdfPageState();
}

class _TextbookPdfPageState extends State<TextbookPdfPage> {
  String? _pdfUrl;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPdf();
  }

  Future<void> _loadPdf() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final ref = FirebaseStorage.instance.ref().child('textbook/document.pdf');
      final url = await ref.getDownloadURL();
      setState(() {
        _pdfUrl = url;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load PDF: $e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Textbook PDF')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child:
                      Text(_error!, style: const TextStyle(color: Colors.red)))
              : _pdfUrl != null
                  ? SfPdfViewer.network(_pdfUrl!)
                  : const Center(child: Text('No PDF found.')),
    );
  }
}
