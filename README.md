# Commandline or GUI Windows
### This plugin allows you to run a flutter windows app in gui mode. 

<br>

## Modifications Required to make use of this plugin:
### **Use at your own risk**
All files that need to be modified will be located in the ```C:\path_to_your_project\windows\runner``` folder
- ```main.cpp```
  - tell linker that this app uses the console subsystem
    - ```#pragma comment(linker, "/subsystem:console")```
  - create a function that hides the gui or console based on passed arguments
    - this required changes to other files listed below
  - change main from ```int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev, _In_ wchar_t *command_line, _In_ int show_command)``` to ```int main(int argc, char *argv[])```
    - remove ```::AttachConsole(ATTACH_PARENT_PROCESS)```, because console provided by OS
  - ensure args are ascii, and not utf-8, unless you change the code to use utf-8
    - ```std::vector<std::string>(argv, argv + argc)```
  - Example:
```cpp
#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>

#include "flutter_window.h"
#include "utils.h"

// ******* ADDED *******
#include "win32_window.h"                     // where flag to hide gui is added
#pragma comment(linker, "/subsystem:console") // tells the linker to use console subsystem

/*
  Function that takes a single flag that if found hides the gui or console
  could be modified to check for more than one flag
*/
void H_hideWindowOnStart(std::vector<std::string> args, std::string flag)
{

  // if there are args look at all to see if match passed flag
  // if match, break, and found = true
  bool found = false;
  if (!args.empty())
  {
    for (std::string i : args)
    {
      if (i == flag)
      {
        found = true;
        break;
      }
    }
  }

  // if found set flag to hide gui, otherwise hide console
  if (found)
  {
    H_HIDE_WINDOW = true;
  }
  else
  {
    ::ShowWindow(::GetConsoleWindow(), SW_HIDE);
  }
}

/*
  New main, because the app is now a console app
*/
int main(int argc, char *argv[])
{

  // call to app that will hide the console, or set the flag to hide the gui
  // H_hideWindowOnStart(std::move(GetCommandLineArguments()), "-a");
  H_hideWindowOnStart(std::vector<std::string>(argv, argv + argc), "-a"); // convert to vector, don't use GetCommandLineArguments unless using utf-8

  // Initialize COM, so that it is available for use in the library and/or
  // plugins.
  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  flutter::DartProject project(L"data");

  std::vector<std::string> command_line_arguments =
      GetCommandLineArguments();

  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  FlutterWindow window(project);
  Win32Window::Point origin(10, 10);
  Win32Window::Size size(1280, 720);
  // change string to show a different title
  if (!window.CreateAndShow(L"commandline_or_gui_windows_example", origin, size))
  {
    return EXIT_FAILURE;
  }
  window.SetQuitOnClose(true);

  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0))
  {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  ::CoUninitialize();
  return EXIT_SUCCESS;
}
```
- ```win32_window.h```
  - Add the flag to hide or show the gui
  - In the example, I only add ```extern bool H_HIDE_WINDOW;``` to the file
  - Example:
```cpp
#ifndef RUNNER_WIN32_WINDOW_H_
#define RUNNER_WIN32_WINDOW_H_

#include <windows.h>

#include <functional>
#include <memory>
#include <string>

// ******* ADDED *******
extern bool H_HIDE_WINDOW;

// see example for full code. The below code is not modified for this plugin to work
```
- ```win32_window.cpp```
  - Add default value of flag to hide gui ```bool H_HIDE_WINDOW = false;```
  - Change ```CreateWindow``` to hide or show gui based on flag
```cpp
#include "win32_window.h"

#include <flutter_windows.h>

#include "resource.h"

// ******* ADDED *******
bool H_HIDE_WINDOW = false;

namespace
{

  constexpr const wchar_t kWindowClassName[] = L"FLUTTER_RUNNER_WIN32_WINDOW";

  // The number of Win32Window objects that currently exist.
  static int g_active_window_count = 0;

  using EnableNonClientDpiScaling = BOOL __stdcall(HWND hwnd);

  // Scale helper to convert logical scaler values to physical using passed in
  // scale factor
  int Scale(int source, double scale_factor)
  {
    return static_cast<int>(source * scale_factor);
  }

  // Dynamically loads the |EnableNonClientDpiScaling| from the User32 module.
  // This API is only needed for PerMonitor V1 awareness mode.
  void EnableFullDpiSupportIfAvailable(HWND hwnd)
  {
    HMODULE user32_module = LoadLibraryA("User32.dll");
    if (!user32_module)
    {
      return;
    }
    auto enable_non_client_dpi_scaling =
        reinterpret_cast<EnableNonClientDpiScaling *>(
            GetProcAddress(user32_module, "EnableNonClientDpiScaling"));
    if (enable_non_client_dpi_scaling != nullptr)
    {
      enable_non_client_dpi_scaling(hwnd);
      FreeLibrary(user32_module);
    }
  }

} // namespace

// Manages the Win32Window's window class registration.
class WindowClassRegistrar
{
public:
  ~WindowClassRegistrar() = default;

  // Returns the singleton registar instance.
  static WindowClassRegistrar *GetInstance()
  {
    if (!instance_)
    {
      instance_ = new WindowClassRegistrar();
    }
    return instance_;
  }

  // Returns the name of the window class, registering the class if it hasn't
  // previously been registered.
  const wchar_t *GetWindowClass();

  // Unregisters the window class. Should only be called if there are no
  // instances of the window.
  void UnregisterWindowClass();

private:
  WindowClassRegistrar() = default;

  static WindowClassRegistrar *instance_;

  bool class_registered_ = false;
};

WindowClassRegistrar *WindowClassRegistrar::instance_ = nullptr;

const wchar_t *WindowClassRegistrar::GetWindowClass()
{
  if (!class_registered_)
  {
    WNDCLASS window_class{};
    window_class.hCursor = LoadCursor(nullptr, IDC_ARROW);
    window_class.lpszClassName = kWindowClassName;
    window_class.style = CS_HREDRAW | CS_VREDRAW;
    window_class.cbClsExtra = 0;
    window_class.cbWndExtra = 0;
    window_class.hInstance = GetModuleHandle(nullptr);
    window_class.hIcon =
        LoadIcon(window_class.hInstance, MAKEINTRESOURCE(IDI_APP_ICON));
    window_class.hbrBackground = 0;
    window_class.lpszMenuName = nullptr;
    window_class.lpfnWndProc = Win32Window::WndProc;
    RegisterClass(&window_class);
    class_registered_ = true;
  }
  return kWindowClassName;
}

void WindowClassRegistrar::UnregisterWindowClass()
{
  UnregisterClass(kWindowClassName, nullptr);
  class_registered_ = false;
}

Win32Window::Win32Window()
{
  ++g_active_window_count;
}

Win32Window::~Win32Window()
{
  --g_active_window_count;
  Destroy();
}

bool Win32Window::CreateAndShow(const std::wstring &title,
                                const Point &origin,
                                const Size &size)
{
  Destroy();

  const wchar_t *window_class =
      WindowClassRegistrar::GetInstance()->GetWindowClass();

  const POINT target_point = {static_cast<LONG>(origin.x),
                              static_cast<LONG>(origin.y)};
  HMONITOR monitor = MonitorFromPoint(target_point, MONITOR_DEFAULTTONEAREST);
  UINT dpi = FlutterDesktopGetDpiForMonitor(monitor);
  double scale_factor = dpi / 96.0;

  /*
  // original
    HWND window = CreateWindow(
        window_class, title.c_str(), WS_OVERLAPPEDWINDOW | WS_VISIBLE,
        Scale(origin.x, scale_factor), Scale(origin.y, scale_factor),
        Scale(size.width, scale_factor), Scale(size.height, scale_factor),
        nullptr, nullptr, GetModuleHandle(nullptr), this);
  */
  // ******* ADDED *******
  HWND window;
  if (H_HIDE_WINDOW)
  {
    window = CreateWindow(
        window_class, title.c_str(), WS_MINIMIZE,
        Scale(origin.x, scale_factor), Scale(origin.y, scale_factor),
        Scale(size.width, scale_factor), Scale(size.height, scale_factor),
        nullptr, nullptr, GetModuleHandle(nullptr), this);

    ShowWindow(window, SW_HIDE);
  }
  else
  {
    window = CreateWindow(
        window_class, title.c_str(), WS_OVERLAPPEDWINDOW | WS_VISIBLE,
        Scale(origin.x, scale_factor), Scale(origin.y, scale_factor),
        Scale(size.width, scale_factor), Scale(size.height, scale_factor),
        nullptr, nullptr, GetModuleHandle(nullptr), this);
  }
  // ******* ADDED *******

  if (!window)
  {
    return false;
  }

  return OnCreate();
}

// static
LRESULT CALLBACK Win32Window::WndProc(HWND const window,
                                      UINT const message,
                                      WPARAM const wparam,
                                      LPARAM const lparam) noexcept
{
  if (message == WM_NCCREATE)
  {
    auto window_struct = reinterpret_cast<CREATESTRUCT *>(lparam);
    SetWindowLongPtr(window, GWLP_USERDATA,
                     reinterpret_cast<LONG_PTR>(window_struct->lpCreateParams));

    auto that = static_cast<Win32Window *>(window_struct->lpCreateParams);
    EnableFullDpiSupportIfAvailable(window);
    that->window_handle_ = window;
  }
  else if (Win32Window *that = GetThisFromHandle(window))
  {
    return that->MessageHandler(window, message, wparam, lparam);
  }

  return DefWindowProc(window, message, wparam, lparam);
}

LRESULT
Win32Window::MessageHandler(HWND hwnd,
                            UINT const message,
                            WPARAM const wparam,
                            LPARAM const lparam) noexcept
{
  switch (message)
  {
  case WM_DESTROY:
    window_handle_ = nullptr;
    Destroy();
    if (quit_on_close_)
    {
      PostQuitMessage(0);
    }
    return 0;

  case WM_DPICHANGED:
  {
    auto newRectSize = reinterpret_cast<RECT *>(lparam);
    LONG newWidth = newRectSize->right - newRectSize->left;
    LONG newHeight = newRectSize->bottom - newRectSize->top;

    SetWindowPos(hwnd, nullptr, newRectSize->left, newRectSize->top, newWidth,
                 newHeight, SWP_NOZORDER | SWP_NOACTIVATE);

    return 0;
  }
  case WM_SIZE:
  {
    RECT rect = GetClientArea();
    if (child_content_ != nullptr)
    {
      // Size and position the child window.
      MoveWindow(child_content_, rect.left, rect.top, rect.right - rect.left,
                 rect.bottom - rect.top, TRUE);
    }
    return 0;
  }

  case WM_ACTIVATE:
    if (child_content_ != nullptr)
    {
      SetFocus(child_content_);
    }
    return 0;
  }

  return DefWindowProc(window_handle_, message, wparam, lparam);
}

void Win32Window::Destroy()
{
  OnDestroy();

  if (window_handle_)
  {
    DestroyWindow(window_handle_);
    window_handle_ = nullptr;
  }
  if (g_active_window_count == 0)
  {
    WindowClassRegistrar::GetInstance()->UnregisterWindowClass();
  }
}

Win32Window *Win32Window::GetThisFromHandle(HWND const window) noexcept
{
  return reinterpret_cast<Win32Window *>(
      GetWindowLongPtr(window, GWLP_USERDATA));
}

void Win32Window::SetChildContent(HWND content)
{
  child_content_ = content;
  SetParent(content, window_handle_);
  RECT frame = GetClientArea();

  MoveWindow(content, frame.left, frame.top, frame.right - frame.left,
             frame.bottom - frame.top, true);

  SetFocus(child_content_);
}

RECT Win32Window::GetClientArea()
{
  RECT frame;
  GetClientRect(window_handle_, &frame);
  return frame;
}

HWND Win32Window::GetHandle()
{
  return window_handle_;
}

void Win32Window::SetQuitOnClose(bool quit_on_close)
{
  quit_on_close_ = quit_on_close;
}

bool Win32Window::OnCreate()
{
  // No-op; provided for subclasses.
  return true;
}

void Win32Window::OnDestroy()
{
  // No-op; provided for subclasses.
}

```

## Notes:
- ***Windows Only*** 
- If in commandline mode, commandline output is supposed to be sent to the stdout/stderr of the shell that ran the app.
- A GUI window opens when in commandline mode while the app is running
    - If the steps above were followed the gui should be hidden when running in commandline mode
    - this does not effect where the output goes when running in commandline mode
    - program closes on completion, and so does the gui
    - cannot remove GUI for now in the plugin, because the plugin requires flutter to be run
        - flutter requires the GUI, and there isn't currently an easy way (I know of) of closing the window, and making use of dart/flutter
    - by default a centered [CircularProgressIndicator](https://api.flutter.dev/flutter/material/CircularProgressIndicator-class.html) is displayed while the GUI is open
        - you can set a widget to display using the ```placeHolderAfterLoadedRunning``` parameter in the ```CommandlineOrGuiWindows.runAppCommandlineOrGUI``` function
        - if the above steps were followed then the gui should be hidden when running in commandline mode (requires ```-a``` passed)

<br>

## Please Post Questions on StackOverflow, and tag @CatTrain (user:16200950)
https://stackoverflow.com/

## Importing:
### YAML:
```yaml
dependencies:
    commandline_or_gui_windows: ^1.2.0
```
### Dart:
```dart
import 'package:commandline_or_gui_windows/commandline_or_gui_windows.dart';
```

<br>

## Example - Commandline Only:
Note that ```commandline``` is ```true``` (default value). The app will exit once ```afterLoaded``` is done running, unless ```closeOnCompleteCommandlineOptionOnly``` is passed as ```false``` (default ```true```). ```-a``` must be passed if the above C++ modifications are made.
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
Note that ```commandline``` is ```false```.
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
This example uses [args.dart package](https://pub.dev/packages/args). ```-a``` must be passed if the above C++ modifications are made, and you wish to run in commandline mode.
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

  bool errors = false;
  bool commandlineMode = false;
  try {
    ArgResults results = parser.parse(args);
    commandlineMode = results["automation"];
  } catch (err) {
    /* ignore parsing errors, and load in gui mode */
    errors = true;
  }

  // part of plugin, main entry. This runciton runs runApp
  await CommandlineOrGuiWindows.runAppCommandlineOrGUI(
    // if you want to run in gui or commandline mode
    commandline: commandlineMode, // parsed option from above

    // code you want to run if in commandline mode
    afterLoaded: () async {
      await CommandlineOrGuiWindows.stdout("Hello World");
      await CommandlineOrGuiWindows.stderr("I broke nooooooo");
    },

    // gui of the app
    gui: MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text("This is the gui of the app. Error detected: $errors"),
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
  int commandlineExitSuccesCode = 0,
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
    - ```int commandlineExitSuccesCode = 0```
        - exit code that is sent when the app exits in commandline mode successfully
    - ```Widget placeHolderAfterLoadedRunning = const MaterialApp(home: Scaffold(body: Center(child: CircularProgressIndicator())))```
        - widget displayed while afterLoaded is running

```dart
static Future<void> stdout(String out) async
```
- sends passed string to stdout
  - uses c++ function
    - ```std::cout << your_string << std::endl;```

```dart
static Future<void> stderr(String out) async
```
- sends passed string to stderr
  - uses c++ function
    - ```std::cerr << your_string << std::endl;``` 

```dart
static Future<void> hideWindow(String out) async
```
- Hides the gui
  - gui still exists, but user can't see it or interact with it

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

