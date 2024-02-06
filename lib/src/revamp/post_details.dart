import 'package:flutter/material.dart';
import 'package:likeminds_feed_flutter_core/likeminds_feed_core.dart';
import 'package:likeminds_feed_nova_fl/src/revamp/builder/component/comment_builder.dart';

class LMNovaPostDetailScreen extends StatefulWidget {
  const LMNovaPostDetailScreen({
    super.key,
    required this.postId,
    this.postBuilder,
  });
  final String postId;
  final LMFeedPostWidgetBuilder? postBuilder;

  @override
  State<LMNovaPostDetailScreen> createState() => _LMNovaPostDetailScreenState();
}

class _LMNovaPostDetailScreenState extends State<LMNovaPostDetailScreen> {
  @override
  Widget build(BuildContext context) {
    return LMFeedPostDetailScreen(
      postId: widget.postId,
      postBuilder: widget.postBuilder,
      commentBuilder: novaCommentBuilder,
      commentSeparatorBuilder: (context) {
        return const SizedBox(
            // height: 12,
            );
      },
      
      // bottomTextFieldBuilder: (context, data) {
      //   return Siz
      // },
      // bottomTextFieldBuilder: (context, postViewData) {
        
      // },
    );
  }
}
