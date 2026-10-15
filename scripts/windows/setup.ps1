<#
.SYNOPSIS
    Cài đặt (hoặc cài lại) server Chi tiêu trên máy Windows: Docker Desktop + ngrok + Telegram.

.DESCRIPTION
    - Kiểm tra Docker Desktop đã cài và đang chạy (chưa chạy thì mở giúp).
    - Tạo file .env từ .env.example nếu chưa có (UTF-8 không BOM, docker compose đọc được).
    - Tự sinh APP_TOKEN và SEPAY_API_KEY bằng bộ sinh số ngẫu nhiên an toàn của hệ điều hành.
    - Hỏi authtoken + tên miền ngrok, token bot Telegram, (tuỳ chọn) Gmail IMAP. Bí mật nhập vào hiện thành dấu *.
    - Chạy lại bao nhiêu lần cũng được: giá trị đã có được giữ nguyên, trừ khi chạy với -Review và chọn đổi.
      Người dùng không cần gõ -Review: nháy đúp doi-cau-hinh.cmd (gọi setup.ps1 -Review).
    - Chạy "docker compose --profile ngrok up -d --build", chờ server sẵn sàng, lấy Chat ID Telegram,
      rồi chỉ bước tiếp theo (URL webhook SePay, API key, địa chỉ server + APP_TOKEN cho app).

.PARAMETER Review
    Xem lại và cho phép đổi từng giá trị đã có (mặc định chỉ hỏi những giá trị còn thiếu).

.PARAMETER NoStart
    Chỉ tạo/cập nhật file .env, không khởi động Docker.

.EXAMPLE
    Nháy đúp scripts\windows\setup.cmd

.EXAMPLE
    Nháy đúp scripts\windows\doi-cau-hinh.cmd   (giống: setup.ps1 -Review)

.EXAMPLE
    powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\windows\setup.ps1 -Review
#>
[CmdletBinding()]
param(
    [switch]$Review,
    [switch]$NoStart
)

$ErrorActionPreference = 'Stop'
. (Join-Path (Join-Path $PSScriptRoot 'lib') 'common.ps1')
Initialize-Console

$Root = Get-RepoRoot
$EnvPath = Join-Path $Root '.env'
$ExamplePath = Join-Path $Root '.env.example'
$script:Changes = [ordered]@{}
$script:Cfg = @{}
$script:ReviewMode = [bool]$Review
$script:BotUsername = ''
$script:EnvState = 'ok'

function Set-Change([string]$Key, [string]$Value) {
    $script:Changes[$Key] = $Value
    $script:Cfg[$Key] = $Value
}

function Save-Changes {
    if ($script:Changes.Count -eq 0) { return }
    Set-DotEnvValues $EnvPath $script:Changes
    Write-Ok ('Đã lưu vào .env: ' + (@($script:Changes.Keys) -join ', '))
    $script:Changes = [ordered]@{}
}

# Hỏi một giá trị. Đã có giá trị thì giữ nguyên, trừ khi đang ở chế độ -Review và người dùng chọn đổi.
function Request-Setting {
    param(
        [string]$Key,
        [string]$Label,
        [string[]]$Help = @(),
        [string[]]$HelpWhenEmpty = @(),
        [switch]$Secret,
        [switch]$Optional,
        [scriptblock]$Normalize = $null,
        [scriptblock]$Validate = $null,
        [string]$InvalidMessage = 'Giá trị có vẻ không đúng định dạng.',
        [string]$SkipMessage = 'Bỏ qua.'
    )
    $current = Get-EnvValue $script:Cfg $Key
    if ($current -ne '') {
        if ($Secret) { Write-Ok ("${Label}: " + (Format-SecretState $current)) } else { Write-Ok "${Label}: $current" }
        if (-not $script:ReviewMode) { return }
        if (-not (Read-YesNo "       Đổi ${Label}?" $false)) { return }
    }
    foreach ($h in $Help) { Write-Info $h }
    if ($current -eq '') { foreach ($h in $HelpWhenEmpty) { Write-Info $h } }
    $canClear = $Optional -and $current -ne ''
    if ($canClear) { Write-Info "Bấm Enter để giữ giá trị cũ; gõ dấu trừ ( - ) rồi Enter để XOÁ ${Label}." }
    while ($true) {
        if ($Secret) {
            $v = Read-SecretText "       Dán $Label (chuột phải hoặc Ctrl+V; ký tự hiện thành *, Enter để xong)"
        } else {
            $v = ("" + (Read-Host "       Nhập $Label")).Trim()
        }
        if ($canClear -and $v -eq '-') {
            Set-Change $Key ''
            Write-Ok "Đã xoá ${Label}. $SkipMessage"
            return
        }
        if ($null -ne $Normalize) { $v = [string](& $Normalize $v) }
        if ($v -eq '') {
            if ($current -ne '') { Write-Info 'Giữ giá trị cũ.'; return }
            if ($Optional) { Write-Info $SkipMessage; return }
            Write-Warn "$Label là bắt buộc. Nhập lại (hoặc bấm Ctrl+C để dừng)."
            continue
        }
        if ($null -ne $Validate -and -not (& $Validate $v)) {
            Write-Warn $InvalidMessage
            if (-not (Read-YesNo '       Vẫn dùng giá trị này?' $false)) { continue }
        }
        Set-Change $Key $v
        if ($Secret) { Write-Ok "Đã nhận $Label ($($v.Length) ký tự)." } else { Write-Ok "Đã nhận ${Label}: $v" }
        return
    }
}

function Request-AppToken {
    $current = Get-EnvValue $script:Cfg 'APP_TOKEN'
    if (-not (Test-AppToken $current)) {
        if ($current -ne '') { Write-Warn 'APP_TOKEN cũ ngắn hơn 32 ký tự, server sẽ không chạy: tạo khoá mới.' }
        Set-Change 'APP_TOKEN' (New-UrlSafeToken 32)
        Write-Ok 'Đã tạo APP_TOKEN ngẫu nhiên (43 ký tự) để app trên điện thoại đăng nhập server.'
        return
    }
    Write-Ok ('APP_TOKEN: ' + (Format-SecretState $current))
    if ($script:ReviewMode -and (Read-YesNo '       Tạo APP_TOKEN mới? (app trên điện thoại sẽ phải nhập lại)' $false)) {
        Set-Change 'APP_TOKEN' (New-UrlSafeToken 32)
        Write-Ok 'Đã tạo APP_TOKEN mới.'
    }
}

function Request-SepayKey {
    $current = Get-EnvValue $script:Cfg 'SEPAY_API_KEY'
    if ($current -eq '') {
        Set-Change 'SEPAY_API_KEY' (New-HexToken 20)
        Write-Ok 'Đã tạo SEPAY_API_KEY ngẫu nhiên (40 ký tự); bước cuối sẽ chép nó để dán vào trang SePay.'
        return
    }
    Write-Ok ('SEPAY_API_KEY: ' + (Format-SecretState $current))
    if (-not $script:ReviewMode) { return }
    Write-Info 'Chọn: [Enter] giữ nguyên   [d] dán khoá do SePay cấp   [m] tạo khoá ngẫu nhiên mới'
    while ($true) {
        $a = ("" + (Read-Host '       Lựa chọn')).Trim().ToLowerInvariant()
        if ($a -eq '') { return }
        if ($a -eq 'd') {
            $v = Read-SecretText '       Dán API key từ trang SePay'
            if ($v -eq '') { Write-Info 'Giữ giá trị cũ.'; return }
            Set-Change 'SEPAY_API_KEY' $v
            Write-Ok "Đã nhận API key của SePay ($($v.Length) ký tự)."
            return
        }
        if ($a -eq 'm') {
            Set-Change 'SEPAY_API_KEY' (New-HexToken 20)
            Write-Warn 'Đã tạo khoá mới: nhớ dán khoá mới vào webhook trên my.sepay.vn, nếu không SePay sẽ bị từ chối (401).'
            return
        }
        Write-Warn 'Gõ d, m hoặc chỉ bấm Enter.'
    }
}

function Request-TelegramToken {
    $current = Get-EnvValue $script:Cfg 'TELEGRAM_BOT_TOKEN'
    if ($current -ne '') {
        Write-Ok ('Token bot Telegram: ' + (Format-SecretState $current))
        $info = Get-TelegramBotInfo $current
        $invalid = (-not $info.Ok) -and (-not $info.Network)
        if ($info.Ok) { $script:BotUsername = $info.Username; Write-Ok "Bot hợp lệ: @$($info.Username)" }
        elseif ($info.Network) { Write-Warn "Chưa kiểm tra được bot (mạng): $($info.Error)" }
        else { Write-Fail "Telegram từ chối token hiện tại: $($info.Error)" }
        if (-not $script:ReviewMode -and -not $invalid) { return }
        if (-not (Read-YesNo '       Đổi token bot Telegram?' $invalid)) { return }
    } else {
        Write-Info 'Cảnh báo số dư gửi qua Telegram. Tạo bot: mở Telegram, nhắn @BotFather lệnh /newbot,'
        Write-Info 'đặt tên, BotFather trả về token dạng 123456789:AAH... (xem docs\cai-dat-windows.md, bước 3).'
    }
    while ($true) {
        $v = Read-SecretText '       Dán token bot Telegram (Enter để bỏ qua)'
        if ($v -eq '') {
            if ($current -ne '') { Write-Info 'Giữ giá trị cũ.'; return }
            Write-Warn 'Bỏ qua Telegram: server sẽ KHÔNG gửi được cảnh báo. Chạy lại setup khi có token.'
            return
        }
        if (-not (Test-TelegramTokenFormat $v)) {
            Write-Warn 'Token không đúng dạng số:chuỗi (vd. 123456789:AAH...). Chép lại nguyên dòng token từ BotFather.'
            continue
        }
        $info = Get-TelegramBotInfo $v
        if ($info.Ok) {
            $script:BotUsername = $info.Username
            Set-Change 'TELEGRAM_BOT_TOKEN' $v
            Write-Ok "Token hợp lệ, bot của bạn là @$($info.Username)."
            if ($current -ne '' -and $current -ne $v) {
                # Bot mới -> chat id cũ không còn đúng.
                Set-Change 'TELEGRAM_CHAT_ID' ''
            }
            return
        }
        if ($info.Network) {
            Write-Warn "Không kiểm tra được token vì lỗi mạng ($($info.Error)); tạm dùng token này."
            Set-Change 'TELEGRAM_BOT_TOKEN' $v
            return
        }
        Write-Fail "Telegram từ chối token: $($info.Error). Kiểm tra lại token trong BotFather."
    }
}

function Request-ChatIdReview {
    $current = Get-EnvValue $script:Cfg 'TELEGRAM_CHAT_ID'
    if ($current -eq '') { return }
    Write-Ok "Telegram Chat ID: $current"
    if ($script:ReviewMode -and (Read-YesNo '       Lấy lại Chat ID (vd. đổi tài khoản Telegram)?' $false)) {
        Set-Change 'TELEGRAM_CHAT_ID' ''
        Write-Info 'Sẽ hỏi lại Chat ID sau khi server khởi động.'
    }
}

function Request-Imap {
    $user = Get-EnvValue $script:Cfg 'IMAP_USER'
    $pass = Get-EnvValue $script:Cfg 'IMAP_PASSWORD'
    if ($user -ne '' -and $pass -ne '') {
        Write-Ok "Gmail (IMAP, nguồn phụ): $user, mật khẩu ứng dụng $(Format-SecretState $pass)"
        if (-not $script:ReviewMode) { return }
        Write-Info 'Chọn: [Enter] giữ nguyên   [d] đổi Gmail / mật khẩu ứng dụng   [x] tắt đọc email'
        while ($true) {
            $a = ("" + (Read-Host '       Lựa chọn')).Trim().ToLowerInvariant()
            if ($a -eq '') { return }
            if ($a -eq 'x') { Set-Change 'IMAP_USER' ''; Set-Change 'IMAP_PASSWORD' ''; Write-Ok 'Đã tắt đọc email.'; return }
            if ($a -eq 'd') { break }
            Write-Warn 'Gõ d, x hoặc chỉ bấm Enter.'
        }
    } else {
        if (-not ($script:ReviewMode -or $script:EnvState -eq 'created')) {
            Write-Info 'Gmail (IMAP, nguồn phụ): chưa dùng. Muốn thêm: nháy đúp doi-cau-hinh.cmd (xem tài liệu, bước 4).'
            return
        }
        Write-Info 'Email biến động số dư là nguồn PHỤ, không bắt buộc. Lưu ý: chưa tìm thấy Vietcombank hay MB'
        Write-Info 'gửi email biến động số dư cho tài khoản cá nhân, nên nguồn này có thể không nhận được gì.'
        Write-Info 'Chỉ bật khi bạn đã thấy ngân hàng gửi email biến động vào Gmail (xem tài liệu, bước 4).'
        if (-not (Read-YesNo '       Dùng Gmail để đọc email biến động số dư?' $false)) { return }
    }
    while ($true) {
        $u = ("" + (Read-Host '       Địa chỉ Gmail (vd. ten.nganhang@gmail.com)')).Trim()
        if ($u -match '^[^@\s]+@[^@\s]+\.[^@\s]+$') { break }
        Write-Warn 'Địa chỉ email chưa đúng.'
    }
    Write-Info 'Mật khẩu ứng dụng 16 chữ cái tạo ở https://myaccount.google.com/apppasswords (cần bật xác minh 2 bước).'
    while ($true) {
        $p = ConvertTo-AppPassword (Read-SecretText '       Dán mật khẩu ứng dụng (dấu cách sẽ được bỏ)')
        if ($p -eq '') { Write-Warn 'Chưa nhập mật khẩu ứng dụng.'; if (Read-YesNo '       Bỏ qua Gmail?' $true) { return } else { continue } }
        if ($p.Length -ne 16) {
            Write-Warn "Mật khẩu ứng dụng của Google thường có 16 chữ cái, bạn nhập $($p.Length) ký tự."
            if (-not (Read-YesNo '       Vẫn dùng?' $false)) { continue }
        }
        break
    }
    Set-Change 'IMAP_USER' $u
    Set-Change 'IMAP_PASSWORD' $p
    if ((Get-EnvValue $script:Cfg 'IMAP_HOST') -eq '') { Set-Change 'IMAP_HOST' 'imap.gmail.com' }
    Write-Ok "Đã nhận Gmail $u và mật khẩu ứng dụng ($($p.Length) ký tự)."
}

function Request-OwnerName {
    $current = Get-EnvValue $script:Cfg 'OWNER_NAME'
    if ($current -ne '') {
        Write-Ok "Tên chủ tài khoản: $current"
        if (-not ($script:ReviewMode -and (Read-YesNo '       Đổi tên chủ tài khoản?' $false))) { return }
    } elseif (-not ($script:ReviewMode -or $script:EnvState -eq 'created')) {
        return
    }
    Write-Info 'Tên chủ tài khoản giúp nhận ra tiền chuyển qua lại giữa VCB và MB của chính bạn (không tính là chi tiêu).'
    $v = ("" + (Read-Host '       Tên in hoa không dấu như trên thẻ, vd. NGUYEN VAN AN (Enter để bỏ qua)')).Trim()
    if ($v -ne '') { Set-Change 'OWNER_NAME' $v; Write-Ok "Đã nhận tên: $v" }
}

function Invoke-ComposeUp([bool]$UseNgrok, [switch]$Build) {
    $a = Get-ComposeArgs $Root
    if ($UseNgrok) {
        $a += @('--profile', 'ngrok')
    } else {
        # Đã xoá authtoken ngrok: dừng và xoá container ngrok cũ (nếu có), nếu không nó vẫn chạy với cấu hình cũ.
        [void](Invoke-Native 'docker' ((Get-ComposeArgs $Root) + @('--profile', 'ngrok', 'rm', '--stop', '--force', 'ngrok')))
    }
    $a += @('up', '-d')
    if ($Build) { $a += '--build' }
    return (Invoke-NativeLive 'docker' $a)
}

function Wait-LocalServer {
    $local = Get-LocalBaseUrl $script:Cfg
    Write-Info 'Đang chờ server trả lời (tối đa 2 phút)...'
    $r = Wait-HttpOk "$local/health" 120
    if ($r.Status -eq 200) { Write-Ok "Server chạy trong máy: $local/health"; return $true }
    Write-Fail ('Server chưa trả lời: ' + (Format-HttpProblem $r))
    Show-ComposeLog $Root 'app' 40
    Write-Info 'Nếu log báo lỗi APP_TOKEN: chạy lại setup. Lỗi khác: gửi log trên cho người hỗ trợ (khoá trong .env đã được che bằng ***, vẫn nên đọc lại trước khi gửi).'
    return $false
}

# Chép một bí mật vào clipboard, chờ người dùng dán xong rồi xoá clipboard.
function Copy-SecretWithPrompt([string]$Name, [string]$Value, [string]$Where) {
    $mode = Set-ClipboardSecret $Value
    if ($mode -eq '') { Write-Warn 'Không chép được vào clipboard; chọn 4 để xem.'; return }
    Write-Ok "Đã chép $Name. Dán (Ctrl+V) vào $Where."
    if ($mode -eq 'plain') {
        Write-Warn 'Windows có thể đã lưu khoá này vào Lịch sử clipboard: dán xong, bấm Win+V và xoá mục đó (bấm ... → Xoá).'
    }
    [void](Read-Host '       Dán xong thì bấm Enter ở đây để xoá khoá khỏi clipboard')
    if (Clear-ClipboardText) { Write-Ok 'Đã xoá clipboard.' } else { Write-Warn 'Không xoá được clipboard: hãy chép một chữ bất kỳ để ghi đè.' }
}

# Gửi địa chỉ máy chủ và APP_TOKEN vào Telegram: mỗi giá trị một tin riêng, đặt trong <code> để chạm một lần là chép
# đúng giá trị (bấm giữ → Chép cũng chỉ chép đúng giá trị, vì tin không có chữ nào khác). Xong thì xoá các tin đó.
function Send-ConnectInfoToTelegram([string]$Bot, [string]$Chat, [string]$BaseUrl, [string]$Token) {
    $intro = '<b>Kết nối app Chi tiêu</b> với server của bạn. Hai tin tiếp theo là:' + "`n" +
             '1) <b>Địa chỉ máy chủ (URL)</b>' + "`n" + '2) <b>Token (APP_TOKEN)</b>' + "`n`n" +
             'Chạm vào dòng chữ đơn cách trong mỗi tin để chép, rồi dán vào đúng ô trong app.' + "`n" +
             'Xong thì quay lại máy tính bấm Enter: script tự xoá các tin này.'
    $ids = New-Object System.Collections.Generic.List[object]
    foreach ($t in @($intro, ('<code>' + (ConvertTo-TelegramHtml $BaseUrl) + '</code>'),
                     ('<code>' + (ConvertTo-TelegramHtml $Token) + '</code>'))) {
        $r = Send-TelegramText $Bot $Chat $t -Html
        if (-not $r.Ok) {
            Write-Fail "Không gửi được: $($r.Error)"
            foreach ($id in $ids) { [void](Remove-TelegramMessage $Bot $Chat $id) }
            return
        }
        $ids.Add($r.MessageId)
    }
    Write-Ok 'Đã gửi 3 tin vào Telegram của bạn.'
    Write-Info 'Trên điện thoại: mở app Chi tiêu, chạm vào địa chỉ trong tin 2 để chép → dán vào ô "Địa chỉ máy chủ (URL)";'
    Write-Info 'chạm vào token trong tin 3 → dán vào ô "Token (APP_TOKEN)" → bấm "Kiểm tra & kết nối".'
    $keep = ("" + (Read-Host '       App đã kết nối xong? Bấm Enter để XOÁ các tin này khỏi Telegram (gõ g để giữ lại)')).Trim().ToLowerInvariant()
    if ($keep -eq 'g') { Write-Warn 'Đã giữ các tin. Nhớ tự xoá tin chứa APP_TOKEN trong Telegram.'; return }
    $failed = 0
    foreach ($id in $ids) { if (-not (Remove-TelegramMessage $Bot $Chat $id)) { $failed++ } }
    if ($failed -eq 0) { Write-Ok 'Đã xoá các tin chứa địa chỉ và APP_TOKEN khỏi Telegram.' }
    else { Write-Warn "Không xoá được $failed tin: hãy tự xoá trong Telegram (bấm giữ tin → Xoá → cả hai phía)." }
}

function Show-Menu([string]$BaseUrl) {
    $token = Get-EnvValue $script:Cfg 'APP_TOKEN'
    $key = Get-EnvValue $script:Cfg 'SEPAY_API_KEY'
    $bot = Get-EnvValue $script:Cfg 'TELEGRAM_BOT_TOKEN'
    $chat = Get-EnvValue $script:Cfg 'TELEGRAM_CHAT_ID'
    while ($true) {
        Write-Host ''
        Write-Host '   Chọn một việc (gõ số rồi Enter):' -ForegroundColor Cyan
        Write-Host '     1) Chép SePay API key vào clipboard (để dán vào my.sepay.vn)'
        Write-Host '     2) Chép APP_TOKEN vào clipboard'
        Write-Host '     3) Gửi địa chỉ máy chủ + APP_TOKEN vào Telegram của bạn (để chép trên điện thoại)'
        Write-Host '     4) Hiện SePay API key và APP_TOKEN trên màn hình'
        Write-Host '     Enter) Thoát'
        $a = ("" + (Read-Host '   Lựa chọn')).Trim()
        if ($a -eq '') { return }
        switch ($a) {
            '1' { Copy-SecretWithPrompt 'SePay API key' $key 'ô API Key của webhook trên my.sepay.vn' }
            '2' { Copy-SecretWithPrompt 'APP_TOKEN' $token 'ô "Token (APP_TOKEN)" của app' }
            '3' {
                if ($bot -eq '' -or $chat -eq '') { Write-Warn 'Chưa có token bot hoặc Chat ID Telegram.'; break }
                if ($BaseUrl -notmatch '^https://') { Write-Warn 'Chưa có địa chỉ Internet (ngrok chưa chạy): chưa gửi.'; break }
                Send-ConnectInfoToTelegram $bot $chat $BaseUrl $token
            }
            '4' {
                if (Read-YesNo '   Khoá sẽ hiện trên màn hình. Không có ai nhìn/chụp màn hình?' $false) {
                    Write-Host "     SePay API key : $key" -ForegroundColor Yellow
                    Write-Host "     APP_TOKEN     : $token" -ForegroundColor Yellow
                    Write-Info 'Xem xong nên xoá màn hình bằng lệnh  cls'
                }
            }
            default { Write-Warn 'Chọn 1, 2, 3, 4 hoặc Enter.' }
        }
    }
}

# =========================================================================================== chạy

Write-Title 'CÀI ĐẶT SERVER CHI TIÊU (Docker Desktop + ngrok + Telegram)'
Write-Info "Thư mục code: $Root"
if ($script:ReviewMode) { Write-Info 'Chế độ xem/đổi cấu hình: script hỏi lại từng giá trị đã lưu (Enter = giữ nguyên).' }
if (Test-InOneDrive $Root) {
    Write-Warn 'Thư mục này nằm trong OneDrive: file .env (chứa khoá bí mật) sẽ bị tải lên mây.'
    Write-Info 'Nên chuyển thư mục code ra ngoài OneDrive, vd. C:\PersonalApp (xem tài liệu, bước 5).'
    if (-not (Read-YesNo '       Vẫn tiếp tục?' $false)) { exit 1 }
}
if (Test-RiskyPath $Root) {
    Write-Warn 'Đường dẫn thư mục code có dấu tiếng Việt, ký tự đặc biệt hoặc dấu cách.'
    Write-Info 'Docker Desktop đôi khi lỗi với đường dẫn như vậy. Nếu bước 4 báo lỗi build/mount, chuyển cả thư mục'
    Write-Info 'sang C:\PersonalApp (giữ file .env) rồi chạy lại setup.cmd. Dữ liệu nằm trong Docker nên không mất.'
}

# 1. Docker
Write-Step '1/5  Kiểm tra Docker Desktop'
if ($NoStart) {
    Write-Info 'Bỏ qua (-NoStart).'
} else {
    if (-not (Initialize-Docker)) { exit 1 }
    if (-not (Test-ComposeAvailable)) {
        Write-Fail 'Không chạy được "docker compose". Cập nhật Docker Desktop lên bản mới rồi chạy lại.'
        exit 1
    }
}

# 2. File .env
Write-Step '2/5  File cấu hình .env'
$script:EnvState = Initialize-EnvFile $EnvPath $ExamplePath
switch ($script:EnvState) {
    'created' { Write-Ok 'Đã tạo file .env từ .env.example.' }
    'repaired' { Write-Warn 'File .env đang lưu dạng UTF-16 hoặc có BOM (docker compose đọc lỗi): đã chuyển sang UTF-8.' }
    default {
        if ($script:ReviewMode) { Write-Ok 'Đã có file .env.' }
        else { Write-Ok 'Đã có file .env: giữ nguyên các giá trị cũ (muốn xem/đổi từng mục: nháy đúp doi-cau-hinh.cmd).' }
    }
}
$added = Add-MissingEnvKeys $EnvPath $ExamplePath
if ($added.Count -gt 0) { Write-Ok ('Thêm biến mới từ .env.example: ' + ($added -join ', ')) }
$script:Cfg = Read-DotEnv $EnvPath

# 3. Các giá trị
Write-Step '3/5  Khoá bí mật và thông tin tài khoản'
Request-AppToken
Request-SepayKey

Write-Step 'ngrok (đưa server ra Internet để SePay và app gọi được)'
Request-Setting -Key 'NGROK_AUTHTOKEN' -Label 'ngrok authtoken' -Secret -Optional `
    -Help @('Lấy ở https://dashboard.ngrok.com/get-started/your-authtoken (đăng nhập ngrok, bấm Copy).') `
    -Validate { param($v) Test-NgrokAuthtokenFormat $v } `
    -InvalidMessage 'Authtoken ngrok thường là một chuỗi chữ, số và dấu gạch dưới, không có dấu cách.' `
    -SkipMessage 'Bỏ qua ngrok: server chỉ chạy trong máy này, SePay và app ngoài mạng nhà sẽ KHÔNG gọi tới được.'
if ((Get-EnvValue $script:Cfg 'NGROK_AUTHTOKEN') -ne '') {
    Request-Setting -Key 'NGROK_DOMAIN' -Label 'tên miền ngrok' -Optional `
        -Help @('Xem ở https://dashboard.ngrok.com/domains, dạng ten-ngau-nhien.ngrok-free.app (chỉ tên miền).') `
        -HelpWhenEmpty @('Không chắc thì bấm Enter: script sẽ tự đọc tên miền sau khi ngrok chạy.') `
        -Normalize { param($v) ConvertTo-NgrokDomain $v } `
        -Validate { param($v) (Test-DomainName $v) -and (Test-NgrokFreeDomain $v) } `
        -InvalidMessage 'Tên miền miễn phí của ngrok thường kết thúc bằng .ngrok-free.app hoặc .ngrok-free.dev.' `
        -SkipMessage 'Sẽ tự nhận tên miền sau khi ngrok chạy.'
}

Write-Step 'Telegram (kênh nhận cảnh báo)'
Request-TelegramToken
Request-ChatIdReview

Write-Step 'Tuỳ chọn'
Request-OwnerName
Request-Imap

Save-Changes
if (Update-ComposeProfiles $EnvPath) {
    Write-Ok 'Đã cập nhật COMPOSE_PROFILES trong .env (để lệnh "docker compose up -d" gõ tay cũng chạy đúng ngrok).'
}
$script:Cfg = Read-DotEnv $EnvPath

if ($NoStart) {
    Write-Step 'Đã lưu .env. Chưa khởi động server (-NoStart).'
    Write-Info 'Chạy lại setup.cmd (không có -NoStart) để khởi động.'
    exit 0
}

# 4. Khởi động
$useNgrok = (Get-EnvValue $script:Cfg 'NGROK_AUTHTOKEN') -ne ''
Write-Step '4/5  Khởi động server (lần đầu mất vài phút để tải và build)'
$code = Invoke-ComposeUp $useNgrok -Build
if ($code -ne 0) {
    Write-Fail "docker compose báo lỗi (mã $code). Xem thông báo phía trên."
    Write-Info 'Lỗi mạng khi tải image: kiểm tra Internet rồi chạy lại.'
    Write-Info ('Lỗi "port is already allocated" hoặc "access permissions" ở cổng ' + (Get-HostPort $script:Cfg) +
                ': cổng đang bị chiếm/bị Windows giữ. Thêm dòng HOST_PORT=18000 vào .env rồi chạy lại (tài liệu, mục 13).')
    exit 1
}
if (-not (Wait-LocalServer)) { exit 1 }

$domain = Get-EnvValue $script:Cfg 'NGROK_DOMAIN'
if ($useNgrok) {
    Write-Info 'Đang chờ ngrok kết nối...'
    $publicUrl = Wait-NgrokPublicUrl $Root 60
    if ($publicUrl) {
        $detected = ([Uri]$publicUrl).Host.ToLowerInvariant()
        if ($domain -eq '') {
            Set-DotEnvValues $EnvPath ([ordered]@{ NGROK_DOMAIN = $detected })
            $script:Cfg['NGROK_DOMAIN'] = $detected
            $domain = $detected
            Write-Ok "ngrok đang chạy. Tên miền của bạn: $detected (đã lưu vào .env)"
        } elseif ($domain -ne $detected) {
            Write-Warn "ngrok đang dùng $detected nhưng .env ghi NGROK_DOMAIN=$domain."
            Write-Info 'Nháy đúp doi-cau-hinh.cmd và sửa tên miền cho đúng trang https://dashboard.ngrok.com/domains (gõ - để xoá, script tự nhận).'
        } else {
            Write-Ok "ngrok đang chạy: https://$domain"
        }
    } else {
        Write-Fail 'ngrok chưa kết nối được.'
        Show-ComposeLog $Root 'ngrok' 20
        Write-Info 'Thường gặp: authtoken sai (ERR_NGROK_105/107), tên miền không thuộc tài khoản của bạn,'
        Write-Info 'hoặc đang chạy ngrok ở máy khác cùng tài khoản. Sửa: nháy đúp scripts\windows\doi-cau-hinh.cmd'
    }
    if ($domain -ne '') {
        $r = Wait-HttpOk "https://$domain/health" 45
        if ($r.Status -eq 200) { Write-Ok "Từ Internet gọi được server: https://$domain/health" }
        else { Write-Warn ('Chưa gọi được server qua Internet: ' + (Format-HttpProblem $r) + '. Chạy status.cmd để xem chi tiết.') }
    }
} else {
    Write-Warn 'Chưa có ngrok authtoken: server chỉ chạy trong máy này.'
}

# 5. Telegram Chat ID
$bot = Get-EnvValue $script:Cfg 'TELEGRAM_BOT_TOKEN'
$chat = Get-EnvValue $script:Cfg 'TELEGRAM_CHAT_ID'
Write-Step '5/5  Kết nối Telegram với tài khoản của bạn'
if ($bot -eq '') {
    Write-Warn 'Chưa có token bot Telegram: bỏ qua. Chạy lại setup khi có token.'
} elseif ($chat -ne '') {
    Write-Ok "Đã có Chat ID ($chat). Bot chỉ trả lời và gửi cảnh báo cho đúng tài khoản Telegram này."
} else {
    if ($script:BotUsername) {
        Write-Info "1. Trên điện thoại, mở Telegram, tìm @$($script:BotUsername) (hoặc mở https://t.me/$($script:BotUsername))."
    } else {
        Write-Info '1. Trên điện thoại, mở Telegram và mở bot bạn vừa tạo với BotFather.'
    }
    Write-Info '2. Bấm Start (hoặc gửi /start). Bot trả lời "Chat ID của bạn" kèm một dãy số.'
    Write-Info '3. Gõ dãy số đó vào đây. (Đừng làm theo dòng "khởi động lại server" trong tin của bot: script tự làm.)'
    while ($true) {
        $id = ("" + (Read-Host '       Chat ID (Enter để làm sau)')).Trim()
        if ($id -eq '') { Write-Warn 'Chưa có Chat ID: server chưa gửi cảnh báo. Chạy lại setup.cmd khi đã có.'; break }
        if (-not (Test-ChatId $id)) { Write-Warn 'Chat ID là một dãy số, vd. 123456789.'; continue }
        if ($id.StartsWith('-')) { Write-Warn 'Chat ID âm là nhóm/kênh: bot chỉ nhận lệnh trong chat riêng. Nên dùng Chat ID của chat riêng với bot.' }
        Set-DotEnvValues $EnvPath ([ordered]@{ TELEGRAM_CHAT_ID = $id })
        $script:Cfg['TELEGRAM_CHAT_ID'] = $id
        Write-Ok 'Đã lưu Chat ID. Khởi động lại server để nạp giá trị mới...'
        if ((Invoke-ComposeUp $useNgrok) -ne 0 -or -not (Wait-LocalServer)) { break }
        $msg = 'Server Chi tiêu đã kết nối với Telegram của bạn. Cảnh báo số dư sẽ gửi vào đây. Gõ /status để xem tình hình.'
        $sent = Send-TelegramText $bot $id $msg
        if ($sent.Ok) { Write-Ok 'Đã gửi tin thử vào Telegram của bạn.' }
        else { Write-Warn "Không gửi được tin thử: $($sent.Error). Kiểm tra lại Chat ID (nháy đúp doi-cau-hinh.cmd)." }
        break
    }
}

# Tổng kết
Write-Title 'XONG. VIỆC TIẾP THEO'
if ($domain -ne '') { $base = "https://$domain" } else { $base = '(chưa có địa chỉ Internet, xem lỗi ngrok phía trên)' }
Write-Step 'A. Thêm webhook trên https://my.sepay.vn (tài liệu: docs\cai-dat-windows.md, bước 7)'
Write-Info "URL webhook       : $base/webhooks/sepay"
Write-Info 'Sự kiện           : Cả hai (tiền vào và tiền ra)'
Write-Info 'Bỏ qua nếu không có Code thanh toán : Không'
Write-Info 'Kiểu chứng thực   : API Key   (key: chọn 1 bên dưới để chép)'
Write-Info 'Kiểu nội dung     : application/json'
Write-Step 'B. Kết nối app Chi tiêu trên điện thoại'
Write-Info "Địa chỉ máy chủ (URL) : $base"
Write-Info 'Token (APP_TOKEN)     : chọn 3 (gửi qua Telegram, chạm để chép) hoặc 2 (clipboard) bên dưới'
Write-Step 'C. Thử đường đi SePay -> server -> Telegram: nháy đúp scripts\windows\test-sepay.cmd'
Write-Step 'Giữ server luôn chạy'
Write-DockerAutoStartAdvice
Write-Info 'Cài đặt nguồn điện Windows: Sleep = Never khi cắm sạc (tài liệu, bước 10).'

Show-Menu $base
Write-Info 'Kiểm tra tình trạng bất cứ lúc nào: scripts\windows\status.cmd'
exit 0
