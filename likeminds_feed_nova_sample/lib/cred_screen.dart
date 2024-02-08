import 'dart:async';

import 'package:likeminds_feed/likeminds_feed.dart';
import 'package:likeminds_feed_flutter_core/likeminds_feed_core.dart';
import 'package:likeminds_feed_nova_fl/likeminds_feed_nova_fl.dart';
import 'package:likeminds_feed_nova_sample/credentials/credentials.dart';
import 'package:likeminds_feed_nova_sample/main.dart';
import 'package:likeminds_feed_nova_sample/network_handling.dart';
import 'package:flutter/material.dart';
import 'package:likeminds_feed_nova_sample/screens/root_screen.dart';
import 'package:likeminds_feed_ui_fl/likeminds_feed_ui_fl.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:uni_links/uni_links.dart';

final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

bool _initialURILinkHandled = false;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return OverlaySupport.global(
      toastTheme: ToastThemeData(
        background: Colors.black,
        textColor: Colors.white,
        alignment: Alignment.bottomCenter,
      ),
      child: LMFeedTheme(
        theme: novaTheme,
        child: MaterialApp(
          title: 'Integration App for UI + SDK package',
          debugShowCheckedModeBanner: false,
          scaffoldMessengerKey: rootScaffoldMessengerKey,
          navigatorKey: navigatorKey,
          theme: ColorTheme.novaTheme,
          home: const CredScreen(),
        ),
      ),
    );
  }
}

class CredScreen extends StatefulWidget {
  const CredScreen({super.key});

  @override
  State<CredScreen> createState() => _CredScreenState();
}

class _CredScreenState extends State<CredScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _userIdController = TextEditingController();
  String? userId;
  StreamSubscription? _streamSubscription;
  late final AppLifecycleListener _listener;

  @override
  void initState() {
    super.initState();
    NetworkConnectivity networkConnectivity = NetworkConnectivity.instance;
    networkConnectivity.initialise();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      initUniLinks(context);
    });
    // Shares logs with LM on App Kill
    _listener = AppLifecycleListener(
      onDetach: () {
        LMFeedLogger.instance.flushLogs();
      },
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _userIdController.dispose();
    super.dispose();
  }

  Future initUniLinks(BuildContext context) async {
    if (!_initialURILinkHandled) {
      _initialURILinkHandled = true;
      // Get the initial deep link if the app was launched with one
      final initialLink = await getInitialLink();

      // Handle the deep link
      if (initialLink != null) {
        // You can extract any parameters from the initialLink object here
        // and use them to navigate to a specific screen in your app
        debugPrint('Received initial deep link: $initialLink');
        final uriLink = Uri.parse(initialLink);
        if (uriLink.isAbsolute) {
          if (uriLink.path == '/post') {
            List secondPathSegment = initialLink.split('post_id=');
            if (secondPathSegment.length > 1 && secondPathSegment[1] != null) {
              String postId = secondPathSegment[1];

              // Call initiate user if not called already
              // It is recommened to call initiate user with your login flow
              // so that navigation works seemlessly
              InitiateUserResponse response = await LMFeedCore.instance
                  .initiateUser((InitiateUserRequestBuilder()
                        ..userId(userId ?? "Test-User-Id")
                        ..userName("Test User"))
                      .build());

              if (response.success) {
                // Replace the below code
                // if you wanna navigate to your screen
                // Either navigatorKey or context must be provided
                // for the navigation to work
                // if both are null an exception will be thrown
                navigateToLMPostDetailsScreen(
                  postId,
                  navigatorKey: navigatorKey,
                );
              }
            }
          } else if (uriLink.path == '/post/create') {
            navigatorKey.currentState!.pushReplacement(
              MaterialPageRoute(
                builder: (context) => const LMFeedComposeScreen(),
              ),
            );
          }
        }
      }

      // Subscribe to link changes
      _streamSubscription = linkStream.listen((String? link) async {
        if (link != null) {
          initialURILinkHandled = true;
          // Handle the deep link
          // You can extract any parameters from the uri object here
          // and use them to navigate to a specific screen in your app
          debugPrint('Received deep link: $link');
          // TODO: add api key to the DeepLinkRequest
          // TODO: add user id and user name of logged in user

          final uriLink = Uri.parse(link);
          if (uriLink.isAbsolute) {
            if (uriLink.path == '/post') {
              List secondPathSegment = link.split('post_id=');
              if (secondPathSegment.length > 1 &&
                  secondPathSegment[1] != null) {
                String postId = secondPathSegment[1];

                InitiateUserResponse response = await LMFeedCore.instance
                    .initiateUser((InitiateUserRequestBuilder()
                          ..userId(userId ?? "Test-User-Id")
                          ..userName("Test User"))
                        .build());

                if (response.success) {
                  // Replace the below code
                  // if you wanna navigate to your screen
                  // Either navigatorKey or context must be provided
                  // for the navigation to work
                  // if both are null an exception will be thrown
                  navigateToLMPostDetailsScreen(
                    postId,
                    navigatorKey: navigatorKey,
                  );
                }
              }
            } else if (uriLink.path == '/post/create') {
              navigatorKey.currentState!.push(
                MaterialPageRoute(
                  builder: (context) => const LMFeedComposeScreen(),
                ),
              );
            }
          }
        }
      }, onError: (err) {
        // Handle exception by warning the user their action did not succeed
        // toast('An error occurred');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    ThemeData theme = ColorTheme.novaTheme;
    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18.0),
          child: Column(
            children: [
              const SizedBox(height: 72),
              Text(
                "LikeMinds Feed\nSample App",
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge!.copyWith(fontSize: 20),
              ),
              const SizedBox(height: 64),
              Text(
                "Enter your credentials",
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 18),
              TextField(
                cursorColor: Colors.white,
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'Gantari',
                ),
                controller: _usernameController,
                decoration: InputDecoration(
                  fillColor: Colors.white,
                  focusColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  labelText: 'Username',
                  labelStyle: theme.textTheme.labelMedium,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                cursorColor: Colors.white,
                controller: _userIdController,
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'Gantari',
                ),
                decoration: InputDecoration(
                  fillColor: Colors.white,
                  focusColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  labelText: 'User ID',
                  labelStyle: theme.textTheme.labelMedium,
                ),
              ),
              const SizedBox(height: 36),
              GestureDetector(
                onTap: () async {
                  String userId = _userIdController.text;
                  String userName = _usernameController.text;

                  if (userId.isEmpty && userName.isEmpty) {
                    toast("Please enter your credentials");
                    return;
                  }

                  MaterialPageRoute route = MaterialPageRoute(
                    builder: (context) => TabApp(
                      feedWidget: LMFeedNova(
                        userId: userId,
                        userName: userName,
                      ),
                      profileWidget: LMFeedUserFeedWidget(
                        postBuilder: (context, postWidget, postViewData) {
                          return novaPostBuilder(
                              context, postWidget, postViewData, true);
                        },
                        userId: userId,
                      ),
                      userName: userName,
                    ),
                  );
                  Navigator.of(context).push(route);
                },
                child: Container(
                  width: 200,
                  height: 42,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                      child: Text("Submit", style: theme.textTheme.bodyMedium)),
                ),
              ),
              const SizedBox(height: 72),
              SizedBox(
                child: Text(
                  "If no credentials are provided, the app will run with the default credentials of Bot user in your community",
                  textAlign: TextAlign.center,
                  softWrap: true,
                  style: theme.textTheme.bodyLarge,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
