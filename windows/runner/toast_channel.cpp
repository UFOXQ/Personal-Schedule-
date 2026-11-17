#include "toast_channel.h"

#include <flutter/encodable_value.h>
#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>
#include <propsys.h>
#include <propkey.h>
#include <propvarutil.h>
#include <shlobj.h>
#include <shobjidl.h>
#include <winrt/Windows.Data.Xml.Dom.h>
#include <winrt/Windows.UI.Notifications.h>
#include <winrt/base.h>

#include <memory>
#include <string>

namespace {

// 非打包（非 MSIX）的 Win32 程序要发系统 toast，必须有一个带
// AppUserModelID 的开始菜单快捷方式，Windows 才认得这个 AUMID。
constexpr wchar_t kAumid[] = L"Com.TNT.TntApp";
constexpr wchar_t kShortcutName[] = L"TNT.lnk";

std::wstring ExecutablePath() {
  wchar_t buffer[MAX_PATH];
  const DWORD length = ::GetModuleFileNameW(nullptr, buffer, MAX_PATH);
  if (length == 0) {
    return L"";
  }
  return std::wstring(buffer, length);
}

std::wstring ShortcutPath() {
  PWSTR programs = nullptr;
  if (FAILED(::SHGetKnownFolderPath(FOLDERID_Programs, 0, nullptr, &programs))) {
    return L"";
  }
  std::wstring path(programs);
  ::CoTaskMemFree(programs);
  path += L"\\";
  path += kShortcutName;
  return path;
}

// 建（或刷新）开始菜单快捷方式，并把 AppUserModelID 写进它的属性：
// 这一步做成功后，CreateToastNotifier(kAumid) 才不会抛「找不到元素」。
// 失败时把哪一步、哪个 HRESULT 带回去，方便在日志里定位。
bool EnsureShortcut(std::wstring* detail) {
  const std::wstring shortcut = ShortcutPath();
  const std::wstring exe = ExecutablePath();
  if (shortcut.empty()) {
    *detail = L"SHGetKnownFolderPath(FOLDERID_Programs) 为空";
    return false;
  }
  if (exe.empty()) {
    *detail = L"GetModuleFileNameW 为空";
    return false;
  }
  // 每次都重写，而不是「存在就跳过」：exe 位置一变（用户挪了目录、
  // 换了构建产物），旧快捷方式就会指向不存在的路径，toast 会静默失效。
  // 重写一个 1KB 的 lnk 代价可以忽略。

  winrt::com_ptr<IShellLinkW> link;
  HRESULT hr = ::CoCreateInstance(CLSID_ShellLink, nullptr, CLSCTX_INPROC_SERVER,
                                  IID_PPV_ARGS(link.put()));
  if (FAILED(hr)) {
    wchar_t buffer[64];
    swprintf_s(buffer, L"CoCreateInstance=0x%08X", static_cast<unsigned>(hr));
    *detail = buffer;
    return false;
  }
  link->SetPath(exe.c_str());
  link->SetDescription(L"TNT 一天时间轴");
  link->SetIconLocation(exe.c_str(), 0);

  winrt::com_ptr<IPropertyStore> store;
  hr = link->QueryInterface(IID_PPV_ARGS(store.put()));
  if (FAILED(hr)) {
    wchar_t buffer[64];
    swprintf_s(buffer, L"QI(IPropertyStore)=0x%08X", static_cast<unsigned>(hr));
    *detail = buffer;
    return false;
  }
  PROPVARIANT value;
  ::PropVariantInit(&value);
  if (SUCCEEDED(::InitPropVariantFromString(kAumid, &value))) {
    store->SetValue(PKEY_AppUserModel_ID, value);
    ::PropVariantClear(&value);
  }
  store->Commit();

  winrt::com_ptr<IPersistFile> file;
  hr = link->QueryInterface(IID_PPV_ARGS(file.put()));
  if (FAILED(hr)) {
    wchar_t buffer[64];
    swprintf_s(buffer, L"QI(IPersistFile)=0x%08X", static_cast<unsigned>(hr));
    *detail = buffer;
    return false;
  }
  hr = file->Save(shortcut.c_str(), TRUE);
  if (FAILED(hr)) {
    wchar_t buffer[64];
    swprintf_s(buffer, L"IPersistFile::Save=0x%08X", static_cast<unsigned>(hr));
    *detail = buffer;
    return false;
  }
  return true;
}

void ShowToast(const std::wstring& title, const std::wstring& body) {
  using winrt::Windows::Data::Xml::Dom::XmlDocument;
  using winrt::Windows::UI::Notifications::ToastNotification;
  using winrt::Windows::UI::Notifications::ToastNotificationManager;
  using winrt::Windows::UI::Notifications::ToastTemplateType;

  ::SetCurrentProcessExplicitAppUserModelID(kAumid);

  XmlDocument xml = ToastNotificationManager::GetTemplateContent(
      ToastTemplateType::ToastText02);
  auto texts = xml.GetElementsByTagName(L"text");
  if (texts.Length() >= 2) {
    texts.Item(0).AppendChild(xml.CreateTextNode(winrt::hstring(title)));
    texts.Item(1).AppendChild(xml.CreateTextNode(winrt::hstring(body)));
  }

  ToastNotification notification(xml);
  ToastNotificationManager::CreateToastNotifier(winrt::hstring(kAumid))
      .Show(notification);
}

std::wstring ReadString(const flutter::EncodableMap* args, const char* key) {
  if (args == nullptr) {
    return L"";
  }
  const auto it = args->find(flutter::EncodableValue(key));
  if (it == args->end()) {
    return L"";
  }
  const auto* text = std::get_if<std::string>(&it->second);
  if (text == nullptr) {
    return L"";
  }
  const auto wide = winrt::to_hstring(*text);
  return std::wstring(wide.c_str());
}

}  // namespace

void RegisterToastChannel(flutter::FlutterEngine* engine) {
  static std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>>
      channel;

  channel = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
      engine->messenger(), "tnt/toast",
      &flutter::StandardMethodCodec::GetInstance());

  channel->SetMethodCallHandler(
      [](const flutter::MethodCall<flutter::EncodableValue>& call,
         std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>>
             result) {
        if (call.method_name() != "show") {
          result->NotImplemented();
          return;
        }

        const flutter::EncodableMap* args = nullptr;
        if (call.arguments() != nullptr) {
          args = std::get_if<flutter::EncodableMap>(call.arguments());
        }
        std::wstring title = ReadString(args, "title");
        const std::wstring body = ReadString(args, "body");
        if (title.empty()) {
          title = L"TNT";
        }

        try {
          winrt::init_apartment(winrt::apartment_type::single_threaded);
        } catch (...) {
          // 主线程已经 CoInitializeEx 过了，重复初始化会抛，忽略即可
        }

        std::wstring detail;
        if (!EnsureShortcut(&detail)) {
          result->Error("shortcut",
                        winrt::to_string(winrt::hstring(detail.c_str())));
          return;
        }
        try {
          ShowToast(title, body);
          result->Success(flutter::EncodableValue(true));
        } catch (const winrt::hresult_error& error) {
          result->Error("toast", winrt::to_string(error.message()),
                        flutter::EncodableValue(
                            static_cast<int>(error.code())));
        } catch (...) {
          result->Error("toast", "未知错误");
        }
      });
}
