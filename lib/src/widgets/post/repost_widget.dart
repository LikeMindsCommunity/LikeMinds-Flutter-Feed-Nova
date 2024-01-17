import 'package:flutter/material.dart';
import 'package:likeminds_feed/likeminds_feed.dart';
import 'package:likeminds_feed_nova_fl/likeminds_feed_nova_fl.dart';
import 'package:likeminds_feed_nova_fl/src/models/post/post_view_model.dart';
import 'package:likeminds_feed_nova_fl/src/services/likeminds_service.dart';
import 'package:likeminds_feed_nova_fl/src/views/media_preview.dart';
import 'package:likeminds_feed_nova_fl/src/views/post_detail_screen.dart';
import 'package:likeminds_feed_ui_fl/likeminds_feed_ui_fl.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:url_launcher/url_launcher.dart';

class NovaRepostWidget extends StatefulWidget {
  const NovaRepostWidget({
    super.key,
    required this.post,
    required this.user,
    this.expanded = false,
    this.showCompanyDetails = true,
    this.widgets,
    this.closeButton,
  });
  final User user;
  final PostViewModel post;
  final bool expanded;
  final bool showCompanyDetails;
  final Map<String, WidgetModel>? widgets;
  final Widget Function()? closeButton;

  @override
  State<NovaRepostWidget> createState() => _NovaRepostWidgetState();
}

class _NovaRepostWidgetState extends State<NovaRepostWidget> {
  PostViewModel? postDetails;
  String? displayName;
  String? displayUrl;
  String? companyId;
  bool? showCompanyDetails;
  Map<String, WidgetModel>? widgets;
  ValueNotifier<bool> rebuildPostWidget = ValueNotifier(false);
  Attachment? linkAttachment;
  VideoController? videoController;

  void setPostDetails() {
    postDetails = widget.post;
    showCompanyDetails = widget.showCompanyDetails;
    widgets = widget.widgets;
    getCompanyDetails();
  }

  void getCompanyDetails() {
    for (Attachment attachment in widget.post.attachments ?? []) {
      if (attachment.attachmentType == 5) {
        final entityId = attachment.attachmentMeta.meta?['entity_id'];
        debugPrint("widget: ${widget.widgets}");
        if (widgets != null && widgets!.containsKey(entityId)) {
          displayName = widgets![entityId]!.metadata['company_name'];
          displayUrl = widgets![entityId]!.metadata['company_image_url'];
          companyId = widgets![entityId]!.metadata['company_id'];
          print("displayName at repost: $displayName");
        }
        break;
      }
    }
  }

  bool checkAttachments(List<Attachment> attachemnts) {
    if (postDetails!.attachments == null || postDetails!.attachments!.isEmpty) {
      return false;
    }
    //remove repost attachment
    postDetails?.attachments
        ?.removeWhere((element) => element.attachmentType == 9);

    for (var attachment in attachemnts) {
      if (attachment.attachmentType != 5) {
        return true;
      }
    }
    return false;
  }

  bool checkForLinkPost() {
    if (postDetails!.attachments == null || postDetails!.attachments!.isEmpty) {
      return false;
    }
    for (var attachment in postDetails!.attachments!) {
      if (attachment.attachmentType == 4) {
        linkAttachment = attachment;
        return true;
      }
    }
    return false;
  }

  @override
  void initState() {
    setPostDetails();
    super.initState();
  }

  @override
  void didUpdateWidget (NovaRepostWidget oldWidget) {
    setPostDetails();
    super.didUpdateWidget(oldWidget);
    
  }

  @override
  Widget build(BuildContext context) {
    ThemeData theme = ColorTheme.novaTheme;
    final screenSize = MediaQuery.of(context).size;
    return InheritedPostProvider(
      post: PostViewData.fromPost(post: widget.post.toPost()),
      child: postDetails?.isDeleted ?? false
          ? Container(
              decoration: BoxDecoration(
                color: ColorTheme.white400,
                borderRadius: BorderRadius.circular(12),
              ),
              height: 120,
              width: double.infinity,
              child: Center(
                child: LMTextView(
                  text: "This post was deleted",
                  textStyle: theme.textTheme.labelMedium,
                ),
              ),
            )
          : InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PostDetailScreen(
                      postId: widget.post.id,
                    ),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10.0, vertical: 10.0),
                decoration: BoxDecoration(
                  border: Border.all(
                      color: theme.colorScheme.onPrimary.withOpacity(0.2)),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ValueListenableBuilder(
                      valueListenable: rebuildPostWidget,
                      builder: (context, _, __) {
                        return LMPostHeader(
                          user: widget.user,
                          isFeed: false,
                          showCustomTitle: false,
                          profilePicture: LMProfilePicture(
                            size: 52,
                            fallbackText: showCompanyDetails!
                                ? displayName ?? widget.user.name
                                : widget.user.name,
                            backgroundColor: theme.primaryColor,
                            imageUrl: showCompanyDetails!
                                ? displayUrl ?? widget.user.imageUrl
                                : widget.user.imageUrl,
                            boxShape: BoxShape.circle,
                            onTap: () {
                              if (companyId != null && companyId!.isNotEmpty) {
                                locator<LikeMindsService>()
                                    .routeToCompany(companyId!);
                              } else if (widget.user.sdkClientInfo != null) {
                                locator<LikeMindsService>().routeToProfile(
                                    widget.user.sdkClientInfo!.userUniqueId);
                              }
                            },
                            fallbackTextStyle: theme.textTheme.titleLarge!
                                .copyWith(fontSize: 28),
                          ),
                          imageSize: 52,
                          titleText: LMTextView(
                            text: showCompanyDetails!
                                ? displayName ?? widget.user.name
                                : widget.user.name,
                            textStyle: theme.textTheme.titleLarge,
                          ),
                          subText: !showCompanyDetails! && displayName != null
                              ? LMTextView(
                                  text: "Created for $displayName",
                                  textStyle: theme.textTheme.labelMedium,
                                )
                              : null,
                          createdAt: LMTextView(
                            text: timeago.format(widget.post.createdAt),
                            textStyle: theme.textTheme.labelMedium,
                          ),
                          editedText: LMTextView(
                            text: "Edited",
                            textStyle: theme.textTheme.labelMedium,
                          ),
                          menu: widget.closeButton != null
                              ? widget.closeButton?.call()
                              : SizedBox.shrink(),
                        );
                      },
                    ),
                    postDetails!.text.isEmpty
                        ? const SizedBox.shrink()
                        : Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: LMPostContent(
                              onTagTap: (String userId) {
                                locator<LikeMindsService>()
                                    .routeToProfile(userId);
                              },
                              linkStyle: theme.textTheme.bodyMedium!
                                  .copyWith(color: theme.colorScheme.primary),
                              textStyle: theme.textTheme.bodyMedium,
                              expandTextStyle: theme.textTheme.bodyMedium!
                                  .copyWith(color: theme.colorScheme.onPrimary),
                              expanded: widget.expanded,
                              expandText: widget.expanded ? '' : 'see more',
                            ),
                          ),
                    checkAttachments(postDetails!.attachments!)
                        ? SizedBox(
                            height: postDetails!.text.isEmpty ? 8.0 : 16.0)
                        : const SizedBox(),
                    checkAttachments(postDetails!.attachments!)
                        ? checkForLinkPost()
                            ? LMLinkPreview(
                                attachment: linkAttachment,
                                backgroundColor: theme.colorScheme.surface,
                                errorWidget: Container(
                                  color: theme.colorScheme.surface,
                                  width: double.infinity,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      LMIcon(
                                        type: LMIconType.icon,
                                        icon: Icons.error_outline,
                                        size: 24,
                                        color: theme.colorScheme.onPrimary,
                                      ),
                                      kVerticalPaddingMedium,
                                      Text("An error occurred fetching media",
                                          style: theme.textTheme.labelSmall)
                                    ],
                                  ),
                                ),
                                onTap: () {
                                  if (linkAttachment?.attachmentMeta.url !=
                                      null) {
                                    launchUrl(
                                      Uri.parse(
                                          linkAttachment!.attachmentMeta.url!),
                                      mode: LaunchMode.externalApplication,
                                    );
                                  }
                                },
                                border: const Border(),
                                title: LMTextView(
                                  text: linkAttachment
                                          ?.attachmentMeta.ogTags?.title ??
                                      "--",
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textStyle: theme.textTheme.titleMedium,
                                ),
                                subtitle: LMTextView(
                                  text: linkAttachment?.attachmentMeta.ogTags
                                          ?.description ??
                                      "--",
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  textStyle: theme.textTheme.displayMedium,
                                ),
                              )
                            : SizedBox(
                                child: LMPostMedia(
                                  initialiseVideoController:
                                      (VideoController controller) {
                                    videoController = controller;
                                  },
                                  attachments: postDetails!.attachments!,
                                  borderRadius: 16.0,
                                  height: screenSize.width - 32,
                                  width: screenSize.width - 32,
                                  boxFit: BoxFit.cover,
                                  textColor: ColorTheme
                                      .novaTheme.colorScheme.onPrimary,
                                  errorWidget: Container(
                                    color: theme.colorScheme.background,
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        LMIcon(
                                          type: LMIconType.icon,
                                          icon: Icons.error_outline,
                                          size: 24,
                                          color: theme
                                              .colorScheme.onPrimaryContainer,
                                        ),
                                        const SizedBox(height: 24),
                                        Text(
                                            "An error occurred fetching media",
                                            style: theme.textTheme.bodyMedium)
                                      ],
                                    ),
                                  ),
                                  backgroundColor: theme.colorScheme.surface,
                                  showBorder: false,
                                  carouselActiveIndicatorColor:
                                      theme.colorScheme.primary,
                                  carouselInactiveIndicatorColor: theme
                                      .colorScheme.primary
                                      .withOpacity(0.3),
                                  documentIcon: Container(
                                    width: 48,
                                    height: 48,
                                    decoration: ShapeDecoration(
                                      color:
                                          theme.colorScheme.primaryContainer,
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(4)),
                                    ),
                                    child: Center(
                                      child: LMTextView(
                                        text: 'PDF',
                                        textStyle: theme.textTheme.titleLarge!
                                            .copyWith(fontSize: 18),
                                      ),
                                    ),
                                  ),
                                ),
                              )
                        : const SizedBox(),
                  ],
                ),
              ),
            ),
    );
  }
}
