import 'package:flutter/material.dart';
import 'package:likeminds_feed/likeminds_feed.dart';
import 'package:likeminds_feed_nova_fl/likeminds_feed_nova_fl.dart';
import 'package:likeminds_feed_nova_fl/src/services/likeminds_service.dart';
import 'package:likeminds_feed_nova_fl/src/services/service_locator.dart';
import 'package:likeminds_feed_ui_fl/likeminds_feed_ui_fl.dart';

class LMUserTile extends StatelessWidget {
  final User user;
  final LMTextView? titleText;
  final LMTextView? subText;
  final double? imageSize;
  const LMUserTile({
    Key? key,
    this.titleText,
    this.imageSize,
    required this.user,
    this.subText,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    ThemeData theme = ColorTheme.novaTheme;
    return GestureDetector(
      onTap: () {
        if (user.sdkClientInfo != null) {
          locator<LikeMindsService>()
              .routeToProfile(user.sdkClientInfo!.userUniqueId);
        }
      },
      child: Container(
        color: Colors.transparent,
        child: Row(
          children: [
            LMProfilePicture(
              size: imageSize ?? 50,
              fallbackText: user.name,
              backgroundColor: theme.primaryColor,
              onTap: () {
                if (user.sdkClientInfo != null) {
                  locator<LikeMindsService>()
                      .routeToProfile(user.sdkClientInfo!.userUniqueId);
                }
              },
              imageUrl: user.imageUrl,
              boxShape: BoxShape.circle,
            ),
            kHorizontalPaddingLarge,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  titleText ??
                      LMTextView(
                        text: user.name,
                        textStyle: ColorTheme.novaTheme.textTheme.bodyLarge,
                      ),
                  kVerticalPaddingMedium,
                  subText ?? const SizedBox(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
