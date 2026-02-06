import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/notification_service.dart';

class AdminSuggestionsScreen extends StatefulWidget {
  const AdminSuggestionsScreen({super.key});

  @override
  State<AdminSuggestionsScreen> createState() => _AdminSuggestionsScreenState();
}

class _AdminSuggestionsScreenState extends State<AdminSuggestionsScreen> {
  final String _selectedFilter = 'All';
  final String _selectedSort = 'Newest';

  final List<String> _filterOptions = [
    'All',
    'Pending',
    'In Review',
    'Approved',
    'Rejected',
    'Implemented',
  ];

  final List<String> _sortOptions = [
    'Newest',
    'Oldest',
    'Most Voted',
    'Category',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF8B0000),
        foregroundColor: Colors.white,
        title: const Text(
          'User Suggestions',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _getSuggestionsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8B0000)),
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Error Loading Suggestions',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${snapshot.error}',
                      style: const TextStyle(fontSize: 14, color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          // Trigger rebuild to retry
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8B0000),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          final allSuggestions = snapshot.data?.docs ?? [];

          if (allSuggestions.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: allSuggestions.length,
            itemBuilder: (context, index) {
              final suggestion = allSuggestions[index];
              final suggestionData = suggestion.data() as Map<String, dynamic>;
              return _buildSimpleSuggestionCard(suggestion.id, suggestionData);
            },
          );
        },
      ),
    );
  }

  Widget _buildStatsBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        border: Border(bottom: BorderSide(color: Colors.white10)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Filter: $_selectedFilter • Sort: $_selectedSort',
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('suggestions')
                .snapshots(),
            builder: (context, snapshot) {
              final allSuggestions = snapshot.data?.docs ?? [];

              // Count filtered suggestions
              final filteredCount = allSuggestions.where((doc) {
                final data = doc.data() as Map<String, dynamic>;

                // Apply status filter
                if (_selectedFilter != 'All') {
                  String expectedStatus = _selectedFilter
                      .toLowerCase()
                      .replaceAll(' ', '_');
                  String actualStatus = data['status'] ?? 'pending';
                  if (actualStatus != expectedStatus) {
                    return false;
                  }
                }

                return true;
              }).length;

              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B0000),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '$filteredCount ${_selectedFilter == 'All' ? 'Total' : _selectedFilter}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lightbulb_outline, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            'No suggestions found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'User suggestions will appear here once submitted',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleSuggestionCard(
    String suggestionId,
    Map<String, dynamic> suggestionData,
  ) {
    final title = suggestionData['title'] ?? 'Untitled';
    final description = suggestionData['description'] ?? '';
    final category = suggestionData['category'] ?? 'Other';
    final status = suggestionData['status'] ?? 'pending';
    final createdAt = suggestionData['createdAt'] as Timestamp?;
    final userEmail = suggestionData['userEmail'] ?? 'Unknown User';
    final userId = suggestionData['userId'] ?? '';

    Color statusColor;
    String statusText;

    switch (status) {
      case 'pending':
        statusColor = Colors.orange;
        statusText = 'Pending';
        break;
      case 'in_review':
        statusColor = Colors.blue;
        statusText = 'In Review';
        break;
      case 'approved':
        statusColor = Colors.green;
        statusText = 'Approved';
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusText = 'Rejected';
        break;
      case 'implemented':
        statusColor = Colors.purple;
        statusText = 'Implemented';
        break;
      default:
        statusColor = Colors.grey;
        statusText = status.toUpperCase();
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      color: const Color(0xFF2A2A2A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showSuggestionDetailsDialog(suggestionId, suggestionData),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  // Category Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B0000).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      category,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF8B0000),
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Title
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),

              // Description Preview
              Text(
                description.length > 120
                    ? '${description.substring(0, 120)}...'
                    : description,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 12),

              // Footer Row
              Row(
                children: [
                  // User Email
                  const Icon(Icons.person, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      userEmail,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Date
                  const Icon(Icons.schedule, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    createdAt != null
                        ? _formatDate(createdAt.toDate())
                        : 'Unknown',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestionCard(
    String suggestionId,
    Map<String, dynamic> suggestionData,
  ) {
    final title = suggestionData['title'] ?? 'Untitled';
    final description = suggestionData['description'] ?? '';
    final category = suggestionData['category'] ?? 'Other';
    final status = suggestionData['status'] ?? 'pending';
    final votes = suggestionData['votes'] ?? 0;
    final createdAt = suggestionData['createdAt'] as Timestamp?;
    final userEmail = suggestionData['userEmail'] ?? 'Unknown User';

    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (status) {
      case 'pending':
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
        statusText = 'Pending';
        break;
      case 'in_review':
        statusColor = Colors.blue;
        statusIcon = Icons.visibility;
        statusText = 'In Review';
        break;
      case 'approved':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusText = 'Approved';
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        statusText = 'Rejected';
        break;
      case 'implemented':
        statusColor = Colors.purple;
        statusIcon = Icons.build;
        statusText = 'Implemented';
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help;
        statusText = status.toUpperCase();
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showSuggestionDetailsDialog(suggestionId, suggestionData),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  // Category Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B0000).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF8B0000).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      category,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF8B0000),
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: statusColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 14, color: statusColor),
                        const SizedBox(width: 4),
                        Text(
                          statusText,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Title
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),

              // Description Preview
              Text(
                description.length > 100
                    ? '${description.substring(0, 100)}...'
                    : description,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 12),

              // Footer Row
              Row(
                children: [
                  // User Email
                  Icon(Icons.person, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    userEmail,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const Spacer(),
                  // Votes
                  Icon(Icons.thumb_up, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    '$votes',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(width: 16),
                  // Date
                  Icon(Icons.schedule, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    createdAt != null
                        ? _formatDate(createdAt.toDate())
                        : 'Unknown',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSuggestionDetailsDialog(
    String suggestionId,
    Map<String, dynamic> suggestionData,
  ) async {
    final title = suggestionData['title'] ?? 'Untitled';
    final description = suggestionData['description'] ?? '';
    final category = suggestionData['category'] ?? 'Other';
    final status = suggestionData['status'] ?? 'pending';
    final votes = suggestionData['votes'] ?? 0;
    final createdAt = suggestionData['createdAt'] as Timestamp?;
    final userEmail = suggestionData['userEmail'] ?? 'Unknown User';
    final userId = suggestionData['userId'] ?? '';

    // Send notification to user when admin opens suggestion
    if (userId.isNotEmpty) {
      await _sendSuggestionViewedNotification(userId, title);
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxHeight: 600),
            decoration: BoxDecoration(
              color: const Color(0xFF2A2A2A),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: Color(0xFF8B0000),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.lightbulb_outline,
                        color: Colors.white,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Suggestion Details',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'ID: $suggestionId',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close, color: Colors.white),
                      ),
                    ],
                  ),
                ),

                // Content
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDetailRow('Title', title),
                        _buildDetailRow('Category', category),
                        _buildDetailRow('Status', status.toUpperCase()),
                        _buildDetailRow('Submitted by', userEmail),
                        _buildDetailRow('Votes', votes.toString()),
                        _buildDetailRow(
                          'Date',
                          createdAt != null
                              ? _formatDate(createdAt.toDate())
                              : 'Unknown',
                        ),
                        _buildDetailRow(
                          'Description',
                          description,
                          isDescription: true,
                        ),
                      ],
                    ),
                  ),
                ),

                // Action Buttons
                Container(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.grey),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Close'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () =>
                              _updateSuggestionStatus(suggestionId, status),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF8B0000),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Update Status'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(
    String label,
    String value, {
    bool isDescription = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF8B0000),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade800,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              value,
              style: TextStyle(
                fontSize: isDescription ? 14 : 16,
                color: Colors.white,
                height: isDescription ? 1.4 : 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Stream<QuerySnapshot> _getSuggestionsStream() {
    // Use a simple query without composite indexes
    // We'll handle filtering and sorting in the client-side code
    return FirebaseFirestore.instance
        .collection('suggestions')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  void _updateSuggestionStatus(String suggestionId, String currentStatus) {
    Navigator.of(context).pop(); // Close details dialog first

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2A2A2A),
          title: const Text(
            'Update Status',
            style: TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Select new status for this suggestion:',
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 16),
              ...[
                'pending',
                'in_review',
                'approved',
                'rejected',
                'implemented',
              ].map(
                (status) => ListTile(
                  title: Text(
                    status.replaceAll('_', ' ').toUpperCase(),
                    style: const TextStyle(color: Colors.white),
                  ),
                  selected: status == currentStatus,
                  onTap: () async {
                    Navigator.of(context).pop();
                    await _changeSuggestionStatus(suggestionId, status);
                  },
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _changeSuggestionStatus(
    String suggestionId,
    String newStatus,
  ) async {
    try {
      await FirebaseFirestore.instance
          .collection('suggestions')
          .doc(suggestionId)
          .update({
            'status': newStatus,
            'updatedAt': FieldValue.serverTimestamp(),
          });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Status updated to ${newStatus.replaceAll('_', ' ').toUpperCase()}',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update status: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _sendSuggestionViewedNotification(
    String userId,
    String suggestionTitle,
  ) async {
    try {
      // Send push notification to user
      await NotificationService.sendNotificationToUser(
        userId: userId,
        title: 'Suggestion Viewed by Development Team',
        body:
            'Thank you for your suggestion "$suggestionTitle". Our development team has reviewed it and is looking into it. We appreciate your feedback!',
        type: 'suggestion_viewed',
        data: {'suggestion_title': suggestionTitle},
      );

      // Also save notification to Firestore for in-app notifications
      await FirebaseFirestore.instance.collection('notifications').add({
        'userId': userId,
        'title': 'Suggestion Viewed by Development Team',
        'body':
            'Thank you for your suggestion "$suggestionTitle". Our development team has reviewed it and is looking into it. We appreciate your feedback!',
        'type': 'suggestion_viewed',
        'data': {'suggestion_title': suggestionTitle},
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      print('✅ Suggestion viewed notification sent to user: $userId');
    } catch (e) {
      print('❌ Failed to send suggestion viewed notification: $e');
    }
  }
}
