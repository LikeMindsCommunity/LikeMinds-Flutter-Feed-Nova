import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:likeminds_feed/likeminds_feed.dart';
import 'package:likeminds_feed_nova_fl/likeminds_feed_nova_fl.dart';
import 'package:likeminds_feed_nova_fl/src/blocs/new_post/new_post_bloc.dart';
import 'package:likeminds_feed_nova_fl/src/models/post_view_model.dart';
import 'package:likeminds_feed_nova_fl/src/persistence/logger/logger.dart';
import 'package:likeminds_feed_nova_fl/src/services/bloc_service.dart';
import 'package:likeminds_feed_nova_fl/src/services/likeminds_service.dart';
import 'package:likeminds_feed_nova_fl/src/utils/post/post_action_id.dart';
import 'package:likeminds_feed_nova_fl/src/utils/post/post_utils.dart';
import 'package:likeminds_feed_nova_fl/src/views/post/edit_post_screen.dart';
import 'package:likeminds_feed_nova_fl/src/views/post_detail_screen.dart';
import 'package:likeminds_feed_nova_fl/src/views/report_screen.dart';
import 'package:likeminds_feed_nova_fl/src/widgets/delete_dialog.dart';
import 'package:likeminds_feed_nova_fl/src/widgets/post/post_widget.dart';
import 'package:likeminds_feed_ui_fl/likeminds_feed_ui_fl.dart';

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
  Map<String, User> users = {};
  Map<String, Topic> topics = {};
  Map<String, WidgetModel> widgets = {};
  int _pageFeed = 1;
  final PagingController<int, PostViewModel> _pagingController =
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
          await locator<LikeMindsService>().getUserFeed(userFeedRequest);
      updatePagingControllers(response);
    });
  }

  void refresh() => _pagingController.refresh();

  // This function updates the paging controller based on the state changes
  void updatePagingControllers(GetUserFeedResponse response) {
    if (response.success) {
      _pageFeed++;
      List<PostViewModel> listOfPosts =
          response.posts!.map((e) => PostViewModel.fromPost(post: e)).toList();
      if (listOfPosts.length < 10) {
        _pagingController.appendLastPage(listOfPosts);
      } else {
        _pagingController.appendPage(listOfPosts, _pageFeed);
      }
      if (response.topics != null) {
        topics.addAll(response.topics!);
      }
      if (response.users != null) {
        users.addAll(response.users!);
      }
      if (response.widgets != null) {
        widgets.addAll(response.widgets!);
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
    NewPostBloc newPostBloc = locator<BlocService>().newPostBlocProvider;
    return BlocListener(
      bloc: locator<BlocService>().newPostBlocProvider,
      listener: (context, state) {
        if (state is PostDeleted) {
          List<PostViewModel>? feedRoomItemList = _pagingController.itemList;
          feedRoomItemList?.removeWhere((item) => item.id == state.postId);
          _pagingController.itemList = feedRoomItemList;
          rebuildPostWidget.value = !rebuildPostWidget.value;
        }
        if (state is NewPostUploaded) {
          PostViewModel item = state.postData;

          int length = _pagingController.itemList?.length ?? 0;
          List<PostViewModel> feedRoomItemList =
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
          users.addAll(state.userData);
          topics.addAll(state.topics);
          widgets.addAll(state.widgets);
          _pagingController.itemList = feedRoomItemList;
          rebuildPostWidget.value = !rebuildPostWidget.value;
        }
        if (state is EditPostUploaded) {
          PostViewModel? item = state.postData;
          List<PostViewModel>? feedRoomItemList = _pagingController.itemList;
          int index = feedRoomItemList
                  ?.indexWhere((element) => element.id == item.id) ??
              -1;
          if (index != -1) {
            feedRoomItemList?[index] = item;
          }
          users.addAll(state.userData);
          topics.addAll(state.topics);
          widgets.addAll(state.widgets);
          rebuildPostWidget.value = !rebuildPostWidget.value;
        }

        if (state is PostUpdateState) {
          List<PostViewModel>? feedRoomItemList = _pagingController.itemList;
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
              builderDelegate: PagedChildBuilderDelegate<PostViewModel>(
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
                      NovaPostWidget(
                        post: item,
                        showMenu: true,
                        topics: topics,
                        showCompanyDetails: false,
                        widgets: widgets,
                        user: users[item.userId]!,
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
                                  item.attachments?.first.attachmentType ?? 0);
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
                              LMFeedLogger.instance
                                  .handleException(err.toString(), stacktrace);
                            }

                            newPostBloc.add(TogglePinPost(
                                postId: item.id, isPinned: !item.isPinned));
                          } else if (id == postEditId) {
                            try {
                              String? postType;
                              postType = getPostType(
                                  item.attachments?.first.attachmentType ?? 0);
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
                              LMFeedLogger.instance
                                  .handleException(err.toString(), stacktrace);
                            }
                            List<TopicUI> postTopics = [];

                            if (item.topics.isNotEmpty &&
                                topics.containsKey(item.topics.first)) {
                              postTopics.add(TopicUI.fromTopic(
                                  topics[item.topics.first]!));
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
                          if (isDeleted) {
                            List<PostViewModel>? feedRoomItemList =
                                _pagingController.itemList;
                            feedRoomItemList?.removeAt(index);
                            _pagingController.itemList = feedRoomItemList;
                            setState(() {});
                          }
                        },
                      ),
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
