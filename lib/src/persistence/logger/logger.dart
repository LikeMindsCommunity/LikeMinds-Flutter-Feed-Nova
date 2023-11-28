import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:likeminds_feed/likeminds_feed.dart';
import 'package:likeminds_feed_nova_fl/likeminds_feed_nova_fl.dart';
import 'package:likeminds_feed_nova_fl/src/persistence/logger/handler/handler.dart';
import 'package:likeminds_feed_nova_fl/src/persistence/logger/models/insert_log_request.dart';
import 'package:likeminds_feed_nova_fl/src/persistence/logger/schema/log_db.dart';
import 'package:likeminds_feed_nova_fl/src/services/likeminds_service.dart';
import 'package:likeminds_feed_nova_fl/src/utils/constants/package_constants.dart';
import 'package:realm/realm.dart' as realm;

// This class handles all the operations
// related to Error Logging
// Accepts a [shareLogsWithLM] boolean as parameter
// which determines whether the logs should be stored in LocalDB
// and shared with LM later or not
// Calls the errorHandler method for client if it is not null
class LMFeedLogger {
  // LogDBHandler instance to handle DB operations
  late final LogDBHandler logDBHandler;
  // shareLogsWithLM is a boolean value which determines whether the logs
  // should be stored in LocalDB and shared with LM or not
  late final bool shareLogsWithLM;
  // LMSDKMeta instance to store the SDK meta data
  // [sampleAppVersion], [middlewareVersion], [uiVersion]
  late final LMSDKMeta lmSDKMeta;

  LMFeedLogger._internal();

  static LMFeedLogger? _instance;

  static LMFeedLogger get instance => _instance ??= LMFeedLogger._internal();

  // Creates a new realm instance with all the neccessary schemas
  // and initialises the logDBHandler
  // shareLogsWithLM is a boolean value which determines whether the logs
  // should be shared with LM or not
  // Must be called only once per app lifecycle
  void initialise({bool shareLogsWithLM = true}) {
    this.shareLogsWithLM = shareLogsWithLM;
    logDBHandler = LogDBHandler(
        config: realm.Configuration.local([
      StackTraceDBModel.schema,
      SDKMetaDBModel.schema,
      LogDBModel.schema
    ]));
    lmSDKMeta = LMSDKMeta(
      sampleAppVersion: sampleAppVersion,
      middlewareVersion: middlewareVersion,
    );
  }

  // Creates a InsertLogRequest object and calls insertLog method
  // of LogDBHandler
  void insertLogs(LMStackTrace stackTrace, Severity severity) {
    int currentTimestamp = DateTime.now().millisecondsSinceEpoch;
    InsertLogRequest insertLogRequest = (InsertLogRequestBuilder()
          ..stackTrace(stackTrace)
          ..sdkMeta(lmSDKMeta)
          ..severity(severity.toString())
          ..timestamp(currentTimestamp))
        .build();
    // insert the log in DB
    logDBHandler.insertLog(insertLogRequest);
  }

  // Gets all the logs from the database
  // Maps the list of logs with DeviceDetails
  // Creates a PushLogRequest object and calls pushLogs method
  // If the response is success, then deletes the logs from the database
  // upto the current timestamp
  Future<PushLogResponse> pushLogs() async {
    int currentTimeStamp = DateTime.now().millisecondsSinceEpoch;
    PushLogResponse response;

    List<LMLogBuilder> lmLogsBuilderList =
        logDBHandler.getLogs(currentTimeStamp);

    if (lmLogsBuilderList.isEmpty) {
      return PushLogResponse(success: true);
    }

    DeviceDetailsBuilder deviceDetailsBuilder = DeviceDetailsBuilder();

    // To check whether the device is connected to wifi or not
    bool isOnWifi;

    final connectivityResult = await (Connectivity().checkConnectivity());

    if (connectivityResult == ConnectivityResult.wifi) {
      isOnWifi = true;
    } else {
      isOnWifi = false;
    }

    // To store device details
    // OS [Android or iOS]
    // OS Version
    // Device Name
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();

    if (Platform.isAndroid) {
      AndroidDeviceInfo androidDeviceInfo = await deviceInfo.androidInfo;
      deviceDetailsBuilder
        ..os('android')
        ..versionOS(androidDeviceInfo.version.release)
        ..deviceName(androidDeviceInfo.model)
        ..screenHeight(androidDeviceInfo.displayMetrics.heightPx.toInt())
        ..screenWidth(androidDeviceInfo.displayMetrics.widthPx.toInt())
        ..wifi(isOnWifi);
    } else if (Platform.isIOS) {
      IosDeviceInfo iosDeviceInfo = await deviceInfo.iosInfo;
      deviceDetailsBuilder
        ..os('ios')
        ..versionOS(iosDeviceInfo.systemVersion)
        ..deviceName(iosDeviceInfo.name)
        ..wifi(isOnWifi);
    }

    DeviceDetails deviceMeta = deviceDetailsBuilder.build();

    // Mapping LMLogBuilder list with Device Details
    // Creating LMLog list by calling build method
    List<LMLog> lmLogList = lmLogsBuilderList.map((e) {
      LMLog lmLog = (e..deviceMeta(deviceMeta)).build();
      return lmLog;
    }).toList();

    PushLogRequest pushLogRequest =
        (PushLogRequestBuilder()..logs(lmLogList)).build();

    await locator<LikeMindsService>().initiateUser((InitiateUserRequestBuilder()
          ..userId("anurag123")
          ..userName("Anurag Tyagi"))
        .build());

    response = await locator<LikeMindsService>().pushLogs(pushLogRequest);

    // Clear logs from DB if response is success
    if (response.success) {
      deleteLogs(lmLogList);
    }

    return response;
  }

  // Handles the exception
  // Calls the errorHandler method for client if it is not null
  // If shareLogsWithLM is true, then calls insertLogs method
  void handleException(String exception, StackTrace stackTrace) {
    LMStackTrace lmStackTrace = (LMStackTraceBuilder()
          ..stack(stackTrace.toString())
          ..exception(exception))
        .build();
    if (shareLogsWithLM) {
      insertLogs(lmStackTrace, Severity.ERROR);
    }
    // Call error handling callback for client
    if (LMFeed.onErrorHandler != null) {
      LMFeed.onErrorHandler!(lmStackTrace);
    }
  }

  // Deletes a list of logs from the database
  // Wrapper function for LogDBHandler
  void deleteLogs(List<LMLog> lmLogsList) {
    logDBHandler.deleteLogs(lmLogsList);
  }
}
