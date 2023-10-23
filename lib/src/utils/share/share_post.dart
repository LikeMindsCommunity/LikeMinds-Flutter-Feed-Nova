import 'package:flutter/material.dart';
import 'package:likeminds_feed/likeminds_feed.dart';
import 'package:likeminds_feed_nova_fl/likeminds_feed_nova_fl.dart';
import 'package:likeminds_feed_nova_fl/src/services/likeminds_service.dart';
import 'package:likeminds_feed_nova_fl/src/services/navigation_service.dart';
import 'package:likeminds_feed_nova_fl/src/utils/credentials/credentials.dart';
import 'package:likeminds_feed_nova_fl/src/views/post_detail_screen.dart';
import 'package:share_plus/share_plus.dart';
part 'deep_link_request.dart';
part 'deep_link_response.dart';

class SharePost {
  // TODO NOVA: Add domain to your application
  String domain = 'feednova://www.feednova.com';

  // below function creates a link from domain and post id
  String createLink(String postId) {
    int length = domain.length;
    if (domain[length - 1] == '/') {
      return "${domain}post?post_id=$postId";
    } else {
      return "$domain/post?post_id=$postId";
    }
  }

  // Below functions takes the user outside of the application
  // using the domain provided at the time of initialization
  // TODO NOVA: Add prefix text, image as per your requirements
  void sharePost(String postId) {
    String postUrl = createLink(postId);
    Share.share(postUrl);
  }

  // Extracts the post id from the link
  String getFirstPathSegment(String url) {
    final uri = Uri.parse(url);
    final pathSegments = uri.pathSegments;
    if (pathSegments.isNotEmpty) {
      return pathSegments.first;
    } else {
      return '';
    }
  }

  Future<DeepLinkResponse> handlePostDeepLink(DeepLinkRequest request) async {
    List secondPathSegment = request.link.split('post_id=');
    if (secondPathSegment.length > 1 && secondPathSegment[1] != null) {
      String postId = secondPathSegment[1];
      setupLMFeed(request.callback, request.apiKey);
      await locator<LikeMindsService>()
          .initiateUser((InitiateUserRequestBuilder()
                ..apiKey(request.apiKey)
                ..userId(request.userUniqueId)
                ..imageUrl(request.imageURL ?? '')
                ..userName(request.userName))
              .build());
      if (!locator<NavigationService>().checkNullState()) {
        locator<NavigationService>().navigatorKey.currentState!.push(
              MaterialPageRoute(
                builder: (context) => PostDetailScreen(
                  postId: postId,
                ),
              ),
            );
      }

      return DeepLinkResponse(
        success: true,
        postId: postId,
      );
    } else {
      return DeepLinkResponse(
        success: false,
        errorMessage: 'URI not supported',
      );
    }
  }

  // Checks if the URL provided is correct or not
  // proceeds with the flow if the given url is correct
  Future<DeepLinkResponse> parseDeepLink(DeepLinkRequest request) async {
    if (Uri.parse(request.link).isAbsolute) {
      final firstPathSegment = getFirstPathSegment(request.link);
      if (firstPathSegment == "post") {
        return handlePostDeepLink(request);
      }
      return DeepLinkResponse(
          success: false, errorMessage: 'URI not supported');
    } else {
      return DeepLinkResponse(
        success: false,
        errorMessage: 'URI not supported',
      );
    }
  }
}
