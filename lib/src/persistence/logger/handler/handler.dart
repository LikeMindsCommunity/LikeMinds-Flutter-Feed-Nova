import 'package:likeminds_feed_nova_fl/src/persistence/logger/models/insert_log_request.dart';
import 'package:likeminds_feed_nova_fl/src/persistence/logger/schema/log_db.dart';
import 'package:realm/realm.dart';

class LogDBHandler {
  late final Realm realm;

  LogDBHandler({required this.realm});

  void insertLog(InsertLogRequest request) {
    StackTraceDBModel stackTraceRO =
        StackTraceDBModel(request.stackTrace.error, request.stackTrace.stack);
    SDKMetaDBModel sdkMetaRO = SDKMetaDBModel(
        sampleAppVersion: request.sdkMeta?.sampleAppVersion ?? '',
        uiVersion: request.sdkMeta?.uiVersion ?? '',
        middlewareVersion: request.sdkMeta?.middlewareVersion ?? '');
    realm.add(LogDBModel(
      request.timestamp,
      stackTrace: stackTraceRO,
      sdkMeta: sdkMetaRO,
      severity: request.severity,
    ));
  }

  List<LogDBModel> getLogs(int timestamp) {
    RealmResults<LogDBModel> realmResults = realm.all<LogDBModel>();
    List<LogDBModel> logsList =
        realmResults.where((element) => element.timestamp < timestamp).toList();
    return logsList;
  }

  void deleteLogs(List<LogDBModel> logsList) async {
    realm.deleteMany(logsList);
  }
}
