Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

$upstreamRepository = 'qqxpee/antigravity2-cn'
$tempRoot = $null
$locationPushed = $false
$originalInputEncoding = [Console]::InputEncoding
$originalOutputEncoding = [Console]::OutputEncoding
$originalPowerShellOutputEncoding = $global:OutputEncoding
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

function Wait-BeforeExit {
    Write-Host ''
    Write-Host '  ----------------------------------------------------' -ForegroundColor DarkGray
    try {
        [void](Read-Host '  按 Enter 鍵結束 / 按 Enter 键结束')
    }
    catch {
        # Some non-interactive hosts do not support Read-Host.
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
    Write-Banner
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
    $originalCodePage = Initialize-Utf8Console

    if ($env:OS -ne 'Windows_NT') {
        throw 'This helper currently supports Windows only.'
    }

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

    $nodeCommand = Get-Command 'node.exe' -ErrorAction SilentlyContinue
    if (-not $nodeCommand) {
        $nodeCommand = Get-Command 'node' -ErrorAction SilentlyContinue
    }
    if (-not $nodeCommand) {
        throw '找不到 Node.js。請安裝 Node.js LTS，重新開啟 PowerShell 後再執行。'
    }

    if ($Language -ne 'en') {
        $npxCommand = Get-Command 'npx.cmd' -ErrorAction SilentlyContinue
        if (-not $npxCommand) {
            $npxCommand = Get-Command 'npx' -ErrorAction SilentlyContinue
        }
        if (-not $npxCommand) {
            throw '找不到 npx。請修復或重新安裝 Node.js LTS 後再執行。'
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

    if ($env:OS -eq 'Windows_NT' -and $originalCodePage) {
        & chcp.com $originalCodePage | Out-Null
    }
    [Console]::InputEncoding = $originalInputEncoding
    [Console]::OutputEncoding = $originalOutputEncoding
    $global:OutputEncoding = $originalPowerShellOutputEncoding

    Wait-BeforeExit
}

if ($caughtError) {
    throw $caughtError
}
