<#
.SYNOPSIS
    Xem tình trạng server Chi tiêu: file .env, Docker, container, server trong máy, ngrok, Internet, Telegram, log.

.PARAMETER Lines
    Số dòng log cuối của mỗi dịch vụ (mặc định 20, 0 = không in log).

.EXAMPLE
    Nháy đúp scripts\windows\status.cmd
#>
[CmdletBinding()]
param(
    [ValidateRange(0, 500)][int]$Lines = 20
)

$ErrorActionPreference = 'Stop'
. (Join-Path (Join-Path $PSScriptRoot 'lib') 'common.ps1')
Initialize-Console

$Root = Get-RepoRoot
$EnvPath = Join-Path $Root '.env'
$Problems = New-Object System.Collections.Generic.List[string]

function Add-Problem([string]$Text) {
    $Problems.Add($Text)
    Write-Fail $Text
}

# docker compose ps --format json: bản mới in mỗi container một dòng JSON, bản cũ in một mảng JSON.
function Get-ComposeContainers {
    $r = Invoke-Native 'docker' ((Get-ComposeArgs $Root) + @('--profile', 'ngrok', 'ps', '--all', '--format', 'json'))
    if ($r.ExitCode -ne 0) { return $null }
    $items = @()
    $text = $r.Output.Trim()
    if ($text -eq '') { return , $items }
    if ($text.StartsWith('[')) {
        try { $items = ConvertFrom-JsonList $text } catch { return $null }
    } else {
        foreach ($line in ($text -split "`n")) {
            $l = $line.Trim()
            if (-not $l.StartsWith('{')) { continue }
            try { $items += ($l | ConvertFrom-Json) } catch { Write-Verbose "Bỏ qua dòng: $l" }
        }
    }
    return , $items
}

function Show-Container($Items, [string]$Service, [bool]$Expected) {
    $c = $null
    foreach ($i in $Items) { if ($i.Service -eq $Service) { $c = $i } }
    if ($null -eq $c) {
        if ($Expected) { Add-Problem "${Service}: chưa được tạo. Chạy setup.cmd." }
        else { Write-Info "${Service}: không dùng." }
        return
    }
    $state = [string]$c.State
    $health = ''
    if ($c.PSObject.Properties['Health']) { $health = [string]$c.Health }
    $detail = [string]$c.Status
    if ($state -eq 'running' -and ($health -eq '' -or $health -eq 'healthy' -or $health -eq 'starting')) {
        Write-Ok "${Service}: đang chạy ($detail)"
    } elseif ($state -eq 'restarting') {
        Add-Problem "${Service}: khởi động lại liên tục ($detail), xem log bên dưới."
    } elseif ($state -eq 'running') {
        Add-Problem "${Service}: đang chạy nhưng kiểm tra sức khoẻ báo '$health' ($detail)."
    } else {
        Add-Problem "${Service}: đã dừng ($detail). Chạy setup.cmd hoặc update.cmd để bật lại."
    }
}

Write-Title 'TÌNH TRẠNG SERVER CHI TIÊU'
Write-Info ('Thời điểm: ' + (Get-Date -Format 'HH:mm:ss dd/MM/yyyy') + "   Thư mục: $Root")

# 1. .env
Write-Step '1. File cấu hình .env'
if (-not (Test-Path -LiteralPath $EnvPath)) {
    Write-Fail 'Chưa có file .env. Chạy scripts\windows\setup.cmd trước.'
    exit 1
}
$bom = Get-TextFileBomKind $EnvPath
if ($bom -ne '') { Add-Problem "File .env đang lưu dạng $bom (docker compose có thể đọc lỗi). Chạy setup.cmd để tự sửa." }
$Cfg = Read-DotEnv $EnvPath
$appToken = Get-EnvValue $Cfg 'APP_TOKEN'
$domain = ConvertTo-NgrokDomain (Get-EnvValue $Cfg 'NGROK_DOMAIN')
$useNgrok = (Get-EnvValue $Cfg 'NGROK_AUTHTOKEN') -ne ''
$bot = Get-EnvValue $Cfg 'TELEGRAM_BOT_TOKEN'
$chat = Get-EnvValue $Cfg 'TELEGRAM_CHAT_ID'
if (Test-AppToken $appToken) { Write-Ok 'APP_TOKEN: đã có.' } else { Add-Problem 'APP_TOKEN thiếu hoặc ngắn hơn 32 ký tự: server không chạy được. Chạy setup.cmd.' }
if ((Get-EnvValue $Cfg 'SEPAY_API_KEY') -ne '' -or (Get-EnvValue $Cfg 'SEPAY_HMAC_SECRET') -ne '') { Write-Ok 'Khoá webhook SePay: đã có.' }
else { Add-Problem 'Chưa có SEPAY_API_KEY: server sẽ từ chối webhook SePay. Chạy setup.cmd.' }
if ($useNgrok) { Write-Ok 'ngrok authtoken: đã có.' } else { Add-Problem 'Chưa có NGROK_AUTHTOKEN: server không ra được Internet.' }
if ($domain -ne '') { Write-Ok "Tên miền ngrok: $domain" } elseif ($useNgrok) { Write-Warn 'Chưa ghi NGROK_DOMAIN trong .env (setup.cmd sẽ tự điền).' }
if ($bot -ne '' -and $chat -ne '') { Write-Ok "Telegram: có token bot, Chat ID $chat." }
elseif ($bot -ne '') { Add-Problem 'Telegram: chưa có Chat ID nên chưa gửi được cảnh báo. Chạy setup.cmd.' }
else { Add-Problem 'Telegram: chưa có token bot, không có cảnh báo.' }
if ((Get-EnvValue $Cfg 'IMAP_USER') -ne '') { Write-Ok ('Gmail (IMAP): ' + (Get-EnvValue $Cfg 'IMAP_USER')) } else { Write-Info 'Gmail (IMAP): không dùng.' }

# 2. Docker
Write-Step '2. Docker Desktop'
if ($null -eq (Find-DockerCli)) {
    Write-Fail 'Chưa cài Docker Desktop: https://www.docker.com/products/docker-desktop/'
    exit 1
}
if (-not (Test-DockerEngine)) {
    Write-Fail 'Docker Desktop chưa chạy. Mở Docker Desktop từ menu Start, đợi "Engine running" rồi chạy lại.'
    exit 1
}
Write-Ok 'Docker Desktop đang chạy.'
Write-DockerAutoStartAdvice

# 3. Container
Write-Step '3. Container'
$items = Get-ComposeContainers
if ($null -eq $items) {
    Write-Warn 'Không đọc được danh sách container dạng JSON, in bảng gốc:'
    [void](Invoke-NativeLive 'docker' ((Get-ComposeArgs $Root) + @('--profile', 'ngrok', 'ps', '--all')))
} else {
    Show-Container $items 'app' $true
    Show-Container $items 'ngrok' $useNgrok
}

# 4. Server trong máy
Write-Step '4. Server trong máy'
$local = Get-LocalBaseUrl $Cfg
$r = Invoke-HttpRequest -Url "$local/health" -TimeoutSec 5
if ($r.Status -eq 200) { Write-Ok "$local/health trả lời bình thường." }
else { Add-Problem ("Server trong máy không trả lời ($local/health): " + (Format-HttpProblem $r)) }

if ($r.Status -eq 200 -and (Test-AppToken $appToken)) {
    $s = Invoke-HttpRequest -Url "$local/api/summary" -Headers @{ Authorization = "Bearer $appToken" } -TimeoutSec 15
    if ($s.Status -eq 200) {
        try {
            $sum = $s.Body | ConvertFrom-Json
            $ih = $sum.ingest_health
            Write-Info ('Webhook SePay gần nhất: ' + (Format-LocalTime $ih.sources.sepay.last_event_at))
            if ($ih.sources.email.enabled) { Write-Info ('Đọc Gmail thành công gần nhất: ' + (Format-LocalTime $ih.sources.email.last_success_at)) }
            foreach ($w in @($ih.warnings)) { if ($w) { Write-Warn ([string]$w) } }
            Write-Info ("Số tài khoản trong app: " + @($sum.accounts).Count)
        } catch { Write-Warn 'Không đọc được /api/summary.' }
    } elseif ($s.Status -eq 401) {
        Add-Problem 'Server từ chối APP_TOKEN trong .env: server đang chạy với .env cũ. Chạy setup.cmd (hoặc docker compose up -d).'
    } else {
        Write-Warn ('Không đọc được /api/summary: ' + (Format-HttpProblem $s))
    }
}

# 5. ngrok + Internet
Write-Step '5. ngrok và truy cập từ Internet'
if (-not $useNgrok) {
    Write-Info 'Không dùng ngrok.'
} else {
    $publicUrl = Get-NgrokPublicUrl $Root
    if ($publicUrl) {
        $detected = ([Uri]$publicUrl).Host.ToLowerInvariant()
        Write-Ok "ngrok đã kết nối: https://$detected"
        if ($domain -ne '' -and $domain -ne $detected) {
            Add-Problem "ngrok dùng $detected nhưng .env ghi $domain. SePay/app phải dùng $detected, hoặc sửa NGROK_DOMAIN."
        }
        if ($domain -eq '') { $domain = $detected }
    } else {
        Add-Problem 'ngrok chưa kết nối (xem log ngrok bên dưới: authtoken sai, tên miền sai, mất mạng...).'
    }
    if ($domain -ne '') {
        $p = Invoke-HttpRequest -Url "https://$domain/health" -TimeoutSec 20
        if ($p.Status -eq 200 -and $p.Body -match '"status"') { Write-Ok "Từ Internet gọi được: https://$domain/health" }
        else { Add-Problem ("Từ Internet chưa gọi được https://$domain/health: " + (Format-HttpProblem $p)) }
        Write-Info "URL webhook SePay: https://$domain/webhooks/sepay   Địa chỉ máy chủ (URL) cho app: https://$domain"
    }
}

# 6. Telegram
Write-Step '6. Telegram'
if ($bot -eq '') {
    Write-Info 'Chưa cấu hình.'
} else {
    $info = Get-TelegramBotInfo $bot
    if ($info.Ok) { Write-Ok "Bot @$($info.Username) hoạt động." }
    elseif ($info.Network) {
        # Không tới được api.telegram.org thì server cũng không gửi được cảnh báo nào (không có lỗi nào hiện ra).
        Add-Problem "Không tới được Telegram từ máy này ($($info.Error)): cảnh báo sẽ KHÔNG tới điện thoại."
        Write-Info 'Kiểm tra Internet. Nếu mạng vẫn chạy mà Telegram không vào được (nhà mạng chặn Telegram):'
        Write-Info 'xem tài liệu, mục 13, dòng "Telegram bị chặn". Trong lúc đó, mở app Chi tiêu → Cảnh báo để xem.'
    }
    else { Add-Problem "Telegram từ chối token bot: $($info.Error). Tạo lại token với BotFather rồi nháy đúp doi-cau-hinh.cmd." }
}

# 7. Log
if ($Lines -gt 0) {
    Write-Step "7. Log gần nhất ($Lines dòng mỗi dịch vụ)"
    Show-ComposeLog $Root 'app' $Lines
    if ($useNgrok) { Show-ComposeLog $Root 'ngrok' $Lines }
}

Write-Title 'KẾT LUẬN'
if ($Problems.Count -eq 0) {
    Write-Ok 'Mọi thứ đều ổn.'
    exit 0
}
Write-Fail "Có $($Problems.Count) vấn đề:"
foreach ($p in $Problems) { Write-Info "- $p" }
Write-Info 'Cách xử lý từng lỗi: docs\cai-dat-windows.md, mục "Xử lý sự cố".'
exit 1
