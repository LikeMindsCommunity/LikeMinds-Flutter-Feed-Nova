import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:likeminds_feed/likeminds_feed.dart';
import 'package:likeminds_feed_flutter_core/likeminds_feed_core.dart';
import 'package:likeminds_feed_nova_fl/likeminds_feed_nova_fl.dart';
import 'package:likeminds_feed_nova_fl/src/blocs/comment/add_comment_reply/add_comment_reply_bloc.dart';
import 'package:likeminds_feed_nova_fl/src/blocs/comment/comment_replies/comment_replies_bloc.dart';
import 'package:likeminds_feed_nova_fl/src/blocs/comment/toggle_like_comment/toggle_like_comment_bloc.dart';
import 'package:likeminds_feed_nova_fl/src/services/likeminds_service.dart';
import 'package:likeminds_feed_nova_fl/src/services/service_locator.dart';
import 'package:likeminds_feed_nova_fl/src/utils/analytics/analytics.dart';
import 'package:likeminds_feed_nova_fl/src/utils/constants/assets_constants.dart';
import 'package:likeminds_feed_nova_fl/src/utils/constants/ui_constants.dart';
import 'package:likeminds_feed_nova_fl/src/utils/icons.dart';
import 'package:likeminds_feed_nova_fl/src/utils/post/post_action_id.dart';
import 'package:likeminds_feed_nova_fl/src/views/report_screen.dart';
import 'package:likeminds_feed_nova_fl/src/widgets/delete_dialog.dart';
import 'package:likeminds_feed_ui_fl/likeminds_feed_ui_fl.dart';
import 'package:timeago/timeago.dart' as timeago;

class CommentReplyWidget extends StatefulWidget {
  final String postId;
  final LMCommentViewData reply;
  final User user;
  final Function() refresh;
  final Function(String commentId, String username) onReply;

  const CommentReplyWidget({
    Key? key,
    required this.reply,
    required this.user,
    required this.postId,
    required this.onReply,
    required this.refresh,
  }) : super(key: key);

  @override
  State<CommentReplyWidget> createState() => _CommentReplyWidgetState();
}

class _CommentReplyWidgetState extends State<CommentReplyWidget> {
  CommentRepliesBloc? _commentRepliesBloc;
  AddCommentReplyBloc? addCommentReplyBloc;
  ValueNotifier<bool> rebuildLikeButton = ValueNotifier(false);
  ValueNotifier<bool> rebuildReplyList = ValueNotifier(false);
  ValueNotifier<bool> rebuildReplyButton = ValueNotifier(false);
  List<LMCommentViewData> replies = [];
  Map<String, User> users = {};
  List<Widget> repliesW = [];
  ThemeData? theme;
  Size? screenSize;

  LMCommentViewData? reply;
  late final User user;
  late final String postId;
  Function()? refresh;
  int? likeCount;
  bool isLiked = false;
  int replyCount = 0;

  void initialiseReply() {
    reply = widget.reply;
    isLiked = reply!.isLiked;
    likeCount = reply!.likesCount;
    replyCount = reply!.repliesCount;
    refresh = widget.refresh;
  }

  @override
  void initState() {
    super.initState();
    postId = widget.postId;
    user = widget.user;
    initialiseReply();
  }

  int page = 1;

  List<Widget> mapRepliesToWidget(
      List<LMCommentViewData> replies, Map<String, User> users) {
    ToggleLikeCommentBloc toggleLikeCommentBloc =
        BlocProvider.of<ToggleLikeCommentBloc>(context);
    ThemeData theme = ColorTheme.novaTheme;
    return replies.mapIndexed((index, element) {
      User user = users[element.userId]!;
      return StatefulBuilder(builder: (context, setReplyState) {
        return Align(
          alignment: Alignment.topRight,
          child: LMReplyTile(
              comment: LMCommentViewDataConvertor.toComment(element),
              textStyle: theme.textTheme.labelMedium,
              linkStyle: theme.textTheme.labelMedium!
                  .copyWith(color: ColorTheme.primaryColor),
              width: screenSize!.width * 0.8,
              backgroundColor: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(10.0),
              margin: const EdgeInsets.only(bottom: 6.0, right: 16.0),
              onTagTap: (String userId) {
                locator<LikeMindsService>().routeToProfile(userId);
              },
              user: user,
              menu: LMIconButton(
                icon: LMIcon(
                  type: LMIconType.icon,
                  icon: Icons.more_vert,
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
                      margin: const EdgeInsets.only(top: 30),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(32),
                        topRight: Radius.circular(32),
                      ),
                      height: max(170, screenSize!.height * 0.25),
                      dragBarColor: theme.colorScheme.onSurface,
                      backgroundColor: theme.colorScheme.surface,
                      children: element.menuItems
                          .map(
                            (e) => GestureDetector(
                              onTap: () {
                                Navigator.of(context).pop();

                                if (e.id == commentDeleteId) {
                                  addCommentReplyBloc!.add(EditCommentCancel());
                                  addCommentReplyBloc!
                                      .add(ReplyCommentCancel());
                                  showDialog(
                                      context: context,
                                      builder: (childContext) =>
                                          deleteConfirmationDialog(childContext,
                                              title: 'Delete Comment',
                                              userId: element.userId,
                                              content:
                                                  'Are you sure you want to delete this comment. This action can not be reversed.',
                                              action: (String reason) async {
                                            Navigator.of(childContext).pop();
                                            //Implement delete post analytics tracking
                                            LMAnalytics.get().track(
                                              AnalyticsKeys.commentDeleted,
                                              {
                                                "post_id": postId,
                                                "comment_id": element.id,
                                              },
                                            );
                                            addCommentReplyBloc!.add(
                                                DeleteCommentReply(
                                                    (DeleteCommentRequestBuilder()
                                                          ..postId(postId)
                                                          ..commentId(
                                                              element.id)
                                                          ..reason(reason
                                                                  .isEmpty
                                                              ? "Reason for deletion"
                                                              : reason))
                                                        .build()));
                                          }, actionText: 'Yes, delete'));
                                } else if (e.id == commentEditId) {
                                  addCommentReplyBloc!.add(EditReplyCancel());
                                  addCommentReplyBloc!.add(
                                    EditingReply(
                                      commentId: reply!.id,
                                      text: element.text,
                                      replyId: element.id,
                                    ),
                                  );
                                } else if (e.id == commentReportId) {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => ReportScreen(
                                        entityCreatorId: reply!.userId,
                                        entityId: reply!.id,
                                        entityType: replyReportEntityType,
                                      ),
                                    ),
                                  );
                                }
                              },
                              child: Container(
                                color: Colors.transparent,
                                padding: const EdgeInsets.symmetric(
                                    vertical: 2.0, horizontal: 16.0),
                                margin: const EdgeInsets.only(bottom: 24.09),
                                width: screenSize!.width - 32.0,
                                child: Row(children: [
                                  getIconFromDropDownItemId(
                                    e.id,
                                    20,
                                    theme.colorScheme.onPrimaryContainer,
                                  ),
                                  kHorizontalPaddingLarge,
                                  LMTextView(
                                    text: e.title,
                                    textStyle: theme.textTheme.headlineLarge!
                                        .copyWith(
                                            color: e.id == commentDeleteId
                                                ? theme.colorScheme.error
                                                : null),
                                  ),
                                ]),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  );
                },
              ),
              profilePicture: LMProfilePicture(
                imageUrl: user.imageUrl,
                fallbackText: user.name,
                boxShape: BoxShape.circle,
                backgroundColor: theme.primaryColor,
                onTap: () {
                  if (user.sdkClientInfo != null) {
                    locator<LikeMindsService>()
                        .routeToProfile(user.sdkClientInfo!.userUniqueId);
                  }
                },
                size: 32,
              ),
              titleText: LMTextView(
                text: user.name,
                textStyle: theme.textTheme.labelMedium,
              ),
              subtitleText: LMTextView(
                text: timeago.format(element.createdAt),
                textStyle: theme.textTheme.labelSmall,
              ),
              onMenuTap: (value) async {},
              commentActions: [
                const SizedBox(
                  width: 50.0,
                ),
                LMTextButton(
                  text: LMTextView(
                    text: "${element.likesCount}",
                    textStyle: theme.textTheme.labelMedium,
                  ),
                  activeText: LMTextView(
                    text: "${element.likesCount}",
                    textStyle: theme.textTheme.labelMedium,
                  ),
                  onTap: () {
                    toggleLikeCommentBloc.add(
                      ToggleLikeComment(
                        toggleLikeCommentRequest:
                            (ToggleLikeCommentRequestBuilder()
                                  ..commentId(element.id)
                                  ..postId(widget.postId))
                                .build(),
                      ),
                    );
                    setReplyState(() {
                      if (element.isLiked) {
                        element.likesCount -= 1;
                      } else {
                        element.likesCount += 1;
                      }
                      element.isLiked = !element.isLiked;
                    });
                  },
                  icon: const LMIcon(
                    type: LMIconType.svg,
                    assetPath: kAssetLikeIcon,
                    size: 14,
                  ),
                  activeIcon: LMIcon(
                    type: LMIconType.svg,
                    assetPath: kAssetLikeFilledIcon,
                    size: 14,
                    color: theme.colorScheme.error,
                  ),
                  isActive: element.isLiked,
                ),
                const SizedBox(width: 8),
              ]),
        );
      });
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    addCommentReplyBloc = BlocProvider.of<AddCommentReplyBloc>(context);
    _commentRepliesBloc = BlocProvider.of<CommentRepliesBloc>(context);
    initialiseReply();
    theme = ColorTheme.novaTheme;
    screenSize = MediaQuery.of(context).size;
    return ValueListenableBuilder(
      valueListenable: rebuildReplyList,
      builder: (context, _, __) {
        return BlocConsumer(
          bloc: _commentRepliesBloc,
          buildWhen: (previous, current) {
            if (current is CommentRepliesLoaded &&
                current.commentId != reply!.id) {
              return false;
            }
            if (current is PaginatedCommentRepliesLoading &&
                current.commentId != reply!.id) {
              return false;
            }
            if (current is CommentRepliesLoading &&
                current.commentId != widget.reply.id) {
              return false;
            }
            return true;
          },
          builder: ((context, state) {
            if (state is ClearedCommentReplies) {
              replies = [];
              users = {};
              repliesW = [];
              return const SizedBox();
            }
            if (state is CommentRepliesLoading) {
              if (state.commentId == widget.reply.id) {
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Center(
                    child: SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: ColorTheme.novaTheme.primaryColor,
                      ),
                    ),
                  ),
                );
              }
            }
            if (state is CommentRepliesLoaded ||
                state is PaginatedCommentRepliesLoading) {
              // replies.addAll(state.commentDetails.postReplies.replies);
              if (state is CommentRepliesLoaded &&
                  state.commentId != reply!.id) {
                return const SizedBox();
              }
              if (state is PaginatedCommentRepliesLoading &&
                  state.commentId != reply!.id) {
                return const SizedBox();
              }

              if (state is CommentRepliesLoaded) {
                // replies = state.commentDetails.postReplies!.replies;
                users = state.commentDetails.users!;
                users.putIfAbsent(user.userUniqueId, () => user);
              } else if (state is PaginatedCommentRepliesLoading) {
                // replies = state.prevCommentDetails.postReplies!.replies;
                users = state.prevCommentDetails.users!;
                users.putIfAbsent(user.userUniqueId, () => user);
              }

              repliesW = mapRepliesToWidget(replies, users);

              if (replies.length % 10 == 0 &&
                  replies.length != reply!.repliesCount) {
                repliesW = [
                  ...repliesW,
                  replies.isEmpty
                      ? const SizedBox()
                      : Padding(
                          padding:
                              const EdgeInsets.only(bottom: 15.0, left: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              TextButton(
                                onPressed: () {
                                  page++;
                                  _commentRepliesBloc!.add(
                                    GetCommentReplies(
                                        commentDetailRequest:
                                            (GetCommentRequestBuilder()
                                                  ..commentId(reply!.id)
                                                  ..page(page)
                                                  ..postId(postId))
                                                .build(),
                                        forLoadMore: true),
                                  );
                                },
                                child: LMTextView(
                                  text: 'Show more replies',
                                  textStyle: TextStyle(
                                    color: ColorTheme
                                        .novaTheme.colorScheme.primary,
                                    fontFamily: 'Gantari',
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(right: 15.0),
                                child: LMTextView(
                                  text:
                                      ' ${replies.length} of ${reply!.repliesCount}',
                                  textStyle: const TextStyle(
                                    fontSize: 11,
                                    fontFamily: 'Gantari',
                                    color: kGrey3Color,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                ];
                // replies.add();
              }
              return BlocConsumer<AddCommentReplyBloc, AddCommentReplyState>(
                bloc: addCommentReplyBloc,
                listener: (context, state) {
                  if (state is AddCommentReplySuccess &&
                      state.addCommentResponse.reply!.parentComment!.id ==
                          reply!.id) {
                    // replies.insert(0, state.addCommentResponse.reply!);

                    repliesW = mapRepliesToWidget(replies, users);

                    if (replies.isNotEmpty &&
                        replies.length % 10 == 0 &&
                        replies.length != reply!.repliesCount) {
                      repliesW = [
                        ...repliesW,
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TextButton(
                              onPressed: () {
                                page++;
                                _commentRepliesBloc!.add(GetCommentReplies(
                                    commentDetailRequest:
                                        (GetCommentRequestBuilder()
                                              ..commentId(reply!.id)
                                              ..page(page)
                                              ..postId(postId))
                                            .build(),
                                    forLoadMore: true));
                              },
                              child: const Text(
                                'Show more replies',
                                style: TextStyle(
                                  color: kBlueGreyColor,
                                  fontFamily: 'Gantari',
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            Text(
                              ' ${replies.length} of ${reply!.repliesCount}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontFamily: 'Gantari',
                                color: kGrey3Color,
                              ),
                            )
                          ],
                        )
                      ];
                      // replies.add();
                    }
                  }
                  if (state is EditReplySuccess) {
                    int index = replies.indexWhere((element) =>
                        element.id == state.editCommentReplyResponse.reply!.id);
                    if (index != -1) {
                      // replies[index] = state.editCommentReplyResponse.reply!;

                      repliesW = mapRepliesToWidget(replies, users);

                      if (replies.isNotEmpty &&
                          replies.length % 10 == 0 &&
                          replies.length != reply!.repliesCount) {
                        repliesW = [
                          ...repliesW,
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              TextButton(
                                onPressed: () {
                                  page++;
                                  _commentRepliesBloc!.add(GetCommentReplies(
                                      commentDetailRequest:
                                          (GetCommentRequestBuilder()
                                                ..commentId(reply!.id)
                                                ..page(page)
                                                ..postId(postId))
                                              .build(),
                                      forLoadMore: true));
                                },
                                child: const Text(
                                  'Show more replies',
                                  style: TextStyle(
                                    color: kBlueGreyColor,
                                    fontFamily: 'Gantari',
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              Text(
                                ' ${replies.length} of ${reply!.repliesCount}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontFamily: 'Gantari',
                                  color: kGrey3Color,
                                ),
                              )
                            ],
                          )
                        ];
                        // replies.add();
                      }
                    }
                  }
                  if (state is CommentReplyDeleted) {
                    int index = replies
                        .indexWhere((element) => element.id == state.replyId);
                    if (index != -1) {
                      replies.removeAt(index);
                      reply!.repliesCount -= 1;
                      replyCount = reply!.repliesCount;
                      rebuildReplyButton.value = !rebuildReplyButton.value;

                      repliesW = mapRepliesToWidget(replies, users);

                      if (replies.isNotEmpty &&
                          replies.length % 10 == 0 &&
                          replies.length != reply!.repliesCount) {
                        repliesW = [
                          ...repliesW,
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              TextButton(
                                onPressed: () {
                                  page++;
                                  _commentRepliesBloc!.add(GetCommentReplies(
                                      commentDetailRequest:
                                          (GetCommentRequestBuilder()
                                                ..commentId(reply!.id)
                                                ..page(page)
                                                ..postId(postId))
                                              .build(),
                                      forLoadMore: true));
                                },
                                child: const Text(
                                  'Show more replies',
                                  style: TextStyle(
                                    color: kBlueGreyColor,
                                    fontFamily: 'Gantari',
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              Text(
                                ' ${replies.length} of ${reply!.repliesCount}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: kGrey3Color,
                                  fontFamily: 'Gantari',
                                ),
                              )
                            ],
                          )
                        ];
                        // replies.add();
                      }
                    }
                  }
                },
                builder: (context, state) {
                  return Container(
                    padding: const EdgeInsets.only(
                      left: 48,
                      top: 8,
                      bottom: 0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: repliesW,
                    ),
                  );
                },
              );
            }
            return Container();
          }),
          listener: (context, state) {
            List<LMCommentViewData> replies = [];
            if (state is CommentRepliesLoaded) {
              // replies = state.commentDetails.postReplies!.replies;
            } else if (state is PaginatedCommentRepliesLoading) {
              // replies = state.prevCommentDetails.postReplies!.replies;
            }
            replyCount = replies.length;
            rebuildReplyButton.value = !rebuildReplyButton.value;
          },
        );
      },
    );
  }
}
