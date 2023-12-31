// ignore_for_file: public_member_api_docs, sort_constructors_first
// import 'package:likeminds_feed/src/models/feed/post.dart';

import 'package:likeminds_feed/likeminds_feed.dart';

class PostViewModel {
  final String id;
  String text;
  List<String> topics;
  List<Attachment>? attachments;
  final int communityId;
  bool isPinned;
  final String userId;
  int likeCount;
  int commentCount;
  bool isSaved;
  bool isLiked;
  List<PopupMenuItemModel> menuItems;
  final DateTime createdAt;
  DateTime updatedAt;
  bool isEdited;
  PostViewModel({
    required this.id,
    required this.text,
    required this.attachments,
    required this.communityId,
    required this.isPinned,
    required this.userId,
    required this.likeCount,
    required this.isSaved,
    required this.topics,
    required this.menuItems,
    required this.createdAt,
    required this.updatedAt,
    required this.isLiked,
    required this.commentCount,
    required this.isEdited,
  });

  factory PostViewModel.fromPost({required Post post}) {
    return PostViewModel(
      id: post.id,
      isEdited: post.isEdited,
      text: post.text,
      attachments: post.attachments,
      communityId: post.communityId,
      isPinned: post.isPinned,
      topics: post.topics ?? [],
      userId: post.userId,
      likeCount: post.likeCount,
      commentCount: post.commentCount,
      isSaved: post.isSaved,
      isLiked: post.isLiked,
      menuItems: post.menuItems,
      createdAt: post.createdAt,
      updatedAt: post.updatedAt,
    );
  }

  Post toPost() {
    return Post(
      id: id,
      text: text,
      topics: topics,
      isEdited: isEdited,
      attachments: attachments,
      communityId: communityId,
      isPinned: isPinned,
      userId: userId,
      likeCount: likeCount,
      isSaved: isSaved,
      isLiked: isLiked,
      commentCount: commentCount,
      menuItems: menuItems,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

PostViewModel getEmptyPostViewModel() {
  return PostViewModel(
      id: '-9999',
      text: 'Custom Widget',
      attachments: null,
      communityId: -9999,
      isPinned: false,
      userId: '-9999',
      likeCount: 0,
      isSaved: false,
      topics: [],
      menuItems: [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isLiked: false,
      commentCount: 0,
      isEdited: false);
}
