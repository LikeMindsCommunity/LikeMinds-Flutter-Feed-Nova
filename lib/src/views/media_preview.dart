import 'package:carousel_slider/carousel_slider.dart';
import 'package:extended_image/extended_image.dart';
import 'package:intl/intl.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:likeminds_feed/likeminds_feed.dart';
import 'package:likeminds_feed_nova_fl/likeminds_feed_nova_fl.dart';
import 'package:likeminds_feed_nova_fl/src/blocs/new_post/new_post_bloc.dart';
import 'package:likeminds_feed_nova_fl/src/models/post/post_view_model.dart';
import 'package:likeminds_feed_nova_fl/src/services/bloc_service.dart';
import 'package:likeminds_feed_nova_fl/src/services/likeminds_service.dart';
import 'package:likeminds_feed_nova_fl/src/utils/constants/assets_constants.dart';
import 'package:likeminds_feed_nova_fl/src/utils/constants/ui_constants.dart';
import 'package:likeminds_feed_nova_fl/src/views/post_detail_screen.dart';
import 'package:likeminds_feed_ui_fl/likeminds_feed_ui_fl.dart';
import 'package:likeminds_feed_ui_fl/packages/expandable_text/expandable_text.dart';
import 'package:overlay_support/overlay_support.dart';

class MediaPreview extends StatefulWidget {
  final List<Attachment> postAttachments;
  final Post post;
  final User user;
  final int? position;

  const MediaPreview({
    Key? key,
    required this.postAttachments,
    required this.post,
    required this.user,
    this.position,
  }) : super(key: key);

  @override
  State<MediaPreview> createState() => _MediaPreviewState();
}

class _MediaPreviewState extends State<MediaPreview> {
  late List<Attachment> postAttachments;
  PostViewModel? post;
  late User user;
  late int? position;
  bool showData = true;
  ValueNotifier<bool> rebuildLikeButton = ValueNotifier<bool>(false);

  int currPosition = 0;
  CarouselController controller = CarouselController();
  ValueNotifier<bool> rebuildCurr = ValueNotifier<bool>(false);

  bool checkIfMultipleAttachments() {
    return (postAttachments.length > 1);
  }

  bool checkIfVideoPost() {
    return !postAttachments.any((element) => element.attachmentType == 2);
  }

  @override
  void initState() {
    postAttachments = widget.postAttachments;
    postAttachments.removeWhere((element) => element.attachmentType == 5);
    post = PostViewModel.fromPost(post: widget.post);
    user = widget.user;
    position = widget.position;
    super.initState();
  }

  @override
  void didUpdateWidget(covariant MediaPreview oldWidget) {
    // TODO: implement didUpdateWidget
    super.didUpdateWidget(oldWidget);
    postAttachments = widget.postAttachments;
    postAttachments.removeWhere((element) => element.attachmentType == 5);
    post = PostViewModel.fromPost(post: widget.post);
    user = widget.user;
    position = widget.position;
  }

  @override
  Widget build(BuildContext context) {
    final DateFormat formatter = DateFormat('MMMM d, HH:MM');
    final String formatted = formatter.format(post!.createdAt);
    final ThemeData theme = ColorTheme.novaTheme;
    final Size screenSize = MediaQuery.of(context).size;
    final NewPostBloc newPostBloc = locator<BlocService>().newPostBlocProvider;
    if (postAttachments.isEmpty) {
      return const SizedBox.shrink();
    }
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        centerTitle: false,
        leading: showData
            ? LMIconButton(
                onTap: (active) {
                  Navigator.of(context).pop();
                },
                icon: const LMIcon(
                  type: LMIconType.icon,
                  color: kWhiteColor,
                  icon: CupertinoIcons.xmark,
                  size: 28,
                ),
              )
            : const SizedBox(),
        leadingWidth: 40,
        elevation: 0,
        title: showData
            ? Row(
                children: [
                  LMProfilePicture(
                    fallbackText: user.name,
                    imageUrl: user.imageUrl,
                    backgroundColor: theme.primaryColor,
                    size: 36,
                    boxShape: BoxShape.circle,
                  ),
                  kHorizontalPaddingMedium,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        LMTextView(
                          text: user.name,
                          textStyle: ColorTheme.novaTheme.textTheme.bodyMedium!
                              .copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            overflow: TextOverflow.ellipsis,
                            color: kWhiteColor,
                          ),
                        ),
                        LMTextView(
                          text: formatted,
                          textStyle: ColorTheme.novaTheme.textTheme.bodyMedium!
                              .copyWith(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            overflow: TextOverflow.ellipsis,
                            color: kWhiteColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              )
            : null,
      ),
      body: GestureDetector(
        onTap: () {
          // setState(() {
          //   showData = !showData;
          // });
        },
        child: Container(
          color: Colors.transparent,
          child: SafeArea(
            top: false,
            child: Column(
              children: <Widget>[
                Expanded(
                  child: Stack(
                    children: [
                      CarouselSlider.builder(
                          options: CarouselOptions(
                            initialPage: position ?? 0,
                            aspectRatio: 9 / 16,
                            enableInfiniteScroll: false,
                            enlargeFactor: 0.0,
                            viewportFraction: 1.0,
                            onPageChanged: (index, reason) {
                              currPosition = index;
                              rebuildCurr.value = !rebuildCurr.value;
                            },
                          ),
                          itemCount: postAttachments.length,
                          itemBuilder: (context, index, realIndex) {
                            if (postAttachments[index].attachmentType == 2) {
                              return LMVideo(
                                videoUrl:
                                    postAttachments[index].attachmentMeta.url,
                                showControls: true,
                                autoPlay: true,
                                // height:
                                //     MediaQuery.of(context).size.height * ,
                              );
                            }

                            return Container(
                              color: Colors.black,
                              width: MediaQuery.of(context).size.width,
                              child: ExtendedImage.network(
                                postAttachments[index].attachmentMeta.url!,
                                fit: BoxFit.contain,
                                mode: ExtendedImageMode.gesture,
                                initGestureConfigHandler: (state) {
                                  return GestureConfig(
                                    hitTestBehavior: HitTestBehavior.opaque,
                                    minScale: 0.9,
                                    animationMinScale: 0.7,
                                    maxScale: 3.0,
                                    animationMaxScale: 3.5,
                                    inPageView: true,
                                  );
                                },
                              ),
                            );
                          }),
                      checkIfVideoPost()
                          ? Positioned(
                              bottom: 0,
                              child: Opacity(
                                opacity: showData ? 1.0 : 0.0,
                                child: Container(
                                  alignment: Alignment.centerLeft,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12.0),
                                  decoration: const BoxDecoration(
                                    boxShadow: <BoxShadow>[
                                      BoxShadow(
                                          offset: Offset(0.0, 4.0),
                                          blurRadius: 15.0,
                                          spreadRadius: -7.0,
                                          color: Colors.black87),
                                      BoxShadow(
                                          offset: Offset(0.0, 18.0),
                                          blurRadius: 38.0,
                                          spreadRadius: 3.0,
                                          color: Colors.black54),
                                      BoxShadow(
                                          offset: Offset(0.0, 7.0),
                                          blurRadius: 46.0,
                                          spreadRadius: 8.0,
                                          color: Colors.black45),
                                    ],
                                  ),
                                  width: screenSize.width,
                                  height: 50,
                                  child: ExpandableText(
                                    widget.post.text,
                                    expandText: '',
                                    onTagTap: (value) {},
                                    hashtagStyle: theme.textTheme.bodyMedium!
                                        .copyWith(
                                            color: theme.colorScheme.primary),
                                    linkStyle: theme.textTheme.bodyMedium!
                                        .copyWith(
                                            color: theme.colorScheme.primary),
                                    textAlign: TextAlign.left,
                                    style: ColorTheme
                                        .novaTheme.textTheme.bodyMedium,
                                  ),
                                ),
                              ),
                            )
                          : const SizedBox.shrink()
                    ],
                  ),
                ),
                checkIfVideoPost()
                    ? Opacity(
                        opacity: showData ? 1.0 : 0.0,
                        child: Column(
                          children: [
                            ValueListenableBuilder(
                              valueListenable: rebuildLikeButton,
                              builder: (context, _, __) {
                                return Row(
                                  children: <Widget>[
                                    kHorizontalPaddingLarge,
                                    LMTextButton(
                                      text: LMTextView(
                                        text: "${post!.likeCount}",
                                        textStyle: theme.textTheme.labelMedium,
                                      ),
                                      margin: 0,
                                      onTap: () async {
                                        if (post!.isLiked) {
                                          post!.likeCount -= 1;
                                          post!.isLiked = false;
                                        } else {
                                          post!.likeCount += 1;
                                          post!.isLiked = true;
                                        }

                                        rebuildLikeButton.value =
                                            !rebuildLikeButton.value;

                                        final response =
                                            await locator<LikeMindsService>()
                                                .likePost(
                                                    (LikePostRequestBuilder()
                                                          ..postId(post!.id))
                                                        .build());
                                        if (!response.success) {
                                          toast(
                                            response.errorMessage ??
                                                "There was an error liking the post",
                                            duration: Toast.LENGTH_LONG,
                                          );

                                          if (post!.isLiked) {
                                            post!.likeCount -= 1;
                                          } else {
                                            post!.likeCount += 1;
                                          }
                                          post!.isLiked = !post!.isLiked;
                                          rebuildLikeButton.value =
                                              !rebuildLikeButton.value;
                                        } else {
                                          newPostBloc.add(
                                            UpdatePost(
                                              post: post!,
                                            ),
                                          );
                                        }
                                      },
                                      icon: LMIcon(
                                        type: LMIconType.svg,
                                        assetPath: kAssetLikeIcon,
                                        color: theme.colorScheme.onPrimary,
                                        size: 20,
                                        boxPadding: 6,
                                      ),
                                      activeIcon: LMIcon(
                                        type: LMIconType.svg,
                                        assetPath: kAssetLikeFilledIcon,
                                        color: theme.colorScheme.error,
                                        size: 20,
                                        boxPadding: 6,
                                      ),
                                      isActive: post!.isLiked,
                                    ),
                                    kHorizontalPaddingLarge,
                                    LMTextButton(
                                      text: LMTextView(
                                        text: "${post!.commentCount}",
                                        textStyle: theme.textTheme.labelMedium,
                                      ),
                                      margin: 0,
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                PostDetailScreen(
                                              postId: post!.id,
                                              fromCommentButton: true,
                                            ),
                                          ),
                                        );
                                      },
                                      icon: LMIcon(
                                        type: LMIconType.svg,
                                        assetPath: kAssetCommentIcon,
                                        color: theme.colorScheme.onPrimary,
                                        size: 20,
                                        boxPadding: 6,
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                            kVerticalPaddingMedium,
                            ValueListenableBuilder(
                                valueListenable: rebuildCurr,
                                builder: (context, _, __) {
                                  return Column(
                                    children: [
                                      checkIfMultipleAttachments()
                                          ? kVerticalPaddingMedium
                                          : const SizedBox(),
                                      checkIfMultipleAttachments()
                                          ? Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children:
                                                  postAttachments.map((url) {
                                                int index = postAttachments
                                                    .indexOf(url);
                                                return Container(
                                                  width: 8.0,
                                                  height: 8.0,
                                                  margin: const EdgeInsets
                                                      .symmetric(
                                                      vertical: 7.0,
                                                      horizontal: 2.0),
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    color: currPosition == index
                                                        ? theme
                                                            .colorScheme.primary
                                                        : theme
                                                            .colorScheme.primary
                                                            .withOpacity(0.3),
                                                  ),
                                                );
                                              }).toList())
                                          : const SizedBox(),
                                    ],
                                  );
                                }),
                          ],
                        ),
                      )
                    : const SizedBox.shrink()
              ],
            ),
          ),
        ),
      ),
    );
  }
}
