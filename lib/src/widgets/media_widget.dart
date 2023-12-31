import 'package:flutter/material.dart';
import 'package:likeminds_feed/likeminds_feed.dart';
import 'package:likeminds_feed_nova_fl/likeminds_feed_nova_fl.dart';
import 'package:likeminds_feed_nova_fl/src/utils/constants/assets_constants.dart';
import 'package:likeminds_feed_ui_fl/likeminds_feed_ui_fl.dart';
import 'package:url_launcher/url_launcher.dart';

class SSPostMedia extends StatefulWidget {
  const SSPostMedia({super.key, required this.attachments});

  final List<Attachment> attachments;

  @override
  State<SSPostMedia> createState() => _SSPostMediaState();
}

class _SSPostMediaState extends State<SSPostMedia> {
  late List<Attachment> attachments;
  late Size screenSize;

  @override
  void initState() {
    super.initState();
    attachments = widget.attachments;
  }

  @override
  Widget build(BuildContext context) {
    screenSize = MediaQuery.of(context).size;
    // attachments = InheritedPostProvider.of(context)?.post.attachments ?? [];
    if (attachments.first.attachmentType == 3) {
      /// If the attachment is a document, we need to call the method 'getDocumentList'
      return getPostDocuments();
      // } else if (attachments.first.attachmentType == 4) {
      // return LMLinkPreview(attachment: attachments[0]);
    } else {
      return LMCarousel(
        attachments: attachments,
        borderRadius: 18,
        activeIndicator: Container(
          width: 12.0,
          height: 8.0,
          margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 2.0),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: ColorTheme.novaTheme.colorScheme.primary,
          ),
        ),
        inactiveIndicator: Container(
          width: 8.0,
          height: 8.0,
          margin: const EdgeInsets.symmetric(vertical: 7.0, horizontal: 2.0),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: ColorTheme.novaTheme.colorScheme.inversePrimary,
          ),
        ),
      );
    }
  }

  Widget getPostDocuments() {
    List<Widget> documents;
    bool isCollapsed = true;

    documents = attachments
        .map(
          (e) => LMDocument(
            onTap: () {
              Uri fileUrl = Uri.parse(e.attachmentMeta.url!);
              launchUrl(fileUrl, mode: LaunchMode.platformDefault);
            },
            documentIcon: Container(
              width: 48,
              height: 48,
              decoration: ShapeDecoration(
                color: ColorTheme.novaTheme.colorScheme.primaryContainer,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4)),
              ),
              child: Center(
                child: LMTextView(
                  text: 'PDF',
                  textStyle: ColorTheme.novaTheme.textTheme.titleLarge!
                      .copyWith(fontSize: 18),
                ),
              ),
            ),
            showBorder: false,
            backgroundColor: ColorTheme.novaTheme.colorScheme.surface,
            size: PostHelper.getFileSizeString(bytes: e.attachmentMeta.size!),
            documentUrl: e.attachmentMeta.url,
            type: e.attachmentMeta.format!,
          ),
        )
        .toList();

    return Align(
      alignment: Alignment.center,
      child: SizedBox(
        width: screenSize.width - 32,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: documents.length > 3 && isCollapsed
                  ? documents.sublist(0, 3)
                  : documents,
            ),
            documents.length > 3 && isCollapsed
                ? GestureDetector(
                    onTap: () => setState(() {
                          isCollapsed = false;
                        }),
                    child: LMTextView(
                      text: '+ ${documents.length - 3} more',
                      textStyle: TextStyle(
                        color: ColorTheme.novaTheme.colorScheme.secondary,
                        fontFamily: 'Gantari',
                      ),
                    ))
                : const SizedBox()
          ],
        ),
      ),
    );
  }
}
