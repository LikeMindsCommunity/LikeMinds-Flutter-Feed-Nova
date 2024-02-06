import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:likeminds_feed_flutter_core/likeminds_feed_core.dart';

class UserFeedWidget extends StatefulWidget {
  final String userId;

  const UserFeedWidget({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  State<UserFeedWidget> createState() => _UserFeedWidgetState();
}

class _UserFeedWidgetState extends State<UserFeedWidget> {
  static const int pageSize = 10;
  ValueNotifier<bool> rebuildPostWidget = ValueNotifier(false);
  Map<String, LMUserViewData> users = {};
  Map<String, LMTopicViewData> topics = {};
  Map<String, LMWidgetViewData> widgets = {};
  Map<String, Post> repostedPosts = {};

  int _pageFeed = 1;
  final PagingController<int, LMPostViewData> _pagingController =
      PagingController(firstPageKey: 1);

  @override
  void initState() {
    super.initState();
    addPaginationListener();
  }

  void addPaginationListener() {
    _pagingController.addPageRequestListener((pageKey) async {
      final userFeedRequest = (GetUserFeedRequestBuilder()
            ..page(pageKey)
            ..pageSize(pageSize)
            ..userId(widget.userId))
          .build();
      GetUserFeedResponse response =
          await LMFeedCore.instance.lmFeedClient.getUserFeed(userFeedRequest);
      updatePagingControllers(response);
    });
  }

  void refresh() => _pagingController.refresh();

  // This function updates the paging controller based on the state changes
  void updatePagingControllers(GetUserFeedResponse response) {
    if (response.success) {
      _pageFeed++;
      List<LMPostViewData> listOfPosts = response.posts!
          .map((e) => LMPostViewDataConvertor.fromPost(
              post: e,
              widgets: widgets.map((key, value) => MapEntry(
                  key, LMWidgetViewDataConvertor.toWidgetModel(value)))))
          .toList();
      if (listOfPosts.length < 10) {
        _pagingController.appendLastPage(listOfPosts);
      } else {
        _pagingController.appendPage(listOfPosts, _pageFeed);
      }
      if (response.topics != null) {
        topics.addAll(response.topics!.map((key, value) =>
            MapEntry(key, LMTopicViewDataConvertor.fromTopic(value))));
      }
      if (response.users != null) {
        users.addAll(response.users!.map((key, value) =>
            MapEntry(key, LMUserViewDataConvertor.fromUser(value))));
      }
      if (response.widgets != null) {
        widgets.addAll(response.widgets!.map((key, value) =>
            MapEntry(key, LMWidgetViewDataConvertor.fromWidgetModel(value))));
      }
      if (response.repostedPosts != null) {
        repostedPosts.addAll(response.repostedPosts!);
      }
    } else {
      _pagingController.appendLastPage([]);
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

  @override
  Widget build(BuildContext context) {
    LMFeedPostBloc newPostBloc = LMFeedPostBloc.instance;
    return BlocListener(
      bloc: newPostBloc,
      listener: (context, state) {
        if (state is LMFeedPostDeletedState) {
          List<LMPostViewData>? feedRoomItemList = _pagingController.itemList;
          feedRoomItemList?.removeWhere((item) => item.id == state.postId);
          _pagingController.itemList = feedRoomItemList;
          rebuildPostWidget.value = !rebuildPostWidget.value;
        }
        if (state is LMFeedPostUpdateState) {
          LMPostViewData item = state.post;

          int length = _pagingController.itemList?.length ?? 0;
          List<LMPostViewData> feedRoomItemList =
              _pagingController.itemList ?? [];
          for (int i = 0; i < feedRoomItemList.length; i++) {
            if (!feedRoomItemList[i].isPinned) {
              feedRoomItemList.insert(i, item);
              break;
            }
          }
          if (length == feedRoomItemList.length) {
            feedRoomItemList.add(item);
          }
          if (feedRoomItemList.isNotEmpty && feedRoomItemList.length > 10) {
            feedRoomItemList.removeLast();
          }
          // users.addAll(state.userData);
          // topics.addAll(state.topics);
          // widgets.addAll(state.widgets);
          // repostedPosts.addAll(state.repostedPosts);
          _pagingController.itemList = feedRoomItemList;
          rebuildPostWidget.value = !rebuildPostWidget.value;
        }
        if (state is LMFeedEditPostUploadedState) {
          LMPostViewData? item = state.postData;
          List<LMPostViewData>? feedRoomItemList = _pagingController.itemList;
          int index = feedRoomItemList
                  ?.indexWhere((element) => element.id == item.id) ??
              -1;
          if (index != -1) {
            feedRoomItemList?[index] = item;
          }
          // users.addAll(state.userData);
          // topics.addAll(state.topics);
          // widgets.addAll(state.widgets);
          // repostedPosts.addAll(state.repostedPosts);
          rebuildPostWidget.value = !rebuildPostWidget.value;
        }

        if (state is LMFeedPostUpdateState) {
          List<LMPostViewData>? feedRoomItemList = _pagingController.itemList;
          int index = feedRoomItemList
                  ?.indexWhere((element) => element.id == state.post.id) ??
              -1;
          if (index != -1) {
            feedRoomItemList?[index] = state.post;
          }
          rebuildPostWidget.value = !rebuildPostWidget.value;
        }
      },
      child: ValueListenableBuilder(
          valueListenable: rebuildPostWidget,
          builder: (context, _, __) {
            return PagedSliverList(
              pagingController: _pagingController,
              builderDelegate: PagedChildBuilderDelegate<LMPostViewData>(
                noItemsFoundIndicatorBuilder: (context) {
                  return const SizedBox();
                },
                itemBuilder: (context, item, index) {
                  if (!users.containsKey(item.userId)) {
                    return const SizedBox();
                  }
                  return Column(
                    children: [
                      const SizedBox(height: 2),
                      LMFeedPostWidget(
                          post: item,
                          user: users[item.userId]!,
                          isFeed: true,
                          topics: topics),
                      // NovaPostWidget(
                      //   post: item,
                      //   topics: topics,
                      //   users: users,
                      //   showCompanyDetails: false,
                      //   widgets: widgets,
                      //   repostedPost: repostedPosts,
                      //   user: users[item.userId]!,
                      //   onMenuTap: (int id) {
                      //     if (id == postDeleteId) {
                      //       showDialog(
                      //           context: context,
                      //           builder: (childContext) =>
                      //               deleteConfirmationDialog(
                      //                 childContext,
                      //                 title: 'Delete Post?',
                      //                 userId: item.userId,
                      //                 content:
                      //                     'Are you sure you want to permanently remove this post from Nova?',
                      //                 action: (String reason) async {
                      //                   Navigator.of(childContext).pop();
                      //                   final res = await LMFeedCore
                      //                       .instance.lmFeedClient
                      //                       .getMemberState();
                      //                   //Implement delete post analytics tracking
                      //                   LMAnalytics.get().track(
                      //                     AnalyticsKeys.postDeleted,
                      //                     {
                      //                       "user_state": res.state == 1
                      //                           ? "CM"
                      //                           : "member",
                      //                       "post_id": item.id,
                      //                       "user_id": item.userId,
                      //                     },
                      //                   );
                      //                   newPostBloc.add(
                      //                     LMFeedDeletePostEvent(
                      //                       postId: item.id,
                      //                       // isRepost: item.isRepost,
                      //                       reason: reason ?? 'Self Post',
                      //                     ),
                      //                   );
                      //                 },
                      //                 actionText: 'Yes, delete',
                      //               ));
                      //     } else if (id == postPinId || id == postUnpinId) {
                      //       try {
                      //         String? postType = getPostType(
                      //             item.attachments?.first.attachmentType ?? 0);
                      //         if (item.isPinned) {
                      //           LMAnalytics.get()
                      //               .track(AnalyticsKeys.postUnpinned, {
                      //             "created_by_id": item.userId,
                      //             "post_id": item.id,
                      //             "post_type": postType,
                      //           });
                      //         } else {
                      //           LMAnalytics.get()
                      //               .track(AnalyticsKeys.postPinned, {
                      //             "created_by_id": item.userId,
                      //             "post_id": item.id,
                      //             "post_type": postType,
                      //           });
                      //         }
                      //       } on Exception catch (err, stacktrace) {
                      //         LMFeedLogger.instance
                      //             .handleException(err, stacktrace);
                      //       }

                      //       newPostBloc.add(LMFeedTogglePinPostEvent(
                      //           postId: item.id, isPinned: !item.isPinned));
                      //     } else if (id == postEditId) {
                      //       try {
                      //         String? postType;
                      //         postType = getPostType(
                      //             item.attachments?.first.attachmentType ?? 0);
                      //         LMAnalytics.get().track(
                      //           AnalyticsKeys.postEdited,
                      //           {
                      //             "created_by_id": item.userId,
                      //             "post_id": item.id,
                      //             "post_type": postType,
                      //           },
                      //         );
                      //       } on Exception catch (err, stacktrace) {
                      //         debugPrint(err.toString());
                      //         LMFeedLogger.instance
                      //             .handleException(err, stacktrace);
                      //       }
                      //       List<TopicUI> postTopics = [];

                      //       if (item.topics.isNotEmpty &&
                      //           topics.containsKey(item.topics.first)) {
                      //         postTopics.add(TopicUI.fromTopic(
                      //             topics[item.topics.first]!));
                      //       }

                      //       Navigator.of(context).push(
                      //         MaterialPageRoute(
                      //           builder: (context) => EditPostScreen(
                      //             postId: item.id,
                      //             selectedTopics: postTopics,
                      //           ),
                      //         ),
                      //       );
                      //     } else if (id == postReportId) {
                      //       Navigator.of(context).push(
                      //         MaterialPageRoute(
                      //           builder: (context) => ReportScreen(
                      //             entityCreatorId: item.userId,
                      //             entityId: item.id,
                      //             entityType: postReportEntityType,
                      //           ),
                      //         ),
                      //       );
                      //     }
                      //   },
                      //   onTap: () {
                      //     Navigator.push(
                      //       context,
                      //       MaterialPageRoute(
                      //         builder: (context) => PostDetailScreen(
                      //           postId: item.id,
                      //         ),
                      //       ),
                      //     );
                      //   },
                      //   isFeed: true,
                      //   refresh: (bool isDeleted) async {
                      //     if (isDeleted) {
                      //       List<PostViewModel>? feedRoomItemList =
                      //           _pagingController.itemList;
                      //       feedRoomItemList?.removeAt(index);
                      //       _pagingController.itemList = feedRoomItemList;
                      //       setState(() {});
                      //     }
                      //   },
                      // ),
                    ],
                  );
                },
                firstPageProgressIndicatorBuilder: (context) =>
                    const LMFeedShimmer(),
                newPageProgressIndicatorBuilder: (context) => const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
            );
          }),
    );
  }
}
