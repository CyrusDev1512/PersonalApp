<#
.SYNOPSIS
    Gửi một webhook SePay giả (có xác thực) tới địa chỉ Internet của server để thử cả đường đi
    Internet -> ngrok -> server -> Telegram, giống SePay: cùng URL, cùng header xác thực, cùng dạng JSON.
    Không gửi header "ngrok-skip-browser-warning" (SePay không gửi header này), nên nếu ngrok chặn bằng trang cảnh
    báo thì bài thử báo lỗi. Bài thử KHÔNG giả được User-Agent thật của SePay (chưa biết), nên kết quả thật cuối cùng
    vẫn phải xem ở nhật ký webhook trên my.sepay.vn sau giao dịch thật đầu tiên.

.DESCRIPTION
    Giao dịch thử dùng tài khoản giả 7391046285013 của "ngân hàng" SEPAYTEST. Server không biết tài khoản này nên
    tạo một tài khoản "không tính vào tổng": tổng số dư, mục tiêu và cảnh báo của bạn KHÔNG bị ảnh hưởng.
    Id webhook thử luôn từ 900000000000000 trở lên nên không bao giờ trùng id giao dịch thật của SePay.
    Lần thử đầu tiên, bot Telegram gửi tin "Phát hiện tài khoản mới" cho tài khoản thử; các lần sau không có tin
    (tài khoản thử đã được đánh dấu "không tính vào tổng").
    Tác dụng phụ (đúng thiết kế): tài khoản thử ở lại trong danh sách tài khoản (server không cho xoá tài khoản đã có
    giao dịch), và mỗi lần thử được tính là "vừa nhận webhook SePay" nên cảnh báo "48 giờ không có webhook SePay"
    trong bản tin 08:00 được đặt lại.

.PARAMETER Local
    Gửi thẳng vào server trong máy (http://127.0.0.1:<HOST_PORT, mặc định 8000>) thay vì qua ngrok.

.PARAMETER Direction
    in (tiền vào, mặc định) hoặc out (tiền ra).

.PARAMETER Amount
    Số tiền thử, mặc định 1000 (đồng).

.EXAMPLE
    Nháy đúp scripts\windows\test-sepay.cmd
#>
[CmdletBinding()]
param(
    [switch]$Local,
    [ValidateSet('in', 'out')][string]$Direction = 'in',
    [ValidateRange(1, 1000000000)][long]$Amount = 1000
)

$ErrorActionPreference = 'Stop'
. (Join-Path (Join-Path $PSScriptRoot 'lib') 'common.ps1')
Initialize-Console

$Root = Get-RepoRoot
$EnvPath = Join-Path $Root '.env'

function Find-TestAccount([string]$LocalBase, [string]$Token) {
    $r = Invoke-HttpRequest -Url "$LocalBase/api/accounts" -Headers @{ Authorization = "Bearer $Token" } -TimeoutSec 15
    if ($r.Status -ne 200) { return [pscustomobject]@{ Ok = $false; Status = $r; Account = $null } }
    $acc = $null
    foreach ($a in (ConvertFrom-JsonList $r.Body)) {
        if ([string]$a.account_number -eq $script:TestAccountNumber) { $acc = $a }
    }
    return [pscustomobject]@{ Ok = $true; Status = $r; Account = $acc }
}

function Get-HmacSha256Hex([string]$Secret, [byte[]]$Data) {
    $hmac = [System.Security.Cryptography.HMACSHA256]::new([System.Text.Encoding]::UTF8.GetBytes($Secret))
    try {
        $sb = New-Object System.Text.StringBuilder
        foreach ($b in $hmac.ComputeHash($Data)) { [void]$sb.Append($b.ToString('x2')) }
        return $sb.ToString()
    } finally { $hmac.Dispose() }
}

Write-Title 'THỬ WEBHOOK SEPAY (giao dịch giả, không ảnh hưởng số liệu thật)'

if (-not (Test-Path -LiteralPath $EnvPath)) { Write-Fail 'Chưa có file .env. Chạy setup.cmd trước.'; exit 1 }
$Cfg = Read-DotEnv $EnvPath
$apiKey = Get-EnvValue $Cfg 'SEPAY_API_KEY'
$hmacSecret = Get-EnvValue $Cfg 'SEPAY_HMAC_SECRET'
$appToken = Get-EnvValue $Cfg 'APP_TOKEN'
if ($apiKey -eq '' -and $hmacSecret -eq '') { Write-Fail 'Chưa có SEPAY_API_KEY trong .env. Chạy setup.cmd trước.'; exit 1 }
if (-not (Test-AppToken $appToken)) { Write-Fail 'APP_TOKEN thiếu hoặc quá ngắn. Chạy setup.cmd trước.'; exit 1 }

# 1. Server trong máy
Write-Step '1. Server trong máy'
if ($null -eq (Find-DockerCli) -or -not (Test-DockerEngine)) {
    Write-Fail 'Docker Desktop chưa chạy. Mở Docker Desktop rồi chạy lại.'
    exit 1
}
$localBase = Get-LocalBaseUrl $Cfg
$h = Invoke-HttpRequest -Url "$localBase/health" -TimeoutSec 5
if ($h.Status -ne 200) { Write-Fail ('Server trong máy không trả lời: ' + (Format-HttpProblem $h) + '. Chạy status.cmd.'); exit 1 }
Write-Ok "Server trong máy trả lời ($localBase)."
$before = Find-TestAccount $localBase $appToken
if (-not $before.Ok) {
    if ($before.Status.Status -eq 401) {
        Write-Fail 'Server từ chối APP_TOKEN trong .env: server đang chạy với .env cũ. Chạy setup.cmd để nạp lại.'
    } else {
        Write-Fail ('Không đọc được danh sách tài khoản: ' + (Format-HttpProblem $before.Status))
    }
    exit 1
}
$existed = $null -ne $before.Account

# 2. Địa chỉ gửi
Write-Step '2. Địa chỉ nhận webhook'
if ($Local) {
    $base = $localBase
    Write-Info "Gửi thẳng vào server trong máy (-Local): $base"
} else {
    $domain = ConvertTo-NgrokDomain (Get-EnvValue $Cfg 'NGROK_DOMAIN')
    if ($domain -eq '') {
        $u = Get-NgrokPublicUrl $Root
        if ($u) { $domain = ([Uri]$u).Host.ToLowerInvariant() }
    }
    if ($domain -eq '') { Write-Fail 'Chưa biết tên miền ngrok. Chạy setup.cmd (hoặc status.cmd để xem lỗi ngrok).'; exit 1 }
    $base = "https://$domain"
    Write-Info "Gửi qua Internet giống SePay: $base/webhooks/sepay"
}

# 3. Gửi webhook
Write-Step '3. Gửi webhook thử'
$txId = $script:TestIdBase + [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
$vnTime = [DateTime]::UtcNow.AddHours(7).ToString('yyyy-MM-dd HH:mm:ss', [Globalization.CultureInfo]::InvariantCulture)
$payload = [ordered]@{
    id              = $txId
    gateway         = $script:TestGateway
    transactionDate = $vnTime
    accountNumber   = $script:TestAccountNumber
    subAccount      = $null
    code            = $null
    content         = 'THU NGHIEM KET NOI SEPAY - KHONG PHAI GIAO DICH THAT'
    transferType    = $Direction
    description     = 'Thu nghiem tu scripts/windows/test-sepay.ps1'
    transferAmount  = $Amount
    referenceCode   = "TEST$txId"
    accumulated     = 0
}
$body = ConvertTo-JsonBytes $payload
$headers = @{}
if ($apiKey -ne '') {
    $headers['Authorization'] = "Apikey $apiKey"
    Write-Info 'Xác thực: API Key (header Authorization: Apikey ...), giống cấu hình webhook trên SePay.'
} else {
    $ts = [string][DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
    $msg = [System.Text.Encoding]::UTF8.GetBytes("$ts.") + $body
    $headers['X-SePay-Timestamp'] = $ts
    $headers['X-SePay-Signature'] = 'sha256=' + (Get-HmacSha256Hex $hmacSecret ([byte[]]$msg))
    Write-Info 'Xác thực: chữ ký HMAC-SHA256 (SEPAY_HMAC_SECRET).'
}
Write-Info ("Giao dịch thử: id $txId, tài khoản $($script:TestAccountNumber), " + $(if ($Direction -eq 'in') { 'tiền vào' } else { 'tiền ra' }) + " $Amount đ")
# Không có header bỏ qua trang cảnh báo của ngrok; User-Agent kiểu máy chủ (không phải trình duyệt), như SePay.
$r = Invoke-HttpRequest -Method 'POST' -Url "$base/webhooks/sepay" -Headers $headers -Body $body -TimeoutSec 30 `
    -NoNgrokBypass -UserAgent 'PersonalApp-test-sepay/1.0 (webhook test)'

if ($r.Status -eq 200 -and $r.Body -match '"success"\s*:\s*true') {
    Write-Ok 'Server nhận webhook: HTTP 200 {"success": true} (đúng như SePay chờ đợi).'
} else {
    Write-Fail ('Webhook thất bại: ' + (Format-HttpProblem $r))
    $ngrokErr = [regex]::Match([string]$r.Body, 'ERR_NGROK_[0-9]+')
    if ($r.Status -eq 0) {
        Write-Info 'Không tới được địa chỉ trên: kiểm tra Internet, tên miền ngrok trong .env, và chạy status.cmd.'
    } elseif ($ngrokErr.Success) {
        Write-Info "ngrok báo $($ngrokErr.Value): thường là ngrok chưa chạy / sai tên miền / không tới được server. Chạy status.cmd."
    } elseif ($r.Status -eq 401) {
        Write-Info 'Server từ chối khoá: khoá trong .env khác khoá server đang dùng. Chạy setup.cmd để nạp lại .env.'
    } elseif ($r.Status -eq 404) {
        Write-Info 'Server chưa bật webhook SePay (chưa nạp SEPAY_API_KEY). Chạy setup.cmd để nạp lại .env.'
    } elseif ($r.Status -ge 500) {
        Write-Info 'Server hoặc ngrok lỗi. Chạy status.cmd và xem log.'
    } elseif ($r.Status -eq 200) {
        Write-Info 'Phản hồi không phải của server (có thể là trang cảnh báo của ngrok). Chạy status.cmd.'
    }
    exit 1
}

# 4. Server xử lý ra sao
Write-Step '4. Server xử lý giao dịch thử'
Start-Sleep -Seconds 1
$ev = Invoke-HttpRequest -Url "$localBase/api/ingest-events?limit=20" -Headers @{ Authorization = "Bearer $appToken" } -TimeoutSec 15
$found = $null
if ($ev.Status -eq 200) {
    foreach ($e in (ConvertFrom-JsonList $ev.Body)) {
        if ([string]$e.external_id -eq [string]$txId -and $e.source -eq 'sepay') { $found = $e; break }
    }
}
$processed = $false
if ($ev.Status -ne 200) {
    Write-Fail ('Không đọc được danh sách sự kiện của server trong máy: ' + (Format-HttpProblem $ev))
} elseif ($null -eq $found) {
    Write-Fail 'Server trong máy KHÔNG có sự kiện vừa gửi: địa chỉ Internet đang trỏ tới một server khác'
    Write-Info '(vd. ngrok cùng tài khoản đang chạy ở máy khác, hoặc NGROK_DOMAIN trong .env không phải của máy này).'
    Write-Info 'Chạy status.cmd, tắt ngrok ở máy kia, hoặc sửa tên miền bằng doi-cau-hinh.cmd.'
} elseif ($found.status -eq 'parsed') {
    Write-Ok 'Đã đọc và ghi nhận giao dịch thử.'
    $processed = $true
} elseif ($found.status -eq 'duplicate') {
    Write-Ok 'Giao dịch thử bị coi là trùng (đã nhận trước đó) — đường truyền vẫn hoạt động.'
    $processed = $true
} else {
    Write-Fail "Server nhận nhưng không đọc được: trạng thái $($found.status), lỗi: $($found.error)"
    Write-Info 'Chạy status.cmd và gửi phần log "app" cho người hỗ trợ.'
}

# Đánh dấu tài khoản thử: đã xác nhận, KHÔNG tính vào tổng, đặt tên dễ nhận ra.
$after = Find-TestAccount $localBase $appToken
if ($after.Ok -and $null -ne $after.Account) {
    $acc = $after.Account
    if ($acc.include_in_total -or -not $acc.confirmed -or [string]$acc.name -ne $script:TestAccountName) {
        $patch = [ordered]@{ name = $script:TestAccountName; confirmed = $true; include_in_total = $false }
        $p = Invoke-HttpRequest -Method 'PATCH' -Url "$localBase/api/accounts/$($acc.id)" `
            -Headers @{ Authorization = "Bearer $appToken" } -Body (ConvertTo-JsonBytes $patch) -TimeoutSec 15
        if ($p.Status -eq 200) { Write-Ok "Tài khoản thử được đặt tên ""$($script:TestAccountName)"", không tính vào tổng số dư." }
        else { Write-Warn ('Không đánh dấu được tài khoản thử: ' + (Format-HttpProblem $p)) }
    } else {
        Write-Ok 'Tài khoản thử vẫn ở trạng thái "không tính vào tổng" — số liệu thật không đổi.'
    }
}

# 5. Telegram
Write-Step '5. Telegram'
$bot = Get-EnvValue $Cfg 'TELEGRAM_BOT_TOKEN'
$chat = Get-EnvValue $Cfg 'TELEGRAM_CHAT_ID'
if (-not $processed) {
    Write-Info 'Bỏ qua: server trong máy chưa ghi nhận giao dịch thử nên bot sẽ không nhắn gì.'
} elseif ($bot -eq '' -or $chat -eq '') {
    Write-Warn 'Telegram chưa cấu hình đủ (token bot + Chat ID) nên sẽ không có tin nhắn. Chạy setup.cmd.'
} elseif ($existed) {
    Write-Ok 'Tài khoản thử đã có từ lần thử trước, nên lần này bot KHÔNG nhắn gì (đúng thiết kế, tránh làm phiền).'
    Write-Info 'Muốn kiểm tra bot: nhắn /status cho bot, bot phải trả lời trong vài giây.'
} else {
    Write-Ok 'Trong khoảng 10 giây, bot Telegram sẽ gửi tin "Phát hiện tài khoản mới" cho tài khoản SEPAYTEST ...5013.'
    Write-Info 'Đó là tin của bài thử. Script đã đánh dấu tài khoản này "không tính vào tổng", bạn không cần bấm nút nào;'
    Write-Info 'nếu bấm thì chọn "Bỏ qua", ĐỪNG bấm "Tính vào tổng".'
    Write-Info 'Không thấy tin sau 1 phút: chạy status.cmd và xem phần Telegram + log.'
}

if (-not $processed) {
    Write-Title 'KẾT QUẢ: CHƯA ĐẠT (xem các dòng [X] phía trên)'
    exit 1
}
Write-Title 'KẾT QUẢ: ĐƯỜNG ĐI WEBHOOK HOẠT ĐỘNG'
if (-not $Local) {
    Write-Info 'SePay sẽ gửi tới đúng địa chỉ này. Nếu SePay thật vẫn báo lỗi, so lại URL và API key trên my.sepay.vn.'
}
exit 0
