Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

$upstreamRepository = 'qqxpee/antigravity2-cn'
$tempRoot = $null
$locationPushed = $false
$originalInputEncoding = $null
$originalOutputEncoding = $null
$originalPowerShellOutputEncoding = $null
$originalCodePage = $null
$caughtError = $null

function Write-Banner {
    Write-Host ''
    Write-Host '  +==================================================+' -ForegroundColor DarkCyan
    Write-Host '  |' -NoNewline -ForegroundColor DarkCyan
    Write-Host '       Antigravity 2.0 語言助手 / 语言助手       ' -NoNewline -ForegroundColor Cyan
    Write-Host '|' -ForegroundColor DarkCyan
    Write-Host '  +==================================================+' -ForegroundColor DarkCyan
    Write-Host ''
}

function Write-MenuOption {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Key,

        [Parameter(Mandatory = $true)]
        [string]$Text,

        [ConsoleColor]$Color = [ConsoleColor]::White
    )

    Write-Host '    [' -NoNewline -ForegroundColor DarkGray
    Write-Host $Key -NoNewline -ForegroundColor Yellow
    Write-Host '] ' -NoNewline -ForegroundColor DarkGray
    Write-Host $Text -ForegroundColor $Color
}

function Write-Step {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Text
    )

    Write-Host '[>] ' -NoNewline -ForegroundColor Cyan
    Write-Host $Text -ForegroundColor White
}

function Get-CommandVersion {
    param(
        [Parameter(Mandatory = $true)]
        $Command
    )

    try {
        $versionOutput = @(& $Command.Path --version 2>$null)
        if ($LASTEXITCODE -ne 0 -or $versionOutput.Count -eq 0) {
            return $null
        }
        return ([string]$versionOutput[0]).Trim()
    }
    catch {
        return $null
    }
}

function Show-ManualNodeInstall {
    Write-Host ''
    Write-Host '    請手動安裝 Node.js LTS / 请手动安装 Node.js LTS：' -ForegroundColor Yellow
    Write-Host '    https://nodejs.org/' -ForegroundColor Cyan
    Write-Host ''
    Write-Host '    安裝完成後，請關閉此視窗並重新執行本腳本。' -ForegroundColor Yellow
    Write-Host '    安装完成后，请关闭此窗口并重新运行本脚本。' -ForegroundColor Yellow
}

function Invoke-NodeLtsInstall {
    param(
        [switch]$Force
    )

    $wingetCommand = Get-Command 'winget.exe' -ErrorAction SilentlyContinue
    if (-not $wingetCommand) {
        $wingetCommand = Get-Command 'winget' -ErrorAction SilentlyContinue
    }

    if (-not $wingetCommand) {
        Write-Host ''
        Write-Host '    [!] 找不到 winget，無法自動安裝。 / 找不到 winget，无法自动安装。' -ForegroundColor Yellow
        Show-ManualNodeInstall
        return $false
    }

    $installArguments = @(
        'install',
        '-e',
        '--id', 'OpenJS.NodeJS.LTS',
        '--source', 'winget',
        '--accept-package-agreements',
        '--accept-source-agreements'
    )
    if ($Force) {
        $installArguments += '--force'
    }

    Write-Host ''
    Write-Host '  Node.js LTS 安裝 / 安装' -ForegroundColor Magenta
    Write-Host ''
    Write-Host '    即將執行 / 即将执行：' -ForegroundColor DarkGray
    Write-Host ('    winget ' + ($installArguments -join ' ')) -ForegroundColor Cyan
    Write-Host ''
    Write-MenuOption -Key '1' -Text '確認安裝 / 确认安装' -Color Green
    Write-MenuOption -Key '0' -Text '取消' -Color DarkGray
    Write-Host ''

    while ($true) {
        $choice = Read-Host '請選擇 / 请选择 [1/0]'
        switch ($choice) {
            '1' {
                Write-Host ''
                Write-Step '正在透過 winget 安裝 Node.js LTS...'
                & $wingetCommand.Path @installArguments | Out-Host
                $wingetExitCode = $LASTEXITCODE

                if ($wingetExitCode -eq 0) {
                    Write-Host ''
                    Write-Host '[OK] Node.js LTS 安裝命令已完成。' -ForegroundColor Green
                    Write-Host '[i] 請關閉此視窗，重新開啟 PowerShell，再執行本腳本。' -ForegroundColor Yellow
                    Write-Host '[i] 请关闭此窗口，重新打开 PowerShell，再运行本脚本。' -ForegroundColor Yellow
                    return $true
                }

                Write-Host ''
                Write-Host "[X] winget 安裝失敗，結束代碼：$wingetExitCode" -ForegroundColor Red
                Show-ManualNodeInstall
                return $false
            }
            '0' {
                Write-Host '[i] 已取消 Node.js 安裝。' -ForegroundColor DarkGray
                return $false
            }
            default {
                Write-Host '[!] 選項無效，請輸入 1 或 0。 / 选项无效，请输入 1 或 0。' -ForegroundColor Yellow
            }
        }
    }
}

function Test-NodeEnvironment {
    Write-Host '  環境檢測 / 环境检测' -ForegroundColor Magenta
    Write-Host ''

    $nodeCommand = Get-Command 'node.exe' -ErrorAction SilentlyContinue
    if (-not $nodeCommand) {
        $nodeCommand = Get-Command 'node' -ErrorAction SilentlyContinue
    }
    if (-not $nodeCommand) {
        Write-Host '    [X] Node.js：未安裝 / 未安装' -ForegroundColor Red
        Write-Host '    中文安裝需要 Node.js、npm 與 npx。' -ForegroundColor DarkGray
        [void](Invoke-NodeLtsInstall)
        return $null
    }

    $nodeVersion = Get-CommandVersion -Command $nodeCommand
    if (-not $nodeVersion) {
        Write-Host '    [X] Node.js：無法執行 / 无法运行' -ForegroundColor Red
        Write-Host '    Node.js 環境可能已損壞，建議重新安裝 LTS。' -ForegroundColor Yellow
        [void](Invoke-NodeLtsInstall -Force)
        return $null
    }
    Write-Host '    [OK] ' -NoNewline -ForegroundColor Green
    Write-Host "Node.js：$nodeVersion" -ForegroundColor White

    $npmCommand = Get-Command 'npm.cmd' -ErrorAction SilentlyContinue
    if (-not $npmCommand) {
        $npmCommand = Get-Command 'npm' -ErrorAction SilentlyContinue
    }
    $npmVersion = if ($npmCommand) { Get-CommandVersion -Command $npmCommand } else { $null }
    if ($npmVersion) {
        Write-Host '    [OK] ' -NoNewline -ForegroundColor Green
        Write-Host "npm：v$npmVersion" -ForegroundColor White
    }
    else {
        Write-Host '    [!] npm：未找到' -ForegroundColor Yellow
    }

    $npxCommand = Get-Command 'npx.cmd' -ErrorAction SilentlyContinue
    if (-not $npxCommand) {
        $npxCommand = Get-Command 'npx' -ErrorAction SilentlyContinue
    }
    $npxVersion = if ($npxCommand) { Get-CommandVersion -Command $npxCommand } else { $null }
    if ($npxVersion) {
        Write-Host '    [OK] ' -NoNewline -ForegroundColor Green
        Write-Host "npx：v$npxVersion" -ForegroundColor White
    }
    else {
        Write-Host '    [!] npx：未找到，中文安裝功能將無法使用。' -ForegroundColor Yellow
        $npxCommand = $null
    }

    $minimumNodeVersion = [version]'22.12.0'
    $nodeVersionSupported = $false
    try {
        $parsedNodeVersion = [version]($nodeVersion.TrimStart([char]'v'))
        $nodeVersionSupported = $parsedNodeVersion -ge $minimumNodeVersion
    }
    catch {
        Write-Host '    [!] 無法判斷 Node.js 版本是否符合需求。' -ForegroundColor Yellow
    }

    if (-not $nodeVersionSupported) {
        Write-Host "    [!] 中文安裝目前需要 Node.js $minimumNodeVersion 或更新版本。" -ForegroundColor Yellow
    }

    Write-Host ''
    return [PSCustomObject]@{
        Node = $nodeCommand
        Npx = $npxCommand
        VersionSupported = $nodeVersionSupported
    }
}

function Wait-BeforeExit {
    Write-Host ''
    Write-Host '  ----------------------------------------------------' -ForegroundColor DarkGray
    Write-Host '  按任意鍵結束 / 按任意键结束' -ForegroundColor DarkGray
    try {
        if ($Host.Name -eq 'ConsoleHost') {
            [void]$Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
        }
        else {
            [void](Read-Host)
        }
    }
    catch {
        try {
            & cmd.exe /d /c pause | Out-Null
        }
        catch {
            # No interactive console is available.
        }
    }
}

function Initialize-Utf8Console {
    $savedCodePage = $null
    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    [Console]::InputEncoding = $utf8NoBom
    [Console]::OutputEncoding = $utf8NoBom
    $global:OutputEncoding = $utf8NoBom

    if ($env:OS -eq 'Windows_NT') {
        $codePageText = (& chcp.com) -join ' '
        $codePageMatch = [regex]::Match($codePageText, '\d+')
        if ($codePageMatch.Success) {
            $savedCodePage = $codePageMatch.Value
        }
        & chcp.com 65001 | Out-Null
    }

    return $savedCodePage
}

function Select-Language {
    Write-Host '  請選擇操作 / 请选择操作' -ForegroundColor Magenta
    Write-Host ''
    Write-MenuOption -Key '1' -Text '安裝 繁體中文' -Color Green
    Write-MenuOption -Key '2' -Text '安装 简体中文' -Color Green
    Write-MenuOption -Key '3' -Text '還原官方English / 恢复官方English' -Color Cyan
    Write-MenuOption -Key '0' -Text '取消' -Color DarkGray
    Write-Host ''

    while ($true) {
        $choice = Read-Host '請選擇 / 请选择 [1/2/3/0]'
        switch ($choice) {
            '1' { return 'zh-TW' }
            '2' { return 'zh-CN' }
            '3' { return 'en' }
            '0' { return $null }
            default {
                Write-Host '[!] ' -NoNewline -ForegroundColor Yellow
                Write-Host '選項無效，請輸入 1、2、3 或 0。 / 选项无效，请输入 1、2、3 或 0。' -ForegroundColor Yellow
            }
        }
    }
}

function Select-BrandTitle {
    param(
        [Parameter(Mandatory = $true)]
        [string]$SelectedLanguage
    )

    Write-Host ''
    if ($SelectedLanguage -eq 'zh-TW') {
        Write-Host '  品牌名稱顯示方式' -ForegroundColor Magenta
        Write-Host ''
        Write-MenuOption -Key '1' -Text '保留英文 Antigravity（建議）' -Color Green
        Write-MenuOption -Key '2' -Text '隱藏品牌名稱'
        Write-MenuOption -Key '3' -Text '顯示中文品牌名稱'
        $prompt = '請選擇 [1/2/3]，預設為 1'
        $invalidMessage = '選項無效，請輸入 1、2 或 3。'
    }
    else {
        Write-Host '  品牌名称显示方式' -ForegroundColor Magenta
        Write-Host ''
        Write-MenuOption -Key '1' -Text '保留英文 Antigravity（推荐）' -Color Green
        Write-MenuOption -Key '2' -Text '隐藏品牌名称'
        Write-MenuOption -Key '3' -Text '显示中文品牌名称'
        $prompt = '请选择 [1/2/3]，默认为 1'
        $invalidMessage = '选项无效，请输入 1、2 或 3。'
    }

    while ($true) {
        $choice = Read-Host $prompt
        switch ($choice) {
            ''  { return 'english' }
            '1' { return 'english' }
            '2' { return 'hidden' }
            '3' { return 'translated' }
            default {
                Write-Host '[!] ' -NoNewline -ForegroundColor Yellow
                Write-Host $invalidMessage -ForegroundColor Yellow
            }
        }
    }
}

function Get-UpstreamPackage {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Destination,

        [Parameter(Mandatory = $true)]
        [string]$Revision,

        [Parameter(Mandatory = $true)]
        [string]$SelectedLanguage
    )

    $archivePath = Join-Path $Destination 'source.zip'
    $extractPath = Join-Path $Destination 'source'
    $archiveUrl = "https://codeload.github.com/$upstreamRepository/zip/$Revision"

    Write-Host ''
    if ($SelectedLanguage -eq 'zh-CN') {
        Write-Step "正在下载 $upstreamRepository（$Revision）..."
    }
    elseif ($SelectedLanguage -eq 'en') {
        Write-Step "正在下載還原元件 $upstreamRepository（$Revision）..."
    }
    else {
        Write-Step "正在下載 $upstreamRepository（$Revision）..."
    }

    $oldProgressPreference = $ProgressPreference
    $ProgressPreference = 'SilentlyContinue'
    try {
        $request = @{
            Uri = $archiveUrl
            OutFile = $archivePath
            ErrorAction = 'Stop'
        }
        if ($PSVersionTable.PSVersion.Major -lt 6) {
            $request['UseBasicParsing'] = $true
        }
        Invoke-WebRequest @request
    }
    finally {
        $ProgressPreference = $oldProgressPreference
    }

    Expand-Archive -LiteralPath $archivePath -DestinationPath $extractPath -Force

    $engines = @(Get-ChildItem -LiteralPath $extractPath -Filter 'localization_engine.js' -File -Recurse)
    if ($engines.Count -ne 1) {
        throw "下載內容無效：預期包含一個 localization_engine.js，實際找到 $($engines.Count) 個。"
    }

    return $engines[0].Directory.FullName
}

try {
    $originalInputEncoding = [Console]::InputEncoding
    $originalOutputEncoding = [Console]::OutputEncoding
    $originalPowerShellOutputEncoding = $global:OutputEncoding
    $originalCodePage = Initialize-Utf8Console

    if ($env:OS -ne 'Windows_NT') {
        throw 'This helper currently supports Windows only.'
    }

    Write-Banner
    $nodeEnvironment = Test-NodeEnvironment
    if (-not $nodeEnvironment) {
        return
    }
    $nodeCommand = $nodeEnvironment.Node
    $npxCommand = $nodeEnvironment.Npx

    $Language = Select-Language
    if (-not $Language) {
        Write-Host ''
        Write-Host '[i] 已取消。' -ForegroundColor DarkGray
        return
    }

    $BrandTitle = 'english'
    if ($Language -ne 'en') {
        $BrandTitle = Select-BrandTitle -SelectedLanguage $Language
    }

    if ($Language -ne 'en') {
        if (-not $nodeEnvironment.VersionSupported) {
            Write-Host ''
            Write-Host '[!] Node.js 版本過舊，無法執行目前的 ASAR 工具。' -ForegroundColor Yellow
            [void](Invoke-NodeLtsInstall -Force)
            return
        }
        if (-not $npxCommand) {
            Write-Host ''
            Write-Host '[!] npm/npx 環境不完整，建議重新安裝 Node.js LTS。' -ForegroundColor Yellow
            [void](Invoke-NodeLtsInstall -Force)
            return
        }
    }

    if ($PSVersionTable.PSVersion.Major -lt 6) {
        [Net.ServicePointManager]::SecurityProtocol =
            [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
    }

    $tempRoot = Join-Path ([IO.Path]::GetTempPath()) ('antigravity2-lang-' + [Guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Path $tempRoot | Out-Null
    $packageRoot = Get-UpstreamPackage -Destination $tempRoot -Revision 'main' -SelectedLanguage $Language

    $requiredDictionary = if ($Language -eq 'zh-TW') { 'dicts_tw' } else { 'dicts' }
    if ($Language -ne 'en' -and -not (Test-Path -LiteralPath (Join-Path $packageRoot $requiredDictionary) -PathType Container)) {
        throw "下載內容缺少 $requiredDictionary 詞典目錄。"
    }

    $enginePath = Join-Path $packageRoot 'localization_engine.js'
    $engineArguments = @($enginePath)

    switch ($Language) {
        'zh-TW' {
            $engineArguments += '--tw'
            $engineArguments += '--brand-title'
            $engineArguments += $BrandTitle
        }
        'zh-CN' {
            $engineArguments += '--brand-title'
            $engineArguments += $BrandTitle
        }
        'en' {
            $engineArguments += '--huifu'
        }
    }

    Push-Location $packageRoot
    $locationPushed = $true
    try {
        & $nodeCommand.Path @engineArguments
        $engineExitCode = $LASTEXITCODE
    }
    finally {
        Pop-Location
        $locationPushed = $false
    }

    if ($engineExitCode -ne 0) {
        throw "上游語言引擎執行失敗，結束代碼：$engineExitCode。"
    }

    Write-Host ''
    switch ($Language) {
        'zh-TW' { Write-Host '[OK] 繁體中文安裝完成。' -ForegroundColor Green }
        'zh-CN' { Write-Host '[OK] 简体中文安装完成。' -ForegroundColor Green }
        'en'    { Write-Host '[OK] 官方英文還原完成。' -ForegroundColor Green }
    }
}
catch {
    $caughtError = $_
    Write-Host ''
    Write-Host '[X] ' -NoNewline -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
}
finally {
    if ($locationPushed) {
        Pop-Location
    }

    if ($tempRoot -and (Test-Path -LiteralPath $tempRoot)) {
        Remove-Item -LiteralPath $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
    }

    try {
        if ($env:OS -eq 'Windows_NT' -and $originalCodePage) {
            & chcp.com $originalCodePage | Out-Null
        }
        if ($originalInputEncoding) {
            [Console]::InputEncoding = $originalInputEncoding
        }
        if ($originalOutputEncoding) {
            [Console]::OutputEncoding = $originalOutputEncoding
        }
        if ($originalPowerShellOutputEncoding) {
            $global:OutputEncoding = $originalPowerShellOutputEncoding
        }
    }
    catch {
        # Console restoration must not skip the final pause.
    }
    finally {
        Wait-BeforeExit
    }
}

if ($caughtError) {
    throw $caughtError
}
