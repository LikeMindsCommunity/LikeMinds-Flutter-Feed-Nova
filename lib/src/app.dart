// import 'package:dotenv/dotenv.dart';
import 'package:flutter/material.dart';
import 'package:likeminds_feed_flutter_core/likeminds_feed_core.dart';
import 'package:likeminds_feed_nova_fl/src/revamp/builder/post/post_builder.dart';

class LMFeedNova extends StatefulWidget {
  final String? userId;
  final String? userName;

  const LMFeedNova({
    super.key,
    this.userId,
    this.userName,
  });

  @override
  State<LMFeedNova> createState() => _LMFeedNovaState();
}

class _LMFeedNovaState extends State<LMFeedNova> {
  Future<InitiateUserResponse>? initiateUser;
  Future<MemberStateResponse>? memberState;

  @override
  void initState() {
    super.initState();
    // var env = DotEnv(includePlatformEnvironment: true)..load();

    InitiateUserRequestBuilder requestBuilder = InitiateUserRequestBuilder();

    if (widget.userId != null) {
      requestBuilder.userId(widget.userId!);
    }

    if (widget.userName != null) {
      requestBuilder.userName(widget.userName!);
    }

    initiateUser = LMFeedCore.instance.initiateUser(requestBuilder.build())
      ..then(
        (value) async {
          if (value.success) {
            memberState = LMFeedCore.instance.getMemberState();
          }
        },
      );
  }

  @override
  Widget build(BuildContext context) {
    LMFeedThemeData feedTheme = LMFeedTheme.of(context);
    return Scaffold(
      body: FutureBuilder<InitiateUserResponse>(
          future: initiateUser,
          builder: (context, snapshot) {
            if (snapshot.hasData && snapshot.data!.success) {
              return FutureBuilder<MemberStateResponse>(
                  future: memberState,
                  builder: (context, snapshot) {
                    if (snapshot.hasData && snapshot.data!.success) {
                      return LMFeedScreen(
                        topicBarBuilder: (topicBar) {
                          return topicBar.copyWith(
                            style: topicBar.style?.copyWith(
                              height: 60,
                              backgroundColor: feedTheme.backgroundColor,
                            ),
                          );
                        },
                        customWidgetBuilder: (context) {
                          return SizedBox.shrink();
                        },
                        postBuilder: (context, postWidget, postViewData) =>
                            novaPostBuilder(
                          context,
                          postWidget,
                          postViewData,
                          true,
                        ),
                        config: const LMFeedScreenConfig(
                          topicSelectionWidgetType:
                              LMFeedTopicSelectionWidgetType
                                  .showTopicSelectionBottomSheet,
                          showCustomWidget: true,
                        ),
                      );
                    } else if (snapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const LMFeedLoader();
                    } else {
                      return const Center(
                        child: Text("An error occurred"),
                      );
                    }
                  });
            } else if (snapshot.connectionState == ConnectionState.waiting) {
              return const LMFeedLoader();
            } else {
              return const Center(
                child: Text("Please check your internet connection"),
              );
            }
          }),
    );
  }
}
