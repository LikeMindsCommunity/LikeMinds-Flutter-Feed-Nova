import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:likeminds_feed_flutter_core/likeminds_feed_core.dart';
import 'package:likeminds_feed_nova_sample/cred_screen.dart';
import 'package:likeminds_feed_nova_sample/firebase_options.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:device_info_plus/device_info_plus.dart';

bool initialURILinkHandled = false;
const debug = bool.fromEnvironment('DEBUG');

/// First level notification handler
/// Essential to declare it outside of any class or function as per Firebase docs
/// Call [LMNotificationHandler.instance.handleNotification] in this function
/// to handle notifications at the second level (inside the app)
/// Make sure to call [setupNotifications] before this function
Future<void> _handleNotification(RemoteMessage message) async {
  debugPrint("--- Notification received in LEVEL 1 ---");
  await LMNotificationHandler.instance
      .handleNotification(message, true, navigatorKey);
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
  await setupNotifications();

  // InitiateLoggerRequest must be passed in setupLMFeed function
  // to enable error logging with LM
  InitiateLoggerRequest initiateLoggerRequest = (InitiateLoggerRequestBuilder()
        // defines the minimum severity level of logs to be processed
        ..logLevel(Severity.ERROR)
        // function to be called in case of an error
        ..errorHandler((exception, stack) {
          debugPrint("---------------------");
          debugPrint("Error handler called");
          debugPrint("---------------------");
          debugPrint("Exception - $exception");
          debugPrint("---------------------");
          debugPrintStack(stackTrace: stack);
          debugPrint("---------------------");
        })
        // whether or not to share logs with LM
        ..shareLogsWithLM(true)
        // defines the UI version being used
        ..uiVersion('feedUIVersion'))
      .build();

  // Setup LM Feed
  // 1. Get API key
  // 2. Pass InitiateLoggerRequest [OPTIONAL]
  // 3. Pass navigatorKey [OPTIONAL]
  // 4. Pass LMSDKCallback [OPTIONAL]
  await LMFeedCore.instance.initialize(
    // lmFeedClient: lmFeedClient,
    apiKey: "",
    domain: "feednova://www.feednova.com",
  );
  runApp(const MyApp());
}

/// Setup notifications
/// 1. Initialize Firebase
/// 2. Get device id - [deviceId]
/// 3. Get FCM token - [setupMessaging]
/// 4. Register device with LM - [LMNotificationHandler]
/// 5. Listen for FG and BG notifications
/// 6. Handle notifications - [_handleNotification]
Future<void> setupNotifications() async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  final devId = await deviceId();
  final fcmToken = await setupMessaging();
  if (fcmToken == null) {
    debugPrint("FCM token is null or permission declined");
    return;
  }
  // Register device with LM, and listen for notifications
  LMNotificationHandler.instance.init(deviceId: devId, fcmToken: fcmToken);
  FirebaseMessaging.onBackgroundMessage(_handleNotification);
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    _handleNotification(message);
  });
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
    debugPrint("---The app is opened from a notification---");
    await LMNotificationHandler.instance
        .handleNotification(message, false, navigatorKey);
  });
  FirebaseMessaging.instance.getInitialMessage().then(
    (RemoteMessage? message) async {
      if (message != null) {
        debugPrint("---The terminated app is opened from a notification---");
        await LMNotificationHandler.instance
            .handleNotification(message, false, navigatorKey);
      }
    },
  );
}

/// Get device id
/// 1. Get device info
/// 2. Get device id
/// 3. Return device id
Future<String> deviceId() async {
  final deviceInfo = await DeviceInfoPlugin().deviceInfo;
  final deviceId =
      deviceInfo.data["identifierForVendor"] ?? deviceInfo.data["id"];
  debugPrint("Device id - $deviceId");
  return deviceId.toString();
}

/// Setup Firebase messaging on your app
/// The UI package needs your Firebase instance to be initialized
/// 1. Get messaging instance
/// 2. Get FCM token
/// 3. Request permission
/// 4. Return FCM token
Future<String?> setupMessaging() async {
  final messaging = FirebaseMessaging.instance;
  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    announcement: false,
    badge: true,
    carPlay: false,
    criticalAlert: false,
    provisional: false,
    sound: true,
  );

  if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    final token = await messaging.getToken();
    debugPrint('User granted permission: ${settings.authorizationStatus}');
    debugPrint("Token - $token");
    return token.toString();
  } else {
    toast(
      'User declined or has not accepted notification permissions',
      duration: Toast.LENGTH_LONG,
    );
    return null;
  }
}
