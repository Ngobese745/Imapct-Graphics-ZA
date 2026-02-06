import 'package:flutter/material.dart';
import '../services/app_analytics_initializer.dart';

class AnalyticsTracker extends StatefulWidget {
  final Widget child;
  final String screenName;
  final Map<String, dynamic>? parameters;

  const AnalyticsTracker({
    Key? key,
    required this.child,
    required this.screenName,
    this.parameters,
  }) : super(key: key);

  @override
  State<AnalyticsTracker> createState() => _AnalyticsTrackerState();
}

class _AnalyticsTrackerState extends State<AnalyticsTracker> {
  final AppAnalyticsInitializer _analyticsInitializer = AppAnalyticsInitializer();

  @override
  void initState() {
    super.initState();
    _trackScreenView();
  }

  @override
  void didUpdateWidget(AnalyticsTracker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.screenName != widget.screenName) {
      _trackScreenView();
    }
  }

  void _trackScreenView() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _analyticsInitializer.trackScreenNavigation(widget.screenName);
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

// Mixin for automatic analytics tracking in StatefulWidgets
mixin AnalyticsMixin<T extends StatefulWidget> on State<T> {
  final AppAnalyticsInitializer _analyticsInitializer = AppAnalyticsInitializer();

  void trackScreenView(String screenName, {Map<String, dynamic>? parameters}) {
    _analyticsInitializer.trackScreenNavigation(screenName);
  }

  void trackFeatureUsage(String featureName) {
    _analyticsInitializer.trackFeatureUsage(featureName);
  }

  void trackBusinessEvent(String eventType, Map<String, dynamic> parameters) {
    _analyticsInitializer.trackBusinessEvent(eventType, parameters);
  }

  void trackOrderCompletion({
    required String orderId,
    required double amount,
    required String serviceType,
  }) {
    _analyticsInitializer.trackOrderCompletion(
      orderId: orderId,
      amount: amount,
      serviceType: serviceType,
    );
  }

  void trackConsultationRequest(String consultationId) {
    _analyticsInitializer.trackConsultationRequest(consultationId);
  }

  void trackPerformanceMetric(String metricName, double value) {
    _analyticsInitializer.trackPerformanceMetric(metricName, value);
  }

  void trackError(String message, String stackTrace) {
    _analyticsInitializer.trackError(message, stackTrace);
  }
}

// Widget for tracking button taps
class AnalyticsButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final String eventName;
  final Map<String, dynamic>? parameters;
  final AppAnalyticsInitializer _analyticsInitializer = AppAnalyticsInitializer();

  AnalyticsButton({
    Key? key,
    required this.child,
    required this.onPressed,
    required this.eventName,
    this.parameters,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        _analyticsInitializer.trackBusinessEvent(eventName, parameters ?? {});
        onPressed?.call();
      },
      child: child,
    );
  }
}

// Widget for tracking form submissions
class AnalyticsForm extends StatefulWidget {
  final Widget child;
  final String formName;
  final Map<String, dynamic>? parameters;

  const AnalyticsForm({
    Key? key,
    required this.child,
    required this.formName,
    this.parameters,
  }) : super(key: key);

  @override
  State<AnalyticsForm> createState() => _AnalyticsFormState();
}

class _AnalyticsFormState extends State<AnalyticsForm> {
  final AppAnalyticsInitializer _analyticsInitializer = AppAnalyticsInitializer();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: widget.child,
    );
  }

  void submitForm() {
    if (_formKey.currentState?.validate() ?? false) {
      _analyticsInitializer.trackBusinessEvent('form_submitted', {
        'form_name': widget.formName,
        ...?widget.parameters,
      });
    }
  }
}
