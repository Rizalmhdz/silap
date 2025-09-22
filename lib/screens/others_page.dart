import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:silap/utils/pdfview_page.dart';
import 'package:url_launcher/url_launcher.dart';

class LainnyaPage extends StatefulWidget {
  @override
  _LainnyaPageState createState() => _LainnyaPageState();
}

class _LainnyaPageState extends State<LainnyaPage> {
  final DatabaseReference ref = FirebaseDatabase.instance.ref();
  List<Map<String, dynamic>> lainnyaItems = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchLainnyaItems();
  }

  Future<void> _fetchLainnyaItems() async {
    try {
      final snapshot = await ref.child('lainnya').get();
      if (snapshot.exists) {
        final List<Map<String, dynamic>> tempList = [];
        for (final item in snapshot.children) {
          final val = item.value as Map;
          tempList.add({
            'nama': val['nama'] ?? '',
            'tipe': val['tipe'] ?? 0,
            'file': val['file'] ?? '',
            'link': val['link'] ?? '',
          });
        }
        setState(() {
          lainnyaItems = tempList;
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Open PDF from Google Drive or a URL
  void _openContent(String fileUrl, int tipe) async {
    if (tipe == 0) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => PDFViewPage(fileUrl: fileUrl)),
      );
    } else if (tipe == 1) {
      final url = Uri.tryParse(fileUrl);
      try {
        await launchUrl(url!, mode: LaunchMode.externalApplication);
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Tidak dapat membuka tautan')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Lainnya'),
        backgroundColor: Colors.brown[400],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child:
              isLoading
                  ? Center(child: CircularProgressIndicator())
                  : ListView.builder(
                    itemCount: lainnyaItems.length,
                    itemBuilder: (context, index) {
                      final item = lainnyaItems[index];
                      return Card(
                        elevation: 4,
                        margin: EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: ListTile(
                          title: Text(item['nama']),
                          trailing: Icon(
                            item['tipe'] == 0
                                ? Icons.picture_as_pdf
                                : Icons.link,
                            color: item['tipe'] == 0 ? Colors.red : Colors.blue,
                          ),
                          onTap: () {
                            _openContent(
                              item['tipe'] == 0 ? item['file'] : item['link'],
                              item['tipe'],
                            );
                          },
                        ),
                      );
                    },
                  ),
        ),
      ),
    );
  }
}
