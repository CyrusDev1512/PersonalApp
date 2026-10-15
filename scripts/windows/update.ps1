<#
.SYNOPSIS
    Cập nhật server Chi tiêu lên bản code mới nhất: git pull rồi docker compose up -d --build.
    Dữ liệu (volume personalapp_app-data) và file .env được giữ nguyên.

.PARAMETER NoPull
    Không tải code mới, chỉ build và khởi động lại (vd. sau khi sửa .env bằng tay).

.EXAMPLE
    Nháy đúp scripts\windows\update.cmd
#>
[CmdletBinding()]
param(
    [switch]$NoPull
)

$ErrorActionPreference = 'Stop'
. (Join-Path (Join-Path $PSScriptRoot 'lib') 'common.ps1')
Initialize-Console

$Root = Get-RepoRoot
$EnvPath = Join-Path $Root '.env'
$ExamplePath = Join-Path $Root '.env.example'

Write-Title 'CẬP NHẬT SERVER CHI TIÊU'

if (-not (Test-Path -LiteralPath $EnvPath)) {
    Write-Fail 'Chưa có file .env. Đây là lần cài đầu tiên? Chạy setup.cmd.'
    exit 1
}

# 1. Docker
Write-Step '1/4  Kiểm tra Docker Desktop'
if (-not (Initialize-Docker)) { exit 1 }

# 2. Code mới
Write-Step '2/4  Tải code mới'
if ($NoPull) {
    Write-Info 'Bỏ qua (-NoPull).'
} elseif (-not (Test-Path -LiteralPath (Join-Path $Root '.git'))) {
    Write-Warn 'Thư mục này không phải bản git clone (có thể bạn đã tải file ZIP), nên không tự tải code mới được.'
    Write-Info 'Cách cập nhật bản ZIP: tải ZIP mới của ĐÚNG nhánh đang dùng (tài liệu, bước 5 cách B và bước 11),'
    Write-Info 'giải nén ĐÈ lên thư mục này (giữ file .env), rồi chạy lại update.cmd. Dữ liệu nằm trong Docker nên không mất.'
    if (-not (Read-YesNo '       Vẫn build lại với code hiện có?' $true)) { exit 1 }
} elseif ($null -eq (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Fail 'Chưa cài Git. Tải tại https://git-scm.com/download/win rồi chạy lại.'
    exit 1
} else {
    $st = Invoke-Native 'git' @('-C', $Root, 'status', '--porcelain', '--untracked-files=no')
    if ($st.ExitCode -eq 0 -and $st.Output.Trim() -ne '') {
        Write-Warn 'Có file trong code đã bị sửa trên máy này (git sẽ không ghi đè):'
        foreach ($l in ($st.Output -split "`n")) { Write-Info $l }
    }
    $dirty = ($st.ExitCode -eq 0 -and $st.Output.Trim() -ne '')
    $branch = (Invoke-Native 'git' @('-C', $Root, 'rev-parse', '--abbrev-ref', 'HEAD')).Output.Trim()
    $before = (Invoke-Native 'git' @('-C', $Root, 'rev-parse', '--short', 'HEAD')).Output.Trim()
    Write-Info "Nhánh: $branch, bản hiện tại: $before"

    # Nhánh đang theo dõi còn trên GitHub không? (vd. nhánh cài đặt đã được gộp vào main rồi bị xoá)
    $up = Invoke-Native 'git' @('-C', $Root, 'rev-parse', '--abbrev-ref', '--symbolic-full-name', '@{u}')
    $upstream = $up.Output.Trim()
    if ($up.ExitCode -eq 0 -and $upstream -match '^([^/]+)/(.+)$') {
        $remote = $Matches[1]
        $remoteBranch = $Matches[2]
        $ls = Invoke-Native 'git' @('-C', $Root, 'ls-remote', '--exit-code', '--heads', $remote, $remoteBranch)
        if ($ls.ExitCode -eq 2) {
            Write-Warn "Nhánh $remoteBranch không còn trên GitHub (thường vì đã được gộp vào main rồi xoá)."
            $main = Invoke-Native 'git' @('-C', $Root, 'ls-remote', '--exit-code', '--heads', $remote, 'main')
            if ($main.ExitCode -ne 0) {
                Write-Fail 'Không thấy nhánh main trên GitHub. Nhờ người hỗ trợ chỉ nhánh cần dùng.'
                exit 1
            }
            if ($dirty) {
                Write-Fail 'Không chuyển sang main được vì có file bị sửa tay (danh sách ở trên). Nhờ người hỗ trợ.'
                exit 1
            }
            if (-not (Read-YesNo '       Chuyển sang nhánh main (bản chính thức) và cập nhật?' $true)) { exit 1 }
            # Bản clone "một nhánh" (--single-branch) chỉ theo dõi nhánh cũ: chuyển sang theo dõi nhánh main, nếu không
            # git pull sau này vẫn đi tìm nhánh đã bị xoá và báo lỗi. (Không truyền '*' cho git: tránh bị bung thành tên file.)
            $specs = (Invoke-Native 'git' @('-C', $Root, 'config', '--get-all', "remote.$remote.fetch")).Output
            if ($specs -notmatch 'refs/heads/\*') {
                [void](Invoke-Native 'git' @('-C', $Root, 'remote', 'set-branches', $remote, 'main'))
            }
            $f = Invoke-NativeLive 'git' @('-C', $Root, 'fetch', $remote, "+refs/heads/main:refs/remotes/$remote/main")
            if ($f -ne 0) { Write-Fail 'Không tải được nhánh main (xem thông báo phía trên). Kiểm tra Internet / đăng nhập GitHub.'; exit 1 }
            $hasLocalMain = (Invoke-Native 'git' @('-C', $Root, 'rev-parse', '--verify', '--quiet', 'refs/heads/main')).ExitCode -eq 0
            if ($hasLocalMain) {
                $sw = Invoke-NativeLive 'git' @('-C', $Root, 'switch', 'main')
                if ($sw -eq 0) { $sw = Invoke-NativeLive 'git' @('-C', $Root, 'branch', '--set-upstream-to', "$remote/main", 'main') }
            } else {
                $sw = Invoke-NativeLive 'git' @('-C', $Root, 'switch', '--create', 'main', '--track', "$remote/main")
            }
            if ($sw -ne 0) { Write-Fail 'Không chuyển được sang nhánh main (xem thông báo phía trên). Server cũ vẫn chạy.'; exit 1 }
            Write-Ok 'Đã chuyển sang nhánh main.'
        } elseif ($ls.ExitCode -ne 0) {
            Write-Fail 'Không hỏi được GitHub (xem thông báo phía trên). Server cũ vẫn đang chạy, chưa có gì thay đổi.'
            Write-Info 'Kiểm tra Internet; kho code riêng tư thì cần đăng nhập GitHub (Git for Windows sẽ mở cửa sổ đăng nhập).'
            Write-Info ($ls.Output.Trim())
            exit 1
        }
    }

    $code = Invoke-NativeLive 'git' @('-C', $Root, 'pull', '--ff-only')
    if ($code -ne 0) {
        Write-Fail 'git pull thất bại (xem thông báo phía trên). Server cũ vẫn đang chạy, chưa có gì thay đổi.'
        if ($dirty) {
            Write-Info 'Nguyên nhân có thể là các file bị sửa tay liệt kê ở trên. Nhờ người hỗ trợ, hoặc tải bản ZIP mới (giữ lại file .env).'
        } else {
            Write-Info 'Thường do mất mạng, chưa đăng nhập GitHub, hoặc code trên máy đã khác bản trên GitHub. Nhờ người hỗ trợ.'
        }
        exit 1
    }
    $after = (Invoke-Native 'git' @('-C', $Root, 'rev-parse', '--short', 'HEAD')).Output.Trim()
    if ($before -eq $after) { Write-Ok "Code đã là bản mới nhất ($after)." }
    else { Write-Ok "Đã cập nhật code: $before -> $after" }
}

# 3. .env: thêm biến mới (nếu có), sửa mã hoá nếu cần
Write-Step '3/4  Kiểm tra file .env'
$state = Initialize-EnvFile $EnvPath $ExamplePath
if ($state -eq 'repaired') { Write-Warn 'File .env đang lưu dạng UTF-16 hoặc có BOM: đã chuyển sang UTF-8.' }
$added = Add-MissingEnvKeys $EnvPath $ExamplePath
if ($added.Count -gt 0) {
    Write-Warn ('Bản mới có thêm biến cấu hình: ' + ($added -join ', ') + '. Nháy đúp doi-cau-hinh.cmd nếu cần điền.')
} else {
    Write-Ok 'Không có biến cấu hình mới.'
}
if (Update-ComposeProfiles $EnvPath) {
    Write-Ok 'Đã cập nhật COMPOSE_PROFILES trong .env (để lệnh "docker compose up -d" gõ tay cũng chạy đúng ngrok).'
}
$Cfg = Read-DotEnv $EnvPath
$useNgrok = (Get-EnvValue $Cfg 'NGROK_AUTHTOKEN') -ne ''

# 4. Build + chạy lại
Write-Step '4/4  Build và khởi động lại (mất vài phút)'
$a = Get-ComposeArgs $Root
if ($useNgrok) { $a += @('--profile', 'ngrok') }
$code = Invoke-NativeLive 'docker' ($a + @('up', '-d', '--build'))
if ($code -ne 0) {
    Write-Fail "docker compose báo lỗi (mã $code). Xem thông báo phía trên; chạy status.cmd để kiểm tra."
    exit 1
}
$local = Get-LocalBaseUrl $Cfg
$r = Wait-HttpOk "$local/health" 120
if ($r.Status -ne 200) {
    Write-Fail ('Server chưa trả lời sau khi cập nhật: ' + (Format-HttpProblem $r) + '. Chạy status.cmd để xem log.')
    exit 1
}
Write-Ok 'Server đã chạy bản mới.'
$domain = ConvertTo-NgrokDomain (Get-EnvValue $Cfg 'NGROK_DOMAIN')
if ($useNgrok -and $domain -ne '') {
    $p = Wait-HttpOk "https://$domain/health" 45
    if ($p.Status -eq 200) { Write-Ok "Từ Internet gọi được: https://$domain" }
    else { Write-Warn ('Chưa gọi được qua Internet: ' + (Format-HttpProblem $p) + '. Chạy status.cmd.') }
}

# Dọn image cũ không còn dùng (chỉ image "dangling", không đụng tới dữ liệu).
[void](Invoke-Native 'docker' @('image', 'prune', '--force'))
Write-Ok 'Đã dọn các image cũ không còn dùng.'
exit 0
