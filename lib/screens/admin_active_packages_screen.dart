import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'admin_package_detail_screen.dart';

/// Admin Active Packages Screen
/// Displays all active package subscriptions for admin management
class AdminActivePackagesScreen extends StatefulWidget {
  const AdminActivePackagesScreen({super.key});

  @override
  State<AdminActivePackagesScreen> createState() =>
      _AdminActivePackagesScreenState();
}

class _AdminActivePackagesScreenState extends State<AdminActivePackagesScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _selectedFilter = 'all';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF8B0000),
        foregroundColor: Colors.white,
        title: const Text('Active Packages'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {});
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFF2A2A2A),
            child: Column(
              children: [
                // Search Bar
                TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search packages by client name or email...',
                    hintStyle: const TextStyle(color: Colors.grey),
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.grey),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: const Color(0xFF3A3A3A),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.toLowerCase();
                    });
                  },
                ),
                const SizedBox(height: 12),
                // Filter Buttons
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('all', 'All Packages'),
                      const SizedBox(width: 8),
                      _buildFilterChip('active', 'Active'),
                      const SizedBox(width: 8),
                      _buildFilterChip('paused', 'Paused'),
                      const SizedBox(width: 8),
                      _buildFilterChip('cancelled', 'Cancelled'),
                      const SizedBox(width: 8),
                      _buildFilterChip('expired', 'Expired'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Packages List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _getPackagesStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFF8B0000)),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 64,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error loading packages: ${snapshot.error}',
                          style: const TextStyle(color: Colors.white),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {});
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          color: Colors.grey,
                          size: 64,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No packages found',
                          style: TextStyle(color: Colors.grey, fontSize: 18),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Package subscriptions will appear here when clients subscribe',
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                final packages = snapshot.data!.docs
                    .map(
                      (doc) => {
                        'id': doc.id,
                        ...doc.data() as Map<String, dynamic>,
                      },
                    )
                    .toList();

                // Apply search filter
                final filteredPackages = packages.where((package) {
                  if (_searchQuery.isEmpty) return true;

                  final clientName = (package['clientName'] ?? '')
                      .toString()
                      .toLowerCase();
                  final clientEmail = (package['clientEmail'] ?? '')
                      .toString()
                      .toLowerCase();
                  final packageName = (package['packageName'] ?? '')
                      .toString()
                      .toLowerCase();

                  return clientName.contains(_searchQuery) ||
                      clientEmail.contains(_searchQuery) ||
                      packageName.contains(_searchQuery);
                }).toList();

                // Apply status filter
                final statusFilteredPackages = filteredPackages.where((
                  package,
                ) {
                  if (_selectedFilter == 'all') return true;
                  return package['status'] == _selectedFilter;
                }).toList();

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: statusFilteredPackages.length,
                  itemBuilder: (context, index) {
                    final package = statusFilteredPackages[index];
                    return _buildPackageCard(package);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = value;
        });
      },
      selectedColor: const Color(0xFF8B0000),
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.grey,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      backgroundColor: const Color(0xFF3A3A3A),
    );
  }

  Widget _buildPackageCard(Map<String, dynamic> package) {
    final packageId = package['id'] as String;
    final clientName = package['clientName'] ?? 'Unknown Client';
    final clientEmail = package['clientEmail'] ?? '';
    final packageName = package['packageName'] ?? 'Unknown Package';
    final packagePrice = (package['packagePrice'] ?? 0.0).toDouble();
    final status = package['status'] ?? 'active';
    final nextBillingDate = (package['nextBillingDate'] as Timestamp?)
        ?.toDate();
    final createdAt = (package['createdAt'] as Timestamp?)?.toDate();
    final billingCycle = package['billingCycle'] ?? 'monthly';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: const Color(0xFF2A2A2A),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => AdminPackageDetailScreen(
                packageId: packageId,
                packageData: package,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          clientName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          clientEmail,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusChip(status),
                ],
              ),
              const SizedBox(height: 12),
              // Package Details
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Package',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          packageName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Price',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                        Text(
                          'R${packagePrice.toStringAsFixed(2)}/$billingCycle',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Dates Row
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Created',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                        Text(
                          createdAt != null
                              ? DateFormat('MMM dd, yyyy').format(createdAt)
                              : 'Unknown',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Next Billing',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                        Text(
                          nextBillingDate != null
                              ? DateFormat(
                                  'MMM dd, yyyy',
                                ).format(nextBillingDate)
                              : 'Unknown',
                          style: TextStyle(
                            color:
                                nextBillingDate != null &&
                                    nextBillingDate.isBefore(
                                      DateTime.now().add(
                                        const Duration(days: 7),
                                      ),
                                    )
                                ? Colors.orange
                                : Colors.white,
                            fontSize: 14,
                            fontWeight:
                                nextBillingDate != null &&
                                    nextBillingDate.isBefore(
                                      DateTime.now().add(
                                        const Duration(days: 7),
                                      ),
                                    )
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'active':
        color = Colors.green;
        break;
      case 'paused':
        color = Colors.orange;
        break;
      case 'cancelled':
        color = Colors.red;
        break;
      case 'expired':
        color = Colors.grey;
        break;
      default:
        color = Colors.blue;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Stream<QuerySnapshot> _getPackagesStream() {
    Query query = _firestore
        .collection('package_subscriptions')
        .orderBy('createdAt', descending: true);

    // Apply status filter if not 'all'
    if (_selectedFilter != 'all') {
      query = query.where('status', isEqualTo: _selectedFilter);
    }

    return query.snapshots();
  }
}


