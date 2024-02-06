import 'package:flutter/material.dart';
import 'package:likeminds_feed_flutter_core/likeminds_feed_core.dart';
import 'package:likeminds_feed_nova_fl/likeminds_feed_nova_fl.dart';
import 'package:likeminds_feed_nova_fl/src/revamp/model/company_view_data.dart';

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
          ..name(widgets[entityId]!.metadata['company_name'])
          ..imageUrl(widgets[entityId]!.metadata['company_image_url'])
          ..description(widgets[entityId]!.metadata['company_description']);
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
                    // margin:8,
                    ),
                text: LMFeedText(
                  text: footerData.likeCount.toString(),
                  style: LMFeedTextStyle(
                    textStyle: ColorTheme.novaTheme.textTheme.labelLarge,
                  ),
                )),
            footerWidget.commentButton!.copyWith(
                text: LMFeedText(
              text: footerData.commentCount.toString(),
              style: LMFeedTextStyle(
                textStyle: ColorTheme.novaTheme.textTheme.labelLarge,
              ),
            )),
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
