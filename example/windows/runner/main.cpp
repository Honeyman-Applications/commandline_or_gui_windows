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

/*
// old win32 entry
int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command)
{

  H_hideWindowOnStart(std::move(GetCommandLineArguments()), "-a");

  // this if is removed in the console main, because the OS provides a console
  // Attach to console when present (e.g., 'flutter run') or create a
  // new console when running with a debugger.
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent())
  {
    CreateAndAttachConsole();
  }

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
*/