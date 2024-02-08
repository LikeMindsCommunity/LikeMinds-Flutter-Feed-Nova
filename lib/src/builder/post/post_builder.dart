import 'package:flutter/material.dart';
import 'package:likeminds_feed_flutter_core/likeminds_feed_core.dart';
import 'package:likeminds_feed_nova_fl/likeminds_feed_nova_fl.dart';
import 'package:likeminds_feed_nova_fl/src/builder/component/comment_builder.dart';
import 'package:likeminds_feed_nova_fl/src/model/company_view_data.dart';
import 'package:media_kit_video/media_kit_video.dart';

LMCompanyViewData? getCompanyDetails(
  LMPostViewData post,
) {
  LMCompanyViewDataBuilder companyViewDataBuilder = LMCompanyViewDataBuilder();
  Map<String, LMWidgetViewData> widgets = post.widgets ?? {};
  for (LMAttachmentViewData attachment in post.attachments ?? []) {
    if (attachment.attachmentType == 5) {
      final entityId = attachment.attachmentMeta.meta?['entity_id'];
      if (widgets.containsKey(entityId)) {
        companyViewDataBuilder
          ..id(widgets[entityId]!.id)
          ..name(widgets[entityId]!.metadata['company_name'] ?? '')
          ..imageUrl(widgets[entityId]!.metadata['company_image_url'] ?? '')
          ..description(
              widgets[entityId]!.metadata['company_description'] ?? '');
        return companyViewDataBuilder.build();
      }
    }
  }
  return null;
}

Widget novaPostBuilder(BuildContext context, LMFeedPostWidget postWidget,
    LMPostViewData postData, bool isFeed) {
  // final feedTheme = LMFeedTheme.of(context);
  final companyViewData = getCompanyDetails(postData);
  return postWidget.copyWith(
    headerBuilder: (context, headerWidget, headerData) {
      return headerWidget.copyWith(
        titleText: companyViewData != null
            ? LMFeedText(text: companyViewData.name ?? '')
            : null,
        subText: companyViewData != null
            ? LMFeedText(text: companyViewData.description ?? '')
            : null,
        profilePicture: companyViewData != null
            ? LMFeedProfilePicture(
                imageUrl: companyViewData.imageUrl,
                fallbackText: companyViewData.name ?? '',
              )
            : null,
      );
    },
    footerBuilder: (context, footerWidget, footerData) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        child: Row(
          children: [
            footerWidget.likeButton!.copyWith(
                style: footerWidget.likeButton!.style?.copyWith(
                  margin: 8,
                ),
                text: LMFeedText(
                  text: footerData.likeCount.toString(),
                  style: LMFeedTextStyle(
                    textStyle: ColorTheme.novaTheme.textTheme.labelLarge,
                  ),
                )),
            const SizedBox(width: 8),
            footerWidget.commentButton!.copyWith(
                style: footerWidget.commentButton!.style?.copyWith(
                  margin: 8,
                ),
                text: LMFeedText(
                  text: footerData.commentCount.toString(),
                  style: LMFeedTextStyle(
                    textStyle: ColorTheme.novaTheme.textTheme.labelLarge,
                  ),
                )),
            if (!postData.isRepost) ...[
              const SizedBox(width: 8),
              footerWidget.repostButton?.copyWith() ?? const SizedBox.shrink()
            ],
            const Spacer(),
            footerWidget.shareButton!.copyWith(
              style: footerWidget.shareButton!.style?.copyWith(
                showText: false,
              ),
            ),
          ],
        ),
      );
    },
  );
}

void navigateToLMPostDetailsScreen(
  String postId, {
  GlobalKey<NavigatorState>? navigatorKey,
  BuildContext? context,
}) async {
  if (context == null && navigatorKey == null) {
    throw Exception('''
Either context or navigator key must be
         provided to navigate to PostDetailScreen''');
  }
  String visiblePostId =
      LMFeedVideoProvider.instance.currentVisiblePostId ?? postId;

  VideoController? videoController =
      LMFeedVideoProvider.instance.getVideoController(visiblePostId);

  await videoController?.player.pause();

  MaterialPageRoute route = MaterialPageRoute(
    builder: (context) => LMFeedPostDetailScreen(
      postId: postId,
      postBuilder: (_, __, ___) {
        return novaPostBuilder(_, __, ___, false);
      },
      commentBuilder: novaCommentBuilder,
    ),
  );
  if (navigatorKey != null) {
    await navigatorKey.currentState!.push(
      route,
    );
  } else {
    await Navigator.of(context!, rootNavigator: true).push(route);
  }

  await videoController?.player.play();
}
