import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:likeminds_feed/likeminds_feed.dart';
import 'package:likeminds_feed_nova_fl/likeminds_feed_nova_fl.dart';
import 'package:likeminds_feed_nova_fl/src/blocs/new_post/new_post_bloc.dart';
import 'package:likeminds_feed_nova_fl/src/models/post_view_model.dart';
import 'package:likeminds_feed_nova_fl/src/services/likeminds_service.dart';
import 'package:likeminds_feed_nova_fl/src/utils/constants/assets_constants.dart';
import 'package:likeminds_feed_nova_fl/src/utils/icons.dart';
import 'package:likeminds_feed_nova_fl/src/utils/post/post_action_id.dart';
import 'package:likeminds_feed_nova_fl/src/utils/post/post_utils.dart';
import 'package:likeminds_feed_nova_fl/src/views/likes/likes_screen.dart';
import 'package:likeminds_feed_nova_fl/src/views/media_preview.dart';
import 'package:likeminds_feed_nova_fl/src/views/post_detail_screen.dart';
import 'package:likeminds_feed_ui_fl/likeminds_feed_ui_fl.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:url_launcher/url_launcher.dart';
import 'package:visibility_detector/visibility_detector.dart';

class NovaPostWidget extends StatefulWidget {
  final PostViewModel post;
  final User user;
  final Map<String, Topic> topics;
  final Map<String, WidgetModel> widgets;
  final bool isFeed;
  final Function() onTap;
  final Function(bool isDeleted) refresh;
  final Function(int) onMenuTap;
  final bool expanded;
  final bool showMenu;
  final bool showCompanyDetails;
  final CompanyUI? company;

  const NovaPostWidget({
    Key? key,
    required this.post,
    required this.user,
    required this.onTap,
    required this.topics,
    required this.refresh,
    required this.isFeed,
    required this.onMenuTap,
    required this.widgets,
    this.expanded = false,
    this.showMenu = true,
    this.showCompanyDetails = true,
    this.company,
  }) : super(key: key);

  @override
  State<NovaPostWidget> createState() => _NovaPostWidgetState();
}

class _NovaPostWidgetState extends State<NovaPostWidget> {
  int postLikes = 0;
  int comments = 0;
  PostViewModel? postDetails;
  String? displayName;
  String? displayUrl;
  String? companyId;
  bool? isLiked;
  bool? isPinned;
  bool? showCompanyDetails;
  Map<String, WidgetModel>? widgets;
  ValueNotifier<bool> rebuildLikeWidget = ValueNotifier(false);
  ValueNotifier<bool> rebuildPostWidget = ValueNotifier(false);
  Attachment? linkAttachment;
  VideoController? videoController;

  @override
  void initState() {
    super.initState();
    setPostDetails();
  }

  @override
  void didUpdateWidget(covariant NovaPostWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    setPostDetails();
  }

  void setPostDetails() {
    postDetails = widget.post;
    widgets = widget.widgets;
    postLikes = postDetails!.likeCount;
    comments = postDetails!.commentCount;
    isLiked = postDetails!.isLiked;
    isPinned = postDetails!.isPinned;
    showCompanyDetails = widget.showCompanyDetails;
    widgets = widget.widgets;
    getCompanyDetails();
  }

  void getCompanyDetails() {
    for (Attachment attachment in widget.post.attachments ?? []) {
      if (attachment.attachmentType == 5) {
        final entityId = attachment.attachmentMeta.meta?['entity_id'];
        if (widgets != null && widgets!.containsKey(entityId)) {
          displayName = widgets![entityId]!.metadata['company_name'];
          displayUrl = widgets![entityId]!.metadata['company_image_url'];
          companyId = widgets![entityId]!.metadata['company_id'];
          print("displayName: $displayName");
        }
        break;
      }
    }
  }

  bool checkAttachments(List<Attachment> attachemnts) {
    if (postDetails!.attachments == null || postDetails!.attachments!.isEmpty) {
      return false;
    }
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
  Widget build(BuildContext context) {
    Size screenSize = MediaQuery.of(context).size;
    NewPostBloc newPostBloc = locator<BlocService>().newPostBlocProvider;
    timeago.setLocaleMessages('en', SSCustomMessages());
    ThemeData theme = ColorTheme.novaTheme;
    return InheritedPostProvider(
      post: PostViewData.fromPost(post: widget.post.toPost()),
      child: Container(
        color: theme.colorScheme.background,
        child: BlocListener(
          bloc: newPostBloc,
          listener: (context, state) {
            if (state is PostPinnedState && state.postId == widget.post.id) {
              isPinned = state.isPinned;
              int? itemIndex = postDetails?.menuItems.indexWhere((element) {
                return (isPinned! && element.id == 2) ||
                    (!isPinned! && element.id == 3);
              });
              if (itemIndex != null && itemIndex != -1) {
                if (postDetails!.menuItems[itemIndex].id == 2) {
                  postDetails!.menuItems[itemIndex] =
                      PopupMenuItemModel(title: "Unpin this Post", id: 3);
                } else if (postDetails!.menuItems[itemIndex].id == 3) {
                  postDetails!.menuItems[itemIndex] =
                      PopupMenuItemModel(title: "Pin this Post", id: 2);
                }
              }
              postDetails!.isPinned = isPinned!;
              rebuildPostWidget.value = !rebuildPostWidget.value;
              newPostBloc.add(UpdatePost(post: postDetails!));
            } else if (state is PostPinError &&
                state.postId == widget.post.id) {
              isPinned = state.isPinned;
              rebuildPostWidget.value = !rebuildPostWidget.value;
            }
          },
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              // Navigate to LMPostPage using material route
              if (widget.isFeed) {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => PostDetailScreen(
                      postId: widget.post.id,
                    ),
                  ),
                );
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ValueListenableBuilder(
                    valueListenable: rebuildPostWidget,
                    builder: (context, _, __) => isPinned!
                        ? const Column(
                            children: [
                              Row(
                                children: [
                                  LMIcon(
                                    type: LMIconType.svg,
                                    assetPath: kAssetPinIcon,
                                    color: ColorTheme.white,
                                    size: 20,
                                  ),
                                  kHorizontalPaddingMedium,
                                  LMTextView(
                                    text: "Pinned Post",
                                    textStyle: TextStyle(
                                      color: ColorTheme.white,
                                      fontFamily: 'Gantari',
                                    ),
                                  )
                                ],
                              ),
                              kVerticalPaddingMedium,
                            ],
                          )
                        : const SizedBox(),
                  ),
                  ValueListenableBuilder(
                    valueListenable: rebuildPostWidget,
                    builder: (context, _, __) {
                      return LMPostHeader(
                          user: widget.user,
                          isFeed: widget.isFeed,
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
                          menu: widget.showMenu
                              ? LMIconButton(
                                  icon: LMIcon(
                                    type: LMIconType.icon,
                                    icon: Icons.more_horiz,
                                    color: theme.colorScheme.onPrimary,
                                  ),
                                  onTap: (bool value) {
                                    showModalBottomSheet(
                                      context: context,
                                      elevation: 5,
                                      isDismissible: true,
                                      useRootNavigator: true,
                                      clipBehavior: Clip.hardEdge,
                                      backgroundColor: Colors.transparent,
                                      enableDrag: false,
                                      shape: const RoundedRectangleBorder(
                                        borderRadius: BorderRadius.only(
                                          topLeft: Radius.circular(32),
                                          topRight: Radius.circular(32),
                                        ),
                                      ),
                                      builder: (context) => LMBottomSheet(
                                        height:
                                            max(170, screenSize.height * 0.25),
                                        margin: const EdgeInsets.only(top: 30),
                                        borderRadius: const BorderRadius.only(
                                          topLeft: Radius.circular(32),
                                          topRight: Radius.circular(32),
                                        ),
                                        dragBar: Container(
                                          width: 96,
                                          height: 6,
                                          decoration: ShapeDecoration(
                                            color: theme.colorScheme.onSurface,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(99),
                                            ),
                                          ),
                                        ),
                                        backgroundColor:
                                            theme.colorScheme.surface,
                                        children: postDetails!.menuItems
                                            .map(
                                              (e) => GestureDetector(
                                                onTap: () {
                                                  Navigator.of(context).pop();
                                                  widget.onMenuTap(e.id);
                                                },
                                                child: Container(
                                                  color: Colors.transparent,
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      vertical: 2.0,
                                                      horizontal: 16.0),
                                                  margin: const EdgeInsets.only(
                                                      bottom: 24.09),
                                                  width:
                                                      screenSize.width - 32.0,
                                                  child: Row(children: [
                                                    getIconFromDropDownItemId(
                                                      e.id,
                                                      20,
                                                      theme.colorScheme
                                                          .onPrimaryContainer,
                                                    ),
                                                    kHorizontalPaddingLarge,
                                                    LMTextView(
                                                      text: e.title,
                                                      textStyle: theme.textTheme
                                                          .headlineLarge!
                                                          .copyWith(
                                                              color: e.id ==
                                                                      postDeleteId
                                                                  ? theme
                                                                      .colorScheme
                                                                      .error
                                                                  : theme
                                                                      .colorScheme
                                                                      .onPrimaryContainer),
                                                    ),
                                                  ]),
                                                ),
                                              ),
                                            )
                                            .toList(),
                                      ),
                                    );
                                  },
                                )
                              : const SizedBox());
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
                      ? SizedBox(height: postDetails!.text.isEmpty ? 8.0 : 16.0)
                      : const SizedBox(),
                  checkAttachments(postDetails!.attachments!)
                      ? checkForLinkPost()
                          ? LMLinkPreview(
                              attachment: linkAttachment,
                              backgroundColor: theme.colorScheme.surface,
                              showLinkUrl: false,
                              errorWidget: Container(
                                color: theme.colorScheme.surface,
                                width: double.infinity,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
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
                                text: linkAttachment
                                        ?.attachmentMeta.ogTags?.description ??
                                    "--",
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                textStyle: theme.textTheme.displayMedium,
                              ),
                            )
                          : SizedBox(
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () async {
                                  await videoController?.player.pause();
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) {
                                        return MediaPreview(
                                          postAttachments:
                                              postDetails!.attachments!,
                                          post: postDetails!.toPost(),
                                          user: widget.user,
                                        );
                                      },
                                    ),
                                  );
                                  await videoController?.player.play();
                                },
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
                                  showLinkUrl: false,
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
                                        Text("An error occurred fetching media",
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
                                      color: theme.colorScheme.primaryContainer,
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
                              ),
                            )
                      : const SizedBox(),
                  kVerticalPaddingLarge,
                  LMPostFooter(
                    alignment: LMAlignment.left,
                    children: [
                      ValueListenableBuilder(
                          valueListenable: rebuildLikeWidget,
                          builder: (context, _, __) {
                            return LMTextButton(
                              padding: EdgeInsets.zero,
                              mainAxisAlignment: MainAxisAlignment.start,
                              text: LMTextView(
                                text: "$postLikes",
                                textStyle: theme.textTheme.labelLarge,
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          LikesScreen(postId: widget.post.id),
                                    ),
                                  );
                                },
                              ),
                              margin: 6,
                              onTap: () async {
                                if (isLiked!) {
                                  postLikes--;
                                  postDetails!.likeCount -= 1;
                                  postDetails!.isLiked = false;
                                } else {
                                  postLikes++;
                                  postDetails!.likeCount += 1;
                                  postDetails!.isLiked = true;
                                }
                                isLiked = !isLiked!;
                                rebuildLikeWidget.value =
                                    !rebuildLikeWidget.value;

                                final response =
                                    await locator<LikeMindsService>().likePost(
                                        (LikePostRequestBuilder()
                                              ..postId(postDetails!.id))
                                            .build());
                                if (!response.success) {
                                  toast(
                                    response.errorMessage ??
                                        "There was an error liking the post",
                                    duration: Toast.LENGTH_LONG,
                                  );

                                  if (isLiked!) {
                                    postLikes--;
                                    postDetails!.likeCount -= 1;
                                    postDetails!.isLiked = false;
                                  } else {
                                    postLikes++;
                                    postDetails!.likeCount += 1;
                                    postDetails!.isLiked = true;
                                  }
                                  isLiked = !isLiked!;
                                  rebuildLikeWidget.value =
                                      !rebuildLikeWidget.value;
                                  widget.refresh(false);
                                } else {
                                  if (!widget.isFeed) {
                                    newPostBloc.add(
                                      UpdatePost(
                                        post: postDetails!,
                                      ),
                                    );
                                    widget.refresh(false);
                                  }
                                }
                              },
                              icon: LMIcon(
                                type: LMIconType.svg,
                                assetPath: kAssetLikeIcon,
                                color: theme.colorScheme.onPrimary,
                                size: 16,
                              ),
                              activeIcon: LMIcon(
                                type: LMIconType.svg,
                                assetPath: kAssetLikeFilledIcon,
                                color: theme.colorScheme.error,
                                size: 16,
                              ),
                              isActive: isLiked!,
                            );
                          }),
                      kHorizontalPaddingLarge,
                      LMTextButton(
                        text: LMTextView(
                          text: "$comments",
                          textStyle: theme.textTheme.labelLarge,
                        ),
                        margin: 6,
                        onTap: () {
                          if (widget.isFeed) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PostDetailScreen(
                                  postId: widget.post.id,
                                  fromCommentButton: true,
                                ),
                              ),
                            );
                          }
                        },
                        icon: LMIcon(
                          type: LMIconType.svg,
                          assetPath: kAssetCommentIcon,
                          color: theme.colorScheme.onPrimary,
                          size: 20,
                        ),
                      ),
                      const Spacer(),
                      LMIconButton(
                        onTap: (value) {
                          SharePost().sharePost(widget.post.id);
                        },
                        icon: LMIcon(
                          type: LMIconType.svg,
                          assetPath: kAssetShareIcon,
                          color: theme.colorScheme.onPrimary,
                          size: 20,
                        ),
                      ),
                    ],
                    // children: [

                    // ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
