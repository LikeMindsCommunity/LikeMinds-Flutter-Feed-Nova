import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:likeminds_feed/likeminds_feed.dart';
import 'package:likeminds_feed_nova_fl/likeminds_feed_nova_fl.dart';
import 'package:likeminds_feed_nova_fl/src/blocs/comment/add_comment/add_comment_bloc.dart';
import 'package:likeminds_feed_nova_fl/src/blocs/comment/add_comment_reply/add_comment_reply_bloc.dart';
import 'package:likeminds_feed_nova_fl/src/blocs/comment/all_comments/all_comments_bloc.dart';
import 'package:likeminds_feed_nova_fl/src/blocs/comment/comment_replies/comment_replies_bloc.dart';
import 'package:likeminds_feed_nova_fl/src/blocs/comment/toggle_like_comment/toggle_like_comment_bloc.dart';
import 'package:likeminds_feed_nova_fl/src/blocs/new_post/new_post_bloc.dart';
import 'package:likeminds_feed_nova_fl/src/models/post/post_view_model.dart';
import 'package:likeminds_feed_nova_fl/src/services/likeminds_service.dart';
import 'package:likeminds_feed_nova_fl/src/utils/constants/assets_constants.dart';
import 'package:likeminds_feed_nova_fl/src/utils/icons.dart';
import 'package:likeminds_feed_nova_fl/src/utils/post/post_action_id.dart';
import 'package:likeminds_feed_nova_fl/src/utils/post/post_utils.dart';
import 'package:likeminds_feed_nova_fl/src/utils/tagging/tagging_textfield_ta.dart';
import 'package:likeminds_feed_nova_fl/src/views/likes/likes_horizontal_view.dart';
import 'package:likeminds_feed_nova_fl/src/views/likes/likes_screen.dart';
import 'package:likeminds_feed_nova_fl/src/views/post/edit_post_screen.dart';
import 'package:likeminds_feed_nova_fl/src/views/report_screen.dart';
import 'package:likeminds_feed_nova_fl/src/widgets/delete_dialog.dart';
import 'package:likeminds_feed_nova_fl/src/widgets/post/post_widget.dart';
import 'package:likeminds_feed_nova_fl/src/widgets/reply/comment_reply.dart';
import 'package:likeminds_feed_ui_fl/likeminds_feed_ui_fl.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:timeago/timeago.dart' as timeago;

class PostDetailScreen extends StatefulWidget {
  final String postId;
  final bool fromCommentButton;

  const PostDetailScreen({
    super.key,
    required this.postId,
    this.fromCommentButton = false,
  });

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  bool keyBoardShown = false;
  late final AllCommentsBloc _allCommentsBloc;
  late final AddCommentBloc _addCommentBloc;
  late final AddCommentReplyBloc _addCommentReplyBloc;
  late final CommentRepliesBloc _commentRepliesBloc;
  late final ToggleLikeCommentBloc _toggleLikeCommentBloc;
  late final NewPostBloc newPostBloc;
  final FocusNode focusNode = FocusNode();
  TextEditingController? _commentController;
  ValueNotifier<bool> rebuildButton = ValueNotifier(false);
  ValueNotifier<bool> rebuildLikesList = ValueNotifier(false);
  ValueNotifier<bool> rebuildPostWidget = ValueNotifier(false);
  ValueNotifier<bool> rebuildReplyWidget = ValueNotifier(false);
  bool right = true;
  PostDetailResponse? postDetailResponse;
  final PagingController<int, Reply> _pagingController =
      PagingController(firstPageKey: 1);
  PostViewModel? postData;
  Map<String, Topic> topics = {};
  Map<String, WidgetModel> widgets = {};
  User currentUser = UserLocalPreference.instance.fetchUserData();

  List<UserTag> userTags = [];
  String? result = '';
  bool isEditing = false;
  bool isReplying = false;

  String? selectedCommentId;
  String? selectedUsername;
  String? selectedReplyId;

  @override
  void dispose() {
    _allCommentsBloc.close();
    _addCommentBloc.close();
    _addCommentReplyBloc.close();
    _pagingController.dispose();
    rebuildButton.dispose();
    rebuildPostWidget.dispose();
    rebuildReplyWidget.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    LMAnalytics.get().track(AnalyticsKeys.commentListOpen, {
      'postId': widget.postId,
    });
    newPostBloc = locator<BlocService>().newPostBlocProvider;
    updatePostDetails(context);
    right = checkCommentRights();
    _commentController = TextEditingController();
    if (_commentController != null) {
      _commentController!.addListener(
        () {
          if (_commentController!.text.isEmpty) {
            _commentController!.clear();
          }
        },
      );
    }
    _allCommentsBloc = AllCommentsBloc();
    _allCommentsBloc.add(GetAllComments(
        postDetailRequest: (PostDetailRequestBuilder()
              ..postId(widget.postId)
              ..page(1))
            .build(),
        forLoadMore: false));
    _addCommentBloc = AddCommentBloc();
    _addCommentReplyBloc = AddCommentReplyBloc();
    _toggleLikeCommentBloc = ToggleLikeCommentBloc();
    _commentRepliesBloc = CommentRepliesBloc();
    _addPaginationListener();
    if (widget.fromCommentButton &&
        focusNode.canRequestFocus &&
        keyBoardShown == false) {
      focusNode.requestFocus();
      keyBoardShown = true;
    }
  }

  int _page = 1;

  void _addPaginationListener() {
    _pagingController.addPageRequestListener(
      (pageKey) {
        _allCommentsBloc.add(
          GetAllComments(
            postDetailRequest: (PostDetailRequestBuilder()
                  ..postId(widget.postId)
                  ..page(pageKey))
                .build(),
            forLoadMore: true,
          ),
        );
      },
    );
  }

  selectCommentToEdit(String commentId, String? replyId, String text) {
    selectedCommentId = commentId;
    isEditing = true;
    selectedReplyId = replyId;
    isReplying = false;
    Map<String, dynamic> decodedComment =
        TaggingHelper.convertRouteToTagAndUserMap(text);
    userTags = decodedComment['userTags'];
    _commentController?.value = TextEditingValue(text: decodedComment['text']);
    openOnScreenKeyboard();
    rebuildReplyWidget.value = !rebuildReplyWidget.value;
  }

  deselectCommentToEdit() {
    selectedCommentId = null;
    selectedReplyId = null;
    isEditing = false;
    _commentController?.clear();
    closeOnScreenKeyboard();
    rebuildReplyWidget.value = !rebuildReplyWidget.value;
  }

  selectCommentToReply(String commentId, String username) {
    selectedCommentId = commentId;
    debugPrint(commentId);
    selectedUsername = username;
    isReplying = true;
    isEditing = false;
    openOnScreenKeyboard();
    rebuildReplyWidget.value = !rebuildReplyWidget.value;
  }

  deselectCommentToReply() {
    selectedCommentId = null;
    selectedUsername = null;
    isReplying = false;
    closeOnScreenKeyboard();
    _commentController?.clear();
    rebuildReplyWidget.value = !rebuildReplyWidget.value;
  }

  Future updatePostDetails(BuildContext context) async {
    final GetPostResponse postDetails =
        await locator<LikeMindsService>().getPost(
      (GetPostRequestBuilder()
            ..postId(widget.postId)
            ..page(1)
            ..pageSize(10))
          .build(),
    );
    if (postDetails.success) {
      postData = PostViewModel.fromPost(post: postDetails.post!);
      topics = postDetails.topics ?? {};
      widgets = postDetails.widgets ?? {};
      rebuildPostWidget.value = !rebuildPostWidget.value;
    } else {
      toast(
        postDetails.errorMessage ?? 'An error occurred',
        duration: Toast.LENGTH_LONG,
      );
    }
  }

  void increaseCommentCount() {
    postData!.commentCount = postData!.commentCount + 1;
  }

  void decreaseCommentCount() {
    if (postData!.commentCount != 0) {
      postData!.commentCount = postData!.commentCount - 1;
    }
  }

  void addCommentToList(AddCommentSuccess addCommentSuccess) {
    List<Reply>? commentItemList = _pagingController.itemList;
    commentItemList ??= [];
    if (commentItemList.length >= 10) {
      commentItemList.removeAt(9);
    }
    commentItemList.insert(0, addCommentSuccess.addCommentResponse.reply!);
    increaseCommentCount();
    rebuildPostWidget.value = !rebuildPostWidget.value;
    newPostBloc.add(
      UpdatePost(
        post: postData!,
      ),
    );
  }

  void updateCommentInList(EditCommentSuccess editCommentSuccess) {
    List<Reply>? commentItemList = _pagingController.itemList;
    commentItemList ??= [];
    int index = commentItemList.indexWhere((element) =>
        element.id == editCommentSuccess.editCommentResponse.reply!.id);
    commentItemList[index] = editCommentSuccess.editCommentResponse.reply!;
    rebuildPostWidget.value = !rebuildPostWidget.value;
  }

  addReplyToList(AddCommentReplySuccess addCommentReplySuccess) {
    List<Reply>? commentItemList = _pagingController.itemList;
    if (addCommentReplySuccess.addCommentResponse.reply!.parentComment !=
        null) {
      int index = commentItemList!.indexWhere((element) =>
          element.id ==
          addCommentReplySuccess.addCommentResponse.reply!.parentComment!.id);
      if (index != -1) {
        commentItemList[index].repliesCount =
            commentItemList[index].repliesCount + 1;
        rebuildPostWidget.value = !rebuildPostWidget.value;
      }
    }
  }

  void removeCommentFromList(String commentId) {
    List<Reply>? commentItemList = _pagingController.itemList;
    int index =
        commentItemList!.indexWhere((element) => element.id == commentId);
    if (index != -1) {
      commentItemList.removeAt(index);
      decreaseCommentCount();
      rebuildPostWidget.value = !rebuildPostWidget.value;
      newPostBloc.add(
        UpdatePost(
          post: postData!,
        ),
      );
    }
  }

  bool checkCommentRights() {
    final MemberStateResponse memberStateResponse =
        UserLocalPreference.instance.fetchMemberRights();
    if (memberStateResponse.state == 1) {
      return true;
    }
    bool memberRights = UserLocalPreference.instance.fetchMemberRight(10);
    return memberRights;
  }

  @override
  Widget build(BuildContext context) {
    Size screenSize = MediaQuery.of(context).size;
    ThemeData theme = ColorTheme.novaTheme;
    return WillPopScope(
      onWillPop: () {
        if (Navigator.of(context).canPop()) {
          Navigator.pop(context);
        }

        return Future(() => false);
      },
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AllCommentsBloc>(
            create: (context) => _allCommentsBloc,
          ),
          BlocProvider<AddCommentBloc>(
            create: (context) => _addCommentBloc,
          ),
          BlocProvider<AddCommentReplyBloc>(
            create: (context) => _addCommentReplyBloc,
          ),
          BlocProvider<CommentRepliesBloc>(
            create: (context) => _commentRepliesBloc,
          ),
          BlocProvider<ToggleLikeCommentBloc>(
            create: (context) => _toggleLikeCommentBloc,
          ),
        ],
        child: Scaffold(
            resizeToAvoidBottomInset: true,
            bottomSheet: ValueListenableBuilder(
              valueListenable: rebuildPostWidget,
              builder: (context, _, __) {
                return postData == null
                    ? const SizedBox()
                    : SafeArea(
                        child: BlocConsumer<AddCommentReplyBloc,
                            AddCommentReplyState>(
                          bloc: _addCommentReplyBloc,
                          listener: (context, state) {
                            if (state is ReplyCommentCanceled) {
                              deselectCommentToReply();
                            }
                            if (state is EditCommentCanceled) {
                              deselectCommentToEdit();
                            }
                            if (state is CommentDeleted) {
                              removeCommentFromList(state.commentId);
                            }
                            if (state is EditReplyLoading) {
                              deselectCommentToEdit();
                            }
                            if (state is ReplyEditingStarted) {
                              selectCommentToEdit(
                                  state.commentId, state.replyId, state.text);
                            }
                            if (state is EditCommentLoading) {
                              deselectCommentToEdit();
                            }
                            if (state is CommentEditingStarted) {
                              selectCommentToEdit(
                                  state.commentId, null, state.text);
                            }
                            if (state is AddCommentReplySuccess) {
                              debugPrint("AddCommentReplySuccess");
                              _commentController!.clear();
                              addReplyToList(state);
                              deselectCommentToReply();
                            }
                            if (state is AddCommentReplyError) {
                              deselectCommentToReply();
                            }
                            if (state is EditCommentSuccess) {
                              updateCommentInList(state);
                            }
                            if (state is EditReplySuccess) {}
                          },
                          builder: (context, state) => Container(
                            decoration: BoxDecoration(
                              color: theme.colorScheme.background,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, -5),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                kVerticalPaddingMedium,
                                ValueListenableBuilder(
                                    valueListenable: rebuildReplyWidget,
                                    builder: (context, _, __) {
                                      return isEditing || isReplying
                                          ? Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 16,
                                                      vertical: 8),
                                              child: Row(
                                                children: [
                                                  LMTextView(
                                                    text: isEditing
                                                        ? "Editing ${selectedReplyId != null ? 'reply' : 'comment'}"
                                                        : "Replying to",
                                                    textStyle: theme
                                                        .textTheme.labelMedium,
                                                  ),
                                                  const SizedBox(
                                                    width: 8,
                                                  ),
                                                  Expanded(
                                                    child: isEditing
                                                        ? const SizedBox()
                                                        : LMTextView(
                                                            text:
                                                                selectedUsername!,
                                                            textStyle: theme
                                                                .textTheme
                                                                .titleMedium!
                                                                .copyWith(
                                                                    color: theme
                                                                        .colorScheme
                                                                        .primary),
                                                          ),
                                                  ),
                                                  LMIconButton(
                                                    onTap: (active) {
                                                      if (isEditing) {
                                                        if (selectedReplyId !=
                                                            null) {
                                                          _addCommentReplyBloc.add(
                                                              EditReplyCancel());
                                                        } else {
                                                          _addCommentReplyBloc.add(
                                                              EditCommentCancel());
                                                        }
                                                        deselectCommentToEdit();
                                                      } else {
                                                        deselectCommentToReply();
                                                      }
                                                    },
                                                    icon: LMIcon(
                                                      type: LMIconType.icon,
                                                      icon: Icons.close,
                                                      color: theme.colorScheme
                                                          .onPrimary,
                                                      size: 24,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            )
                                          : const SizedBox();
                                    }),
                                Container(
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 8.0),
                                  padding: const EdgeInsets.all(3.0),
                                  child: Row(
                                    children: [
                                      LMProfilePicture(
                                        fallbackText: currentUser.name,
                                        imageUrl: currentUser.imageUrl,
                                        backgroundColor: theme.primaryColor,
                                        boxShape: BoxShape.circle,
                                        onTap: () {
                                          if (currentUser.sdkClientInfo !=
                                              null) {
                                            locator<LikeMindsService>()
                                                .routeToProfile(currentUser
                                                    .sdkClientInfo!
                                                    .userUniqueId);
                                          }
                                        },
                                        size: 32,
                                      ),
                                      kHorizontalPaddingMedium,
                                      Expanded(
                                        child: Container(
                                          constraints: BoxConstraints(
                                            maxWidth: screenSize.width * 0.6,
                                          ),
                                          child: TaggingAheadTextField(
                                            isDown: false,
                                            maxLines: 5,
                                            onTagSelected: (tag) {
                                              userTags.add(tag);
                                            },
                                            controller: _commentController!,
                                            decoration: InputDecoration(
                                              enabled: right,
                                              border: InputBorder.none,
                                              hintText: right
                                                  ? 'Comment your thoughts'
                                                  : "You do not have permission to comment.",
                                              hintStyle: theme
                                                  .textTheme.bodyMedium!
                                                  .copyWith(
                                                color:
                                                    theme.colorScheme.onPrimary,
                                              ),
                                            ),
                                            focusNode: focusNode,
                                            onChange: (String p0) {
                                              rebuildButton.value =
                                                  !rebuildButton.value;
                                            },
                                          ),
                                        ),
                                      ),
                                      LMIconButton(
                                        icon: LMIcon(
                                          type: LMIconType.svg,
                                          assetPath: kAssetMentionIcon,
                                          color: theme.colorScheme.onPrimary,
                                          boxPadding: 0,
                                          size: 19,
                                        ),
                                        onTap: (active) {
                                          if (!focusNode.hasFocus) {
                                            focusNode.requestFocus();
                                          }
                                          String currentText =
                                              _commentController!.text;
                                          if (currentText.lastIndexOf('@') <
                                              currentText.length - 1) {
                                            currentText = '$currentText @';
                                          } else if (currentText.isNotEmpty) {
                                            currentText = currentText;
                                          } else {
                                            currentText = '@';
                                          }
                                          _commentController!.text =
                                              currentText;
                                        },
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8.0),
                                        child: !right
                                            ? null
                                            : ValueListenableBuilder(
                                                valueListenable:
                                                    rebuildReplyWidget,
                                                builder: (context, _, __) =>
                                                    isReplying || isEditing
                                                        ? BlocConsumer<
                                                            AddCommentReplyBloc,
                                                            AddCommentReplyState>(
                                                            bloc:
                                                                _addCommentReplyBloc,
                                                            listener: (context,
                                                                state) {},
                                                            buildWhen:
                                                                (previous,
                                                                    current) {
                                                              if (current
                                                                  is ReplyEditingStarted) {
                                                                return false;
                                                              }
                                                              if (current
                                                                  is EditReplyLoading) {
                                                                return false;
                                                              }
                                                              if (current
                                                                  is CommentEditingStarted) {
                                                                return false;
                                                              }
                                                              if (current
                                                                  is EditCommentLoading) {
                                                                return false;
                                                              }
                                                              return true;
                                                            },
                                                            builder: (context,
                                                                state) {
                                                              if (state
                                                                  is AddCommentReplyLoading) {
                                                                return SizedBox(
                                                                  height: 15,
                                                                  width: 15,
                                                                  child:
                                                                      CircularProgressIndicator(
                                                                    strokeWidth:
                                                                        2,
                                                                    color: ColorTheme
                                                                        .novaTheme
                                                                        .primaryColor,
                                                                  ),
                                                                );
                                                              }
                                                              return ValueListenableBuilder(
                                                                  valueListenable:
                                                                      rebuildButton,
                                                                  builder: (
                                                                    context,
                                                                    s,
                                                                    a,
                                                                  ) {
                                                                    return LMTextButton(
                                                                      height:
                                                                          18,
                                                                      text:
                                                                          LMTextView(
                                                                        text:
                                                                            "Comment",
                                                                        textStyle:
                                                                            TextStyle(
                                                                          color: right
                                                                              ? _commentController!.value.text.isEmpty
                                                                                  ? theme.colorScheme.onPrimary
                                                                                  : ColorTheme.novaTheme.colorScheme.primary
                                                                              : Colors.transparent,
                                                                          fontFamily:
                                                                              'Gantari',
                                                                          fontSize:
                                                                              14,
                                                                        ),
                                                                      ),
                                                                      onTap:
                                                                          () {
                                                                        closeOnScreenKeyboard();
                                                                        String commentText = TaggingHelper.encodeString(
                                                                            _commentController!.text,
                                                                            userTags);
                                                                        commentText =
                                                                            commentText.trim();
                                                                        if (commentText
                                                                            .isEmpty) {
                                                                          toast(
                                                                              "Please write something to comment");
                                                                          return;
                                                                        }

                                                                        if (isEditing) {
                                                                          if (selectedReplyId !=
                                                                              null) {
                                                                            _addCommentReplyBloc.add(
                                                                              EditReply(
                                                                                editCommentReplyRequest: (EditCommentReplyRequestBuilder()
                                                                                      ..postId(widget.postId)
                                                                                      ..text(commentText)
                                                                                      ..commentId(selectedCommentId!)
                                                                                      ..replyId(selectedReplyId!))
                                                                                    .build(),
                                                                              ),
                                                                            );
                                                                          } else {
                                                                            _addCommentReplyBloc.add(
                                                                              EditComment(
                                                                                editCommentRequest: (EditCommentRequestBuilder()
                                                                                      ..postId(widget.postId)
                                                                                      ..text(commentText)
                                                                                      ..commentId(selectedCommentId!))
                                                                                    .build(),
                                                                              ),
                                                                            );
                                                                          }
                                                                        } else {
                                                                          _addCommentReplyBloc.add(AddCommentReply(
                                                                              addCommentRequest: (AddCommentReplyRequestBuilder()
                                                                                    ..postId(widget.postId)
                                                                                    ..text(commentText)
                                                                                    ..commentId(selectedCommentId!))
                                                                                  .build()));

                                                                          _commentController
                                                                              ?.clear();
                                                                        }
                                                                      },
                                                                    );
                                                                  });
                                                            },
                                                          )
                                                        : BlocConsumer<
                                                            AddCommentBloc,
                                                            AddCommentState>(
                                                            bloc:
                                                                _addCommentBloc,
                                                            listener: (context,
                                                                state) {
                                                              if (state
                                                                  is AddCommentSuccess) {
                                                                addCommentToList(
                                                                    state);
                                                              }
                                                              if (state
                                                                  is AddCommentLoading) {
                                                                deselectCommentToEdit();
                                                              }
                                                            },
                                                            builder: (context,
                                                                state) {
                                                              if (state
                                                                  is AddCommentLoading) {
                                                                return SizedBox(
                                                                  height: 15,
                                                                  width: 15,
                                                                  child:
                                                                      CircularProgressIndicator(
                                                                    strokeWidth:
                                                                        2,
                                                                    color: ColorTheme
                                                                        .novaTheme
                                                                        .primaryColor,
                                                                  ),
                                                                );
                                                              }
                                                              return ValueListenableBuilder(
                                                                  valueListenable:
                                                                      rebuildButton,
                                                                  builder:
                                                                      (context,
                                                                          s,
                                                                          a) {
                                                                    return LMTextButton(
                                                                      height:
                                                                          18,
                                                                      text:
                                                                          LMTextView(
                                                                        text:
                                                                            "Comment",
                                                                        textAlign:
                                                                            TextAlign.center,
                                                                        textStyle:
                                                                            TextStyle(
                                                                          fontSize:
                                                                              14,
                                                                          fontFamily:
                                                                              'Gantari',
                                                                          color: _commentController!.value.text.isEmpty
                                                                              ? theme.colorScheme.onPrimary
                                                                              : ColorTheme.novaTheme.colorScheme.primary,
                                                                        ),
                                                                      ),
                                                                      onTap:
                                                                          () {
                                                                        closeOnScreenKeyboard();
                                                                        String
                                                                            commentText =
                                                                            TaggingHelper.encodeString(
                                                                          _commentController!
                                                                              .text,
                                                                          userTags,
                                                                        );
                                                                        commentText =
                                                                            commentText.trim();
                                                                        if (commentText
                                                                            .isEmpty) {
                                                                          toast(
                                                                              "Please write something to comment");
                                                                          return;
                                                                        }

                                                                        if (postDetailResponse !=
                                                                            null) {
                                                                          postDetailResponse!.users?.putIfAbsent(
                                                                              currentUser.userUniqueId,
                                                                              () => currentUser);
                                                                        }

                                                                        _addCommentBloc
                                                                            .add(
                                                                          AddComment(
                                                                            addCommentRequest: (AddCommentRequestBuilder()
                                                                                  ..postId(widget.postId)
                                                                                  ..text(commentText))
                                                                                .build(),
                                                                          ),
                                                                        );

                                                                        closeOnScreenKeyboard();
                                                                        _commentController
                                                                            ?.clear();
                                                                      },
                                                                    );
                                                                  });
                                                            },
                                                          ),
                                              ),
                                      ),
                                    ],
                                  ),
                                ),
                                kVerticalPaddingLarge,
                              ],
                            ),
                          ),
                        ),
                      );
              },
            ),
            backgroundColor: theme.colorScheme.background,
            appBar: AppBar(
              leading: LMIconButton(
                icon: LMIcon(
                  type: LMIconType.icon,
                  icon: Icons.arrow_back_ios,
                  color: theme.colorScheme.onPrimaryContainer,
                  size: 28,
                ),
                onTap: (active) {
                  Navigator.pop(context);
                },
                containerSize: 48,
              ),
              backgroundColor: theme.colorScheme.background,
              elevation: 1,
            ),
            body: BlocConsumer<AllCommentsBloc, AllCommentsState>(
              listener: (context, state) {
                if (state is AllCommentsLoaded) {
                  _page++;
                  if (state.postDetails.postReplies!.replies.length < 10) {
                    _pagingController
                        .appendLastPage(state.postDetails.postReplies!.replies);
                  } else {
                    _pagingController.appendPage(
                        state.postDetails.postReplies!.replies, _page);
                  }
                }
              },
              bloc: _allCommentsBloc,
              builder: (context, state) {
                if (state is AllCommentsLoaded ||
                    state is PaginatedAllCommentsLoading) {
                  if (state is AllCommentsLoaded) {
                    debugPrint("AllCommentsLoaded$state");
                    postDetailResponse = state.postDetails;
                    postDetailResponse!.users!.putIfAbsent(
                        currentUser.userUniqueId, () => currentUser);
                  } else {
                    debugPrint("PaginatedAllCommentsLoading$state");
                    postDetailResponse =
                        (state as PaginatedAllCommentsLoading).prevPostDetails;
                    postDetailResponse!.users!.putIfAbsent(
                        currentUser.userUniqueId, () => currentUser);
                  }
                  return RefreshIndicator(
                    onRefresh: () async {
                      await updatePostDetails(context);
                      _commentRepliesBloc.add(ClearCommentReplies());
                      _pagingController.refresh();
                      _page = 1;
                    },
                    child: ValueListenableBuilder(
                        valueListenable: rebuildPostWidget,
                        builder: (context, _, __) {
                          return BlocListener<NewPostBloc, NewPostState>(
                            bloc: newPostBloc,
                            listener: (context, state) {
                              if (state is EditPostUploaded) {
                                postData = state.postData;
                                topics = state.topics;
                                widgets = state.widgets;
                                rebuildPostWidget.value =
                                    !rebuildPostWidget.value;
                              }
                              if (state is PostUpdateState) {
                                postData = state.post;
                              }
                            },
                            child: CustomScrollView(
                              slivers: [
                                SliverToBoxAdapter(
                                  child: postData == null
                                      ? Center(
                                          child: CircularProgressIndicator(
                                              color: ColorTheme.novaTheme
                                                  .colorScheme.primary),
                                        )
                                      : NovaPostWidget(
                                          post: postData!,
                                          expanded: true,
                                          users: postDetailResponse!.users!,
                                          repostedPost: postDetailResponse!
                                                  .repostedPosts ??
                                              {},
                                          topics:
                                              postDetailResponse!.topics ?? {},
                                          widgets:
                                              postDetailResponse!.widgets ?? {},
                                          user: postDetailResponse!.users![
                                              postDetailResponse!
                                                  .postReplies!.userId]!,
                                          onTap: () {
                                            print("Tapped");
                                          },
                                          onMenuTap: (int id) {
                                            if (id == postDeleteId) {
                                              showDialog(
                                                  context: context,
                                                  builder: (childContext) =>
                                                      deleteConfirmationDialog(
                                                        childContext,
                                                        title: 'Delete Post',
                                                        userId:
                                                            postData!.userId,
                                                        content:
                                                            'Are you sure you want to delete this post. This action can not be reversed.',
                                                        action: (String
                                                            reason) async {
                                                          Navigator.of(
                                                                  childContext)
                                                              .pop();
                                                          final res = await locator<
                                                                  LikeMindsService>()
                                                              .getMemberState();
                                                          //Implement delete post analytics tracking
                                                          LMAnalytics.get()
                                                              .track(
                                                            AnalyticsKeys
                                                                .postDeleted,
                                                            {
                                                              "user_state":
                                                                  res.state == 1
                                                                      ? "CM"
                                                                      : "member",
                                                              "post_id":
                                                                  postData!.id,
                                                              "user_id":
                                                                  postData!
                                                                      .userId,
                                                            },
                                                          );
                                                          newPostBloc.add(
                                                            DeletePost(
                                                              postId:
                                                                  postData!.id,
                                                              isRepost:
                                                                  postData!
                                                                      .isRepost,
                                                              reason: reason,
                                                            ),
                                                          );
                                                          Navigator.of(context)
                                                              .pop();
                                                        },
                                                        actionText:
                                                            'Yes, delete',
                                                      ));
                                            } else if (id == postPinId ||
                                                id == postUnpinId) {
                                              try {
                                                String? postType = getPostType(
                                                    postData!.attachments?.first
                                                            .attachmentType ??
                                                        0);
                                                if (postData!.isPinned) {
                                                  LMAnalytics.get().track(
                                                      AnalyticsKeys
                                                          .postUnpinned,
                                                      {
                                                        "created_by_id":
                                                            postData!.userId,
                                                        "post_id": postData!.id,
                                                        "post_type": postType,
                                                      });
                                                } else {
                                                  LMAnalytics.get().track(
                                                      AnalyticsKeys.postPinned,
                                                      {
                                                        "created_by_id":
                                                            postData!.userId,
                                                        "post_id": postData!.id,
                                                        "post_type": postType,
                                                      });
                                                }
                                              } on Exception catch (err, stacktrace) {
                                                debugPrint(err.toString());
                                                LMFeedLogger.instance
                                                    .handleException(
                                                        err, stacktrace);
                                              }
                                              newPostBloc.add(TogglePinPost(
                                                  postId: postData!.id,
                                                  isPinned:
                                                      !postData!.isPinned));
                                            } else if (id == postEditId) {
                                              try {
                                                String? postType;
                                                if (postData!.attachments !=
                                                        null &&
                                                    postData!.attachments!
                                                        .isNotEmpty) {
                                                  postType = getPostType(
                                                      postData!
                                                          .attachments!
                                                          .first
                                                          .attachmentType);
                                                } else {
                                                  postType = getPostType(0);
                                                }
                                                LMAnalytics.get().track(
                                                  AnalyticsKeys.postEdited,
                                                  {
                                                    "created_by_id":
                                                        postData!.userId,
                                                    "post_id": postData!.id,
                                                    "post_type": postType,
                                                  },
                                                );
                                              } on Exception catch (err, stacktrace) {
                                                debugPrint(err.toString());
                                                LMFeedLogger.instance
                                                    .handleException(
                                                        err, stacktrace);
                                              }
                                              List<TopicUI> postTopics = [];

                                              if (postData!.topics.isNotEmpty &&
                                                  topics.containsKey(
                                                      postData!.topics.first)) {
                                                postTopics.add(
                                                    TopicUI.fromTopic(topics[
                                                        postData!
                                                            .topics.first]!));
                                              }

                                              Navigator.of(context).push(
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      EditPostScreen(
                                                    postId: postData!.id,
                                                    selectedTopics: postTopics,
                                                  ),
                                                ),
                                              );
                                            } else if (id == postReportId) {
                                              Navigator.of(context).push(
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      ReportScreen(
                                                    entityCreatorId:
                                                        postData!.userId,
                                                    entityId: postData!.id,
                                                    entityType:
                                                        postReportEntityType,
                                                  ),
                                                ),
                                              );
                                            }
                                          },
                                          isFeed: false,
                                          refresh: (bool isDeleted) async {
                                            print("Post interacted with");
                                            rebuildLikesList.value =
                                                !rebuildLikesList.value;
                                          },
                                        ),
                                ),
                                SliverToBoxAdapter(
                                  child: Container(
                                    height: 0.1,
                                    width: screenSize.width,
                                    margin: const EdgeInsets.only(
                                        bottom: 12.0, left: 16.0, right: 16.0),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.onPrimary,
                                    ),
                                  ),
                                ),
                                postData != null && postData!.likeCount > 0
                                    ? SliverToBoxAdapter(
                                        child: ValueListenableBuilder(
                                          valueListenable: rebuildLikesList,
                                          builder: (
                                            context,
                                            value,
                                            child,
                                          ) {
                                            return postData != null &&
                                                    postData!.likeCount > 0
                                                ? GestureDetector(
                                                    onTap: () {
                                                      Navigator.of(context)
                                                          .push(
                                                        MaterialPageRoute(
                                                          builder: (context) =>
                                                              LikesScreen(
                                                                  postId: widget
                                                                      .postId),
                                                        ),
                                                      );
                                                    },
                                                    child: Container(
                                                      color: Colors.transparent,
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                        horizontal: 16.0,
                                                      ),
                                                      child: AbsorbPointer(
                                                        absorbing: false,
                                                        child: LikesListWidget(
                                                          postId: widget.postId,
                                                        ),
                                                      ),
                                                    ),
                                                  )
                                                : const SizedBox.shrink();
                                          },
                                        ),
                                      )
                                    : const SliverToBoxAdapter(
                                        child: SizedBox(),
                                      ),
                                const SliverPadding(
                                  padding: EdgeInsets.only(bottom: 16.0),
                                ),
                                SliverToBoxAdapter(
                                  child: Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        LMTextView(
                                          text: "Comments",
                                          textStyle: theme.textTheme.titleLarge!
                                              .copyWith(
                                                  fontWeight: FontWeight.w600),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                postData == null
                                    ? const SliverToBoxAdapter(
                                        child: SizedBox(),
                                      )
                                    : PagedSliverList(
                                        pagingController: _pagingController,
                                        builderDelegate:
                                            PagedChildBuilderDelegate<Reply>(
                                          noMoreItemsIndicatorBuilder:
                                              (context) =>
                                                  const SizedBox(height: 75),
                                          noItemsFoundIndicatorBuilder:
                                              (context) => Column(
                                            children: <Widget>[
                                              const SizedBox(height: 42),
                                              Text(
                                                'No comment found',
                                                style:
                                                    theme.textTheme.labelMedium,
                                              ),
                                              const SizedBox(height: 12),
                                              Text(
                                                'Be the first one to comment',
                                                style:
                                                    theme.textTheme.labelMedium,
                                              ),
                                              const SizedBox(height: 180),
                                            ],
                                          ),
                                          itemBuilder: (context, item, index) {
                                            bool replyShown = false;
                                            return Container(
                                              decoration: BoxDecoration(
                                                color: theme
                                                    .colorScheme.background,
                                                border: const Border(
                                                  bottom: BorderSide(
                                                    width: 0.2,
                                                    color: Colors.black45,
                                                  ),
                                                ),
                                              ),
                                              child: Column(
                                                children: [
                                                  StatefulBuilder(builder:
                                                      (context,
                                                          setCommentState) {
                                                    return LMCommentTile(
                                                      key: ValueKey(item.id),
                                                      textStyle: ColorTheme
                                                          .novaTheme
                                                          .textTheme
                                                          .labelMedium,
                                                      linkStyle: ColorTheme
                                                          .novaTheme
                                                          .textTheme
                                                          .labelMedium!
                                                          .copyWith(
                                                              color: ColorTheme
                                                                  .novaTheme
                                                                  .primaryColor),
                                                      width: screenSize.width,
                                                      backgroundColor: theme
                                                          .colorScheme.surface,
                                                      borderRadius:
                                                          const BorderRadius
                                                              .only(
                                                        topRight:
                                                            Radius.circular(10),
                                                        bottomLeft:
                                                            Radius.circular(10),
                                                        bottomRight:
                                                            Radius.circular(10),
                                                      ),
                                                      margin: const EdgeInsets
                                                          .symmetric(
                                                        horizontal: 12.0,
                                                        vertical: 6.0,
                                                      ),
                                                      menu:
                                                          item.menuItems
                                                                  .isNotEmpty
                                                              ? LMIconButton(
                                                                  icon: LMIcon(
                                                                    type: LMIconType
                                                                        .icon,
                                                                    icon: Icons
                                                                        .more_vert,
                                                                    color: theme
                                                                        .colorScheme
                                                                        .onPrimary,
                                                                  ),
                                                                  onTap: (bool
                                                                      value) {
                                                                    showModalBottomSheet(
                                                                      context:
                                                                          context,
                                                                      elevation:
                                                                          5,
                                                                      isDismissible:
                                                                          true,
                                                                      useRootNavigator:
                                                                          true,
                                                                      clipBehavior:
                                                                          Clip.hardEdge,
                                                                      backgroundColor:
                                                                          Colors
                                                                              .transparent,
                                                                      enableDrag:
                                                                          false,
                                                                      shape:
                                                                          const RoundedRectangleBorder(
                                                                        borderRadius:
                                                                            BorderRadius.only(
                                                                          topLeft:
                                                                              Radius.circular(32),
                                                                          topRight:
                                                                              Radius.circular(32),
                                                                        ),
                                                                      ),
                                                                      builder:
                                                                          (context) =>
                                                                              LMBottomSheet(
                                                                        height: max(
                                                                            170,
                                                                            screenSize.height *
                                                                                0.25),
                                                                        margin: const EdgeInsets
                                                                            .only(
                                                                            top:
                                                                                30),
                                                                        borderRadius:
                                                                            const BorderRadius.only(
                                                                          topLeft:
                                                                              Radius.circular(32),
                                                                          topRight:
                                                                              Radius.circular(32),
                                                                        ),
                                                                        dragBar:
                                                                            Container(
                                                                          width:
                                                                              96,
                                                                          height:
                                                                              6,
                                                                          decoration:
                                                                              ShapeDecoration(
                                                                            color:
                                                                                theme.colorScheme.onSurface,
                                                                            shape:
                                                                                RoundedRectangleBorder(
                                                                              borderRadius: BorderRadius.circular(99),
                                                                            ),
                                                                          ),
                                                                        ),
                                                                        backgroundColor: theme
                                                                            .colorScheme
                                                                            .surface,
                                                                        children: item
                                                                            .menuItems
                                                                            .map(
                                                                              (e) => GestureDetector(
                                                                                onTap: () {
                                                                                  Navigator.of(context).pop();
                                                                                  if (e.id == commentDeleteId) {
                                                                                    deselectCommentToEdit();
                                                                                    deselectCommentToReply();
                                                                                    // Delete post
                                                                                    showDialog(
                                                                                        context: context,
                                                                                        builder: (childContext) => deleteConfirmationDialog(
                                                                                              childContext,
                                                                                              title: 'Delete Comment',
                                                                                              userId: item.userId,
                                                                                              content: 'Are you sure you want to delete this post. This action can not be reversed.',
                                                                                              action: (String reason) async {
                                                                                                Navigator.of(childContext).pop();
                                                                                                //Implement delete post analytics tracking
                                                                                                LMAnalytics.get().track(
                                                                                                  AnalyticsKeys.commentDeleted,
                                                                                                  {
                                                                                                    "post_id": widget.postId,
                                                                                                    "comment_id": item.id,
                                                                                                  },
                                                                                                );
                                                                                                if (postDetailResponse != null) {
                                                                                                  postDetailResponse!.users?.putIfAbsent(currentUser.userUniqueId, () => currentUser);
                                                                                                }
                                                                                                _addCommentReplyBloc.add(DeleteComment((DeleteCommentRequestBuilder()
                                                                                                      ..postId(widget.postId)
                                                                                                      ..commentId(item.id)
                                                                                                      ..reason(reason.isEmpty ? "Reason for deletion" : reason))
                                                                                                    .build()));
                                                                                              },
                                                                                              actionText: 'Yes, delete',
                                                                                            ));
                                                                                  } else if (e.id == commentEditId) {
                                                                                    debugPrint('Editing functionality');
                                                                                    _addCommentReplyBloc.add(EditCommentCancel());
                                                                                    _addCommentReplyBloc.add(
                                                                                      EditingComment(
                                                                                        commentId: item.id,
                                                                                        text: item.text,
                                                                                      ),
                                                                                    );
                                                                                  } else if (e.id == commentReportId) {
                                                                                    Navigator.of(context).push(
                                                                                      MaterialPageRoute(
                                                                                        builder: (context) => ReportScreen(
                                                                                          entityCreatorId: item.userId,
                                                                                          entityId: item.id,
                                                                                          entityType: commentReportEntityType,
                                                                                        ),
                                                                                      ),
                                                                                    );
                                                                                  }
                                                                                },
                                                                                child: Container(
                                                                                  color: Colors.transparent,
                                                                                  padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 16.0),
                                                                                  margin: const EdgeInsets.only(bottom: 24.09),
                                                                                  width: screenSize.width - 32.0,
                                                                                  child: Row(children: [
                                                                                    getIconFromDropDownItemId(
                                                                                      e.id,
                                                                                      20,
                                                                                      theme.colorScheme.onPrimary,
                                                                                    ),
                                                                                    kHorizontalPaddingLarge,
                                                                                    LMTextView(
                                                                                      text: e.title,
                                                                                      textStyle: theme.textTheme.headlineLarge!.copyWith(color: e.id == commentDeleteId ? theme.colorScheme.error : null),
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
                                                              : const SizedBox
                                                                  .shrink(),
                                                      onTagTap:
                                                          (String userId) {
                                                        locator<LikeMindsService>()
                                                            .routeToProfile(
                                                                userId);
                                                      },
                                                      onMenuTap: (id) {},
                                                      comment: item,
                                                      user: postDetailResponse!
                                                          .users![item.userId]!,
                                                      profilePicture:
                                                          LMProfilePicture(
                                                        fallbackText:
                                                            postDetailResponse!
                                                                .users![item
                                                                    .userId]!
                                                                .name,
                                                        backgroundColor:
                                                            theme.primaryColor,
                                                        onTap: () {
                                                          if (postDetailResponse!
                                                                  .users![item
                                                                      .userId]!
                                                                  .sdkClientInfo !=
                                                              null) {
                                                            locator<LikeMindsService>().routeToProfile(
                                                                postDetailResponse!
                                                                    .users![item
                                                                        .userId]!
                                                                    .sdkClientInfo!
                                                                    .userUniqueId);
                                                          }
                                                        },
                                                        imageUrl:
                                                            postDetailResponse!
                                                                .users![item
                                                                    .userId]!
                                                                .imageUrl,
                                                        size: 42,
                                                        boxShape:
                                                            BoxShape.circle,
                                                      ),
                                                      titleText: LMTextView(
                                                        text:
                                                            postDetailResponse!
                                                                .users![item
                                                                    .userId]!
                                                                .name,
                                                        textStyle: theme
                                                            .textTheme
                                                            .labelMedium!,
                                                      ),
                                                      subtitleText: LMTextView(
                                                        text: timeago.format(
                                                            item.createdAt),
                                                        textStyle: theme
                                                            .textTheme
                                                            .bodySmall!
                                                            .copyWith(
                                                                color: ColorTheme
                                                                    .lightWhite300),
                                                      ),
                                                      actionsPadding:
                                                          const EdgeInsets.only(
                                                        left: 56,
                                                      ),
                                                      commentActions: [
                                                        LMTextButton(
                                                          margin: 10,
                                                          text: LMTextView(
                                                            text:
                                                                "${item.likesCount}",
                                                            onTap: () {
                                                              Navigator.of(
                                                                      context)
                                                                  .push(
                                                                MaterialPageRoute(
                                                                  builder:
                                                                      (context) =>
                                                                          LikesScreen(
                                                                    commentId:
                                                                        item.id,
                                                                    isCommentLikes:
                                                                        true,
                                                                    postId: widget
                                                                        .postId,
                                                                  ),
                                                                ),
                                                              );
                                                            },
                                                            textStyle: theme
                                                                .textTheme
                                                                .labelMedium,
                                                          ),
                                                          activeText:
                                                              LMTextView(
                                                            text:
                                                                "${item.likesCount}",
                                                            textStyle: theme
                                                                .textTheme
                                                                .labelMedium,
                                                          ),
                                                          onTap: () {
                                                            _toggleLikeCommentBloc
                                                                .add(
                                                              ToggleLikeComment(
                                                                toggleLikeCommentRequest:
                                                                    (ToggleLikeCommentRequestBuilder()
                                                                          ..commentId(
                                                                              item.id)
                                                                          ..postId(
                                                                              widget.postId))
                                                                        .build(),
                                                              ),
                                                            );
                                                            setCommentState(() {
                                                              if (item
                                                                  .isLiked) {
                                                                item.likesCount -=
                                                                    1;
                                                              } else {
                                                                item.likesCount +=
                                                                    1;
                                                              }
                                                              item.isLiked =
                                                                  !item.isLiked;
                                                            });
                                                          },
                                                          icon: LMIcon(
                                                            type:
                                                                LMIconType.svg,
                                                            assetPath:
                                                                kAssetLikeIcon,
                                                            size: 14,
                                                            color: theme
                                                                .colorScheme
                                                                .onPrimary,
                                                          ),
                                                          activeIcon: LMIcon(
                                                            type:
                                                                LMIconType.svg,
                                                            assetPath:
                                                                kAssetLikeFilledIcon,
                                                            size: 14,
                                                            color: theme
                                                                .colorScheme
                                                                .error,
                                                          ),
                                                          isActive:
                                                              item.isLiked,
                                                        ),
                                                        kHorizontalPaddingSmall,
                                                        LMTextView(
                                                          text: '·',
                                                          textStyle: TextStyle(
                                                            fontSize:
                                                                kFontSmall,
                                                            color: theme
                                                                .colorScheme
                                                                .onPrimary,
                                                            fontFamily:
                                                                'Gantari',
                                                          ),
                                                        ),
                                                        kHorizontalPaddingSmall,
                                                        Row(
                                                          children: [
                                                            LMTextButton(
                                                              margin: 10,
                                                              text: LMTextView(
                                                                text: "Reply",
                                                                textStyle: theme
                                                                    .textTheme
                                                                    .labelMedium,
                                                              ),
                                                              onTap: () {
                                                                selectCommentToReply(
                                                                  item.id,
                                                                  postDetailResponse!
                                                                      .users![item
                                                                          .userId]!
                                                                      .name,
                                                                );
                                                              },
                                                            ),
                                                            kHorizontalPaddingSmall,
                                                            item.repliesCount >
                                                                    0
                                                                ? LMTextView(
                                                                    text: '·',
                                                                    textStyle:
                                                                        TextStyle(
                                                                      fontSize:
                                                                          kFontSmall,
                                                                      fontFamily:
                                                                          'Gantari',
                                                                      color: theme
                                                                          .colorScheme
                                                                          .onPrimary,
                                                                    ),
                                                                  )
                                                                : const SizedBox(),
                                                            kHorizontalPaddingSmall,
                                                            item.repliesCount >
                                                                    0
                                                                ? LMTextButton(
                                                                    onTap: () {
                                                                      if (!replyShown) {
                                                                        _commentRepliesBloc.add(GetCommentReplies(
                                                                            commentDetailRequest: (GetCommentRequestBuilder()
                                                                                  ..commentId(item.id)
                                                                                  ..postId(widget.postId)
                                                                                  ..page(1))
                                                                                .build(),
                                                                            forLoadMore: true));
                                                                        replyShown =
                                                                            true;
                                                                      }
                                                                    },
                                                                    text:
                                                                        LMTextView(
                                                                      text:
                                                                          "${item.repliesCount} ${item.repliesCount > 1 ? 'Replies' : 'Reply'}",
                                                                      textStyle:
                                                                          TextStyle(
                                                                        color: ColorTheme
                                                                            .novaTheme
                                                                            .colorScheme
                                                                            .primary,
                                                                        fontFamily:
                                                                            'Gantari',
                                                                      ),
                                                                    ),
                                                                  )
                                                                : const SizedBox()
                                                          ],
                                                        ),
                                                      ],
                                                    );
                                                  }),
                                                  CommentReplyWidget(
                                                    onReply:
                                                        selectCommentToReply,
                                                    refresh: () {
                                                      _pagingController
                                                          .refresh();
                                                    },
                                                    postId: widget.postId,
                                                    reply: item,
                                                    user: postDetailResponse!
                                                        .users![item.userId]!,
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                SliverPadding(
                                  padding: EdgeInsets.only(
                                      bottom:
                                          isEditing || isReplying ? 60.0 : 0),
                                ),
                              ],
                            ),
                          );
                        }),
                  );
                }
                return Center(
                    child: CircularProgressIndicator(
                  color: ColorTheme.novaTheme.primaryColor,
                ));
              },
            )),
      ),
    );
  }

  void openOnScreenKeyboard() {
    if (focusNode.canRequestFocus) {
      focusNode.requestFocus();
      if (_commentController != null && _commentController!.text.isNotEmpty) {
        _commentController!.selection = TextSelection.fromPosition(
            TextPosition(offset: _commentController!.text.length));
      }
    }
  }

  void closeOnScreenKeyboard() {
    if (focusNode.hasFocus) {
      focusNode.unfocus();
    }
  }
}
