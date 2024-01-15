import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:likeminds_feed/likeminds_feed.dart';
import 'package:likeminds_feed_nova_fl/likeminds_feed_nova_fl.dart';
import 'package:likeminds_feed_nova_fl/src/blocs/new_post/new_post_bloc.dart';
import 'package:likeminds_feed_nova_fl/src/models/post/post_view_model.dart';
import 'package:likeminds_feed_nova_fl/src/services/likeminds_service.dart';
import 'package:likeminds_feed_nova_fl/src/utils/constants/assets_constants.dart';
import 'package:likeminds_feed_nova_fl/src/utils/post/post_utils.dart';
import 'package:likeminds_feed_nova_fl/src/utils/tagging/tagging_textfield_ta.dart';
import 'package:likeminds_feed_nova_fl/src/views/post/post_composer_header.dart';
import 'package:likeminds_feed_nova_fl/src/widgets/post/repost_widget.dart';
import 'package:likeminds_feed_ui_fl/likeminds_feed_ui_fl.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:url_launcher/url_launcher.dart';

// TODO: uncomment code for topic feature
//import 'package:likeminds_feed_nova_fl/src/widgets/topic/topic_popup.dart';

class EditPostScreen extends StatefulWidget {
  static const String route = '/edit_post_screen';
  final String postId;
  final List<TopicUI> selectedTopics;
  final CompanyUI? company;

  const EditPostScreen({
    super.key,
    required this.postId,
    required this.selectedTopics,
    this.company,
  });

  @override
  State<EditPostScreen> createState() => _EditPostScreenState();
}

class _EditPostScreenState extends State<EditPostScreen> {
  late Future<GetPostResponse> postFuture;
  final FocusNode _focusNode = FocusNode();
  TextEditingController? textEditingController;

  // TODO: uncomment code for topic feature
  // Future<GetTopicsResponse>? getTopicsResponse;
  // ValueNotifier<bool> rebuildTopicFeed = ValueNotifier<bool>(false);
  // List<TopicUI> selectedTopics = [];
  ValueNotifier<bool> rebuildAttachments = ValueNotifier(false);
  late String postId;
  Post? postDetails;
  NewPostBloc? newPostBloc;
  List<Attachment>? attachments;
  User? user;
  bool isDocumentPost = false; // flag for document or media post
  bool isMediaPost = false;
  String previewLink = '';
  String convertedPostText = '';
  AttachmentPostViewData? linkModel;
  List<UserTag> userTags = [];
  bool showLinkPreview =
      true; // if set to false link preview should not be displayed
  Timer? _debounce;
  Size? screenSize;
  ThemeData? theme;
  Map<String, WidgetModel>? widgets;
  bool showRepost = false;
  Map<String, Post>? repostedPosts;

  void _onTextChanged(String p0) {
    if (_debounce?.isActive ?? false) {
      _debounce?.cancel();
    }
    _debounce = Timer(const Duration(milliseconds: 500), () {
      handleTextLinks(p0);
    });
  }

  Widget getPostDocument(double width) {
    return ListView.builder(
      itemCount: attachments!.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) => LMDocument(
        size:
            getFileSizeString(bytes: attachments![index].attachmentMeta.size!),
        showBorder: false,
        type: attachments![index].attachmentMeta.format!,
        backgroundColor: theme!.colorScheme.surface,
        textColor: theme!.colorScheme.onPrimary,
        documentIcon: Container(
          width: 48,
          height: 48,
          decoration: ShapeDecoration(
            color: theme!.colorScheme.primaryContainer,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          ),
          child: Center(
            child: LMTextView(
              text: 'PDF',
              textStyle: theme!.textTheme.titleLarge!.copyWith(fontSize: 18),
            ),
          ),
        ),
        documentUrl: attachments![index].attachmentMeta.url,
        onTap: () {
          Uri fileUrl = Uri.parse(attachments![index].attachmentMeta.url!);
          launchUrl(fileUrl, mode: LaunchMode.platformDefault);
        },
      ),
    );
  }

  // TODO: uncomment code for topic feature
  // void updateSelectedTopics(List<TopicUI> topics) {
  //   selectedTopics = topics;
  //   rebuildTopicFeed.value = !rebuildTopicFeed.value;
  // }

  void handleTextLinks(String text) async {
    String link = getFirstValidLinkFromString(text);
    if (link.isNotEmpty && showLinkPreview) {
      previewLink = link;
      DecodeUrlRequest request =
          (DecodeUrlRequestBuilder()..url(previewLink)).build();
      DecodeUrlResponse response =
          await locator<LikeMindsService>().decodeUrl(request);
      if (response.success == true) {
        OgTags? responseTags = response.ogTags;
        linkModel = AttachmentPostViewData(
          mediaType: MediaType.link,
          link: previewLink,
          ogTags: AttachmentMetaOgTags(
            description: responseTags!.description,
            image: responseTags.image,
            title: responseTags.title,
            url: responseTags.url,
          ),
        );
      }
      rebuildAttachments.value = !rebuildAttachments.value;
    } else if (link.isEmpty) {
      linkModel = null;
      attachments?.removeWhere((element) => element.attachmentType == 4);
      rebuildAttachments.value = !rebuildAttachments.value;
    }
  }

  @override
  void initState() {
    super.initState();
    user = UserLocalPreference.instance.fetchUserData();
    postId = widget.postId;
    textEditingController = TextEditingController();
    postFuture = locator<LikeMindsService>().getPost((GetPostRequestBuilder()
          ..postId(widget.postId)
          ..page(1)
          ..pageSize(10))
        .build());
    // TODO: uncomment code for topic feature
    // getTopicsResponse =
    //     locator<LikeMindsService>().getTopics((GetTopicsRequestBuilder()
    //           ..page(1)
    //           ..pageSize(20)
    //           ..isEnabled(true))
    //         .build());
    // selectedTopics = widget.selectedTopics;
    if (_focusNode.canRequestFocus) {
      _focusNode.requestFocus();
    }
  }

  @override
  void didUpdateWidget(covariant EditPostScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    postId = widget.postId;
    // TODO: uncomment code for topic feature
    //selectedTopics = widget.selectedTopics;
  }

  void checkTextLinks() {
    String link = getFirstValidLinkFromString(textEditingController!.text);
    if (link.isEmpty) {
      linkModel = null;
      attachments?.removeWhere((element) => element.attachmentType == 4);
    } else if (linkModel != null &&
        showLinkPreview &&
        !isDocumentPost &&
        !isMediaPost) {
      attachments = [
        Attachment(
          attachmentType: 4,
          attachmentMeta: AttachmentMeta(
            url: linkModel?.link,
            ogTags: AttachmentMetaOgTags(
              description: linkModel?.ogTags?.description,
              image: linkModel?.ogTags?.image,
              title: linkModel?.ogTags?.title,
              url: linkModel?.ogTags?.url,
            ),
          ),
        ),
      ];
    } else if (!showLinkPreview) {
      attachments?.removeWhere((element) => element.attachmentType == 4);
    }
  }

  void setPostData(Post post, Map<String, Post> repostedPosts) {
    this.repostedPosts = repostedPosts;
    if (postDetails == null) {
      postDetails = post;
      convertedPostText = TaggingHelper.convertRouteToTag(post.text);
      textEditingController!.value = TextEditingValue(text: convertedPostText);
      textEditingController!.selection = TextSelection.fromPosition(
          TextPosition(offset: textEditingController!.text.length));
      userTags = TaggingHelper.addUserTagsIfMatched(post.text);
      attachments = post.attachments ?? [];
      if (attachments != null && attachments!.isNotEmpty) {
        if (attachments![0].attachmentType == 1 ||
            attachments![0].attachmentType == 2) {
          isMediaPost = true;
          showLinkPreview = false;
        } else if (attachments![0].attachmentType == 3) {
          isDocumentPost = true;
          showLinkPreview = false;
        } else if (attachments![0].attachmentType == 4) {
          linkModel = AttachmentPostViewData(
              mediaType: MediaType.link,
              link: attachments![0].attachmentMeta.url,
              ogTags: attachments![0].attachmentMeta.ogTags);
        } else if (attachments![0].attachmentType == 8) {
          showRepost = true;
          isMediaPost = false;
          showLinkPreview = false;
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
    screenSize = MediaQuery.of(context).size;
    newPostBloc = locator<BlocService>().newPostBlocProvider;
    theme = ColorTheme.novaTheme;
    return WillPopScope(
      onWillPop: () {
        if (textEditingController!.text != convertedPostText) {
          showDialog(
              context: context,
              builder: (dialogContext) => AlertDialog(
                    shadowColor: Colors.transparent,
                    backgroundColor: theme!.colorScheme.background,
                    elevation: 0,
                    content: LMTextView(
                      text: 'Are you sure you want to discard your changes?',
                      maxLines: 3,
                      textStyle: theme!.textTheme.labelLarge,
                    ),
                    actions: <Widget>[
                      Padding(
                        padding:
                            const EdgeInsets.only(right: 4.0, bottom: 10.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            LMTextButton(
                              text: LMTextView(
                                text: 'No thanks',
                                textStyle: theme!.textTheme.headlineMedium,
                              ),
                              onTap: () {
                                Navigator.of(dialogContext).pop();
                              },
                            ),
                            kHorizontalPaddingLarge,
                            LMTextButton(
                              text: LMTextView(
                                text: 'Discard',
                                textStyle: theme!.textTheme.headlineMedium!
                                    .copyWith(color: theme!.colorScheme.error),
                              ),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16.0, vertical: 4.0),
                              onTap: () {
                                Navigator.of(dialogContext).pop();
                                Navigator.of(context).pop();
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ));
        } else {
          Navigator.of(context).pop();
        }
        return Future(() => false);
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark,
        child: Scaffold(
          resizeToAvoidBottomInset: false,
          backgroundColor: theme!.colorScheme.background,
          // TODO: uncomment code for topic feature
          // floatingActionButton: Padding(
          //   padding: const EdgeInsets.only(bottom: 64.0, left: 16.0),
          //   child: Row(
          //     mainAxisAlignment: MainAxisAlignment.start,
          //     children: [
          //       Align(
          //         alignment: Alignment.bottomLeft,
          //         child: FutureBuilder<GetTopicsResponse>(
          //           future: getTopicsResponse,
          //           builder: (context, snapshot) {
          //             if (snapshot.connectionState == ConnectionState.done &&
          //                 snapshot.hasData &&
          //                 snapshot.data!.success == true) {
          //               if (snapshot.data!.topics!.isNotEmpty) {
          //                 return ValueListenableBuilder(
          //                   valueListenable: rebuildTopicFeed,
          //                   builder: (context, _, __) {
          //                     return GestureDetector(
          //                       onTap: () async {
          //                         if (_focusNode.hasFocus) {
          //                           FocusScopeNode currentFocus =
          //                               FocusScope.of(context);
          //                           currentFocus.unfocus();
          //                           await Future.delayed(
          //                               const Duration(milliseconds: 500));
          //                         }
          //                         _controllerPopUp.showMenu();
          //                       },
          //                       child: AbsorbPointer(
          //                         absorbing: true,
          //                         child: CustomPopupMenu(
          //                           controller: _controllerPopUp,
          //                           showArrow: false,
          //                           verticalMargin: 10,
          //                           horizontalMargin: 16.0,
          //                           pressType: PressType.singleClick,
          //                           menuBuilder: () => TopicPopUp(
          //                             selectedTopics: selectedTopics,
          //                             backgroundColor:
          //                                 theme!.colorScheme.surface,
          //                             selectedTextColor:
          //                                 theme!.colorScheme.onPrimary,
          //                             unSelectedTextColor:
          //                                 theme!.colorScheme.onPrimary,
          //                             selectedColor: theme!.colorScheme.primary,
          //                             isEnabled: true,
          //                             onTopicSelected:
          //                                 (updatedTopics, tappedTopic) {
          //                               if (selectedTopics.isEmpty) {
          //                                 selectedTopics.add(tappedTopic);
          //                               } else {
          //                                 if (selectedTopics.first.id ==
          //                                     tappedTopic.id) {
          //                                   selectedTopics.clear();
          //                                 } else {
          //                                   selectedTopics.clear();
          //                                   selectedTopics.add(tappedTopic);
          //                                 }
          //                               }
          //                               _controllerPopUp.hideMenu();
          //                               rebuildTopicFeed.value =
          //                                   !rebuildTopicFeed.value;
          //                             },
          //                           ),
          //                           child: Container(
          //                             height: 36,
          //                             alignment: Alignment.bottomLeft,
          //                             margin: const EdgeInsets.only(left: 16.0),
          //                             decoration: BoxDecoration(
          //                               borderRadius:
          //                                   BorderRadius.circular(500),
          //                               color: theme!.colorScheme.primary,
          //                             ),
          //                             child: LMTopicChip(
          //                               topic: selectedTopics.isEmpty
          //                                   ? (TopicUIBuilder()
          //                                         ..id("0")
          //                                         ..isEnabled(true)
          //                                         ..name("Topic"))
          //                                       .build()
          //                                   : selectedTopics.first,
          //                               textStyle: theme!.textTheme.bodyMedium,
          //                               icon: LMIcon(
          //                                 type: LMIconType.icon,
          //                                 icon: CupertinoIcons.chevron_down,
          //                                 size: 16,
          //                                 color: theme!.colorScheme.onPrimary,
          //                               ),
          //                             ),
          //                           ),
          //                         ),
          //                       ),
          //                     );
          //                   },
          //                 );
          //               }
          //             }
          //             return const SizedBox();
          //           },
          //         ),
          //       ),
          //     ],
          //   ),
          // ),
          body: SafeArea(
            child: FutureBuilder(
                future: postFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: CircularProgressIndicator(
                        color: ColorTheme.novaTheme.primaryColor,
                      ),
                    );
                  } else if (snapshot.connectionState == ConnectionState.done) {
                    GetPostResponse response = snapshot.data!;
                    widgets = response.widgets;
                    if (response.success) {
                      setPostData(response.post!, response.repostedPosts!);
                      return postEditWidget();
                    } else {
                      return postErrorScreen(response.errorMessage!);
                    }
                  }
                  return const SizedBox();
                }),
          ),
        ),
      ),
    );
  }

  Widget postErrorScreen(String error) {
    return Center(
      child: Text(error),
    );
  }

  Widget postEditWidget() {
    return Stack(
      children: [
        Column(
          children: <Widget>[
            PostComposerHeader(
              onPressedBack: () {
                if (textEditingController!.text != convertedPostText) {
                  showDialog(
                    context: context,
                    builder: (dialogContext) => AlertDialog(
                      shadowColor: Colors.transparent,
                      backgroundColor: theme!.colorScheme.background,
                      elevation: 0,
                      content: LMTextView(
                        text: 'Are you sure you want to discard your changes?',
                        maxLines: 3,
                        textStyle: theme!.textTheme.labelLarge,
                      ),
                      actions: <Widget>[
                        Padding(
                          padding:
                              const EdgeInsets.only(right: 4.0, bottom: 10.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              LMTextButton(
                                text: LMTextView(
                                  text: 'No thanks',
                                  textStyle: theme!.textTheme.headlineMedium,
                                ),
                                onTap: () {
                                  Navigator.of(dialogContext).pop();
                                },
                              ),
                              kHorizontalPaddingLarge,
                              LMTextButton(
                                text: LMTextView(
                                  text: 'Discard',
                                  textStyle: theme!.textTheme.headlineMedium!
                                      .copyWith(
                                          color: theme!.colorScheme.error),
                                ),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0, vertical: 4.0),
                                onTap: () {
                                  Navigator.of(dialogContext).pop();
                                  Navigator.of(context).pop();
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                } else {
                  Navigator.of(context).pop();
                }
              },
              title: const LMTextView(
                text: "",
              ),
              actionText: LMTextView(
                text: "Update",
                textStyle: theme!.textTheme.bodyMedium,
              ),
              onTap: () async {
                if (textEditingController!.text.isNotEmpty ||
                    (postDetails!.attachments != null &&
                        postDetails!.attachments!.isNotEmpty)) {
                  checkTextLinks();

                  userTags = TaggingHelper.matchTags(
                      textEditingController!.text, userTags);
                  String result = TaggingHelper.encodeString(
                      textEditingController!.text, userTags);

                  // List<String> disabledTopics = [];
                  // for (TopicUI topic in selectedTopics) {
                  //   if (!topic.isEnabled) {
                  //     disabledTopics.add(topic.name);
                  //   }
                  // }
                  //
                  // if (disabledTopics.isNotEmpty) {
                  //   showDialog(
                  //     context: context,
                  //     builder: (dialogContext) => AlertDialog(
                  //       shadowColor: Colors.transparent,
                  //       backgroundColor: theme!.colorScheme.background,
                  //       elevation: 0,
                  //       title: const Text(
                  //         "Topic Disabled",
                  //         style: TextStyle(
                  //           fontWeight: FontWeight.w700,
                  //           fontSize: 16,
                  //         ),
                  //       ),
                  //       content: LMTextView(
                  //         text:
                  //             "The following topics have been disabled. Please remove them to save the post.\n${disabledTopics.join(', ')}.",
                  //         textStyle: theme!.textTheme.labelLarge,
                  //       ),
                  //       actions: <Widget>[
                  //         Padding(
                  //           padding:
                  //               const EdgeInsets.only(right: 4.0, bottom: 10.0),
                  //           child: Row(
                  //             mainAxisAlignment: MainAxisAlignment.end,
                  //             children: [
                  //               LMTextButton(
                  //                 text: LMTextView(
                  //                   text: 'Okay',
                  //                   textStyle: theme!.textTheme.headlineMedium!
                  //                       .copyWith(
                  //                           color: theme!.colorScheme.error),
                  //                 ),
                  //                 padding: const EdgeInsets.symmetric(
                  //                     horizontal: 16.0, vertical: 4.0),
                  //                 onTap: () {
                  //                   Navigator.of(dialogContext).pop();
                  //                 },
                  //               ),
                  //             ],
                  //           ),
                  //         ),
                  //       ],
                  //     ),
                  //   );
                  //   return;
                  // }
                  newPostBloc?.add(
                    EditPost(
                      postText: result,
                      attachments: attachments,
                      postId: postId,
                      // TODO: uncomment code for topic feature
                      selectedTopics: const [], //selectedTopics,
                      isRepost: postDetails!.isRepost,
                    ),
                  );
                  Navigator.of(context).pop();
                } else {
                  toast(
                    "Can't save a post without text or attachments",
                    duration: Toast.LENGTH_LONG,
                  );
                }
              },
            ),
            kVerticalPaddingMedium,
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 6.0,
                ),
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            LMProfilePicture(
                              fallbackText: widget.company?.name ?? user!.name,
                              imageUrl:
                                  widget.company?.imageUrl ?? user!.imageUrl,
                              backgroundColor: theme!.primaryColor,
                              boxShape: BoxShape.circle,
                              onTap: () {
                                if (user!.sdkClientInfo != null) {
                                  locator<LikeMindsService>().routeToProfile(
                                      user!.sdkClientInfo!.userUniqueId);
                                }
                              },
                              size: 48,
                            ),
                            kHorizontalPaddingLarge,
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(top: 6.0),
                                child: LMTextView(
                                  text: widget.company?.name ?? user!.name,
                                  overflow: TextOverflow.ellipsis,
                                  textStyle: theme!.textTheme.titleMedium,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SliverPadding(
                      padding: EdgeInsets.only(
                        top: 16.0,
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: SizedBox(
                        width: screenSize!.width - 24.0,
                        child: TaggingAheadTextField(
                          isDown: true,
                          minLines: 3,
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: 'What\'s on your mind?',
                            hintStyle: theme!.textTheme.labelMedium,
                          ),
                          onTagSelected: (tag) {
                            userTags.add(tag);
                          },
                          controller: textEditingController!,
                          focusNode: _focusNode,
                          onChange: _onTextChanged,
                        ),
                      ),
                    ),
                    const SliverPadding(
                      padding: EdgeInsets.only(
                        top: 20.0,
                      ),
                    ),
                    if (postDetails!.isRepost && showRepost)
                      SliverToBoxAdapter(
                        child: NovaRepostWidget(
                          post: PostViewModel.fromPost(
                              post: repostedPosts![postDetails!.attachments!
                                  .first.attachmentMeta.entityId]!),
                          user: user!,
                        ),
                      ),
                    if (!showRepost)
                      SliverToBoxAdapter(
                        child: ValueListenableBuilder(
                            valueListenable: rebuildAttachments,
                            builder: (context, value, child) => ((attachments !=
                                                null &&
                                            attachments!.isNotEmpty) &&
                                        mapIntToMediaType(attachments!
                                                .first.attachmentType) ==
                                            MediaType.link &&
                                        showLinkPreview) ||
                                    (linkModel != null && showLinkPreview)
                                ? Stack(
                                    children: [
                                      LMLinkPreview(
                                        linkModel: linkModel,
                                        backgroundColor:
                                            theme!.colorScheme.surface,
                                        showLinkUrl: false,
                                        onTap: () {
                                          launchUrl(
                                            Uri.parse(
                                                linkModel?.ogTags?.url ?? ''),
                                            mode:
                                                LaunchMode.externalApplication,
                                          );
                                        },
                                        border: const Border(),
                                        title: LMTextView(
                                          text:
                                              linkModel?.ogTags?.title ?? "--",
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          textStyle:
                                              theme!.textTheme.titleMedium,
                                        ),
                                        subtitle: LMTextView(
                                          text:
                                              linkModel?.ogTags?.description ??
                                                  "--",
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          textStyle:
                                              theme!.textTheme.displayMedium,
                                        ),
                                      ),
                                      Positioned(
                                        top: 5,
                                        right: 5,
                                        child: GestureDetector(
                                          onTap: () {
                                            showLinkPreview = false;
                                            rebuildAttachments.value =
                                                !rebuildAttachments.value;
                                          },
                                          child: const CloseButtonIcon(),
                                        ),
                                      )
                                    ],
                                  )
                                : const SizedBox()),
                      ),
                    if (!showRepost &&
                        attachments != null &&
                        attachments!.isNotEmpty &&
                        mapIntToMediaType(attachments!.first.attachmentType) !=
                            MediaType.link)
                      mapIntToMediaType(attachments!.first.attachmentType) ==
                              MediaType.document
                          ? SliverToBoxAdapter(
                              child: getPostDocument(screenSize!.width))
                          : SliverToBoxAdapter(
                              child: Builder(builder: (context) {
                                List<Attachment> mediaList = [...attachments!];
                                mediaList.removeWhere(
                                    (element) => element.attachmentType == 5);
                                int mediaLength = mediaList.length;
                                return Container(
                                  padding: const EdgeInsets.only(
                                    top: kPaddingSmall,
                                  ),
                                  height: mediaLength == 1
                                      ? screenSize!.width - 32
                                      : 200,
                                  alignment: Alignment.center,
                                  child: ListView.builder(
                                    itemCount: mediaLength,
                                    physics: mediaLength == 1
                                        ? const NeverScrollableScrollPhysics()
                                        : null,
                                    scrollDirection: Axis.horizontal,
                                    itemBuilder:
                                        (BuildContext context, int index) {
                                      return Row(
                                        children: [
                                          SizedBox(
                                            child: Stack(
                                              children: [
                                                mapIntToMediaType(mediaList[
                                                                index]
                                                            .attachmentType) ==
                                                        MediaType.video
                                                    ? ClipRRect(
                                                        borderRadius:
                                                            const BorderRadius
                                                                .all(
                                                                Radius.circular(
                                                                    20)),
                                                        child: Container(
                                                          height: mediaLength ==
                                                                  1
                                                              ? screenSize!
                                                                      .width -
                                                                  32
                                                              : 200,
                                                          width: mediaLength ==
                                                                  1
                                                              ? screenSize!
                                                                      .width -
                                                                  32
                                                              : 200,
                                                          color: Colors.black,
                                                          child: LMVideo(
                                                            videoUrl: mediaList[
                                                                    index]
                                                                .attachmentMeta
                                                                .url!,
                                                            height: mediaLength ==
                                                                    1
                                                                ? screenSize!
                                                                        .width -
                                                                    32
                                                                : 200,
                                                            width: mediaLength ==
                                                                    1
                                                                ? screenSize!
                                                                        .width -
                                                                    32
                                                                : 200,
                                                            boxFit:
                                                                BoxFit.cover,
                                                            showControls: false,
                                                            borderRadius: 18,
                                                          ),
                                                        ),
                                                      )
                                                    : ClipRRect(
                                                        borderRadius:
                                                            const BorderRadius
                                                                .all(
                                                                Radius.circular(
                                                                    20)),
                                                        child: Container(
                                                          height: mediaLength ==
                                                                  1
                                                              ? screenSize!
                                                                      .width -
                                                                  32
                                                              : 200,
                                                          width: mediaLength ==
                                                                  1
                                                              ? screenSize!
                                                                      .width -
                                                                  32
                                                              : 200,
                                                          color: Colors.black,
                                                          child: LMImage(
                                                            height: mediaLength ==
                                                                    1
                                                                ? screenSize!
                                                                        .width -
                                                                    32
                                                                : 200,
                                                            width: mediaLength ==
                                                                    1
                                                                ? screenSize!
                                                                        .width -
                                                                    32
                                                                : 200,
                                                            boxFit:
                                                                BoxFit.cover,
                                                            borderRadius: 18,
                                                            imageUrl: mediaList[
                                                                    index]
                                                                .attachmentMeta
                                                                .url!,
                                                          ),
                                                        ),
                                                      ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                        ],
                                      );
                                    },
                                  ),
                                );
                              }),
                            ),
                    const SliverPadding(
                      padding: EdgeInsets.only(
                        top: 80.0,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        Positioned(
          bottom: 0,
          child: Container(
            color: theme!.colorScheme.background,
            width: screenSize!.width,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              mainAxisSize: MainAxisSize.max,
              children: [
                Padding(
                  padding: const EdgeInsets.only(
                      right: 16.0, bottom: 16.0, top: 8.0),
                  child: LMIconButton(
                    icon: LMIcon(
                      type: LMIconType.svg,
                      assetPath: kAssetMentionIcon,
                      color: theme!.colorScheme.primary,
                      boxPadding: 0,
                      size: 28,
                    ),
                    onTap: (active) {
                      if (!_focusNode.hasFocus) {
                        _focusNode.requestFocus();
                      }
                      String currentText = textEditingController!.text;
                      if (currentText.isNotEmpty) {
                        currentText = '$currentText @';
                      } else {
                        currentText = '@';
                      }
                      textEditingController!.value =
                          TextEditingValue(text: currentText);
                    },
                  ),
                ),
              ],
            ),
          ),
        )
      ],
    );
  }
}
