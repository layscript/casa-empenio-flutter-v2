import 'package:casa_empenio_pe/presentation/app/assets/assets.dart';
import 'package:flutter/material.dart';

const _defaultTextStyle = TextStyle(
  letterSpacing: 0.125,
  color: AppColors.black,
//
);
ThemeData buildTheme(BuildContext context) {
  final themeData = Theme.of(context);
  return ThemeData(
    useMaterial3: false,
    dividerTheme: const DividerThemeData(
      color: AppColors.divider,
      space: 1,
      thickness: 1,
    ),
    scaffoldBackgroundColor: AppColors.white,
    platform: TargetPlatform.iOS,
    checkboxTheme: CheckboxThemeData(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(4)),
      ),
      fillColor: MaterialStateProperty.resolveWith(
        (states) => states.contains(MaterialState.selected)
            ? AppColors.blue
            : AppColors.secondaryText,
      ),
    ),
    //hintColor: AppColors.secondaryText,

    /* bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.white,
      showUnselectedLabels: true,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: AppColors.orange,
      unselectedItemColor: AppColors.secondaryText,
      elevation: 0,
      selectedIconTheme: IconThemeData(
        size: 24,
      ),
      unselectedIconTheme: IconThemeData(
        size: 24,
      ),
      selectedLabelStyle: TextStyle(
        fontSize: 10,
        color: AppColors.orange,
      ),
      unselectedLabelStyle: TextStyle(
        fontSize: 10,
      ),
    ), */
    /*  switchTheme: SwitchThemeData(
      trackColor: MaterialStateProperty.all(AppColors.primary),
      thumbColor: MaterialStateProperty.all(AppColors.primary),
      overlayColor: MaterialStateProperty.all(AppColors.primary),
    ),
    checkboxTheme: CheckboxThemeData(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(4)),
      ),
      fillColor: MaterialStateProperty.resolveWith(
        (states) => states.contains(MaterialState.selected)
            ? AppColors.primary
            : AppColors.secondaryText,
      ),
    ),
    radioTheme: RadioThemeData(
      fillColor: MaterialStateProperty.resolveWith(
        (states) => states.contains(MaterialState.selected)
            ? AppColors.primary
            : AppColors.secondaryText,
      ),
    ), */
    inputDecorationTheme: const InputDecorationTheme(
      errorStyle: TextStyle(
        color: AppColors.error,
        fontSize: 9,
        height: 0.8,
      ),
      border: OutlineInputBorder(
        borderSide: BorderSide(
          color: AppColors.secondaryText,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderSide: BorderSide(
          color: AppColors.error,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderSide: BorderSide(
          color: AppColors.error,
        ),
      ),
      filled: true,
      isDense: true,
      fillColor: Colors.transparent,
      labelStyle: TextStyle(
        fontSize: 14,
      ),
      // contentPadding: EdgeInsets.fromLTRB(12, 20, 0, 20),
      contentPadding: EdgeInsets.only(left: 15, top: 18, bottom: 18),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(
          color: AppColors.buttonPrimary,
        ),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ButtonStyle(
        elevation: MaterialStateProperty.all(0),
        backgroundColor: MaterialStateProperty.resolveWith<Color>(
          (Set<MaterialState> states) => states.contains(MaterialState.disabled)
              ? AppColors.disabledButton
              : AppColors.blue,
        ),
        //overlayColor: MaterialStateProperty.all(AppColors.primaryHover),
        animationDuration: const Duration(seconds: 500),
        //shape: MaterialStateProperty.all(shapeButtonBorderRadius),
        //padding: MaterialStateProperty.all(horizontalViewSpacing),
        fixedSize: MaterialStateProperty.all(const Size.fromHeight(50)),
        minimumSize: MaterialStateProperty.all(const Size.fromHeight(50)),
        foregroundColor: MaterialStateProperty.all(AppColors.white),
        textStyle: MaterialStateProperty.all(
          const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.white,
          ),
        ),
      ),
    ),
    textTheme: themeData.textTheme.copyWith(
      subtitle1: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: AppColors.black,
      ),
      headline1: _defaultTextStyle,
      headline2: _defaultTextStyle,
      headline3: _defaultTextStyle,
      headline4: _defaultTextStyle,
      headline5: _defaultTextStyle,
      headline6: _defaultTextStyle,
      subtitle2: _defaultTextStyle,
      bodyText1: _defaultTextStyle,
      bodyText2: _defaultTextStyle,
      button: _defaultTextStyle,
      caption: _defaultTextStyle,
      overline: _defaultTextStyle,
    ),
  );
}
