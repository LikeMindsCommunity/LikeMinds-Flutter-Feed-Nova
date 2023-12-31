import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:likeminds_feed/likeminds_feed.dart';
import 'package:likeminds_feed_nova_fl/likeminds_feed_nova_fl.dart';
import 'package:likeminds_feed_nova_fl/src/services/likeminds_service.dart';
import 'package:likeminds_feed_nova_fl/src/utils/post/post_action_id.dart';
import 'package:likeminds_feed_ui_fl/likeminds_feed_ui_fl.dart';
import 'package:overlay_support/overlay_support.dart';

class ReportScreen extends StatefulWidget {
  final String entityId; // post, comment, reply id
  final String entityCreatorId;
  final int entityType;

  const ReportScreen({
    Key? key,
    required this.entityId,
    required this.entityCreatorId,
    required this.entityType,
  }) : super(key: key);

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  Future<GetDeleteReasonResponse>? getReportTagsFuture;
  TextEditingController reportReasonController = TextEditingController();
  Set<int> selectedTags = {};
  DeleteReason? deleteReason;

  @override
  void initState() {
    GetDeleteReasonRequest request = (GetDeleteReasonRequestBuilder()
          ..type(postCommentReplyReportTypeId))
        .build();
    super.initState();
    getReportTagsFuture = locator<LikeMindsService>().getReportTags(request);
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    reportReasonController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ThemeData theme = ColorTheme.novaTheme;
    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.background,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Report',
          style: theme.textTheme.titleLarge!.copyWith(fontSize: 22),
        ),
        leading: LMIconButton(
          icon: LMIcon(
            type: LMIconType.icon,
            size: 24,
            icon: CupertinoIcons.xmark,
            color: theme.colorScheme.onPrimaryContainer,
          ),
          onTap: (value) {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: <Widget>[
                    kVerticalPaddingLarge,
                    kVerticalPaddingLarge,
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: LMTextView(
                        text:
                            'Thank you for looking out for yourself and your fellow Nova users by reporting what violates the rules. Let us know what’s happening, and we’ll look into it.',
                        textStyle: theme.textTheme.labelMedium,
                        overflow: TextOverflow.visible,
                      ),
                    ),
                    kVerticalPaddingLarge,
                    kVerticalPaddingMedium,
                    FutureBuilder<GetDeleteReasonResponse>(
                        future: getReportTagsFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return CircularProgressIndicator(
                              color: ColorTheme.novaTheme.primaryColor,
                            );
                          } else if (snapshot.connectionState ==
                                  ConnectionState.done &&
                              snapshot.hasData &&
                              snapshot.data!.success == true) {
                            return Wrap(
                                spacing: 12.0,
                                alignment: WrapAlignment.start,
                                runAlignment: WrapAlignment.start,
                                crossAxisAlignment: WrapCrossAlignment.start,
                                children: snapshot.data!.reportTags != null &&
                                        snapshot.data!.reportTags!.isNotEmpty
                                    ? snapshot.data!.reportTags!
                                        .map(
                                          (e) => GestureDetector(
                                            onTap: () {
                                              setState(
                                                () {
                                                  if (selectedTags
                                                      .contains(e.id)) {
                                                    selectedTags.remove(e.id);
                                                    deleteReason = null;
                                                  } else {
                                                    selectedTags = {e.id};
                                                    deleteReason = e;
                                                  }
                                                },
                                              );
                                            },
                                            child: Container(
                                              color:
                                                  theme.colorScheme.background,
                                              child: Chip(
                                                label: LMTextView(
                                                  text: e.name,
                                                  textStyle: theme
                                                      .textTheme.bodyLarge!
                                                      .copyWith(
                                                    color: selectedTags
                                                            .contains(e.id)
                                                        ? theme
                                                            .colorScheme.primary
                                                        : theme.colorScheme
                                                            .onPrimaryContainer,
                                                  ),
                                                ),
                                                backgroundColor: selectedTags
                                                        .contains(e.id)
                                                    ? const Color.fromRGBO(
                                                        47, 36, 67, 1)
                                                    : theme.colorScheme.surface,
                                                color:
                                                    MaterialStateProperty.all(
                                                        Colors.transparent),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          12.0),
                                                  side: BorderSide(
                                                    color: selectedTags
                                                            .contains(e.id)
                                                        ? theme
                                                            .colorScheme.primary
                                                        : Colors.transparent,
                                                  ),
                                                ),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 16.0),
                                                labelPadding: EdgeInsets.zero,
                                                elevation: 0,
                                              ),
                                            ),
                                          ),
                                        )
                                        .toList()
                                    : []);
                          } else {
                            return const SizedBox();
                          }
                        }),
                    kVerticalPaddingLarge,
                    deleteReason != null &&
                            (deleteReason!.name.toLowerCase() == 'others' ||
                                deleteReason!.name.toLowerCase() == 'other')
                        ? Container(
                            margin:
                                const EdgeInsets.symmetric(horizontal: 24.0),
                            child: TextField(
                              cursorColor: Colors.white,
                              style: const TextStyle(
                                color: Colors.white,
                                fontFamily: 'Gantari',
                              ),
                              controller: reportReasonController,
                              decoration: InputDecoration(
                                fillColor: Colors.white,
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12.0),
                                  borderSide: const BorderSide(
                                    color: Colors.white,
                                  ),
                                ),
                                focusColor: theme.colorScheme.primary,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12.0),
                                  borderSide: BorderSide(
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                                labelText: 'Reason',
                                labelStyle: theme.textTheme.labelMedium,
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12.0),
                                  borderSide: BorderSide(
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ),
                            ),
                          )
                        : const SizedBox()
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: LMTextButton(
                height: 56,
                backgroundColor: selectedTags.isEmpty
                    ? theme.colorScheme.primary.withOpacity(0.2)
                    : theme.colorScheme.primary,
                borderRadius: 12,
                text: LMTextView(
                  text: 'Submit',
                  textStyle: theme.textTheme.bodyLarge,
                ),
                onTap: () async {
                  String? reason = reportReasonController.text;
                  if (deleteReason != null &&
                      (deleteReason!.name.toLowerCase() == 'others' ||
                          deleteReason!.name.toLowerCase() == 'other')) {
                    if (reason.isEmpty) {
                      toast('Please specify a reason for reporting');
                      return;
                    }
                  }
                  if (selectedTags.isNotEmpty) {
                    Navigator.of(context).pop();
                    PostReportRequest postReportRequest =
                        (PostReportRequestBuilder()
                              ..entityCreatorId(widget.entityCreatorId)
                              ..entityId(widget.entityId)
                              ..entityType(widget.entityType)
                              ..reason(
                                  reason.isEmpty ? deleteReason!.name : reason)
                              ..tagId(deleteReason!.id))
                            .build();
                    PostReportResponse response =
                        await locator<LikeMindsService>()
                            .postReport(postReportRequest);
                    if (!response.success) {
                      toast(response.errorMessage ?? 'An error occured');
                    } else {
                      toast(
                          '${widget.entityType == 5 ? 'Post' : widget.entityType == 6 ? 'Comment' : 'Reply'} reported');
                    }
                  } else {
                    toast('Please select a reason');
                    return;
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
