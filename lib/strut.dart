/*
  Bradley Honeyman
  April 22, 2024
 */

import 'package:flutter/material.dart';

/// strut version, no support for this platform
class CommandlineOrGuiWindows {
  /// used to run the app in commandline or gui mode
  /// argsCount should be args.length from the main function
  /// the gui will load if 0 args are passed
  /// commandline mode will run if 1+ args are passed
  /// if the function is running wrong run:
  /// flutter pub run commandline_or_gui_windows:create.
  /// Throws an error if not windows
  static Future<void> runAppCommandlineOrGUI({
    Widget? gui,
    Future<void> Function()? commandlineRun,
    required int argsCount,
    bool closeOnCompleteCommandlineOptionOnly = true,
    int commandlineExitSuccessCode = 0,
  }) async {
    throw UnsupportedError('Unsupported Platform');
  }

  /// A function that can be used to exit the app when it is in commandline mode
  /// should only be called from afterLoaded function
  /// not for use with gui
  /// will not close app if _closeOnCompleteCommandlineOptionOnly is false, which is usually for debugging purposes only
  static commandlineExit({int exitCode = 0}) {
    throw UnsupportedError('Unsupported Platform');
  }
}
