import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

class ResourcesDocsScreen extends StatefulWidget {
  const ResourcesDocsScreen({super.key});

  @override
  State<ResourcesDocsScreen> createState() => _ResourcesDocsScreenState();
}

class _ResourcesDocsScreenState extends State<ResourcesDocsScreen>
    with TickerProviderStateMixin {
  String _selectedCategory = 'All';
  String _selectedSort = 'Newest';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;

  final List<String> _categories = [
    'All',
    'Invoices',
    'Contracts',
    'Design Files',
    'Brand Guidelines',
    'Templates',
    'Reports',
    'Certificates',
    'Other',
  ];

  final List<String> _sortOptions = [
    'Newest',
    'Oldest',
    'Name A-Z',
    'Name Z-A',
    'Category',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF8B0000),
        foregroundColor: Colors.white,
        title: const Text(
          'Resources & Docs',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showSearchDialog(),
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterDialog(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Stats and Filter Bar
          _buildStatsBar(),

          // Tab Bar
          Container(
            color: const Color(0xFF2A2A2A),
            child: TabBar(
              controller: _tabController,
              indicatorColor: const Color(0xFF8B0000),
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              tabs: const [
                Tab(text: 'My Documents'),
                Tab(text: 'Templates'),
              ],
            ),
          ),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [_buildDocumentsTab(), _buildTemplatesTab()],
            ),
          ),
        ],
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
              'Category: $_selectedCategory • Sort: $_selectedSort',
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('user_documents')
                .snapshots(),
            builder: (context, snapshot) {
              final allDocuments = snapshot.data?.docs ?? [];
              final currentUserId = FirebaseAuth.instance.currentUser?.uid;

              // Count user's documents
              final userDocuments = allDocuments.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                if (currentUserId == null) return false;
                String documentUserId = data['userId'] ?? '';
                return documentUserId == currentUserId;
              }).toList();

              final totalCount = userDocuments.length;
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
                  '$totalCount Documents',
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

  Widget _buildDocumentsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('user_documents')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _buildErrorState(snapshot.error.toString());
        }

        final allDocuments = snapshot.data?.docs ?? [];
        final currentUserId = FirebaseAuth.instance.currentUser?.uid;

        // Filter documents
        List<QueryDocumentSnapshot> filteredDocuments = allDocuments.where((
          doc,
        ) {
          final data = doc.data() as Map<String, dynamic>;

          // Apply user filter first
          if (currentUserId != null) {
            String documentUserId = data['userId'] ?? '';
            if (documentUserId != currentUserId) {
              return false;
            }
          }

          // Apply category filter
          if (_selectedCategory != 'All') {
            String documentCategory = data['category'] ?? 'Other';
            if (documentCategory != _selectedCategory) {
              return false;
            }
          }

          // Apply search filter
          if (_searchQuery.isNotEmpty) {
            String title = (data['title'] ?? '').toLowerCase();
            String description = (data['description'] ?? '').toLowerCase();
            String query = _searchQuery.toLowerCase();
            if (!title.contains(query) && !description.contains(query)) {
              return false;
            }
          }

          return true;
        }).toList();

        // Sort documents
        _sortDocuments(filteredDocuments);

        if (filteredDocuments.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: filteredDocuments.length,
          itemBuilder: (context, index) {
            final document = filteredDocuments[index];
            final documentData = document.data() as Map<String, dynamic>;
            return _buildDocumentCard(document.id, documentData);
          },
        );
      },
    );
  }

  Widget _buildTemplatesTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('templates')
          .orderBy('order', descending: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF8B0000)),
          );
        }

        if (snapshot.hasError) {
          return _buildErrorState(snapshot.error.toString());
        }

        final templates = snapshot.data?.docs ?? [];

        if (templates.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.file_copy, color: Colors.white54, size: 64),
                const SizedBox(height: 16),
                const Text(
                  'No Templates Available',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Templates will appear here when added by admin',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        // Group templates by category
        Map<String, List<QueryDocumentSnapshot>> groupedTemplates = {};
        for (var template in templates) {
          final data = template.data() as Map<String, dynamic>;
          final category = data['category'] ?? 'Other';
          if (!groupedTemplates.containsKey(category)) {
            groupedTemplates[category] = [];
          }
          groupedTemplates[category]!.add(template);
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: groupedTemplates.entries.map((entry) {
            final categoryName = entry.key;
            final categoryTemplates = entry.value;

            // Get category metadata from first template
            final firstTemplate =
                categoryTemplates.first.data() as Map<String, dynamic>;
            final categoryDescription =
                firstTemplate['categoryDescription'] ??
                'Professional templates for your projects';
            final categoryIcon = _getCategoryIcon(categoryName);
            final categoryColor = _getCategoryColor(categoryName);

            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildTemplateCategory(
                categoryName,
                categoryDescription,
                categoryIcon,
                categoryColor,
                categoryTemplates.map((template) {
                  final data = template.data() as Map<String, dynamic>;
                  return _buildTemplateItem(
                    data['name'] ?? 'Template',
                    data['description'] ?? 'No description',
                    data['format'] ?? 'FILE',
                    data['downloadUrl'],
                  );
                }).toList(),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Design Templates':
        return Icons.palette;
      case 'Marketing Templates':
        return Icons.campaign;
      case 'Document Templates':
        return Icons.description;
      default:
        return Icons.folder;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Design Templates':
        return const Color(0xFF8B0000);
      case 'Marketing Templates':
        return const Color(0xFF4CAF50);
      case 'Document Templates':
        return const Color(0xFF2196F3);
      default:
        return const Color(0xFF9E9E9E);
    }
  }

  Widget _buildTemplateCategory(
    String title,
    String description,
    IconData icon,
    Color color,
    List<Widget> templates,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...templates,
        ],
      ),
    );
  }

  Widget _buildTemplateItem(
    String name,
    String description,
    String format,
    String? downloadUrl,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF8B0000).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              format,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Color(0xFF8B0000),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                Text(
                  description,
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.download, color: Colors.white70),
            onPressed: downloadUrl != null && downloadUrl.isNotEmpty
                ? () => _downloadTemplate(name, downloadUrl)
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentCard(
    String documentId,
    Map<String, dynamic> documentData,
  ) {
    final title = documentData['title'] ?? 'Untitled Document';
    final description = documentData['description'] ?? '';
    final category = documentData['category'] ?? 'Other';
    final fileUrl = documentData['fileUrl'] ?? '';
    final fileSize = documentData['fileSize'] ?? '';
    final createdAt = documentData['createdAt'] as Timestamp?;
    final fileType = documentData['fileType'] ?? 'PDF';

    Color categoryColor;
    IconData categoryIcon;

    switch (category) {
      case 'Invoices':
        categoryColor = Colors.green;
        categoryIcon = Icons.receipt;
        break;
      case 'Contracts':
        categoryColor = Colors.blue;
        categoryIcon = Icons.description;
        break;
      case 'Design Files':
        categoryColor = Colors.purple;
        categoryIcon = Icons.palette;
        break;
      case 'Brand Guidelines':
        categoryColor = Colors.orange;
        categoryIcon = Icons.style;
        break;
      case 'Templates':
        categoryColor = Colors.teal;
        categoryIcon = Icons.dynamic_form;
        break;
      case 'Reports':
        categoryColor = Colors.indigo;
        categoryIcon = Icons.assessment;
        break;
      case 'Certificates':
        categoryColor = Colors.amber;
        categoryIcon = Icons.workspace_premium;
        break;
      default:
        categoryColor = Colors.grey;
        categoryIcon = Icons.insert_drive_file;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _viewDocument(documentId, documentData),
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
                      color: categoryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: categoryColor.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(categoryIcon, size: 14, color: categoryColor),
                        const SizedBox(width: 4),
                        Text(
                          category,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: categoryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  // File Type Badge
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
                      fileType,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF8B0000),
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
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),

              // Description
              if (description.isNotEmpty) ...[
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Footer Row
              Row(
                children: [
                  // File Size
                  Icon(Icons.storage, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    fileSize.isNotEmpty ? fileSize : 'Unknown size',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const Spacer(),
                  // Date
                  Icon(Icons.schedule, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    createdAt != null
                        ? _formatDate(createdAt.toDate())
                        : 'Unknown date',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(width: 16),
                  // Download Button
                  IconButton(
                    icon: const Icon(Icons.download, color: Color(0xFF8B0000)),
                    onPressed: () => _downloadDocument(fileUrl, title),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_open, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            'No documents found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your documents will appear here once they are shared with you',
            style: TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'Error Loading Documents',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
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

  void _sortDocuments(List<QueryDocumentSnapshot> documents) {
    switch (_selectedSort) {
      case 'Oldest':
        documents.sort((a, b) {
          final aDate =
              (a.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
          final bDate =
              (b.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
          if (aDate == null || bDate == null) return 0;
          return aDate.compareTo(bDate);
        });
        break;
      case 'Name A-Z':
        documents.sort((a, b) {
          final aTitle = (a.data() as Map<String, dynamic>)['title'] ?? '';
          final bTitle = (b.data() as Map<String, dynamic>)['title'] ?? '';
          return (aTitle as String).compareTo(bTitle as String);
        });
        break;
      case 'Name Z-A':
        documents.sort((a, b) {
          final aTitle = (a.data() as Map<String, dynamic>)['title'] ?? '';
          final bTitle = (b.data() as Map<String, dynamic>)['title'] ?? '';
          return (bTitle as String).compareTo(aTitle as String);
        });
        break;
      case 'Category':
        documents.sort((a, b) {
          final aCategory =
              (a.data() as Map<String, dynamic>)['category'] ?? '';
          final bCategory =
              (b.data() as Map<String, dynamic>)['category'] ?? '';
          return (aCategory as String).compareTo(bCategory as String);
        });
        break;
      default: // Newest (already sorted by the query)
        break;
    }
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

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: const Text(
          'Search Documents',
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: _searchController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Enter search terms...',
            hintStyle: TextStyle(color: Colors.white54),
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _searchQuery = _searchController.text;
              });
              Navigator.of(context).pop();
            },
            child: const Text('Search'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _searchQuery = '';
                _searchController.clear();
              });
              Navigator.of(context).pop();
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: const Text(
          'Filter & Sort',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Category Filter
            const Text(
              'Category',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _selectedCategory,
              dropdownColor: const Color(0xFF2A2A2A),
              style: const TextStyle(color: Colors.white),
              items: _categories.map((category) {
                return DropdownMenuItem<String>(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value ?? 'All';
                });
              },
            ),
            const SizedBox(height: 16),
            // Sort Options
            const Text(
              'Sort By',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _selectedSort,
              dropdownColor: const Color(0xFF2A2A2A),
              style: const TextStyle(color: Colors.white),
              items: _sortOptions.map((sort) {
                return DropdownMenuItem<String>(value: sort, child: Text(sort));
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedSort = value ?? 'Newest';
                });
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _viewDocument(String documentId, Map<String, dynamic> documentData) {
    final fileUrl = documentData['fileUrl'] ?? '';
    if (fileUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Document URL not available'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: Text(
          documentData['title'] ?? 'Document',
          style: const TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              documentData['description'] ?? 'No description available',
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _downloadDocument(
                      fileUrl,
                      documentData['title'] ?? 'Document',
                    ),
                    icon: const Icon(Icons.download),
                    label: const Text('Download'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B0000),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _openDocument(fileUrl),
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('Open'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _downloadDocument(String fileUrl, String fileName) async {
    try {
      final uri = Uri.parse(fileUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Downloading $fileName...'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception('Could not launch URL');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error downloading document: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _openDocument(String fileUrl) async {
    try {
      final uri = Uri.parse(fileUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw Exception('Could not launch URL');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error opening document: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _downloadTemplate(
    String templateName,
    String downloadUrl,
  ) async {
    try {
      // Show downloading message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Downloading $templateName...'),
          backgroundColor: const Color(0xFF8B0000),
          duration: const Duration(seconds: 2),
        ),
      );

      // Open the download URL in browser/external app
      final uri = Uri.parse(downloadUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Opening $templateName...'),
              backgroundColor: const Color(0xFF4CAF50),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        throw Exception('Could not open download link');
      }
    } catch (e) {
// print('Error downloading template: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error downloading: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
