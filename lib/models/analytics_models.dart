import 'package:cloud_firestore/cloud_firestore.dart';

class UserSession {
  final String sessionId;
  final String userId;
  final DateTime startTime;
  final DateTime? endTime;
  final String deviceType;
  final String os;
  final String appVersion;

  UserSession({
    required this.sessionId,
    required this.userId,
    required this.startTime,
    this.endTime,
    required this.deviceType,
    required this.os,
    required this.appVersion,
  });

  Map<String, dynamic> toMap() {
    return {
      'sessionId': sessionId,
      'userId': userId,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'deviceType': deviceType,
      'os': os,
      'appVersion': appVersion,
    };
  }

  factory UserSession.fromMap(Map<String, dynamic> map) {
    return UserSession(
      sessionId: map['sessionId'] as String,
      userId: map['userId'] as String,
      startTime: DateTime.parse(map['startTime'] as String),
      endTime: map['endTime'] != null ? DateTime.parse(map['endTime'] as String) : null,
      deviceType: map['deviceType'] as String,
      os: map['os'] as String,
      appVersion: map['appVersion'] as String,
    );
  }
}

class AppUsageEvent {
  final String eventId;
  final String userId;
  final String sessionId;
  final String eventName;
  final Map<String, dynamic>? parameters;
  final DateTime timestamp;

  AppUsageEvent({
    required this.eventId,
    required this.userId,
    required this.sessionId,
    required this.eventName,
    this.parameters,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'eventId': eventId,
      'userId': userId,
      'sessionId': sessionId,
      'eventName': eventName,
      'parameters': parameters,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory AppUsageEvent.fromMap(Map<String, dynamic> map) {
    return AppUsageEvent(
      eventId: map['eventId'] as String,
      userId: map['userId'] as String,
      sessionId: map['sessionId'] as String,
      eventName: map['eventName'] as String,
      parameters: map['parameters'] as Map<String, dynamic>?,
      timestamp: DateTime.parse(map['timestamp'] as String),
    );
  }
}

class FeatureUsage {
  final String featureName;
  final String userId;
  final DateTime timestamp;
  final int count;

  FeatureUsage({
    required this.featureName,
    required this.userId,
    required this.timestamp,
    required this.count,
  });

  Map<String, dynamic> toMap() {
    return {
      'featureName': featureName,
      'userId': userId,
      'timestamp': Timestamp.fromDate(timestamp),
      'count': count,
    };
  }

  factory FeatureUsage.fromMap(Map<String, dynamic> map) {
    return FeatureUsage(
      featureName: map['featureName'] as String,
      userId: map['userId'] as String,
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      count: map['count'] as int,
    );
  }
}

class ErrorLog {
  final String errorId;
  final String userId;
  final String sessionId;
  final String message;
  final String stackTrace;
  final DateTime timestamp;

  ErrorLog({
    required this.errorId,
    required this.userId,
    required this.sessionId,
    required this.message,
    required this.stackTrace,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'errorId': errorId,
      'userId': userId,
      'sessionId': sessionId,
      'message': message,
      'stackTrace': stackTrace,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory ErrorLog.fromMap(Map<String, dynamic> map) {
    return ErrorLog(
      errorId: map['errorId'] as String,
      userId: map['userId'] as String,
      sessionId: map['sessionId'] as String,
      message: map['message'] as String,
      stackTrace: map['stackTrace'] as String,
      timestamp: DateTime.parse(map['timestamp'] as String),
    );
  }
}

class PerformanceMetric {
  final String metricId;
  final String userId;
  final String sessionId;
  final String metricName;
  final double value;
  final DateTime timestamp;

  PerformanceMetric({
    required this.metricId,
    required this.userId,
    required this.sessionId,
    required this.metricName,
    required this.value,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'metricId': metricId,
      'userId': userId,
      'sessionId': sessionId,
      'metricName': metricName,
      'value': value,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory PerformanceMetric.fromMap(Map<String, dynamic> map) {
    return PerformanceMetric(
      metricId: map['metricId'] as String,
      userId: map['userId'] as String,
      sessionId: map['sessionId'] as String,
      metricName: map['metricName'] as String,
      value: map['value'] as double,
      timestamp: DateTime.parse(map['timestamp'] as String),
    );
  }
}

class RevenueEvent {
  final String eventId;
  final String userId;
  final double amount;
  final String currency;
  final String? orderId;
  final DateTime timestamp;

  RevenueEvent({
    required this.eventId,
    required this.userId,
    required this.amount,
    required this.currency,
    this.orderId,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'eventId': eventId,
      'userId': userId,
      'amount': amount,
      'currency': currency,
      'orderId': orderId,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory RevenueEvent.fromMap(Map<String, dynamic> map) {
    return RevenueEvent(
      eventId: map['eventId'] as String,
      userId: map['userId'] as String,
      amount: (map['amount'] as num).toDouble(),
      currency: map['currency'] as String,
      orderId: map['orderId'] as String?,
      timestamp: DateTime.parse(map['timestamp'] as String),
    );
  }
}

class BusinessMetric {
  final String metricName;
  final double value;
  final DateTime timestamp;

  BusinessMetric({
    required this.metricName,
    required this.value,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'metricName': metricName,
      'value': value,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  factory BusinessMetric.fromMap(Map<String, dynamic> map) {
    return BusinessMetric(
      metricName: map['metricName'] as String,
      value: (map['value'] as num).toDouble(),
      timestamp: (map['timestamp'] as Timestamp).toDate(),
    );
  }
}
