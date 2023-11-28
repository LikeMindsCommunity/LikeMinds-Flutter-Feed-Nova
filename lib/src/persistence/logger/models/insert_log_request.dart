import 'package:likeminds_feed/likeminds_feed.dart';

// Used to insert logs in the DB
// Accepts a [LMStackTrace] object as parameter
// [sdkMeta] is optional
// [severity] is optional
// [timestamp] is required and must be unique
class InsertLogRequest {
  final LMStackTrace stackTrace;
  final LMSDKMeta? sdkMeta;
  final String? severity;
  final int timestamp;

  InsertLogRequest._({
    required this.stackTrace,
    this.sdkMeta,
    this.severity,
    required this.timestamp,
  });
}

// Builder class for InsertLogRequest
// Accepts a [LMStackTrace] object as parameter
// [sdkMeta] is optional
// [severity] is optional
// [timestamp] is required and must be unique
class InsertLogRequestBuilder {
  LMStackTrace? _stackTrace;
  LMSDKMeta? _sdkMeta;
  String? _severity;
  int? _timestamp;

  void stackTrace(LMStackTrace stackTrace) {
    _stackTrace = stackTrace;
  }

  void sdkMeta(LMSDKMeta sdkMeta) {
    _sdkMeta = sdkMeta;
  }

  void severity(String severity) {
    _severity = severity;
  }

  void timestamp(int timestamp) {
    _timestamp = timestamp;
  }

  InsertLogRequest build() {
    return InsertLogRequest._(
      stackTrace: _stackTrace!,
      sdkMeta: _sdkMeta,
      severity: _severity,
      timestamp: _timestamp!,
    );
  }
}
