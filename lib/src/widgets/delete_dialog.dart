// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:likeminds_feed/likeminds_feed.dart';
import 'package:likeminds_feed_nova_fl/likeminds_feed_nova_fl.dart';
import 'package:likeminds_feed_nova_fl/src/services/likeminds_service.dart';
import 'package:likeminds_feed_nova_fl/src/services/service_locator.dart';
import 'package:likeminds_feed_nova_fl/src/utils/constants/ui_constants.dart';
import 'package:likeminds_feed_nova_fl/src/utils/local_preference/user_local_preference.dart';
import 'package:likeminds_feed_ui_fl/likeminds_feed_ui_fl.dart';
import 'package:overlay_support/overlay_support.dart';

Dialog deleteConfirmationDialog(
  BuildContext context, {
  required String title,
  required String content,
  required String userId,
  required Function(String) action,
  required String actionText,
}) {
  Size screenSize = MediaQuery.of(context).size;
  bool boolVarLoading = false;
  ValueNotifier<bool> rebuildReasonBox = ValueNotifier(false);
  DeleteReason? reasonForDeletion;
  bool isCm = UserLocalPreference.instance.fetchMemberState();
  User user = UserLocalPreference.instance.fetchUserData();
  ThemeData theme = ColorTheme.novaTheme;

  return Dialog(
    backgroundColor: theme.colorScheme.background,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(6.0),
    ),
    elevation: 5,
    child: Container(
      width: screenSize.width * 0.7,
      padding: const EdgeInsets.symmetric(
        horizontal: 20.0,
        vertical: 20.0,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          LMTextView(
            text: title,
            textStyle: theme.textTheme.titleLarge,
          ),
          kVerticalPaddingLarge,
          LMTextView(
            text: content,
            maxLines: 3,
            textAlign: TextAlign.center,
            textStyle: theme.textTheme.bodyMedium,
          ),
          user.userUniqueId == userId
              ? const SizedBox.shrink()
              : isCm
                  ? kVerticalPaddingLarge
                  : const SizedBox.shrink(),
          user.userUniqueId == userId
              ? const SizedBox.shrink()
              : isCm
                  ? Builder(builder: (context) {
                      return ValueListenableBuilder(
                          valueListenable: rebuildReasonBox,
                          builder: (context, _, __) {
                            return GestureDetector(
                              onTap: boolVarLoading
                                  ? () {}
                                  : () async {
                                      boolVarLoading = true;
                                      rebuildReasonBox.value =
                                          !rebuildReasonBox.value;
                                      GetDeleteReasonResponse response =
                                          await locator<LikeMindsService>()
                                              .getReportTags(
                                                  ((GetDeleteReasonRequestBuilder()
                                                        ..type(0))
                                                      .build()));
                                      if (response.success) {
                                        List<DeleteReason> reportTags =
                                            response.reportTags!;

                                        await showModalBottomSheet(
                                            context: context,
                                            elevation: 5,
                                            enableDrag: true,
                                            clipBehavior: Clip.hardEdge,
                                            backgroundColor:
                                                theme.colorScheme.surface,
                                            useSafeArea: true,
                                            shape: const RoundedRectangleBorder(
                                              borderRadius: BorderRadius.only(
                                                topLeft: Radius.circular(16.0),
                                                topRight: Radius.circular(16.0),
                                              ),
                                            ),
                                            builder: (context) {
                                              return Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 20.0,
                                                        vertical: 30.0),
                                                color: theme
                                                    .colorScheme.background,
                                                width: screenSize.width,
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                              left: 10.0),
                                                      child: Text(
                                                        'Reason for deletion',
                                                        textAlign:
                                                            TextAlign.left,
                                                        style: theme.textTheme
                                                            .titleLarge,
                                                      ),
                                                    ),
                                                    kVerticalPaddingXLarge,
                                                    Expanded(
                                                      child: ListView.separated(
                                                          separatorBuilder:
                                                              (context,
                                                                      index) =>
                                                                  Container(
                                                                    margin: const EdgeInsets
                                                                        .only(
                                                                        left:
                                                                            50),
                                                                    child:
                                                                        const Divider(
                                                                      thickness:
                                                                          0.5,
                                                                      color:
                                                                          kGrey3Color,
                                                                    ),
                                                                  ),
                                                          itemBuilder:
                                                              (context, index) {
                                                            return InkWell(
                                                              onTap: () {
                                                                reasonForDeletion =
                                                                    reportTags[
                                                                        index];
                                                                Navigator.pop(
                                                                    context);
                                                              },
                                                              child: Container(
                                                                color: Colors
                                                                    .transparent,
                                                                child: Row(
                                                                  children: [
                                                                    SizedBox(
                                                                      width: 35,
                                                                      child:
                                                                          Radio(
                                                                        value: reportTags[index]
                                                                            .id,
                                                                        groupValue: reasonForDeletion ==
                                                                                null
                                                                            ? -1
                                                                            : reasonForDeletion!.id,
                                                                       fillColor: MaterialStateProperty.all(reasonForDeletion != null &&
                                                                                reasonForDeletion!.id == reportTags[index].id
                                                                            ? theme.colorScheme.primary
                                                                            : Colors.white),
                                                                        onChanged:
                                                                            (value) {},
                                                                        activeColor: theme
                                                                            .colorScheme
                                                                            .primary,
                                                                      ),
                                                                    ),
                                                                    kHorizontalPaddingLarge,
                                                                    Text(
                                                                      reportTags[
                                                                              index]
                                                                          .name,
                                                                      style: theme
                                                                          .textTheme
                                                                          .labelMedium,
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                            );
                                                          },
                                                          itemCount: reportTags
                                                              .length),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            });
                                        rebuildReasonBox.value =
                                            !rebuildReasonBox.value;
                                      } else {
                                        toast(response.errorMessage ??
                                            'An error occurred');
                                      }
                                      boolVarLoading = false;
                                      rebuildReasonBox.value =
                                          !rebuildReasonBox.value;
                                    },
                              child: Container(
                                  padding: const EdgeInsets.all(14.0),
                                  decoration: BoxDecoration(
                                      color: theme.colorScheme.surface,
                                      borderRadius: BorderRadius.circular(8.0),
                                      boxShadow: const [
                                        BoxShadow(
                                          blurRadius: 4,
                                          spreadRadius: 0,
                                          offset: Offset(0, 2),
                                          color: Colors.black12,
                                        )
                                      ]),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        reasonForDeletion == null
                                            ? 'Reason for deletion'
                                            : reasonForDeletion!.name,
                                        style: theme.textTheme.titleMedium,
                                      ),
                                      Icon(
                                        Icons.arrow_drop_down,
                                        color: ColorTheme
                                            .novaTheme.colorScheme.onPrimary,
                                      )
                                    ],
                                  )),
                            );
                          });
                    })
                  : const SizedBox.shrink(),
          kVerticalPaddingLarge,
          const Divider(color: kGrey3Color),
          LMTextButton(
            onTap: () {
              if (user.userUniqueId != userId && isCm) {
                if (reasonForDeletion == null) {
                  toast('Please select a reason for deletion');
                  return;
                }
              }
              action(reasonForDeletion == null ? '' : reasonForDeletion!.name);
            },
            text: LMTextView(
              text: actionText,
              textStyle: theme.textTheme.headlineMedium!
                  .copyWith(color: theme.colorScheme.error),
            ),
          ),
          const Divider(color: kGrey3Color),
          LMTextButton(
            onTap: () {
              Navigator.of(context).pop();
            },
            text: LMTextView(
              text: 'Cancel',
              textStyle: theme.textTheme.headlineMedium,
            ),
          ),
        ],
      ),
    ),
  );
}
