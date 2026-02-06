import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/paystack_customer_service.dart';
import 'saved_cards_screen.dart';

class ManageSavedCardsScreen extends StatefulWidget {
  const ManageSavedCardsScreen({super.key});

  @override
  State<ManageSavedCardsScreen> createState() => _ManageSavedCardsScreenState();
}

class _ManageSavedCardsScreenState extends State<ManageSavedCardsScreen> {
  List<Map<String, dynamic>> _savedCards = [];
  bool _isLoading = true;
  final PaystackCustomerService _customerService =
      PaystackCustomerService.instance;

  @override
  void initState() {
    super.initState();
    _loadSavedCards();
  }

  Future<void> _loadSavedCards() async {
    setState(() => _isLoading = true);

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      final cards = await _customerService.getSavedCards(currentUser.uid);
      setState(() {
        _savedCards = cards;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF8B0000),
        title: const Text('Saved Cards', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () => _addNewCard(),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF8B0000)),
            )
          : _savedCards.isEmpty
          ? _buildEmptyState()
          : _buildCardsList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.credit_card_off, size: 80, color: Colors.grey[600]),
            const SizedBox(height: 24),
            const Text(
              'No Saved Cards',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Save your card details for faster checkout and autofill in future payments.',
              style: TextStyle(color: Colors.grey[400], fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => _addNewCard(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B0000),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Add Your First Card',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardsList() {
    return RefreshIndicator(
      onRefresh: _loadSavedCards,
      color: const Color(0xFF8B0000),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _savedCards.length,
        itemBuilder: (context, index) {
          final card = _savedCards[index];
          return _buildCardItem(card);
        },
      ),
    );
  }

  Widget _buildCardItem(Map<String, dynamic> card) {
    final isDefault = card['isDefault'] ?? false;
    final cardType = card['cardType'] ?? 'Unknown';
    final lastFour = card['lastFourDigits'] ?? '****';
    final expiryDate = card['expiryDate'] ?? '**/**';
    final cardName = card['cardName'] ?? 'Unknown';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: Colors.grey[800],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Card Type Icon
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getCardTypeColor(cardType),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getCardTypeIcon(cardType),
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),

                // Card Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$cardType •••• $lastFour',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        cardName,
                        style: TextStyle(color: Colors.grey[300], fontSize: 14),
                      ),
                      Text(
                        'Expires $expiryDate',
                        style: TextStyle(color: Colors.grey[400], fontSize: 12),
                      ),
                    ],
                  ),
                ),

                // Default Badge
                if (isDefault)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B0000),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'DEFAULT',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 16),

            // Action Buttons
            Row(
              children: [
                if (!isDefault) ...[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _setAsDefault(card['id']),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF8B0000),
                        side: const BorderSide(color: Color(0xFF8B0000)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Set as Default'),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _deleteCard(card['id']),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Delete'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getCardTypeColor(String cardType) {
    switch (cardType.toLowerCase()) {
      case 'visa':
        return Colors.blue;
      case 'mastercard':
        return Colors.red;
      case 'american express':
        return Colors.green;
      case 'discover':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getCardTypeIcon(String cardType) {
    switch (cardType.toLowerCase()) {
      case 'visa':
        return Icons.credit_card;
      case 'mastercard':
        return Icons.credit_card;
      case 'american express':
        return Icons.credit_card;
      case 'discover':
        return Icons.credit_card;
      default:
        return Icons.credit_card;
    }
  }

  void _addNewCard() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SavedCardsScreen()),
    );

    if (result == true) {
      _loadSavedCards();
    }
  }

  void _setAsDefault(String cardId) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final success = await _customerService.setDefaultCard(
      cardId,
      currentUser.uid,
    );

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Default card updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      _loadSavedCards();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update default card. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _deleteCard(String cardId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: const Text('Delete Card', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to delete this saved card? This action cannot be undone.',
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      final success = await _customerService.deleteSavedCard(
        cardId,
        currentUser.uid,
      );

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Card deleted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        _loadSavedCards();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to delete card. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
