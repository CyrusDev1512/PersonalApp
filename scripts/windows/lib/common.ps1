# Hàm dùng chung cho các script Windows của PersonalApp (Chi tiêu).
# Chạy được trên Windows PowerShell 5.1 (mặc định của Windows 10/11) và PowerShell 7.
# Các script khác nạp file này bằng: . (Join-Path (Join-Path $PSScriptRoot 'lib') 'common.ps1')
#
# Lưu ý cho người sửa file: giữ mã hoá UTF-8 CÓ BOM (Windows PowerShell 5.1 đọc file không BOM theo bảng mã ANSI
# nên chữ tiếng Việt sẽ hỏng) và không dùng cú pháp chỉ có ở PowerShell 7 (??, ?:, &&, ||, -AsPlainText...).

Set-StrictMode -Version 1.0

# Tài khoản thử dùng cho test-sepay.ps1. Server coi đây là tài khoản lạ: tạo TK "không tính vào tổng",
# nên giao dịch thử không bao giờ làm đổi tổng số dư thật.
$script:TestAccountNumber = '7391046285013'
$script:TestGateway = 'SEPAYTEST'
$script:TestAccountName = 'Thử kết nối SePay (không phải TK thật)'
# Id webhook thử bắt đầu từ 9e14: không bao giờ trùng id giao dịch thật của SePay (server khử trùng theo id).
$script:TestIdBase = [long]900000000000000

# ------------------------------------------------------------------------------------------------ hiển thị

function Initialize-Console {
    try { [Console]::OutputEncoding = New-Object System.Text.UTF8Encoding($false) } catch { Write-Verbose 'Không đổi được bảng mã console.' }
    # Windows PowerShell 5.1 mặc định có thể chưa bật TLS 1.2 (ngrok, Telegram, GitHub đều cần).
    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
    } catch { Write-Verbose 'Không bật được TLS 1.2.' }
}

function Write-Title([string]$Text) {
    Write-Host ''
    Write-Host ('=' * 70) -ForegroundColor DarkCyan
    Write-Host "  $Text" -ForegroundColor Cyan
    Write-Host ('=' * 70) -ForegroundColor DarkCyan
}

function Write-Step([string]$Text) {
    Write-Host ''
    Write-Host ">> $Text" -ForegroundColor Cyan
}

function Write-Ok([string]$Text) { Write-Host "   [OK] $Text" -ForegroundColor Green }
function Write-Warn([string]$Text) { Write-Host "   [!]  $Text" -ForegroundColor Yellow }
function Write-Fail([string]$Text) { Write-Host "   [X]  $Text" -ForegroundColor Red }
function Write-Info([string]$Text) { Write-Host "        $Text" }

# ------------------------------------------------------------------------------------------------ đường dẫn

function Get-RepoRoot {
    # file này nằm ở <repo>\scripts\windows\lib
    return (Split-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) -Parent)
}

function Get-ComposeArgs([string]$Root) {
    return @('compose', '--project-directory', $Root, '-f', (Join-Path $Root 'docker-compose.yml'))
}

# ------------------------------------------------------------------------------------------------ nhập liệu

function Read-YesNo([string]$Prompt, [bool]$Default = $false) {
    $suffix = '[c/K]'
    if ($Default) { $suffix = '[C/k]' }
    while ($true) {
        $answer = ("" + (Read-Host "$Prompt $suffix")).Trim().ToLowerInvariant()
        if ($answer -eq '') { return $Default }
        if (@('c', 'co', 'có', 'y', 'yes') -contains $answer) { return $true }
        if (@('k', 'khong', 'không', 'n', 'no') -contains $answer) { return $false }
        Write-Warn 'Gõ c (có) hoặc k (không), rồi Enter.'
    }
}

function ConvertFrom-SecureText([Security.SecureString]$Secure) {
    if ($null -eq $Secure -or $Secure.Length -eq 0) { return '' }
    $bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($Secure)
    try { return [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr) }
    finally { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr) }
}

# Nhập bí mật: ký tự hiện thành dấu *, không bao giờ in lại ra màn hình.
function Read-SecretText([string]$Prompt) {
    $secure = Read-Host -Prompt $Prompt -AsSecureString
    return (ConvertFrom-SecureText $secure).Trim()
}

function Format-SecretState([string]$Value) {
    if ([string]::IsNullOrEmpty($Value)) { return 'chưa có' }
    return "đã có ($($Value.Length) ký tự, không hiển thị)"
}

# ------------------------------------------------------------------------------------------------ sinh khoá

function New-RandomBytes([int]$Count) {
    $bytes = New-Object byte[] $Count
    $rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()
    try { $rng.GetBytes($bytes) } finally { $rng.Dispose() }
    return , $bytes
}

# Chuỗi base64url (giống secrets.token_urlsafe của Python): 32 byte -> 43 ký tự.
function New-UrlSafeToken([int]$Bytes = 32) {
    $b64 = [Convert]::ToBase64String((New-RandomBytes $Bytes))
    return $b64.TrimEnd('=').Replace('+', '-').Replace('/', '_')
}

# Chuỗi hex chữ thường: 20 byte -> 40 ký tự (dễ dán vào mọi ô nhập).
function New-HexToken([int]$Bytes = 20) {
    $sb = New-Object System.Text.StringBuilder
    foreach ($b in (New-RandomBytes $Bytes)) { [void]$sb.Append($b.ToString('x2')) }
    return $sb.ToString()
}

# ------------------------------------------------------------------------------------------------ file .env

# '' | 'utf8bom' | 'utf16' | 'utf32'
function Get-TextFileBomKind([string]$Path) {
    if (-not (Test-Path -LiteralPath $Path)) { return '' }
    $stream = [System.IO.File]::OpenRead($Path)
    try {
        $head = New-Object byte[] 4
        $n = $stream.Read($head, 0, 4)
    } finally { $stream.Dispose() }
    if ($n -ge 4 -and $head[0] -eq 0xFF -and $head[1] -eq 0xFE -and $head[2] -eq 0 -and $head[3] -eq 0) { return 'utf32' }
    if ($n -ge 2 -and (($head[0] -eq 0xFF -and $head[1] -eq 0xFE) -or ($head[0] -eq 0xFE -and $head[1] -eq 0xFF))) { return 'utf16' }
    if ($n -ge 3 -and $head[0] -eq 0xEF -and $head[1] -eq 0xBB -and $head[2] -eq 0xBF) { return 'utf8bom' }
    return ''
}

function Read-TextFile([string]$Path) {
    # ReadAllText tự nhận BOM UTF-8/UTF-16/UTF-32; không có BOM thì đọc là UTF-8.
    return [System.IO.File]::ReadAllText($Path, (New-Object System.Text.UTF8Encoding($false)))
}

# Ghi UTF-8 KHÔNG BOM, xuống dòng LF: docker compose đọc được chắc chắn (UTF-16 thì không).
function Write-TextFileUtf8([string]$Path, [string]$Text) {
    $normalized = ($Text -replace "`r`n", "`n")
    [System.IO.File]::WriteAllText($Path, $normalized, (New-Object System.Text.UTF8Encoding($false)))
}

# Tách một dòng KEY=value theo cách docker compose hiểu (đủ cho các giá trị của dự án này).
function ConvertFrom-EnvLine([string]$Line) {
    $m = [regex]::Match($Line, '^\s*(?:export\s+)?([A-Za-z_][A-Za-z0-9_]*)\s*=(.*)$')
    if (-not $m.Success) { return $null }
    $key = $m.Groups[1].Value
    $raw = $m.Groups[2].Value.Trim()
    $value = $raw
    if ($raw.StartsWith("'")) {
        $end = $raw.IndexOf("'", 1)
        if ($end -gt 0) { $value = $raw.Substring(1, $end - 1) } else { $value = $raw.Substring(1) }
    } elseif ($raw.StartsWith('"')) {
        $end = -1
        for ($i = 1; $i -lt $raw.Length; $i++) {
            if ($raw[$i] -eq '\') { $i++; continue }
            if ($raw[$i] -eq '"') { $end = $i; break }
        }
        if ($end -gt 0) { $inner = $raw.Substring(1, $end - 1) } else { $inner = $raw.Substring(1) }
        $value = $inner.Replace('\"', '"').Replace('\n', "`n").Replace('\\', '\')
    } else {
        $hash = $raw.IndexOf(' #')
        if ($raw.StartsWith('#')) { $value = '' }
        elseif ($hash -ge 0) { $value = $raw.Substring(0, $hash).TrimEnd() }
    }
    return [pscustomobject]@{ Key = $key; Value = $value }
}

# Đọc .env thành bảng KEY -> value (dòng sau ghi đè dòng trước, giống compose).
function Read-DotEnv([string]$Path) {
    $map = @{}
    if (-not (Test-Path -LiteralPath $Path)) { return $map }
    foreach ($line in ((Read-TextFile $Path) -split "`r?`n")) {
        if ($line -match '^\s*#') { continue }
        $kv = ConvertFrom-EnvLine $line
        if ($null -ne $kv) { $map[$kv.Key] = $kv.Value }
    }
    return $map
}

function Get-EnvValue([hashtable]$Map, [string]$Key) {
    if ($Map.ContainsKey($Key) -and $null -ne $Map[$Key]) { return [string]$Map[$Key] }
    return ''
}

# Viết giá trị sao cho compose đọc lại đúng nguyên văn: ký tự an toàn thì để trần, còn lại đặt trong nháy đơn
# (trong nháy đơn compose không thay $ và không cắt #).
function Format-EnvValue([string]$Value) {
    if ([string]::IsNullOrEmpty($Value)) { return '' }
    if ($Value -match "[`r`n]") { throw 'Giá trị không được có xuống dòng.' }
    if ($Value -cmatch '^[A-Za-z0-9_\-\.:/@+=,]+$') { return $Value }
    if ($Value.Contains("'")) { throw "Giá trị chứa dấu nháy đơn ('), file .env không lưu được an toàn." }
    return "'" + $Value + "'"
}

# Cập nhật tại chỗ các KEY trong .env, giữ nguyên chú thích và thứ tự; KEY chưa có thì thêm vào cuối.
function Set-DotEnvValues([string]$Path, [System.Collections.IDictionary]$Values) {
    $lines = New-Object System.Collections.Generic.List[string]
    if (Test-Path -LiteralPath $Path) {
        foreach ($l in ((Read-TextFile $Path) -split "`r?`n")) { $lines.Add($l) }
        if ($lines.Count -gt 0 -and $lines[$lines.Count - 1] -eq '') { $lines.RemoveAt($lines.Count - 1) }
    }
    foreach ($key in @($Values.Keys)) {
        $newLine = "$key=" + (Format-EnvValue ([string]$Values[$key]))
        $active = [regex]('^\s*(?:export\s+)?' + [regex]::Escape($key) + '\s*=')
        $commented = [regex]('^\s*#\s*' + [regex]::Escape($key) + '\s*=')
        $done = $false
        for ($i = 0; $i -lt $lines.Count; $i++) {
            if ($active.IsMatch($lines[$i])) {
                if (-not $done) { $lines[$i] = $newLine; $done = $true }
                else { $lines[$i] = '# (trùng, đã bỏ) ' + $lines[$i] }
            }
        }
        if (-not $done) {
            for ($i = 0; $i -lt $lines.Count; $i++) {
                if ($commented.IsMatch($lines[$i])) { $lines[$i] = $newLine; $done = $true; break }
            }
        }
        if (-not $done) { $lines.Add($newLine) }
    }
    Write-TextFileUtf8 $Path (($lines -join "`n") + "`n")
}

# Tạo .env từ .env.example nếu chưa có; sửa mã hoá nếu .env đang là UTF-16 hoặc có BOM.
# Trả về 'created' | 'repaired' | 'ok'.
function Initialize-EnvFile([string]$EnvPath, [string]$ExamplePath) {
    if (-not (Test-Path -LiteralPath $EnvPath)) {
        if (-not (Test-Path -LiteralPath $ExamplePath)) { throw "Không thấy file mẫu $ExamplePath" }
        Write-TextFileUtf8 $EnvPath (Read-TextFile $ExamplePath)
        return 'created'
    }
    $bom = Get-TextFileBomKind $EnvPath
    if ($bom -ne '') {
        Write-TextFileUtf8 $EnvPath (Read-TextFile $EnvPath)
        return 'repaired'
    }
    return 'ok'
}

# Các KEY có trong .env.example mà .env chưa có (sau khi cập nhật code có thể xuất hiện biến mới).
function Get-MissingEnvKeys([string]$EnvPath, [string]$ExamplePath) {
    $have = Read-DotEnv $EnvPath
    $missing = [ordered]@{}
    foreach ($line in ((Read-TextFile $ExamplePath) -split "`r?`n")) {
        if ($line -match '^\s*#') { continue }
        $kv = ConvertFrom-EnvLine $line
        if ($null -ne $kv -and -not $have.ContainsKey($kv.Key) -and -not $missing.Contains($kv.Key)) {
            $missing[$kv.Key] = $kv.Value
        }
    }
    return $missing
}

# Thêm vào .env các KEY mới của .env.example (giá trị mẫu). Trả về danh sách KEY đã thêm.
function Add-MissingEnvKeys([string]$EnvPath, [string]$ExamplePath) {
    $missing = Get-MissingEnvKeys $EnvPath $ExamplePath
    if ($missing.Count -gt 0) { Set-DotEnvValues $EnvPath $missing }
    return , @($missing.Keys)
}

# ------------------------------------------------------------------------------------------------ kiểm tra giá trị

function Test-AppToken([string]$Value) { return ($Value.Length -ge 32) }

function ConvertTo-NgrokDomain([string]$Value) {
    $v = ("" + $Value).Trim().ToLowerInvariant()
    $v = $v -replace '^[a-z][a-z0-9+.-]*://', ''
    $v = $v.Split('/')[0]
    return $v.TrimEnd('.')
}

function Test-DomainName([string]$Domain) {
    return ($Domain -match '^(?=.{4,253}$)([a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?\.)+[a-z]{2,63}$')
}

function Test-NgrokFreeDomain([string]$Domain) {
    return ($Domain -match '\.ngrok(-free)?\.(app|dev)$' -or $Domain -match '\.ngrok\.io$')
}

function Test-NgrokAuthtokenFormat([string]$Value) {
    return ($Value -match '^[A-Za-z0-9_\-]{20,200}$')
}

function Test-TelegramTokenFormat([string]$Value) {
    return ($Value -match '^[0-9]{5,15}:[A-Za-z0-9_\-]{30,60}$')
}

function Test-ChatId([string]$Value) {
    return ($Value -match '^-?[0-9]{1,20}$')
}

# Mật khẩu ứng dụng Gmail hiển thị dạng "abcd efgh ijkl mnop": bỏ dấu cách cho chắc.
function ConvertTo-AppPassword([string]$Value) {
    return (("" + $Value) -replace '\s', '')
}

# ------------------------------------------------------------------------------------------------ lệnh ngoài

# Chạy lệnh ngoài, gom stdout+stderr thành chuỗi. Không ném lỗi khi lệnh ghi ra stderr (PowerShell 5.1).
# stdin của lệnh được đóng ngay (@() |): "docker compose exec" mặc định đọc stdin và sẽ "nuốt" phím người dùng gõ.
function Invoke-Native([string]$FilePath, [string[]]$Arguments) {
    $old = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    $global:LASTEXITCODE = 0
    try {
        $out = @() | & $FilePath @Arguments 2>&1 | ForEach-Object { "$_" }
        $code = $LASTEXITCODE
    } catch {
        $out = @("$($_.Exception.Message)")
        $code = 1
    } finally {
        $ErrorActionPreference = $old
    }
    return [pscustomobject]@{ ExitCode = $code; Output = (@($out) -join "`n") }
}

# Chạy lệnh ngoài, hiện trực tiếp tiến trình ra màn hình; trả về mã thoát.
function Invoke-NativeLive([string]$FilePath, [string[]]$Arguments) {
    $old = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    $global:LASTEXITCODE = 0
    try {
        # Out-Host: đưa stdout ra màn hình, không lẫn vào giá trị trả về của hàm.
        & $FilePath @Arguments | Out-Host
        return $LASTEXITCODE
    } catch {
        Write-Fail $_.Exception.Message
        return 1
    } finally {
        $ErrorActionPreference = $old
    }
}

# ------------------------------------------------------------------------------------------------ Docker

function Find-DockerDesktopExe {
    $candidates = @()
    if ($env:ProgramFiles) { $candidates += (Join-Path $env:ProgramFiles 'Docker\Docker\Docker Desktop.exe') }
    if ($env:LOCALAPPDATA) { $candidates += (Join-Path $env:LOCALAPPDATA 'Programs\DockerDesktop\Docker Desktop.exe') }
    foreach ($c in $candidates) { if (Test-Path -LiteralPath $c) { return $c } }
    return $null
}

# Tìm docker.exe; vừa cài xong Docker Desktop thì PATH của cửa sổ cũ chưa có, nên dò thêm thư mục cài đặt.
function Find-DockerCli {
    $cmd = Get-Command docker -ErrorAction SilentlyContinue
    if ($null -ne $cmd) { return $cmd.Source }
    $candidates = @()
    if ($env:ProgramFiles) { $candidates += (Join-Path $env:ProgramFiles 'Docker\Docker\resources\bin\docker.exe') }
    if ($env:LOCALAPPDATA) { $candidates += (Join-Path $env:LOCALAPPDATA 'Programs\DockerDesktop\resources\bin\docker.exe') }
    foreach ($c in $candidates) {
        if (Test-Path -LiteralPath $c) {
            $env:PATH = (Split-Path $c -Parent) + [IO.Path]::PathSeparator + $env:PATH
            return $c
        }
    }
    return $null
}

function Test-DockerEngine {
    $r = Invoke-Native 'docker' @('info', '--format', '{{.ServerVersion}}')
    return ($r.ExitCode -eq 0 -and $r.Output.Trim() -ne '')
}

# Kiểm tra Docker Desktop đã cài và đang chạy; nếu chưa chạy thì thử mở và chờ.
function Initialize-Docker([int]$WaitSeconds = 240) {
    if ($null -eq (Find-DockerCli)) {
        Write-Fail 'Chưa cài Docker Desktop (không tìm thấy lệnh docker).'
        Write-Info 'Tải và cài tại: https://www.docker.com/products/docker-desktop/'
        Write-Info 'Cài xong, mở Docker Desktop một lần, chấp nhận điều khoản, rồi chạy lại script này.'
        return $false
    }
    if (Test-DockerEngine) { Write-Ok 'Docker Desktop đang chạy.'; return $true }

    $exe = Find-DockerDesktopExe
    if ($null -ne $exe) {
        Write-Warn 'Docker Desktop chưa chạy, đang mở giúp bạn...'
        Start-Process -FilePath $exe | Out-Null
    } else {
        Write-Warn 'Docker Desktop chưa chạy. Hãy mở "Docker Desktop" từ menu Start.'
    }
    Write-Info "Đang chờ Docker khởi động (tối đa $WaitSeconds giây; lần đầu có thể phải bấm Accept điều khoản)..."
    $deadline = (Get-Date).AddSeconds($WaitSeconds)
    while ((Get-Date) -lt $deadline) {
        Start-Sleep -Seconds 5
        if (Test-DockerEngine) { Write-Ok 'Docker Desktop đã sẵn sàng.'; return $true }
    }
    Write-Fail 'Docker Desktop vẫn chưa sẵn sàng.'
    Write-Info 'Mở Docker Desktop, đợi góc dưới bên trái báo "Engine running", rồi chạy lại script.'
    Write-Info 'Nếu Docker báo lỗi WSL: mở PowerShell và chạy  wsl --update  rồi khởi động lại máy.'
    return $false
}

function Test-ComposeAvailable {
    $r = Invoke-Native 'docker' @('compose', 'version', '--short')
    return ($r.ExitCode -eq 0)
}

# Đọc cài đặt "Start Docker Desktop when you sign in". Trả về $true/$false, hoặc $null nếu không xác định được.
function Get-DockerAutoStart {
    if (-not $env:APPDATA) { return $null }
    foreach ($name in @('settings-store.json', 'settings.json')) {
        $p = Join-Path (Join-Path $env:APPDATA 'Docker') $name
        if (-not (Test-Path -LiteralPath $p)) { continue }
        try {
            $text = Read-TextFile $p
            $m = [regex]::Match($text, '"[Aa]utoStart"\s*:\s*(true|false)')
            if ($m.Success) { return ($m.Groups[1].Value -eq 'true') }
        } catch { Write-Verbose "Không đọc được $p" }
    }
    return $null
}

function Write-DockerAutoStartAdvice {
    $auto = Get-DockerAutoStart
    if ($auto -eq $true) { Write-Ok 'Docker Desktop tự chạy khi đăng nhập Windows.'; return }
    if ($auto -eq $false) {
        Write-Warn 'Docker Desktop CHƯA bật tự chạy khi đăng nhập Windows.'
    } else {
        Write-Warn 'Không đọc được cài đặt tự chạy của Docker Desktop, hãy tự kiểm tra.'
    }
    Write-Info 'Docker Desktop > Settings (bánh răng) > General > bật "Start Docker Desktop when you sign in to your computer".'
}

# ------------------------------------------------------------------------------------------------ HTTP

# Gửi HTTP bằng HttpClient (giống nhau trên PowerShell 5.1 và 7). Không ném lỗi: trả về Status = 0 khi không kết nối được.
function Invoke-HttpRequest {
    param(
        [string]$Method = 'GET',
        [Parameter(Mandatory = $true)][string]$Url,
        [hashtable]$Headers = @{},
        [byte[]]$Body = $null,
        [string]$ContentType = 'application/json',
        [int]$TimeoutSec = 15,
        [string]$UserAgent = 'PersonalApp-windows-scripts/1.0',
        # Không gửi header bỏ qua trang cảnh báo của ngrok (test-sepay: gửi giống SePay, để lộ ra trang đó nếu có).
        [switch]$NoNgrokBypass
    )
    Add-Type -AssemblyName System.Net.Http
    $client = New-Object System.Net.Http.HttpClient
    $client.Timeout = [TimeSpan]::FromSeconds($TimeoutSec)
    try {
        $req = [System.Net.Http.HttpRequestMessage]::new([System.Net.Http.HttpMethod]::new($Method), $Url)
        [void]$req.Headers.TryAddWithoutValidation('User-Agent', $UserAgent)
        # Gói miễn phí của ngrok có trang cảnh báo cho trình duyệt; header này bỏ qua trang đó.
        if (-not $NoNgrokBypass) { [void]$req.Headers.TryAddWithoutValidation('ngrok-skip-browser-warning', '1') }
        foreach ($k in $Headers.Keys) { [void]$req.Headers.TryAddWithoutValidation($k, [string]$Headers[$k]) }
        if ($null -ne $Body) {
            $content = [System.Net.Http.ByteArrayContent]::new($Body)
            $content.Headers.ContentType = [System.Net.Http.Headers.MediaTypeHeaderValue]::new($ContentType)
            $req.Content = $content
        }
        $resp = $client.SendAsync($req).GetAwaiter().GetResult()
        $text = $resp.Content.ReadAsStringAsync().GetAwaiter().GetResult()
        return [pscustomobject]@{ Status = [int]$resp.StatusCode; Body = $text; Error = $null }
    } catch {
        $e = $_.Exception
        while ($null -ne $e.InnerException) { $e = $e.InnerException }
        $msg = $e.Message
        if ($e -is [System.Threading.Tasks.TaskCanceledException] -or $e -is [System.TimeoutException]) {
            $msg = "hết thời gian chờ ($TimeoutSec giây)"
        }
        return [pscustomobject]@{ Status = 0; Body = ''; Error = $msg }
    } finally {
        $client.Dispose()
    }
}

# Đọc mảng JSON thành mảng phẳng. (PowerShell 5.1 trả cả mảng thành MỘT đối tượng, nên không dùng @(... | ConvertFrom-Json).)
function ConvertFrom-JsonList([string]$Text) {
    $parsed = $Text | ConvertFrom-Json
    $list = New-Object System.Collections.Generic.List[object]
    foreach ($item in $parsed) { if ($null -ne $item) { $list.Add($item) } }
    return , $list.ToArray()
}

function ConvertTo-JsonBytes($Object) {
    $json = $Object | ConvertTo-Json -Compress -Depth 6
    return , ([System.Text.Encoding]::UTF8.GetBytes($json))
}

function Wait-HttpOk([string]$Url, [int]$TimeoutSec = 120, [int]$IntervalSec = 3) {
    $deadline = (Get-Date).AddSeconds($TimeoutSec)
    $last = $null
    do {
        $last = Invoke-HttpRequest -Url $Url -TimeoutSec 10
        if ($last.Status -eq 200) { return $last }
        Start-Sleep -Seconds $IntervalSec
    } while ((Get-Date) -lt $deadline)
    return $last
}

# Cổng của server trên máy này (HOST_PORT trong .env, mặc định 8000; khớp docker-compose.yml).
function Get-HostPort([hashtable]$Cfg) {
    $p = (Get-EnvValue $Cfg 'HOST_PORT').Trim()
    if ($p -match '^[0-9]{1,5}$' -and [int]$p -ge 1 -and [int]$p -le 65535) { return [int]$p }
    return 8000
}

function Get-LocalBaseUrl([hashtable]$Cfg) {
    $bind = (Get-EnvValue $Cfg 'BIND_ADDR').Trim()
    $port = Get-HostPort $Cfg
    if ($bind -eq '' -or $bind -eq '0.0.0.0' -or $bind -eq '127.0.0.1') { return "http://127.0.0.1:$port" }
    return "http://${bind}:$port"
}

# Đổi chuỗi thời gian ISO của server (luôn là giờ UTC, có "Z") sang giờ máy này.
# PowerShell 7 tự đổi chuỗi ISO trong JSON thành [DateTime]; PowerShell 5.1 để nguyên chuỗi: nhận cả hai.
function Format-LocalTime($Value) {
    if ($null -eq $Value -or ($Value -is [string] -and $Value -eq '')) { return 'chưa có' }
    try {
        if ($Value -is [DateTime]) {
            $dt = $Value
            if ($dt.Kind -eq [DateTimeKind]::Unspecified) { $dt = [DateTime]::SpecifyKind($dt, [DateTimeKind]::Utc) }
            return $dt.ToLocalTime().ToString('HH:mm dd/MM/yyyy', [Globalization.CultureInfo]::InvariantCulture)
        }
        if ($Value -is [DateTimeOffset]) {
            return $Value.ToLocalTime().ToString('HH:mm dd/MM/yyyy', [Globalization.CultureInfo]::InvariantCulture)
        }
        $dto = [DateTimeOffset]::Parse([string]$Value, [Globalization.CultureInfo]::InvariantCulture,
            [Globalization.DateTimeStyles]::AssumeUniversal)
        return $dto.ToLocalTime().ToString('HH:mm dd/MM/yyyy', [Globalization.CultureInfo]::InvariantCulture)
    } catch { return [string]$Value }
}

# Mô tả ngắn một phản hồi HTTP lỗi (không in bí mật).
function Format-HttpProblem($Response) {
    if ($null -eq $Response) { return 'không có phản hồi' }
    if ($Response.Status -eq 0) { return "không kết nối được: $($Response.Error)" }
    $code = [regex]::Match([string]$Response.Body, 'ERR_NGROK_[0-9]+')
    if ($code.Success) { return "HTTP $($Response.Status), lỗi ngrok $($code.Value)" }
    return "HTTP $($Response.Status)"
}

# In N dòng log cuối của một dịch vụ, bỏ các dòng ngrok ghi lại chính những lần script hỏi API cục bộ của nó.
# Mọi khoá trong .env bị thay bằng *** (vd. lỗi ERR_NGROK_105 của ngrok in nguyên authtoken ra log).
function Show-ComposeLog([string]$Root, [string]$Service, [int]$Lines = 30) {
    $r = Invoke-Native 'docker' ((Get-ComposeArgs $Root) + @('--profile', 'ngrok', 'logs', '--no-color', '--timestamps', '--tail', '400', $Service))
    $text = $r.Output
    $cfg = Read-DotEnv (Join-Path $Root '.env')
    foreach ($k in @('APP_TOKEN', 'SEPAY_API_KEY', 'SEPAY_HMAC_SECRET', 'CASSO_SECURE_KEY', 'NGROK_AUTHTOKEN',
                     'TELEGRAM_BOT_TOKEN', 'IMAP_PASSWORD', 'CLOUDFLARE_TUNNEL_TOKEN', 'FCM_SERVICE_ACCOUNT_JSON')) {
        $v = Get-EnvValue $cfg $k
        if ($v.Length -ge 8) { $text = $text.Replace($v, '***') }
    }
    $kept = @($text -split "`n" | Where-Object { $_ -notmatch 'pg=/api/(tunnels|endpoints)' -and $_.Trim() -ne '' })
    Write-Info "--- $Lines dòng log cuối của $Service ---"
    if ($kept.Count -gt $Lines) { $kept = $kept[($kept.Count - $Lines)..($kept.Count - 1)] }
    foreach ($l in $kept) { Write-Host "  $l" }
    Write-Info '--- hết log ---'
}

# ------------------------------------------------------------------------------------------------ ngrok

# Hỏi API cục bộ của ngrok agent (cổng 4040 bên trong container, không mở ra ngoài) xem địa chỉ public hiện tại.
function Get-NgrokPublicUrl([string]$Root) {
    $a = (Get-ComposeArgs $Root) + @('--profile', 'ngrok', 'exec', '-T', 'ngrok', 'wget', '-q', '-O', '-', 'http://127.0.0.1:4040/api/tunnels')
    $r = Invoke-Native 'docker' $a
    if ($r.ExitCode -ne 0) { return $null }
    foreach ($pattern in @('"public_url"\s*:\s*"(https://[^"]+)"', '"url"\s*:\s*"(https://[^"]+)"')) {
        $m = [regex]::Match($r.Output, $pattern)
        if ($m.Success) { return $m.Groups[1].Value.TrimEnd('/') }
    }
    return $null
}

function Wait-NgrokPublicUrl([string]$Root, [int]$TimeoutSec = 60) {
    $deadline = (Get-Date).AddSeconds($TimeoutSec)
    do {
        $u = Get-NgrokPublicUrl $Root
        if ($u) { return $u }
        Start-Sleep -Seconds 3
    } while ((Get-Date) -lt $deadline)
    return $null
}

# ------------------------------------------------------------------------------------------------ Telegram

# Kiểm tra token bot bằng getMe. Trả về @{ Ok; Username; Error; Network }.
function Get-TelegramBotInfo([string]$Token) {
    $r = Invoke-HttpRequest -Url ("https://api.telegram.org/bot" + $Token + "/getMe") -TimeoutSec 15
    if ($r.Status -eq 0) { return [pscustomobject]@{ Ok = $false; Username = ''; Error = $r.Error; Network = $true } }
    try { $data = $r.Body | ConvertFrom-Json } catch { $data = $null }
    if ($r.Status -eq 200 -and $null -ne $data -and $data.ok) {
        return [pscustomobject]@{ Ok = $true; Username = [string]$data.result.username; Error = $null; Network = $false }
    }
    $desc = "HTTP $($r.Status)"
    if ($null -ne $data -and $data.description) { $desc = [string]$data.description }
    return [pscustomobject]@{ Ok = $false; Username = ''; Error = $desc; Network = $false }
}

# Thoát ký tự đặc biệt cho parse_mode=HTML của Telegram.
function ConvertTo-TelegramHtml([string]$Text) {
    return ("" + $Text).Replace('&', '&amp;').Replace('<', '&lt;').Replace('>', '&gt;')
}

# Gửi tin. -Html: $Text là HTML của Telegram (vd. <code>...</code>: trên điện thoại chạm một lần là chép đúng phần đó).
# Trả về @{ Ok; Error; MessageId } (MessageId dùng để xoá tin sau).
function Send-TelegramText([string]$Token, [string]$ChatId, [string]$Text, [switch]$Html) {
    $payload = [ordered]@{ chat_id = $ChatId; text = $Text; disable_web_page_preview = $true }
    if ($Html) { $payload['parse_mode'] = 'HTML' }
    $r = Invoke-HttpRequest -Method 'POST' -Url ("https://api.telegram.org/bot" + $Token + "/sendMessage") `
        -Body (ConvertTo-JsonBytes $payload) -TimeoutSec 15
    $data = $null
    try { $data = $r.Body | ConvertFrom-Json } catch { Write-Verbose 'Phản hồi Telegram không phải JSON.' }
    if ($r.Status -eq 200) {
        $id = $null
        if ($null -ne $data -and $null -ne $data.result) { $id = $data.result.message_id }
        return [pscustomobject]@{ Ok = $true; Error = $null; MessageId = $id }
    }
    $desc = Format-HttpProblem $r
    if ($null -ne $data -and $data.description) { $desc = [string]$data.description }
    return [pscustomobject]@{ Ok = $false; Error = $desc; MessageId = $null }
}

# Xoá một tin bot đã gửi (Telegram cho bot xoá tin của chính nó trong chat riêng, trong vòng 48 giờ).
function Remove-TelegramMessage([string]$Token, [string]$ChatId, $MessageId) {
    if ($null -eq $MessageId) { return $false }
    $payload = [ordered]@{ chat_id = $ChatId; message_id = $MessageId }
    $r = Invoke-HttpRequest -Method 'POST' -Url ("https://api.telegram.org/bot" + $Token + "/deleteMessage") `
        -Body (ConvertTo-JsonBytes $payload) -TimeoutSec 15
    return ($r.Status -eq 200)
}

# ------------------------------------------------------------------------------------------------ clipboard

# Chép một BÍ MẬT vào clipboard sao cho Windows không lưu vào Lịch sử clipboard (Win+V) và không đồng bộ lên mây:
# đặt kèm các định dạng ExcludeClipboardContentFromMonitorProcessing / CanIncludeInClipboardHistory=0 /
# CanUploadToCloudClipboard=0 (Windows 10 1809 trở lên tôn trọng các định dạng này). Không được thì chép bình thường.
# Trả về 'private' (đã chép, không vào lịch sử) | 'plain' (đã chép kiểu thường) | '' (không chép được).
function Set-ClipboardSecret([string]$Text) {
    try {
        Add-Type -AssemblyName System.Windows.Forms -ErrorAction Stop
        $data = New-Object System.Windows.Forms.DataObject
        $data.SetData([System.Windows.Forms.DataFormats]::UnicodeText, $Text)
        $zero = [byte[]](0, 0, 0, 0)
        $data.SetData('ExcludeClipboardContentFromMonitorProcessing', ([System.IO.MemoryStream]::new($zero)))
        $data.SetData('CanIncludeInClipboardHistory', ([System.IO.MemoryStream]::new($zero)))
        $data.SetData('CanUploadToCloudClipboard', ([System.IO.MemoryStream]::new($zero)))
        [System.Windows.Forms.Clipboard]::SetDataObject($data, $true)
        return 'private'
    } catch {
        Write-Verbose "Không chép kiểu riêng tư được: $($_.Exception.Message)"
    }
    if (Set-ClipboardText $Text) { return 'plain' }
    return ''
}

# Xoá nội dung clipboard hiện tại (thay bằng một dấu cách).
function Clear-ClipboardText {
    try {
        Add-Type -AssemblyName System.Windows.Forms -ErrorAction Stop
        [System.Windows.Forms.Clipboard]::Clear()
        return $true
    } catch { Write-Verbose 'Clipboard.Clear lỗi.' }
    return (Set-ClipboardText ' ')
}

function Set-ClipboardText([string]$Text) {
    if (Get-Command Set-Clipboard -ErrorAction SilentlyContinue) {
        try { Set-Clipboard -Value $Text -ErrorAction Stop; return $true } catch { Write-Verbose 'Set-Clipboard lỗi.' }
    }
    $clip = Get-Command clip.exe -ErrorAction SilentlyContinue
    if ($null -ne $clip) {
        try { $Text | & $clip.Source; return ($LASTEXITCODE -eq 0) } catch { Write-Verbose 'clip.exe lỗi.' }
    }
    return $false
}

# ------------------------------------------------------------------------------------------------ an toàn

# Cảnh báo nếu thư mục code nằm trong OneDrive (file .env chứa khoá bí mật sẽ bị tải lên mây).
function Test-InOneDrive([string]$Path) {
    foreach ($od in @($env:OneDrive, $env:OneDriveConsumer, $env:OneDriveCommercial)) {
        if ($od -and $Path.StartsWith($od, [StringComparison]::OrdinalIgnoreCase)) { return $true }
    }
    return $false
}

# Đường dẫn có dấu tiếng Việt / ký tự ngoài ASCII hoặc dấu cách (vd. C:\Users\Tân): Docker Desktop từng có lỗi với
# đường dẫn như vậy khi build và mount thư mục. Trả về $true nếu nên chuyển sang chỗ đơn giản như C:\PersonalApp.
function Test-RiskyPath([string]$Path) {
    return ($Path -match '[^\x21-\x7E]')
}

# ------------------------------------------------------------------------------------------------ COMPOSE_PROFILES

# Thêm/bỏ "ngrok" trong giá trị COMPOSE_PROFILES (danh sách phân cách bằng dấu phẩy), giữ các profile khác.
function Get-ComposeProfilesValue([string]$Current, [bool]$UseNgrok) {
    $list = New-Object System.Collections.Generic.List[string]
    foreach ($p in (("" + $Current) -split ',')) {
        $t = $p.Trim()
        if ($t -ne '' -and $t -ne 'ngrok' -and -not $list.Contains($t)) { $list.Add($t) }
    }
    if ($UseNgrok) { $list.Insert(0, 'ngrok') }
    return ($list -join ',')
}

# Ghi COMPOSE_PROFILES vào .env cho khớp NGROK_AUTHTOKEN: docker compose tự đọc biến này từ .env của dự án,
# nên cả lệnh "docker compose up -d" gõ tay (hay nút trong Docker Desktop) cũng chạy/cập nhật container ngrok.
# Trả về $true nếu đã đổi file.
function Update-ComposeProfiles([string]$EnvPath) {
    $cfg = Read-DotEnv $EnvPath
    $useNgrok = (Get-EnvValue $cfg 'NGROK_AUTHTOKEN') -ne ''
    $current = Get-EnvValue $cfg 'COMPOSE_PROFILES'
    $wanted = Get-ComposeProfilesValue $current $useNgrok
    if ($wanted -eq $current) { return $false }
    Set-DotEnvValues $EnvPath ([ordered]@{ COMPOSE_PROFILES = $wanted })
    return $true
}
