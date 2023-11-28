library likeminds_feed_ss_fl;

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_no_internet_widget/flutter_no_internet_widget.dart';
import 'package:likeminds_feed/likeminds_feed.dart';
import 'package:likeminds_feed_nova_fl/src/persistence/logger/logger.dart';
import 'package:likeminds_feed_nova_fl/src/utils/icons.dart';
import 'package:likeminds_feed_nova_fl/src/utils/network_handling.dart';

import 'package:likeminds_feed_nova_fl/src/utils/utils.dart';

import 'package:likeminds_feed_nova_fl/src/views/universal_feed_page.dart';
import 'package:likeminds_feed_ui_fl/likeminds_feed_ui_fl.dart';

import 'package:likeminds_feed_nova_fl/src/services/likeminds_service.dart';
import 'package:likeminds_feed_nova_fl/src/services/service_locator.dart';
import 'package:likeminds_feed_nova_fl/src/utils/constants/ui_constants.dart';
import 'package:likeminds_feed_nova_fl/src/utils/credentials/credentials.dart';
import 'package:media_kit/media_kit.dart';

export 'src/services/service_locator.dart';
export 'src/services/navigation_service.dart';
export 'src/services/bloc_service.dart';
export 'src/utils/analytics/analytics.dart';
export 'src/utils/notifications/notification_handler.dart';
export 'src/utils/share/share_post.dart';
export 'src/utils/constants/ui_constants.dart';
export 'package:likeminds_feed_nova_fl/src/utils/utils.dart';
export 'src/widgets/feed/user_feed_widget.dart';
export 'src/widgets/feed/company_feed_widget.dart';
export 'src/models/company_view_model.dart';
export 'src/views/post/new_post_screen.dart';

/// Flutter environment manager v0.0.1
const prodFlag = !bool.fromEnvironment('DEBUG', defaultValue: true);
//bool _initialURILinkHandled = false;

final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

class LMFeed extends StatefulWidget {
  final String? userId;
  final String? userName;
  final String? imageUrl;
  final Function(BuildContext context)? openChatCallback;
  final Map<int, Widget>? customWidgets;
  static bool? shareErrorLogsWithLM;
  static Function(LMStackTrace stackTrace)? onErrorHandler;

  /// INIT - Get the LMFeed instance and pass the credentials (if any)
  /// to the instance. This will be used to initialize the app.
  /// If no credentials are provided, the app will run with the default
  /// credentials of Bot user in your community in `credentials.dart`
  static LMFeed instance({
    String? userId,
    String? userName,
    String? imageUrl,
    Function(BuildContext context)? openChatCallback,
    Map<int, Widget>? customWidgets,
  }) {
    return LMFeed._(
      userId: userId,
      userName: userName,
      imageUrl: imageUrl,
      customWidgets: customWidgets,
      openChatCallback: openChatCallback,
    );
  }

  static void setupFeed({
    required String apiKey,
    LMSDKCallback? lmCallBack,
    GlobalKey<NavigatorState>? navigatorKey,
    bool shareErrorLogsWithLM = true,
    Function(LMStackTrace stackTrace)? onErrorHandler,
  }) {
    setupLMFeed(
      lmCallBack,
      apiKey,
      navigatorKey: navigatorKey ?? GlobalKey<NavigatorState>(),
    );
  }

  static void logout() {
    locator<LikeMindsService>().logout(LogoutRequestBuilder().build());
  }

  const LMFeed._({
    Key? key,
    this.userId,
    this.userName,
    this.imageUrl,
    this.customWidgets,
    this.openChatCallback,
  }) : super(key: key);

  @override
  _LMFeedState createState() => _LMFeedState();
}

class _LMFeedState extends State<LMFeed> {
  User? user;
  late final String userId;
  late final String userName;
  String? imageUrl;
  late final bool isProd;
  late final NetworkConnectivity networkConnectivity;
  ValueNotifier<bool> rebuildOnConnectivityChange = ValueNotifier<bool>(false);
  Map<int, Widget>? customWidgets;
  Future<InitiateUserResponse>? initiateUser;

  @override
  void initState() {
    super.initState();
    networkConnectivity = NetworkConnectivity.instance;
    networkConnectivity.initialise();
    MediaKit.ensureInitialized();
    loadSvgIntoCache();
    isProd = prodFlag;
    userId = widget.userId!.isEmpty
        ? isProd
            ? CredsProd.botId
            : CredsDev.botId
        : widget.userId!;
    userName = widget.userName!.isEmpty ? "Test username" : widget.userName!;
    imageUrl = widget.imageUrl;
    initiateUser = locator<LikeMindsService>().initiateUser(
      (InitiateUserRequestBuilder()
            ..userId(userId)
            ..userName(userName)
            ..imageUrl(imageUrl ?? ''))
          .build(),
    );
    customWidgets = widget.customWidgets;
    firebase();
  }

  @override
  void didUpdateWidget(covariant LMFeed oldWidget) {
    // TODO: implement didUpdateWidget
    super.didUpdateWidget(oldWidget);
    initiateUser = locator<LikeMindsService>().initiateUser(
      (InitiateUserRequestBuilder()
            ..userId(userId)
            ..userName(userName)
            ..imageUrl(imageUrl ?? ''))
          .build(),
    );
  }

  void firebase() {
    try {
      final firebase = Firebase.app();
      debugPrint("Firebase - ${firebase.options.appId}");
    } on FirebaseException catch (err, stacktrace) {
      debugPrint("Make sure you have initialized firebase, ${err.toString()}");
      LMFeedLogger.instance.handleException(err.toString(), stacktrace);
    }
  }

  @override
  Widget build(BuildContext context) {
    Size screenSize = MediaQuery.of(context).size;
    return InternetWidget(
      offline: FullScreenWidget(
        child: Container(
          width: screenSize.width,
          color: ColorTheme.backgroundColor,
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(
                Icons.signal_wifi_off,
                size: 40,
                color: ColorTheme.primaryColor,
              ),
              kVerticalPaddingLarge,
              Text(
                "No internet\nCheck your connection and try again",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: ColorTheme.primaryColor,
                  fontFamily: 'Gantari',
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
      connectivity: networkConnectivity.networkConnectivity,
      // ignore: avoid_print
      whenOffline: () {
        debugPrint('No Internet');
        rebuildOnConnectivityChange.value = !rebuildOnConnectivityChange.value;
      },
      // ignore: avoid_print
      whenOnline: () {
        debugPrint('Connected to internet');
        locator<LikeMindsService>().initiateUser(
          (InitiateUserRequestBuilder()
                ..userId(userId)
                ..userName(userName)
                ..imageUrl(imageUrl ?? ''))
              .build(),
        );
        rebuildOnConnectivityChange.value = !rebuildOnConnectivityChange.value;
      },
      loadingWidget: Container(
        width: screenSize.width,
        height: screenSize.height,
        color: ColorTheme.backgroundColor,
        child: Center(
          child: CircularProgressIndicator(
            color: ColorTheme.novaTheme.primaryColor,
          ),
        ),
      ),
      online: ValueListenableBuilder(
          valueListenable: rebuildOnConnectivityChange,
          builder: (context, _, __) {
            return FutureBuilder<InitiateUserResponse>(
              future: initiateUser,
              initialData: null,
              builder: (BuildContext context, AsyncSnapshot snapshot) {
                if (snapshot.hasData) {
                  InitiateUserResponse response = snapshot.data;
                  if (response.success) {
                    user = response.initiateUser?.user;

                    //Get community configurations
                    locator<LikeMindsService>().getCommunityConfigurations();

                    LMNotificationHandler.instance.registerDevice(user!.id);
                    return FutureBuilder(
                      future: locator<LikeMindsService>().getMemberState(),
                      initialData: null,
                      builder: (BuildContext context, AsyncSnapshot snapshot) {
                        if (snapshot.hasData) {
                          //TODO: Add Custom widget here
                          return UniversalFeedScreen(
                            openChatCallback: widget.openChatCallback,
                            customWidgets: customWidgets,
                          );
                        }

                        return Container(
                          height: screenSize.height,
                          width: screenSize.width,
                          color: ColorTheme.backgroundColor,
                          child: Center(
                            child: LMLoader(
                              isPrimary: true,
                              color: ColorTheme.novaTheme.primaryColor,
                            ),
                          ),
                        );
                      },
                      // ),
                    );
                  } else {}
                } else if (snapshot.hasError) {
                  debugPrint("Error - ${snapshot.error}");
                  return Container(
                    height: screenSize.height,
                    width: screenSize.width,
                    color: ColorTheme.backgroundColor,
                    child: const Center(
                      child: Text("An error has occured",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: ColorTheme.white,
                            fontFamily: 'Gantari',
                            fontSize: 16,
                          )),
                    ),
                  );
                }
                return Container(
                  height: screenSize.height,
                  width: screenSize.width,
                  color: ColorTheme.backgroundColor,
                );
              },
            );
          }),
    );
  }
}
