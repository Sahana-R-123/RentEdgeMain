import 'package:flutter/material.dart';

class ReportIssueScreen extends StatefulWidget {
  @override
  _ReportIssueScreenState createState() => _ReportIssueScreenState();
}

class _ReportIssueScreenState extends State<ReportIssueScreen> {
  final TextEditingController _issueController = TextEditingController();

  void _submitReport(BuildContext context) {
    if (_issueController.text.isNotEmpty) {
      // Display a confirmation message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Report has been issued')),
      );

      // Navigate back to Profile Screen
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report an Issue'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Describe your issue:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _issueController,
              maxLines: 5,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Write your issue here...',
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: () => _submitReport(context),
                child: const Text('Send Report'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
