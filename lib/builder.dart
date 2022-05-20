/*
  Bradley Honeyman
  May 20, 2022

  This code is used to modify windows/runner code
  This code should not be used in your app just for developing

 */

import 'dart:io';
import 'package:args/args.dart';
import 'package:package_config/package_config.dart';

class Builder {
  final List<String> arguments;
  late final ArgResults _results;
  late final ArgParser _parser;

  Builder({
    required this.arguments,
  }) {
    // make parser
    _parser = ArgParser();
    _parser.addOption(
      "windows_runner_path",
      abbr: "p",
      mandatory: false,
      help:
          "Set the folder path of a project that contains the windows\\runner folder. For example, C:\\project_path",
    );
    _parser.addFlag(
      "help",
      abbr: "h",
      negatable: false,
      help: "If passed displays help regarding flags and options",
    );
    _parser.addFlag(
      "overwrite",
      abbr: "o",
      negatable: true,
      defaultsTo: true,
      help:
          "By default is true, and tells to overwrite existing C++ files to make false pass --no-overwrite",
    );

    // parse args
    _results = _parser.parse(arguments);
  }

  /// prints specific help to stdout and option/flag help
  bool _help(String? specific) {
    if (_results["help"]) {
      // write help to stdio if passed
      if (specific != null) {
        stdout.writeln(specific);
      }
      stdout.writeln(_parser.usage);
      return true;
    }
    return false;
  }

  /// returns a custom path or the default path to windows\\runnner
  String _getRunnerPath() {
    String subPath = "\\windows\\runner";

    // if path provided
    if (_results["windows_runner_path"] != null &&
        (_results["windows_runner_path"] as String).isNotEmpty) {
      // convert to string and remove trailing slash if there
      String temp =
          _removeTrailingSlash(_results["windows_runner_path"] as String);

      // replace / with \
      if (temp.contains("/")) {
        temp = temp.replaceAll("/", "\\");
      }

      // return formatted path
      return "$temp$subPath";
    }

    // default path
    return "${Directory.current.path}$subPath";
  }

  /// removes a leading / or \\ if it is there
  String _removeTrailingSlash(String input) {
    if (input.endsWith("/") || input.endsWith("\\")) {
      return input.substring(0, input.length - 1);
    }
    return input;
  }

  /// uses .dart_tool\\package_config.json to get the path to the assets
  Future<List<String>?> _getAssetPaths() async {
    // get package config
    PackageConfig? config = await findPackageConfig(Directory.current);
    if (config == null) {
      stderr.writeln("Unable to find package config");
      return null;
    }

    // get commandline_or_gui_windows
    Package package = config.packages
        .singleWhere((element) => element.name == "commandline_or_gui_windows");

    // get path to assets
    String path = "${package.packageUriRoot.toFilePath(windows: true)}assets\\";

    // return asset paths
    return <String>[
      "${path}main.cpp",
      "${path}win32_window.cpp",
      "${path}win32_window.h",
    ];
  }

  /// copies the C++ files from the plugin to the dev's app
  Future<void> _copyAssetsToProject() async {
    // set file paths
    List<String> projectCodePaths = <String>[
      "${_getRunnerPath()}\\main.cpp",
      "${_getRunnerPath()}\\win32_window.cpp",
      "${_getRunnerPath()}\\win32_window.h",
    ];

    // get asset paths
    List<String>? assetPaths = await _getAssetPaths();
    if (assetPaths == null) {
      return;
    }

    // if no overwite don't overwrite existing c++ files
    if (!_results["overwrite"]) {
      for (var element in projectCodePaths) {
        if (File(element).existsSync()) {
          stderr.writeln(
              "--no-overwrite passed, and there are existing C++ files: $element");
          return;
        }
      }
    }

    // copy files
    for (int i = 0; i < assetPaths.length; i++) {
      File(assetPaths[i]).copy(projectCodePaths[i]);
    }
  }

  /// Creates the required C++ files to run in commandline mode.
  /// Note that existing C++ files in the windows\\runner folder will be deleted
  /// unless --no-overwrite is passed
  Future<void> create() async {
    // run help and exit if help passed
    // and write specific help data
    if (_help(
        "Creates the required C++ files to run in commandline mode. Note that existing C++ files in the windows\\runner folder will be deleted")) {
      return;
    }

    // copy C++ code to project
    _copyAssetsToProject();

    // throw error if windows/runner can't be found
    if (!Directory(_getRunnerPath()).existsSync()) {
      stderr.writeln("Could not find: ${_getRunnerPath()}");
    }
  }
}
