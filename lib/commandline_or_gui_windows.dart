/*
  Bradley Honeyman
  March 16, 2022
 */

import 'dart:io';

import 'package:flutter/material.dart';

class CommandlineOrGuiWindows {
  // static const MethodChannel _channel = MethodChannel("commandline_or_gui_windows");
  static bool? _closeOnCompleteCommandlineOptionOnly;

  ///
  static Future<void> runAppCommandlineOrGUI<T>({
    Widget? gui,
    Future<void> Function()? commandlineRun,
    required int argsCount,
    bool closeOnCompleteCommandlineOptionOnly = true,
    int commandlineExitSuccessCode = 0,
  }) async {
    _closeOnCompleteCommandlineOptionOnly =
        closeOnCompleteCommandlineOptionOnly;
    bool commandline = argsCount > 0;

    // throw err if in gui mode and no gui
    if (gui == null && !commandline) {
      throw Exception(
          "CommandlineOrGuiWindows: Must pass a gui Widget if commandline == false");
    }

    // if in gui mode run gui function
    if (!commandline) {
      runApp(gui!);
      return;
    }

    // err if in commandline mode and commandlineRun is passed
    if (commandlineRun == null) {
      throw Exception(
          "CommandlineOrGuiWindows: Must pass a commandlineRun Future if in commandline mode");
    }

    // run users commandline code and exit
    await commandlineRun();
    commandlineExit(exitCode: commandlineExitSuccessCode);
  }

  /// A function that can be used to exit the app when it is in commandline mode
  /// should only be called from afterLoaded function
  /// not for use with gui
  /// will not close app if _closeOnCompleteCommandlineOptionOnly is false, which is usually for debugging purposes only
  static commandlineExit({int exitCode = 0}) {
    // if not called in afterLoaded, throw error, because _closeOnCompleteCommandlineOptionOnly is set in runAppCommandlineOrGUI
    if (_closeOnCompleteCommandlineOptionOnly == null) {
      throw Exception(
          "CommandlineOrGuiWindows: commandlineExit function can only be used in afterLoaded function");
    }

    // close app using passed or default exit code
    if (_closeOnCompleteCommandlineOptionOnly!) {
      exit(exitCode);
    }
  }
}
