import 'package:flutter/material.dart';
import 'package:likeminds_feed_flutter_core/likeminds_feed_core.dart';
import 'package:likeminds_feed_nova_fl/likeminds_feed_nova_fl.dart';
import 'package:likeminds_feed_nova_fl/src/utils/constants/assets_constants.dart';
import 'package:timeago/timeago.dart' as timeago;

Widget novaCommentBuilder(BuildContext context,
    LMFeedCommentWidget commentWidget, LMPostViewData postViewData) {
  final screenSize = MediaQuery.of(context).size;
  return commentWidget.copyWith(
      subtitleText: LMFeedText(
        text: timeago.format(commentWidget.comment.createdAt),
        style: LMFeedTextStyle(
          textStyle: ColorTheme.novaTheme.textTheme.labelMedium,
        ),
      ),
      likeButtonBuilder: (likeButton) {
        return likeButton.copyWith(
          style: likeButton.style?.copyWith(
            showText: true,
          ),
          activeText: LMFeedText(
            text: commentWidget.comment.likesCount.toString(),
            style: LMFeedTextStyle(
              textStyle: ColorTheme.novaTheme.textTheme.labelMedium,
            ),
          ),
          text: LMFeedText(
            text: commentWidget.comment.likesCount.toString(),
            style: LMFeedTextStyle(
              textStyle: ColorTheme.novaTheme.textTheme.labelMedium,
            ),
          ),
        );
      },
      showRepliesButtonBuilder: (showRepliesButton) {
        return showRepliesButton.copyWith(
          style: showRepliesButton.style?.copyWith(
            showText: true,
          ),
          text: LMFeedText(
            text: 'View Replies',
            style: LMFeedTextStyle(
              textStyle: ColorTheme.novaTheme.textTheme.labelMedium?.copyWith(
                color: ColorTheme.novaTheme.primaryColor,
              ),
            ),
          ),
          activeText: LMFeedText(
            text: 'Hide Replies',
            style: LMFeedTextStyle(
              textStyle: ColorTheme.novaTheme.textTheme.labelMedium?.copyWith(
                color: ColorTheme.novaTheme.primaryColor,
              ),
            ),
          ),
        );
      },
      replyButtonBuilder: (replyButton) {
        return replyButton.copyWith(
          style: replyButton.style?.copyWith(
            showText: true,
          ),
          text: LMFeedText(
            text: 'Reply',
            style: LMFeedTextStyle(
              textStyle: ColorTheme.novaTheme.textTheme.labelMedium,
            ),
          ),
          activeText: LMFeedText(
            text: 'Reply',
            style: LMFeedTextStyle(
              textStyle: ColorTheme.novaTheme.textTheme.labelMedium?.copyWith(
                color: ColorTheme.novaTheme.primaryColor,
              ),
            ),
          ),
        );
      },
      style: commentWidget.style?.copyWith(
        showTimestamp: false,
        likeButtonStyle: LMFeedButtonStyle.like().copyWith(
          activeIcon: LMFeedIcon(
            type: LMFeedIconType.svg,
            assetPath: kAssetLikeFilledIcon,
            style: LMFeedIconStyle(
              size: 14,
              color: ColorTheme.novaTheme.colorScheme.error,
            ),
          ),
          icon: const LMFeedIcon(
            type: LMFeedIconType.svg,
            assetPath: kAssetLikeIcon,
            style: LMFeedIconStyle(
              size: 14,
              color: ColorTheme.lightWhite300,
            ),
          ),
        ),
        showProfilePicture: true,
        profilePicturePadding: const EdgeInsets.only(right: 12),
        textStyle: ColorTheme.novaTheme.textTheme.labelMedium,
        linkStyle: ColorTheme.novaTheme.textTheme.labelMedium!
            .copyWith(color: ColorTheme.novaTheme.primaryColor),
        width: screenSize.width,
        backgroundColor: ColorTheme.novaTheme.colorScheme.surface,
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(10),
          bottomLeft: Radius.circular(10),
          bottomRight: Radius.circular(10),
        ),
        margin: const EdgeInsets.symmetric(
          horizontal: 12.0,
          vertical: 6.0,
        ),
      ));
}
