import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

// Data Models
class Proposal {
  final String id;
  final String clientName;
  final String clientEmail;
  final String subject;
  final String type;
  final double value;
  final String status; // 'draft', 'sent', 'responded', 'scheduled', 'rejected'
  final DateTime sentDate;
  final DateTime? responseDate;
  final String? messageBody;
  final DateTime createdAt;
  final DateTime updatedAt;

  Proposal({
    required this.id,
    required this.clientName,
    required this.clientEmail,
    required this.subject,
    required this.type,
    required this.value,
    required this.status,
    required this.sentDate,
    this.responseDate,
    this.messageBody,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Proposal.fromMap(Map<String, dynamic> data, String id) {
    return Proposal(
      id: id,
      clientName: data['clientName'] ?? '',
      clientEmail: data['clientEmail'] ?? '',
      subject: data['subject'] ?? '',
      type: data['type'] ?? '',
      value: (data['value'] ?? 0).toDouble(),
      status: data['status'] ?? 'draft',
      sentDate: (data['sentDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      responseDate: (data['responseDate'] as Timestamp?)?.toDate(),
      messageBody: data['messageBody'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'clientName': clientName,
      'clientEmail': clientEmail,
      'subject': subject,
      'type': type,
      'value': value,
      'status': status,
      'sentDate': Timestamp.fromDate(sentDate),
      'responseDate': responseDate != null
          ? Timestamp.fromDate(responseDate!)
          : null,
      'messageBody': messageBody,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}

class Appointment {
  final String id;
  final String clientName;
  final String clientEmail;
  final String type;
  final DateTime date;
  final String time;
  final int duration; // in minutes
  final String status; // 'pending', 'confirmed', 'completed', 'cancelled'
  final String? meetingLink;
  final String? notes;
  final String meetingFormat; // 'In-Person' or 'Call'
  final DateTime createdAt;
  final DateTime updatedAt;

  Appointment({
    required this.id,
    required this.clientName,
    required this.clientEmail,
    required this.type,
    required this.date,
    required this.time,
    required this.duration,
    required this.status,
    this.meetingLink,
    this.notes,
    this.meetingFormat = 'In-Person', // Default to In-Person
    required this.createdAt,
    required this.updatedAt,
  });

  factory Appointment.fromMap(Map<String, dynamic> data, String id) {
    return Appointment(
      id: id,
      clientName: data['clientName'] ?? '',
      clientEmail: data['clientEmail'] ?? '',
      type: data['type'] ?? '',
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      time: data['time'] ?? '',
      duration: data['duration'] ?? 30,
      status: data['status'] ?? 'pending',
      meetingLink: data['meetingLink'],
      notes: data['notes'],
      meetingFormat: data['meetingFormat'] ?? 'In-Person',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'clientName': clientName,
      'clientEmail': clientEmail,
      'type': type,
      'date': Timestamp.fromDate(date),
      'time': time,
      'duration': duration,
      'status': status,
      'meetingLink': meetingLink,
      'notes': notes,
      'meetingFormat': meetingFormat,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}

class MarketingStats {
  final int totalProposals;
  final int proposalsThisWeek;
  final int totalAppointments;
  final int appointmentsThisWeek;
  final double responseRate;
  final double responseRateChange;

  MarketingStats({
    required this.totalProposals,
    required this.proposalsThisWeek,
    required this.totalAppointments,
    required this.appointmentsThisWeek,
    required this.responseRate,
    required this.responseRateChange,
  });
}

class MarketingService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _proposalsCollection = 'proposals';
  static const String _appointmentsCollection = 'appointments';

  // Proposals
  static Stream<List<Proposal>> getProposalsStream() {
    return _firestore
        .collection(_proposalsCollection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Proposal.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  static Future<List<Proposal>> getProposals() async {
    final snapshot = await _firestore
        .collection(_proposalsCollection)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => Proposal.fromMap(doc.data(), doc.id))
        .toList();
  }

  static Future<String> createProposal({
    required String clientName,
    required String clientEmail,
    required String subject,
    required String type,
    required double value,
    String? messageBody,
  }) async {
    final proposal = Proposal(
      id: '', // Will be set by Firestore
      clientName: clientName,
      clientEmail: clientEmail,
      subject: subject,
      type: type,
      value: value,
      status: 'draft',
      sentDate: DateTime.now(),
      messageBody: messageBody,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final docRef = await _firestore
        .collection(_proposalsCollection)
        .add(proposal.toMap());

    return docRef.id;
  }

  static Future<void> updateProposalStatus(
    String proposalId,
    String status,
  ) async {
    await _firestore.collection(_proposalsCollection).doc(proposalId).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
      if (status == 'responded') 'responseDate': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> updateProposal(Proposal proposal) async {
    await _firestore.collection(_proposalsCollection).doc(proposal.id).update({
      'subject': proposal.subject,
      'clientName': proposal.clientName,
      'clientEmail': proposal.clientEmail,
      'type': proposal.type,
      'value': proposal.value,
      'messageBody': proposal.messageBody,
      'status': proposal.status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> deleteProposal(String proposalId) async {
    await _firestore.collection(_proposalsCollection).doc(proposalId).delete();
  }

  // Appointments
  static Stream<List<Appointment>> getAppointmentsStream() {
    return _firestore
        .collection(_appointmentsCollection)
        .orderBy('date', descending: false)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Appointment.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  static Future<List<Appointment>> getAppointments() async {
    final snapshot = await _firestore
        .collection(_appointmentsCollection)
        .orderBy('date', descending: false)
        .get();

    return snapshot.docs
        .map((doc) => Appointment.fromMap(doc.data(), doc.id))
        .toList();
  }

  static Future<String> createAppointment({
    required String clientName,
    required String clientEmail,
    required String type,
    required DateTime date,
    required String time,
    required int duration,
    String? meetingLink,
    String? notes,
    String meetingFormat = 'In-Person',
  }) async {
    final appointment = Appointment(
      id: '', // Will be set by Firestore
      clientName: clientName,
      clientEmail: clientEmail,
      type: type,
      date: date,
      time: time,
      duration: duration,
      status: 'pending',
      meetingLink: meetingLink,
      notes: notes,
      meetingFormat: meetingFormat,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final docRef = await _firestore
        .collection(_appointmentsCollection)
        .add(appointment.toMap());

    return docRef.id;
  }

  static Future<void> updateAppointmentStatus(
    String appointmentId,
    String status,
  ) async {
    await _firestore
        .collection(_appointmentsCollection)
        .doc(appointmentId)
        .update({'status': status, 'updatedAt': FieldValue.serverTimestamp()});
  }

  static Future<void> updateAppointment({
    required String appointmentId,
    required String clientName,
    required String clientEmail,
    required String type,
    required DateTime date,
    required String time,
    required int duration,
    String? meetingLink,
    String? notes,
    String meetingFormat = 'In-Person',
  }) async {
    await _firestore
        .collection(_appointmentsCollection)
        .doc(appointmentId)
        .update({
          'clientName': clientName,
          'clientEmail': clientEmail,
          'type': type,
          'date': Timestamp.fromDate(date),
          'time': time,
          'duration': duration,
          'meetingLink': meetingLink,
          'notes': notes,
          'meetingFormat': meetingFormat,
          'updatedAt': FieldValue.serverTimestamp(),
        });
  }

  static Future<void> deleteAppointment(String appointmentId) async {
    await _firestore
        .collection(_appointmentsCollection)
        .doc(appointmentId)
        .delete();
  }

  // Statistics
  static Future<MarketingStats> getMarketingStats() async {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    final monthAgo = now.subtract(const Duration(days: 30));

    // Get proposals
    final proposalsSnapshot = await _firestore
        .collection(_proposalsCollection)
        .get();

    final proposals = proposalsSnapshot.docs
        .map((doc) => Proposal.fromMap(doc.data(), doc.id))
        .toList();

    // Get appointments
    final appointmentsSnapshot = await _firestore
        .collection(_appointmentsCollection)
        .get();

    final appointments = appointmentsSnapshot.docs
        .map((doc) => Appointment.fromMap(doc.data(), doc.id))
        .toList();

    // Calculate stats
    final totalProposals = proposals.length;
    final proposalsThisWeek = proposals
        .where((p) => p.createdAt.isAfter(weekAgo))
        .length;

    final totalAppointments = appointments.length;
    final appointmentsThisWeek = appointments
        .where((a) => a.createdAt.isAfter(weekAgo))
        .length;

    // Calculate response rate
    final sentProposals = proposals
        .where(
          (p) =>
              p.status == 'sent' ||
              p.status == 'responded' ||
              p.status == 'scheduled',
        )
        .length;
    final respondedProposals = proposals
        .where((p) => p.status == 'responded' || p.status == 'scheduled')
        .length;
    final responseRate = sentProposals > 0
        ? (respondedProposals / sentProposals) * 100
        : 0.0;

    // Calculate response rate change (this month vs previous month)
    final thisMonthProposals = proposals
        .where((p) => p.createdAt.isAfter(monthAgo))
        .toList();
    final thisMonthSent = thisMonthProposals
        .where(
          (p) =>
              p.status == 'sent' ||
              p.status == 'responded' ||
              p.status == 'scheduled',
        )
        .length;
    final thisMonthResponded = thisMonthProposals
        .where((p) => p.status == 'responded' || p.status == 'scheduled')
        .length;
    final thisMonthResponseRate = thisMonthSent > 0
        ? (thisMonthResponded / thisMonthSent) * 100
        : 0.0;

    final previousMonthProposals = proposals
        .where(
          (p) =>
              p.createdAt.isBefore(monthAgo) &&
              p.createdAt.isAfter(monthAgo.subtract(const Duration(days: 30))),
        )
        .toList();
    final previousMonthSent = previousMonthProposals
        .where(
          (p) =>
              p.status == 'sent' ||
              p.status == 'responded' ||
              p.status == 'scheduled',
        )
        .length;
    final previousMonthResponded = previousMonthProposals
        .where((p) => p.status == 'responded' || p.status == 'scheduled')
        .length;
    final previousMonthResponseRate = previousMonthSent > 0
        ? (previousMonthResponded / previousMonthSent) * 100
        : 0.0;

    final responseRateChange =
        thisMonthResponseRate - previousMonthResponseRate;

    return MarketingStats(
      totalProposals: totalProposals,
      proposalsThisWeek: proposalsThisWeek,
      totalAppointments: totalAppointments,
      appointmentsThisWeek: appointmentsThisWeek,
      responseRate: responseRate,
      responseRateChange: responseRateChange,
    );
  }

  // Helper methods
  static String formatCurrency(double amount) {
    return 'R${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
  }

  static String formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  static String formatTime(DateTime date) {
    final hour = date.hour > 12 ? date.hour - 12 : date.hour;
    final period = date.hour >= 12 ? 'PM' : 'AM';
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute $period';
  }

  static String getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'sent':
        return 'orange';
      case 'responded':
        return 'green';
      case 'scheduled':
        return 'blue';
      case 'draft':
        return 'grey';
      case 'rejected':
        return 'red';
      case 'pending':
        return 'orange';
      case 'confirmed':
        return 'green';
      case 'completed':
        return 'blue';
      case 'cancelled':
        return 'red';
      default:
        return 'grey';
    }
  }

  static IconData getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'sent':
        return Icons.email;
      case 'responded':
        return Icons.check_circle;
      case 'scheduled':
        return Icons.schedule;
      case 'draft':
        return Icons.edit;
      case 'rejected':
        return Icons.cancel;
      case 'pending':
        return Icons.pending;
      case 'confirmed':
        return Icons.check_circle;
      case 'completed':
        return Icons.done_all;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }
}
