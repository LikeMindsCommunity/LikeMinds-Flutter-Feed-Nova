import 'package:flutter/material.dart';
import 'package:likeminds_feed/likeminds_feed.dart';

class SetupLMFeedRequest {
  String apiKey;
  LMSDKCallback? lmCallBack;
  GlobalKey<NavigatorState>? navigatorKey;
  InitiateLoggerRequest? initiateLoggerRequest;

  SetupLMFeedRequest._({
    required this.apiKey,
    this.lmCallBack,
    this.navigatorKey,
    this.initiateLoggerRequest,
  });
}

class SetupLMFeedRequestBuilder {
  String? _apiKey;
  LMSDKCallback? _lmCallBack;
  GlobalKey<NavigatorState>? _navigatorKey;
  InitiateLoggerRequest? _initiateLoggerRequest;

  void apiKey(String apiKey) {
    _apiKey = apiKey;
  }

  void lmCallBack(LMSDKCallback lmCallBack) {
    _lmCallBack = lmCallBack;
  }

  void navigatorKey(GlobalKey<NavigatorState> navigatorKey) {
    _navigatorKey = navigatorKey;
  }

  void initiateLoggerRequest(InitiateLoggerRequest initiateLoggerRequest) {
    _initiateLoggerRequest = initiateLoggerRequest;
  }

  SetupLMFeedRequest build() {
    if (_apiKey == null) {
      throw Exception("API Key cannot be null");
    }

    return SetupLMFeedRequest._(
      apiKey: _apiKey!,
      lmCallBack: _lmCallBack,
      navigatorKey: _navigatorKey,
      initiateLoggerRequest: _initiateLoggerRequest,
    );
  }
}
