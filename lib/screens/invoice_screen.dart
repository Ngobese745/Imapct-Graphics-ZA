import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../main.dart';
import '../services/invoice_payment_service.dart';

class InvoiceScreen extends StatefulWidget {
  final String transactionId;
  final String customerName;
  final String customerEmail;
  final String serviceName;
  final double amount;
  final String status;
  final DateTime date;
  final String? reference;
  final String? phone;
  final String? orderNumber;

  const InvoiceScreen({
    super.key,
    required this.transactionId,
    required this.customerName,
    required this.customerEmail,
    required this.serviceName,
    required this.amount,
    required this.status,
    required this.date,
    this.reference,
    this.phone,
    this.orderNumber,
  });

  @override
  State<InvoiceScreen> createState() => _InvoiceScreenState();
}

class _InvoiceScreenState extends State<InvoiceScreen> {
  final GlobalKey _invoiceKey = GlobalKey();
  String? _paymentUrl;
  bool _isGeneratingPaymentLink = false;

  @override
  void initState() {
    super.initState();
    // Generate payment link if status is pending
    if (widget.status.toUpperCase() == 'PENDING') {
      _generatePaymentLink();
    }
  }

  Future<void> _generatePaymentLink() async {
    if (_isGeneratingPaymentLink) return;

    setState(() {
      _isGeneratingPaymentLink = true;
    });

    try {
      final result = await InvoicePaymentService.generatePaymentLink(
        email: widget.customerEmail,
        amount: widget.amount,
        reference: widget.reference ?? widget.transactionId,
        customerName: widget.customerName,
        phoneNumber: widget.phone,
        serviceName: widget.serviceName,
      );

      if (result['success'] == true) {
        setState(() {
          _paymentUrl = result['paymentUrl'];
        });
        print('✅ Payment link generated: $_paymentUrl');
      } else {
        print('❌ Failed to generate payment link: ${result['message']}');
      }
    } catch (e) {
      print('❌ Error generating payment link: $e');
    } finally {
      setState(() {
        _isGeneratingPaymentLink = false;
      });
    }
  }

  Future<void> _openPaymentLink() async {
    if (_paymentUrl == null) return;

    try {
      final uri = Uri.parse(_paymentUrl!);
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      print('❌ Error opening payment link: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error opening payment link: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF8B0000),
        foregroundColor: Colors.white,
        title: const Text(
          'Invoice',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: _shareInvoice,
            icon: const Icon(Icons.share),
            tooltip: 'Share Invoice',
          ),
          IconButton(
            onPressed: _downloadInvoice,
            icon: const Icon(Icons.download),
            tooltip: 'Download Invoice',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: RepaintBoundary(
          key: _invoiceKey,
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF2A2A2A),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [_buildInvoiceHeader(), _buildInvoiceContent()],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInvoiceHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24.0),
      decoration: const BoxDecoration(
        color: Color(0xFF8B0000),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLogo(),
              const SizedBox(width: 16),
              const Text(
                'INVOICE',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Transaction #${widget.transactionId}',
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white70,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: Image.asset(
          'assets/images/logo.png',
          width: 60,
          height: 60,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            // Fallback if logo image is not found
            return Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Center(
                child: Text(
                  'IG',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF8B0000),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildInvoiceContent() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFromSection(),
          const SizedBox(height: 24),
          _buildToSection(),
          const SizedBox(height: 24),
          _buildTransactionDetails(),
          const SizedBox(height: 32),
          _buildAmountSection(),
          const SizedBox(height: 24),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildFromSection() {
    return _buildSectionCard('From:', [
      const Text(
        'Impact Graphics ZA',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      const SizedBox(height: 4),
      const Text(
        'Professional Design Services',
        style: TextStyle(fontSize: 14, color: Colors.white70),
      ),
      const SizedBox(height: 8),
      const Text(
        'Email: info@impactgraphicsza.co.za',
        style: TextStyle(fontSize: 14, color: Colors.white70),
      ),
      const SizedBox(height: 4),
      const Text(
        'Phone: +27 68 367 5755',
        style: TextStyle(fontSize: 14, color: Colors.white70),
      ),
    ]);
  }

  Widget _buildToSection() {
    return _buildSectionCard('To:', [
      Text(
        widget.customerName,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      const SizedBox(height: 4),
      Text(
        widget.customerEmail,
        style: const TextStyle(fontSize: 14, color: Colors.white70),
      ),
      if (widget.phone != null) ...[
        const SizedBox(height: 4),
        Text(
          'Phone: ${widget.phone}',
          style: const TextStyle(fontSize: 14, color: Colors.white70),
        ),
      ],
    ]);
  }

  Widget _buildTransactionDetails() {
    return _buildSectionCard('Transaction Details', [
      _buildDetailRow('Description', widget.serviceName),
      if (widget.orderNumber != null)
        _buildDetailRow('Order Number', widget.orderNumber!),
      _buildDetailRow('Type', 'DEBIT'),
      _buildDetailRow('Status', widget.status.toUpperCase()),
      _buildDetailRow('Reference', widget.reference ?? widget.transactionId),
      _buildDetailRow('Date', _formatDate(widget.date)),
      _buildDetailRow('Time', _formatTime(widget.date)),
    ]);
  }

  Widget _buildAmountSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF8B0000).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF8B0000).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          const Text(
            'Total Amount',
            style: TextStyle(fontSize: 16, color: Colors.white70),
          ),
          const SizedBox(height: 8),
          Text(
            'R${widget.amount.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Color(0xFFFFD700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF8B0000).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFFFF6B6B),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$label:',
            style: const TextStyle(fontSize: 14, color: Colors.white70),
          ),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildActionButtons() {
    // Show payment sections for pending invoices
    if (widget.status.toUpperCase() == 'PENDING') {
      return Column(
        children: [
          // Paystack Payment Section
          _buildUIPaymentSection(),
          const SizedBox(height: 20),
          // Banking Details Section
          _buildUIBankingSection(),
          const SizedBox(height: 20),
          // Other buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _shareInvoice,
                  icon: const Icon(Icons.share, color: Color(0xFF8B0000)),
                  label: const Text(
                    'Share',
                    style: TextStyle(color: Color(0xFF8B0000)),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF8B0000)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (context) => const DashboardScreen(),
                      ),
                      (route) => false,
                    );
                  },
                  icon: const Icon(Icons.check, color: Colors.white),
                  label: const Text(
                    'Done',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B0000),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    }

    // Regular buttons for non-pending invoices
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _shareInvoice,
            icon: const Icon(Icons.share, color: Color(0xFF8B0000)),
            label: const Text(
              'Share',
              style: TextStyle(color: Color(0xFF8B0000)),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFF8B0000)),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (context) => const DashboardScreen(),
                ),
                (route) => false,
              );
            },
            icon: const Icon(Icons.check, color: Colors.white),
            label: const Text('Done', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B0000),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUIPaymentSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF8B0000), // Dark red/maroon
        border: Border.all(color: const Color(0xFFDC143C), width: 2),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          // Header
          const Text(
            'PAY NOW',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 15),

          // Amount display
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 25),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFDC143C), width: 2),
            ),
            child: Column(
              children: [
                const Text(
                  'Amount to Pay',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF8B0000),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'R${widget.amount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF8B0000),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Payment instructions
          const Text(
            'CLICK THE BUTTON BELOW TO PAY SECURELY',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.yellow,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 15),

          // Payment button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isGeneratingPaymentLink ? null : _openPaymentLink,
              icon: _isGeneratingPaymentLink
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.payment, color: Colors.white),
              label: Text(
                _isGeneratingPaymentLink
                    ? 'Generating Payment Link...'
                    : 'PAY R${widget.amount.toStringAsFixed(2)} NOW',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC143C),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          const SizedBox(height: 15),

          // Payment URL display (if available)
          if (_paymentUrl != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white, width: 1),
              ),
              child: Column(
                children: [
                  const Text(
                    'PAYMENT LINK:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF8B0000),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SelectableText(
                    _paymentUrl!,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.blue,
                      decoration: TextDecoration.underline,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '(Click or copy this link to complete payment)',
                    style: TextStyle(
                      fontSize: 9,
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 15),

          // Security notice
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Text(
                'Secure payment powered by Paystack - Your payment is protected',
                style: TextStyle(fontSize: 10, color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUIBankingSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF8B0000), // Dark red/maroon
        border: Border.all(color: const Color(0xFFDC143C), width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Text(
            'ALTERNATIVE PAYMENT METHODS',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          const Text(
            'Prefer Bank Transfer?',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.yellow,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Bank Name:',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF8B0000),
                  ),
                ),
                const Text(
                  'Capitec Business',
                  style: TextStyle(fontSize: 10, color: Color(0xFF8B0000)),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Account Number:',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF8B0000),
                  ),
                ),
                const Text(
                  '1053262485',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF8B0000),
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Account Holder:',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF8B0000),
                  ),
                ),
                const Text(
                  'Impact Graphics ZA',
                  style: TextStyle(fontSize: 10, color: Color(0xFF8B0000)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Use your invoice number as reference when making payment',
            style: TextStyle(
              fontSize: 8,
              color: Colors.grey,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Future<void> _shareInvoice() async {
    try {
      // Generate PDF
      final pdf = await _generatePDF();

      // Save to temporary directory
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/invoice_${widget.transactionId}.pdf');
      await file.writeAsBytes(await pdf.save());

      // Share the PDF
      await Share.shareXFiles(
        [XFile(file.path)],
        text:
            'Invoice for ${widget.serviceName} - R${widget.amount.toStringAsFixed(2)}',
      );
    } catch (e) {
      // If sharing completely fails, show a dialog with the invoice text
      _showInvoiceTextDialog();
    }
  }

  void _showInvoiceTextDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: const Text(
          'Invoice Details',
          style: TextStyle(color: Colors.white),
        ),
        content: SingleChildScrollView(
          child: Text(
            'Invoice #${widget.transactionId}\n'
            '${widget.orderNumber != null ? 'Order: ${widget.orderNumber}\n' : ''}'
            'Service: ${widget.serviceName}\n'
            'Amount: R${widget.amount.toStringAsFixed(2)}\n'
            'Status: ${widget.status}\n'
            'Date: ${_formatDate(widget.date)}\n'
            'Customer: ${widget.customerName}\n'
            'Email: ${widget.customerEmail}\n\n'
            'You can copy this text to share manually.',
            style: const TextStyle(color: Colors.white),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              // Copy to clipboard
              Clipboard.setData(
                ClipboardData(
                  text:
                      'Invoice #${widget.transactionId}\n'
                      'Service: ${widget.serviceName}\n'
                      'Amount: R${widget.amount.toStringAsFixed(2)}\n'
                      'Status: ${widget.status}\n'
                      'Date: ${_formatDate(widget.date)}\n'
                      'Customer: ${widget.customerName}\n'
                      'Email: ${widget.customerEmail}',
                ),
              );
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Invoice details copied to clipboard'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Copy to Clipboard'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadInvoice() async {
    try {
      // Generate PDF
      final pdf = await _generatePDF();

      // Show print/share dialog
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => await pdf.save(),
        name: 'Invoice_${widget.transactionId}.pdf',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invoice ready for printing or saving'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      // Fallback: try to save to downloads directory
      try {
        final pdf = await _generatePDF();
        final directory = await getApplicationDocumentsDirectory();
        final file = File(
          '${directory.path}/invoice_${widget.transactionId}.pdf',
        );
        await file.writeAsBytes(await pdf.save());

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Invoice saved to app documents: ${file.path}'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 5),
          ),
        );
      } catch (e2) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving invoice: $e2'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<pw.Document> _generatePDF() async {
    final pdf = pw.Document();

    print('=== GENERATING PDF ===');
    print('Status: ${widget.status}');
    print('Payment URL: $_paymentUrl');
    print('Is Pending: ${widget.status.toUpperCase() == 'PENDING'}');
    print('Amount: R${widget.amount.toStringAsFixed(2)}');

    // Load logo image bytes
    final logoBytes = await _loadLogoBytes();

    // First page - Invoice details
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              _buildPDFHeader(logoBytes),
              pw.SizedBox(height: 20),
              // From Section
              _buildPDFFromSection(),
              pw.SizedBox(height: 20),
              // To Section
              _buildPDFToSection(),
              pw.SizedBox(height: 20),
              // Transaction Details
              _buildPDFTransactionDetails(),
              pw.SizedBox(height: 20),
              // Amount Section
              _buildPDFAmountSection(),
            ],
          );
        },
      ),
    );

    // Second page - Payment sections (only for pending invoices)
    if (widget.status.toUpperCase() == 'PENDING') {
      print('✅ Adding payment section to PDF as separate page');
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(20),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Page title
                pw.Text(
                  'PAYMENT INSTRUCTIONS',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.red900,
                  ),
                ),
                pw.SizedBox(height: 20),
                // Payment section
                _buildPDFPaymentSection(),
              ],
            );
          },
        ),
      );
      print('📄 Payment page added successfully');
    } else {
      print('❌ Not adding payment section - Status: ${widget.status}');
    }

    print('📄 PDF page added successfully');

    return pdf;
  }

  pw.Widget _buildPDFHeader(Uint8List? logoBytes) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(20),
      decoration: const pw.BoxDecoration(color: PdfColors.red900),
      child: pw.Column(
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [
              // Logo image
              pw.Container(
                width: 50,
                height: 50,
                decoration: pw.BoxDecoration(
                  color: PdfColors.white,
                  shape: pw.BoxShape.circle,
                ),
                child: logoBytes != null && logoBytes.isNotEmpty
                    ? pw.Center(
                        child: pw.Image(
                          pw.MemoryImage(logoBytes),
                          width: 40,
                          height: 40,
                          fit: pw.BoxFit.contain,
                        ),
                      )
                    : pw.Center(
                        child: pw.Text(
                          'IG',
                          style: pw.TextStyle(
                            fontSize: 20,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.red900,
                          ),
                        ),
                      ),
              ),
              pw.SizedBox(width: 15),
              pw.Text(
                'INVOICE',
                style: pw.TextStyle(
                  fontSize: 28,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 10),
          pw.Text(
            'Transaction #${widget.transactionId}',
            style: pw.TextStyle(fontSize: 14, color: PdfColors.grey300),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPDFFromSection() {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey800,
        border: pw.Border.all(color: PdfColors.red900, width: 1),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'From:',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.red400,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Text(
            'Impact Graphics ZA',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            'Professional Design Services',
            style: pw.TextStyle(fontSize: 12, color: PdfColors.grey300),
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            'Email: info@impactgraphicsza.co.za',
            style: pw.TextStyle(fontSize: 12, color: PdfColors.grey300),
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            'Phone: +27 68 367 5755',
            style: pw.TextStyle(fontSize: 12, color: PdfColors.grey300),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPDFToSection() {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey800,
        border: pw.Border.all(color: PdfColors.red900, width: 1),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'To:',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.red400,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Text(
            widget.customerName,
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            widget.customerEmail,
            style: pw.TextStyle(fontSize: 12, color: PdfColors.grey300),
          ),
          if (widget.phone != null) ...[
            pw.SizedBox(height: 5),
            pw.Text(
              'Phone: ${widget.phone}',
              style: pw.TextStyle(fontSize: 12, color: PdfColors.grey300),
            ),
          ],
        ],
      ),
    );
  }

  pw.Widget _buildPDFTransactionDetails() {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey800,
        border: pw.Border.all(color: PdfColors.red900, width: 1),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Transaction Details',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.red400,
            ),
          ),
          pw.SizedBox(height: 10),
          _buildPDFDetailRow('Description', widget.serviceName),
          if (widget.orderNumber != null)
            _buildPDFDetailRow('Order Number', widget.orderNumber!),
          _buildPDFDetailRow('Type', 'DEBIT'),
          _buildPDFDetailRow('Status', widget.status.toUpperCase()),
          _buildPDFDetailRow(
            'Reference',
            widget.reference ?? widget.transactionId,
          ),
          _buildPDFDetailRow('Date', _formatDate(widget.date)),
          _buildPDFDetailRow('Time', _formatTime(widget.date)),
        ],
      ),
    );
  }

  pw.Widget _buildPDFAmountSection() {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey800,
        border: pw.Border.all(color: PdfColors.red900, width: 1),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            'Total Amount',
            style: pw.TextStyle(fontSize: 14, color: PdfColors.grey300),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'R${widget.amount.toStringAsFixed(2)}',
            style: pw.TextStyle(
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.yellow,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPDFPaymentSection() {
    print('=== BUILDING PDF PAYMENT SECTION ===');
    print('Payment URL in PDF: $_paymentUrl');
    print('Amount in PDF: R${widget.amount.toStringAsFixed(2)}');

    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(25),
      decoration: pw.BoxDecoration(
        color: PdfColors.red900,
        border: pw.Border.all(color: PdfColors.red400, width: 3),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(15)),
      ),
      child: pw.Column(
        children: [
          // Header
          pw.Text(
            'PAY NOW',
            style: pw.TextStyle(
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
            textAlign: pw.TextAlign.center,
          ),
          pw.SizedBox(height: 15),

          // Amount display
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.symmetric(
              vertical: 15,
              horizontal: 25,
            ),
            decoration: pw.BoxDecoration(
              color: PdfColors.white,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
              border: pw.Border.all(color: PdfColors.red400, width: 2),
            ),
            child: pw.Column(
              children: [
                pw.Text(
                  'Amount to Pay',
                  style: pw.TextStyle(
                    fontSize: 14,
                    color: PdfColors.red900,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  'R${widget.amount.toStringAsFixed(2)}',
                  style: pw.TextStyle(
                    fontSize: 28,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.red900,
                  ),
                ),
              ],
            ),
          ),

          pw.SizedBox(height: 20),

          // Payment instructions
          pw.Text(
            'CLICK THE LINK BELOW TO PAY SECURELY',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.yellow,
            ),
            textAlign: pw.TextAlign.center,
          ),
          pw.SizedBox(height: 10),

          // Payment URL in a prominent box
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(15),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              border: pw.Border.all(color: PdfColors.white, width: 2),
            ),
            child: pw.Column(
              children: [
                pw.Text(
                  'PAYMENT LINK:',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.red900,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  _paymentUrl ?? 'Generating payment link...',
                  style: pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.blue800,
                    decoration: _paymentUrl != null
                        ? pw.TextDecoration.underline
                        : pw.TextDecoration.none,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  '(Click or copy this link to complete payment)',
                  style: pw.TextStyle(
                    fontSize: 9,
                    color: PdfColors.grey600,
                    fontStyle: pw.FontStyle.italic,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
              ],
            ),
          ),

          pw.SizedBox(height: 15),

          // Security notice
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: PdfColors.red800,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
            ),
            child: pw.Center(
              child: pw.Text(
                'Secure payment powered by Paystack - Your payment is protected',
                style: pw.TextStyle(fontSize: 10, color: PdfColors.white),
                textAlign: pw.TextAlign.center,
              ),
            ),
          ),

          pw.SizedBox(height: 20),

          // Alternative Payment Methods
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(15),
            decoration: pw.BoxDecoration(
              color: PdfColors.red800,
              border: pw.Border.all(color: PdfColors.red400, width: 2),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
            ),
            child: pw.Column(
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: [
                    pw.Text(
                      'ALTERNATIVE PAYMENT METHODS',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 10),
                pw.Text(
                  'Prefer Bank Transfer?',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.yellow,
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.white,
                    borderRadius: const pw.BorderRadius.all(
                      pw.Radius.circular(8),
                    ),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Bank Name:',
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.red900,
                        ),
                      ),
                      pw.Text(
                        'Capitec Business',
                        style: pw.TextStyle(
                          fontSize: 10,
                          color: PdfColors.red900,
                        ),
                      ),
                      pw.SizedBox(height: 5),
                      pw.Text(
                        'Account Number:',
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.red900,
                        ),
                      ),
                      pw.Text(
                        '1053262485',
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.red900,
                        ),
                      ),
                      pw.SizedBox(height: 5),
                      pw.Text(
                        'Account Holder:',
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.red900,
                        ),
                      ),
                      pw.Text(
                        'Impact Graphics ZA',
                        style: pw.TextStyle(
                          fontSize: 10,
                          color: PdfColors.red900,
                        ),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  'Use your invoice number as reference when making payment',
                  style: pw.TextStyle(
                    fontSize: 8,
                    color: PdfColors.white,
                    fontStyle: pw.FontStyle.italic,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPDFSectionCard(String title, List<pw.Widget> children) {
    return pw.Container(
      width: double.infinity,
      margin: const pw.EdgeInsets.only(bottom: 16),
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey800,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
        border: pw.Border.all(color: PdfColors.red900, width: 1),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.red400,
              letterSpacing: 0.5,
            ),
          ),
          pw.SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  pw.Widget _buildPDFDetailRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            '$label:',
            style: pw.TextStyle(fontSize: 14, color: PdfColors.grey300),
          ),
          pw.Flexible(
            child: pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.normal,
                color: PdfColors.white,
              ),
              textAlign: pw.TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Future<Uint8List?> _captureInvoiceImage() async {
    try {
      final RenderRepaintBoundary boundary =
          _invoiceKey.currentContext!.findRenderObject()
              as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      return byteData?.buffer.asUint8List();
    } catch (e) {
      // print('Error capturing invoice image: $e');
      return null;
    }
  }

  Future<Uint8List?> _loadLogoBytes() async {
    try {
      final ByteData data = await rootBundle.load('assets/images/logo.png');
      return data.buffer.asUint8List();
    } catch (e) {
      // print('Error loading logo: $e');
      return null;
    }
  }
}
