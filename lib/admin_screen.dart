import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminDashboard extends StatefulWidget {
  @override
  _AdminDashboardState createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  List<PieChartSectionData> _pieChartData = [];
  List<Map<String, dynamic>> _reports = [];

  @override
  void initState() {
    super.initState();
    _fetchReportsFromFirestore();
  }

  Future<void> _fetchReportsFromFirestore() async {
    final reportsSnapshot = await FirebaseFirestore.instance
        .collection('disaster_reports')
        .orderBy('reportDate', descending: true)
        .get();

    setState(() {
      _reports = reportsSnapshot.docs.map((doc) => doc.data()).toList();
      _generateSeverityChartData();
    });
  }

  void _generateSeverityChartData() {
    Map<String, int> severityCount = {'Low': 0, 'Medium': 0, 'High': 0, 'Critical': 0};

    for (var report in _reports) {
      String severity = report['severity'];
      if (severityCount.containsKey(severity)) {
        severityCount[severity] = severityCount[severity]! + 1;
      }
    }

    setState(() {
      _pieChartData = _buildPieChartData(severityCount);
    });
  }

  List<PieChartSectionData> _buildPieChartData(Map<String, int> severityCount) {
    return severityCount.entries.map((entry) {
      final severity = entry.key;
      final count = entry.value;
      final color = _getSeverityColor(severity);

      return PieChartSectionData(
        value: count.toDouble(),
        color: color,
        title: '$severity: $count',
        radius: 50,
        titleStyle: const TextStyle(color: Colors.white, fontSize: 12),
      );
    }).toList();
  }

  Color _getSeverityColor(String severity) {
    switch (severity) {
      case 'Low':
        return Colors.green;
      case 'Medium':
        return Colors.yellow;
      case 'High':
        return Colors.orange;
      case 'Critical':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Future<void> _takeActionOnReport(String reportId, String action) async {
    await FirebaseFirestore.instance
        .collection('disaster_reports')
        .doc(reportId)
        .update({'adminAction': action});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Action "$action" taken on report $reportId')),
    );
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacementNamed(context, '/login');  // Replace with your login screen route
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: Colors.redAccent,
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recent Reports',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 10),
            _buildRecentReports(),
            const SizedBox(height: 20),
            const Text(
              'Severity Chart',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 10),
            _buildSeverityChart(),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentReports() {
    return _reports.isEmpty
        ? const Center(child: CircularProgressIndicator())
        : Column(
      children: _reports.map((report) {
        return Card(
          color: const Color(0xFF2C5364),
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: ListTile(
            title: Text(
              '${report['disasterType']} at ${report['location']}',
              style: const TextStyle(color: Colors.white),
            ),
            subtitle: Text(
              'Reported by ${report['userName']} (${report['userEmail']})\nSeverity: ${report['severity']}',
              style: const TextStyle(color: Colors.white70),
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (action) {
                _takeActionOnReport(report['id'], action);
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'Send Alert',
                  child: Text('Send Alert'),
                ),
                const PopupMenuItem(
                  value: 'Dispatch Team',
                  child: Text('Dispatch Team'),
                ),
                const PopupMenuItem(
                  value: 'Mark as Resolved',
                  child: Text('Mark as Resolved'),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSeverityChart() {
    return Container(
      height: 300,
      child: PieChart(
        PieChartData(
          sections: _pieChartData,
          sectionsSpace: 0,
          centerSpaceRadius: 40,
          borderData: FlBorderData(show: false),
        ),
        swapAnimationDuration: const Duration(milliseconds: 500),
      ),
    );
  }
}

class SeverityData {
  final String severity;
  final int count;

  SeverityData(this.severity, this.count);
}
