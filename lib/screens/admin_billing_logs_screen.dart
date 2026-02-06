import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Admin Billing Logs Screen
/// Displays automated billing logs and statistics for admin review
class AdminBillingLogsScreen extends StatefulWidget {
  const AdminBillingLogsScreen({super.key});

  @override
  State<AdminBillingLogsScreen> createState() => _AdminBillingLogsScreenState();
}

class _AdminBillingLogsScreenState extends State<AdminBillingLogsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF8B0000),
        foregroundColor: Colors.white,
        title: const Text(
          'Billing Logs',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              setState(() {});
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Summary Cards
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    'Total Runs',
                    '📊',
                    Colors.blue,
                    _getTotalRuns(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryCard(
                    'Successful',
                    '✅',
                    Colors.green,
                    _getSuccessfulRuns(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryCard(
                    'Failed',
                    '❌',
                    Colors.red,
                    _getFailedRuns(),
                  ),
                ),
              ],
            ),
          ),

          // Billing Logs List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('billing_logs')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFF8B0000)),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error: ${snapshot.error}',
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                }

                final logs = snapshot.data?.docs ?? [];

                if (logs.isEmpty) {
                  return const Center(
                    child: Text(
                      'No billing logs found.',
                      style: TextStyle(color: Colors.white70),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: logs.length,
                  itemBuilder: (context, index) {
                    final logDoc = logs[index];
                    final logData = logDoc.data() as Map<String, dynamic>;
                    return _buildLogCard(logDoc.id, logData);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    String title,
    String icon,
    Color color,
    Future<int> countFuture,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withOpacity(0.2), color.withOpacity(0.1)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(icon, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          FutureBuilder<int>(
            future: countFuture,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return Text(
                  '${snapshot.data}',
                  style: TextStyle(
                    color: color,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                );
              }
              return const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white54,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLogCard(String logId, Map<String, dynamic> data) {
    final date = (data['date'] ?? '').toString();
    final timestamp = (data['timestamp'] as Timestamp?)?.toDate();
    final totalPackages = data['totalPackages'] ?? 0;
    final successful = data['successful'] ?? 0;
    final failed = data['failed'] ?? 0;
    final isSuccess = data['success'] ?? false;
    final error = data['error']?.toString();

    Color statusColor;
    IconData statusIcon;
    String statusText;

    if (isSuccess) {
      if (failed == 0) {
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusText = 'All Successful';
      } else {
        statusColor = Colors.orange;
        statusIcon = Icons.warning;
        statusText = 'Partial Success';
      }
    } else {
      statusColor = Colors.red;
      statusIcon = Icons.error;
      statusText = 'Failed';
    }

    return GestureDetector(
      onTap: () => _showLogDetails(logId, data),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2A2A2A), Color(0xFF1A1A1A)],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: statusColor.withOpacity(0.3), width: 2),
          boxShadow: [
            BoxShadow(
              color: statusColor.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Billing Run - $date',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: statusColor.withOpacity(0.5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 16, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        statusText,
                        style: TextStyle(color: statusColor, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(color: Colors.white10, height: 1),
            const SizedBox(height: 12),
            _buildInfoRow(
              'Time:',
              timestamp != null
                  ? DateFormat('MMM dd, yyyy - HH:mm:ss').format(timestamp)
                  : 'N/A',
            ),
            _buildInfoRow('Total Packages:', '$totalPackages'),
            _buildInfoRow(
              'Successful:',
              '$successful',
              valueColor: Colors.green,
            ),
            _buildInfoRow(
              'Failed:',
              '$failed',
              valueColor: failed > 0 ? Colors.red : Colors.white54,
            ),
            if (error != null && error.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Text(
                  'Error: $error',
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF8B0000).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFF8B0000).withOpacity(0.3),
                ),
              ),
              child: const Text(
                'Tap to view details',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF8B0000),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: valueColor ?? Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  void _showLogDetails(String logId, Map<String, dynamic> data) {
    final results = data['results'] as List<dynamic>? ?? [];

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF2A2A2A),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.8,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Billing Log Details - ${data['date']}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(color: Colors.white10),
              const SizedBox(height: 16),

              // Summary
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    _buildDetailRow(
                      'Total Packages:',
                      '${data['totalPackages'] ?? 0}',
                    ),
                    _buildDetailRow(
                      'Successful:',
                      '${data['successful'] ?? 0}',
                      Colors.green,
                    ),
                    _buildDetailRow(
                      'Failed:',
                      '${data['failed'] ?? 0}',
                      Colors.red,
                    ),
                    _buildDetailRow(
                      'Success Rate:',
                      '${((data['successful'] ?? 0) / (data['totalPackages'] ?? 1) * 100).toStringAsFixed(1)}%',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
              const Text(
                'Package Results:',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              // Results List
              Expanded(
                child: results.isEmpty
                    ? const Center(
                        child: Text(
                          'No package results available.',
                          style: TextStyle(color: Colors.white70),
                        ),
                      )
                    : ListView.builder(
                        itemCount: results.length,
                        itemBuilder: (context, index) {
                          final result = results[index] as Map<String, dynamic>;
                          return _buildResultItem(result);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, [Color? valueColor]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultItem(Map<String, dynamic> result) {
    final success = result['success'] ?? false;
    final clientName = result['clientName'] ?? 'Unknown';
    final clientEmail = result['clientEmail'] ?? 'Unknown';
    final packageId = result['packageId'] ?? 'Unknown';
    final error = result['error']?.toString();
    final nextBillingDate = result['nextBillingDate']?.toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: success
            ? Colors.green.withOpacity(0.1)
            : Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: success
              ? Colors.green.withOpacity(0.3)
              : Colors.red.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                success ? Icons.check_circle : Icons.error,
                color: success ? Colors.green : Colors.red,
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  clientName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            clientEmail,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          Text(
            'Package ID: $packageId',
            style: const TextStyle(color: Colors.white54, fontSize: 11),
          ),
          if (nextBillingDate != null)
            Text(
              'Next Billing: $nextBillingDate',
              style: const TextStyle(color: Colors.green, fontSize: 11),
            ),
          if (error != null && error.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Error: $error',
                style: const TextStyle(color: Colors.red, fontSize: 11),
              ),
            ),
        ],
      ),
    );
  }

  Future<int> _getTotalRuns() async {
    final snapshot = await _firestore.collection('billing_logs').get();
    return snapshot.docs.length;
  }

  Future<int> _getSuccessfulRuns() async {
    final snapshot = await _firestore
        .collection('billing_logs')
        .where('success', isEqualTo: true)
        .get();
    return snapshot.docs.length;
  }

  Future<int> _getFailedRuns() async {
    final snapshot = await _firestore
        .collection('billing_logs')
        .where('success', isEqualTo: false)
        .get();
    return snapshot.docs.length;
  }
}



