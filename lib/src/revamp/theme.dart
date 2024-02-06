import 'package:flutter/material.dart';
import 'package:likeminds_feed_flutter_core/likeminds_feed_core.dart';
import 'package:likeminds_feed_nova_fl/src/utils/constants/assets_constants.dart';

LMFeedThemeData novaTheme = LMFeedThemeData.light(
  backgroundColor: const Color.fromRGBO(24, 23, 25, 1),
  primaryColor: const Color.fromRGBO(150, 94, 255, 1),
  container: const Color.fromRGBO(24, 23, 25, 1),
  onContainer: const Color.fromRGBO(255, 255, 255, 1),
  commentStyle: LMFeedCommentStyle.basic().copyWith(
    backgroundColor: const Color.fromRGBO(24, 23, 25, 1),
    showProfilePicture: true,
    actionsPadding: const EdgeInsets.only(
      left: 44.0,
    ),
    titlePadding: const EdgeInsets.only(left: 8),
  ),
  replyStyle: LMFeedCommentStyle.basic(isReply: true).copyWith(
    backgroundColor: const Color.fromRGBO(24, 23, 25, 1),
    showProfilePicture: true,
    actionsPadding: const EdgeInsets.only(
      left: 44.0,
    ),
    titlePadding: const EdgeInsets.only(left: 8),
    // margin: const EdgeInsets.only(
    //   left: 44.0,
    // ),
  ),
  composeScreenStyle: LMFeedComposeScreenStyle.basic().copyWith(
    addImageIcon: LMFeedIcon(
      type: LMFeedIconType.svg,
      assetPath: kAssetGalleryIcon,
      style: LMFeedIconStyle.basic().copyWith(
        color: const Color.fromRGBO(150, 94, 255, 1),
        boxPadding: 0,
        size: 28,
      ),
    ),
    addVideoIcon: LMFeedIcon(
      type: LMFeedIconType.svg,
      assetPath: kAssetVideoIcon,
      style: LMFeedIconStyle.basic().copyWith(
        color: const Color.fromRGBO(150, 94, 255, 1),
        boxPadding: 0,
        size: 28,
      ),
    ),
    addDocumentIcon: LMFeedIcon(
      type: LMFeedIconType.svg,
      assetPath: kAssetDocPDFIcon,
      style: LMFeedIconStyle.basic().copyWith(
        color: const Color.fromRGBO(150, 94, 255, 1),
        boxPadding: 0,
        size: 28,
      ),
    ),
  ),
  footerStyle: LMFeedPostFooterStyle.basic().copyWith(
    showSaveButton: false,
    likeButtonStyle: LMFeedButtonStyle.basic().copyWith(
      activeIcon: const LMFeedIcon(
        type: LMFeedIconType.svg,
        assetPath: kAssetLikeFilledIcon,
        style: LMFeedIconStyle(
          size: 16,
          color: Color.fromRGBO(255, 73, 90, 1),
        ),
      ),
      icon: const LMFeedIcon(
        type: LMFeedIconType.svg,
        assetPath: kAssetLikeIcon,
        style: LMFeedIconStyle(
          size: 16,
          color: Color.fromRGBO(241, 241, 241, 0.694),
        ),
      ),
    ),
    commentButtonStyle: LMFeedButtonStyle.basic().copyWith(
      icon: const LMFeedIcon(
        type: LMFeedIconType.svg,
        assetPath: kAssetCommentIcon,
        style: LMFeedIconStyle(
            size: 20, color: Color.fromRGBO(241, 241, 241, 0.694)),
      ),
    ),
    shareButtonStyle: LMFeedButtonStyle.basic().copyWith(
      icon: const LMFeedIcon(
        type: LMFeedIconType.svg,
        assetPath: kAssetShareIcon,
        style: LMFeedIconStyle(
            size: 20, color: Color.fromRGBO(241, 241, 241, 0.694)),
      ),
    ),
  ),
);
