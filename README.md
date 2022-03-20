# Commandline or GUI Windows
### This plugin allows you to run a flutter windows app in gui mode, or commandline mode, and redirect stdout & stderr to the shell. 

<br>

## Notes:
- ***Windows Only*** 
- Only tested on Windows 10 21H1 
    - 16/03/2022
- If in commandline mode, commandline output is supposed to be sent to the stdout/stderr of the shell that ran the app.
- A GUI window opens when in commandline mode while the app is running
    - this does not effect where the output goes when running in commandline mode
    - program closes on completion, and so does the gui
    - cannot remove GUI for now, because the plugin requires flutter to be run
        - flutter requires the GUI, and there isn't currently an easy way (I know of) of closing the window, and making use of dart/flutter
    - by default a centered [CircularProgressIndicator](https://api.flutter.dev/flutter/material/CircularProgressIndicator-class.html) is displayed while the GUI us open
        - you can set a widget to display using the ```placeHolderAfterLoadedRunning``` parameter in the ```CommandlineOrGuiWindows.runAppCommandlineOrGUI``` function

<br>

## Please Post Questions on StackOverflow, and tag @CatTrain (user:16200950)
https://stackoverflow.com/

## Importing:
### YAML:
```yaml
dependencies:
    commandline_or_gui_windows: ^0.0.1
    
```
### Dart:
```dart
import 'package:commandline_or_gui_windows/commandline_or_gui_windows.dart';
```

<br>

## Example - Commandline Only:
Note that ```commandline``` is true, if false app attempts to run in GUI mode. The app will exit once afterLoaded is done running, unless ```closeOnCompleteCommandlineOptionOnly``` is passed as ```false``` (default ```true```). If the below code is run in Android Studio by clicking the run (debug) button you will see a window open and close. To run this example follow the below steps:
- Open PowerShell
    - navigate to ```C:\my_project_path\```
    - run:
        - ```flutter build windows --debug```
    - navigate to ```C:\my_project_path\build\windows\runner```
    - run:
        - ```.\myApp.exe```
```dart
import 'package:commandline_or_gui_windows/commandline_or_gui_windows.dart';

void main() async {
  await CommandlineOrGuiWindows.runAppCommandlineOrGUI(
    afterLoaded: () async {
      await CommandlineOrGuiWindows.stdout("Hello World!");
      await CommandlineOrGuiWindows.stderr("I am broken, oh no!");
    },
  );
}
```

## Example - GUI Only:
Note that ```commandline``` is false, if true the app attempts to run in commandline mode
```dart
import 'package:commandline_or_gui_windows/commandline_or_gui_windows.dart';
import 'package:flutter/material.dart';

void main() async {
  await CommandlineOrGuiWindows.runAppCommandlineOrGUI(
    commandline: false,

    // gui of the app
    gui: const MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text("This is the gui of the app"),
        ),
      ),
    ),
  );
}
```

## Example - GUI or Commandline:
This example uses [args.dart package](https://pub.dev/packages/args). If the below code is run in Android Studio by clicking the run (debug) button you will see only the GUI. To run this example follow the below steps:
- Open PowerShell
    - navigate to ```C:\my_project_path\```
    - run:
        - ```flutter build windows --debug```
    - navigate to ```C:\my_project_path\build\windows\runner```
    - run:
        - for GUI
            - ```.\myApp.exe```
        - for commandline
            - ```.\myApp.exe -a```
```dart
import 'package:flutter/material.dart';
import 'package:commandline_or_gui_windows/commandline_or_gui_windows.dart';

// not part of plugin, added to add commandline input
import 'package:args/args.dart';

void main(List<String> args) async {
  /*
   not part of plugin, added to add commandline input
   ref:
   https://pub.dev/packages/args
   if run from shell:
   .\commandline_or_gui_windows_example.exe -a
   it will run in commandline mode
   if run from shell:
   .\commandline_or_gui_windows_example.exe
   it will run in gui mode
  */
  ArgParser parser = ArgParser();
  parser.addFlag(
    "automation",
    abbr: "a",
  );
  ArgResults results = parser.parse(args);

  // part of plugin, main entry. This runciton runs runApp
  await CommandlineOrGuiWindows.runAppCommandlineOrGUI(
    // if you want to run in gui or commandline mode
    commandline: results["automation"], // parsed option from above

    // code you want to run if in commandline mode
    afterLoaded: () async {
      await CommandlineOrGuiWindows.stdout("Hello World");
      await CommandlineOrGuiWindows.stderr("I am broken, oh no!");
    },

    // gui of the app
    gui: const MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text("This is the gui of the app"),
        ),
      ),
    ),
  );
}
```

## Functions:
```dart
static Future<void> runAppCommandlineOrGUI({
  Widget? gui,
  Future<void> Function()? afterLoaded,
  bool commandline = true,
  bool closeOnCompleteCommandlineOptionOnly = true,
  Widget placeHolderAfterLoadedRunning = const MaterialApp(home: Scaffold(body: Center(child: CircularProgressIndicator()))),
}) async
  ```
- runs runApp, is a replacment for runApp. Allows running of the app in commandline or GUI mode.
- Parameters: 
    - ```Widget? gui```
        - The gui that will be displayed, only required if ```commandline == false```
    - ```Future<void> Function()? afterLoaded```
        - Function that must be passed if ```commandline == true```
        - This is the code that is run when in commandline mode
    - ```bool commandline = true,```
        - if ```true``` run in commandline mode
            - ```afterLoaded``` must be passed
        - if ```false``` 
            - ```gui``` must be passed
    - ```bool closeOnCompleteCommandlineOptionOnly = true```
        - closes the app when ```afterLoaded``` is done being run
        - Only relevant if in commandline mode
    - ```Widget placeHolderAfterLoadedRunning = const MaterialApp(home: Scaffold(body: Center(child: CircularProgressIndicator())))```
        - widget displayed while afterLoaded is running

```dart
static Future<void> terminalAsOut() async
```
- calls both ```terminalAsStdout``` & ```terminalAsStderr```
```dart
static Future<void> terminalAsStdout() async
```
- Allocates a terminal, and sets the terminal as stdout
  - Makes use of the terminal that launched the application, or open a new terminal if the app was not launched from a terminal
  - if called more that one time, only one terminal will be allocated 

```dart
static Future<void> terminalAsStderr() async
```
- Allocates a terminal, and sets the terminal as stderr
  - Makes use of the terminal that launched the application, or open a new terminal if the app was not launched from a terminal
  - if called more that one time, only one terminal will be allocated 

```dart
static Future<void> stdout(String out) async
```
- sends passed string to stdout
  - uses c++ function
    - ```std::cout```
- must ensure ```terminalAsStdout``` is run before calling the function, otherwise an error will be thrown

```dart
static Future<void> stderr(String out) async
```
- sends passed string to stderr
  - uses c++ function
    - ```std::cerr```
- must ensure ```terminalAsStderr``` is run before calling the function, otherwise an error will be thrown

<br>

## Ref:
https://api.flutter.dev/flutter/material/CircularProgressIndicator-class.html
<br>
https://pub.dev/packages/args

