import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ReportIssueScreen extends StatefulWidget {
  @override
  _ReportIssueScreenState createState() => _ReportIssueScreenState();
}

class _ReportIssueScreenState extends State<ReportIssueScreen> {
  final TextEditingController _issueController = TextEditingController();
  bool _isSubmitting = false;

  Future<void> _submitReport(BuildContext context) async {
    if (_issueController.text.isEmpty) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Get reference to Firestore
      final firestore = FirebaseFirestore.instance;

      // Add a new document with the report
      await firestore.collection('reported_issues').add({
        'description': _issueController.text,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'new',
      });

      // Display success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Report has been submitted successfully')),
      );

      // Navigate back
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error submitting report: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
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
                onPressed: _isSubmitting ? null : () => _submitReport(context),
                child: _isSubmitting
                    ? const CircularProgressIndicator()
                    : const Text('Send Report'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}