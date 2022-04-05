#include "include/commandline_or_gui_windows/commandline_or_gui_windows_plugin.h"

// This must be included before many other Windows headers.
#include <windows.h>

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

#include <map>
#include <memory>
#include <sstream>

#include <iostream>
#include <variant>

namespace
{

  using flutter::EncodableList;
  using flutter::EncodableMap;
  using flutter::EncodableValue;

  class CommandlineOrGuiWindowsPlugin : public flutter::Plugin
  {
  public:
    static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

    CommandlineOrGuiWindowsPlugin();

    virtual ~CommandlineOrGuiWindowsPlugin();

  private:
    // Called when a method is called on this plugin's channel from Dart.
    void HandleMethodCall(
        const flutter::MethodCall<flutter::EncodableValue> &method_call,
        std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

    void hideWindow();
  };

  // static
  void CommandlineOrGuiWindowsPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarWindows *registrar)
  {
    auto channel =
        std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
            registrar->messenger(), "commandline_or_gui_windows",
            &flutter::StandardMethodCodec::GetInstance());

    auto plugin = std::make_unique<CommandlineOrGuiWindowsPlugin>();

    channel->SetMethodCallHandler(
        [plugin_pointer = plugin.get()](const auto &call, auto result)
        {
          plugin_pointer->HandleMethodCall(call, std::move(result));
        });

    registrar->AddPlugin(std::move(plugin));
  }

  CommandlineOrGuiWindowsPlugin::CommandlineOrGuiWindowsPlugin() {}

  CommandlineOrGuiWindowsPlugin::~CommandlineOrGuiWindowsPlugin() {}

  void CommandlineOrGuiWindowsPlugin::hideWindow()
  {
    ShowWindow(GetActiveWindow(), SW_HIDE);
  }

  // called by flutter plugin
  void CommandlineOrGuiWindowsPlugin::HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result)
  {

    // get arguments
    const EncodableMap *arguments = std::get_if<EncodableMap>(method_call.arguments());

    // print output to stdout, not to termial if terminal not set as stdout
    if (method_call.method_name().compare("printToTerminal") == 0)
    {
      auto params = arguments->find(EncodableValue("out"));
      std::string mystring = std::get<std::string>(params->second);
      mystring.erase(std::remove(mystring.begin(), mystring.end(), '\r'), mystring.end());
      std::cout << mystring << std::endl;
      result->Success(flutter::EncodableValue("done"));
    }
    // print output to stderr, not to terminal if terminal not set as stderr
    else if (method_call.method_name().compare("printToTerminalError") == 0)
    {
      auto params = arguments->find(EncodableValue("out"));
      std::string mystring = std::get<std::string>(params->second);
      mystring.erase(std::remove(mystring.begin(), mystring.end(), '\r'), mystring.end());
      std::cerr << mystring << std::endl;
      result->Success(flutter::EncodableValue("done"));
    }
    // hide the window(gui)
    else if (method_call.method_name().compare("hideWindow") == 0)
    {
      CommandlineOrGuiWindowsPlugin::hideWindow();
      result->Success(flutter::EncodableValue("done"));
    }
    else
    {
      result->NotImplemented();
    }
  }

} // namespace

void CommandlineOrGuiWindowsPluginRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar)
{
  CommandlineOrGuiWindowsPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
