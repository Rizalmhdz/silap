import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class PDFViewPage extends StatefulWidget {
  final String fileUrl;

  const PDFViewPage({required this.fileUrl});

  @override
  _PDFViewPageState createState() => _PDFViewPageState();
}

class _PDFViewPageState extends State<PDFViewPage> {
  String filePath = '';

  @override
  void initState() {
    super.initState();
    _downloadFile();
  }

  // Download the file and save it locally
  Future<void> _downloadFile() async {
    try {
      final response = await http.get(Uri.parse(widget.fileUrl));
      if (response.statusCode == 200) {
        final dir = await getApplicationDocumentsDirectory();
        final file = File('${dir.path}/downloaded.pdf');

        // Save the downloaded file
        await file.writeAsBytes(response.bodyBytes);

        // Log the file path
        print('File saved to: ${file.path}');

        setState(() {
          filePath = file.path;
        });
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to download PDF')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error occurred while downloading PDF')),
      );
      print('Error downloading file: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Return a loading indicator until the filePath is assigned
    return Scaffold(
      appBar: AppBar(
        title: Text('PDF View'),
        backgroundColor: Colors.brown[400],
      ),
      body:
          filePath.isEmpty
              ? Center(
                child: CircularProgressIndicator(),
              ) // Show loading while downloading
              : PDFView(
                filePath: filePath, // Show PDF after downloading
              ),
    );
  }
}
