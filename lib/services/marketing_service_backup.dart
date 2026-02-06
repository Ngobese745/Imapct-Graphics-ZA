import 'package:cloud_firestore/cloud_firestore.dart';

class Proposal {
  final String id;
  final String clientName;
  final String clientEmail;
  final String subject;
  final String status; // 'sent', 'responded', 'scheduled', 'draft'
  final DateTime sentDate;
  final DateTime? responseDate;
  final double value;
  final String type;
  final String messageBody;
  final DateTime createdAt;
  final DateTime updatedAt;

  Proposal({
    required this.id,
    required this.clientName,
    required this.clientEmail,
    required this.subject,
    required this.status,
    required this.sentDate,
    this.responseDate,
    required this.value,
    required this.type,
    required this.messageBody,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Proposal.fromMap(Map<String, dynamic> data, String id) {
    return Proposal(
      id: id,
      clientName: data['clientName'] ?? '',
      clientEmail: data['clientEmail'] ?? '',
      subject: data['subject'] ?? '',
      status: data['status'] ?? 'draft',
      sentDate: (data['sentDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      responseDate: (data['responseDate'] as Timestamp?)?.toDate(),
      value: (data['value'] ?? 0).toDouble(),
      type: data['type'] ?? '',
      messageBody: data['messageBody'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'clientName': clientName,
      'clientEmail': clientEmail,
      'subject': subject,
      'status': status,
      'sentDate': Timestamp.fromDate(sentDate),
      'responseDate': responseDate != null
          ? Timestamp.fromDate(responseDate!)
          : null,
      'value': value,
      'type': type,
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
  final String status; // 'confirmed', 'pending', 'cancelled', 'completed'
  final String? meetingLink;
  final String? notes;
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
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}

class MarketingService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Proposals Collection
  static const String _proposalsCollection = 'proposals';
  static const String _appointmentsCollection = 'appointments';

  // Create a new proposal
  static Future<String> createProposal({
    required String clientName,
    required String clientEmail,
    required String subject,
    required String type,
    required double value,
    required String messageBody,
  }) async {
    try {
      final proposal = Proposal(
        id: '', // Will be set by Firestore
        clientName: clientName,
        clientEmail: clientEmail,
        subject: subject,
        status: 'draft',
        sentDate: DateTime.now(),
        value: value,
        type: type,
        messageBody: messageBody,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final docRef = await _firestore
          .collection(_proposalsCollection)
          .add(proposal.toMap());

      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create proposal: $e');
    }
  }

  // Send a proposal (update status to 'sent')
  static Future<void> sendProposal(String proposalId) async {
    try {
      await _firestore.collection(_proposalsCollection).doc(proposalId).update({
        'status': 'sent',
        'sentDate': Timestamp.fromDate(DateTime.now()),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      throw Exception('Failed to send proposal: $e');
    }
  }

  // Mark proposal as responded
  static Future<void> markProposalResponded(String proposalId) async {
    try {
      await _firestore.collection(_proposalsCollection).doc(proposalId).update({
        'status': 'responded',
        'responseDate': Timestamp.fromDate(DateTime.now()),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      throw Exception('Failed to mark proposal as responded: $e');
    }
  }

  // Get all proposals (real-time stream)
  static Stream<List<Proposal>> getProposals() {
    return _firestore
        .collection(_proposalsCollection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return Proposal.fromMap(doc.data(), doc.id);
          }).toList();
        });
  }

  // Get proposals by status
  static Stream<List<Proposal>> getProposalsByStatus(String status) {
    return _firestore
        .collection(_proposalsCollection)
        .where('status', isEqualTo: status)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return Proposal.fromMap(doc.data(), doc.id);
          }).toList();
        });
  }

  // Create a new appointment
  static Future<String> createAppointment({
    required String clientName,
    required String clientEmail,
    required String type,
    required DateTime date,
    required String time,
    required int duration,
    String? meetingLink,
    String? notes,
  }) async {
    try {
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
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final docRef = await _firestore
          .collection(_appointmentsCollection)
          .add(appointment.toMap());

      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create appointment: $e');
    }
  }

  // Update appointment status
  static Future<void> updateAppointmentStatus(
    String appointmentId,
    String status,
  ) async {
    try {
      await _firestore
          .collection(_appointmentsCollection)
          .doc(appointmentId)
          .update({
            'status': status,
            'updatedAt': Timestamp.fromDate(DateTime.now()),
          });
    } catch (e) {
      throw Exception('Failed to update appointment status: $e');
    }
  }

  // Get all appointments (real-time stream)
  static Stream<List<Appointment>> getAppointments() {
    return _firestore
        .collection(_appointmentsCollection)
        .orderBy('date', descending: false)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return Appointment.fromMap(doc.data(), doc.id);
          }).toList();
        });
  }

  // Get appointments by status
  static Stream<List<Appointment>> getAppointmentsByStatus(String status) {
    return _firestore
        .collection(_appointmentsCollection)
        .where('status', isEqualTo: status)
        .orderBy('date', descending: false)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return Appointment.fromMap(doc.data(), doc.id);
          }).toList();
        });
  }

  // Get upcoming appointments (next 7 days)
  static Stream<List<Appointment>> getUpcomingAppointments() {
    final now = DateTime.now();
    final nextWeek = now.add(const Duration(days: 7));

    return _firestore
        .collection(_appointmentsCollection)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(now))
        .where('date', isLessThan: Timestamp.fromDate(nextWeek))
        .orderBy('date', descending: false)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return Appointment.fromMap(doc.data(), doc.id);
          }).toList();
        });
  }

  // Get marketing statistics
  static Future<Map<String, dynamic>> getMarketingStats() async {
    try {
      // Get proposals count
      final proposalsSnapshot = await _firestore
          .collection(_proposalsCollection)
          .get();

      final proposals = proposalsSnapshot.docs.map((doc) {
        return Proposal.fromMap(doc.data(), doc.id);
      }).toList();

      // Get appointments count
      final appointmentsSnapshot = await _firestore
          .collection(_appointmentsCollection)
          .get();

      final appointments = appointmentsSnapshot.docs.map((doc) {
        return Appointment.fromMap(doc.data(), doc.id);
      }).toList();

      // Calculate statistics
      final totalProposals = proposals.length;
      final sentProposals = proposals.where((p) => p.status == 'sent').length;
      final respondedProposals = proposals
          .where((p) => p.status == 'responded')
          .length;
      final responseRate = totalProposals > 0
          ? (respondedProposals / totalProposals * 100).round()
          : 0;

      final totalAppointments = appointments.length;
      final confirmedAppointments = appointments
          .where((a) => a.status == 'confirmed')
          .length;
      final upcomingAppointments = appointments
          .where(
            (a) =>
                a.date.isAfter(DateTime.now()) &&
                a.status != 'cancelled' &&
                a.status != 'completed',
          )
          .length;

      // This week's proposals
      final weekAgo = DateTime.now().subtract(const Duration(days: 7));
      final thisWeekProposals = proposals
          .where((p) => p.createdAt.isAfter(weekAgo))
          .length;

      // This week's appointments
      final thisWeekAppointments = appointments
          .where((a) => a.createdAt.isAfter(weekAgo))
          .length;

      return {
        'totalProposals': totalProposals,
        'sentProposals': sentProposals,
        'respondedProposals': respondedProposals,
        'responseRate': responseRate,
        'totalAppointments': totalAppointments,
        'confirmedAppointments': confirmedAppointments,
        'upcomingAppointments': upcomingAppointments,
        'thisWeekProposals': thisWeekProposals,
        'thisWeekAppointments': thisWeekAppointments,
      };
    } catch (e) {
      throw Exception('Failed to get marketing stats: $e');
    }
  }

  // Get real-time marketing statistics stream
  static Stream<Map<String, dynamic>> getMarketingStatsStream() {
    return Stream.periodic(const Duration(seconds: 30)).asyncMap((_) async {
      return await getMarketingStats();
    });
  }

  // Delete proposal
  static Future<void> deleteProposal(String proposalId) async {
    try {
      await _firestore
          .collection(_proposalsCollection)
          .doc(proposalId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete proposal: $e');
    }
  }

  // Delete appointment
  static Future<void> deleteAppointment(String appointmentId) async {
    try {
      await _firestore
          .collection(_appointmentsCollection)
          .doc(appointmentId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete appointment: $e');
    }
  }
}
