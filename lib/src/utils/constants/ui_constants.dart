import 'package:flutter/material.dart';
import 'package:likeminds_feed_flutter_core/likeminds_feed_core.dart';
import 'package:likeminds_feed_nova_fl/src/utils/constants/assets_constants.dart';

class ColorTheme {
  static const backgroundColor = Color.fromRGBO(24, 23, 25, 1);
  static const primaryColor = Color.fromRGBO(150, 94, 255, 1);
  static const darkBlack300 = Color.fromRGBO(49, 49, 50, 1);
  static const darkBlack500 = Color.fromRGBO(36, 35, 37, 1);
  static const lightWhite300 = Color.fromRGBO(241, 241, 241, 0.694);
  static const white = Color.fromRGBO(255, 255, 255, 1);
  static const white400 = Color.fromRGBO(241, 241, 241, 0.498);
  static const white600 = Color.fromRGBO(241, 241, 241, 0.12);
  static const redColor = Color.fromRGBO(255, 73, 90, 1);
  static const pdfBlue = Color.fromRGBO(71, 111, 254, 1);

  static final novaTheme = ThemeData.from(
    useMaterial3: false,
    colorScheme: ColorScheme.fromSeed(
      background: ColorTheme.backgroundColor,
      surface: ColorTheme.darkBlack500,
      onBackground: ColorTheme.darkBlack300,
      seedColor: ColorTheme.primaryColor,
      primary: ColorTheme.primaryColor,
      onSecondary: kSecondaryColor700,
      onPrimary: ColorTheme.lightWhite300,
      error: ColorTheme.redColor,
      onPrimaryContainer: ColorTheme.white,
      onSurface: ColorTheme.white600,
      primaryContainer: ColorTheme.pdfBlue,
    ),
    textTheme: const TextTheme(
      titleLarge: TextStyle(
        fontSize: 16,
        color: ColorTheme.white,
        fontWeight: FontWeight.w700,
        fontFamily: 'Gantari',
      ),
      titleMedium: TextStyle(
        fontSize: 14,
        color: ColorTheme.white,
        fontFamily: 'Gantari',
        fontWeight: FontWeight.w700,
        ////height: 0,
      ),
      titleSmall: TextStyle(
        fontSize: 12,
        color: ColorTheme.white,
        fontWeight: FontWeight.w700,
        fontFamily: 'Gantari',
      ),
      labelLarge: TextStyle(
        fontSize: 16,
        color: ColorTheme.lightWhite300,
        fontFamily: 'Gantari',
        fontWeight: FontWeight.w500,
      ),
      labelMedium: TextStyle(
        fontSize: 14,
        color: ColorTheme.lightWhite300,
        fontWeight: FontWeight.w500,
        fontFamily: 'Gantari',
      ),
      labelSmall: TextStyle(
        fontSize: 12,
        color: ColorTheme.lightWhite300,
        fontWeight: FontWeight.w500,
        fontFamily: 'Gantari',
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        color: ColorTheme.white,
        fontFamily: 'Gantari',
        fontWeight: FontWeight.w400,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        color: ColorTheme.white,
        fontWeight: FontWeight.w400,
        fontFamily: 'Gantari',
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        color: ColorTheme.white,
        fontWeight: FontWeight.w400,
        fontFamily: 'Gantari',
      ),
      displayLarge: TextStyle(
        fontSize: 16,
        color: ColorTheme.lightWhite300,
        fontWeight: FontWeight.w400,
        fontFamily: 'Gantari',
      ),
      displayMedium: TextStyle(
        fontSize: 14,
        color: ColorTheme.lightWhite300,
        fontWeight: FontWeight.w400,
        fontFamily: 'Gantari',
      ),
      displaySmall: TextStyle(
        fontSize: 12,
        color: ColorTheme.lightWhite300,
        fontWeight: FontWeight.w400,
        fontFamily: 'Gantari',
      ),
      headlineLarge: TextStyle(
        fontSize: 16,
        color: ColorTheme.white,
        fontFamily: 'Gantari',
        fontWeight: FontWeight.w500,
      ),
      headlineMedium: TextStyle(
        fontSize: 14,
        color: ColorTheme.white,
        fontWeight: FontWeight.w500,
        fontFamily: 'Gantari',
      ),
      headlineSmall: TextStyle(
        fontSize: 12,
        color: ColorTheme.white,
        fontWeight: FontWeight.w500,
        fontFamily: 'Gantari',
      ),
    ),
  );
}

// should not use this theme
LMFeedThemeData novaTheme1 = LMFeedThemeData.light(
  backgroundColor: ColorTheme.backgroundColor,
  primaryColor: ColorTheme.primaryColor,
  container: ColorTheme.backgroundColor,
  onContainer: ColorTheme.white,
  commentStyle: LMFeedCommentStyle.basic().copyWith(
    backgroundColor: ColorTheme.backgroundColor,
    showProfilePicture: true,
    actionsPadding: const EdgeInsets.only(
      left: 44.0,
    ),
  ),
  replyStyle: LMFeedCommentStyle.basic(isReply: true).copyWith(
    backgroundColor: ColorTheme.backgroundColor,
    showProfilePicture: true,
    actionsPadding: const EdgeInsets.only(
      left: 44.0,
    ),
    margin: const EdgeInsets.only(
      left: 44.0,
    ),
  ),
  composeScreenStyle: LMFeedComposeScreenStyle.basic().copyWith(
    addImageIcon: LMFeedIcon(
      type: LMFeedIconType.svg,
      assetPath: kAssetGalleryIcon,
      style: LMFeedIconStyle.basic().copyWith(
        color: ColorTheme.novaTheme.colorScheme.primary,
        boxPadding: 0,
        size: 28,
      ),
    ),
    addVideoIcon: LMFeedIcon(
      type: LMFeedIconType.svg,
      assetPath: kAssetVideoIcon,
      style: LMFeedIconStyle.basic().copyWith(
        color: ColorTheme.novaTheme.colorScheme.primary,
        boxPadding: 0,
        size: 28,
      ),
    ),
    addDocumentIcon: LMFeedIcon(
      type: LMFeedIconType.svg,
      assetPath: kAssetDocPDFIcon,
      style: LMFeedIconStyle.basic().copyWith(
        color: ColorTheme.novaTheme.colorScheme.primary,
        boxPadding: 0,
        size: 28,
      ),
    ),
  ),
  footerStyle: LMFeedPostFooterStyle.basic().copyWith(
    showSaveButton: false,
    likeButtonStyle: LMFeedButtonStyle.basic().copyWith(
      activeIcon: LMFeedIcon(
        type: LMFeedIconType.svg,
        assetPath: kAssetLikeFilledIcon,
        style: LMFeedIconStyle(
          size: 16,
          color: ColorTheme.novaTheme.colorScheme.error,
        ),
      ),
      icon: LMFeedIcon(
        type: LMFeedIconType.svg,
        assetPath: kAssetLikeIcon,
        style: LMFeedIconStyle(
            size: 16, color: ColorTheme.novaTheme.colorScheme.onPrimary),
      ),
    ),
    commentButtonStyle: LMFeedButtonStyle.basic().copyWith(
      icon: LMFeedIcon(
        type: LMFeedIconType.svg,
        assetPath: kAssetCommentIcon,
        style: LMFeedIconStyle(
            size: 20, color: ColorTheme.novaTheme.colorScheme.onPrimary),
      ),
    ),
    shareButtonStyle: LMFeedButtonStyle.basic().copyWith(
      icon: LMFeedIcon(
        type: LMFeedIconType.svg,
        assetPath: kAssetShareIcon,
        style: LMFeedIconStyle(
            size: 20, color: ColorTheme.novaTheme.colorScheme.onPrimary),
      ),
    ),
  ),
);

const Color kPrimaryColor = Color(0xFF3B82F6);
const Color primary500 = Color(0xFF4666F6);
const Color kHeadingBlackColor = Color(0xFF0F172A);
const Color kPrimaryColorLight = Color(0xFFDBEAFE);
const Color kSecondary100 = Color(0xFFF1F5F9);
const Color kSecondaryColor700 = Color(0xFF334155);
const Color kSecondaryColorLight = Color(0xFFEDF0FE);
const Color onSurface = Color(0xFFE2E8F0);
const Color onSurface500 = Color(0xFF64748B);
const Color kBackgroundColor = Color(0xffF5F5F5);
const Color kWhiteColor = Color(0xffFFFFFF);
const Color appBlack = Color(0xFF334155);
const Color appSecondaryBlack = Color(0xFF94A3B8);
const Color kGreyColor = Color(0xff666666);
const Color kGrey1Color = Color(0xff222020);
const Color kGrey2Color = Color(0xff504B4B);
const Color kGrey3Color = Color(0xff9B9B9B);
const Color kGreyWebBGColor = Color(0xffE6EBF5);
const Color kGreyBGColor = Color(0x66D0D8E2);
const Color kBlueGreyColor = Color(0xFF484F67);
const Color kLinkColor = Color(0xff007AFF);
const Color kHeadingColor = Color(0xff333149);
const Color kBorderColor = Color(0x7ED0D8E2);
const Color notificationRedColor = Color(0x66D0D8E2);

const double kFontSmall = 12;
const double kButtonFontSize = 12;
const double kFontXSmall = 11;
const double kFontSmallMed = 14;
const double kFontMedium = 16;
const double kPaddingXSmall = 2;
const double kPaddingSmall = 4;
const double kPaddingMedium = 8;
const double kPaddingLarge = 16;
const double kPaddingXLarge = 20;
const double kBorderRadiusXSmall = 2;
const double kBorderRadiusMedium = 8;
const SizedBox kHorizontalPaddingXLarge = SizedBox(width: kPaddingXLarge);
const SizedBox kHorizontalPaddingSmall = SizedBox(width: kPaddingSmall);
const SizedBox kHorizontalPaddingXSmall = SizedBox(width: kPaddingXSmall);
const SizedBox kHorizontalPaddingLarge = SizedBox(width: kPaddingLarge);
const SizedBox kHorizontalPaddingMedium = SizedBox(width: kPaddingMedium);
const SizedBox kVerticalPaddingXLarge = SizedBox(height: kPaddingXLarge);
const SizedBox kVerticalPaddingSmall = SizedBox(height: kPaddingSmall);
const SizedBox kVerticalPaddingXSmall = SizedBox(height: kPaddingXSmall);
const SizedBox kVerticalPaddingLarge = SizedBox(height: kPaddingLarge);
const SizedBox kVerticalPaddingMedium = SizedBox(height: kPaddingMedium);
