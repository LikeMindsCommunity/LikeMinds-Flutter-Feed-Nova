import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'package:likeminds_feed/likeminds_feed.dart';

import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:likeminds_feed_nova_fl/likeminds_feed_nova_fl.dart';
import 'package:likeminds_feed_nova_fl/src/blocs/new_post/new_post_bloc.dart';
import 'package:likeminds_feed_nova_fl/src/blocs/simple_bloc_observer.dart';
import 'package:likeminds_feed_nova_fl/src/blocs/universal_feed/universal_feed_bloc.dart';
import 'package:likeminds_feed_nova_fl/src/models/post_view_model.dart';
import 'package:likeminds_feed_nova_fl/src/services/likeminds_service.dart';
import 'package:likeminds_feed_nova_fl/src/utils/constants/assets_constants.dart';
import 'package:likeminds_feed_nova_fl/src/utils/constants/ui_constants.dart';
import 'package:likeminds_feed_nova_fl/src/utils/post/post_action_id.dart';
import 'package:likeminds_feed_nova_fl/src/utils/post/post_utils.dart';
import 'package:likeminds_feed_nova_fl/src/utils/utils.dart';
import 'package:likeminds_feed_nova_fl/src/views/post/edit_post_screen.dart';
import 'package:likeminds_feed_nova_fl/src/views/post/new_post_screen.dart';
import 'package:likeminds_feed_nova_fl/src/views/post_detail_screen.dart';
import 'package:likeminds_feed_nova_fl/src/widgets/delete_dialog.dart';
import 'package:likeminds_feed_nova_fl/src/widgets/post/post_something.dart';
import 'package:likeminds_feed_nova_fl/src/widgets/post/post_widget.dart';
import 'package:likeminds_feed_nova_fl/src/widgets/topic/topic_bottom_sheet.dart';
import 'package:likeminds_feed_ui_fl/likeminds_feed_ui_fl.dart';
import 'package:overlay_support/overlay_support.dart';

class UniversalFeedScreen extends StatefulWidget {
  final Function(BuildContext context)? openChatCallback;
  const UniversalFeedScreen({
    this.openChatCallback,
    super.key,
  });

  @override
  State<UniversalFeedScreen> createState() => _UniversalFeedScreenState();
}

class _UniversalFeedScreenState extends State<UniversalFeedScreen> {
  ThemeData? theme;
  /* 
  * defines the height of topic feed bar
  * initialy set to 0, after fetching the topics
  * it is set to 62 if the topics are not empty
  */
  final ScrollController _controller = ScrollController();
  // notifies value listenable builder to rebuild the topic feed
  ValueNotifier<bool> rebuildTopicFeed = ValueNotifier(false);
  // future to get the topics
  Future<GetTopicsResponse>? getTopicsResponse;
  // list of selected topics by the user
  List<TopicUI> selectedTopics = [];
  bool topicVisible = true;

  // bloc to handle universal feed
  late final UniversalFeedBloc _feedBloc; // bloc to fetch the feedroom data
  bool isCm = UserLocalPreference.instance
      .fetchMemberState(); // whether the logged in user is a community manager or not

  User user = UserLocalPreference.instance.fetchUserData();

  // future to get the unread notification count
  late Future<GetUnreadNotificationCountResponse> getUnreadNotificationCount;

  // used to rebuild the appbar
  final ValueNotifier _rebuildAppBar = ValueNotifier(false);

  // to control paging on FeedRoom View
  final PagingController<int, PostViewModel> _pagingController =
      PagingController(firstPageKey: 1);

  final ValueNotifier postSomethingNotifier = ValueNotifier(false);
  bool userPostingRights = true;
  var iconContainerHeight = 60.00;

  @override
  void initState() {
    super.initState();
    _addPaginationListener();
    getTopicsResponse = locator<LikeMindsService>().getTopics(
      (GetTopicsRequestBuilder()
            ..page(1)
            ..pageSize(20))
          .build(),
    );
    Bloc.observer = SimpleBlocObserver();
    _feedBloc = UniversalFeedBloc();
    _feedBloc.add(GetUniversalFeed(offset: 1, topics: selectedTopics));
    updateUnreadNotificationCount();
    _controller.addListener(_scrollListener);
    userPostingRights = checkPostCreationRights();
  }

  bool checkPostCreationRights() {
    final MemberStateResponse memberStateResponse =
        UserLocalPreference.instance.fetchMemberRights();
    if (memberStateResponse.state == 1) {
      return true;
    }
    final memberRights = UserLocalPreference.instance.fetchMemberRight(9);
    return memberRights;
  }

  void _scrollListener() {
    if (_controller.position.userScrollDirection == ScrollDirection.reverse) {
      if (iconContainerHeight != 0) {
        iconContainerHeight = 0;
        topicVisible = false;
        rebuildTopicFeed.value = !rebuildTopicFeed.value;
        postSomethingNotifier.value = !postSomethingNotifier.value;
      }
    }
    if (_controller.position.userScrollDirection == ScrollDirection.forward) {
      if (iconContainerHeight == 0) {
        iconContainerHeight = 60.0;
        topicVisible = true;
        rebuildTopicFeed.value = !rebuildTopicFeed.value;
        postSomethingNotifier.value = !postSomethingNotifier.value;
      }
    }
  }

  void updateSelectedTopics(List<TopicUI> topics) {
    selectedTopics = topics;
    rebuildTopicFeed.value = !rebuildTopicFeed.value;
    clearPagingController();
    _feedBloc.add(
      GetUniversalFeed(
        offset: 1,
        topics: selectedTopics,
      ),
    );
  }

  // This function fetches the unread notification count
  // and updates the respective future
  void updateUnreadNotificationCount() async {
    getUnreadNotificationCount =
        locator<LikeMindsService>().getUnreadNotificationCount();
    await getUnreadNotificationCount;
    _rebuildAppBar.value = !_rebuildAppBar.value;
  }

  @override
  void dispose() {
    _pagingController.dispose();
    _rebuildAppBar.dispose();
    _feedBloc.close();
    super.dispose();
  }

  void _scrollToTop() {
    _controller.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOut,
    );
  }

  int _pageFeed = 1; // current index of FeedRoom

  void _addPaginationListener() {
    _pagingController.addPageRequestListener(
      (pageKey) {
        _feedBloc.add(
          GetUniversalFeed(
            offset: pageKey,
            topics: selectedTopics,
          ),
        );
      },
    );
  }

  void refresh() => _pagingController.refresh();

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

  // This function clears the paging controller
  // whenever user uses pull to refresh on feedroom screen
  void clearPagingController() {
    /* Clearing paging controller while changing the
     event to prevent duplication of list */
    if (_pagingController.itemList != null) _pagingController.itemList?.clear();
    _pageFeed = 1;
  }

  void showTopicSelectSheet() {
    showModalBottomSheet(
      context: context,
      elevation: 5,
      isDismissible: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28.0),
          topRight: Radius.circular(28.0),
        ),
      ),
      enableDrag: false,
      clipBehavior: Clip.hardEdge,
      builder: (context) => TopicBottomSheet(
        key: GlobalKey(),
        backgroundColor: theme!.colorScheme.surface,
        selectedTopics: selectedTopics,
        onTopicSelected: (updatedTopics, tappedTopic) {
          updateSelectedTopics(updatedTopics);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    theme = Theme.of(context);
    return Scaffold(
      backgroundColor: ColorTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: ColorTheme.backgroundColor,
        centerTitle: false,
        title: GestureDetector(
          onTap: () {
            _scrollToTop();
          },
          child: const LMTextView(
            text: "Feed",
            textAlign: TextAlign.start,
            textStyle: TextStyle(
              color: kWhiteColor,
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        elevation: 1,
        actions: [
          if (widget.openChatCallback != null)
            LMIconButton(
              containerSize: 42,
              onTap: (active) {
                widget.openChatCallback!(context);
              },
              icon: const LMIcon(
                type: LMIconType.svg,
                assetPath: kAssetChatIcon,
                color: ColorTheme.white,
                size: 24,
                boxPadding: 6,
                boxSize: 36,
              ),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          refresh();
          clearPagingController();
        },
        child: Column(
          children: [
            ValueListenableBuilder(
              valueListenable: rebuildTopicFeed,
              builder: (context, _, __) {
                return Visibility(
                  visible: topicVisible,
                  maintainAnimation: true,
                  maintainState: true,
                  child: FutureBuilder<GetTopicsResponse>(
                      future: getTopicsResponse,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const SizedBox.shrink();
                        } else if (snapshot.hasData &&
                            snapshot.data != null &&
                            snapshot.data!.success == true) {
                          if (snapshot.data!.topics!.isNotEmpty) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20.0, vertical: 12.0),
                              child: GestureDetector(
                                onTap: () => showTopicSelectSheet(),
                                child: Row(
                                  children: [
                                    selectedTopics.isEmpty
                                        ? LMTopicChip(
                                            topic: (TopicUIBuilder()
                                                  ..id("0")
                                                  ..isEnabled(true)
                                                  ..name("Topic"))
                                                .build(),
                                            borderRadius: 20.0,
                                            borderWidth: 1,
                                            height: 30,
                                            showBorder: true,
                                            borderColor: theme!
                                                .colorScheme.onPrimaryContainer,
                                            textStyle:
                                                theme!.textTheme.bodyLarge,
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 12.0,
                                                vertical: 4.0),
                                            icon: LMIcon(
                                              type: LMIconType.icon,
                                              icon: CupertinoIcons.chevron_down,
                                              size: 16,
                                              color: theme!.colorScheme
                                                  .onPrimaryContainer,
                                            ),
                                          )
                                        : selectedTopics.length == 1
                                            ? LMTopicChip(
                                                topic: (TopicUIBuilder()
                                                      ..id(selectedTopics
                                                          .first.id)
                                                      ..isEnabled(selectedTopics
                                                          .first.isEnabled)
                                                      ..name(selectedTopics
                                                          .first.name))
                                                    .build(),
                                                borderRadius: 20.0,
                                                showBorder: false,
                                                height: 30,
                                                backgroundColor:
                                                    theme!.colorScheme.primary,
                                                textStyle:
                                                    theme!.textTheme.bodyLarge,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 12.0,
                                                        vertical: 4.0),
                                                icon: LMIcon(
                                                  type: LMIconType.icon,
                                                  icon: CupertinoIcons
                                                      .chevron_down,
                                                  size: 16,
                                                  color: theme!.colorScheme
                                                      .onPrimaryContainer,
                                                ),
                                              )
                                            : LMTopicChip(
                                                topic: (TopicUIBuilder()
                                                      ..id("0")
                                                      ..isEnabled(true)
                                                      ..name("Topics"))
                                                    .build(),
                                                borderRadius: 20.0,
                                                showBorder: false,
                                                height: 30,
                                                backgroundColor:
                                                    theme!.colorScheme.primary,
                                                textStyle:
                                                    theme!.textTheme.bodyLarge,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 12.0,
                                                        vertical: 4.0),
                                                icon: Row(
                                                  children: [
                                                    kHorizontalPaddingXSmall,
                                                    Container(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          horizontal: 4),
                                                      decoration:
                                                          ShapeDecoration(
                                                        color: Colors.white,
                                                        shape:
                                                            RoundedRectangleBorder(
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            4)),
                                                      ),
                                                      child: LMTextView(
                                                        text: selectedTopics
                                                            .length
                                                            .toString(),
                                                        textStyle: theme!
                                                            .textTheme
                                                            .bodySmall!
                                                            .copyWith(
                                                          color: theme!
                                                              .colorScheme
                                                              .primary,
                                                        ),
                                                      ),
                                                    ),
                                                    kHorizontalPaddingSmall,
                                                    LMIcon(
                                                      type: LMIconType.icon,
                                                      icon: CupertinoIcons
                                                          .chevron_down,
                                                      size: 16,
                                                      color: theme!.colorScheme
                                                          .onPrimaryContainer,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                  ],
                                ),
                              ),
                            );
                          } else {
                            return const SizedBox.shrink();
                          }
                        }
                        return const SizedBox();
                      }),
                );
              },
            ),
            Expanded(
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
                builder: ((context, state) {
                  if (state is UniversalFeedLoaded) {
                    // Log the event in the analytics
                    return FeedRoomView(
                      isCm: isCm,
                      universalFeedBloc: _feedBloc,
                      feedResponse: state.feed,
                      feedRoomPagingController: _pagingController,
                      user: user,
                      onRefresh: refresh,
                      scrollController: _controller,
                      openTopicBottomSheet: showTopicSelectSheet,
                      selectedTopicIds: selectedTopics,
                    );
                  } else if (state is UniversalFeedError) {
                    return FeedRoomErrorView(message: state.message);
                  }
                  return const LMFeedShimmer();
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FeedRoomErrorView extends StatelessWidget {
  final String message;
  const FeedRoomErrorView({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: kBackgroundColor, body: Center(child: Text(message)));
  }
}

class FeedRoomView extends StatefulWidget {
  final bool isCm;
  final User user;
  final UniversalFeedBloc universalFeedBloc;
  final GetFeedResponse feedResponse;
  final PagingController<int, PostViewModel> feedRoomPagingController;
  final ScrollController scrollController;
  final VoidCallback onRefresh;
  final VoidCallback openTopicBottomSheet;
  final List<TopicUI> selectedTopicIds;

  const FeedRoomView({
    super.key,
    required this.isCm,
    required this.universalFeedBloc,
    required this.feedResponse,
    required this.feedRoomPagingController,
    required this.user,
    required this.onRefresh,
    required this.scrollController,
    required this.openTopicBottomSheet,
    required this.selectedTopicIds,
  });

  @override
  State<FeedRoomView> createState() => _FeedRoomViewState();
}

class _FeedRoomViewState extends State<FeedRoomView> {
  ValueNotifier<bool> rebuildPostWidget = ValueNotifier(false);
  final ValueNotifier postUploading = ValueNotifier(false);
  bool scrolledToTop = true;
  final ValueNotifier rebuildNewPostFAB = ValueNotifier(true);

  ScrollController? _controller;
  final ValueNotifier postSomethingNotifier = ValueNotifier(false);
  bool right = true;

  Widget getLoaderThumbnail(MediaModel? media) {
    if (media != null) {
      if (media.mediaType == MediaType.image) {
        return Container(
          height: 50,
          width: 50,
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(6.0),
          ),
          child: LMImage(
            imageFile: media.mediaFile!,
            boxFit: BoxFit.cover,
          ),
        );
      } else if (media.mediaType == MediaType.document) {
        return Container(
          width: 48,
          height: 48,
          decoration: ShapeDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          ),
          child: Center(
            child: LMTextView(
              text: 'PDF',
              textStyle: Theme.of(context)
                  .textTheme
                  .titleLarge!
                  .copyWith(fontSize: 18),
            ),
          ),
        );
      } else {
        return const SizedBox.shrink();
      }
    } else {
      return const SizedBox.shrink();
    }
  }

  bool checkPostCreationRights() {
    final MemberStateResponse memberStateResponse =
        UserLocalPreference.instance.fetchMemberRights();
    if (memberStateResponse.state == 1) {
      return true;
    }
    final memberRights = UserLocalPreference.instance.fetchMemberRight(9);
    return memberRights;
  }

  var iconContainerHeight = 90.00;
  @override
  void initState() {
    super.initState();
    LMAnalytics.get()
        .track(AnalyticsKeys.feedOpened, {'feed_type': "universal_feed"});
    _controller = widget.scrollController..addListener(_scrollListener);
    right = checkPostCreationRights();
  }

  void _scrollListener() {
    if (_controller != null &&
        _controller!.position.userScrollDirection == ScrollDirection.reverse) {
      if (iconContainerHeight != 0) {
        iconContainerHeight = 0;
        postSomethingNotifier.value = !postSomethingNotifier.value;
      }
      if (scrolledToTop) {
        scrolledToTop = false;
        rebuildNewPostFAB.value = false;
      }
    }
    if (_controller != null &&
        _controller!.position.userScrollDirection == ScrollDirection.forward) {
      if (iconContainerHeight == 0) {
        iconContainerHeight = 90.0;
        postSomethingNotifier.value = !postSomethingNotifier.value;
      }
      if (!scrolledToTop) {
        scrolledToTop = true;
        rebuildNewPostFAB.value = true;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    NewPostBloc newPostBloc = BlocProvider.of<NewPostBloc>(context);
    ThemeData theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.onBackground,
      body: Column(
        children: [
          BlocConsumer<NewPostBloc, NewPostState>(
            bloc: newPostBloc,
            listener: (prev, curr) {
              if (curr is PostDeleted) {
                List<PostViewModel>? feedRoomItemList =
                    widget.feedRoomPagingController.itemList;
                feedRoomItemList?.removeWhere((item) => item.id == curr.postId);
                widget.feedRoomPagingController.itemList = feedRoomItemList;
                rebuildPostWidget.value = !rebuildPostWidget.value;
              }
              if (curr is NewPostUploading || curr is EditPostUploading) {
                // if current state is uploading
                // change postUploading flag to true
                // to block new post creation
                postUploading.value = true;
              }
              if (prev is NewPostUploading || prev is EditPostUploading) {
                // if state has changed from uploading
                // change postUploading flag to false
                // to allow new post creation
                postUploading.value = false;
              }
              if (curr is NewPostUploaded) {
                PostViewModel item = curr.postData;
                int index = widget.selectedTopicIds
                    .indexWhere((element) => element.id == item.topics.first);
                if (index == -1 && widget.selectedTopicIds.isNotEmpty) {
                  return;
                }
                int length =
                    widget.feedRoomPagingController.itemList?.length ?? 0;
                List<PostViewModel> feedRoomItemList =
                    widget.feedRoomPagingController.itemList ?? [];
                for (int i = 0; i < feedRoomItemList.length; i++) {
                  if (!feedRoomItemList[i].isPinned) {
                    feedRoomItemList.insert(i, item);
                    break;
                  }
                }
                if (length == feedRoomItemList.length) {
                  feedRoomItemList.add(item);
                }
                if (feedRoomItemList.isNotEmpty &&
                    feedRoomItemList.length > 10) {
                  feedRoomItemList.removeLast();
                }
                widget.feedResponse.users.addAll(curr.userData);
                widget.feedResponse.topics.addAll(curr.topics);
                widget.feedRoomPagingController.itemList = feedRoomItemList;
                postUploading.value = false;
                rebuildPostWidget.value = !rebuildPostWidget.value;
              }
              if (curr is EditPostUploaded) {
                PostViewModel? item = curr.postData;
                List<PostViewModel>? feedRoomItemList =
                    widget.feedRoomPagingController.itemList;
                int index = feedRoomItemList
                        ?.indexWhere((element) => element.id == item.id) ??
                    -1;
                if (index != -1) {
                  feedRoomItemList?[index] = item;
                }
                widget.feedResponse.users.addAll(curr.userData);
                widget.feedResponse.topics.addAll(curr.topics);
                postUploading.value = false;
                rebuildPostWidget.value = !rebuildPostWidget.value;
              }
              if (curr is NewPostError) {
                postUploading.value = false;
                toast(
                  curr.message,
                  duration: Toast.LENGTH_LONG,
                );
              }
              if (curr is PostUpdateState) {
                List<PostViewModel>? feedRoomItemList =
                    widget.feedRoomPagingController.itemList;
                int index = feedRoomItemList
                        ?.indexWhere((element) => element.id == curr.post.id) ??
                    -1;
                if (index != -1) {
                  feedRoomItemList?[index] = curr.post;
                }
                rebuildPostWidget.value = !rebuildPostWidget.value;
              }
            },
            builder: (context, state) {
              if (state is EditPostUploading) {
                return Container(
                  height: 60,
                  color: theme.colorScheme.background,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          const SizedBox(
                            width: 50,
                            height: 50,
                          ),
                          kHorizontalPaddingMedium,
                          Text(
                            'Saving',
                            style: theme.textTheme.bodyMedium,
                          )
                        ],
                      ),
                      CircularProgressIndicator(
                        valueColor:
                            AlwaysStoppedAnimation(theme.colorScheme.primary),
                        strokeWidth: 3,
                      ),
                    ],
                  ),
                );
              }
              if (state is NewPostUploading) {
                return Container(
                  height: 60,
                  color: theme.colorScheme.background,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          getLoaderThumbnail(state.thumbnailMedia),
                          kHorizontalPaddingMedium,
                          Text(
                            'Posting',
                            style: theme.textTheme.bodyMedium,
                          )
                        ],
                      ),
                      StreamBuilder(
                          initialData: 0,
                          stream: state.progress,
                          builder: (context, snapshot) {
                            return SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  value: (snapshot.data == null ||
                                          snapshot.data == 0.0
                                      ? null
                                      : snapshot.data?.toDouble()),
                                  valueColor: AlwaysStoppedAnimation(
                                      theme.colorScheme.primary),
                                  strokeWidth: 3,
                                ));
                          }),
                    ],
                  ),
                );
              } else {
                return const SizedBox.shrink();
              }
            },
          ),
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: ValueListenableBuilder(
                    valueListenable: rebuildPostWidget,
                    builder: (context, _, __) {
                      return PagedListView<int, PostViewModel>(
                        pagingController: widget.feedRoomPagingController,
                        scrollController: _controller,
                        padding: EdgeInsets.zero,
                        builderDelegate:
                            PagedChildBuilderDelegate<PostViewModel>(
                          noItemsFoundIndicatorBuilder: (context) {
                            if (widget.universalFeedBloc.state
                                    is UniversalFeedLoaded &&
                                (widget.universalFeedBloc.state
                                        as UniversalFeedLoaded)
                                    .topics
                                    .isNotEmpty) {
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    LMTextView(
                                        text:
                                            "Looks like there are no posts for this topic yet.",
                                        textStyle: theme.textTheme.labelMedium),
                                    const SizedBox(height: 16),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        LMTextButton(
                                          borderRadius: 48,
                                          height: 40,
                                          border: Border.all(
                                            color: theme.colorScheme.primary,
                                            width: 2,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 8, horizontal: 12),
                                          text: LMTextView(
                                              text: "Change Filter",
                                              textAlign: TextAlign.center,
                                              textStyle: theme
                                                  .textTheme.labelMedium!
                                                  .copyWith(
                                                      color: theme.colorScheme
                                                          .primary)),
                                          onTap: () =>
                                              widget.openTopicBottomSheet(),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            }
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  LMIcon(
                                    type: LMIconType.icon,
                                    icon: Icons.post_add,
                                    size: 48,
                                    color: theme.colorScheme.onPrimary,
                                  ),
                                  const SizedBox(height: 12),
                                  Center(
                                    child: Expanded(
                                      child: LMTextView(
                                        text:
                                            'No posts to show, Be the first one to post here',
                                        textStyle: theme.textTheme.labelMedium,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 28),
                                ],
                              ),
                            );
                          },
                          itemBuilder: (context, item, index) {
                            if (widget.feedResponse.users[item.userId] ==
                                null) {
                              return const SizedBox();
                            }
                            return Column(
                              children: [
                                const SizedBox(height: 2),
                                NovaPostWidget(
                                  post: item,
                                  topics: widget.feedResponse.topics,
                                  user: widget.feedResponse.users[item.userId]!,
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
                                                  Navigator.of(childContext)
                                                      .pop();
                                                  final res = await locator<
                                                          LikeMindsService>()
                                                      .getMemberState();
                                                  //Implement delete post analytics tracking
                                                  LMAnalytics.get().track(
                                                    AnalyticsKeys.postDeleted,
                                                    {
                                                      "user_state":
                                                          res.state == 1
                                                              ? "CM"
                                                              : "member",
                                                      "post_id": item.id,
                                                      "user_id": item.userId,
                                                    },
                                                  );
                                                  newPostBloc.add(
                                                    DeletePost(
                                                      postId: item.id,
                                                      reason:
                                                          reason ?? 'Self Post',
                                                    ),
                                                  );
                                                },
                                                actionText: 'Yes, delete',
                                              ));
                                    } else if (id == postPinId ||
                                        id == postUnpinId) {
                                      try {
                                        String? postType = getPostType(item
                                                .attachments
                                                ?.first
                                                .attachmentType ??
                                            0);
                                        if (item.isPinned) {
                                          LMAnalytics.get().track(
                                              AnalyticsKeys.postUnpinned, {
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
                                      } catch (_) {}
                                      newPostBloc.add(TogglePinPost(
                                          postId: item.id,
                                          isPinned: !item.isPinned));
                                    } else if (id == postEditId) {
                                      try {
                                        String? postType;
                                        postType = getPostType(item.attachments
                                                ?.first.attachmentType ??
                                            0);
                                        LMAnalytics.get().track(
                                          AnalyticsKeys.postEdited,
                                          {
                                            "created_by_id": item.userId,
                                            "post_id": item.id,
                                            "post_type": postType,
                                          },
                                        );
                                      } catch (err) {
                                        debugPrint(err.toString());
                                      }
                                      List<TopicUI> postTopics = [];

                                      if (item.topics.isNotEmpty &&
                                          widget.feedResponse.topics
                                              .containsKey(item.topics.first)) {
                                        postTopics.add(TopicUI.fromTopic(widget
                                            .feedResponse
                                            .topics[item.topics.first]!));
                                      }

                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (context) => EditPostScreen(
                                            postId: item.id,
                                            selectedTopics: postTopics,
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
                                    if (isDeleted) {
                                      List<PostViewModel>? feedRoomItemList =
                                          widget.feedRoomPagingController
                                              .itemList;
                                      feedRoomItemList?.removeAt(index);
                                      widget.feedRoomPagingController.itemList =
                                          feedRoomItemList;
                                      rebuildPostWidget.value =
                                          !rebuildPostWidget.value;
                                    }
                                  },
                                ),
                              ],
                            );
                          },
                          firstPageProgressIndicatorBuilder: (context) =>
                              const LMFeedShimmer(),
                          newPageProgressIndicatorBuilder: (context) =>
                              const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Center(child: CircularProgressIndicator()),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          )
        ],
      ),
      floatingActionButtonAnimator: FloatingActionButtonAnimator.scaling,
      floatingActionButton: ValueListenableBuilder(
          valueListenable: rebuildNewPostFAB,
          builder: (context, value, __) {
            return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: value ? 140 : 56,
                child: !value
                    ? LMIconButton(
                        containerSize: 56,
                        padding: const EdgeInsets.all(12),
                        borderRadius: 28,
                        backgroundColor:
                            right ? theme.colorScheme.primary : kGrey3Color,
                        icon: LMIcon(
                          type: LMIconType.icon,
                          icon: Icons.add,
                          fit: BoxFit.cover,
                          size: 24,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                        onTap: right
                            ? (_) {
                                if (!postUploading.value) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const NewPostScreen(),
                                    ),
                                  );
                                } else {
                                  toast(
                                    'A post is already uploading.',
                                    duration: Toast.LENGTH_LONG,
                                  );
                                }
                              }
                            : (value) => toast(
                                "You do not have permission to create a post"),
                      )
                    : AnimatedContainer(
                        duration: const Duration(milliseconds: 500),
                        width: value ? 140 : 56,
                        clipBehavior: Clip.hardEdge,
                        decoration: const BoxDecoration(),
                        child: LMTextButton(
                          height: 56,
                          width: 140,
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 20,
                          ),
                          borderRadius: 28,
                          backgroundColor:
                              right ? theme.colorScheme.primary : kGrey3Color,
                          placement: LMIconPlacement.start,
                          text: LMTextView(
                            text: "New Post",
                            textStyle: theme.textTheme.bodyMedium,
                            maxLines: 1,
                            overflow: TextOverflow.fade,
                          ),
                          margin: 5,
                          icon: LMIcon(
                            type: LMIconType.icon,
                            icon: Icons.add,
                            fit: BoxFit.cover,
                            size: 24,
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                          onTap: right
                              ? () {
                                  if (!postUploading.value) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const NewPostScreen(),
                                      ),
                                    );
                                  } else {
                                    toast(
                                      'A post is already uploading.',
                                      duration: Toast.LENGTH_LONG,
                                    );
                                  }
                                }
                              : () => toast(
                                  "You do not have permission to create a post"),
                        ),
                      ));
          }),
      // floatingActionButton: ValueListenableBuilder(
      //   valueListenable: rebuildPostWidget,
      //   builder: (context, _, __) {
      //     return widget.feedRoomPagingController.itemList == null ||
      //             widget.feedRoomPagingController.itemList!.isEmpty
      //         ? const SizedBox()
      //         : LMTextButton(
      //             height: 56,
      //             width: 140,
      //             padding: const EdgeInsets.symmetric(
      //               vertical: 12,
      //               horizontal: 20,
      //             ),
      //             borderRadius: 28,
      //             backgroundColor:
      //                 right ? theme.colorScheme.primary : kGrey3Color,
      //             placement: LMIconPlacement.start,
      //             text: LMTextView(
      //               text: "New Post",
      //               textStyle: theme.textTheme.bodyMedium,
      //             ),
      //             margin: 5,
      //             icon: LMIcon(
      //               type: LMIconType.icon,
      //               icon: Icons.add,
      //               fit: BoxFit.cover,
      //               size: 24,
      //               color: theme.colorScheme.onPrimary,
      //             ),
      //             onTap: right
      //                 ? () {
      //                     if (!postUploading.value) {
      //                       Navigator.push(
      //                         context,
      //                         MaterialPageRoute(
      //                           builder: (context) => const NewPostScreen(),
      //                         ),
      //                       );
      //                     } else {
      //                       toast(
      //                         'A post is already uploading.',
      //                         duration: Toast.LENGTH_LONG,
      //                       );
      //                     }
      //                   }
      //                 : () =>
      //                     toast("You do not have permission to create a post"),
      //           );
      //   },
      // ),
    );
  }
}
