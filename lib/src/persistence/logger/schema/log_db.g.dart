// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'log_db.dart';

// **************************************************************************
// RealmObjectGenerator
// **************************************************************************

// ignore_for_file: type=lint
class LogDBModel extends _LogDBModel
    with RealmEntity, RealmObjectBase, RealmObject {
  LogDBModel(
    int timestamp, {
    StackTraceDBModel? stackTrace,
    SDKMetaDBModel? sdkMeta,
    String? severity,
  }) {
    RealmObjectBase.set(this, 'timestamp', timestamp);
    RealmObjectBase.set(this, 'stack_trace', stackTrace);
    RealmObjectBase.set(this, 'sdk_meta', sdkMeta);
    RealmObjectBase.set(this, 'severity', severity);
  }

  LogDBModel._();

  @override
  int get timestamp => RealmObjectBase.get<int>(this, 'timestamp') as int;
  @override
  set timestamp(int value) => throw RealmUnsupportedSetError();

  @override
  StackTraceDBModel? get stackTrace =>
      RealmObjectBase.get<StackTraceDBModel>(this, 'stack_trace')
          as StackTraceDBModel?;
  @override
  set stackTrace(covariant StackTraceDBModel? value) =>
      throw RealmUnsupportedSetError();

  @override
  SDKMetaDBModel? get sdkMeta =>
      RealmObjectBase.get<SDKMetaDBModel>(this, 'sdk_meta') as SDKMetaDBModel?;
  @override
  set sdkMeta(covariant SDKMetaDBModel? value) =>
      throw RealmUnsupportedSetError();

  @override
  String? get severity =>
      RealmObjectBase.get<String>(this, 'severity') as String?;
  @override
  set severity(String? value) => throw RealmUnsupportedSetError();

  @override
  Stream<RealmObjectChanges<LogDBModel>> get changes =>
      RealmObjectBase.getChanges<LogDBModel>(this);

  @override
  LogDBModel freeze() => RealmObjectBase.freezeObject<LogDBModel>(this);

  static SchemaObject get schema => _schema ??= _initSchema();
  static SchemaObject? _schema;
  static SchemaObject _initSchema() {
    RealmObjectBase.registerFactory(LogDBModel._);
    return const SchemaObject(
        ObjectType.realmObject, LogDBModel, 'LogDBModel', [
      SchemaProperty('timestamp', RealmPropertyType.int, primaryKey: true),
      SchemaProperty('stackTrace', RealmPropertyType.object,
          mapTo: 'stack_trace',
          optional: true,
          linkTarget: 'StackTraceDBModel'),
      SchemaProperty('sdkMeta', RealmPropertyType.object,
          mapTo: 'sdk_meta', optional: true, linkTarget: 'SDKMetaDBModel'),
      SchemaProperty('severity', RealmPropertyType.string, optional: true),
    ]);
  }
}

// ignore_for_file: type=lint
class SDKMetaDBModel extends _SDKMetaDBModel
    with RealmEntity, RealmObjectBase, RealmObject {
  SDKMetaDBModel({
    String? sampleAppVersion,
    String? uiVersion,
    String? middlewareVersion,
  }) {
    RealmObjectBase.set(this, 'sample_app_version', sampleAppVersion);
    RealmObjectBase.set(this, 'ui_version', uiVersion);
    RealmObjectBase.set(this, 'middleware_version', middlewareVersion);
  }

  SDKMetaDBModel._();

  @override
  String? get sampleAppVersion =>
      RealmObjectBase.get<String>(this, 'sample_app_version') as String?;
  @override
  set sampleAppVersion(String? value) => throw RealmUnsupportedSetError();

  @override
  String? get uiVersion =>
      RealmObjectBase.get<String>(this, 'ui_version') as String?;
  @override
  set uiVersion(String? value) => throw RealmUnsupportedSetError();

  @override
  String? get middlewareVersion =>
      RealmObjectBase.get<String>(this, 'middleware_version') as String?;
  @override
  set middlewareVersion(String? value) => throw RealmUnsupportedSetError();

  @override
  Stream<RealmObjectChanges<SDKMetaDBModel>> get changes =>
      RealmObjectBase.getChanges<SDKMetaDBModel>(this);

  @override
  SDKMetaDBModel freeze() => RealmObjectBase.freezeObject<SDKMetaDBModel>(this);

  static SchemaObject get schema => _schema ??= _initSchema();
  static SchemaObject? _schema;
  static SchemaObject _initSchema() {
    RealmObjectBase.registerFactory(SDKMetaDBModel._);
    return const SchemaObject(
        ObjectType.realmObject, SDKMetaDBModel, 'SDKMetaDBModel', [
      SchemaProperty('sampleAppVersion', RealmPropertyType.string,
          mapTo: 'sample_app_version', optional: true),
      SchemaProperty('uiVersion', RealmPropertyType.string,
          mapTo: 'ui_version', optional: true),
      SchemaProperty('middlewareVersion', RealmPropertyType.string,
          mapTo: 'middleware_version', optional: true),
    ]);
  }
}

// ignore_for_file: type=lint
class StackTraceDBModel extends _StackTraceDBModel
    with RealmEntity, RealmObjectBase, RealmObject {
  StackTraceDBModel(
    String exception,
    String trace,
  ) {
    RealmObjectBase.set(this, 'exception', exception);
    RealmObjectBase.set(this, 'trace', trace);
  }

  StackTraceDBModel._();

  @override
  String get exception =>
      RealmObjectBase.get<String>(this, 'exception') as String;
  @override
  set exception(String value) => throw RealmUnsupportedSetError();

  @override
  String get trace => RealmObjectBase.get<String>(this, 'trace') as String;
  @override
  set trace(String value) => throw RealmUnsupportedSetError();

  @override
  Stream<RealmObjectChanges<StackTraceDBModel>> get changes =>
      RealmObjectBase.getChanges<StackTraceDBModel>(this);

  @override
  StackTraceDBModel freeze() =>
      RealmObjectBase.freezeObject<StackTraceDBModel>(this);

  static SchemaObject get schema => _schema ??= _initSchema();
  static SchemaObject? _schema;
  static SchemaObject _initSchema() {
    RealmObjectBase.registerFactory(StackTraceDBModel._);
    return const SchemaObject(
        ObjectType.realmObject, StackTraceDBModel, 'StackTraceDBModel', [
      SchemaProperty('exception', RealmPropertyType.string),
      SchemaProperty('trace', RealmPropertyType.string),
    ]);
  }
}
