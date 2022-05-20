# Commandline or GUI Windows
### This plugin allows you to run a flutter windows app in gui mode. 

<br>

## ***Setup***
### If the setup isn't performed the below code will not run as expected
1. Import the package (add to ```pubspec.yaml``` and run ```pub get```)
2. Open powershell and navigate to the root directory of your app. This is typically the directory where your pubspec.yaml resides.
3. run ```flutter pub run commandline_or_gui_windows:create``` If you want more details run ```flutter pub run commandline_or_gui_windows:create --help```

## Please Post Questions on StackOverflow, and tag @CatTrain (user:16200950)
https://stackoverflow.com/

## Importing:
### YAML:
```yaml
dependencies:
    commandline_or_gui_windows: ^2.0.0
```
### Dart:
```dart
import 'package:commandline_or_gui_windows/commandline_or_gui_windows.dart';
```

<br>

## Example - Commandline Only:
Note that at least one argument must be passed or the app will crash and enter gui mode
```dart
import 'package:commandline_or_gui_windows/commandline_or_gui_windows.dart';
import 'dart:io';

void main(List<String> args) {
  CommandlineOrGuiWindows.runAppCommandlineOrGUI(
    argsCount: args.length,
    commandlineRun: () async {
      stdout.writeln("Hello world");
      stderr.writeln("Oh no!");
    },
  );
}
```

## Example - GUI Only:
Note that it will crash if any commandline arguments are passed, because ```commandlineRun``` isn't set
```dart
import 'package:commandline_or_gui_windows/commandline_or_gui_windows.dart';
import 'package:flutter/material.dart';

void main(List<String> args) {
  CommandlineOrGuiWindows.runAppCommandlineOrGUI(
    argsCount: args.length,
    gui: const MaterialApp(
      home: Scaffold(
        body: Text("Hello World"),
      ),
    ),
  );
}
```

## Example - GUI or Commandline:
This example uses [args.dart package](https://pub.dev/packages/args).
```dart
// flutter library for gui
import 'package:flutter/material.dart';

// import of the plugin
import 'package:commandline_or_gui_windows/commandline_or_gui_windows.dart';

// used to write to stdout and stderr
import 'dart:io';

// not part of plugin, added to add commandline input
import 'package:args/args.dart';

/*
  Commandline and dart
    https://dart.dev/tutorials/server/cmdline
  Error codes:
    https://docs.microsoft.com/en-us/windows/win32/debug/system-error-codes--0-499-
 */
void main(List<String> args) async {
  // create flags
  ArgParser parser = ArgParser();
  parser.addOption(
    "two_multiplied_by",
    abbr: "m",
    mandatory: false,
    help: "Pass an int, and see 2 * int",
  );
  parser.addFlag(
    "help",
    abbr: "h",
    negatable: true,
    defaultsTo: false,
    help: "If passed help for flags is displayed",
  );

  // parse results exit if error
  ArgResults results;
  try {
    // parse
    results = parser.parse(args);

    // if help is passed display help
    if (results["help"]) {
      stdout.writeln(parser.usage);
      exit(0);
    }
  } catch (err) {
    stderr.writeln(err.toString());
    exit(1);
  }

  /*
    Runs in commandline mode if one or more args are passed
    trys to multiply by the value passed by two_multiplied_by
    and outputs result to stdout
    on error prints to stderr
    if no args, runs in gui mode
   */
  CommandlineOrGuiWindows.runAppCommandlineOrGUI<void>(
    // if there are 1 or more args passed the app will run in commandline mode
    argsCount: args.length,

    // if false the app won't close at the end of commandline mode
    // this is allows you to work on code without builing after every change
    // set to true if you want the app to close when commandline finishes
    closeOnCompleteCommandlineOptionOnly: false,

    // when in commandline mode run the below function
    commandlineRun: () async {
      // if a value is passed attempt to parse and multiply by 2
      if (results["two_multiplied_by"] != null) {
        try {
          stdout.writeln(int.parse(results["two_multiplied_by"]) * 2);
        } catch (err) {
          stderr.writeln(
              "Unable to multiply, 2 * ${results["two_multiplied_by"]}:\n${err.toString()}");
          CommandlineOrGuiWindows.commandlineExit(
              exitCode: 87); // ERROR_INVALID_PARAMETER
        }
        // write error to stderr and send 1 as error exit code
      } else {
        stdout.writeln("You didn't pass anything to be multiplied by 2");
      }
    },

    // gui to be shown when running in gui mode
    gui: const MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text("Hello World"),
        ),
      ),
    ),
  );
}
```

## Functions:
```dart
static Future<void> runAppCommandlineOrGUI<T>({
  Widget? gui,
  Future<void> Function()? commandlineRun,
  required int argsCount,
  bool closeOnCompleteCommandlineOptionOnly = true,
  int commandlineExitSuccessCode = 0,
}) async
  ```
- runs runApp, is a replacment for runApp. Allows running of the app in commandline or GUI mode.
- Parameters: 
    - ```Widget? gui```
        - The gui that will be displayed, only required if there are one or more commandline arguments passed
    - ```Future<void> Function()? commandlineRun```
        - Function that must be passed if there are one or more commandline arguments passed
        - This is the code that is run when in commandline mode
    - ```required int argsCount```
        - if ```> 0``` run in commandline mode
            - ```commandlineRun``` must be passed
        - if ```< 1``` 
            - ```gui``` must be passed
    - ```bool closeOnCompleteCommandlineOptionOnly = true```
        - closes the app when ```commandlineRun``` is done being run
        - Only relevant if in commandline mode
    - ```int commandlineExitSuccesCode = 0```
        - exit code that is sent when the app exits in commandline mode successfully

```dart
static commandlineExit({int exitCode = 0})
```
- Exits the commandline app when called
  - should only be called from the ```afterLoaded``` function passed to ```runAppCommandlineOrGUI```
  - will not close app if ```closeOnCompleteCommandlineOptionOnly``` passed to ```runAppCommandlineOrGUI``` is ```false```
    - this allows for debugging in certain scenarios

<br>

## Ref:
https://github.com/Honeyman-Applications/commandline_or_gui_windows/
<br>
https://api.flutter.dev/flutter/material/CircularProgressIndicator-class.html
<br>
https://pub.dev/packages/args
<br>
https://dart.dev/tutorials/server/cmdline
<br>
https://docs.microsoft.com/en-us/windows/win32/debug/system-error-codes--0-499-