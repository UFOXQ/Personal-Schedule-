# TNT 一键构建：analyze → test → APK（arm64/armv7）→ Windows zip → dist/
#
# 用法：
#   pwsh -File tool/build.ps1
#   pwsh -File tool/build.ps1 -SkipTest
#   pwsh -File tool/build.ps1 -WindowsOnly
#
# 环境变量（缺省时按本机 E:\TNT 布局猜）：
#   FLUTTER_ROOT / ANDROID_HOME / JAVA_HOME

[CmdletBinding()]
param(
    [switch]$SkipTest,
    [switch]$WindowsOnly,
    [switch]$AndroidOnly
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $root

function Resolve-Tool($name, $fallback) {
    $cmd = Get-Command $name -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }
    if ($fallback -and (Test-Path $fallback)) { return $fallback }
    throw "找不到 $name，请先装好并加入 PATH（或设置环境变量）"
}

$flutter = Resolve-Tool 'flutter' 'E:\TNT\flutter\bin\flutter.bat'
if (-not $env:ANDROID_HOME -and (Test-Path 'E:\TNT\Android\Sdk')) { $env:ANDROID_HOME = 'E:\TNT\Android\Sdk' }
if ($env:ANDROID_HOME) { $env:ANDROID_SDK_ROOT = $env:ANDROID_HOME }
if (-not $env:JAVA_HOME -and (Test-Path 'C:\Program Files\Microsoft\jdk-17.0.20.101-hotspot')) {
    $env:JAVA_HOME = 'C:\Program Files\Microsoft\jdk-17.0.20.101-hotspot'
}
if (-not $env:GRADLE_USER_HOME -and (Test-Path 'E:\TNT\gradle')) { $env:GRADLE_USER_HOME = 'E:\TNT\gradle' }
if (-not $env:PUB_CACHE -and (Test-Path 'E:\TNT\pub-cache')) { $env:PUB_CACHE = 'E:\TNT\pub-cache' }

# 版本号从 pubspec.yaml 读
$versionLine = Select-String -Path 'pubspec.yaml' -Pattern '^version:\s*(.+)$' | Select-Object -First 1
$version = ($versionLine.Matches[0].Groups[1].Value -split '\+')[0]
Write-Host "==> TNT v$version" -ForegroundColor Cyan

$dist = Join-Path $root 'dist'
New-Item -ItemType Directory -Force -Path $dist | Out-Null

Write-Host '==> flutter pub get' -ForegroundColor Cyan
& $flutter pub get | Out-Null

Write-Host '==> flutter analyze' -ForegroundColor Cyan
& $flutter analyze
if ($LASTEXITCODE -ne 0) { throw 'analyze 失败' }

if (-not $SkipTest) {
    Write-Host '==> flutter test' -ForegroundColor Cyan
    & $flutter test
    if ($LASTEXITCODE -ne 0) { throw 'test 失败' }
}

if (-not $WindowsOnly) {
    Write-Host '==> flutter build apk --release --split-per-abi' -ForegroundColor Cyan
    & $flutter build apk --release --split-per-abi
    if ($LASTEXITCODE -ne 0) { throw 'APK 构建失败' }

    $apkDir = Join-Path $root 'build\app\outputs\flutter-apk'
    Copy-Item "$apkDir\app-arm64-v8a-release.apk" (Join-Path $dist "tnt-$version-arm64-release.apk") -Force
    Copy-Item "$apkDir\app-armeabi-v7a-release.apk" (Join-Path $dist "tnt-$version-armv7-release.apk") -Force
}

if (-not $AndroidOnly) {
    Write-Host '==> flutter build windows --release' -ForegroundColor Cyan
    & $flutter build windows --release
    if ($LASTEXITCODE -ne 0) { throw 'Windows 构建失败' }

    $winDir = Join-Path $root 'build\windows\x64\runner\Release'
    $zip = Join-Path $dist "tnt-$version-windows-x64.zip"
    if (Test-Path $zip) { Remove-Item $zip -Force }
    Compress-Archive -Path "$winDir\*" -DestinationPath $zip
}

Write-Host ''
Write-Host '==> 产物' -ForegroundColor Green
Get-ChildItem $dist -Filter "*$version*" | ForEach-Object { "  $($_.Name)  $([math]::Round($_.Length / 1MB, 1)) MB" }
