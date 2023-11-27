import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:likeminds_feed/likeminds_feed.dart';
import 'package:likeminds_feed_nova_fl/likeminds_feed_nova_fl.dart';
import 'package:likeminds_feed_nova_fl/src/persistence/logger/handler/handler.dart';
import 'package:likeminds_feed_nova_fl/src/persistence/logger/models/insert_log_request.dart';
import 'package:likeminds_feed_nova_fl/src/persistence/logger/schema/log_db.dart';
import 'package:likeminds_feed_nova_fl/src/utils/network_handling.dart';
import 'package:realm/realm.dart';

class LMFeedLogger {
  late final Realm realm;
  late final LogDBHandler logDBHandler;
  late final bool shareLogsWithLM;

  LMFeedLogger._internal();

  static LMFeedLogger? _instance;

  static LMFeedLogger get instance => _instance ??= LMFeedLogger._internal();

  void initialise({bool shareLogsWithLM = true}) {
    this.shareLogsWithLM = shareLogsWithLM;
    realm = Realm(Configuration.local([LogDBModel.schema]));
    logDBHandler = LogDBHandler(realm: realm);
  }

  void openLogger() {
    realm = Realm(Configuration.local([LogDBModel.schema]));
  }

  void closeLogger() {
    realm.close();
  }

  void insertLogs(LMStackTrace stackTrace, Severity severity) {
    int currentTimestamp = DateTime.now().millisecondsSinceEpoch;
    InsertLogRequest insertLogRequest = (InsertLogRequestBuilder()
          ..stackTrace(stackTrace)
          ..severity(severity.toString())
          ..timestamp(currentTimestamp))
        .build();

    logDBHandler.insertLog(insertLogRequest);
  }

  Future<PushLogResponse> pushLogs() async {
    int currentTimeStamp = DateTime.now().millisecondsSinceEpoch;
    var response;

    List<LogDBModel> logsList = logDBHandler.getLogs(currentTimeStamp);

    if (logsList.isEmpty) {
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
        ..os(androidDeviceInfo.version.sdkInt.toString())
        ..versionOS(androidDeviceInfo.version.release)
        ..deviceName(androidDeviceInfo.model)
        ..wifi(isOnWifi);
    } else if (Platform.isIOS) {
      IosDeviceInfo iosDeviceInfo = await deviceInfo.iosInfo;
      deviceDetailsBuilder
        ..os(iosDeviceInfo.systemName)
        ..versionOS(iosDeviceInfo.systemVersion)
        ..deviceName(iosDeviceInfo.name)
        ..wifi(isOnWifi);
    }

    DeviceDetails deviceDetails = deviceDetailsBuilder.build();

    // Converting LogDBModel to LMLog while
    // Mapping LMLog list with Device Details
    List<LMLog> lmLogList = logsList.map((e) {
      LMStackTrace stackTrace = (LMStackTraceBuilder()
            ..error(e.stackTrace?.exception ?? "")
            ..stack(e.stackTrace?.trace ?? ""))
          .build();

      LMSDKMeta sdkMeta = (LMSDKMetaBuilder()
            ..middlewareVersion(e.sdkMeta?.middlewareVersion ?? "")
            ..sampleAppVersion(e.sdkMeta?.sampleAppVersion ?? "")
            ..uiVersion(e.sdkMeta?.uiVersion ?? ""))
          .build();

      return LMLog(
          timestamp: e.timestamp,
          deviceDetails: deviceDetails,
          stackTrace: stackTrace,
          sdkMeta: sdkMeta);
    }).toList();

    PushLogRequest pushLogRequest =
        (PushLogRequestBuilder()..logs(lmLogList)).build();

    response = locator<LMFeedClient>().pushLogs(pushLogRequest);

    if (response.success) {
      deleteLogs(logsList);
    }

    return response;
  }

  Future handleException(String error, StackTrace stackTrace) async {
    LMStackTrace lmStackTrace = (LMStackTraceBuilder()
          ..stack(stackTrace.toString())
          ..error(error))
        .build();
    if (shareLogsWithLM) {
      insertLogs(lmStackTrace, Severity.ERROR);
    }
    // TODO: Call error handling callback for client
    if (LMFeed.onErrorHandler != null) {
      LMFeed.onErrorHandler!(lmStackTrace);
    }
  }

  void deleteLogs(List<LogDBModel> logsList) {
    realm.deleteMany(logsList);
  }
}
