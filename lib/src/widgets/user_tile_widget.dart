import 'package:flutter/material.dart';
import 'package:likeminds_feed/likeminds_feed.dart';
import 'package:likeminds_feed_nova_fl/likeminds_feed_nova_fl.dart';
import 'package:likeminds_feed_nova_fl/src/services/likeminds_service.dart';
import 'package:likeminds_feed_nova_fl/src/utils/constants/ui_constants.dart';
import 'package:likeminds_feed_ui_fl/likeminds_feed_ui_fl.dart';

// TODO: Customisation
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
    return Row(
      children: [
        LMProfilePicture(
          size: imageSize ?? 50,
          fallbackText: user.name,
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
                    textStyle: Theme.of(context).textTheme.bodyLarge,
                  ),
              kVerticalPaddingMedium,
              subText ?? const SizedBox(),
            ],
          ),
        ),
      ],
    );
  }
}
