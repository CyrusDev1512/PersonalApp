Bản phát hành hiện tại: **2026.10.19.4**. EXE gốc và ZIP đã cập nhật; 177 Python + 24 JavaScript + frozen smoke + kiểm thử chính ZIP ngoài repo đạt. Chi tiết: KET-QUA-KIEM-THU-UI.md. Chưa có nghiệm thu máy vật lý sạch khác. Không tự xác nhận bỏ qua bài thật của người dùng.

## Cập nhật 2026.10.19.4 — xác nhận bỏ qua bài chưa rõ kết quả

- Trong Lịch sử → Chi tiết, mở link Bài cần kiểm tra. Sau khi tự kiểm tra, bấm **Đã kiểm tra — bỏ qua bài này** rồi xác nhận.
- Giữ nguyên kết quả chưa rõ và khóa chống gửi trùng bài trên mọi tài khoản trong kho. Ghi nhận riêng hành động kiểm tra; không tự đánh dấu thành công/thất bại và không tự gửi tiếp lượt cũ.
- Chỉ gỡ app hold tương ứng khi mọi lần gửi chưa rõ của tài khoản đã được xử lý và không có lỗi phiên, xác minh hoặc hạn chế khác. Không bỏ khóa tài khoản do Facebook yêu cầu xác minh/hạn chế.
- Ghi nhận kiểm tra và gỡ app hold trong cùng transaction SQLite; lỗi ghi giữ nguyên trạng thái. Kiểm tra đúng account, revision phiên, operation và post; không cho thao tác khi request khác đang chạy.
- Kiểm tra phiên chỉ xác nhận khả năng đọc, không xác minh kết quả bình luận trước.
- ZIP có Python và thư viện đóng gói trong _internal. Không cần repo hoặc venv; cần Windows x64 và Microsoft Edge. Giải nén toàn bộ trước khi mở EXE.
- Máy/người dùng Windows mới tự lưu dữ liệu riêng. Không sao chép kho cookie DPAPI để chuyển tài khoản sang máy khác; nhập phiên lại trên máy đó. Chưa có backup thật.
- Cổng phát hành mới kiểm tra chính ZIP giải nén ngoài repo, từ thư mục chạy trống, xóa biến Python/venv và PATH Python của tiến trình app. Đây không thay thế nghiệm thu trên máy vật lý/VM Windows sạch khác.

## Cập nhật 2026.10.19.3 — đọc đầy đủ nhóm

- Sửa nguyên nhân chỉ lấy trang đầu: dùng cursor của all_joined_groups.tab_groups_list, tiếp tục đến has_next_page=false. Truy vấn chỉ đọc được xác minh từ public JS của chính trang hiện tại, không hardcode docID, không lấy nhóm gợi ý/chờ duyệt.
- Đã kiểm chứng thật bằng thao tác chỉ đọc: tài khoản đang chọn trả 371 nhóm duy nhất qua 19 trang, stop_reason=exhausted, complete=true. Không đăng bình luận, không ghi cookie hoặc raw phản hồi vào tài liệu.
- Đồng bộ vẫn chạy nền; cập nhật số nhóm/số trang sau mỗi trang; có Dừng giữa các request. Kiểm tra revision và jobID trước khi công bố kết quả. Lỗi giữa chừng giữ danh sách đã lưu trước đó.
- Không giả phần trăm khi chưa biết tổng. Cursor lặp, không nhận diện query hoặc giới hạn bảo vệ 500 trang luôn báo chưa đầy đủ, không coi là thành công toàn bộ.
- Lỗi đọc/parser dừng lượt hiện tại nhưng không tạo app hold lâu dài. Dấu hiệu phiên/xác minh/hạn chế vẫn dừng và được lưu riêng. Không tự xóa hold cũ thiếu bằng chứng.
- Thông báo app hold có nút Xem lịch sử; Kiểm tra khả năng đọc không được trình bày là xác nhận kết quả gửi trước hoặc mở khóa gửi. Bản lịch sử cũ thiếu diagnostic không thể suy ra chính xác phản hồi Facebook.
- Không thay cơ chế gửi, chống trùng, không retry và khóa kết quả chưa rõ sau POST. Không có backup thật.
- Sau khi cài bản mới, bấm Đồng bộ lại để cập nhật danh sách cũ; không cần nhập lại cookie chỉ để kích hoạt đồng bộ.

Bản phát hành lịch sử: 2026.10.19.2, 157 Python + 20 JS + frozen smoke + desktop acceptance đạt. EXE root đã cập nhật; xem KET-QUA-KIEM-THU-UI.md. Không suy ra đã test Facebook thật.

## Bản 2026.10.19.2 — giao diện và đồng bộ nền

- Giao diện app thật có panel tài khoản, panel nhóm/nhập link riêng và vùng soạn thảo. Hướng dẫn, lịch sử và chi tiết kết quả vẫn có; không thêm backup thật.
- Lưu tài khoản mới hoặc thay cookie tự xếp lịch đồng bộ nhóm. Đổi tên không gây đồng bộ lại. Có Dừng và Đồng bộ lại; không chạy lại công việc dở khi mở app.
- Đồng bộ chạy nền: tiếp tục soạn, xem lịch sử, thêm/chuyển tài khoản. Thao tác mạng được xếp tuần tự; gửi/lấy bài chờ đồng bộ đang chạy để không chồng request. Khi chưa biết tổng nhóm, thanh tiến độ không hiển thị phần trăm giả.
- Kết quả gắn tài khoản, revision phiên và mã công việc; sửa phiên/xóa tài khoản khiến kết quả cũ không được ghi trở lại. Lỗi đồng bộ không xóa nhóm đã lưu.
- Bộ đọc joined groups hiện chỉ xác minh trang đầu; có trang sau thì báo một phần. Chưa khẳng định đọc đủ danh sách và chưa kiểm chứng Facebook thật trong lượt nghiệm thu này.
- Bản nháp, link và lựa chọn nhóm giữ riêng theo tài khoản trong phiên trang hiện tại; thu gọn/mở lại vẫn giữ. Tải lại trang không phải lưu bản nháp lâu dài.
- Lỗi bài/nguồn, dấu hiệu phiên và app tạm dừng được trình bày riêng. Bài được xác nhận không có quyền bình luận trước POST được bỏ qua. Lỗi chuẩn bị trước POST là chưa gửi; không tự báo tài khoản bị khóa.
- Sau POST mà chưa biết kết quả: dừng lượt, giữ khóa bài và app hold; không retry, không bỏ khóa khi sửa cookie. Chỉ bằng chứng hết phiên/xác minh/hạn chế mới được lưu là session issue. HTTP 200 không đủ xác nhận thành công.
- Lịch sử giữ tên tài khoản/nhóm tại thời điểm xử lý; có tìm kiếm và lọc trong trang lịch sử, mở panel chi tiết. Không ghi cookie/raw response vào chẩn đoán.
- Mỗi kho chỉ có một lượt gửi; chống trùng xuyên tài khoản và khởi động lại giữ nguyên.

# Bàn giao hiện hành — 19/10/2026

## Chẩn đoán thông báo tạm dừng — thay đổi nguồn mới nhất

remote_status không khẳng định yêu cầu xác minh chỉ vì checkpoint_url trong body; vẫn stop dạng unknown. Diagnostic chỉ lưu enum/scope/stage/status; không raw response. GraphQL chỉ đọc message lỗi, không quét debug. UI nói rõ hold là của app. Không auto-clear hold cũ hoặc tiếp tục lượt gửi. 147 Python +16 Node đạt. Thay đổi này chưa build vào EXE/ZIP; không nói app đang mở đã có sửa mới. Xem phần đầu KET-QUA-KIEM-THU-UI.md.

## Sửa lệch phiên bản desktop (bản phát hành trước)

- UI_PROTOCOL trong lab_server.py và app.js phải khớp. /api/state công bố protocol; UI dừng trước mọi POST khi backend cũ/không tương thích. Không retry request gửi.
- make_server snapshot HTML/CSS/JS một lần; không đọc UI mới trên đĩa bằng backend cũ đang chạy. Thay UI cần restart server.
- MO-COMMENT-LAB.cmd mở EXE, không còn chạy Python server 8790. EXE dùng cổng trống tự động.
- desktop.data_root ưu tiên kho hiện có cạnh EXE chỉ khi cả scripts/lab_server.py và private/accounts.sqlite3 tồn tại (bản đặt trong source). ZIP độc lập dùng AppData như trước. Không copy/hợp nhất/đổi schema kho hoặc nhật ký.
- Không sửa luồng đọc bài/gửi; không thêm Page. Kiểm thử phát hành chỉ local/fixture, không đăng Facebook thật.

Phần này và PRODUCT.md ghi đè phạm vi lịch sử phía dưới. Chỉ làm CommentLab tại C:\Tools\FacebookCommentLab; không sửa ASSETCONTROL/Kanban. Không commit/push hoặc gửi bình luận thật trong đợt nghiệm thu này.

## Phạm vi đã triển khai

UI mockup gọn đã đưa vào ui/: tài khoản → nhóm/nhập link → gửi trực tiếp (xem trước tùy chọn) → lịch sử. Nhiều tài khoản nhưng một lượt xử lý trên mỗi kho dữ liệu. Không tự chuyển tài khoản khi hạn chế. Cookie mã hóa Windows DPAPI; không trả qua API. Danh tính c_user duy nhất, đổi ID tạo tài khoản mới. Lịch sử/khóa giữ khi xóa và thêm lại.

## Các module hiện hành

- scripts/account_store.py: SQLite accounts.sqlite3; DPAPI qua ctypes; accounts, blocks, groups_saved, settings. Chỉ metadata ra state. Cookies giải mã trong RAM, không file tạm. DPAPI theo tài khoản Windows, không portable sang Windows user khác.
- scripts/workspace_lab.py: lớp WorkspaceLab kế thừa Lab, mặc định của make_server. Khóa thread + khóa file Windows private/work.lock. Mọi thao tác account_id tường minh. Migration session.json cũ đọc-ghi-giải mã kiểm chứng rồi mới unlink; lỗi giữ nguyên nguồn. Không trộn dữ liệu bản nguồn với desktop.
- scripts/lab_server.py: endpoint mới accounts/save|select|delete|recheck, groups/sync, links/check|load, review/prepare|send, send/direct, history, work/stop; Host/Origin/CSRF và loopback giữ nguyên. Các POST session/preview/send/batch cũ bị 409 khi dùng WorkspaceLab, không bỏ qua kho tài khoản/khóa mới. Lab cũ vẫn dùng trong regression test.
- scripts/joined_groups.py: GET groups/joins/, chỉ GroupsCometJoinsRootQuery, actorID khớp, viewer.all_joined_groups.tab_groups_list và MEMBER. Kiểm tra page_info. Hiện chỉ trang đầu; more=true luôn partial, KHÔNG nói lấy hết; không đoán docID cho trang sau.
- scripts/group_feed.py: đọc 10/20/50 bài mới nhất, strict kiểm tra remote. Link bài cụ thể hiện đối chiếu trong danh sách đó; ngoài danh sách hoặc không có chữ sẽ báo chưa đọc được, không tạo nội dung giả. Missing permission tại một nhóm không làm mất bài đọc được của nhóm khác; lỗi phiên/xác minh/unknown dừng toàn lượt.
- scripts/remote_status.py: phân loại login, checkpoint, 429, GraphQL, unknown. Không log response hay cookie.
- scripts/comment_probe.py: nhận cookies in-memory; strict reserve trong BEGIN IMMEDIATE, post_locks dùng post_id duy nhất xuyên tài khoản. Backfill nhật ký cũ; reserved/unknown cũng khóa. content_hash NFKC/whitespace/casefold giữ metadata nội dung; cho phép cùng nội dung ở các bài khác nhau. Khóa bài xuyên tài khoản vẫn bắt buộc. Nhật ký cũ không có content_hash không thể phục dựng text, nhưng vẫn giữ khóa bài.
- UI app.js: tài khoản/phiên revision và bài/nội dung đóng băng 10 phút, không yêu cầu approved. Nút Gửi trực tiếp dùng /api/send/direct và giữ global lock xuyên đọc/gửi. Xem trước dùng prepare/send bên trong khi bấm Gửi. Đồng bộ/lấy bài/gửi có Dừng; đồng bộ dùng SyncJobs riêng, stop_sync không dừng lượt gửi. Không dùng native confirm cho xóa; xác nhận trong panel.
- scripts/desktop.py, desktop_window.py: một Edge app window, theo dõi cây Edge relaunch. Không console/launcher. Dữ liệu %LOCALAPPDATA%\CommentLab; source server dùng root riêng. Không dùng cả hai kho để gửi cùng bài vì lịch sử không tự hợp nhất.

## Các giới hạn phải nói thật

1. Đồng bộ joined groups mới trang đầu. Khảo sát read-only thật đọc được20 MEMBER, has_next_page=true. Chưa triển khai hoặc kiểm chứng phân trang tiếp theo.
2. Bài link cũ ngoài 10/20/50 bài mới nhất chưa đọc độc lập. Page, share, pfbid chưa hỗ trợ.
3. Luồng gửi nghiệm thu bằng fixture; KHÔNG đã gửi thật. confirmed_by_response chỉ là phản hồi phù hợp, không phải bằng chứng hiển thị cuối cùng trên Facebook.
4. Restricted/checkpoint/unknown giữ khóa qua đổi cookie, restart, xóa/thêm tài khoản. Kiểm tra đọc thành công chỉ có thể gỡ session_expired, không chứng minh quyền gửi. Không có bypass unknown.
5. Chỉ1 request gửi tại một thời điểm, tổng tối đa50 bài/lượt; không dùng nhiều tài khoản song song, không tạo nội dung né phát hiện.
6. EXE chưa ký số và chưa thử trên máy sạch khác. Không bảo đảm tránh khóa Facebook.

## Kiểm thử / build

Python: build\desktop-venv\Scripts\python.exe
- -X utf8 -m unittest discover -s tests -q
- Node: node --check ui/app.js
- -X utf8 -m scripts.build_desktop: full suite → PyInstaller → frozen smoke → desktop acceptance → scan kho dữ liệu → ZIP + SHA256.
- tests/workspace_fixture.py chạy8794 bằng dữ liệu giả, chặn mọi external request; UI được phép gửi giả tại đây.
- tests/test_workspace.py, test_joined_groups.py bổ sung các ca vault, khóa, account switch, partial sync, read error, stale preview, injection, duplicate và dừng.
- tests/desktop_acceptance.py dùng temp LOCALAPPDATA và Edge thật: save, link validation, singleton, idle30s, process-tree shutdown, reopen. Không mô tả process shutdown là click nút×. Kết quả trong dist/desktop-acceptance.json.
- Báo cáo mới ở KET-QUA-KIEM-THU-UI.md. Số ca cũ phía dưới là lịch sử, không dùng làm kết quả bản mới.

## Đóng gói / cập nhật

Bản gốc dist\CommentLab\CommentLab.exe + _internal. Root CommentLab.exe phải luôn đi cùng _internal đồng bộ. ZIP Desktop CommentLab-Windows-x64.zip + .sha256. Không ghi đè bundle đang chạy; không đưa private, profiles, .probe, cookie JSON, database hay log thật vào ZIP. Không thêm dependency production trong đợt này. Không quét Chrome cookie hoặc đưa bí mật ra chat/log.

---


Bổ sung hiện hành: limit50 là tổng toàn lượt; đã sửa phân trang, kiểm tra chỉ đọc19/10 lấy50 ID riêng biệt qua8 trang. scripts/feed_pagination.py giải query từ public JS asset của trang hiện tại, không cookies ở CDN, không hardcode ID/execute JS; group_feed dùng cursor, chặn cursor lặp, max10trang, complete/stop_reason/pages_read. Không hứa đủ nếu nguồn không cho đọc tiếp. history_page phân trang50. probe context allowlist account_name/group_name/group_url lưu trong reservation trướcPOST; không lưu cookie. Tên snapshot giữ khi đổi/xóa tài khoản. UI Hướng dẫn và hướng dẫn c_user/xs đã khôi phục.

# Lịch sử trước bản nhiều tài khoản (chỉ để tham chiếu)

> Phạm vi mới nhất 17/10/2026 — ĐÃ DUYỆT và triển khai cùng nội dung cho 10/20 bài mới trong một nhóm. Bổ sung scripts/group_feed.py: chuẩn hóa cả group/permalink URL, lấy queryID và variables động từ bootstrap JSON của chính trang nhóm, giữ CHRONOLOGICAL, chỉ chọn root group_feed Story với post_id và creation_time; không lấy attached/recommended story. Đã đọc thật đủ 20 ID riêng biệt trên nhóm người dùng đưa, chưa gửi bình luận thật. Lab có load_batch/start_batch/stop_batch, polling progress, stop-on-unknown và skip fingerprint đã tồn tại. Hàng đợi chỉ trong RAM, journal từng bài vẫn bền vững; mở lại lấy danh sách mới, không tự resume. Desktop đóng sẽ request_shutdown để chờ bài đang chạy rồi bỏ các bài còn lại. UI thêm Phạm vi, Số bài, checkbox danh sách, tiến độ/Dừng. API POST /api/batch/load|start|stop và GET /api/batch/status dùng cùng Host/Origin/CSRF. Không thêm dependency production. Mọi đoạn nói batch chưa được duyệt bên dưới là lịch sử phạm vi trước và được ghi đè bởi đoạn này + PRODUCT.md hiện hành.

> Bản sửa tiếp theo 17/10/2026 — mất kết nối sau Lưu phiên: code cũ theo PID Edge ban đầu; Edge có thể compatibility-relaunch sang tiến trình con (`--edge-skip-compat-layer-relaunch` đã thấy ở tiến trình còn sống khi backend mất). Đã thay bằng BrowserWindowTracker dùng Toolhelp PID/parent/name, theo dõi cả cây Edge và giữ HWND đang tồn tại khi ẩn. Metadata cập nhật PID chủ cửa sổ mới. Không kết luận mọi lần lỗi đã tái hiện: baseline cũ có lượt vẫn chạy ổn, lỗi có tính điều kiện. Thêm vòng log desktop-events.jsonl chỉ có sự kiện/PID/cổng/loại lỗi, không request/cookie. **60/60 unit test đạt; dist/desktop-acceptance.json đạt trên EXE + Edge thật với dữ liệu tạm riêng: save session, preview, mở lần hai, chờ 30s rồi save lại, dừng cây browser thử khiến backend thoát, mở lại giữ phiên.** Việc dừng browser trong acceptance là kết thúc tiến trình thử, không phải tự động bấm × của người dùng; không mô tả là đã UI E2E mọi thao tác. Build hiện bắt buộc chạy acceptance trước khi tạo ZIP.

> Cập nhật ưu tiên 17/10/2026 — bản desktop một cửa sổ: đã bỏ launcher Tk và nút Mở giao diện/Thoát. EXE mở một cửa sổ Edge app; mở lại EXE chỉ focus cửa sổ hiện có. Đóng cửa sổ dừng backend (đợi lượt gửi đang chạy kết thúc). Microsoft Edge bắt buộc; không fallback sang trình duyệt thường. Runtime theo PID/cửa sổ trong scripts/desktop_window.py; metadata desktop-runtime.json chỉ chứa PID/cổng, không có cookie. Profile cửa sổ tạm riêng từng lần; phiên và journal vẫn ở LocalAppData/CommentLab. Mọi mô tả launcher hai cửa sổ hoặc fallback browser bên dưới là lịch sử bản cũ.

# HandoffPrompt — Comment Lab

Cập nhật: 17/10/2026. Dùng tài liệu này làm prompt khởi đầu cho AI tiếp theo. Các kết quả bên dưới là bằng chứng lịch sử, không thay thế kiểm tra trạng thái hiện tại.

## Prompt khởi đầu

Bạn tiếp quản **Comment Lab** tại `C:\Tools\FacebookCommentLab`. Hãy đọc `AGENTS.md`, tài liệu này, `PRODUCT.md` và code liên quan trước khi làm việc. Kiểm tra `git status` để giữ nguyên thay đổi chưa commit. Báo ngắn gọn phần đã xác minh, phần còn thiếu và thực hiện yêu cầu mới nhất của người dùng; không tự bắt đầu các đề xuất chưa được duyệt. Không hỏi lại những việc có thể kiểm tra an toàn từ code.

## 1. Bối cảnh và mục tiêu

- Người dùng muốn công cụ marketing cho dịch vụ tài khoản AI: ban đầu muốn bình luận nhiều bài trong group/Page bằng tài khoản Facebook cá nhân, ưu tiên request trực tiếp, không dùng Playwright cho việc gửi.
- Đây là **mục tiêu ban đầu**, không phải mô tả khả năng đã hoàn thành hoặc quyền tự gửi hàng loạt. Phạm vi đang có là bản thử **một bài, một bình luận mỗi lần**, có xem trước và kiểm chứng phản hồi.
- Thư viện nền là fbkit. Chưa kiểm chứng bằng một bình luận thật rằng request nội bộ hiện tại có thể đăng vào group của người dùng. Không quảng cáo là API Meta chính thức hay đảm bảo đăng thành công.
- Người dùng đã duyệt: thư mục riêng, Python xử lý request, UI web tiếng Việt trên Windows, dựng UI trực tiếp theo skill impeccable, và thêm bản ZIP desktop không yêu cầu tự cài Python.
- Người dùng yêu cầu UI ít chữ, nhỏ gọn, dễ dùng. Đã bỏ phần giới thiệu, thanh bước và footer; hướng dẫn/lịch sử thu gọn. Không tự thêm lại các đoạn giải thích dài vào màn hình chính.
- Không cần API key AI cho luồng hiện tại. Tạo nội dung AI, chạy chiến dịch hàng loạt, tự tham gia nhóm và quản lý nhiều tài khoản **chưa được triển khai trong bản này**.

## 2. Tách biệt với các dự án trước

Cuộc trò chuyện cũ chứa nhiều việc ASSETCONTROL/MREkanban, VPS, phân quyền, ảnh Trello, backup. Đó không phải phạm vi Comment Lab. Không sửa hoặc triển khai repo `C:\Users\PC\Desktop\NHA_ZUZU_CEO_CROSSPLATFORM` khi làm việc với tool này. Skill impeccable hiện nằm trong repo đó nhưng được dùng cho thiết kế Comment Lab.

- Dự án hiện hành: `C:\Tools\FacebookCommentLab`.
- Bản nguồn cũ được giữ: `C:\Users\PC\Desktop\fbkit-request-test`.
- Không ghi đè bản cũ, không tự đồng bộ dữ liệu giữa các bản.
- Các thay đổi hiện có phần lớn chưa commit; không reset, clean, force-push hoặc commit/push khi chưa được yêu cầu.

## 3. Cách mở và các bản phát hành

### Bản desktop

- File mở nhanh ở root: `C:\Tools\FacebookCommentLab\CommentLab.exe`.
- Thư mục `C:\Tools\FacebookCommentLab\_internal` là runtime đi cùng EXE. **Không tách EXE khỏi thư mục này**: đây là bản PyInstaller onedir, không phải một file standalone.
- Bản build gốc: `dist\CommentLab\CommentLab.exe`, cùng `_internal` bên trong thư mục đó.
- ZIP: `C:\Users\PC\Desktop\CommentLab-Windows-x64.zip`, khoảng 15,22 MiB ở lần build đã kiểm chứng; checksum `.sha256` nằm cạnh ZIP.
- Bản giải nén đã mở ở lượt trước: `C:\Users\PC\Desktop\CommentLab-Desktop\CommentLab\CommentLab.exe`.
- EXE khởi chạy server loopback ở **cổng động**, khác bản nguồn 8790. Không dùng tab 8790 để tuyên bố đã test đúng EXE.
- UI mở bằng Edge `--app`; nếu không có Edge thì mở trình duyệt mặc định. Python/Tk được đóng gói; Edge không được đóng gói.
- Cửa sổ điều khiển Tk có **Mở giao diện** và **Thoát**. Đóng cửa sổ Edge không dừng backend; phải bấm Thoát. Không cho thoát qua nút khi đang gửi.
- Khóa file Windows ngăn hai instance desktop cùng chạy với một vùng dữ liệu. Khi mở lần hai sẽ báo đang chạy.
- EXE chưa ký số. Chưa kiểm thử trên một máy Windows sạch khác.

### Bản chạy từ source

- Mở `MO-COMMENT-LAB.cmd` hoặc `python -X utf8 -m scripts.lab_server --open`.
- Mặc định `http://127.0.0.1:8790/`; có `--port` để đổi cổng.
- Python đã có trên máy: `C:\Users\PC\AppData\Local\Programs\Python\Python312\python.exe`.
- Node kiểm tra cú pháp: `C:\Program Files\nodejs\node.exe`.
- Source UI được đọc trực tiếp khi tải lại trang. **EXE dùng UI đã copy lúc build**; sửa source không tự cập nhật desktop, phải build lại.

## 4. Dữ liệu và bí mật

| Bản | Phiên | Nhật ký chống trùng |
|---|---|---|
| Source | `<repo>\private\session.json` | `<repo>\.probe\attempts.sqlite3` |
| Desktop | `%LOCALAPPDATA%\CommentLab\private\session.json` | `%LOCALAPPDATA%\CommentLab\.probe\attempts.sqlite3` |

- Desktop có profile Edge riêng tại `%LOCALAPPDATA%\CommentLab\window`, chỉ để hiển thị UI local; không dùng profile Facebook của người dùng để lấy cookie.
- Phiên lưu JSON chưa mã hóa, quyền thư mục Windows giới hạn cho tài khoản Windows hiện tại. Không gọi đây là kho mã hóa.
- Không đọc/ghi cookie thật vào chat, log, test fixture công khai, Git, ZIP hoặc tài liệu. Không quét database cookie Chrome.
- Người dùng tự nhập `c_user`, `xs`, cookie bổ sung hoặc file JSON danh sách cookie. ID phải khớp; từ chối `i_user` (danh tính Page).
- Không tự nhập/chuyển phiên hoặc lịch sử giữa source và desktop. Hai nhật ký khác nhau: không dùng hai bản để gửi lại cùng bình luận.
- Không xóa `.probe` để vượt cơ chế chống trùng. Không xóa dữ liệu hiện có để làm sạch bài test.
- Kiểm thử ghi dùng fixture/thư mục tạm riêng; không điền cookie giả vào vùng dữ liệu thực của người dùng.

## 5. Sơ đồ code

| File | Vai trò |
|---|---|
| `ui/index.html` | Form phiên, nội dung, xem trước/kết quả, lịch sử và trợ giúp |
| `ui/app.css` | Bố cục compact; desktop 3 cột, trung bình 2 cột, mobile 1 cột |
| `ui/app.js` | State UI, preview cố định, khóa gửi, dựng DOM an toàn, trạng thái/lịch sử |
| `scripts/lab_server.py` | HTTP loopback, session, API, CSRF/Origin/Host, serve UI theo allowlist |
| `scripts/comment_probe.py` | Parse bài, kiểm tra phiên, gửi một lần, SQLite journal và phân loại kết quả |
| `scripts/fb.py` | Code nền fbkit; probe dùng `_try_comment` |
| `scripts/fb_session.py` | Requests session, token và GraphQL helper |
| `scripts/fb_config.py` | Các hằng số/doc ID nội bộ; không coi là API ổn định |
| `scripts/desktop.py` | Launcher Tk, Edge app mode, khóa instance, data path, frozen smoke test |
| `desktop-entry.py` | Entrypoint PyInstaller |
| `scripts/build_desktop.py` | Full test → build → licenses → smoke EXE → ZIP + SHA-256 |
| `requirements-desktop-build.txt` | Dependency môi trường build; không dùng để thay toàn bộ dependency fbkit |
| `tests/test_lab_server.py` | HTTP, quyền local, session, preview, tài nguyên UI |
| `tests/test_comment_probe.py` | Probe, journal, phản hồi và lỗi; xem test hiện tại trước khi sửa |
| `tests/test_desktop.py` | Tách asset/data root, frozen path, fallback khi không có Edge |
| `tests/ui_fixture.py` | Fixture E2E local, thay probe bằng kết quả giả; đọc file trước khi chạy |

`Lab(root, asset_root=None)` tách dữ liệu khỏi UI. Source mặc định dùng chung root, desktop truyền asset root từ `sys._MEIPASS` và data root ở LocalAppData. Không đổi hai đường dẫn này thành một trong bản frozen.

## 6. Hành vi cần giữ

- `/api/state`: đọc trạng thái, CSRF và lịch sử; không trả giá trị cookie.
- `/api/session`: kiểm tra rồi lưu phiên; `/api/forget`: gỡ phiên của tool, không đăng xuất Chrome.
- `/api/preview`: offline, không gọi Facebook; hỗ trợ ID số hoặc HTTPS group posts/permalink có ID số. Không đoán ID cho share/pfbid.
- `/api/send`: phải xác nhận đúng operation ID của preview, dùng nội dung đã cố định. Preview hết hạn sau 10 phút; sửa nội dung/bài/phiên làm mất hiệu lực preview.
- Gửi một lần, không tự retry khi kết quả chưa rõ. Journal dự trữ thao tác trước POST để chống trùng.
- Trạng thái phân biệt chưa gửi, xác nhận theo phản hồi và chưa rõ kết quả. `confirmed_by_response` không chứng minh bài đã hiện/được duyệt trong nhóm.
- Nút gửi bị khóa nếu chưa có phiên hoặc preview không hợp lệ, đang xử lý, hoặc đã gửi preview đó.
- Chỉ bind `127.0.0.1`; không mở LAN/public. POST kiểm tra Host, Origin, CSRF, JSON và giới hạn body. Không nới kiểm tra để sửa lỗi UI.
- UI dựng nội dung bằng text nodes, giữ xuống dòng, không chèn nội dung người dùng bằng innerHTML.
- Sau Xem trước, focus chuyển tới tiêu đề preview. Lịch sử/Trợ giúp có thể mở bằng bàn phím.

## 7. Thiết kế và cách phối hợp

- Đọc `DESIGN.md`, `.impeccable/design.json`, `PRODUCT.md`, `.impeccable/config.json` trước thay đổi UI.
- Skill: `C:\Users\PC\Desktop\NHA_ZUZU_CEO_CROSSPLATFORM\.agents\skills\impeccable\SKILL.md`.
- Người dùng đã chọn code-first; thay đổi nhỏ không cần hỏi lại chọn mockup/concept.
- Giữ palette teal/xám xanh, font hệ thống, ít chữ và ít khoảng trắng dư. Hướng dẫn kỹ thuật đặt trong mục mở khi cần.
- Khi người dùng hỏi **giải pháp**, chỉ phân tích/đề xuất; không tự code. Khi họ yêu cầu thực hiện thì làm và kiểm chứng.
- Chỉ hỏi điểm chưa rõ ảnh hưởng phạm vi, dữ liệu, kiến trúc hoặc quyền; không bắt người dùng xác nhận lại điều đã duyệt.
- Không thêm dependency production khi chưa hỏi. PyInstaller đã được dùng làm công cụ build riêng; không thay backend sang framework khác chỉ để đóng gói.

## 8. Build và test

PowerShell, working directory `C:\Tools\FacebookCommentLab`:

```powershell
& 'C:\Users\PC\AppData\Local\Programs\Python\Python312\python.exe' -m venv build/desktop-venv
& '.\build\desktop-venv\Scripts\python.exe' -m pip install -r requirements-desktop-build.txt
& '.\build\desktop-venv\Scripts\python.exe' -X utf8 -m scripts.build_desktop
& 'C:\Program Files\nodejs\node.exe' --check ui/app.js
git diff --check
```

Build script hiện **không tự copy** EXE/runtime ra root hoặc Desktop. Sau build, đóng instance đang dùng rồi cập nhật cả `CommentLab.exe` và `_internal` từ `dist\CommentLab`; không chỉ copy EXE. Kiểm tra file đang tồn tại trước khi thay. ZIP mới nằm trong `dist`; copy file ZIP + checksum mới ra Desktop nếu nhiệm vụ yêu cầu giao bản mới.

Kiểm tra runtime đóng gói, không gửi Facebook:

```powershell
& '.\CommentLab.exe' --smoke-test 'C:\Tools\FacebookCommentLab\dist\root-desktop-smoke.json'
```

EXE windowed có thể trả quyền điều khiển shell trước khi xong; dùng `Start-Process -Wait -PassThru -WindowStyle Hidden` hoặc `subprocess.run(..., timeout=60)` để lấy đúng exit code, rồi đọc JSON report. Không kết luận đạt từ việc chỉ thấy process khởi động.

## 9. Bằng chứng đã có và giới hạn

- Lần build desktop: **51/51 unittest đạt**. Đây là số tại thời điểm build, phải chạy lại sau sửa.
- EXE trong dist và bản giải nén ở đường dẫn có dấu/khoảng trắng: smoke đạt, HTML/CSS/JS đầy đủ, preview offline, gửi khóa khi thiếu phiên, CSRF 403, Tk khởi tạo được.
- Bản giải nén được chạy với PATH chỉ còn System32 và bỏ PYTHONHOME/PYTHONPATH. Không thay thế test trên máy Windows sạch.
- ZIP kiểm kê 1052 mục ở lần build này, không có private/.probe/profiles/.git, cookie, `.env` hoặc database thật.
- Trước đó, fixture UI chặn request Facebook đã kiểm tra lưu phiên giả, xem trước, gửi giả, kết quả chưa rõ/xác nhận và lịch sử sau reload. Đây là **mock**, không phải gửi thật.
- UI compact đã kiểm tra 1366px và 360px không tràn ngang; preview giữ xuống dòng, vô hiệu sau sửa; lịch sử/trợ giúp hoạt động.
- Lượt gần nhất mở **EXE giải nén thật**: đã quan sát process/cửa sổ launcher `Comment Lab` và cửa sổ Edge `Comment Lab — Thử bình luận Facebook`.
- Kiểm thử native bị công cụ Computer Use tự dừng: không xác định đủ chắc URL cửa sổ Edge để thực thi chính sách. **Chưa test đầy đủ thao tác native/đóng-mở lại launcher**, không được nói đã E2E hoàn chỉnh.
- Không cố vượt chặn Computer Use bằng kênh điều khiển khác trong cùng lượt. Có thể dùng smoke tự động hợp lệ ở lượt phù hợp, hoặc hướng dẫn người dùng thao tác phần bị chặn.
- Chưa thử cookie Facebook thật, file picker JSON trên Chrome thật, gửi group thật, SmartScreen trên máy sạch hoặc Edge không có trên máy khác.
- File lỗi `Thiếu file giao diện` cũ liên quan thiếu/không tìm thấy UI. Build hiện đóng gói cả thư mục `ui`; nếu tái hiện hãy kiểm tra asset root và ZIP trước, không sửa bừa backend.

## 10. Những việc tiếp theo có ích, chưa tự được duyệt

1. Kiểm tra đầy đủ launcher: lần mở thứ hai, mở lại giao diện, Thoát, cổng ngừng nghe và mở lại giữ lịch sử trên fixture riêng.
2. Test UI desktop nhập file JSON, validation, lỗi mạng và bản xem trước hết hạn, không đụng phiên thật.
3. Khi người dùng muốn gửi thật: cần bài cụ thể + nội dung + tài khoản được chọn. Không dùng link Trello, Facebook từ hội thoại cũ làm đích ngầm; không tự gửi quảng cáo để smoke test.
4. Cập nhật bản desktop từ source thành một bước có kiểm chứng, giữ dữ liệu; hiện build/copy vẫn là hai bước.
5. Đánh giá cải thiện lifecycle (đóng cửa sổ app và backend), ký số và test máy sạch nếu được yêu cầu. Không coi các điểm này là đã hoàn thành.
6. Bất kỳ mở rộng hàng loạt/AI/multi-account/API chính thức cần chốt phạm vi riêng, kiểm tra khả năng thực tế và quyền; không suy ra được duyệt chỉ từ mục tiêu marketing ban đầu.

## 11. Các tài liệu nên đọc

`AGENTS.md` → tài liệu này → `PRODUCT.md` → `HUONG-DAN-GIAO-DIEN.md` → `HUONG-DAN-TEST.md` → `KET-QUA-KIEM-THU-UI.md` → code/test liên quan. Thiết kế đọc thêm `DESIGN.md`. Desktop đọc `DESKTOP-README.txt` và `scripts/build_desktop.py`.

Không có cookie, mật khẩu, token hoặc API key thật trong handoff. AI tiếp theo phải tự kiểm tra tools/quyền/môi trường đang có; không giả định cửa sổ hay process cũ vẫn tồn tại.

## Bộ nhớ kiểm tra 19/10/2026 — thiếu sót đã xác minh, chưa sửa

- Đọc code comment_probe.py, lab_server.py, fb_session.py và fb.py; chạy lại 40 test comment_probe/batch, tất cả đạt với giả lập, không gửi Facebook thật.
- Đã có: ghi reservation SQLite trước POST, fingerprint tài khoản+bài+nội dung, không retry write, dừng batch khi không confirmed/GraphQL error/journal failure, preview một lần và busy trong tiến trình.
- Thiếu phân loại riêng checkpoint, hết phiên, hạn chế bình luận, thiếu quyền và lỗi mạng. fetch_tokens chưa nhận diện đầy đủ trang xác minh.
- Thiếu khóa gửi bền vững theo tài khoản sau hạn chế/xác minh; có thể bắt đầu lượt mới.
- Fingerprint phụ thuộc nguyên văn: đổi ký tự có thể gửi lại cùng bài; chưa khóa bài có kết quả chưa rõ bất kể nội dung.
- Chưa ngăn nội dung lặp trên nhiều bài; chưa chuẩn hóa Unicode/khoảng trắng để cảnh báo trùng.
- Nhật ký cục bộ không đồng bộ máy/thư mục khác; chưa đối chiếu bình luận hiện hữu trước thử lại. Không được suy ra timeout là chưa gửi.
- Khoảng chờ 1 giây chỉ là cách thực thi, không phải ngưỡng an toàn của Meta.
- Đề xuất ưu tiên, CHƯA TRIỂN KHAI: khóa tài khoản sau hạn chế; khóa actor+post khi unknown; kiểm tra trùng theo bài và nội dung chuẩn hóa; cảnh báo lặp nhiều bài; AI chỉ hỗ trợ nội dung đúng ngữ cảnh và người dùng duyệt, không làm công cụ che giấu clone hoặc lách chống spam.
- Nền open source: origin drpwchen/fbkit, upstream htlin222/fbpost, MIT. Kế thừa session/token/GraphQL/comment; CommentLab thêm UI/EXE, journal, kiểm tra phản hồi, đọc nhóm và batch. Hàm gốc mô tả bình luận bài của chính mình, không chứng minh mọi nhóm đều hỗ trợ.

## Yêu cầu đang bàn bạc 19/10/2026 — CHƯA DUYỆT TRIỂN KHAI

Người dùng yêu cầu chỉ lập kế hoạch, chưa code: nhiều đích Page/nhóm; nhận biết nhóm mà từng tài khoản tham gia; lưu/chuyển nhiều tài khoản; cân nhắc nhiều tài khoản comment song song. Cần phân biệt Page với group; việc lưu cookie không tự cho biết đầy đủ memberships. Chưa kiểm chứng khả năng đọc đầy đủ nhóm tham gia bằng request hiện tại. Không tự coi đề xuất là phạm vi đã duyệt. Chưa sửa app hoặc build lại.
