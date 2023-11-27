import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:likeminds_feed/likeminds_feed.dart';
import 'package:likeminds_feed_nova_fl/likeminds_feed_nova_fl.dart';
import 'package:likeminds_feed_nova_fl/src/blocs/new_post/new_post_bloc.dart';
import 'package:likeminds_feed_nova_fl/src/blocs/universal_feed/universal_feed_bloc.dart';
import 'package:likeminds_feed_nova_fl/src/models/post_view_model.dart';
import 'package:likeminds_feed_nova_fl/src/persistence/logger/logger.dart';
import 'package:likeminds_feed_nova_fl/src/services/likeminds_service.dart';
import 'package:likeminds_feed_nova_fl/src/utils/constants/ui_constants.dart';
import 'package:likeminds_feed_nova_fl/src/utils/post/post_action_id.dart';
import 'package:likeminds_feed_nova_fl/src/utils/post/post_utils.dart';
import 'package:likeminds_feed_nova_fl/src/views/post/edit_post_screen.dart';
import 'package:likeminds_feed_nova_fl/src/views/post/new_post_screen.dart';
import 'package:likeminds_feed_nova_fl/src/views/post_detail_screen.dart';
import 'package:likeminds_feed_nova_fl/src/views/report_screen.dart';
import 'package:likeminds_feed_nova_fl/src/widgets/delete_dialog.dart';
import 'package:likeminds_feed_nova_fl/src/widgets/post/post_widget.dart';
import 'package:likeminds_feed_ui_fl/likeminds_feed_ui_fl.dart';
import 'package:overlay_support/overlay_support.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  bool showScrollButton = true;
  ScrollController scrollController = ScrollController();
  late final UniversalFeedBloc _feedBloc;
  ValueNotifier<bool> rebuildPostWidget = ValueNotifier(false);
  final ValueNotifier postUploading = ValueNotifier(false);

  final PagingController<int, PostViewModel> _pagingController =
      PagingController(
    firstPageKey: 1,
  );

  void _scrollToTop() {
    scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOut,
    );
  }

  @override
  void initState() {
    super.initState();
    // Bloc.observer = SimpleBlocObserver();
    _feedBloc = UniversalFeedBloc();
    _feedBloc.add(const GetUniversalFeed(offset: 1));
    scrollController.addListener(() {
      _showScrollToBottomButton();
    });
    _addPaginationListener();
  }

  void _showScrollToBottomButton() {
    if (scrollController.offset > 10.0) {
      _showButton();
    } else {
      _hideButton();
    }
  }

  void _showButton() {
    setState(() {
      showScrollButton = true;
    });
  }

  void _hideButton() {
    setState(() {
      showScrollButton = false;
    });
  }

  @override
  void dispose() {
    _feedBloc.close();
    scrollController.dispose();
    _pagingController.dispose();
    super.dispose();
  }

  void _addPaginationListener() {
    _pagingController.addPageRequestListener((pageKey) {
      _feedBloc.add(GetUniversalFeed(offset: pageKey));
    });
  }

  void refresh() => _pagingController.refresh();

  int _pageFeed = 1; // current index of FeedRoom

  // This function clears the paging controller
  // whenever user uses pull to refresh on feedroom screen
  void clearPagingController() {
    /* Clearing paging controller while changing the
     event to prevent duplication of list */
    if (_pagingController.itemList != null) _pagingController.itemList!.clear();
    _pageFeed = 1;
  }

  // This function updates the paging controller based on the state changes
  void updatePagingControllers(Object? state) {
    if (state is UniversalFeedLoaded) {
      _pageFeed++;
      List<PostViewModel> listOfPosts =
          state.feed.posts.map((e) => PostViewModel.fromPost(post: e)).toList();
      if (state.feed.posts.length < 10) {
        _pagingController.appendLastPage(listOfPosts);
      } else {
        _pagingController.appendPage(listOfPosts, _pageFeed);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    NewPostBloc newPostBloc = locator<BlocService>().newPostBlocProvider;
    return Scaffold(
      backgroundColor: kWhiteColor.withOpacity(0.95),
      appBar: AppBar(
        backgroundColor: kWhiteColor,
        centerTitle: false,
        title: LMTextView(
          text: "Feed",
          textAlign: TextAlign.start,
          textStyle: ColorTheme.novaTheme.textTheme.titleLarge!.copyWith(
            color: Colors.black,
            fontSize: 28,
            fontWeight: FontWeight.w800,
          ),
        ),
        elevation: 1,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          refresh();
          clearPagingController();
        },
        child: BlocConsumer(
          bloc: _feedBloc,
          buildWhen: (prev, curr) {
            // Prevents changin the state while paginating the feed
            if (prev is UniversalFeedLoaded &&
                (curr is PaginatedUniversalFeedLoading ||
                    curr is UniversalFeedLoading)) {
              return false;
            }
            return true;
          },
          listener: (context, state) => updatePagingControllers(state),
          builder: (context, state) {
            if (state is UniversalFeedLoaded) {
              GetFeedResponse feedResponse = state.feed;
              return PagedListView<int, PostViewModel>(
                pagingController: _pagingController,
                scrollController: scrollController,
                builderDelegate: PagedChildBuilderDelegate<PostViewModel>(
                  noItemsFoundIndicatorBuilder: (context) => Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const LMIcon(
                          type: LMIconType.icon,
                          icon: Icons.post_add,
                          size: 48,
                        ),
                        const SizedBox(height: 12),
                        const Text("No posts to show",
                            style: TextStyle(
                              fontSize: 24,
                              fontFamily: 'Gantari',
                              fontWeight: FontWeight.bold,
                            )),
                        const SizedBox(height: 12),
                        const Text("Be the first one to post here",
                            style: TextStyle(
                                fontSize: 16,
                                fontFamily: 'Gantari',
                                fontWeight: FontWeight.w300,
                                color: kGrey2Color)),
                        const SizedBox(height: 28),
                        LMTextButton(
                          height: 48,
                          width: 142,
                          borderRadius: 28,
                          backgroundColor:
                              ColorTheme.novaTheme.colorScheme.primary,
                          text: LMTextView(
                            text: "Create Post",
                            textStyle: ColorTheme
                                .novaTheme.textTheme.titleLarge!
                                .copyWith(
                              color: ColorTheme.novaTheme.colorScheme.onPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          icon: LMIcon(
                            type: LMIconType.icon,
                            icon: Icons.add,
                            color: ColorTheme.novaTheme.colorScheme.onPrimary,
                          ),
                          onTap: () {
                            if (!postUploading.value) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => NewPostScreen(),
                                ),
                              );
                            } else {
                              toast(
                                'A post is already uploading.',
                                duration: Toast.LENGTH_LONG,
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  itemBuilder: (context, item, index) {
                    return Column(
                      children: [
                        const SizedBox(height: 8),
                        NovaPostWidget(
                          post: item,
                          user: feedResponse.users[item.userId]!,
                          topics: feedResponse.topics,
                          widgets: feedResponse.widgets,
                          onMenuTap: (int id) {
                            if (id == postDeleteId) {
                              showDialog(
                                  context: context,
                                  builder: (childContext) =>
                                      deleteConfirmationDialog(
                                        childContext,
                                        title: 'Delete Post?',
                                        userId: item.userId,
                                        content:
                                            'Are you sure you want to permanently remove this post from Nova?',
                                        action: (String reason) async {
                                          Navigator.of(childContext).pop();
                                          final res =
                                              await locator<LikeMindsService>()
                                                  .getMemberState();
                                          //Implement delete post analytics tracking
                                          LMAnalytics.get().track(
                                            AnalyticsKeys.postDeleted,
                                            {
                                              "user_state": res.state == 1
                                                  ? "CM"
                                                  : "member",
                                              "post_id": item.id,
                                              "user_id": item.userId,
                                            },
                                          );
                                          newPostBloc.add(
                                            DeletePost(
                                              postId: item.id,
                                              reason: reason ?? 'Self Post',
                                            ),
                                          );
                                        },
                                        actionText: 'Yes, delete',
                                      ));
                            } else if (id == postPinId || id == postUnpinId) {
                              try {
                                String? postType = getPostType(
                                    item.attachments?.first.attachmentType ??
                                        0);
                                if (item.isPinned) {
                                  LMAnalytics.get()
                                      .track(AnalyticsKeys.postUnpinned, {
                                    "created_by_id": item.userId,
                                    "post_id": item.id,
                                    "post_type": postType,
                                  });
                                } else {
                                  LMAnalytics.get()
                                      .track(AnalyticsKeys.postPinned, {
                                    "created_by_id": item.userId,
                                    "post_id": item.id,
                                    "post_type": postType,
                                  });
                                }
                              } on Exception catch (err, stacktrace) {
                                LMFeedLogger.instance.handleException(
                                    err.toString(), stacktrace);
                              }

                              newPostBloc.add(TogglePinPost(
                                  postId: item.id, isPinned: !item.isPinned));
                            } else if (id == postEditId) {
                              try {
                                String? postType;
                                postType = getPostType(
                                    item.attachments?.first.attachmentType ??
                                        0);
                                LMAnalytics.get().track(
                                  AnalyticsKeys.postEdited,
                                  {
                                    "created_by_id": item.userId,
                                    "post_id": item.id,
                                    "post_type": postType,
                                  },
                                );
                              } on Exception catch (err, stacktrace) {
                                debugPrint(err.toString());
                                LMFeedLogger.instance.handleException(
                                    err.toString(), stacktrace);
                              }
                              List<TopicUI> postTopics = [];

                              if (item.topics.isNotEmpty &&
                                  feedResponse.topics
                                      .containsKey(item.topics.first)) {
                                postTopics.add(TopicUI.fromTopic(
                                    feedResponse.topics[item.topics.first]!));
                              }

                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => EditPostScreen(
                                    postId: item.id,
                                    selectedTopics: postTopics,
                                  ),
                                ),
                              );
                            } else if (id == postReportId) {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => ReportScreen(
                                    entityCreatorId: item.userId,
                                    entityId: item.id,
                                    entityType: postReportEntityType,
                                  ),
                                ),
                              );
                            }
                          },
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PostDetailScreen(
                                  postId: item.id,
                                ),
                              ),
                            );
                          },
                          isFeed: true,
                          refresh: (bool isDeleted) async {
                            if (!isDeleted) {
                              final GetPostResponse updatedPostDetails =
                                  await locator<LikeMindsService>().getPost(
                                (GetPostRequestBuilder()
                                      ..postId(item.id)
                                      ..page(1)
                                      ..pageSize(10))
                                    .build(),
                              );
                              item = PostViewModel.fromPost(
                                  post: updatedPostDetails.post!);
                              List<PostViewModel>? feedRoomItemList =
                                  _pagingController.itemList;
                              feedRoomItemList?[index] = item;
                              _pagingController.itemList = feedRoomItemList;
                              rebuildPostWidget.value =
                                  !rebuildPostWidget.value;
                            } else {
                              List<PostViewModel>? feedRoomItemList =
                                  _pagingController.itemList;
                              feedRoomItemList!.removeAt(index);
                              _pagingController.itemList = feedRoomItemList;
                              rebuildPostWidget.value =
                                  !rebuildPostWidget.value;
                            }
                          },
                        ),
                      ],
                    );
                  },
                ),
              );
            }
            return Center(
              child: CircularProgressIndicator(
                color: ColorTheme.novaTheme.primaryColor,
              ),
            );
          },
        ),
      ),
      floatingActionButtonAnimator: FloatingActionButtonAnimator.scaling,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Wrap(
        direction: Axis.horizontal,
        children: [
          // Container(
          //   height: 25,
          //   margin: const EdgeInsets.only(bottom: 12),
          //   width: 25,
          //   decoration: BoxDecoration(
          //     shape: BoxShape.circle,
          //     color: kPrimaryColor,
          //     boxShadow: [
          //       BoxShadow(
          //         offset: const Offset(0, 4),
          //         blurRadius: 25,
          //         color: Colors.black.withOpacity(0.3),
          //       )
          //     ],
          //   ),
          //   child: Center(
          //     child: LMIconButton(
          //       onTap: (value) {
          //         _scrollToTop();
          //       },
          //       icon: const LMIcon(
          //         type: LMIconType.icon,
          //         icon: Icons.keyboard_arrow_up,
          //         color: Colors.white,
          //         size: 14,
          //       ),
          //     ),
          //   ),
          // ),
          LMTextButton(
            height: 56,
            width: 140,
            borderRadius: 28,
            placement: LMIconPlacement.start,
            backgroundColor: ColorTheme.novaTheme.colorScheme.primary,
            text: LMTextView(
              text: "New Post",
              textStyle: TextStyle(
                color: ColorTheme.novaTheme.colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
                fontFamily: 'Gantari',
              ),
            ),
            icon: LMIcon(
              type: LMIconType.icon,
              icon: Icons.add,
              size: 12,
              color: ColorTheme.novaTheme.colorScheme.onPrimary,
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => NewPostScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
