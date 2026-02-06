import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  bool _isLoading = true;
  Map<String, bool> _notificationSettings = {
    'order_updates': true,
    'payment_notifications': true,
    'loyalty_points': true,
    'tier_upgrades': true,
    'project_completion': true,
    'app_updates': true,
    'promotional': false,
  };

  @override
  void initState() {
    super.initState();
    _loadNotificationSettings();
  }

  Future<void> _loadNotificationSettings() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final doc = await _firestore.collection('users').doc(user.uid).get();
        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;
          final settings = data['notificationSettings'] as Map<String, dynamic>?;
          if (settings != null) {
            setState(() {
              _notificationSettings = Map<String, bool>.from(settings);
            });
          }
        }
      }
    } catch (e) {
// print('Error loading notification settings: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateNotificationSetting(String key, bool value) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        setState(() {
          _notificationSettings[key] = value;
        });

        await _firestore.collection('users').doc(user.uid).update({
          'notificationSettings': _notificationSettings,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Notification settings updated'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
// print('Error updating notification setting: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating settings: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildSettingTile({
    required String title,
    required String subtitle,
    required String key,
    required IconData icon,
    Color? iconColor,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: Icon(
          icon,
          color: iconColor ?? const Color(0xFF8B0000),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
        trailing: Switch(
          value: _notificationSettings[key] ?? true,
          onChanged: (value) => _updateNotificationSetting(key, value),
          activeThumbColor: const Color(0xFF8B0000),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Notification Settings',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF8B0000),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: Color(0xFF8B0000),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.notifications_active,
                        size: 48,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Manage Your Notifications',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Choose which notifications you want to receive',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Notification Settings
                Expanded(
                  child: ListView(
                    children: [
                      // Order Updates
                      _buildSettingTile(
                        title: 'Order Updates',
                        subtitle: 'Get notified about order status changes',
                        key: 'order_updates',
                        icon: Icons.shopping_bag,
                        iconColor: Colors.blue,
                      ),
                      
                      // Payment Notifications
                      _buildSettingTile(
                        title: 'Payment Notifications',
                        subtitle: 'Receive payment confirmations and updates',
                        key: 'payment_notifications',
                        icon: Icons.payment,
                        iconColor: Colors.green,
                      ),
                      
                      // Loyalty Points
                      _buildSettingTile(
                        title: 'Loyalty Points',
                        subtitle: 'Get notified when you earn loyalty points',
                        key: 'loyalty_points',
                        icon: Icons.star,
                        iconColor: Colors.amber,
                      ),
                      
                      // Tier Upgrades
                      _buildSettingTile(
                        title: 'Tier Upgrades',
                        subtitle: 'Notifications about membership tier changes',
                        key: 'tier_upgrades',
                        icon: Icons.workspace_premium,
                        iconColor: Colors.purple,
                      ),
                      
                      // Project Completion
                      _buildSettingTile(
                        title: 'Project Completion',
                        subtitle: 'Get notified when your projects are completed',
                        key: 'project_completion',
                        icon: Icons.check_circle,
                        iconColor: Colors.green,
                      ),
                      
                      // App Updates
                      _buildSettingTile(
                        title: 'App Updates',
                        subtitle: 'Important app updates and announcements',
                        key: 'app_updates',
                        icon: Icons.system_update,
                        iconColor: Colors.orange,
                      ),
                      
                      // Promotional
                      _buildSettingTile(
                        title: 'Promotional',
                        subtitle: 'Special offers and promotional content',
                        key: 'promotional',
                        icon: Icons.local_offer,
                        iconColor: Colors.red,
                      ),
                    ],
                  ),
                ),
                
                // Bottom Info
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Colors.blue[700],
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'You can change these settings at any time. Some important notifications cannot be disabled.',
                                style: TextStyle(
                                  color: Colors.blue[700],
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
