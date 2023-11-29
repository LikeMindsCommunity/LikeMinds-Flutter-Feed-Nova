import 'dart:async';

import 'package:likeminds_feed/likeminds_feed.dart';
import 'package:likeminds_feed_nova_fl/likeminds_feed_nova_fl.dart';
import 'package:likeminds_feed_nova_sample/credentials/credentials.dart';
import 'package:likeminds_feed_nova_sample/dummy_custom_widget/custom_widget.dart';
import 'package:likeminds_feed_nova_sample/likeminds_callback.dart';
import 'package:likeminds_feed_nova_sample/main.dart';
import 'package:likeminds_feed_nova_sample/network_handling.dart';
import 'package:flutter/material.dart';
import 'package:likeminds_feed_nova_sample/screens/root_screen.dart';
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
      child: MaterialApp(
        title: 'Integration App for UI + SDK package',
        debugShowCheckedModeBanner: false,
        scaffoldMessengerKey: rootScaffoldMessengerKey,
        navigatorKey: navigatorKey,
        theme: ColorTheme.novaTheme,
        home: const CredScreen(),
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
  LMFeed? lmFeed;
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

        // TODO: add api key to the DeepLinkRequest
        // TODO: add user id and user name of logged in user
        SharePost().parseDeepLink((DeepLinkRequestBuilder()
              // Add your api key here
              ..apiKey(debug ? CredsDev.apiKey : CredsProd.apiKey)
              ..isGuest(false)
              ..link(initialLink)
              // Add user name here
              ..userName("Test User")
              // Add user id here
              ..userUniqueId('Test User Id'))
            .build());
      }

      // Subscribe to link changes
      _streamSubscription = linkStream.listen((String? link) async {
        if (link != null) {
          // Handle the deep link
          // You can extract any parameters from the uri object here
          // and use them to navigate to a specific screen in your app
          debugPrint('Received deep link: $link');

          // TODO: add api key to the DeepLinkRequest
          // TODO: add user id and user name of logged in user
          SharePost().parseDeepLink((DeepLinkRequestBuilder()
                // Add your api key here
                ..apiKey(debug ? CredsDev.apiKey : CredsProd.apiKey)
                ..isGuest(false)
                ..link(link)
                // Add user name here
                ..userName("Test User")
                // Add user id here
                ..userUniqueId('Test User Id'))
              .build());
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
    Size screenSize = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: Padding(
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
                lmFeed = LMFeed.instance(
                    userId: _userIdController.text,
                    userName: _usernameController.text,
                    customWidgets: customWidgets(screenSize));

                MaterialPageRoute route = MaterialPageRoute(
                  builder: (context) => TabApp(feedWidget: lmFeed!),
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
    );
  }
}
