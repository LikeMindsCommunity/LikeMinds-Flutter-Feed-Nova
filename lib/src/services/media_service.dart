import 'dart:io';
import 'package:flutter/material.dart';
import 'package:likeminds_feed_nova_fl/src/persistence/logger/logger.dart';
import 'package:likeminds_feed_nova_fl/src/utils/credentials/credentials.dart';
import 'package:path/path.dart';

import 'package:simple_s3/simple_s3.dart';

class MediaService {
  late final String _bucketName;
  late final String _poolId;
  final _region = AWSRegions.apSouth1;
  final SimpleS3 _s3Client = SimpleS3();

  MediaService(bool isProd) {
    _bucketName = isProd ? CredsProd.bucketName : CredsDev.bucketName;
    _poolId = isProd ? CredsProd.poolId : CredsDev.poolId;
  }

  Future<String?> uploadFile(File file, String userUniqueId) async {
    try {
      String fileName = basenameWithoutExtension(file.path);
      String currTimeInMilli = DateTime.now().millisecondsSinceEpoch.toString();

      String result = await _s3Client.uploadFile(
        file,
        _bucketName,
        _poolId,
        _region,
        s3FolderPath: "files/post/$userUniqueId/$fileName-$currTimeInMilli",
      );
      return result;
    } on SimpleS3Errors catch (err, stacktrace) {
      debugPrint(err.name);
      debugPrint(err.index.toString());
      LMFeedLogger.instance.handleException(err.toString(), stacktrace);
      return null;
    } on Exception catch (err, stacktrace) {
      LMFeedLogger.instance.handleException(err.toString(), stacktrace);
      return null;
    }
  }
}
