import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'incoming_requests_tab.dart';
import 'sent_requests_tab.dart';

class RequestsScreen extends StatefulWidget {
  const RequestsScreen({super.key});

  @override
  _RequestsScreenState createState() => _RequestsScreenState();
}

class _RequestsScreenState extends State<RequestsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = _auth.currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Requests'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Incoming'),
            Tab(text: 'Sent'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          IncomingRequestsTab(currentUserId: currentUserId),
          SentRequestsTab(currentUserId: currentUserId),
        ],
      ),
    );
  }
}