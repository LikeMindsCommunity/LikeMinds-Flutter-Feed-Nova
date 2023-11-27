import 'dart:async';
import 'dart:io';
import 'package:custom_pop_up_menu/custom_pop_up_menu.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:flutter/services.dart';

import 'package:likeminds_feed/likeminds_feed.dart';
import 'package:likeminds_feed_nova_fl/likeminds_feed_nova_fl.dart';
import 'package:likeminds_feed_nova_fl/src/blocs/new_post/new_post_bloc.dart';
import 'package:likeminds_feed_nova_fl/src/persistence/logger/logger.dart';
import 'package:likeminds_feed_nova_fl/src/services/likeminds_service.dart';
import 'package:likeminds_feed_nova_fl/src/utils/constants/assets_constants.dart';
import 'package:likeminds_feed_nova_fl/src/utils/post/post_media_picker.dart';
import 'package:likeminds_feed_nova_fl/src/utils/post/post_utils.dart';
import 'package:likeminds_feed_nova_fl/src/utils/tagging/tagging_textfield_ta.dart';
import 'package:likeminds_feed_nova_fl/src/views/post/post_composer_header.dart';

// TODO Nova: Uncomment this when topic is enabled
// import 'package:likeminds_feed_nova_fl/src/widgets/topic/topic_popup.dart';

import 'package:likeminds_feed_ui_fl/likeminds_feed_ui_fl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

class NewPostScreen extends StatefulWidget {
  CompanyUI? company;

  NewPostScreen({super.key, this.company});

  @override
  State<NewPostScreen> createState() => _NewPostScreenState();
}

class _NewPostScreenState extends State<NewPostScreen> {
  late String displayName;
  late String displayImageURL;
  late String creatorId;
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  // TODO Nova: Uncomment this when topic is enabled
  // Future<GetTopicsResponse>? getTopicsResponse;
  ValueNotifier<bool> rebuildLinkPreview = ValueNotifier(false);
  ValueNotifier<bool> rebuildPostButton = ValueNotifier(false);
  List<TopicUI> selectedTopic = [];
  ValueNotifier<bool> rebuildTopicFloatingButton = ValueNotifier(false);
  final CustomPopupMenuController _controllerPopUp =
      CustomPopupMenuController();
  ThemeData? theme;

  NewPostBloc? newPostBloc;
  late final User user;

  List<MediaModel> postMedia = [];
  List<UserTag> userTags = [];
  String? result;

  bool isDocumentPost = true; // flag for document or media post
  bool isMediaPost = true;
  bool isUploading = false;
  bool isVideoAttached = false;

  String previewLink = '';
  MediaModel? linkModel;
  bool showLinkPreview =
      true; // if set to false link preview should not be displayed
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    user = UserLocalPreference.instance.fetchUserData();
    // TODO Nova: Uncomment this when topic is enabled
    // getTopicsResponse =
    //     locator<LikeMindsService>().getTopics((GetTopicsRequestBuilder()
    //           ..page(1)
    //           ..pageSize(20)
    //           ..isEnabled(true))
    //         .build());
    newPostBloc = locator<BlocService>().newPostBlocProvider;
    if (_focusNode.canRequestFocus) {
      _focusNode.requestFocus();
    }
    if (widget.company != null) {
      displayName = widget.company!.name;
      displayImageURL = widget.company!.imageUrl;
      creatorId = widget.company!.id;
    } else {
      displayName = user.name;
      displayImageURL = user.imageUrl;
      creatorId = user.userUniqueId;
    }
  }

  bool checkIfPostMediaIsAttached() {
    if (postMedia.isNotEmpty) {
      for (MediaModel media in postMedia) {
        if (media.mediaType == MediaType.image ||
            media.mediaType == MediaType.video ||
            media.mediaType == MediaType.document ||
            media.mediaType == MediaType.link) {
          return true;
        }
      }
    }
    return false;
  }

  /*
  * Removes the media from the list
  * whenever the user taps on the X button
  */
  void removeAttachmenetAtIndex(int index) {
    if (postMedia.isNotEmpty) {
      MediaModel mediaToBeRemoved = postMedia[index];
      if (mediaToBeRemoved.mediaType == MediaType.document) {
        int docCount = 0;
        for (var element in postMedia) {
          if (element.mediaType == MediaType.document) {
            docCount++;
          }
        }
        LMAnalytics.get().track(
            AnalyticsKeys.documentAttachedInPost, {'document_count': docCount});
      } else if (mediaToBeRemoved.mediaType == MediaType.video) {
        int videoCount = 0;
        for (var element in postMedia) {
          if (element.mediaType == MediaType.video) {
            videoCount++;
          }
        }
        LMAnalytics.get().track(
            AnalyticsKeys.videoAttachedToPost, {'video_count': videoCount});
      } else if (mediaToBeRemoved.mediaType == MediaType.image) {
        int imageCount = 0;
        for (var element in postMedia) {
          if (element.mediaType == MediaType.image) {
            imageCount++;
          }
        }
        LMAnalytics.get().track(
            AnalyticsKeys.imageAttachedToPost, {'image_count': imageCount});
      }
      postMedia.removeAt(index);
      if (postMedia.isEmpty) {
        isDocumentPost = true;
        isMediaPost = true;
        showLinkPreview = true;
        isVideoAttached = false;
      }
      setState(() {});
    }
  }

  // this function initiliases postMedia list
  // with photos/videos picked by the user
  void setPickedMediaFiles(List<MediaModel> pickedMediaFiles) {
    if (postMedia.isEmpty) {
      postMedia = <MediaModel>[...pickedMediaFiles];
    } else {
      postMedia.addAll(pickedMediaFiles);
    }
    if (pickedMediaFiles.isNotEmpty &&
        pickedMediaFiles.first.mediaType == MediaType.document) {
      int documentCount = 0;
      for (var element in postMedia) {
        if (element.mediaType == MediaType.document) {
          documentCount++;
        }
      }
      LMAnalytics.get().track(AnalyticsKeys.documentAttachedInPost,
          {'document_count': documentCount});
    } else {
      int imageCount = 0;
      if (postMedia.first.mediaType == MediaType.video) {
        LMAnalytics.get()
            .track(AnalyticsKeys.videoAttachedToPost, {'video_count': 1});
        isVideoAttached = true;
      } else {
        int imageCount = 0;
        for (var element in postMedia) {
          if (element.mediaType == MediaType.image) {
            imageCount++;
          }
        }
        LMAnalytics.get().track(
            AnalyticsKeys.imageAttachedToPost, {'image_count': imageCount});
      }
      LMAnalytics.get().track(
          AnalyticsKeys.imageAttachedToPost, {'image_count': imageCount});
    }
  }

  /*
  * Changes state to uploading
  * for showing a circular loader while the user is
  * picking files
  */
  void onUploading() {
    setState(() {
      isUploading = true;
    });
  }

  /*
  * Changes state to uploaded
  * for showing the picked files
  */
  void onUploadedMedia(bool uploadResponse) {
    if (uploadResponse) {
      isMediaPost = true;
      showLinkPreview = false;
      isDocumentPost = false;
      setState(() {
        isUploading = false;
      });
    } else {
      if (postMedia.isEmpty) {
        isMediaPost = true;
        isVideoAttached = false;
        showLinkPreview = true;
      }
      setState(() {
        isUploading = false;
      });
    }
    rebuildPostButton.value = !rebuildPostButton.value;
  }

  /*
  * updated the post media list
  * with the files picked by the user
  */
  void onUploadedDocument(bool uploadResponse) {
    if (uploadResponse) {
      isDocumentPost = true;
      showLinkPreview = false;
      isMediaPost = false;
      setState(() {
        isUploading = false;
      });
    } else {
      if (postMedia.isEmpty) {
        isDocumentPost = true;
        isMediaPost = true;
        isVideoAttached = false;
        showLinkPreview = true;
      }
      setState(() {
        isUploading = false;
      });
    }
    rebuildPostButton.value = !rebuildPostButton.value;
  }

  /*
  * This function return a list
  * containing LMDocument widget
  * which generates preview for a document
  */
  Widget getPostDocument(double width) {
    return ListView.builder(
      itemCount: postMedia.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) => LMDocument(
        size: getFileSizeString(bytes: postMedia[index].size!),
        onTap: () {
          OpenFilex.open(postMedia[index].mediaFile!.path);
        },
        type: postMedia[index].format!,
        showBorder: false,
        backgroundColor: theme!.colorScheme.surface,
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
        documentFile: postMedia[index].mediaFile,
        removeIcon: const LMIcon(
          type: LMIconType.icon,
          icon: Icons.close,
          color: Colors.white,
          size: 28,
        ),
        onRemove: () => removeAttachmenetAtIndex(index),
      ),
    );
  }

  /*
  * Takes a string as input
  * extracts the first valid link from the string
  * decodes the url using LikeMinds SDK
  * and generates a preview for the link
  */
  void handleTextLinks(String text) async {
    String link = getFirstValidLinkFromString(text);
    if (link.isNotEmpty) {
      previewLink = link;
      DecodeUrlRequest request =
          (DecodeUrlRequestBuilder()..url(previewLink)).build();
      DecodeUrlResponse response =
          await locator<LikeMindsService>().decodeUrl(request);
      if (response.success == true) {
        OgTags? responseTags = response.ogTags;
        linkModel = MediaModel(
          mediaType: MediaType.link,
          link: previewLink,
          ogTags: AttachmentMetaOgTags(
            description: responseTags!.description,
            image: responseTags.image,
            title: responseTags.title,
            url: responseTags.url,
          ),
        );
        LMAnalytics.get().track(
          AnalyticsKeys.linkAttachedInPost,
          {
            'link': previewLink,
          },
        );
        if (postMedia.isEmpty) {
          rebuildLinkPreview.value = !rebuildLinkPreview.value;
        }
      }
    } else if (link.isEmpty) {
      linkModel = null;
      rebuildLinkPreview.value = !rebuildLinkPreview.value;
    }
  }

  /*
  * This function adds the link model in attachemnt
  * If the link model is not present in the attachment
  * and the link preview is enabled (no media is there)
  */
  void checkTextLinks() {
    String link = getFirstValidLinkFromString(_controller.text);
    if (link.isEmpty) {
      linkModel = null;
    } else if (linkModel != null &&
        checkIfMediaIsAttached() &&
        showLinkPreview) {
      postMedia.add(linkModel!);
    }
  }

  // Checks if a attachment is there apart from custom widget [type 5]
  bool checkIfMediaIsAttached() {
    if (postMedia.isNotEmpty) {
      for (MediaModel media in postMedia) {
        if (media.mediaType == MediaType.image ||
            media.mediaType == MediaType.video ||
            media.mediaType == MediaType.document) {
          return false;
        }
      }
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    theme = ColorTheme.novaTheme;
    Size screenSize = MediaQuery.of(context).size;
    return WillPopScope(
      onWillPop: () {
        showDialog(
          context: context,
          builder: (dialogContext) => AlertDialog(
            shadowColor: Colors.transparent,
            backgroundColor: theme!.colorScheme.background,
            elevation: 0,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(
                Radius.circular(18),
              ),
            ),
            content: LMTextView(
              text: 'Are you sure you want to discard your changes?',
              maxLines: 3,
              textStyle: theme!.textTheme.labelLarge,
            ),
            actions: <Widget>[
              Padding(
                padding: const EdgeInsets.only(right: 4.0, bottom: 10.0),
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
          ),
        );

        return Future.value(false);
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Scaffold(
          backgroundColor: theme!.colorScheme.background,
          // TODO Nova: Uncomment this when topic is enabled
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
          //                   valueListenable: rebuildTopicFloatingButton,
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
          //                             selectedTopics: selectedTopic,
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
          //                               if (selectedTopic.isEmpty) {
          //                                 selectedTopic.add(tappedTopic);
          //                               } else {
          //                                 if (selectedTopic.first.id ==
          //                                     tappedTopic.id) {
          //                                   selectedTopic.clear();
          //                                 } else {
          //                                   selectedTopic.clear();
          //                                   selectedTopic.add(tappedTopic);
          //                                 }
          //                               }
          //                               _controllerPopUp.hideMenu();
          //                               rebuildTopicFloatingButton.value =
          //                                   !rebuildTopicFloatingButton.value;
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
          //                               topic: selectedTopic.isEmpty
          //                                   ? (TopicUIBuilder()
          //                                         ..id("0")
          //                                         ..isEnabled(true)
          //                                         ..name("Topic"))
          //                                       .build()
          //                                   : selectedTopic.first,
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
            child: Stack(
              children: [
                kVerticalPaddingMedium,
                Padding(
                  padding: const EdgeInsets.only(
                    left: 16.0,
                    right: 16.0,
                    top: 72.0,
                    bottom: 40.0,
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
                                fallbackText: displayName,
                                backgroundColor: theme!.primaryColor,
                                imageUrl: displayImageURL,
                                onTap: () {
                                  if (user.sdkClientInfo != null) {
                                    locator<LikeMindsService>().routeToProfile(
                                        user.sdkClientInfo!.userUniqueId);
                                  }
                                },
                                size: 48,
                                boxShape: BoxShape.circle,
                              ),
                              kHorizontalPaddingLarge,
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 6.0),
                                  child: LMTextView(
                                    text: displayName,
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
                        padding: EdgeInsets.only(bottom: 16.0),
                      ),
                      SliverToBoxAdapter(
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
                          controller: _controller,
                          focusNode: _focusNode,
                          onChange: _onTextChanged,
                        ),
                      ),
                      const SliverPadding(
                        padding: EdgeInsets.only(bottom: 20.0),
                      ),
                      if (isUploading)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.only(
                              top: kPaddingMedium,
                              bottom: kPaddingLarge,
                            ),
                            child: Center(
                              child: LMLoader(
                                color: ColorTheme.novaTheme.primaryColor,
                              ),
                            ),
                          ),
                        ),
                      SliverToBoxAdapter(
                        child: ValueListenableBuilder(
                          valueListenable: rebuildLinkPreview,
                          builder: (context, value, child) {
                            return (postMedia.isEmpty &&
                                    linkModel != null &&
                                    showLinkPreview)
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
                                            rebuildLinkPreview.value =
                                                !rebuildLinkPreview.value;
                                          },
                                          child: const CloseButtonIcon(),
                                        ),
                                      )
                                    ],
                                  )
                                : const SizedBox();
                          },
                        ),
                      ),
                      if (postMedia.isNotEmpty)
                        postMedia.first.mediaType == MediaType.document
                            ? SliverToBoxAdapter(
                                child: getPostDocument(screenSize.width))
                            : SliverToBoxAdapter(
                                child: Builder(builder: (context) {
                                  int mediaLength = postMedia.length;
                                  return Container(
                                    padding: const EdgeInsets.only(
                                      top: kPaddingSmall,
                                    ),
                                    height: mediaLength == 1
                                        ? screenSize.width - 32
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
                                        return Stack(children: [
                                          Row(
                                            children: [
                                              SizedBox(
                                                child: Stack(
                                                  children: [
                                                    postMedia[index]
                                                                .mediaType ==
                                                            MediaType.video
                                                        ? ClipRRect(
                                                            borderRadius:
                                                                const BorderRadius
                                                                    .all(Radius
                                                                        .circular(
                                                                            20)),
                                                            child: Container(
                                                              height: mediaLength ==
                                                                      1
                                                                  ? screenSize
                                                                          .width -
                                                                      32
                                                                  : 200,
                                                              width: mediaLength ==
                                                                      1
                                                                  ? screenSize
                                                                          .width -
                                                                      32
                                                                  : 200,
                                                              color:
                                                                  Colors.black,
                                                              child: LMVideo(
                                                                videoFile: postMedia[
                                                                        index]
                                                                    .mediaFile!,
                                                                height: mediaLength ==
                                                                        1
                                                                    ? screenSize
                                                                            .width -
                                                                        32
                                                                    : 200,
                                                                width: mediaLength ==
                                                                        1
                                                                    ? screenSize
                                                                            .width -
                                                                        32
                                                                    : 200,
                                                                boxFit: BoxFit
                                                                    .cover,
                                                                showControls:
                                                                    false,
                                                                // width:
                                                                //     300,
                                                                borderRadius:
                                                                    18,
                                                                autoPlay: true,
                                                                isMute: true,
                                                              ),
                                                            ),
                                                          )
                                                        : postMedia[index]
                                                                    .mediaFile ==
                                                                null
                                                            ? const SizedBox()
                                                            : ClipRRect(
                                                                borderRadius:
                                                                    const BorderRadius
                                                                        .all(
                                                                        Radius.circular(
                                                                            20)),
                                                                child:
                                                                    Container(
                                                                  height: mediaLength ==
                                                                          1
                                                                      ? screenSize
                                                                              .width -
                                                                          32
                                                                      : 200,
                                                                  width: mediaLength ==
                                                                          1
                                                                      ? screenSize
                                                                              .width -
                                                                          32
                                                                      : 200,
                                                                  color: Colors
                                                                      .black,
                                                                  child:
                                                                      LMImage(
                                                                    height: mediaLength ==
                                                                            1
                                                                        ? screenSize.width -
                                                                            32
                                                                        : 200,
                                                                    width: mediaLength ==
                                                                            1
                                                                        ? screenSize.width -
                                                                            32
                                                                        : 200,
                                                                    boxFit: BoxFit
                                                                        .cover,
                                                                    borderRadius:
                                                                        18,
                                                                    imageFile: postMedia[
                                                                            index]
                                                                        .mediaFile!,
                                                                  ),
                                                                ),
                                                              ),
                                                    Positioned(
                                                      top: 4,
                                                      right: 4,
                                                      child: Container(
                                                        decoration:
                                                            const BoxDecoration(
                                                                boxShadow: [
                                                              BoxShadow(
                                                                  offset:
                                                                      Offset(
                                                                          0.0,
                                                                          5.0),
                                                                  blurRadius:
                                                                      30.0,
                                                                  spreadRadius:
                                                                      -3.0,
                                                                  color: Colors
                                                                      .black38),
                                                            ]),
                                                        child: LMIconButton(
                                                          onTap: (active) =>
                                                              removeAttachmenetAtIndex(
                                                                  index),
                                                          icon: LMIcon(
                                                            type:
                                                                LMIconType.icon,
                                                            icon: CupertinoIcons
                                                                .xmark_circle_fill,
                                                            backgroundColor:
                                                                theme!
                                                                    .colorScheme
                                                                    .background
                                                                    .withOpacity(
                                                                        0.5),
                                                            color: theme!
                                                                .colorScheme
                                                                .onPrimary,
                                                          ),
                                                        ),
                                                      ),
                                                    )
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                            ],
                                          ),
                                        ]);
                                      },
                                    ),
                                  );
                                }),
                              ),
                      const SliverToBoxAdapter(
                        child: SizedBox(
                          height: 80,
                        ),
                      ),
                    ],
                  ),
                ),
                // const Spacer(),
                ValueListenableBuilder(
                  valueListenable: rebuildPostButton,
                  builder: (context, value, child) {
                    return PostComposerHeader(
                      active: _controller.value.text.isNotEmpty ||
                          postMedia.isNotEmpty,
                      onPressedBack: () {
                        showDialog(
                          context: context,
                          builder: (dialogContext) => AlertDialog(
                            shadowColor: Colors.transparent,
                            backgroundColor: theme!.colorScheme.background,
                            elevation: 0,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.all(
                                Radius.circular(18),
                              ),
                            ),
                            content: LMTextView(
                              text:
                                  'Are you sure you want to discard your changes?',
                              maxLines: 3,
                              textStyle: theme!.textTheme.labelLarge,
                            ),
                            actions: <Widget>[
                              Padding(
                                padding: const EdgeInsets.only(
                                    right: 4.0, bottom: 10.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    LMTextButton(
                                      text: LMTextView(
                                        text: 'No thanks',
                                        textStyle:
                                            theme!.textTheme.headlineMedium,
                                      ),
                                      onTap: () {
                                        Navigator.of(dialogContext).pop();
                                      },
                                    ),
                                    kHorizontalPaddingLarge,
                                    LMTextButton(
                                      text: LMTextView(
                                        text: 'Discard',
                                        textStyle: theme!
                                            .textTheme.headlineMedium!
                                            .copyWith(
                                                color:
                                                    theme!.colorScheme.error),
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
                      },
                      title: const LMTextView(text: ''),
                      onTap: () async {
                        _focusNode.unfocus();
                        if (widget.company != null) {
                          GetWidgetRequest request = (GetWidgetRequestBuilder()
                                ..page(1)
                                ..pageSize(10)
                                ..searchKey("metadata.company_id")
                                ..searchValue(widget.company!.id))
                              .build();
                          GetWidgetResponse response =
                              await locator<LikeMindsService>()
                                  .getWidgets(request);
                          Map<String, dynamic> meta = widget.company!.toJson();

                          if (response.success) {
                            String? id = response.widgets?.first.id;
                            meta['entity_id'] = id;
                          }
                          postMedia.add(
                            MediaModel(
                              mediaType: MediaType.widget,
                              widgetsMeta: meta,
                            ),
                          );
                        }

                        String postText = _controller.text;
                        postText = postText.trim();
                        if (postText.isNotEmpty ||
                            checkIfPostMediaIsAttached()) {
                          checkTextLinks();
                          userTags = TaggingHelper.matchTags(
                              _controller.text, userTags);

                          result = TaggingHelper.encodeString(
                              _controller.text, userTags);
                          newPostBloc!.add(
                            CreateNewPost(
                              postText: result!,
                              postMedia: postMedia,
                              // TODO Nova: Uncomment this when topic is enabled
                              selectedTopics: const [], //selectedTopic,
                            ),
                          );
                          Navigator.pop(context);
                        } else {
                          toast(
                            "Can't create a post without text or attachments",
                            duration: Toast.LENGTH_LONG,
                          );
                        }
                      },
                    );
                  },
                ),

                const SizedBox(
                  height: 30,
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: isVideoAttached
                      ? const SizedBox.shrink()
                      : Container(
                          // height: 32,
                          decoration: BoxDecoration(
                            color: theme!.colorScheme.background,
                          ),
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Opacity(
                                opacity: isMediaPost ? 1 : 0.5,
                                child: LMIconButton(
                                  icon: LMIcon(
                                    type: LMIconType.svg,
                                    assetPath: kAssetGalleryIcon,
                                    color: theme!.colorScheme.primary,
                                    boxPadding: 0,
                                    size: 28,
                                  ),
                                  onTap: isMediaPost
                                      ? (active) async {
                                          LMAnalytics.get().track(
                                              AnalyticsKeys.clickedOnAttachment,
                                              {'type': 'image'});
                                          final result =
                                              await handlePermissions(
                                                  context, 1);
                                          if (result) {
                                            pickImages();
                                          }
                                        }
                                      : (active) {},
                                ),
                              ),
                              isMediaPost && postMedia.isEmpty
                                  ? const SizedBox(width: 16)
                                  : const SizedBox.shrink(),
                              isMediaPost && postMedia.isEmpty
                                  ? LMIconButton(
                                      icon: LMIcon(
                                        type: LMIconType.svg,
                                        assetPath: kAssetVideoIcon,
                                        color: theme!.colorScheme.primary,
                                        boxPadding: 0,
                                        size: 28,
                                      ),
                                      onTap: (active) async {
                                        onUploading();
                                        List<MediaModel>? pickedMediaFiles =
                                            await PostMediaPicker.pickVideos(
                                                postMedia.length);
                                        if (pickedMediaFiles != null) {
                                          setPickedMediaFiles(pickedMediaFiles);
                                          onUploadedMedia(true);
                                        } else {
                                          onUploadedMedia(false);
                                        }
                                      },
                                    )
                                  : const SizedBox.shrink(),
                              const SizedBox(width: 16.0),
                              Opacity(
                                opacity: isDocumentPost ? 1 : 0.5,
                                child: LMIconButton(
                                  icon: LMIcon(
                                    type: LMIconType.svg,
                                    assetPath: kAssetDocPDFIcon,
                                    color: theme!.colorScheme.primary,
                                    boxPadding: 0,
                                    size: 28,
                                  ),
                                  onTap: isDocumentPost
                                      ? (active) async {
                                          if (postMedia.length >= 3) {
                                            //  TODO: Add your own toast message for document limit
                                            return;
                                          }
                                          onUploading();
                                          LMAnalytics.get().track(
                                              AnalyticsKeys.clickedOnAttachment,
                                              {'type': 'file'});
                                          List<MediaModel>? pickedMediaFiles =
                                              await PostMediaPicker
                                                  .pickDocuments(
                                                      postMedia.length);
                                          if (pickedMediaFiles != null &&
                                              pickedMediaFiles.isNotEmpty) {
                                            setPickedMediaFiles(
                                                pickedMediaFiles);
                                            onUploadedDocument(true);
                                          } else {
                                            onUploadedDocument(false);
                                          }
                                        }
                                      : (active) {},
                                ),
                              ),
                              const Spacer(),
                              LMIconButton(
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
                                  String currentText = _controller.text;
                                  if (currentText.isNotEmpty) {
                                    currentText = '$currentText @';
                                  } else {
                                    currentText = '@';
                                  }
                                  _controller.value =
                                      TextEditingValue(text: currentText);
                                },
                              ),
                            ],
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _onTextChanged(String p0) {
    rebuildPostButton.value = !rebuildPostButton.value;
    if (_debounce?.isActive ?? false) {
      _debounce?.cancel();
    }
    _debounce = Timer(const Duration(milliseconds: 500), () {
      handleTextLinks(p0);
    });
  }

  Future<bool> handlePermissions(BuildContext context, int mediaType) async {
    if (Platform.isAndroid) {
      PermissionStatus permissionStatus;

      DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      if (androidInfo.version.sdkInt >= 33) {
        if (mediaType == 1) {
          permissionStatus = await Permission.photos.status;
          if (permissionStatus == PermissionStatus.granted) {
            return true;
          } else if (permissionStatus == PermissionStatus.denied) {
            permissionStatus = await Permission.photos.request();
            if (permissionStatus == PermissionStatus.permanentlyDenied) {
              toast(
                'Permissions denied, change app settings',
                duration: Toast.LENGTH_LONG,
              );
              return false;
            } else if (permissionStatus == PermissionStatus.granted) {
              return true;
            } else {
              return false;
            }
          }
        } else {
          permissionStatus = await Permission.videos.status;
          if (permissionStatus == PermissionStatus.granted) {
            return true;
          } else if (permissionStatus == PermissionStatus.denied) {
            permissionStatus = await Permission.videos.request();
            if (permissionStatus == PermissionStatus.permanentlyDenied) {
              toast(
                'Permissions denied, change app settings',
                duration: Toast.LENGTH_LONG,
              );
              return false;
            } else if (permissionStatus == PermissionStatus.granted) {
              return true;
            } else {
              return false;
            }
          }
        }
      } else {
        permissionStatus = await Permission.storage.status;
        if (permissionStatus == PermissionStatus.granted) {
          return true;
        } else {
          permissionStatus = await Permission.storage.request();
          if (permissionStatus == PermissionStatus.granted) {
            return true;
          } else if (permissionStatus == PermissionStatus.denied) {
            return false;
          } else if (permissionStatus == PermissionStatus.permanentlyDenied) {
            toast(
              'Permissions denied, change app settings',
              duration: Toast.LENGTH_LONG,
            );
            return false;
          }
        }
      }
    }
    return true;
  }

  void pickImages() async {
    onUploading();
    try {
      final FilePickerResult? list = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.image,
      );
      final config =
          await UserLocalPreference.instance.getCommunityConfigurations();
      double sizeLimit = (config.value!["max_image_size"]! / 1024) as double;
      sizeLimit = sizeLimit.truncateToDouble();
      if (list != null && list.files.isNotEmpty) {
        if (postMedia.length + list.files.length > 10) {
          toast(
            'A total of 10 attachments can be added to a post',
            duration: Toast.LENGTH_LONG,
          );
          onUploadedMedia(false);
          return;
        }
        for (PlatformFile image in list.files) {
          int fileBytes = image.size;
          double fileSize = getFileSizeInDouble(fileBytes);
          if (fileSize > sizeLimit) {
            toast(
              'Max file size allowed: ${sizeLimit.toInt()}MB',
              duration: Toast.LENGTH_LONG,
            );
            onUploadedMedia(false);
            return;
          }
        }
        List<File> pickedFiles = list.files.map((e) => File(e.path!)).toList();
        List<MediaModel> mediaFiles = pickedFiles
            .map((e) =>
                MediaModel(mediaFile: File(e.path), mediaType: MediaType.image))
            .toList();
        setPickedMediaFiles(mediaFiles);
        onUploadedMedia(true);

        return;
      } else {
        onUploadedMedia(false);
        return;
      }
    } on Exception catch (err, stacktrace) {
      toast(
        'An error occurred',
        duration: Toast.LENGTH_LONG,
      );
      onUploadedMedia(false);
      print(err.toString());
      LMFeedLogger.instance.handleException(err.toString(), stacktrace);
      return;
    }
  }

  void pickVideos(BuildContext context) async {}
}
