import 'package:flutter/material.dart';
import '../services/marketing_service.dart';

// Proposal Details Dialog for viewing, editing, and resending proposals
class ProposalDetailsDialog extends StatefulWidget {
  final Proposal proposal;
  final Function(Proposal) onEdit;
  final Function(Proposal) onResend;

  const ProposalDetailsDialog({
    super.key,
    required this.proposal,
    required this.onEdit,
    required this.onResend,
  });

  @override
  State<ProposalDetailsDialog> createState() => _ProposalDetailsDialogState();
}

class _ProposalDetailsDialogState extends State<ProposalDetailsDialog> {
  late TextEditingController _subjectController;
  late TextEditingController _clientNameController;
  late TextEditingController _clientEmailController;
  late TextEditingController _valueController;
  late TextEditingController _messageController;
  late String _selectedType;
  late String _selectedStatus;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _subjectController = TextEditingController(text: widget.proposal.subject);
    _clientNameController = TextEditingController(
      text: widget.proposal.clientName,
    );
    _clientEmailController = TextEditingController(
      text: widget.proposal.clientEmail,
    );
    _valueController = TextEditingController(
      text: widget.proposal.value.toString(),
    );
    _messageController = TextEditingController(
      text: widget.proposal.messageBody ?? '',
    );
    _selectedType = widget.proposal.type;
    _selectedStatus = widget.proposal.status;
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _clientNameController.dispose();
    _clientEmailController.dispose();
    _valueController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _isEditing ? 'Edit Proposal' : 'Proposal Details',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    if (!_isEditing) ...[
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _isEditing = true;
                          });
                        },
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        tooltip: 'Edit Proposal',
                      ),
                      IconButton(
                        onPressed: () => _resendProposal(),
                        icon: const Icon(Icons.send, color: Colors.green),
                        tooltip: 'Resend Email',
                      ),
                    ],
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, color: Colors.white70),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Content
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Proposal Type and Status
                    Row(
                      children: [
                        Expanded(
                          child: _buildInfoField(
                            'Type',
                            _isEditing
                                ? DropdownButtonFormField<String>(
                                    initialValue: _selectedType,
                                    decoration: const InputDecoration(
                                      border: OutlineInputBorder(),
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                    ),
                                    dropdownColor: const Color(0xFF2A2A2A),
                                    style: const TextStyle(color: Colors.white),
                                    items: const [
                                      DropdownMenuItem(
                                        value: 'Website Design',
                                        child: Text('Website Design'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'Logo Design',
                                        child: Text('Logo Design'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'Marketing',
                                        child: Text('Marketing'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'Development',
                                        child: Text('Development'),
                                      ),
                                    ],
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedType = value!;
                                      });
                                    },
                                  )
                                : Text(
                                    _selectedType,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildInfoField(
                            'Status',
                            _isEditing
                                ? DropdownButtonFormField<String>(
                                    initialValue: _selectedStatus,
                                    decoration: const InputDecoration(
                                      border: OutlineInputBorder(),
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                    ),
                                    dropdownColor: const Color(0xFF2A2A2A),
                                    style: const TextStyle(color: Colors.white),
                                    items: const [
                                      DropdownMenuItem(
                                        value: 'draft',
                                        child: Text('Draft'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'sent',
                                        child: Text('Sent'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'responded',
                                        child: Text('Responded'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'accepted',
                                        child: Text('Accepted'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'declined',
                                        child: Text('Declined'),
                                      ),
                                    ],
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedStatus = value!;
                                      });
                                    },
                                  )
                                : Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(
                                        _selectedStatus,
                                      ).withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: _getStatusColor(_selectedStatus),
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(
                                      _selectedStatus.toUpperCase(),
                                      style: TextStyle(
                                        color: _getStatusColor(_selectedStatus),
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Subject
                    _buildInfoField(
                      'Subject',
                      _isEditing
                          ? TextFormField(
                              controller: _subjectController,
                              style: const TextStyle(color: Colors.white),
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                              ),
                            )
                          : Text(
                              _subjectController.text,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                    ),
                    const SizedBox(height: 16),

                    // Client Information
                    Row(
                      children: [
                        Expanded(
                          child: _buildInfoField(
                            'Client Name',
                            _isEditing
                                ? TextFormField(
                                    controller: _clientNameController,
                                    style: const TextStyle(color: Colors.white),
                                    decoration: const InputDecoration(
                                      border: OutlineInputBorder(),
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                    ),
                                  )
                                : Text(
                                    _clientNameController.text,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildInfoField(
                            'Client Email',
                            _isEditing
                                ? TextFormField(
                                    controller: _clientEmailController,
                                    style: const TextStyle(color: Colors.white),
                                    decoration: const InputDecoration(
                                      border: OutlineInputBorder(),
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                    ),
                                  )
                                : Text(
                                    _clientEmailController.text,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Value
                    _buildInfoField(
                      'Value',
                      _isEditing
                          ? TextFormField(
                              controller: _valueController,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(color: Colors.white),
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                prefixText: 'R',
                              ),
                            )
                          : Text(
                              'R${_valueController.text}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                    const SizedBox(height: 16),

                    // Message
                    _buildInfoField(
                      'Message',
                      _isEditing
                          ? TextFormField(
                              controller: _messageController,
                              maxLines: 5,
                              style: const TextStyle(color: Colors.white),
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                alignLabelWithHint: true,
                              ),
                            )
                          : Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2A2A2A),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: const Color(0xFF3A3A3A),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                _messageController.text.isEmpty
                                    ? 'No message provided'
                                    : _messageController.text,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                    ),
                    const SizedBox(height: 16),

                    // Dates
                    Row(
                      children: [
                        Expanded(
                          child: _buildInfoField(
                            'Sent Date',
                            Text(
                              MarketingService.formatDate(
                                widget.proposal.sentDate,
                              ),
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                        if (widget.proposal.responseDate != null) ...[
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildInfoField(
                              'Response Date',
                              Text(
                                MarketingService.formatDate(
                                  widget.proposal.responseDate!,
                                ),
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Action Buttons
            if (_isEditing) ...[
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _isEditing = false;
                        // Reset to original values
                        _subjectController.text = widget.proposal.subject;
                        _clientNameController.text = widget.proposal.clientName;
                        _clientEmailController.text =
                            widget.proposal.clientEmail;
                        _valueController.text = widget.proposal.value
                            .toString();
                        _messageController.text =
                            widget.proposal.messageBody ?? '';
                        _selectedType = widget.proposal.type;
                        _selectedStatus = widget.proposal.status;
                      });
                    },
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: _saveChanges,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B0000),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Save Changes'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoField(String label, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'draft':
        return Colors.grey;
      case 'sent':
        return Colors.blue;
      case 'responded':
        return Colors.orange;
      case 'accepted':
        return Colors.green;
      case 'declined':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _saveChanges() {
    final updatedProposal = Proposal(
      id: widget.proposal.id,
      subject: _subjectController.text,
      clientName: _clientNameController.text,
      clientEmail: _clientEmailController.text,
      type: _selectedType,
      value: double.tryParse(_valueController.text) ?? 0.0,
      messageBody: _messageController.text,
      status: _selectedStatus,
      sentDate: widget.proposal.sentDate,
      responseDate: widget.proposal.responseDate,
      createdAt: widget.proposal.createdAt,
      updatedAt: DateTime.now(),
    );

    widget.onEdit(updatedProposal);
    Navigator.of(context).pop();
  }

  void _resendProposal() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text(
          'Resend Proposal',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Are you sure you want to resend this proposal email?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close confirmation dialog
              Navigator.of(context).pop(); // Close details dialog
              widget.onResend(widget.proposal);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B0000),
              foregroundColor: Colors.white,
            ),
            child: const Text('Resend'),
          ),
        ],
      ),
    );
  }
}
