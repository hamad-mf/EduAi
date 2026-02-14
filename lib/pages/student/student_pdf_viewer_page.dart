import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import '../../config/app_theme.dart';

class StudentPdfViewerPage extends StatelessWidget {
  const StudentPdfViewerPage({
    super.key,
    required this.title,
    required this.pdfUrl,
  });

  final String title;
  final String pdfUrl;

  Future<void> _downloadPdf(BuildContext context) async {
    try {
      final http.Response response = await http.get(Uri.parse(pdfUrl));
      final Directory dir = await getApplicationDocumentsDirectory();
      final String path = '${dir.path}/$title.pdf';
      final File file = File(path);
      await file.writeAsBytes(response.bodyBytes);

      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Saved to: $path')));
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Download failed: $error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: <Widget>[
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFE3EDFF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: IconButton(
              icon: const Icon(Icons.download_rounded, size: 20),
              color: AppTheme.primaryBlue,
              tooltip: 'Download PDF',
              onPressed: () => _downloadPdf(context),
            ),
          ),
        ],
      ),
      body: SfPdfViewer.network(pdfUrl),
    );
  }
}
