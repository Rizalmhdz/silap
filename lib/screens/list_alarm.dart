import 'package:alarm/alarm.dart';
import 'package:alarm/model/alarm_settings.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'edit_alarm.dart';

class ListAlarmsPage extends StatefulWidget {
  @override
  State<ListAlarmsPage> createState() => _ListAlarmsPageState();
}

class _ListAlarmsPageState extends State<ListAlarmsPage> {
  List<AlarmSettings> alarms = [];

  @override
  void initState() {
    super.initState();
    _loadAlarms();
  }

  Future<void> _loadAlarms() async {
    final updatedAlarms = await Alarm.getAlarms();
    updatedAlarms.sort((a, b) => a.dateTime.compareTo(b.dateTime));
    setState(() {
      alarms = updatedAlarms;
    });
  }

  Future<void> _deleteAlarm(AlarmSettings alarm) async {
    await Alarm.stop(alarm.id);
    _loadAlarms();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("Alarm berhasil dihapus")));
  }

  Future<void> navigateToAlarmScreen(
    AlarmSettings? settings, {
    String? namaLaporan,
  }) async {
    final res = await showModalBottomSheet<bool?>(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 0.85,
          child: ExampleAlarmEditScreen(
            alarmSettings: settings,
            namaLaporan: namaLaporan,
          ),
        );
      },
    );

    if (res != null && res == true) _loadAlarms();
  }

  Future<void> _editAlarm([AlarmSettings? alarm]) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ExampleAlarmEditScreen(alarmSettings: alarm),
      ),
    );

    if (result != null) {
      _loadAlarms();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Daftar Alarm')),
      body:
          alarms.isEmpty
              ? Center(child: Text('Tidak ada alarm yang terpasang'))
              : ListView.builder(
                itemCount: alarms.length,
                itemBuilder: (context, index) {
                  final alarm = alarms[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      vertical: 6,
                      horizontal: 12,
                    ),
                    child: ListTile(
                      title: Text(
                        alarm.notificationSettings?.title ??
                            "Alarm ${index + 1}",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        DateFormat("dd MMM yyyy, HH:mm").format(alarm.dateTime),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.edit, color: Colors.blueAccent),
                            onPressed:
                                () => navigateToAlarmScreen(
                                  alarms[index],
                                  namaLaporan:
                                      alarm.notificationSettings?.title,
                                ),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteAlarm(alarm),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
    );
  }
}
