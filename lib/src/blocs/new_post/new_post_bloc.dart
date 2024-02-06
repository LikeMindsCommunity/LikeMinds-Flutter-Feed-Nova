import 'dart:async';
import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:likeminds_feed/likeminds_feed.dart';
import 'package:likeminds_feed_nova_fl/src/models/post/post_view_model.dart';
import 'package:likeminds_feed_nova_fl/src/services/likeminds_service.dart';
import 'package:likeminds_feed_nova_fl/src/services/service_locator.dart';
import 'package:likeminds_feed_nova_fl/src/utils/analytics/analytics.dart';
import 'package:likeminds_feed_nova_fl/src/utils/local_preference/user_local_preference.dart';
import 'package:likeminds_feed_ui_fl/likeminds_feed_ui_fl.dart';
import 'package:overlay_support/overlay_support.dart';

part 'new_post_event.dart';

part 'new_post_state.dart';

class NewPostBloc extends Bloc<NewPostEvents, NewPostState> {
  NewPostBloc() : super(NewPostInitiate()) {
    on<CreateNewPost>(mapNewPostHandler);
    on<EditPost>(mapEditPostHandler);
    on<DeletePost>(mapDeletePostHandler);
    on<UpdatePost>(mapUpdatePostHandler);
    on<TogglePinPost>(mapTogglePinPostHandler);
  }

  mapNewPostHandler(CreateNewPost event, Emitter<NewPostState> emit) async {
    try {
      List<AttachmentPostViewData>? postMedia = event.postMedia;
      User user = UserLocalPreference.instance.fetchUserData();
      int imageCount = 0;
      int videoCount = 0;
      int documentCount = 0;
      int linkCount = 0;
      List<Attachment> attachments = [];
      int index = 0;

      StreamController<double> progress = StreamController<double>.broadcast();
      progress.add(0);

      // Upload post media to s3 and add links as Attachments
      if (postMedia != null && postMedia.isNotEmpty) {
        emit(
          NewPostUploading(
            progress: progress.stream,
            thumbnailMedia: postMedia.isEmpty
                ? null
                : (postMedia[0].mediaType == MediaType.link ||
                        postMedia[0].mediaType == MediaType.widget ||
                        postMedia[0].mediaType == MediaType.post)
                    ? null
                    : postMedia[0],
          ),
        );
        for (final media in postMedia) {
          if (media.mediaType == MediaType.post) {
            attachments.add(
              Attachment(
                attachmentType: 8,
                attachmentMeta: AttachmentMeta(
                  entityId: event.postMedia!.first.postId,
                ),
              ),
            );
          } else if (media.mediaType == MediaType.widget) {
            attachments.add(
              Attachment(
                attachmentType: 5,
                attachmentMeta: AttachmentMeta(meta: media.widgetsMeta),
              ),
            );
          } else if (media.mediaType == MediaType.link) {
            attachments.add(
              Attachment(
                attachmentType: 4,
                attachmentMeta: AttachmentMeta(
                  url: media.ogTags!.url,
                  ogTags: OgTags(
                    description: media.ogTags!.description,
                    image: media.ogTags!.image,
                    title: media.ogTags!.title,
                    url: media.ogTags!.url,
                  ),
                ),
              ),
            );
            linkCount = 1;
          } else {
            File mediaFile = media.mediaFile!;
            index += 1;
            final String? response = await locator<LikeMindsService>()
                .uploadFile(mediaFile, user.userUniqueId);
            if (response != null) {
              attachments.add(
                Attachment(
                  attachmentType: media.mapMediaTypeToInt(),
                  attachmentMeta: AttachmentMeta(
                      url: response,
                      size: media.mediaType == MediaType.document
                          ? media.size
                          : null,
                      format: media.mediaType == MediaType.document
                          ? media.format
                          : null,
                      duration: media.mediaType == MediaType.video
                          ? media.duration
                          : null),
                ),
              );
              progress.add(index / postMedia.length);
            } else {
              throw ('Error uploading file');
            }
          }
        }
        // For counting the no of attachments
        for (final attachment in attachments) {
          if (attachment.attachmentType == 1) {
            imageCount++;
          } else if (attachment.attachmentType == 2) {
            videoCount++;
          } else if (attachment.attachmentType == 3) {
            documentCount++;
          }
        }
      } else {
        emit(
          NewPostUploading(
            progress: progress.stream,
          ),
        );
      }
      List<Topic> postTopics =
          event.selectedTopics.map((e) => e.toTopic()).toList();
      final addPostRequestBuilder = AddPostRequestBuilder()
        ..text(event.postText)
        ..attachments(attachments)
        ..topics(postTopics);
      if (checkIfPostIsRepost(attachments)) {
        addPostRequestBuilder.isRepost(true);
      }
      final AddPostRequest request = addPostRequestBuilder.build();

      final AddPostResponse response =
          await locator<LikeMindsService>().addPost(request);

      if (response.success) {
        LMAnalytics.get().track(
          AnalyticsKeys.postCreationCompleted,
          {
            "user_tagged": "no",
            "link_attached": linkCount == 0
                ? "no"
                : {"yes": attachments.first.attachmentMeta.ogTags?.url ?? ""},
            "image_attached": imageCount == 0
                ? "no"
                : {
                    "yes": {"image_count": imageCount},
                  },
            "video_attached": videoCount == 0
                ? "no"
                : {
                    "yes": {"video_count": videoCount},
                  },
            "document_attached": documentCount == 0
                ? "no"
                : {
                    "yes": {"document_count": documentCount},
                  },
          },
        );
        emit(
          NewPostUploaded(
            postData: PostViewModel.fromPost(post: response.post!),
            userData: response.user!,
            widgets: response.widgets ?? <String, WidgetModel>{},
            topics: response.topics ?? <String, Topic>{},
            repostedPosts: response.repostedPosts ?? <String, Post>{},
          ),
        );
      } else {
        emit(NewPostError(message: response.errorMessage!));
      }
    } on Exception catch (err, stacktrace) {
      emit(const NewPostError(message: 'An error occurred'));
      LMFeedLogger.instance.handleException(err, stacktrace);
      debugPrint(err.toString());
    }
  }

  mapEditPostHandler(EditPost event, Emitter<NewPostState> emit) async {
    try {
      emit(EditPostUploading());
      List<Attachment>? attachments = event.attachments;
      String postText = event.postText;

      bool isRepost = false;
      if (attachments != null && attachments.isNotEmpty) {
        isRepost = checkIfPostIsRepost(attachments);
      }
      var response =
          await locator<LikeMindsService>().editPost((EditPostRequestBuilder()
                ..attachments(attachments ?? [])
                ..postId(event.postId)
                ..postText(postText)
                ..isRepost(isRepost))
              .build());

      if (response.success) {
        emit(
          EditPostUploaded(
            postData: PostViewModel.fromPost(post: response.post!),
            userData: response.user!,
            widgets: response.widgets ?? <String, WidgetModel>{},
            topics: response.topics ?? <String, Topic>{},
            repostedPosts: response.repostedPosts ?? <String, Post>{},
          ),
        );
      } else {
        emit(
          NewPostError(
            message: response.errorMessage!,
          ),
        );
      }
    } on Exception catch (err, stacktrace) {
      emit(
        const NewPostError(
          message: 'An error occurred while saving the post',
        ),
      );
      LMFeedLogger.instance.handleException(err, stacktrace);
    }
  }

  mapDeletePostHandler(DeletePost event, Emitter<NewPostState> emit) async {
    final response = await locator<LikeMindsService>().deletePost(
      (DeletePostRequestBuilder()
            ..postId(event.postId)
            ..deleteReason(event.reason)
            ..isRepost(event.isRepost))
          .build(),
    );

    if (response.success) {
      toast(
        'Post Deleted',
        duration: Toast.LENGTH_LONG,
      );
      emit(PostDeleted(postId: event.postId));
    } else {
      toast(
        response.errorMessage ?? 'An error occurred',
        duration: Toast.LENGTH_LONG,
      );
      emit(PostDeletionError(
          message: response.errorMessage ?? 'An error occurred'));
    }
  }

  mapUpdatePostHandler(UpdatePost event, Emitter<NewPostState> emit) async {
    emit(
      PostUpdateState(post: event.post),
    );
  }

  mapTogglePinPostHandler(
      TogglePinPost event, Emitter<NewPostState> emit) async {
    PinPostRequest request =
        (PinPostRequestBuilder()..postId(event.postId)).build();

    PinPostResponse response =
        await locator<LikeMindsService>().pinPost(request);

    if (response.success) {
      toast(event.isPinned ? "Post pinned" : "Post unpinned",
          duration: Toast.LENGTH_LONG);
      emit(PostPinnedState(isPinned: event.isPinned, postId: event.postId));
    } else {
      emit(PostPinError(
          message: response.errorMessage ?? "An error occurred",
          isPinned: !event.isPinned,
          postId: event.postId));
    }
  }

  bool checkIfPostIsRepost(List<Attachment> attachments) {
    for (Attachment attachment in attachments) {
      if (attachment.attachmentType == 8) {
        return true;
      }
    }
    return false;
  }
}
