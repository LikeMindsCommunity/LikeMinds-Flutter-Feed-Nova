import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:likeminds_feed_nova_fl/likeminds_feed_nova_fl.dart';
import 'package:likeminds_feed_nova_fl/src/services/likeminds_service.dart';

final GetIt locator = GetIt.I;

final GlobalKey<NavigatorState> serviceNavigatorKey =
    GlobalKey<NavigatorState>();

void _setupLocator(SetupLMFeedRequest setupLMFeedRequest) {
  locator.allowReassignment = true;

  if (!locator.isRegistered<LikeMindsService>()) {
    locator.registerSingleton(LikeMindsService(setupLMFeedRequest));
  }
  if (!locator.isRegistered<NavigationService>()) {
    locator.registerSingleton(NavigationService(
      navigatorKey: setupLMFeedRequest.navigatorKey ?? serviceNavigatorKey,
    ));
  }
  if (!locator.isRegistered<BlocService>()) {
    locator.registerSingleton(BlocService());
  }
}

void setupLMFeed(SetupLMFeedRequest setupLMFeedRequest) {
  _setupLocator(setupLMFeedRequest);
}
