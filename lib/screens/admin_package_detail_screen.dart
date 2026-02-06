import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Admin Package Detail Screen
/// Allows admin to manage individual package subscriptions
class AdminPackageDetailScreen extends StatefulWidget {
  final String packageId;
  final Map<String, dynamic> packageData;

  const AdminPackageDetailScreen({
    super.key,
    required this.packageId,
    required this.packageData,
  });

  @override
  State<AdminPackageDetailScreen> createState() =>
      _AdminPackageDetailScreenState();
}

class _AdminPackageDetailScreenState extends State<AdminPackageDetailScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final clientName = widget.packageData['clientName'] ?? 'Unknown Client';
    final clientEmail = widget.packageData['clientEmail'] ?? '';
    final packageName = widget.packageData['packageName'] ?? 'Unknown Package';
    final packagePrice = widget.packageData['packagePrice'] ?? 0.0;
    final status = widget.packageData['status'] ?? 'active';
    final nextBillingDate =
        (widget.packageData['nextBillingDate'] as Timestamp?)?.toDate();
    final createdAt = (widget.packageData['createdAt'] as Timestamp?)?.toDate();
    final lastPaymentDate =
        (widget.packageData['lastPaymentDate'] as Timestamp?)?.toDate();
    final billingCycle = widget.packageData['billingCycle'] ?? 'monthly';
    final notes = widget.packageData['notes'] ?? '';
    final userId = widget.packageData['userId'];

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF8B0000),
        foregroundColor: Colors.white,
        title: const Text(
          'Package Details',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.email),
            tooltip: 'Send Invoice',
            onPressed: () => _sendInvoiceEmail(),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Cancel Subscription',
            onPressed: () => _confirmCancelSubscription(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF8B0000)),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Client Info Card
                  _buildSectionCard(
                    title: 'Client Information',
                    icon: Icons.person,
                    children: [
                      _buildDetailRow('Name', clientName),
                      if (clientEmail.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _buildDetailRow('Email', clientEmail),
                      ],
                      if (userId != null) ...[
                        const SizedBox(height: 12),
                        _buildDetailRow('User ID', userId),
                      ],
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Package Info Card
                  _buildSectionCard(
                    title: 'Package Information',
                    icon: Icons.card_giftcard,
                    children: [
                      _buildDetailRow('Package Name', packageName),
                      const SizedBox(height: 12),
                      _buildDetailRow(
                        'Price',
                        'R ${packagePrice.toStringAsFixed(2)}',
                      ),
                      const SizedBox(height: 12),
                      _buildDetailRow(
                        'Billing Cycle',
                        billingCycle.toUpperCase(),
                      ),
                      const SizedBox(height: 12),
                      _buildDetailRow(
                        'Status',
                        status.toUpperCase(),
                        valueColor: status == 'active'
                            ? Colors.green
                            : status == 'expired'
                            ? Colors.red
                            : Colors.orange,
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Billing Info Card
                  _buildSectionCard(
                    title: 'Billing Information',
                    icon: Icons.calendar_today,
                    children: [
                      if (createdAt != null) ...[
                        _buildDetailRow(
                          'Created Date',
                          DateFormat('MMM dd, yyyy HH:mm').format(createdAt),
                        ),
                        const SizedBox(height: 12),
                      ],
                      if (lastPaymentDate != null) ...[
                        _buildDetailRow(
                          'Last Payment',
                          DateFormat('MMM dd, yyyy').format(lastPaymentDate),
                        ),
                        const SizedBox(height: 12),
                      ],
                      if (nextBillingDate != null) ...[
                        _buildDetailRow(
                          'Next Billing Date',
                          DateFormat(
                            'MMM dd, yyyy HH:mm',
                          ).format(nextBillingDate),
                          valueColor: _getNextBillingColor(nextBillingDate),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                _getNextBillingMessage(nextBillingDate),
                                style: TextStyle(
                                  color: _getNextBillingColor(nextBillingDate),
                                  fontSize: 12,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),

                  if (notes.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    _buildSectionCard(
                      title: 'Notes',
                      icon: Icons.note,
                      children: [
                        Text(
                          notes,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Action Buttons
                  Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _updateNextBillingDate(),
                          icon: const Icon(Icons.edit_calendar),
                          label: const Text('Update Billing Date & Time'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _updatePackagePrice(),
                          icon: const Icon(Icons.attach_money),
                          label: const Text('Update Package Price'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _addNotes(),
                          icon: const Icon(Icons.note_add),
                          label: const Text('Add/Update Notes'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: status == 'active'
                              ? () => _pauseSubscription()
                              : () => _activateSubscription(),
                          icon: Icon(
                            status == 'active' ? Icons.pause : Icons.play_arrow,
                          ),
                          label: Text(
                            status == 'active'
                                ? 'Pause Subscription'
                                : 'Activate Subscription',
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white70,
                            side: const BorderSide(color: Colors.white30),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2A2A2A), Color(0xFF1A1A1A)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF8B0000), size: 24),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.white10, height: 1),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 140,
          child: Text(
            label,
            style: const TextStyle(color: Colors.white54, fontSize: 14),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: valueColor ?? Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Color _getNextBillingColor(DateTime nextBillingDate) {
    final daysUntil = nextBillingDate.difference(DateTime.now()).inDays;
    if (daysUntil < 0) return Colors.red;
    if (daysUntil <= 7) return Colors.orange;
    return Colors.green;
  }

  String _getNextBillingMessage(DateTime nextBillingDate) {
    final daysUntil = nextBillingDate.difference(DateTime.now()).inDays;
    if (daysUntil < 0) {
      return '${daysUntil.abs()} days overdue - Action required!';
    } else if (daysUntil == 0) {
      return 'Due today - Send invoice reminder';
    } else if (daysUntil <= 7) {
      return 'Due in $daysUntil days - Consider sending reminder';
    } else {
      return 'Next payment in $daysUntil days';
    }
  }

  Future<void> _updateNextBillingDate() async {
    final currentDateTime =
        (widget.packageData['nextBillingDate'] as Timestamp?)?.toDate() ??
        DateTime.now();

    // First, show date picker
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: currentDateTime,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF8B0000),
              surface: Color(0xFF2A2A2A),
            ),
          ),
          child: child!,
        );
      },
    );

    if (selectedDate != null) {
      // Then show time picker
      final selectedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(currentDateTime),
        builder: (context, child) {
          return Theme(
            data: ThemeData.dark().copyWith(
              colorScheme: const ColorScheme.dark(
                primary: Color(0xFF8B0000),
                surface: Color(0xFF2A2A2A),
              ),
            ),
            child: child!,
          );
        },
      );

      if (selectedTime != null) {
        // Combine date and time
        final newDateTime = DateTime(
          selectedDate.year,
          selectedDate.month,
          selectedDate.day,
          selectedTime.hour,
          selectedTime.minute,
        );

        setState(() => _isLoading = true);
        try {
          await _firestore
              .collection('package_subscriptions')
              .doc(widget.packageId)
              .update({
                'nextBillingDate': Timestamp.fromDate(newDateTime),
                'updatedAt': FieldValue.serverTimestamp(),
              });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Next billing date updated to ${DateFormat('MMM dd, yyyy HH:mm').format(newDateTime)}',
                ),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 4),
              ),
            );
            Navigator.pop(context);
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error updating billing date: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        } finally {
          if (mounted) setState(() => _isLoading = false);
        }
      }
    }
  }

  Future<void> _updatePackagePrice() async {
    final controller = TextEditingController(
      text: widget.packageData['packagePrice'].toString(),
    );

    final newPrice = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: const Text(
          'Update Package Price',
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: 'New Price (R)',
            labelStyle: TextStyle(color: Colors.white54),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.white24),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF8B0000)),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final price = double.tryParse(controller.text);
              Navigator.pop(context, price);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B0000),
            ),
            child: const Text('Update'),
          ),
        ],
      ),
    );

    if (newPrice != null && newPrice > 0) {
      setState(() => _isLoading = true);
      try {
        await _firestore
            .collection('package_subscriptions')
            .doc(widget.packageId)
            .update({
              'packagePrice': newPrice,
              'updatedAt': FieldValue.serverTimestamp(),
            });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Package price updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error updating price: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _addNotes() async {
    final controller = TextEditingController(
      text: widget.packageData['notes'] ?? '',
    );

    final notes = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: const Text(
          'Add/Update Notes',
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: controller,
          maxLines: 5,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: 'Notes',
            labelStyle: TextStyle(color: Colors.white54),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.white24),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF8B0000)),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B0000),
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (notes != null) {
      setState(() => _isLoading = true);
      try {
        await _firestore
            .collection('package_subscriptions')
            .doc(widget.packageId)
            .update({
              'notes': notes,
              'updatedAt': FieldValue.serverTimestamp(),
            });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Notes updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error updating notes: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pauseSubscription() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: const Text(
          'Pause Subscription',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Are you sure you want to pause this subscription? The client will not be billed until reactivated.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Pause'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      try {
        await _firestore
            .collection('package_subscriptions')
            .doc(widget.packageId)
            .update({
              'status': 'paused',
              'pausedAt': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
            });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Subscription paused successfully'),
              backgroundColor: Colors.orange,
            ),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error pausing subscription: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _activateSubscription() async {
    setState(() => _isLoading = true);
    try {
      await _firestore
          .collection('package_subscriptions')
          .doc(widget.packageId)
          .update({
            'status': 'active',
            'reactivatedAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Subscription activated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error activating subscription: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _confirmCancelSubscription() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: const Text(
          'Cancel Subscription',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Are you sure you want to cancel this subscription? This action cannot be undone.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep Subscription'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Cancel Subscription'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      try {
        await _firestore
            .collection('package_subscriptions')
            .doc(widget.packageId)
            .update({
              'status': 'cancelled',
              'cancelledAt': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
            });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Subscription cancelled successfully'),
              backgroundColor: Colors.red,
            ),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error cancelling subscription: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _sendInvoiceEmail() async {
    setState(() => _isLoading = true);
    try {
      final clientEmail = widget.packageData['clientEmail'] ?? '';

      if (clientEmail.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Client email is missing. Cannot send invoice.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // TODO: Implement invoice email service
      print('📧 Invoice email functionality not yet implemented');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invoice email functionality coming soon'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('📧 ❌ Error sending invoice email: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending email: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
