/*
  Bradley Honeyman
  March 16, 2022
 */

import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

/// Provides ability to write to terminal stdout & stderr
/// and the ability to run in terminal and or gui
/// terminal = shell in terminology
class CommandlineOrGuiWindows {
  static const MethodChannel _channel =
      MethodChannel("commandline_or_gui_windows");
  static bool? _closeOnCompleteCommandlineOptionOnly;

  @Deprecated("Should not have been added, OS syncs stdout and stderr")
  static Future<void> syncStdOutAndStdErrWithConsole() async {
    await _channel.invokeMethod(
      "syncStdOutAndStdErrWithConsole",
    );
  }

  /// send data to stdout
  /// will send to default stdout if terminal not set as stdout
  static Future<void> stdout(String out) async {
    await _channel.invokeMethod(
      "printToTerminal",
      {
        "out": out,
      },
    );
  }

  /// send data to sdterr
  /// will send to default stderr if terminal not set as stderr
  static Future<void> stderr(String out) async {
    await _channel.invokeMethod(
      "printToTerminalError",
      {
        "out": out,
      },
    );
  }

  /// hides the gui
  /// the gui still exists, but cannot be interacted with by the user
  static Future<void> hideWindow() async {
    await _channel.invokeMethod(
      "hideWindow",
    );
  }

  /// runs runApp. Is a replacement for runApp
  /// if commandline = true run app in commandline
  /// otherwise load passed gui widget ex material app
  /// closeOnCompleteCommandlineOptionOnly, closes app after supplied code (afterLoaded) is run, unless is false
  /// should only set closeOnCompleteCommandlineOptionOnly as false if debugging
  /// placeHolderAfterLoadedRunning is the widget displayed while afterLoaded is running
  /// placeHolderAfterLoadedRunning defaults to a circular progress indicator
  static Future<void> runAppCommandlineOrGUI({
    Widget? gui,
    Future<void> Function()? afterLoaded,
    bool commandline = true,
    bool closeOnCompleteCommandlineOptionOnly = true,
    int commandlineExitSuccessCode = 0,
    Widget placeHolderAfterLoadedRunning = const MaterialApp(
        home: Scaffold(body: Center(child: CircularProgressIndicator()))),
  }) async {
    // set so commandlineExit can be used
    _closeOnCompleteCommandlineOptionOnly =
        closeOnCompleteCommandlineOptionOnly;

    // throw err if in gui mode and no gui
    if (gui == null && !commandline) {
      throw Exception(
          "CommandlineOrGuiWindows: Must pass a gui widget if commandline == false");
    }

    // if in gui mode return gui
    if (!commandline) {
      runApp(gui!);
      return;
    }

    // err if afterLoaded passed and null
    if (afterLoaded == null) {
      throw Exception(
          "CommandlineOrGuiWindows: Must pass a afterLoaded Future if in commandline mode");
    }

    // run in commandline mode if not in gui mode
    runApp(_CommandlineWidget(
      afterLoaded: afterLoaded,
      closeOnComplete: closeOnCompleteCommandlineOptionOnly,
      placeHolder: placeHolderAfterLoadedRunning,
      commandlineExitSuccessCode: commandlineExitSuccessCode,
    ));
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

// place holder widget, shown before app closes
class _CommandlineWidget extends StatefulWidget {
  final Future<void> Function() afterLoaded;
  final bool closeOnComplete;
  final Widget placeHolder;
  final int commandlineExitSuccessCode;

  const _CommandlineWidget({
    Key? key,
    required this.afterLoaded,
    required this.closeOnComplete,
    required this.placeHolder,
    required this.commandlineExitSuccessCode,
  }) : super(key: key);

  @override
  _CommandlineWidgetState createState() {
    return _CommandlineWidgetState();
  }
}

// place holder state
class _CommandlineWidgetState extends State<_CommandlineWidget> {
  @override
  void initState() {
    super.initState();
    _run();
  }

  // runs after widget init, this way it is fairly certain that flutter has loaded
  // closes app on complete unless told not to
  Future<void> _run() async {
    // run code passed
    await widget.afterLoaded();

    // close app on complete unless otherwise specified
    if (widget.closeOnComplete) {
      exit(widget.commandlineExitSuccessCode);
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.placeHolder;
  }
}
