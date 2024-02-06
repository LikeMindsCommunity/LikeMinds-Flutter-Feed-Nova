import 'package:flutter/material.dart';
import 'package:likeminds_feed_flutter_core/likeminds_feed_core.dart';
import 'package:likeminds_feed_nova_fl/likeminds_feed_nova_fl.dart';

class LMNovaCreatePostScreen extends StatefulWidget {
  const LMNovaCreatePostScreen({super.key});

  @override
  State<LMNovaCreatePostScreen> createState() => _LMNovaCreatePostScreenState();
}

class _LMNovaCreatePostScreenState extends State<LMNovaCreatePostScreen> {
  // bool checkPostCreationRights() {
  //   final MemberStateResponse memberStateResponse =
  //       LMFeedUserLocalPreference.instance.fetchMemberRights();
  //   if (!memberStateResponse.success || memberStateResponse.state == 1) {
  //     return true;
  //   }
  //   final memberRights = LMFeedUserLocalPreference.instance.fetchMemberRight(9);
  //   return memberRights;
  // }

  @override
  Widget build(BuildContext context) {
    return LMFeedComposeScreen(
      composeAppBarBuilder: (oldAppBar) => oldAppBar.copyWith(
        style: oldAppBar.style?.copyWith(
          backgroundColor: ColorTheme.backgroundColor,
        ),
      ),
    );
  }
}
