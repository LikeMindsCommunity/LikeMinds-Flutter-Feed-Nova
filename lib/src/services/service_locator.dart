import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:likeminds_feed/likeminds_feed.dart';
import 'package:likeminds_feed_nova_fl/likeminds_feed_nova_fl.dart';
import 'package:likeminds_feed_nova_fl/src/persistence/logger/logger.dart';
import 'package:likeminds_feed_nova_fl/src/services/bloc_service.dart';
import 'package:likeminds_feed_nova_fl/src/services/likeminds_service.dart';
import 'package:likeminds_feed_nova_fl/src/services/navigation_service.dart';

final GetIt locator = GetIt.I;

final GlobalKey<NavigatorState> serviceNavigatorKey =
    GlobalKey<NavigatorState>();

void _setupLocator(
    LMSDKCallback? callback,
    String apiKey,
    GlobalKey<NavigatorState>? navigatorKey,
    bool shareLogsWithLM,
    Function(LMStackTrace)? onErrorHandler) {
  locator.allowReassignment = true;
  if (!locator.isRegistered<LikeMindsService>()) {
    locator.registerSingleton(LikeMindsService(callback, apiKey));
  }
  if (!locator.isRegistered<NavigationService>()) {
    locator.registerSingleton(
        NavigationService(navigatorKey: navigatorKey ?? serviceNavigatorKey));
  }
  if (!locator.isRegistered<BlocService>()) {
    locator.registerSingleton(BlocService());
  }
  if (!locator.isRegistered<LMFeedLogger>()) {
    LMFeedLogger logger = LMFeedLogger.instance;
    LMFeed.shareErrorLogsWithLM = shareLogsWithLM;
    LMFeed.onErrorHandler = onErrorHandler;
    logger.initialise(shareLogsWithLM: shareLogsWithLM);
    locator.registerSingleton(logger);

    locator.registerSingleton(LMSDKMeta(
      sampleAppVersion: "0.8.2",
    ));
  }
}

void setupLMFeed(LMSDKCallback? callback, String apiKey,
    {GlobalKey<NavigatorState>? navigatorKey,
    bool shareLogsWithLM = true,
    Function(LMStackTrace)? onErrorHandler}) {
  _setupLocator(
      callback, apiKey, navigatorKey, shareLogsWithLM, onErrorHandler);
}
