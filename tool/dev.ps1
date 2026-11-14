#requires -Version 7
# TNT dev-loop helper.
#
# Why this exists: `flutter run -d windows` dies in this workspace with
#   _createDevFS ... PathAccessException: Creation of temporary directory failed,
#   path = 'C:\Users\ADMINI~1\AppData\Local\Temp' (errno = 5)
# The debug app inherits the sandboxed %TEMP% and cannot create dirs there, so
# DevFS never comes up and hot reload is unavailable. Pointing TMP/TEMP at a
# workspace-local dir (writable under the DSH sandbox) restores `flutter run`.
#
# Usage:
#   tool\dev.ps1 run          # desktop hot-reload loop (press r to reload, q to quit)
#   tool\dev.ps1 run-phone    # same for the connected Android device
#   tool\dev.ps1 build-win    # windows debug build
#   tool\dev.ps1 apk          # android debug apk
#   tool\dev.ps1 install      # adb install the last apk
#   tool\dev.ps1 test         # flutter test
#   tool\dev.ps1 analyze      # flutter analyze

$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSScriptRoot
Set-Location $repo

$env:JAVA_HOME        = 'C:\Program Files\Microsoft\jdk-17.0.20.101-hotspot'
$env:ANDROID_HOME     = 'E:\TNT\Android\Sdk'
$env:ANDROID_SDK_ROOT = $env:ANDROID_HOME
$env:GRADLE_USER_HOME = 'E:\TNT\gradle'
$env:PUB_CACHE        = 'E:\TNT\pub-cache'
$env:PATH             = "E:\TNT\flutter\bin;E:\TNT\Android\Sdk\platform-tools;$env:PATH"

# writable, workspace-local temp so the debug app can create its DevFS dirs
$tmp = Join-Path $repo '.tmp'
New-Item -ItemType Directory -Force -Path $tmp | Out-Null
$env:TMP  = $tmp
$env:TEMP = $tmp

$flutter = 'E:\TNT\flutter\bin\flutter.bat'

switch ($args[0]) {
  'run'       { & $flutter run -d windows }
  'run-phone' { & $flutter run -d android }
  'build-win' { & $flutter build windows --debug }
  'apk'       { & $flutter build apk --debug }
  'install'   { & adb install -r 'build\app\outputs\flutter-apk\app-debug.apk' }
  'test'      { & $flutter test }
  'analyze'   { & $flutter analyze }
  default     { Write-Output 'usage: tool\dev.ps1 [run|run-phone|build-win|apk|install|test|analyze]' }
}
