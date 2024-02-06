import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:likeminds_feed/likeminds_feed.dart';

import 'package:flutter/material.dart';
import 'package:likeminds_feed_flutter_core/likeminds_feed_core.dart';
import 'package:likeminds_feed_nova_fl/src/blocs/post/likes/likes_bloc.dart';
import 'package:likeminds_feed_nova_fl/src/blocs/simple_bloc_observer.dart';
import 'package:likeminds_feed_nova_fl/src/utils/analytics/analytics.dart';
import 'package:likeminds_feed_nova_fl/src/utils/constants/assets_constants.dart';
import 'package:likeminds_feed_nova_fl/src/utils/constants/ui_constants.dart';
import 'package:likeminds_feed_nova_fl/src/widgets/likes/likes_helper.dart';
import 'package:likeminds_feed_nova_fl/src/widgets/user_tile_widget.dart';
import 'package:likeminds_feed_ui_fl/likeminds_feed_ui_fl.dart';

class LikesListWidget extends StatefulWidget {
  static const String route = "/likes_screen";
  final String postId;
  final bool isCommentLikes;
  final String? commentId;

  const LikesListWidget({
    super.key,
    this.isCommentLikes = false,
    required this.postId,
    this.commentId,
  });

  @override
  State<LikesListWidget> createState() => _LikesListWidgetState();
}

class _LikesListWidgetState extends State<LikesListWidget> {
  LikesBloc? _likesBloc;
  int _offset = 1;
  Map<String, User> userData = {};
  ThemeData? theme;

  final PagingController<int, Like> _pagingControllerLikes =
      PagingController(firstPageKey: 1);

  final PagingController<int, LMLikeViewData> _pagingControllerCommentLikes =
      PagingController(firstPageKey: 1);

  void _addPaginationListener() {
    if (widget.isCommentLikes) {
      _pagingControllerCommentLikes.addPageRequestListener(
        (pageKey) {
          _likesBloc!.add(
            GetCommentLikes(
              offset: pageKey,
              pageSize: 10,
              postId: widget.postId,
              commentId: widget.commentId!,
            ),
          );
        },
      );
    } else {
      _pagingControllerLikes.addPageRequestListener(
        (pageKey) {
          _likesBloc!.add(
            GetLikes(
              postId: widget.postId,
              offset: pageKey,
              pageSize: 10,
            ),
          );
        },
      );
    }
  }

  @override
  void initState() {
    super.initState();
    Bloc.observer = SimpleBlocObserver();
    _likesBloc = LikesBloc();
    _addPaginationListener();
    if (widget.isCommentLikes && widget.commentId != null) {
      _likesBloc!.add(
        GetCommentLikes(
          offset: 1,
          pageSize: 5,
          postId: widget.postId,
          commentId: widget.commentId!,
        ),
      );
    } else {
      _likesBloc!.add(
        GetLikes(
          offset: 1,
          pageSize: 5,
          postId: widget.postId,
        ),
      );
    }
  }

  @override
  void dispose() {
    _pagingControllerLikes.dispose();
    _pagingControllerCommentLikes.dispose();
    _likesBloc?.close();
    super.dispose();
  }

  void updatePagingControllers(Object? state) {
    if (state is LikesLoaded) {
      _offset += 1;
      if (state.response.likes!.length < 10) {
        userData.addAll(state.response.users ?? {});
        _pagingControllerLikes.appendLastPage(state.response.likes ?? []);
      } else {
        userData.addAll(state.response.users ?? {});
        _pagingControllerLikes.appendPage(state.response.likes!, _offset);
      }
    }
    if (state is CommentLikesLoaded) {
      _offset += 1;
      if (state.response.commentLikes!.length < 10) {
        // userData.addAll(state.response.users ?? {});
        // _pagingControllerCommentLikes
        //     .appendLastPage(state.response.commentLikes ?? []);
      } else {
        // userData.addAll(state.response.users ?? {});
        // _pagingControllerCommentLikes.appendPage(
        //     state.response.commentLikes!, _offset);
      }
    }
  }

  // Analytics event logging for Like Screen
  void logLikeListEvent(totalLikes) {
    LMAnalytics.get().track(
      AnalyticsKeys.likeListOpen,
      {
        "post_id": widget.postId,
        "total_likes": totalLikes,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    theme = ColorTheme.novaTheme;
    return BlocConsumer(
      bloc: _likesBloc,
      buildWhen: (previous, current) {
        if (current is LikesPaginationLoading &&
            (previous is LikesLoaded || previous is CommentLikesLoaded)) {
          return false;
        }
        return true;
      },
      listener: (context, state) => updatePagingControllers(state),
      builder: (context, state) {
        if (state is LikesLoading) {
          return getLikesLoadingView();
        } else if (state is LikesError) {
          return getLikesErrorView(state.message);
        } else if (state is LikesLoaded) {
          if (!widget.isCommentLikes) {
            logLikeListEvent(state.response.totalCount);
          }
          return getLikesLoadedView(state: state);
        } else if (state is CommentLikesLoaded) {
          return getCommentLikesLoadedView(commentState: state);
        } else {
          return const SizedBox();
        }
      },
    );
  }

  Widget getCommentLikesLoadedView({CommentLikesLoaded? commentState}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LMTextView(
          text: 'Liked By',
          textStyle: theme!.textTheme.titleLarge,
        ),
        kVerticalPaddingMedium,
        SizedBox(
          height: 50,
          child: PagedListView(
            padding: EdgeInsets.zero,
            scrollDirection: Axis.horizontal,
            pagingController: _pagingControllerCommentLikes,
            builderDelegate: PagedChildBuilderDelegate<LMLikeViewData>(
              noMoreItemsIndicatorBuilder: (context) => const SizedBox(
                height: 20,
              ),
              noItemsFoundIndicatorBuilder: (context) => const SizedBox(),
              itemBuilder: (context, item, index) =>
                  LikesTile(user: userData[item.userId]),
            ),
          ),
        ),
      ],
    );
  }

  Widget getLikesLoadedView({
    LikesLoaded? state,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LMTextView(
          text: 'Liked By',
          textStyle: theme!.textTheme.titleLarge,
        ),
        kVerticalPaddingMedium,
        SizedBox(
          height: 50,
          child: PagedListView<int, Like>(
            padding: EdgeInsets.zero,
            scrollDirection: Axis.horizontal,
            pagingController: _pagingControllerLikes,
            builderDelegate: PagedChildBuilderDelegate<Like>(
              noMoreItemsIndicatorBuilder: (context) => SizedBox(
                height: 48,
                width: 48,
                child: Container(
                  decoration: BoxDecoration(
                    color: ColorTheme.darkBlack500,
                    border: Border.all(color: ColorTheme.darkBlack300),
                    borderRadius: const BorderRadius.all(
                      Radius.circular(24),
                    ),
                  ),
                  child: const LMIcon(
                    type: LMIconType.icon,
                    icon: Icons.more_horiz,
                    color: ColorTheme.lightWhite300,
                  ),
                ),
              ),
              noItemsFoundIndicatorBuilder: (context) => const SizedBox(),
              itemBuilder: (context, item, index) =>
                  LikesTile(user: userData[item.userId]),
            ),
          ),
        )
      ],
    );
  }

  Widget getLikesErrorView(String message) {
    return const SizedBox();
  }

  Widget getLikesLoadingView() {
    return const SizedBox();
  }
}

class LikesTile extends StatelessWidget {
  final User? user;
  const LikesTile({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    ThemeData theme = ColorTheme.novaTheme;
    if (user != null) {
      return Container(
        margin: const EdgeInsets.only(right: 20.0),
        child: Stack(
          children: [
            user!.isDeleted != null && user!.isDeleted!
                ? const SizedBox()
                : LMProfilePicture(
                    fallbackText: user!.name,
                    imageUrl: user!.imageUrl,
                    backgroundColor: theme.primaryColor,
                    boxShape: BoxShape.circle,
                    size: 48,
                  ),
            Positioned(
                right: 3,
                bottom: 3,
                child: LMIcon(
                  type: LMIconType.svg,
                  assetPath: kAssetLikeFilledIcon,
                  color: theme.colorScheme.error,
                  size: 12,
                ))
          ],
        ),
      );
    } else {
      return const SizedBox();
    }
  }
}
