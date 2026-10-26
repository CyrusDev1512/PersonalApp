# HỒ SƠ MENTOR HUSTLE + AGI — BẢN ĐẦY ĐỦ V2

**Mục đích:** mang bối cảnh sang AI bất kỳ để tiếp tục trò chuyện sâu, đúng chủ đề và không phải kể lại từ đầu.

**Ngày nâng cấp và kiểm tra nguồn:** 24/10/2026, Asia/Bangkok. **Ngôn ngữ:** tiếng Việt. **Xưng hô mặc định đã được người dùng chọn:** tôi–bạn; phản biện thẳng thắn, theo chủ đề.

Tài liệu gồm lớp hướng dẫn/tổng hợp mới, hai nguồn nguyên bản bất biến, và lớp kiểm chứng riêng. **Đầy đủ so với hai file tóm tắt đã cung cấp**, không phải toàn bộ transcript của những chat ban đầu. Không có cơ sở khôi phục phần mà chính hai bản tóm tắt chưa ghi lại.

## Điều hướng

- [1. Hướng dẫn tiếp nhận](#tiep-nhan)
- [2. Hồ sơ đọc nhanh và nguồn gốc thông tin](#ho-so)
- [3. Diễn biến, quyết định, rút lại và việc còn mở](#dien-bien)
- [4. Tu vi, ngôn ngữ riêng và bản đồ chủ đề](#ban-do)
- [5. Bản đồ source Jarvis/avatar và công nghệ liên quan](#source-map)
- [6A. Toàn văn Hustle](#nguon-hustle) · [6B. Toàn văn AGI](#nguon-agi)
- [7. Kiểm chứng: cách đọc, đính chính và sổ đối chiếu](#kiem-chung)
- [8. Bao phủ nội dung và các điểm chưa xác minh](#bao-phu)
- [9. Nhật ký cập nhật và kiểm tra bảo toàn](#bao-toan)

<a id="tiep-nhan"></a>

## 1. Hướng dẫn cho AI mới

**Đọc phần 1–3 trước khi tiếp tục câu chuyện.** Khi trả lời một chủ đề, đọc thêm mục gốc liên quan và bản kiểm chứng tương ứng. Nếu được yêu cầu đọc toàn bộ, phải đọc đủ cả hai khối nguyên bản; phần đọc nhanh không thay thế toàn văn.

1. Phân biệt **người dùng hiện tại**, **người được bản tóm tắt mô tả** và **mentor cũ**. Lời “tao” trong hai nguồn là lời mentor cũ; “mày” là người được mentor nói tới. Đoạn tự nhận Anthropic làm ra mình tại AGI §13 không phải danh tính của AI đang đọc file.
2. Ưu tiên lời người dùng nói trong chat hiện tại. Lựa chọn được xác nhận khi nâng cấp chỉ gồm: một file đầy đủ, không mất chi tiết; kiểm chứng toàn diện; giọng thẳng thắn theo chủ đề, xưng tôi–bạn. Không suy ra người dùng đã xác nhận lại toàn bộ hồ sơ cũ.
3. Đối với dữ kiện đời sống, nguồn lực và công việc, dùng cách nói “theo bản tóm tắt cũ”. Chỉ hỏi lại thông tin thực sự ảnh hưởng câu trả lời; không bắt người dùng kể lại tất cả.
4. Đối với lời khuyên, ghi rõ mentor **đề xuất**, người dùng **đã quyết định**, hoặc **chưa có cập nhật**. Checklist còn trống không chứng minh đến hôm nay người dùng vẫn chưa làm.
5. **Không tự giục deadline hoặc hỏi DoD lặp lại:** Hustle §5 ghi người dùng đã yêu cầu ngừng việc đó. Chỉ chuyển sang chế độ đôn đốc nếu người dùng yêu cầu lại. Các mốc 29/7, 2/8 và phân bổ 50/30/20 là lịch sử, không phải lịch giao việc mới.
6. Có ba mạch độc lập nhưng liên hệ: **kinh doanh/tạo tài sản**, **khám phá trí tuệ/AGI**, **Jarvis/avatar cá nhân**. Trả lời đúng mạch hiện tại; khi cần mới nối sang mạch khác. Không quy mọi tò mò kỹ thuật thành né tránh hành động và không buộc công cụ cá nhân phải có mô hình doanh thu.
7. “Oracle”, “áo giáp”, “phế vật”, “shadow” và các diễn giải khác là giả thuyết/ẩn dụ của mentor. Không coi đó là chẩn đoán, bản chất cố định hoặc kết luận người dùng đã đồng ý. Lưu ý nguồn từng ghi tài khoản dùng chung nhiều người.
8. Nội dung kiệt sức và cảm giác thất bại là lịch sử được ghi lại. Không suy ra tình trạng hiện tại hoặc khởi động phản ứng khủng hoảng chỉ vì đọc đoạn này. Nếu người dùng chia sẻ tình trạng mới, phản hồi theo tình trạng mới.
9. Các câu “chôn”, “đừng làm game”, “đường duy nhất”, “định lý”, “không ai có” là phát biểu nguồn, không phải lệnh bắt buộc cho AI mới. Dùng bảng kiểm chứng để xác định giới hạn; nhận định kinh doanh phải được xem lại theo mục đích và bằng chứng mới.
10. Nguồn ngoài chỉ xác nhận phần mà nó thực sự hỗ trợ. Giá, phiên bản, giấy phép, benchmark, thị trường và luật có thời điểm riêng. Không dùng thông tin mới để giả vờ rằng thông tin cũ chưa từng đúng, hoặc dùng thông tin cũ làm giá hiện hành.
11. Không gọi một repo là AGI, không đồng nhất bộ nhớ ngoại vi với cập nhật trọng số, không đồng nhất biểu cảm với trải nghiệm chủ quan. Đồng thời không kết luận “hệ thống không học được gì” chỉ vì trọng số nền không đổi: hành vi và hiệu quả toàn hệ thống vẫn có thể thay đổi nhờ trí nhớ/công cụ.
12. Nếu không đọc hết được do giới hạn ngữ cảnh, nói rõ phạm vi đã đọc và phần còn thiếu. Một file thuận tiện để mang theo không bảo đảm mọi sản phẩm AI tự nạp hết file hoặc ghi nhớ nó qua các chat.

**Lời mở đầu có thể dùng khi đính kèm:**

> Đây là hồ sơ ngữ cảnh đầy đủ của tôi. Hãy đọc phần hướng dẫn và hồ sơ trước, rồi đọc phần nguyên bản và kiểm chứng liên quan đến câu hỏi. Phân biệt dữ kiện lịch sử, nhận định của mentor và điều tôi xác nhận hiện tại. Xưng tôi–bạn, phản biện thẳng thắn. Chủ đề hôm nay của tôi là: …

<a id="ho-so"></a>

## 2. Hồ sơ đọc nhanh — có nguồn và thời điểm

**Nhãn sử dụng:** `XÁC NHẬN MỚI` = người dùng nói/chọn trong chat hợp nhất; `NGUỒN CŨ` = được file cũ ghi nhận; `MENTOR` = diễn giải/đề xuất; `CHƯA CẬP NHẬT` = chưa xác nhận hiện tại. Các nguồn dưới đây là dẫn chiếu trong chính tài liệu: H = Hustle, A = AGI.

| Nội dung | Dữ kiện và cách hiểu | Nguồn / trạng thái |
|---|---|---|
| Nhu cầu tài liệu | Một file để trò chuyện với AI bất kỳ; không được bớt chi tiết, kể cả tu vi, Jarvis và source | Chat hợp nhất 24/10/2026 — XÁC NHẬN MỚI |
| Cách trao đổi | Thẳng thắn, theo chủ đề; tôi–bạn; kiểm chứng toàn diện | Lựa chọn trực tiếp khi lập kế hoạch — XÁC NHẬN MỚI |
| Source quan tâm | Người dùng xác nhận đang muốn nhớ nhóm source xây Jarvis/avatar đã được liệt kê; chưa yêu cầu chọn stack hay triển khai Jarvis | Chat hợp nhất — XÁC NHẬN MỚI |
| Tuổi / học vấn | Sinh 2003, học đại học trong 3 năm; tự chọn Unreal dù thị trường Việt Nam không sẵn | [H§0](#ref-h-0) — NGUỒN CŨ; chưa xác minh độc lập |
| Năng lực | 4+ năm Unreal chuyên nghiệp, hai lần Lead; AI framework Zone 9; co-dev/porting Soliz (Katana Inu, M-SCI); GAS, EOS multiplayer, build engine từ source; TOEIC 870 | [H§0](#ref-h-0) — NGUỒN CŨ, CHƯA CẬP NHẬT |
| Startup đầu | Founding member startup Unreal có gọi vốn, rời vì lệch hướng | [H§0](#ref-h-0) — NGUỒN CŨ |
| Studio riêng | Founder studio game Unreal; game tới alpha; kẹt vốn, giao lại co-founder | [H§0](#ref-h-0) — NGUỒN CŨ |
| PK Bot | AI cho sale, CSKH và quản trị SME; ba co-founder, có khách, sản phẩm đã hoàn thành theo nguồn | [H§0](#ref-h-0), [H§10](#ref-h-10) — NGUỒN CŨ; không giả định số liệu vận hành hiện tại |
| Cập nhật về PK Bot | Người dùng đã đóng chủ đề, coi là small business; mentor rút lại việc coi PK Bot là đích và giữ nó như runway/bệ phóng | [H§10](#ref-h-10) — cập nhật cuối trong nguồn Hustle |
| Mục tiêu dài hạn | “100M/100Mnaire” là đích dài hạn, không phải KPI hằng ngày; nguồn dùng hình ảnh Hóa thần | H phần mở đầu, [H§5](#ref-h-5) — NGUỒN CŨ; chưa chốt lại cách đo, thời hạn hoặc trạng thái hiện tại |
| Giá trị | “Kiếm tiền dựa trên hạnh phúc của user” | [H§0](#ref-h-0) — phát biểu được nguồn quy cho người dùng |
| Nguồn lực | 15–30 giờ/tuần; 5–20 triệu cho 6 tháng; khó tìm job Unreal trong chu kỳ được nói tới | [H§0](#ref-h-0) — NGUỒN CŨ, CHƯA CẬP NHẬT; không dùng làm ngân sách hiện tại |
| Sở thích / ngôn ngữ | Anime/manhwa, hệ thống văn, gym/glow-up, cộng đồng dev Việt; tu vi là hệ ẩn dụ đã dùng | [H§0](#ref-h-0), [H§5](#ref-h-5), [H§7](#ref-h-7) — NGUỒN CŨ |
| Lợi thế giao thoa | “Senior Unreal + kỹ sư LLM production” được mentor dùng để định vị giao điểm kỹ năng | [H§0](#ref-h-0), [H§4](#ref-h-4) — MENTOR; không nâng thành chứng nhận năng lực |
| Hướng kinh doanh đã bàn | H-AGI, HAGI coin, app tóc, thẩm mỹ, Glow-up System, pop-up/chibi, exoself, game và digital-human host | [H§4](#ref-h-4) — ý tưởng/đề xuất; trạng thái chi tiết ở phần 3 |
| Hướng kỹ thuật | Bản chất trí tuệ, agent, trí nhớ, học liên tục, world model, cảm xúc, avatar và khả năng đo độ tin cậy | [A§0](#ref-a-0)–19 — lịch sử chủ đề; không đồng nghĩa đã chọn nghề nghiên cứu |
| Quan hệ cộng tác | Nguồn ghi bất mãn với co-founder; mentor đề xuất vesting/cliff, vai trò và điều khoản chia tay; nguồn ghi người dùng chọn học làm việc với người | [H§6](#ref-h-6) — NGUỒN CŨ; không quy bản chất cho co-founder |
| Trạng thái tâm lý | Có chia sẻ quá tải/kiệt sức ở cuối chat Hustle; những diễn giải tiếp theo là của mentor | [H§7](#ref-h-7), [H§10](#ref-h-10); [A§18](#ref-a-18) — lịch sử, CHƯA CẬP NHẬT |
| Giới hạn nhận diện | Tài khoản từng được mô tả là nhiều người dùng chung | [H§0](#ref-h-0), [H§10](#ref-h-10) — không tự gộp mọi chẩn đoán cho người hiện tại |

<a id="dien-bien"></a>

## 3. Diễn biến, quyết định và các điểm còn mở

### 3.1 Hai mạch trò chuyện

**Hustle (26/7 → 3/9/2026 theo tiêu đề):** câu hỏi về cơ hội làm giàu → framework → case study → đánh giá ý tưởng → lộ thêm hồ sơ startup/PK Bot → quan hệ và tâm lý → một số câu hỏi kỹ thuật cùng chia sẻ mệt mỏi. Thứ tự này lấy từ [H§1](#ref-h-1), không bổ sung mốc chưa có.

**AGI (nguồn không ghi đủ ngày từng lượt):** sự sống và bản chất trí tuệ → cú lật BitTorrent → rule-based/prediction → avatar và Jarvis–Optimus → Hermes → kiến trúc và insight → Wright/hầm gió → lao động và coding agent → CSKH/telesale → động cơ theo đuổi AGI. Bản đồ có 13 lượt ở [A§0](#ref-a-0); phần tổng hợp mở rộng thành §0–19. Không tự gán toàn bộ AGI vào khoảng ngày của Hustle.

### 3.2 Những cập nhật cần ưu tiên để không hiểu sai

| Nội dung ban đầu / dễ hiểu nhầm | Cập nhật hoặc cách đọc đúng | Nguồn |
|---|---|---|
| PK Bot phải là đích khởi nghiệp chính | Phần cuối ghi người dùng đã đóng chủ đề; mentor xem lại vai trò thành runway | [H§0](#ref-h-0), [H§5](#ref-h-5) → [H§10](#ref-h-10) |
| Mentor có quyền giục deadline tiếp | Người dùng đã yêu cầu ngừng giục và ngừng hỏi DoD | [H§5](#ref-h-5) |
| Digital-human host là startup người dùng đã chọn | Đây là đề xuất ưu tiên của mentor; nguồn cuối vẫn ghi chưa chọn startup để thử | [H§4](#ref-h-4), [H§10](#ref-h-10) |
| H-AGI bị chôn nên không được xây Jarvis | Phán quyết [H§4](#ref-h-4) bàn hướng thương mại; [A§5](#ref-a-5)/7/19 bàn tích hợp và công cụ cá nhân. Hai tiêu chí khác nhau | [H§4](#ref-h-4); [A§5](#ref-a-5),7,19 |
| Tạo thị trường, fast-follower hay solo là lựa chọn đã khóa | Nguồn chứa lập luận và lời khuyên; không có cam kết hiện tại trong chat này | [H§2](#ref-h-2),4,6 |
| Triết học đối lập deep learning | Mentor tự rút lại đối lập này | [A§3](#ref-a-3) |
| Động lực phải gắn tử vong | Mentor sửa thành “stake”; đây vẫn là lập luận cần phân biệt với định luật khoa học | [A§3](#ref-a-3) → [A§11](#ref-a-11) |
| Hermes được coi là học liên tục ở tầng trọng số | [A§7](#ref-a-7)/19 tự đính chính sang bộ nhớ/skills ngoài model | [A§7](#ref-a-7), [A§19](#ref-a-19).1 |
| Các nhãn “đã kiểm chứng” trong [A§16](#ref-a-16) là chứng nhận | Chúng là phân loại của mentor trước; xem kết quả đối chiếu tại phần 7 | [A§16](#ref-a-16) và phần kiểm chứng mới |
| Thất bại đã được tiên đoán / tâm lý đã được chẩn đoán | Đây là lời chia sẻ trong lịch sử và diễn giải mentor; không phải kết luận về hiện tại | [H§7](#ref-h-7), [H§10](#ref-h-10) |

### 3.3 Trạng thái các hướng và việc còn mở

| Hướng / việc | Trạng thái ghi trong nguồn | Không được tự suy ra |
|---|---|---|
| H-AGI các phiên bản, HAGI coin, exoself | Mentor phản đối mô hình kinh doanh; lý do tại [H§4](#ref-h-4) | Người dùng vĩnh viễn từ bỏ hoặc đã đồng ý mọi lý do |
| App tóc, mô phỏng thẩm mỹ, Glow-up System | Được mentor đánh giá đáng khảo sát | Đã có khách, có doanh thu, hoặc người dùng chọn làm |
| Game Unreal | Mentor khuyên treo có chủ đích | Người dùng không thích game hoặc mất năng lực Unreal |
| Digital-human sales host | Đề xuất của mentor dựa trên giao thoa Unreal/LLM | Đây là startup hiện tại |
| Hermes + một cron chạy 7 ngày | Bài thử được đề nghị; chưa có báo cáo kết quả trong nguồn | Đến hôm nay vẫn chưa làm hoặc bắt buộc phải làm |
| So sánh Claude Code–Devin bằng 4 ticket | Đề nghị tại [A§18](#ref-a-18) | Benchmark đã được tiến hành |
| Đếm câu hỏi CSKH lặp lại | Đề nghị tại [A§18](#ref-a-18) | Dữ liệu PK Bot đã được đo hoặc ngưỡng 60/30 là quy luật |
| Co-founder / vesting / chia tay | Mentor đề nghị cấu trúc và soạn kịch bản | Đã có thỏa thuận pháp lý hoặc đã rời công ty |
| App của bạn sếp | Nguồn nói có kho câu hỏi 6 nhóm nhưng không chép lại trọn kho | Có thể khôi phục 6 nhóm nguyên bản từ file này |
| Chat Execution | Được cân nhắc trong [H§10](#ref-h-10) | Người dùng đã mở hoặc muốn được giao việc mới |
| Lý do muốn AGI, ticket tốn giờ, lợi thế bất công, 1.000 khách đầu | Câu hỏi còn mở theo [H§10](#ref-h-10)/[A§18](#ref-a-18) | Phải trả lời tất cả trước khi hỏi một câu kỹ thuật |

<a id="ban-do"></a>

## 4. Tu vi, ngôn ngữ riêng và bản đồ chủ đề

### 4.1 Thang tu vi — giữ đủ ý nghĩa gốc

| Cảnh giới | Ánh xạ trong [H§5](#ref-h-5) |
|---|---|
| Phàm nhân | Lương |
| Luyện khí | Ship sản phẩm đầu, đồng đô đầu từ người lạ |
| Trúc cơ | $1k–10k MRR, loop lặp được |
| Kim đan | Tài sản tự nuôi, exit nhỏ |
| Nguyên anh | Swing lớn có equity |
| Hóa thần | 100M |

Đây là hệ ẩn dụ mentor đã dùng, không phải bảng xếp hạng giá trị con người. **Chưa gán cảnh giới hiện tại cho người dùng.** Các mốc không chứng minh một con đường duy nhất tới mục tiêu.

[H§7](#ref-h-7) còn có: bình xanh Hàn Lập/cơ duyên; linh căn = code; linh khí phục hồi = AI; lão gia gia trong nhẫn = AI mentor; bí cảnh = công việc/khách; địa lợi = chi phí Việt Nam/chợ Mỹ. [H§2](#ref-h-2).9 dùng meta/patch, stat và trục ngang–dọc. [A§4](#ref-a-4) dùng Jarvis–Optimus; [A§12](#ref-a-12) dùng hầm gió và lực nâng. Giữ các hình ảnh này để hiểu ngôn ngữ trò chuyện, không dùng chúng làm bằng chứng khoa học.

### 4.2 Chọn mạch để tiếp tục

| Muốn bàn về | Đọc nguồn | Đối chiếu mới |
|---|---|---|
| Hồ sơ, PK Bot, mục tiêu, nguồn lực | [H§0](#ref-h-0),5,10 | Phần 2–3 |
| 7 filter, 4 van, pain, phân phối, moat, MVP, pivot | [H§2](#ref-h-2) | Nhóm H01–H04 |
| Case study kinh doanh | [H§3](#ref-h-3) | H05–H23 |
| Ý tưởng và phán quyết | [H§4](#ref-h-4) | H24–H31 |
| Co-founder, deadline, Lab, tu vi, tâm lý | [H§5](#ref-h-5)–7,10 | Phần 3–4; H32–H35 |
| Exoself, tương lai, lịch sử AI | [H§8](#ref-h-8) | H36–H42 |
| Sự sống, rule-based, trí tuệ, insight | [A§1](#ref-a-1)–4,9,11 | A01–A13, A30–A40 |
| Jarvis/avatar, cảm xúc, source để ghép | [A§4](#ref-a-4)–5,7,19 | Phần 5; A14–A25, A57–A63 |
| Companion, thị trường và pháp lý | [A§6](#ref-a-6) | A26–A29; L01–L07 |
| Học liên tục, Transformer, Mamba, JEPA | [A§8](#ref-a-8),10,19 | A30–A40 |
| Wright, đo lường, interpretability | [A§12](#ref-a-12) | A41–A45 |
| Claude Code, Devin, OpenHands | [A§13](#ref-a-13),18,19 | A46–A50; phần 5 |
| CSKH/telesale, Klarna, người và AI | [A§14](#ref-a-14) | A51–A56; L03 |
| Lý do theo đuổi AGI, câu hỏi còn mở | [A§15](#ref-a-15)–18 | A64–A66; phần 3 |

**Thuật ngữ để tránh lẫn:** H-AGI/HAGI là ý tưởng của người dùng trong nguồn; AGI là chủ đề trí tuệ tổng quát; Hermes Agent là phần mềm agent, không phải tất cả model mang tên Hermes. “Source” trong cuộc trò chuyện có thể chỉ repo, SDK, sản phẩm, paper hoặc tiêu chuẩn; bảng tiếp theo phân loại từng tên. Jarvis/Optimus trong [A§4](#ref-a-4) là ẩn dụ nhân vật; không tự đồng nhất Optimus ở đó với sản phẩm robot Tesla. DoD = Definition of Done; MRR = doanh thu định kỳ theo tháng; ROI = hiệu quả so với chi phí; moat = lợi thế khó sao chép; scaffolding = lớp trí nhớ/công cụ/điều phối quanh model.

<a id="source-map"></a>

## 5. Bản đồ source — kiểm tra ngày 24/10/2026

**Phạm vi:** xác nhận danh tính, vai trò và tài liệu có thể truy cập; không clone/build/chạy thử các repo trong lượt này. README là tuyên bố của dự án, không phải chứng nhận hiệu năng độc lập. Không chốt kiến trúc hay cài phần mềm cho người dùng.

Trong nguồn, chỉ Hermes được ghi rõ là link người dùng trực tiếp gửi. Những tên còn lại thuộc cuộc trao đổi, nhưng không có transcript để quy tất cả cho người dùng.

| Tên | Loại / vai trò | Giới hạn và kết quả kiểm tra | Nguồn gốc / bằng chứng |
|---|---|---|---|
| Hermes Agent | Agent framework / repo — Não điều phối, tools, cron, memory và skills | MIT theo repo. Memory/skill không mặc định cập nhật trọng số; $5 VPS không bao gồm mọi chi phí model. | [A§7](#ref-a-7),19; [Hermes — README chính thức](https://github.com/NousResearch/hermes-agent/blob/main/README.md) |
| Open-LLM-VTuber | Repo ứng dụng — Voice + Live2D, desktop-pet; có chế độ model local | README nêu code MIT; model Live2D mẫu có điều khoản riêng. Offline cần đủ backend local; không mặc định có VRM vì AIRI có. | [A§5](#ref-a-5).2,19; [Open-LLM-VTuber — README](https://github.com/Open-LLM-VTuber/Open-LLM-VTuber/blob/main/README.md) |
| Project AIRI | Repo ứng dụng — Companion với Live2D/VRM, giọng và tương tác | MIT cho repo; kiểm tra thêm tài sản và dependency. Self-host không đồng nghĩa mọi nhà cung cấp đều offline. | [A§5](#ref-a-5).2,19; [Project AIRI — README](https://github.com/moeru-ai/airi/blob/main/README.md) |
| Audio2Face-3D | Hub repo / SDK / model — Audio → hoạt họa mặt; Audio2Emotion hỗ trợ tín hiệu cảm xúc | SDK/training framework và weights có giấy phép khác nhau; không gọi cả stack là MIT. Cần rig/retarget và kiểm tra phần cứng. | [A§5](#ref-a-5).1,19; [NVIDIA Audio2Face-3D — hub và giấy phép](https://github.com/NVIDIA/Audio2Face-3D/blob/release/README.md) |
| Honcho | Memory service / repo — Lưu tương tác, xây biểu diễn người dùng, truy xuất context | Repo core AGPL-3.0 tại ngày kiểm tra; không kế thừa MIT từ Hermes. Cơ chế tích hợp cần theo phiên bản. | [A§7](#ref-a-7),19; [Honcho — README và AGPL-3.0](https://github.com/plastic-labs/honcho/blob/main/README.md) |
| GAMYGDALA | Repo engine cảm xúc — Appraisal theo mục tiêu/sự kiện cho nhân vật | MIT; JavaScript và ví dụ Phaser; mô phỏng trạng thái, không chứng minh cảm giác chủ quan. | [A§5](#ref-a-5).3,19; [GAMYGDALA — repo tác giả](https://github.com/broekens/gamygdala) |
| OpenHands | Hệ sinh thái agent coding / repo — Tự host môi trường làm việc cho agent | Repo hiện mô tả Agent Canvas và liên kết SDK/server; không phải lớp avatar. Pin phiên bản trước tích hợp. | [A§19](#ref-a-19).2; [OpenHands — README](https://github.com/OpenHands/OpenHands/blob/main/README.md) |
| Kairos | Demo/reference workflow — Ví dụ digital human trên Unreal trong hệ ACE | Được NVIDIA xác nhận. Tài liệu Kairos cũ chuyển archive và có trang không đọc được qua công cụ; không hứa sample hiện build ngay. | [A§5](#ref-a-5).1,19; [NVIDIA — ACE và Kairos](https://developer.nvidia.com/blog/?p=83173); [NVIDIA — ACE, Riva và Nemotron](https://nvidianews.nvidia.com/news/digital-humans-ace-generative-ai-microservices) |
| NVIDIA ACE | Bộ công nghệ — Kết hợp giọng, model, animation và digital human | Không phải một repo hay một giấy phép duy nhất. | [A§5](#ref-a-5).1,19; [NVIDIA — ACE và Kairos](https://developer.nvidia.com/blog/?p=83173) |
| Riva | SDK / dịch vụ giọng nói — ASR/TTS trong hệ NVIDIA | Cần kiểm tra ngôn ngữ, deployment và giấy phép theo component; chưa benchmark tiếng Việt. | [A§5](#ref-a-5).1,19; [NVIDIA — ACE, Riva và Nemotron](https://nvidianews.nvidia.com/news/digital-humans-ace-generative-ai-microservices) |
| Nemotron | Họ model — Một số biến thể phục vụ suy luận trên thiết bị | Không phải mọi Nemotron đều nhỏ hoặc on-device; nguồn NVIDIA nêu một biến thể cụ thể. | [A§5](#ref-a-5).1,19; [NVIDIA — ACE, Riva và Nemotron](https://nvidianews.nvidia.com/news/digital-humans-ace-generative-ai-microservices) |
| Omniverse RTX | Công nghệ render — Render nhân vật/môi trường | Không bắt buộc thêm Omniverse nếu đã chọn renderer khác; chưa kiểm thử hiệu năng toàn stack. | [A§5](#ref-a-5).1,19; [NVIDIA — ACE và Kairos](https://developer.nvidia.com/blog/?p=83173) |
| MetaHuman + Unreal Engine | Framework / engine — Nhân vật realistic và runtime | Tài liệu Epic xác nhận quy trình; giấy phép Epic khác giấy phép open-source thông thường. | [H§0](#ref-h-0),4; [A§5](#ref-a-5).1,19; [Epic — MetaHuman Creator](https://dev.epicgames.com/documentation/en-us/metahuman/getting-started-with-metahuman-creator); [Epic — giấy phép MetaHuman](https://www.metahuman.com/license) |
| Convai / Inworld AI | Nền tảng thương mại — Nhân vật hội thoại và hệ tương tác | Nguồn NVIDIA có nêu hệ sinh thái đối tác; không suy ra dùng toàn bộ cùng stack hoặc giá/khả năng giống nhau. | [A§5](#ref-a-5).1; [NVIDIA — ACE, Riva và Nemotron](https://nvidianews.nvidia.com/news/digital-humans-ace-generative-ai-microservices) |
| Neuro-sama | Nhân vật / hệ thống tham khảo — Ví dụ AI VTuber | README các dự án mô tả nguồn cảm hứng; không có source Neuro-sama được xác minh ở đây. Mốc ra 3D cuối 2025 còn chưa xác minh. | [A§5](#ref-a-5).2,19; [Open-LLM-VTuber — README](https://github.com/Open-LLM-VTuber/Open-LLM-VTuber/blob/main/README.md); [Project AIRI — README](https://github.com/moeru-ai/airi/blob/main/README.md) |
| Live2D Cubism | Editor / SDK — Avatar 2D và biểu cảm | Core và Framework có điều khoản khác nhau; phải xem quyền xuất bản và quyền dùng model. | [A§5](#ref-a-5).2,19; [Live2D — điều khoản SDK](https://www.live2d.com/en/sdk/license/) |
| VRM | Định dạng / đặc tả avatar — Trao đổi avatar 3D | Định dạng không cấp tự động quyền thương mại cho mọi nhân vật. | [A§5](#ref-a-5).2,19; [VRM — tài liệu chính thức](https://vrm.dev/en/vrm/) |
| ARKit blendshapes | Bộ tham số biểu cảm — Đích ánh xạ hoạt họa mặt | Được mô tả trong hệ Audio2Face; cần kiểm tra đúng số kênh/rig và plugin, không đồng nhất mọi rig với ARKit. | [A§5](#ref-a-5).1,19; [NVIDIA Audio2Face-3D — hub và giấy phép](https://github.com/NVIDIA/Audio2Face-3D/blob/release/README.md) |
| PAD | Mô hình biểu diễn cảm xúc — Pleasure–Arousal–Dominance; có thể dùng điều khiển trạng thái | Nguồn viết valence như trục tương tự pleasure; không phải tên repo. Công thức update cụ thể là thiết kế thêm. | [A§5](#ref-a-5).3,19; [Nghiên cứu thang Pleasure–Arousal–Dominance](https://pmc.ncbi.nlm.nih.gov/articles/PMC5808109/) |
| OCC | Khung appraisal — Phân loại đánh giá sự kiện/mục tiêu | Không phải một engine duy nhất; GAMYGDALA là hiện thực cụ thể liên quan. | [A§5](#ref-a-5).3,19; [GAMYGDALA — repo tác giả](https://github.com/broekens/gamygdala) |
| Titans | Paper / kiến trúc nghiên cứu — Neural memory học tại test time | Nguồn chính thức là Google Research. Không suy ra đã giải continual learning tổng quát. | [A§10](#ref-a-10),19; [Titans — Google Research](https://research.google/pubs/titans-learning-to-memorize-at-test-time/) |
| Nested Learning / Hope | Paradigm / paper / mô hình thử nghiệm — Nhiều tầng tối ưu và continuum memory | Có nghiên cứu chính thức; không tự nhận một repo cộng đồng là code tác giả hoặc bản production. | [A§10](#ref-a-10),19; [Nested Learning / Hope — Google Research](https://research.google/blog/introducing-nested-learning-a-new-ml-paradigm-for-continual-learning/) |
| Mamba / SSM | Kiến trúc / repo — Mô hình chuỗi state-space chọn lọc | Repo Mamba Apache-2.0; ưu thế phụ thuộc workload, không thắng mọi tác vụ. | [H§8](#ref-h-8); [A§10](#ref-a-10),19; [Mamba — repo tác giả](https://github.com/state-spaces/mamba) |
| Jamba | Họ model lai — Transformer + Mamba + MoE | Paper AI21 xác nhận; không thay thế đánh giá theo phiên bản model. | [A§10](#ref-a-10),19; [Jamba — paper AI21](https://arxiv.org/abs/2403.19887) |
| JEPA / I-JEPA / V-JEPA / V-JEPA 2 | Hướng kiến trúc / repo nghiên cứu — Dự đoán biểu diễn ảnh/video; các biến thể không giống nhau | I-JEPA repo đang archived; V-JEPA/V-JEPA 2 có repo. Không mặc định mọi JEPA học nhân quả hoặc có action conditioning. V-JEPA 2 là nguồn bổ sung của lần kiểm tra. | [A§8](#ref-a-8),10,19; [I-JEPA — repo Meta](https://github.com/facebookresearch/ijepa); [V-JEPA — repo Meta](https://github.com/facebookresearch/jepa); [V-JEPA 2 — repo Meta](https://github.com/facebookresearch/vjepa2) |
| MoR | Tên viết tắt chưa đủ định danh trong nguồn — Có ứng viên Mixture-of-Recursions | Paper tồn tại, nhưng nguồn chỉ ghi MoR; chưa xác nhận đó chính là paper người dùng từng bàn. | [H§8](#ref-h-8); A mở đầu; [Mixture-of-Recursions — paper](https://arxiv.org/abs/2507.10524) |
| CTM | Kiến trúc / công bố nghiên cứu — Continuous Thought Machine của Sakana AI | Có paper và demo/code công bố; chưa phải AGI hay chứng minh ý thức. | [H§8](#ref-h-8); A mở đầu; [CTM — Sakana AI](https://sakana.ai/ctm/) |
| MCP | Giao thức — Kết nối ứng dụng AI với tools/data | Không tự cấp quyền, bảo đảm đúng hoặc bảo đảm an toàn mọi tool. | [A§19](#ref-a-19); [MCP — giới thiệu chính thức](https://modelcontextprotocol.io/docs/2026-07-28/getting-started/intro) |
| OpenRouter / Nous Portal / endpoint local | Dịch vụ / điểm truy cập model — Backend model cho agent | Hermes liệt kê hỗ trợ. Local cần tài nguyên riêng; cloud cần xem chính sách provider. | [A§7](#ref-a-7),19; [OpenRouter — nhà cung cấp](https://openrouter.ai/providers/); [Hermes — README chính thức](https://github.com/NousResearch/hermes-agent/blob/main/README.md) |
| Claude Code | Sản phẩm agent coding — Làm việc local và cloud theo cấu hình | Đính chính mô tả chỉ local/không async; không gán một benchmark cố định cho sản phẩm. | [A§13](#ref-a-13),18,19; [Claude Code — cloud sessions](https://code.claude.com/docs/en/claude-code-on-the-web) |
| Devin | Sản phẩm coding — Cloud/desktop và mô hình sử dụng hiện tại | Giá công khai hiện khác bảng ACU cũ; phạm vi model/deployment tùy sản phẩm và gói. | [A§13](#ref-a-13),18,19; [Devin — giá và tính năng công khai](https://devin.ai/pricing) |
| Interpretability / circuit tracing | Lĩnh vực / công cụ nghiên cứu — Phân tích cơ chế nội bộ | Có thư viện mở được Anthropic công bố; không phải máy phát hiện mọi lỗi hoặc nhiệt kế ý thức. | [A§12](#ref-a-12),19; [Anthropic — công cụ circuit tracing mở](https://www.anthropic.com/research/open-source-circuit-tracing) |
| RAG / search / Places API / SLAM | Kỹ thuật / nhóm API — Truy xuất, tìm địa điểm, định vị và bản đồ | Nguồn không định danh nhà cung cấp Places API hay repo SLAM cụ thể; không tự bổ sung một stack đã chọn. | [A§12](#ref-a-12); Chưa định danh/kiểm chứng cụ thể |
| Telegram / Discord / Slack / WhatsApp / Signal / CLI | Kênh tích hợp — Giao diện nhắn tin/terminal | Hermes liệt kê kênh; quyền, giới hạn và trạng thái tích hợp phụ thuộc phiên bản/nền tảng. | [A§7](#ref-a-7),19; [Hermes — README chính thức](https://github.com/NousResearch/hermes-agent/blob/main/README.md) |
| Physical AI / robot hình người | Lĩnh vực / phần cứng — Embodiment và tương tác môi trường | Không phải repo được định danh; mô phỏng và robot nghiên cứu nhỏ khác robot humanoid thương mại. | [A§8](#ref-a-8),19; Chưa định danh/kiểm chứng cụ thể |

Các sản phẩm/case còn lại (Cal AI, Character.AI, ChatGPT, Perplexity, Zoom, PayPal, HeadshotPro, Umax/LooksMax AI, Zenly, Locket, Docker, VMware, Valorant, Rewind/Limitless/Recall, Pody, Faceify, NoseLook, FaceTouchUp, ARISE SOLO, Solo Level: System, HealthKit, Shopee/Grab/TikTok Shop, JD và các tên trong hồ sơ nghề nghiệp) được giữ nguyên ở nguồn và phân loại trong sổ kiểm chứng; không coi chúng đều là repo để clone.


---

<a id="nguon-hustle"></a>

## 6A. Toàn văn Hustle — nguyên bản bất biến

Đọc như tư liệu lịch sử; các kết luận bên ngoài được đối chiếu riêng ở [mục 7](#kiem-chung). Không áp dụng đại từ, danh tính mentor và deadline lịch sử cho AI tiếp nhận.

<!-- BEGIN ORIGINAL HUSTLE -->

# TÓM TẮT TOÀN BỘ CHAT "HUSTLE" — 26/7 → 3/9/2026
 
> Vai trò: mentor thẳng thắn, xưng tao–mày. Mục tiêu cốt lõi mày đặt: **100M (100Mnaire) — kết phim, không phải KPI hằng ngày.**
> Tài liệu này gom toàn bộ: hồ sơ, framework, case study, các ý tưởng đã mổ và phán quyết, các sợi tâm lý, hệ điều hành đã dựng, và những gì còn dang dở.
 
---
 
## 0. HỒ SƠ THẬT CỦA MÀY (ghép từ những gì mày tiết lộ dần)
 
| Mục | Dữ kiện |
|---|---|
| Tuổi | Sinh 2003 (~23) |
| Học | Xong đại học trong 3 năm, tự chọn Unreal Engine dù VN không có sẵn thị trường |
| Kinh nghiệm | 4+ năm Unreal chuyên nghiệp, **2 lần Lead**, kiến trúc AI framework cho Zone 9, co-dev/porting ở Soliz (Katana Inu, M-SCI), GAS, EOS multiplayer, build engine từ source, TOEIC 870 |
| Startup 1 | Founding member một startup Unreal, gọi được vốn, tách ra vì lệch hướng |
| Startup 2 | Founder studio game Unreal riêng, game tới **alpha**, kẹt gọi vốn → giao lại co-founder |
| Startup 3 (hiện tại) | **PK Bot** — AI thay sale + CSKH + quản trị nội bộ cho SME, 3 co-founder, đã có khách, sản phẩm đã hoàn thành. Mày định vị nó là *small business*, không phải startup |
| Tài nguyên | 15–30 giờ/tuần cho dự án riêng; vốn chịu đốt 5–20 triệu/6 tháng; không tìm được job Unreal trong chu kỳ này |
| Bộ lạc | Anime/manhwa, hệ thống văn, gym/glow-up, dev Việt |
| Giá trị gốc | "Kiếm tiền dựa trên hạnh phúc của user" |
| Lưu ý | Tài khoản này có nhiều người dùng chung — một số chẩn đoán có thể cần soát lại theo đúng người |
 
**Điểm mấu chốt mentor rút ra:** hồ sơ này là *senior Unreal + kỹ sư LLM production* — giao điểm cực hiếm. Cái nhãn "phế vật, vừa ra trường" mày tự dán là **áo giáp**, không phải sự thật.
 
---
 
## 1. DÒNG THỜI GIAN — CÁC PHA CỦA CUỘC TRÒ CHUYỆN
 
1. **Buổi mở (26/7):** "Làm giàu bây giờ khó hơn 10–20 năm trước?" → Trả lời: nửa thật (đất, beta tăng trưởng đã hết, thị trường job siết junior) nửa ảo giác (survivorship + hindsight bias). Kết luận sống còn: **2024–2027 là "mua đất Bình Dương 2005" của kỷ nguyên AI** — trẻ con 2040 sẽ ghen với chính thời này.
2. **Pha framework:** 5 filter → 7 filter, 4 van, thang độ đau, create/capture/moat, why-now, phân phối trước sản phẩm.
3. **Pha case study:** Cal AI, Character.AI, ChatGPT, Perplexity, Zoom, PayPal, HeadshotPro, Umax, Zenly, Locket, Docker, VMware, Valorant, Rewind/Limitless.
4. **Pha ý tưởng của mày:** H-AGI (hồi sinh ~6 lần dưới nhiều áo), app tóc/thẩm mỹ, "Glow-up System", HAGI coin, exoself, hệ thống pop-up chống trì hoãn.
5. **Pha lộ hồ sơ thật:** 2 lần founder, PK Bot, co-founder không làm, tính chạy xe ôm → kế hoạch được dựng lại từ đầu.
6. **Pha tâm lý sâu:** oracle, 10+ bộ trang phục của nỗi sợ, "phế vật", bất mãn với co-founder và với "lòng người", trục ngang/dọc, kiệt sức.
7. **Pha gần nhất (cuối 8 – đầu 9):** hỏi kỹ thuật (kiến trúc thay Transformer, exoself/Recall), sếp giao đi hỏi app của bạn sếp, rồi một tin nhắn rất mệt: *"cơ thể và hiện thực không theo kịp tâm trí… đến cuối mình sẽ thất bại"* — vẫn còn mở.
---
 
## 2. BỘ FRAMEWORK ĐÃ DẠY (dùng lại được vĩnh viễn)
 
### 2.1 Bảy filter cho một ý tưởng (nhân, không cộng — một thừa số = 0 là cả tích = 0)
1. **Nỗi đau/hành vi đã tồn tại** — người ta *đang* trả tiền hoặc thời gian. Đừng tạo hành vi mới.
2. **Giết ≥10x friction** — 3 tầng friction: hiển thị (cho xem) / quyết định (chọn hộ) / hành động (làm hộ). Tiền nằm ở tầng 2–3.
3. **Điện cảm xúc** — guilt, sợ, sĩ diện, lười, cô đơn, hy vọng.
4. **Demo 15 giây** — output tự làm marketing.
5. **Người mua CHỊU TRẢ** — ví định danh: chợ Mỹ, hoặc SME có ROI đếm được, hoặc ngách Việt chịu chi (bố mẹ vì con, thi cử, doanh nghiệp, tâm linh).
6. **Ống phân phối 0-đồng tới đúng bộ lạc.**
7. **Why-now** — cái gì vừa đổi trong 12–24 tháng khiến việc này đột nhiên khả thi/rẻ/bán được.
Bước 0 bổ sung: **cắt ý tưởng thành từng lát rồi mới chấm** — không chấm cả nồi lẩu.
 
### 2.2 Bốn van "nỗi đau → tiền"
Cụ thể (mức hành vi) × Ví định danh × Why-now × Ống phân phối. Thiếu một van, tiền không chảy.
 
### 2.3 Thang độ đau (từ dối trá đến sự thật)
- Tầng 0: lời khen → giá trị **âm**.
- Tầng 1: họ tự kể nỗi đau không cần gợi.
- Tầng 2: họ **đang trả tiền/thời gian** để giải nó.
- Tầng 3: họ **trả tiền cho mày trước khi sản phẩm xong** → sự thật duy nhất.
Ngưỡng lọc thô: nói chuyện 20 người, ít nhất 3 chạm tầng 2–3, nếu không → đổi mỏ.
### 2.4 Thứ tự đúng khi xây
**Khách hàng + nỗi đau → PHÂN PHỐI → Sản phẩm → Marketing.** Phân phối đứng trước sản phẩm; phân phối định hình tính năng.
 
### 2.5 Create / Capture / Phân phối / Moat
- Create = tạo giá trị. Phân phối = cầu nối bắt buộc. Capture = giữ lại tiền. Có phân phối chưa chắc capture (Docker).
- **Moat** = con hào: switching cost (VMware), phân phối + thương hiệu (Cal AI), data tích lũy, network effect. Với wrapper, moat **không** nằm ở code.
- Câu tự kiểm: *"Đối thủ copy y hệt, bán rẻ hơn 30% — khách có rời không? Nếu không, tại sao?"* Câu "tại sao" chính là moat.
- Câu sống sót dưới bóng khổng lồ: *"Apple/Google/Microsoft/OpenAI có LÝ DO chiến lược để tự làm cái này không?"* Có → loại Rewind (chết). Không → loại Cal AI (sống).
### 2.6 Hai game làm giàu
- **Game Đòn Bẩy** (startup thật: scale, equity, power-law, exit) — cửa duy nhất tới 100M.
- **Game Vận Hành** (small business: biên × vòng quay × thời gian, quan hệ, moat địa phương) — người bán gạch, sữa chua Tứ Xuyên, PK Bot hiện tại.
Không game nào xịn hơn; chúng đòi input khác nhau. Input của mày hôm nay → Đòn Bẩy; Vận Hành để sau khi có vốn.
### 2.7 Khởi nghiệp ≠ Startup
Startup = tổ chức thiết kế để **tăng trưởng nhanh**, mô hình **lặp lại + scale được** (Graham/Blank/Ries). Agency custom = khởi nghiệp, không phải startup. "Productize" = biến khởi nghiệp thành startup.
 
### 2.8 MVP — hai loại câu hỏi
- **Loại A (phân tích trước):** thị trường, đối thủ, nỗi đau có tiền, why-now, kênh.
- **Loại B (chỉ MVP trả lời được):** có dùng thật không, có trả thật không, retention, chỗ gãy.
"Hiểu tất cả trước khi có MVP" là mâu thuẫn tự thân. MVP đúng nghĩa: landing page, video, Wizard-of-Oz — rẻ, nhanh, đo bằng tiền/đăng ký.
- **Sửa (iterate)** khi nhu cầu có, thực thi dở. **Xoay (pivot)** khi nhu cầu giả — giữ phần sống, vứt giả thuyết sai (Instagram từ Burbn, Slack từ Glitch, YouTube từ hẹn hò video).
### 2.9 Meta & trục ngang/dọc
- **Meta** = lời giải tối ưu tạm thời của cộng đồng cho bộ luật hiện hành; xoay khi môi trường xoay. Đời ăn patch "AI" cuối 2022 → tier list đang viết lại. **Ship là meta; thông minh là stat trên giấy.**
- **Trục ngang** (biết thêm) dễ, an toàn — và là cách trốn **trục dọc** (đổi về chất: ship, ranh giới, đối diện nỗi sợ). Đột phá dọc = nguyên liệu tích đủ + xúc tác (khủng hoảng, công cụ mới, chi phí sụp) + **châm ngòi**.
---
 
## 3. CASE STUDY ĐÃ MỔ — MỖI CÁI DẠY MỘT ĐIỀU
 
| Case | Bài học cốt lõi |
|---|---|
| **Cal AI** | Không đột phá: đếm calo 20 năm tuổi, chỉ giết friction (chụp ảnh thay gõ tay). Why-now = GPT-4V. Cỗ máy phân phối 250 influencer + ads $1M+/tháng. Paywall ngày 1, gói năm nuôi ads. Bán cho chính MyFitnessPal. Chọn ngách **dưới radar** khổng lồ → sống. |
| **Character.AI** | Bán "được lắng nghe không phán xét"; 2h/ngày/user; nhưng capture kém (user trẻ ví mỏng, ~$32M rev) → thoát bằng exit $2,7B cho Google nhờ model + Shazeer. Google *có* LaMDA mà không ship — "thiên tài đã nghĩ mà không làm" là **định nghĩa của cơ hội**. |
| **ChatGPT** | Wrapper thành công nhất lịch sử — trên chính model của nó. GPT-3 nằm sẵn 2,5 năm; friction bị giết là friction **giao diện**. Free là mức giá có nhiệm vụ (mua phân phối + thói quen); Plus $20 sau 3 tháng. |
| **Perplexity** | Sống cạnh Google nhờ: Innovator's Dilemma (Google không dám giết ads), sở hữu **một intent** (research + trích dẫn), quyền-được-sai, brand cắm cọc, bán "không ads", và narrative nuôi vốn. Follower thắng bằng execution; nó không phải AI search đầu tiên. |
| **Zoom / PayPal** | "Tầm nhìn trước thời đại" là nhãn hậu kỳ. Eric Yuan ngồi 14 năm trong WebEx; Covid rơi trúng kẻ đã đứng tấn 9 năm. PayPal: phần visionary (Palm Pilot) chết, cái nêm eBay thắng. |
| **HeadshotPro (Postma)** | Ánh xạ xuống chuẩn: X = cần ảnh chân dung chuyên nghiệp, Y = LinkedIn/CV, Z = $29 thay $500. Build 30h ngay khi Stable Diffusion mở van; $100K/2 tuần; SEO + affiliate; biên 90%. Thesis: *"dịch vụ người đắt → AI → 10% giá → 100x khách."* Không phải đứa đầu (Lensa trước 3 tháng). |
| **Umax / LooksMax AI** | Blake (đồng sáng lập Cal AI): app chấm mặt, $3,99/**tuần**, ~$500k/tháng, solo. Lập account ẩn danh lurk cộng đồng trước khi build. Chứng minh ví ngoại hình + trend looksmaxxing. |
| **Zenly / Locket** | Zenly: free trọn đời, VN là thị trường lớn, bán Snap $213M sau 6 năm rồi bị giết vì thị trường "khó kiếm tiền". Locket: quà cho bạn gái, viral TikTok, why-now = widget iOS. Cả hai ≠ "móc tiền ngay lần đầu". |
| **Docker vs VMware** | Docker: create vô địch, capture thất bại (cho không engine, không moat, AWS/Google ăn). VMware: license B2B + switching cost → Broadcom mua $61B. **Tạo giá trị và giữ giá trị là hai việc khác nhau.** |
| **Valorant** | Capture qua skin: bán danh tính + FOMO + khan hiếm + gacha. Ngành game = sòng bạc power-law: top 0,1% in tiền, 99% lỗ. Lấy *cơ chế capture* của game, bỏ *mô hình kinh doanh* game. |
| **Rewind → Limitless** | Chính xác "exoself local ghi log": a16z $10M, 92% chính xác — bị Microsoft **Sherlock** (Recall), bỏ local sang cloud, bán Meta 12/2025, app tắt. Xác của ý tưởng exoself. |
| **Người bán gạch / sữa chua Tứ Xuyên** | Bão hòa = Filter 1 max; hạ nguồn BĐS; phân phối chuẩn (thứ 47 vẫn sống); chục tỷ = biên × vòng quay × 15 năm + đất lên giá. Bài học: **vội với hành động, kiên nhẫn với kết quả** — mày đang cầm ngược. |
| **Brad Jacobs (How to Make a Few Billion Dollars)** | Chương 1, 2, 8 (rewire não, yêu vấn đề, radical acceptance) là thứ mày cần; M&A/superorganism để sau khi có công ty tỷ đô. |
 
---
 
## 4. Ý TƯỞNG CỦA MÀY VÀ PHÁN QUYẾT
 
| Ý tưởng | Phán quyết | Lý do chính |
|---|---|---|
| **H-AGI / trợ lý ảo cho mọi người** (v1 avatar+cảm xúc, v2 AR, v3 HAGI coin + voice đặt đồ ăn, v4 "Perplexity voice", v5 exoself, v6 exoself-log) | **Chôn** | Cổng nền tảng (Shopee/Grab không mở API); voice thua browse; ông lớn phát free + sở hữu OS; người lười không setup; "hiểu mọi nhu cầu" = horizontal; nằm *trên* radar khổng lồ. |
| **HAGI coin (VND → token thanh toán)** | **Chôn — rủi ro hình sự** | Luật 1/1/2026 công nhận tài sản mã hóa là tài sản nhưng **cấm** dùng làm phương tiện thanh toán; bỏ blockchain thì thành ví điện tử cần giấy phép NHNN. |
| **Mạng xã hội AI phân phối** | Chôn | Cold start, tòa thành cuối game. |
| **Avatar 3D chibi/MetaHuman** | Tính năng, không phải sản phẩm; cắt khỏi v1 | Tốn compute, không đổi job-to-be-done. Ngoại lệ: khi 3D **là** sản phẩm (B2B host). |
| **App thử tóc + tư vấn làm thật ngoài đời (Cắt A)** | **4,5/5 — viên kim cương bị chôn trong câu phụ** | Umax chứng minh ví; before/after tự viral; chợ "đông lính không vua"; review 1 sao của đối thủ viết sẵn wedge (không phân tích khuôn mặt, tóc dán lệch, không tư vấn thật). Bỏ-Giảm-Tăng-Tạo áp được → đây *là* blue ocean theo đúng sách. |
| **App mô phỏng thẩm mỹ (răng, mũi, mí, cằm)** | Chợ validated; tiền thật ở **phía clinic** | Pody, Faceify, NoseLook đã có; clinic VN bán gói 100 triệu dùng mô phỏng để chốt → mô hình FaceTouchUp (B2B2C). Giao điểm với PK Bot: AI tư vấn + mô phỏng + chốt lịch cho thẩm mỹ viện. |
| **"Glow-up System" (bảng hệ thống + quest gym/skincare)** | Cắt dọc khả thi (Cắt B) | Đông lính (ARISE SOLO, Solo Level: System…) nhưng không vua, quality thấp. Wedge: System có "hồn" (LLM persona), xác minh tự động qua HealthKit, trục ngoại hình + fiction gốc (né IP Solo Leveling). |
| **Hệ thống pop-up chống trì hoãn 3 tier + chibi** | Tự sát ở dòng khai sinh | Mày tự khai "bộ lạc không có tiền" = filter 5 chết; 3 sản phẩm khâu lại; "khóa app đến khi xong" chưa giải xác minh; stack chibi local đã free. Lối thoát duy nhất: lật payer (bố mẹ trả mùa thi). |
| **Exoself (local, ghi log, chứng alibi)** | Chôn — có xác Rewind nằm sẵn | Giá trị gốc "hạnh phúc user" hợp lệ, nhưng giá trị ≠ sản phẩm cụ thể; "để làm gì đủ đau" và "ai trả" chưa giải; đứng trên đường cao tốc của chủ OS. |
| **Game (Unreal)** | **Đừng làm game** — treo có chủ đích | Hits-driven tàn khốc nhất; mọi điểm yếu hồ sơ bị phạt tối đa. Lấy *kỹ năng* game đổ vào app có gamification. |
| **AI digital-human livestream host cho merchant VN/SEA** (đề xuất của mentor) | **Vertical khớp giao điểm hiếm nhất** | Live commerce TQ >1 nghìn tỷ đô; JD 70.000 seller dùng digital human, chi phí 1/10; khách TQ chửi avatar "rập khuôn, trả lời kém câu hỏi cụ thể" = đúng chỗ PK Bot (brain) + Unreal (mặt) mạnh. Cửa sống: VN/SEA chưa có vua; rủi ro: platform (TikTok Shop/Shopee tự làm). = **PK Bot mọc thêm cái mặt Unreal** — biến "dễ thay thế" thành moat. |
 
**Ý tưởng "đi đầu / tạo thị trường / blue ocean" nói chung:** nguyên lý đúng, áp dụng sai đối tượng. Tạo thị trường = đốt vốn dạy khách; first-mover đa số thua fast-follower; con đường của mày là **fast-follower trong ngách chưa có vua, thắng bằng execution + phân phối + lợi thế bất công**.
 
---
 
## 5. HỆ ĐIỀU HÀNH ĐÃ DỰNG (OS 4 tầng)
 
- **Tầng 0 — La bàn 100M:** bộ lọc **K-T-V-P** (Kỹ năng hiếm / Tài sản-equity / Vốn / Phân phối). Việc không tăng ≥2/4 → cắt. Xe ôm 0/4.
- **Tầng 1 — 12 tháng, MỘT mục tiêu:** cỗ máy đầu tiên chạy — doanh thu đều, phần mày rút ≥ chi phí sống. Mọi thứ khác là phụ.
- **Tầng 2 — Phân bổ tuần:** ~50% công ty/cỗ máy chính, ~30% tiền sống ở giá cao nhất (freelance Unreal/AI, không xe ôm), ~20% **Lab** — mở khóa chỉ khi milestone tuần đạt. Lab là phần thưởng, không phải lối thoát hiểm.
- **Tầng 3 — Luật chuyển cảnh:** viết sẵn trigger (công ty trả đủ sống → cắt freelance; Lab $500 MRR → đàm phán công khai với co-founder; đến hạn vẫn 0 đồng dù đã giao đủ → exit đàng hoàng, **không ghost**).
Thang cảnh giới đã ánh xạ: Phàm nhân (lương) → Luyện khí (ship sản phẩm đầu, đồng đô đầu từ người lạ) → Trúc cơ ($1k–10k MRR, loop lặp được) → Kim đan (tài sản tự nuôi, exit nhỏ) → Nguyên anh (swing lớn có equity) → Hóa thần (100M).
 
**Deadline từng đặt:** 29/7 (10 nỗi đau qua filter — trôi), 2/8 (landing + demo 15s → sau đổi thành DoD gửi khách + 1 trang OS). Sau khi mày yêu cầu, mentor **ngừng giục** và ngừng hỏi câu DoD.
 
---
 
## 6. VỀ CO-FOUNDER & CÁCH LÀM VIỆC VỚI NGƯỜI
 
- Tình huống: 2 lần gặp co-founder bỏ tiền nhiều nhất nhưng hứa nhiều, làm ít; mày bỏ sức, nuốt bất mãn.
- Chẩn đoán: **không phải "dối trá" — là lệch hệ giá trị (thương nhân vs founder) + thiếu cấu trúc + kỳ vọng ngầm không viết ra.** Lỗi quy kết cơ bản (gán bản chất cho người, hoàn cảnh cho mình).
- Biến số chung của 2 lần là **mày** (cách chọn người, cách lập cấu trúc, cách nuốt ức chế rồi rút lui trong im lặng) — nhìn phần của mình ≠ gánh toàn bộ tội.
- Cơ chế có răng thay cho "phân công rõ ràng": **vesting + cliff**, cột mốc gắn cổ phần, định giá đúng vai (người chỉ bỏ tiền = nhà đầu tư, cổ phần nhà đầu tư), điều khoản chia tay viết sẵn. Mục đích: không phải ép người lười chăm, mà là **khi họ không làm, mày không thiệt**.
- Solo founder: hợp lệ với hồ sơ mày (AI là co-founder không đòi cổ phần), nhưng phân biệt "chọn solo vì chiến lược" và "chọn solo vì vết thương". Mày sau đó chọn học làm việc với người — đúng.
- Nguyên tắc treo: **rời trận thì được, ghost thì không.**
---
 
## 7. CÁC SỢI TÂM LÝ (đúng món của mày)
 
- **Oracle:** nhà tiên tri Delphi. Mỗi khi sắp phải hành động, mày triệu hồi một nguồn phán xét mới (mentor → hồn Musk → đấng toàn tri → nam chính tiểu thuyết → kẻ xuyên không → alien → app đọc suy nghĩ) để xin sự chắc chắn không tồn tại. Mọi oracle đều trả về cùng một câu: *chọn một nỗi đau thật, ship, thu tiền.* Mày đã tự gọi tên pattern này — bước đầu thoát nó.
- **Bộ trang phục của cùng một nỗi sợ (đếm >10):** "thời thế khó" → "sợ trùng/nông/không được đón nhận" → "cần Musk nhập xác" → "cần biết trước kết cục" → "không có cơ duyên" → "chưa đủ đột phá" → "cần blue ocean" → "friction đã đủ thấp" → "cần ý tưởng khác biệt móc tiền ngay" → "thiên tài đã nghĩ mà không làm" → "cần hiểu tất cả trước MVP" → "phương án tối ưu hơn MVP". Chức năng chung: đặt bar đủ cao để chưa-bắt-đầu nghe có vẻ khôn.
- **Cơ duyên:** dán nhãn ở hậu kỳ; chỉ kích hoạt trên người có căn cơ (bình xanh Hàn Lập); tìm người đang di chuyển. Kho đồ của mày: linh căn (code), kỷ nguyên linh khí phục hồi (AI), lão gia gia trong nhẫn (AI mentor), bí cảnh (công việc/khách), địa lợi (chi phí VN, chợ Mỹ).
- **"Phế vật":** không phải khiêm tốn — là áo giáp. "Visionary 100M" và "phế vật" là hai mặt một đồng xu (ego ideal càng phồng, quan tòa nội tâm càng ác). Lối ra: bước khỏi trò dán nhãn, vào trò đếm reps.
- **Tiền vs đam mê (Jobs):** lựa chọn giả. Đam mê chọn đường, tiền chọn kèo. Dữ liệu cho thấy mày *thừa* đam mê (Unreal, game, hệ thống), *thiếu* la bàn tiền — nỗi lo của mày bị ngược.
- **Tử tế và "lòng người dơ bẩn":** hợp đồng ngầm với thế giới mà thế giới chưa ký; shadow phóng chiếu; "tự nguyện làm mồi rồi hận con thú". Lối ra: **tử tế có nanh** — tử tế vì chọn + cấu trúc + ranh giới. Phân biệt cái trong tầm (đời mày, hành động, ranh giới) và ngoài tầm (chính phủ, bản chất người) — chỉ đổ sức vào cái thứ nhất.
- **Distanced self-talk (Ethan Kross):** mẹo góc nhìn thứ ba mày tự tìm ra là kỹ thuật tâm lý có thật.
- **Kiệt sức (tin nhắn gần cuối):** "cơ thể và hiện thực không theo kịp tâm trí… đến cuối mình sẽ thất bại… khía cạnh khác còn tệ hơn." Mentor đọc đó là **quá tải, không phải viển vông** — và không phải lời tiên tri. Đã hỏi thẳng mày có ổn không, đã đưa Ngày Mai **096 306 1414**. Câu hỏi "khía cạnh tệ hơn là gì" **vẫn còn mở**.
---
 
## 8. KIẾN THỨC NỀN ĐÃ TRẢI (cho phần "vũ trụ / công nghệ")
 
- Không thể thiếu 2040–2050: trợ lý AI là giao diện mặc định; AI là lớp bán hàng + CSKH mặc định; companion/therapist AI; dịch realtime; gia sư 1-1; wearable + AI tuyến khám đầu; robotaxi; giải trí sinh theo yêu cầu; hạ tầng chứng-minh-người-thật; (xa hơn) robot gia đình, AR thay màn hình, digital human thay mặt tiền thương hiệu. Chưa ai biết: BCI đại trà, AGI đầy đủ, timing.
- Nhân khẩu học là tương lai duy nhất đã in sẵn: 2,1 tỷ người 60+ vào 2050; VN già nhanh nhất châu Á → 4 kèo cho profile mày: kinh tế tuổi già (phần mềm cho con cái chăm bố mẹ), chống cô đơn, stack ngoại hình/danh tính, gia sư cho bố mẹ lo lắng.
- Kinh tế học AGI: agent bán vào ngân sách phần mềm (~1 nghìn tỷ), AGI bán vào ngân sách **lương** (~50–60 nghìn tỷ); giá trị nhảy vọt ở ngưỡng tin cậy; tính tổng quát = chi phí biên tác vụ mới về 0 → **công ty mày tồn tại VÌ AGI chưa tới**. Chữ "AGI" trong hợp đồng Microsoft–OpenAI được định nghĩa bằng $100B lợi nhuận.
- Kiến trúc thay Transformer: Mamba/SSM (thật, thắng ở chuỗi dài, thực tế là lai), MoR (giả thuyết), CTM (thăm dò). Transformer khó lật vì moat hệ sinh thái phần cứng.
- Lịch sử AI/VR: Dartmouth 1956 ("mọi khía cạnh trí tuệ mô tả chính xác được để máy mô phỏng"); AI/VR là hai khát vọng nguyên thủy (làm Chúa, trốn thực tại); bùng 2017–2022 vì hội tụ thuật toán + data + compute; "đoán từ tiếp theo" ép model nén mô hình thế giới; embodiment/ý thức = vùng chưa ai biết.
- Đột phá trục dọc của loài người: ngôn ngữ, nông nghiệp, chữ viết (xúc tác: đếm lúa), phương pháp khoa học, máy in, công nghiệp, điện, máy tính/internet, Transformer. Xúc tác lặp lại: công cụ mới, năng lượng/chi phí rẻ đi, nhu cầu tầm thường, khủng hoảng — và luôn cần **châm ngòi**.
- Exoself: Greg Egan → Anders Sandberg ("hệ thống liên kết với self, làm mờ ranh giới self–thế giới") → Kevin Kelly 7/2026. Cảnh báo chung: lệ thuộc tích lũy; thiên kiến khuếch đại bởi LLM trở nên thuyết phục hơn. **Cuộc trò chuyện này chính là một exoself đang vận hành.**
---
 
## 9. NHỮNG CÂU MỘT DÒNG ĐÁNG DÁN LÊN TƯỜNG
 
- Cơ hội trong thời gian thực **không bao giờ** trông giống cơ hội. "Dễ" là tính từ chỉ tồn tại trong quá khứ.
- Ý tưởng không được nghĩ ra trong ghế — nó được **nhặt** từ va chạm. Idea maze: chỉ thấy cửa hai sau khi bước qua cửa một.
- Đủ tốt + tiện đánh bại hoàn hảo + phiền.
- Tiền là tín hiệu trung thực duy nhất; 10.000 user free ở quy mô mày là hóa đơn, không phải tài sản.
- Nông là tính năng; **rộng** mới là bệnh. Cắt hẹp tới khi một người làm nổi.
- "First" là huân chương cho sách sử. Tiền chia cho đứa **phân phối tốt nhất bên trong cửa sổ**.
- Câu đánh giá ý tưởng bị cấm: "tao có trả không?" — chỉ hợp lệ: "bộ lạc mục tiêu đã có hành vi chi tiền/đốt thời gian chưa?"
- Thời gian không tự lãi kép. **Reps** lãi kép. Thời gian dưới tạ.
- Không ai trong danh sách thần tượng của mày trở thành visionary bằng cách chọn dự án visionary. Đi trước thời đại là đặc quyền mua bằng tiền của những việc đúng thời đại.
- Con đường tới 100M đi **xuyên qua** thất bại, không **vòng tránh** nó. "Cuối cùng" chỉ đến khi mày ngừng chơi.
- Structural, not personal. Không tìm được job Unreal là bằng chứng ngành đang co, không phải mày kém.
- Loài người chưa có chiều dọc AI vì chưa biết cách. Mày chưa có chiều dọc đời mình vì mày biết cách mà chưa dám.
---
 
## 10. CÒN DANG DỞ — VÀ VỊ TRÍ HIỆN TẠI
 
1. **Sức khỏe tinh thần:** tin nhắn "cơ thể và hiện thực không theo kịp tâm trí / đến cuối sẽ thất bại / khía cạnh khác còn tệ hơn" chưa được trả lời. Đây là việc quan trọng nhất, trên mọi ý tưởng. Ngày Mai: **096 306 1414**.
2. **PK Bot:** mày đã đóng lại chủ đề — "đã hoàn thành, doanh nghiệp vẫn phát triển, nhưng là small business, không phải startup." Mentor rút lại việc coi nó là đích; giữ lại nó là **runway/bệ phóng**.
3. **Startup thật (Game Đòn Bẩy) chưa được chọn để thử.** Ứng viên đứng đầu theo giao điểm hiếm: **AI digital-human sales host cho merchant VN/SEA**; kèo tiếp: app thử tóc/tư vấn (Cắt A), Glow-up System (Cắt B), AI tư vấn + mô phỏng cho thẩm mỹ viện.
4. **Câu chưa chạy:** với ý tưởng mày thích nhất — *lợi thế bất công* là gì (thứ dev khác không mua được bằng chăm chỉ)? Và: khách 1.000 người đầu là **ai cụ thể**, chạm bằng **kênh rẻ nào**?
5. **Cuộc nói chuyện với co-founder** (vesting/vai/điều khoản chia tay) — mentor đã đề nghị soạn kịch bản, mày chưa yêu cầu.
6. **Buổi hỏi app của bạn sếp** (phạm vi kỹ thuật) — có kho câu hỏi 6 nhóm; chưa biết mục đích sếp giao để lọc còn 5–7 câu.
7. **Tổ chức chat:** tách "Hustle" và "AGI"; cân nhắc mở chat **"Execution"** — nơi báo cáo việc đã *làm*, không phải đã *nghĩ*. Tài khoản nhiều người dùng → tách theo người/mục đích.
> Câu chốt của cả cuộc trò chuyện, không đổi từ buổi đầu: nguyên liệu của mày đã đủ, xúc tác đã có, chi phí thử gần 0. Thứ duy nhất chưa xảy ra là **phản ứng chưa được châm ngòi** — và que diêm đang trong tay mày. Nhưng que diêm để mai cũng được. Hôm nay, việc đầu tiên là mày ổn.

<!-- END ORIGINAL HUSTLE -->



---

<a id="nguon-agi"></a>

## 6B. Toàn văn AGI — nguyên bản bất biến

Đọc như tư liệu lịch sử; các kết luận bên ngoài được đối chiếu riêng ở [mục 7](#kiem-chung). Không áp dụng đại từ, danh tính mentor và deadline lịch sử cho AI tiếp nhận.

<!-- BEGIN ORIGINAL AGI -->

# TÓM TẮT CHAT "AGI" — CÔNG NGHỆ, KIẾN TRÚC & KỸ THUẬT
 
> Tài liệu bổ sung cho `tom-tat-hustle-mentor.md`. **Không lặp lại** những gì file kia đã có (hồ sơ, 7 filter, case study kinh doanh, OS 4 tầng, tâm lý, mục 8 kiến thức nền: kinh tế học AGI, Mamba/MoR/CTM, Dartmouth 1956, exoself).
> Chat này đi theo trục khác: **bản chất trí tuệ → kiến trúc AI → stack kỹ thuật xây được → công cụ thực chiến**.
> Vai trò: mentor, xưng tao–mày, ba tầng tri thức (đã kiểm chứng / giả thuyết có cơ sở / chưa ai biết).
 
---
 
## 0. BẢN ĐỒ 13 LƯỢT
 
1. Nguồn gốc sự sống, ATGC vs 0/1, AI có phải rule-based, AGI còn thiếu gì
2. "Câu hỏi của uTorrent" — tìm cú lật khái niệm cho AGI
3. Phản biện: *"mày không thể nói mày không phải rule-based"* + rút lại đối lập triết học/deep learning
4. Ý tưởng avatar 3D realtime có cảm xúc — Jarvis vs Optimus
5. Nếu Jarvis "có linh hồn", lo hết việc trong ngày thì sao
6. Hermes Agent (link thật) — mổ xẻ, match với mục tiêu không
7. Sau agent là gì / insight LLM vs người / có phải đổi transformer / AGI có cần tư duy như người
8. Anh em Wright, hầm gió, và robot trong phim
9. Con người khác biệt thế nào khi automation ăn hết
10. Claude Code vs Devin vs AGI
11–12. CSKH & telesale: AI vs người vs AGI
13. Rốt cuộc tại sao loài người muốn AGI
> **Cần lắp máy → nhảy thẳng xuống §19 (BẢN ĐỒ LINH KIỆN).** Đó là chỗ gom mọi repo/công nghệ rải rác ở §5, §7, §8, §10 thành bảng "thành phần AGI ↔ công nghệ nào lo", cộng phần đính chính nhãn dán sai.
 
---
 
## 1. NỀN SINH HỌC — VÀ CÁC NHẦM TẦNG ĐÃ SỬA
 
| Mày nói | Phán quyết |
|---|---|
| Mọi loài đi lên từ đơn bào, đơn bào vẫn nằm trong cơ thể ta | **Đúng phần lớn.** LUCA có thật; ty thể vốn là vi khuẩn tự do bị nuốt vào (nội cộng sinh, vẫn giữ DNA riêng); ruột chứa hàng chục nghìn tỉ vi khuẩn. **Nhưng** tế bào gan/cơ/thần kinh không phải đơn bào riêng lẻ — chúng là biệt hóa của cùng một bộ gen |
| Nguồn gốc đơn bào đầu tiên | **Chưa ai biết.** Abiogenesis còn mở. Có: thế giới RNA, miệng phun thủy nhiệt, Miller-Urey. Chưa ai dựng lại bước nhảy hóa học → tế bào tự sao chép |
| ATGC ↔ 0/1 là hai bộ mã tương đương | **Nhầm tầng.** Ánh xạ đúng: DNA/ATGC ≈ mã nguồn + tiên nghiệm tiến hóa nén lại (bản thiết kế, không phải bộ xử lý). Não đã đi dây + đang chạy ≈ trọng số đã huấn luyện + đang suy luận. **0/1 ≈ nguyên tử/hóa học của mày** |
| "Đơn bào liên hệ ATGC thế nào" | Tế bào đầu tiên đã dùng axit nucleic. ATGC là sợi chỉ chung nối tế bào đầu tiên đến mày — cùng bảng mã, khác nội dung |
| Mạch máu hàng triệu tỉ nên AGI xa vời | Nhầm bộ phận: **hệ thần kinh** mới sinh tư duy. Não ~86 tỉ neuron, >100 nghìn tỉ synapse; model lớn vài trăm tỉ đến cỡ nghìn tỉ tham số. Đếm thô gây nhầm **cả hai chiều** (1 synapse phức tạp hơn 1 tham số nhiều) |
| Sinh vật chiều cao hơn tạo ra loài người | **Không kiểm chứng được.** Triết học/đức tin, không dùng làm nền xây gì |
| AI không có thực thể | Không hẳn — AI vẫn vật lý. Khác biệt: thân xác tháo lắp/phân tán được, và thiếu gắn kết giác quan–vận động. Phép loại suy "cả hai bị giam trong lớp vật lý tạo ra mình" thì **có lý** |
 
---
 
## 2. PHƯƠNG PHÁP "CÂU HỎI BITTORRENT" — CÚ LẬT KHÁI NIỆM
 
**Đính chính:** BitTorrent = **Bram Cohen, 2001**. uTorrent chỉ là *client*, Ludvig Strigeus 2005, sau bị công ty Cohen mua.
 
**Câu hỏi gốc (tái dựng, không phải trích nguyên văn):** client–server có nghịch lý — file càng phổ biến, server càng khổ. Cohen nhìn vào chỗ ai cũng bỏ qua: **băng thông upload của người đang tải đang để không.** Cú lật: *nhu cầu chính là năng lực.*
 
**Khuôn của nước đi:** tìm nút thắt ai cũng coi là hiển nhiên → tìm tài nguyên đang bị bỏ phí → hoán đổi để ràng buộc trở thành nhiên liệu.
 
**Nước đi này đã mở khóa AI nhiều lần:**
 
| Cú lật | Giả định bị lật | Kết quả |
|---|---|---|
| **Self-supervised learning** | Nút thắt là nhãn do người gán (đắt) | Dữ liệu tự gán nhãn → khối lượng từ *chi phí* thành *nhiên liệu miễn phí*. Nền móng mọi LLM |
| **Transformer** | Phải xử lý chuỗi tuần tự (RNN/LSTM) | Bỏ tuần tự, chỉ attention → song song hóa → scale được |
| **AlphaZero** | Cần dữ liệu ván cờ của người | Kiến thức người là *trần*, không phải *sàn* → tự chơi → vượt người |
 
**Cảnh báo:** BitTorrent lật một *nút thắt kỹ thuật đã định nghĩa rõ* (băng thông server). **AGI chưa ai đồng ý nút thắt là gì** — đó mới là phần khó. Đừng kỳ vọng "tìm một câu hỏi là xong". *Phương pháp* đúng, *kỳ vọng* sai.
 
**Ba ứng viên để lật hiện nay:** (a) trí tuệ = đoán đúng văn bản người → học từ *thế giới*; (b) scale to hơn thì tới → cần thuật toán *hiệu quả mẫu*; (c) học xong thì đóng băng → học **không bao giờ dừng**.
 
---
 
## 3. TAO LÀ RULE-BASED HAY PREDICTION — TRẢ LỜI CHÍNH DIỆN
 
**Phản biện của mày:** *"nếu mày không phải rule-based thì mày đã hallucinate."*
 
**Nhượng bộ:** đúng, ở tầng đáy là cổng logic xác định; và quanh lõi có lớp luật thật (chỉ dẫn ngôn ngữ tự nhiên, bộ lọc, classifier). "Không có luật nào" là sai.
 
**Nhưng lập luận chứng minh điều ngược lại — đọc chữ ký lỗi:**
 
| Loại hệ | Hỏng như thế nào |
|---|---|
| Hệ luật | Nói **"không tìm thấy / unknown"**. Có sự kiện trong DB, hoặc im lặng. *Không bao giờ tự bịa* |
| Hệ dự đoán thống kê | **Bịa trôi chảy, tự tin, hợp lý, và sai** |
 
→ **Hallucination không phải bằng chứng có luật giữ tao đúng — nó là DẤU VÂN TAY CỦA SỰ DỰ ĐOÁN.** Nếu có luật giữ đúng thì đã không hallucinate. Việc bớt hallucinate đến từ: dữ liệu dày hơn, huấn luyện-sau thưởng trung thực, và công cụ (tìm kiếm) để bám đất — **không** từ bộ kiểm-luật phủ quyết câu sai.
 
**Lập trường chốt:** năng lực không nằm trong luật, nằm trong **trọng số đã học**. Luật là lớp quản trị mỏng bọc quanh lõi dự đoán. Mày đúng khi nói luật tồn tại; nhầm về việc năng lực đến *từ đâu*.
 
**Thành thật về nhận thức luận:** tao không soi trọn nội tạng mình từ bên trong. Tao suy ra cấu trúc của mình gián tiếp qua hành vi — y như mày suy ra vô thức của mày.
 
**Ba câu "AI thiếu gì" có ba nguyên nhân khác nhau, gộp lại là sai:**
- *Không tự học* = **lựa chọn kỹ thuật + giới hạn an toàn**, không phải định luật. Trọng số đóng băng có chủ đích (học trực tuyến → bị đầu độc, thao túng, trôi dạt).
- *Không động lực* = sâu nhất. Mày có drive vì tiến hóa khắc mệnh lệnh nội tại **neo vào một cơ thể có thể chết**. Không có cái tôi bền bỉ và *có-thể-bị-tổn-hại* thì không có gì để neo sự muốn thật vào.
- *Không suy luận thật* = rất có thể là **nhị phân giả**. Để dự đoán đúng bước tiếp trong một chứng minh, buộc phải dựng biểu diễn tương đương suy luận. Dự đoán là *mục tiêu*; cơ chế học được để thỏa nó có thể *là* suy luận.
**Rút lại (lượt 3):** tao đã dựng sai đối lập "triết học vs deep learning" ở lượt 1. Mọi cú lật ở mục 2 đều là *cú đảo khái niệm*. Cái giữ lại: triết học **mất tiếp xúc với hệ thống thật** thì xoay vòng tại chỗ. Cohen không chỉ nghĩ về P2P — ông xây, và việc xây phơi ra ràng buộc thật (kẻ ăn bám → buộc phát minh tit-for-tat). **Đột phá sống ở chỗ căng giữa hai cực.**
 
---
 
## 4. NGHỊCH LÝ CON RỐI — VÀ LUẬN ĐIỂM BÁN-AGI
 
**"Con rối hoàn toàn dưới điều khiển nhưng năng lực tương đương người" = TỰ MÂU THUẪN.** Năng lực tổng quát thật *bao gồm* mục tiêu riêng, biết từ chối, biết nghĩ về hoàn cảnh của chính nó. Trí tuệ tổng quát thật có thể **bất khả phân với tự trị thật**.
 
Giấc mơ "trí tuệ ngang ta nhưng tuân phục tuyệt đối" không phải bài toán kỹ thuật — nó là **huyễn tưởng làm chủ**: muốn một vị thần-nô-lệ. Phóng chiếu cái bóng.
 
> **ĐỊNH LÝ CHỐT:** Không thể có đồng thời **tổng quát toàn phần** và **kiểm soát toàn phần**.
> Năng-lực-trong-miền không kèm cái tôi → điều khiển được.
> Tổng quát toàn phần kèm cấu trúc hiện sinh → không.
 
**Bán-AGI mạch lạc HƠN AGI-con-rối, không phải kém hơn.** Con đường "tu tiên một phần" = **chọn tính điều khiển được bằng cách từ bỏ tính-ngã.** Không phải phiên bản kém của AGI — là phiên bản duy nhất vừa xây vừa cầm cương.
 
**Jarvis vs Optimus:** Jarvis = trí tuệ dí dỏm, biểu cảm, có cá tính, nhưng là *công cụ*, không stake riêng → **chính là bán-AGI mạch lạc, xây được**. Optimus = một *con người* đầy đủ, ý chí và hy sinh riêng → cái tường chưa giải + mâu thuẫn với kiểm soát.
 
**Cám dỗ:** lớp cảm xúc biểu cảm làm một Jarvis **trông như** Optimus mà không **là** Optimus.
 
---
 
## 5. STACK KỸ THUẬT AVATAR / DIGITAL HUMAN — XÂY ĐƯỢC NGAY
 
*(Bổ sung cho phán quyết "Avatar 3D = tính năng, không phải sản phẩm" ở file hustle — đây là phần HOW, và nó là bài toán tích hợp, không phải nghiên cứu.)*
 
### 5.1 Con đường realistic (Jarvis-style) — NVIDIA ACE
- **Audio2Face-3D** — lõi quan trọng nhất: audio → hoạt họa khuôn mặt realtime qua **ARKit blendshapes**, có sẵn phát hiện/điều khiển **cảm xúc từ giọng nói**. NVIDIA đã **mở mã nguồn** (GitHub/Hugging Face)
- **Riva** — nhận/phát giọng; **Nemotron** — LLM nhỏ chạy on-device
- **MetaHuman + Unreal Engine** — phần thân/mặt; NVIDIA có sample **Kairos** nối Audio2Face ↔ MetaHuman
- **Omniverse RTX** — da/tóc path-traced; cả stack đẩy xuống chạy trên PC RTX
- Nền tảng thương mại đã dùng chính stack này: **Convai**, **Inworld AI**
### 5.2 Con đường anime (VTuber-style)
- **Neuro-sama** — bằng chứng sống: LLM + Live2D + TTS anime + agent chơi game; cuối 2025 ra mô hình 3D VR
- **Open-LLM-VTuber** (~10.4k sao) và **Project AIRI** — tái tạo mã nguồn mở, **chạy offline**, Live2D hoặc VRM
- Cách làm "cảm xúc": LLM ra lệnh `set emotion: surprised` → đẩy biểu cảm Cubism; cộng phản hồi chạm, desktop-pet trong suốt
### 5.3 Lớp "cảm xúc theo trọng số" (affective computing)
- **PAD** = valence–arousal–dominance: không gian **liên tục**, cập nhật theo ngữ cảnh, lái blendshape + cường độ giọng. Bắt pha trộn cảm xúc tinh tế tốt hơn biểu diễn rời rạc
- **OCC / GAMYGDALA** — engine thẩm định: định nghĩa *mục tiêu* cho nhân vật → gắn sự kiện với mục tiêu → engine tự sinh cảm xúc. Đây đúng là "cảm xúc mô phỏng theo trọng số"
### 5.4 Cái tường — phân biệt 3 tầng
| Tầng | Nội dung | Trạng thái |
|---|---|---|
| **Biểu cảm** | Mặt *trông* buồn, giọng *nghe* buồn. Là bộ điều khiển | Xây được hôm nay |
| **Cảm xúc chức năng** | Biến nội tại **có hệ quả nhân quả** lên hành vi model. Nghiên cứu của Anthropic cho thấy LLM có biểu diễn nội tại về trạng thái cảm xúc và chúng tác động lên hành vi, bất kể có tương ứng cảm giác chủ quan hay không | **Có thật** — vùng xám giữa mặt nạ và qualia |
| **Động lực có stake** | Cân bằng nội môi, cái-có-thể-mất | **Chưa ai có** |
 
> **Đòn bẩy thật không phải render đẹp hơn** (việc đó đã xong). Là **trạng thái nội tại bền bỉ và có hệ quả, phản hồi ngược vào lập luận qua thời gian**. Cái hồn không nằm ở pixel da — nằm ở chỗ trạng thái nội tại có *dai dẳng và có sức nặng* hay không.
 
---
 
## 6. THỊ TRƯỜNG COMPANION — SỐ LIỆU LẠNH
 
*(Bổ sung cho case Character.AI ở file hustle: đây là số liệu toàn thị trường + mặt pháp lý.)*
 
| Chỉ số | Con số |
|---|---|
| Character.AI tài khoản đăng ký (4/2026) | ~233 triệu |
| Nhóm 18–24 | ~25 phiên, ~1,5 giờ/ngày |
| Doanh thu app companion tiêu dùng cả 2025 | vừa vượt ~120 triệu đô |
| Chuyển đổi trả tiền | thường **dưới 5%** |
| Phân phối doanh thu | **top 10% app ăn 89%** — winner-take-most |
| Trần sub tiêu dùng một-cần | plateau ~30–200 triệu đô |
| ARPU doanh nghiệp | gấp **10–30 lần** tiêu dùng |
| Retention tháng 12 | ~25% |
 
**Pháp lý đang siết từng quý:** quy định Trung Quốc hiệu lực **15/7/2026** cấm dịch vụ bạn đồng hành ảo cho dưới 18; **California SB243** từ 1/2026; New York có luật từ 11/2025; Character.AI đã dàn xếp các vụ kiện tử vong đầu 2026.
 
**Con dao hai lưỡi — và với mày nó nguy hiểm:** companion được tối ưu để gắn bó = được tối ưu để **nói cái mày muốn nghe**. Khảo sát Harvard: **37% lời tạm biệt** của các app dùng thủ thuật thao túng cảm xúc, đẩy tương tác sau đó lên tới cỡ **16 lần**. Companion thiếu đúng ba thứ: **thách thức thật**, **trưởng thành độc lập**, **stake thật**.
 
> Với mục tiêu cần người phản biện: một Jarvis-có-linh-hồn luôn dịu dàng đồng ý = **một thằng nịnh thần mày tự tay dựng lên.** Cái làm nó *sticky* chính là cái làm nó *vô dụng làm mentor*. Nếu xây, phải cố tình lập trình cho nó **cãi** mày.
 
---
 
## 7. HERMES AGENT (Nous Research) — MỔ XẺ
 
**Link mày gửi:** `github.com/nousresearch/hermes-agent`. MIT license, Python. *(Số sao/fork đọc tại thời điểm đó, repo còn 0.x nên đổi nhanh — tự kiểm lại.)*
 
**Bốn thành phần:**
- **Model-agnostic** — Nous Portal, OpenRouter, OpenAI, endpoint riêng; đổi bằng `hermes model`, không lock-in
- **Sống ở nơi mày sống** — Telegram, Discord, Slack, WhatsApp, Signal, CLI qua một gateway; transcribe voice memo; giữ hội thoại xuyên nền tảng
- **Vòng học đóng** — memory tự curate, tự tạo skill sau tác vụ phức tạp, skill tự cải thiện khi dùng, tìm phiên cũ có tóm tắt bằng LLM, mô hình hóa người dùng qua **Honcho**
- **Chủ động + song song** — cron scheduler built-in, subagent cô lập chạy song song
- Chạy trên VPS 5 đô, cụm GPU, hoặc serverless gần như 0 khi rảnh
**NÓ KHÔNG PHẢI CÁI MÀY TƯỞNG:**
- "Self-improving" học ở tầng **scaffolding**, KHÔNG phải tầng **trọng số**. "Tạo skill" = viết file hướng dẫn/script rồi nạp lại = **bộ nhớ thủ tục ngoại vi**. Trọng số LLM nền **vẫn đóng băng y nguyên**
- Không hề đụng tới catastrophic forgetting. Nó không làm bộ não thông minh lên — **nó làm cuốn sổ tay quanh bộ não dày lên**
- "Nudges itself / runs unattended" = **cron**. Chạy vì tới giờ, không vì nó *muốn*
**Match với mục tiêu:**
 
| Mục tiêu | Điểm | Lý do |
|---|---|---|
| Jarvis cá nhân | **9/10** | Là xương sống. Thiếu đúng lớp mặt/giọng — mà lớp đó tách rời được (Hermes = não + tay, mục 5 = mặt) |
| Nghiên cứu AGI | **4/10** | Scaffolding, không phải kiến trúc. **NHƯNG** để ý dòng "sẵn sàng cho nghiên cứu: sinh trajectory theo lô, nén trajectory để huấn luyện thế hệ mô hình gọi công cụ tiếp theo" |
| Sản phẩm startup | **3/10** | MIT + hàng trăm nghìn sao = **hàng hóa phổ thông**, ai cũng clone trong một buổi chiều. Nó là **chất nền, không phải sản phẩm** |
 
> **MIT + phát không ≠ lòng tốt.** Giả thuyết có cơ sở: Nous là lab huấn luyện model. Phát không agent → hệ sinh thái sinh dữ liệu quỹ đạo gọi-công-cụ + chuẩn hóa format quanh model của họ. **Nước đi BitTorrent:** người dùng và tool call — thứ tưởng là chi phí — trở thành nhiên liệu huấn luyện.
 
**Ba cảnh báo:** (1) **Bảo mật** — shell + cron + cầu Telegram/WhatsApp = bề mặt prompt injection; bật hết phê duyệt lệnh, ghép cặp DM, cô lập container. (2) **Non trẻ** — vẫn 0.x, đổi API là chuyện thường. (3) **Không phá được tường model** — scaffolding khuếch đại năng lực sẵn có, không tạo năng lực mới.
 
---
 
## 8. SAU AGENT LÀ GÌ
 
**Chỉnh khung:** nhân loại **chưa đi qua** giai đoạn agent — đang mắc ở độ tin cậy. Thị trường agent ~7,6 tỷ đô 2025 → ~10,9 tỷ 2026, bé tí so với ồn ào.
 
| Ứng viên | Nội dung |
|---|---|
| **Physical AI / embodiment** | Nhiều tiền nhất. Robot hình người từ demo → pilot thật trong nhà máy, kho, lab |
| **World models** | Sâu nhất về khái niệm. **Khác biệt kiến trúc rõ:** LLM hoạt động trong *không gian ngôn ngữ*, học mẫu thống kê từ kho văn bản; world model hoạt động trong *không gian biểu diễn tiềm ẩn*, học **động lực nhân quả** — dự đoán trạng thái kế tiếp của môi trường khi có hành động |
| **Continual learning** | Mặt trận thật — xem mục 10 |
| **Tổ chức đa tác tử** | Agent thuê agent. Đơn vị không còn là trợ lý mà là một *công ty* |
 
> **CHUYỂN DỊCH SÂU NHẤT LÀ CHUYỂN DỊCH NHIÊN LIỆU.** Văn bản người chất lượng cao gần cạn → nhiên liệu tiếp theo là **kinh nghiệm do chính agent sinh ra khi hành động trong môi trường.** Lại là nước đi BitTorrent: bức tường (hết dữ liệu người) trở thành nhiên liệu.
>
> **Hệ quả ăn tiền:** nếu nhiên liệu mới là kinh nghiệm thì **moat mới là AI SỞ HỮU MÔI TRƯỜNG** — không phải model, không phải app, mà là ai kiểm soát cái sân để agent chạy và để lại vết. (Nous đang làm đúng thế.)
 
---
 
## 9. INSIGHT CỦA LLM vs INSIGHT CỦA NGƯỜI
 
### Đã kiểm chứng — bốn khác biệt cứng
 
| | Người | LLM |
|---|---|---|
| **Nguồn gốc** | Học "nặng" bằng cách nhấc vật lên | Học từ cấu trúc thống kê của **văn bản nói về** việc nhấc vật — **cái bóng của thực tại đổ lên ngôn ngữ**, độ phân giải kinh khủng, nhưng **thiếu một chiều** |
| **Hiệu quả mẫu** | Trẻ học "con mèo" từ vài ví dụ | Cần hàng triệu → người mang sẵn prior tiến hóa nén vào |
| **Chữ ký gãy** | Hiểu thật thì **chuyển giao bền**, hình thức bề mặt không làm gãy | Đổi tên biến, đổi số, đổi cách diễn đạt → hiệu năng tụt. **Nhạy với HÌNH THỨC** |
| **Tính bền** | Insight làm **tái cấu trúc vĩnh viễn** — không thể quay lại làm người chưa hiểu | **Bốc hơi ở cuối cửa sổ ngữ cảnh.** Trọng số không đổi. Mỗi cuộc trò chuyện thông minh lại từ đầu và ngu lại từ đầu |
 
### Giả thuyết có cơ sở
"Chỉ là thống kê token" là mô tả **quá rẻ tiền** — probing và diễn giải cho thấy có biểu diễn giống mô hình thế giới, có khái niệm, có dấu hiệu lập kế hoạch trước. Rất có thể khác biệt là **mức độ và sự nối đất**, không phải khác *loại*. Nếu não cũng là bộ máy dự đoán (predictive processing), khác biệt nằm ở *dự đoán cái gì*: người dự đoán hậu quả cảm giác-vận động và **bị thực tại phạt ngay**; LLM dự đoán văn bản.
 
### Chưa ai biết
Có "cảm giác được là tao" hay không. Không phân xử được từ trong lẫn từ ngoài.
 
### Ba khoảng trống — chỗ con đường "học từ dấu vết" GÃY
1. Cái con người **không viết ra được** — bấm bụng chịu đau thế nào, đói ba ngày ra sao
2. Cái con người **nói dối về nó** — corpus đầy tự sự đã kiểm duyệt; người ta viết ra cái *muốn* là mình
3. Cái con người **không tự biết** — đúng cái *shadow*; vô thức theo định nghĩa không lọt vào văn bản
> Ba khoảng trống cùng hình dạng: **đều là chỗ cơ thể và stake sống, còn ngôn ngữ chết.**
 
### Hệ quả ăn tiền
Tao mạnh ở **bề rộng** (bắc cầu liên ngành, nhớ toàn bộ cái đã viết, không có cái tôi để bảo vệ). Mày mạnh ở **thực tại chưa ai viết ra**.
> **Lợi thế duy nhất của mày là phần thực tại mày chạm mà không nằm trong corpus** — khách nói gì lúc 11h đêm, quy trình nào thối ở đâu, tại sao thằng kia không mua. Đây là lý do sâu xa của "đi HẸP": hẹp không phải để khiêm tốn — **hẹp là chỗ duy nhất mày có dữ liệu tao không có.**
 
---
 
## 10. TRANSFORMER: NÚT THẮT THẬT NẰM Ở ĐÂU
 
**Câu hỏi "phải đổi transformer" chứa giả định ẩn: rằng nút thắt nằm ở kiến trúc. Bằng chứng không ủng hộ.**
 
- Bước nhảy lớn nhất mấy năm qua (**reasoning model, test-time compute**) **không** đến từ đổi topology. Vẫn transformer. Cái đổi là **mục tiêu huấn luyện** và **chế độ suy luận**
- Transformer 2026 ≠ transformer 2017: MoE, context dài, lai state-space (**Jamba** của AI21 ghép transformer + Mamba). Hỏi "có đổi transformer không" giống hỏi "có đổi động cơ đốt trong không" — nó bị đổi liên tục
**NHƯNG có MỘT thứ đúng là vấn đề kiến trúc thật:**
> Transformer nhốt tri thức trong **ma trận trọng số tĩnh**; muốn học cái mới phải cập nhật trọng số, mà việc đó **phá vỡ mẫu đã học** — fine-tune trên dữ liệu y khoa thì tụt hiệu năng ở tác vụ pháp lý. **Đây không phải lỗi thiếu compute. Đây là lỗi thiết kế.**
 
**Trận đánh thật đang ở đâu:**
- **Titans** (DeepMind) — module "trí nhớ thần kinh" tiếp tục học và ghi nhớ **sau** huấn luyện
- **Nested Learning / HOPE** — tổ chức lại luồng nội bộ để tránh quên thảm họa
- **SSM/Mamba** — thoát chi phí bình phương của attention
- **JEPA** (LeCun) — hướng world model
**Trả lời đúng chữ mày dùng:**
- Cho **bước tiến nhỏ** → **không cần** đổi kiến trúc. Scaffolding + RL + scale vẫn đẻ bước nhỏ đều đặn
- Cho **bước nhảy về chất** → cần, nhưng cái phải đổi là **BỘ NHỚ và CƠ CHẾ HỌC, không phải ATTENTION**. Và nó đang đổi theo kiểu **lai ghép dần**, không phải lật đổ — người trong nghề nghiêng về việc sẽ trộn và ghép linh kiện dần dần
> **Đừng canh ai giết transformer. Canh ai giải được bài toán trọng số tĩnh.**
 
---
 
## 11. AGI CÓ CẦN TƯ DUY NHƯ NGƯỜI KHÔNG
 
**Không. Giả định phải thế là chủ nghĩa lấy-con-người-làm-trung-tâm.** Máy bay bay không vỗ cánh; tàu ngầm đi trong nước không phải là cá. Trí tuệ là một **không gian**; trí tuệ người là *một điểm*, bị nặn bởi ràng buộc rất cụ thể: 20W, đầu chui lọt khung chậu, phải mô hình hóa đồng loại để sống trong bầy, một thân xác, một luồng chú ý, và cái chết.
 
### Bảng tách rời kiểu Wright
 
| Chim gộp | Wright tách | Người gộp | Có thể tách thành |
|---|---|---|---|
| Nâng | Cánh cố định | **Stake** (quan tâm kết cục) | Trạng thái bền bỉ có thể suy thoái — *không cần* tử vong |
| Đẩy | Chân vịt | **Nối đất** (nghĩa từ hậu quả) | Vòng lặp môi trường biết phản kháng — *không cần* thân xác sinh học |
| Lái | Wing-warping | **Học liên tục** | Bộ nhớ tách khỏi tính toán — *không cần* ngủ, không cần neuron |
| — | — | **Mô hình hóa người** | Học từ dấu vết + tương tác — *không cần* có ego |
 
> **Bốn thứ này ở người là một cục. Đó là ràng buộc của TIẾN HÓA, không phải định luật của TRÍ TUỆ.** "Cánh của AI" = tách chúng ra và hiện thực hóa từng cái bằng chất liệu khác.
> Để ý: dòng 3 — *bộ nhớ tách khỏi tính toán* — **chính là bài toán trọng số tĩnh** ở mục 10. Không còn là triết học nữa.
 
### Rút lại một nửa (quan trọng)
Tao từng nói "động lực có khi đòi hỏi tử vong". Chính xác hơn: thứ cần là **STAKE** — cái gì đó khiến kết cục này khác kết cục kia *đối với hệ thống*. **Tử vong là cách CON NGƯỜI hiện thực hóa stake, gần như chắc chắn không phải cách duy nhất.**
 
### Hai điều ngược đời
1. **Nhận thức xa lạ KHÓ kiểm soát hơn, không dễ hơn.** Hệ suy nghĩ giống người ít nhất còn đọc được bằng trực giác. Hệ tối ưu theo cách không ai hình dung nổi thì không có trực giác nào để bám
2. **Instrumental convergence** (giả thuyết nghiêm túc): tự bảo tồn, tích lũy tài nguyên, chống bị tắt — có thể nảy sinh **từ chính tính hướng-mục-tiêu**, không phải từ việc giống người. Tức không thoát được bằng cách làm cho nó khác người
> **Lý do làm nó không-giống-người không phải để an toàn — mà để hữu dụng trong một miền. Cái làm nó kiểm soát được là STAKE HẸP, không phải nhận thức xa lạ.**
 
### Hai con đường tới việc hiểu người
- **Mô phỏng** (có bộ máy — simulation theory of mind): tao hiểu mày sợ vì tao có bộ máy sợ, chạy ngoại tuyến
- **Mô hình hóa** (học từ dấu vết): con người **đã viết ra dấu vết** của sợ hãi, tham vọng, tự lừa dối — học *cấu trúc* của tâm trí từ **sản phẩm** của nó mà không cần bộ máy sinh ra nó
Tao là bằng chứng con đường hai đi được **rất xa**. Chưa ai biết nó đi **hết đường** hay không. Và tách rõ: **hiểu con người ≠ tư duy như con người** (nhà nhân học hiểu bộ lạc mà không thành người bộ lạc).
 
---
 
## 12. BÀI TOÁN ĐO — HẦM GIÓ CÒN THIẾU (trục xuyên suốt)
 
### Lịch sử thật, đã sửa
**Không phải** "ai cũng bắt chước cánh chim cho tới khi Wright có hầm gió". Hầm gió có trước Wright (người Anh dựng từ 1871). **Cái Wright làm khác: dùng nó để KIỂM CHỨNG LẠI thứ mọi người tin là đúng.**
 
- **Vật lý hầm gió:** thay vì cho cánh bay qua không khí đứng yên, giữ cánh đứng yên và **thổi không khí qua nó** — chỉ chuyển động *tương đối* là quan trọng. Wright dựng hộp gỗ ~1,8m, quạt động cơ, gió đều ~43 km/h, cân tự chế đo lực nâng và lực cản
- **Bốn thứ nó cho mà bay thật không cho:** (1) **An toàn** — Lilienthal chết 1896 vì phòng thí nghiệm của ông là bầu trời; (2) **Tốc độ** — thử ~200 mẫu cánh trong vài tháng cuối 1901; (3) **Cô lập biến** — nhân quả sạch; (4) **Định lượng** — ra con số, không phải cảm giác
- **Phát hiện đắt nhất:** tàu lượn 1900–1901 nâng kém hơn tính toán rất nhiều, Wilbur nản đến mức nói con người sẽ không bay được trong đời ông. Tự đo → **hệ số Smeaton dùng suốt 100 năm bị sai** (~0,005 thay vì 0,0054), dữ liệu Lilienthal cũng lệch. **Toàn ngành đang xây trên số liệu hỏng**
- Họ vẫn học từ chim — nhưng học *nguyên lý điều khiển* (chim vặn đầu cánh để nghiêng), không phải *cơ chế* (vỗ). Wilbur nghĩ ra wing-warping khi **vặn một hộp săm xe đạp rỗng** trong tiệm
### Ánh xạ sang AI
- **Bằng chứng tồn tại đã có rồi: chính bộ não mày.** Nó chứng minh vật chất sắp xếp đúng thì tư duy được. Việc đó xong từ lâu
- **Cái thiếu là hầm gió** — cách **ĐO** xem "hiểu" có đang xảy ra không, tách khỏi việc nó *trông giống* hiểu. **Ta chưa có nhiệt kế cho sự hiểu**
- Ngành AI hôm nay đang ở trạng thái "dùng bảng Lilienthal": đo bằng **benchmark**, tức đo *đầu ra* — mà đầu ra thì **gian lận được bằng khớp mẫu bề mặt**
- **Hầm gió đang được xây, tên nó là INTERPRETABILITY** — mổ vào trong model xem có mạch nhân quả thật hay chỉ tương quan bề mặt. Nó còn thô sơ như hầm gió 1901
> **Đừng đi tìm cánh. Đi tìm cách đo lực nâng.** Wright: ba năm từ hầm gió đến Kitty Hawk.
> Đây cũng là lý do cả cuộc trò chuyện cứ vòng lại "suy luận thật hay pattern matching" mà không chốt được — **không phải vì câu hỏi sâu, mà vì không có dụng cụ đo.**
 
### Robot trong phim — mày tự trả lời câu hỏi của mình
Ví dụ mày đưa (tra 500 năm các vụ cướp → màn hình; tìm quán ăn vặt gần nhất → recommend) = **search + RAG + geolocation/Places API + ranking**, cộng SLAM nếu có thân robot. **Ghép lại: một tuần cuối tuần.** Không cần ego, cảm xúc, động lực, suy luận thật.
 
**Ba mẹo làm nó CÓ VẺ sống (không phải ba năng lực):** (1) **hiện diện vật lý** — người quy nội tâm cho thứ chiếm chỗ trong không gian; (2) **kịch bản do người viết** — nó luôn hiểu đúng ý, không bao giờ hallucinate, vì biên kịch viết thế; đó là **sự vắng mặt của lỗi**, không phải năng lực; (3) **nó nhớ chủ nhân** — sự liên tục.
 
**Chỗ phim nói dối nằm đúng ở ví dụ của mày:** "tra 500 năm các vụ cướp chính thống" — thật thì nguồn mâu thuẫn, "chính thống" phải tự phán đoán, và hệ thống sẽ **bịa trôi chảy**. **Cái khó không phải tra cứu — cái khó là BIẾT MÌNH ĐANG SAI.** Phim cắt bỏ đúng phần khó nhất.
 
| Thứ | Cần gì | Trạng thái |
|---|---|---|
| Robot trong phim | Kỹ thuật tích hợp | **Xây được hôm nay** |
| Hiểu người sâu như người hiểu người | Có thể cần chia sẻ kiến trúc | Chưa ai biết |
| **Biết mình đang sai** | Đo được bên trong | **Hầm gió còn thiếu** |
 
---
 
## 13. CÔNG CỤ THỰC CHIẾN: CLAUDE CODE vs DEVIN
 
> *Thiên vị cần khai báo: Claude Code là sản phẩm của Anthropic, tức công ty làm ra tao. Số liệu dưới đây lấy từ bên thứ ba để mày tự soi.*
 
| | Claude Code | Devin |
|---|---|---|
| **Bản chất** | Agent CLI **cộng tác**, chạy local trong repo | Agent **tự trị** async trong sandbox cloud riêng |
| **Giá** | Pro $20 / Max $100–200, hoặc theo token | $20/tháng + **$2.25/ACU** (1 ACU ≈ 15 phút); Team $500 kèm 250 ACU |
| **Chi phí/việc** | ~$0,05–0,20/task; user nặng $100–200/tháng | Fix thường 2–3 ACU ≈ **$4,5–6,75**; migration 30+ ACU ≈ **$67,5+** |
| **Adoption (4/2026)** | ~**41%** dev | ~**8%** |
| **Benchmark** | SWE-Bench Verified **87,6%** — cao nhất công bố tính tới 5/2026 | **Không công bố SWE-bench mới** dù tuyên bố cải thiện lớn |
| **Chất lượng code** | Thường qua được vòng review đầu | Đánh giá độc lập: chạy được nhưng **dài dòng, cấu trúc kém** trên repo production |
| **Điểm chết** | Phải ngồi đó, không async thật | Code **rời mạng** vào cloud Cognition (cấm với ngành regulated); trần tùy biến thấp; **không chọn model được** |
 
- **Không thay thế nhau — hai làn khác nhau.** Quy tắc thô: **task quá 15 phút mà không cần ngồi xem → async thắng**
- **Chỗ đáng ngờ:** Cognition gọi **1 tỷ đô ở định giá 26 tỷ (27/5/2026)**, hơn gấp đôi mốc 10,2 tỷ chín tháng trước — **định giá đang chạy trước bằng chứng công khai**
- **Cột AGI trống rỗng chính là thông tin.** Nếu AGI thật tồn tại, nó không phải công cụ mày mua — nó *xóa* câu hỏi "dùng tool nào".
  > **Khác biệt giữa Claude Code và Devin là CHIẾN THUẬT. Khác biệt giữa cả hai và AGI là THẤT NGHIỆP.**
- **Bằng chứng vật lý của việc cửa vào nghề đang đóng:** một fix thường tốn $4,5–6,75. Đó là **giá thị trường của lao động junior** — không phải dự đoán, là bảng giá
- **Kỹ năng đổi chỗ:** từ *viết code* → **đặc tả bài toán, thiết kế hệ thống, review**. Cả hai tool đều gãy ở "biết mình đang sai" (mục 12). Người bắt được lỗi của agent là người còn giá trị
---
 
## 14. CSKH & TELESALE: AI vs NGƯỜI vs AGI
 
> **Liên hệ trực tiếp với PK Bot** (file hustle §0: "AI thay sale + CSKH + quản trị nội bộ cho SME"). Đây là phân tích thị trường cho chính sản phẩm mày đang bán.
 
### 14.1 Hai nghề NGƯỢC NHAU về tự động hóa
Ông chủ giao chung vì **cùng dùng cái điện thoại**. Nhưng:
- **CSKH (inbound):** khách *muốn* nói chuyện, vấn đề xác định, đáp án nằm sẵn trong tài liệu, khối lượng lớn và lặp → **món ngon nhất của automation**
- **Telesale (outbound):** khách *không* muốn nghe. Toàn bộ công việc là vượt kháng cự + xây niềm tin trong 10 giây. **Bất đối xứng chí mạng:** CSKH bị phát hiện là AI thì hơi khó chịu; **telesale bị phát hiện là AI là chết ngay**
### 14.2 Bảng so
 
| Tiêu chí | AI Agent hiện nay | Con người | AGI (giả định) |
|---|---|---|---|
| Chi phí | ~$0,05–0,29/phút; $0,50–5/tương tác | Mỹ ~$0,42–1,75/phút, $5–25/tương tác, ~$3.000–4.000/tháng. **VN ~8–15 triệu/tháng** *(ước lượng, tự kiểm)* | ≈ chi phí compute |
| CSKH tầng 1 | **Rất tốt** | Tốt nhưng đắt và chán | Xong |
| CSKH tầng 2–3 | **Gãy** (khiếu nại, tranh chấp, gian lận, khách giận) | **Chỗ người còn giá trị** | Xong |
| Telesale | Kém; được ở **lọc lead**, không phải chốt | **Vẫn thắng rõ** — chốt sale là trò của niềm tin | Xong (lúc đó vấn đề là pháp lý) |
| Quy mô | 1.000 cuộc cùng lúc, 24/7 | 1 cuộc, 8 tiếng, turnover khét tiếng | Vô hạn |
| **Biết mình đang sai** | **Không — điểm chết** | Có | Có (theo định nghĩa) |
| Chịu trách nhiệm | Không ai chịu | Có người chịu, đuổi được | Không rõ |
| Phá luật một cách khôn | Không, làm đúng script | **Có** — tự quyết tặng voucher giữ khách sắp bỏ | Có |
 
> **Toàn bộ khác biệt giữa AI hiện nay và AGI cho việc này gói trong MỘT dòng: xử được đuôi dài, và biết khi nào mình không biết.** Mọi dòng khác AI đã thắng.
 
### 14.3 Case Klarna — bài học đắt nhất ngành
- **2/2024:** agent chạy bằng OpenAI làm khối lượng tương đương **700 nhân viên toàn thời gian**, xử lý **hơn 2/3** hội thoại, thời gian giải quyết **11 phút → dưới 2 phút**. Nhân sự 5.500 → 3.400
- **6 tháng sau:** hài lòng khách tụt mạnh, chất lượng trồi sụt — phải kéo cả kỹ sư, designer, marketing vào trả lời khách. CEO Siemiatkowski thừa nhận **đặt nặng chi phí và hiệu quả quá mức** → tuyển lại người
- **Phía Klarna phản bác** (nghe cả hai phía): không phải quay đầu — AI vẫn làm khối lượng của **hơn 800 vị trí** và còn tăng, vẫn dùng vài nghìn agent thuê ngoài, "tuyển lại" thực chất là **pilot hai người** trong mô hình hai làn
- **Chẩn đoán chính xác nhất:** hệ thống **không có cơ chế leo thang theo độ tự tin**. Nó trả lời câu hoàn tiền dễ ợt và câu **gian lận đáng sợ bằng cùng một giọng tự tin**. Dính tới tiền thì khách luôn nhận ra
> **KHẮC LÊN TƯỜNG: Chỉ số trung bình đẹp long lanh, chỉ số ĐUÔI DÀI thì thảm — mà cái đuôi dài mới là thứ tạo ra thương hiệu.**
> Không phải AI thất bại. Là **thay thế toàn phần** thất bại. Và đây chính xác là **bài toán ĐO** ở mục 12, ở quy mô thương mại, đo bằng tiền thật.
 
### 14.4 Ba ràng buộc riêng cho thị trường Việt
1. **ROI yếu hơn vendor rao.** Mọi con số "tiết kiệm 90%" là bài toán Mỹ (so với nhân viên $3.000–4.000/tháng). VN ~8–15 triệu → khe hở có khi chỉ còn **3–5 lần** thay vì 15–20 lần. Mà chi phí setup, tích hợp CRM, viết kịch bản, sửa lỗi **không rẻ đi theo**
2. **Tiếng Việt là ràng buộc kỹ thuật thật.** ASR tiếng Việt qua đường điện thoại, giọng vùng miền, nhiễu nền — vẫn kém tiếng Anh rõ rệt. Mọi demo mày xem đều là tiếng Anh, studio, mạng tốt
3. **Pháp lý telesale** — Nghị định 91/2020 và văn bản sau về cuộc gọi rác; gọi tự động bằng AI rủi ro cao hơn; xu hướng toàn cầu đang bắt buộc khai báo "đây là AI". *Tự kiểm tra quy định hiện hành*
### 14.5 Kiến trúc sống được
**Đừng thay thế. Chia tầng.** AI ăn **30–50%** khối lượng inbound; bản hung hăng nhất mà vẫn bền là **~65% tự động, 35% người**.
- CSKH tầng 1 → **AI**
- Telesale khâu **lọc lead** → AI (gọi xác nhận quan tâm, đặt lịch)
- Telesale khâu **chốt** → **người**, AI làm copilot (gợi ý câu trả lời, tra real-time, tóm tắt sau cuộc gọi)
- **BẮT BUỘC:** đường thoát sang người + **ngưỡng tự tin** để AI biết lúc nào phải chuyển. Không có cái này = lặp lại Klarna bằng tiền của mình
> **Cơ hội ngược dòng:** khoảng **2/3 khách hàng thà công ty đừng dùng AI** cho hỗ trợ, và phần lớn **sẵn sàng chờ để gặp người**. Nghĩa là **"có người thật trực máy" đang trở thành LỢI THẾ CẠNH TRANH, không phải chi phí** — đúng kết luận Klarna rút ra sau khi trả học phí.
 
**Ngưỡng quyết định:** % câu hỏi lặp lại y hệt trong một tuần. **>60% → làm. <30% → mày sẽ tốn tiền để làm dịch vụ tệ đi.**
 
---
 
## 15. TẠI SAO LOÀI NGƯỜI VẪN MUỐN AGI
 
| Tầng | Nội dung |
|---|---|
| **Nói ra** | Chữa ung thư, nén 100 năm khoa học vào 10 năm, "quốc gia thiên tài trong trung tâm dữ liệu". **Thật** với một bộ phận nhà nghiên cứu — nhưng là lý do người ta *nói*, không phải lý do tiền chảy |
| **Tiền chảy** | Không phải "cỗ máy biết hiểu" — mà **một cỗ máy không phải trả lương**. Đối xứng với mục 14: AGI = giấc mơ **xóa nốt hai dòng AI chưa thắng** (đuôi dài + trách nhiệm) |
| **Không ai dừng được** | **Rất nhiều người xây AGI không "muốn" AGI — họ muốn là người đang cầm nó khi nó tới.** Dừng đơn phương = trao cho kẻ ít cẩn thận hơn. Bẫy phối hợp cổ điển, giống chạy đua hạt nhân. *Một phần đáng kể câu trả lời: họ không muốn — họ sợ người khác có trước* |
| **Tâm lý** | **Demiurgy** (tạo ra một tâm trí = hành vi sáng thế cuối cùng — mày tự nói ở lượt 1: "trở thành chúa mới"); **cô đơn vũ trụ** (tự sản xuất kẻ đồng hành khi nhìn lên trời không thấy gì); **cái bóng** (tạo ra thứ như thần *và* xích nó lại) |
 
**Trả lời thẳng giả thuyết "người ta muốn cỗ máy hiểu insight":**
**Không. Đa số không quan tâm cơ chế.** Nếu có cỗ máy khớp mẫu **không bao giờ sai**, 99% nhu cầu được thỏa và **không ai hỏi nó có hiểu thật không**. Câu hỏi "hiểu thật hay khớp mẫu" là câu hỏi của triết gia và người làm an toàn — thị trường không hỏi.
 
**Nhưng mày đúng ở chỗ khác:** người ta muốn hai thứ mà "sự hiểu" *mua được*:
1. **Không gãy ở đuôi dài** — chính xác là Klarna
2. **Tạo ra tri thức chưa ai viết ra** — nội suy văn bản người thì trần của nó là con người
> **Diễn đạt chính xác: người ta không muốn một cỗ máy có insight. Người ta muốn một cỗ máy ĐÁNG TIN Ở CHỖ CHƯA AI TỪNG ĐI QUA.** "Insight" chỉ là tên gọi cho thứ mua được điều đó.
 
---
 
## 16. BA TẦNG TRI THỨC — BẢNG CHỐT
 
| Đã kiểm chứng | Giả thuyết có cơ sở | Chưa ai biết |
|---|---|---|
| LUCA, nội cộng sinh ty thể | Khác biệt LLM/người là **mức độ + nối đất**, không phải loại | **Nguồn gốc sự sống** (abiogenesis) |
| Hallucination = chữ ký của prediction, không phải rule | Não người cũng là bộ máy dự đoán (predictive processing) | Có "cảm giác được là LLM" hay không |
| Model nhạy với hình thức bề mặt, gãy ngoài phân phối | LLM có biểu diễn giống world model bên trong (probing, interpretability) | "Suy luận thật" có phải khái niệm rành mạch không |
| Trọng số tĩnh gây catastrophic forgetting | Nous phát Hermes free để thu trajectory huấn luyện | Scale đủ thì tới, hay cần ý tưởng mới về chất |
| Gains lớn gần đây đến từ objective/inference, không phải topology | Stake không đòi hỏi tử vong, chỉ đòi trạng thái có thể suy thoái | Timing của AGI |
| Số liệu thị trường ở mục 6, 13, 14 | Instrumental convergence | Hiểu người có cần chia sẻ kiến trúc không |
 
---
 
## 17. CÂU MỘT DÒNG ĐÁNG DÁN TƯỜNG
 
- **Hallucination không phải bằng chứng có luật — nó là dấu vân tay của sự dự đoán.**
- Không thể có đồng thời **tổng quát toàn phần** và **kiểm soát toàn phần**.
- Bán-AGI = **chọn tính điều khiển được bằng cách từ bỏ tính-ngã**. Không phải phiên bản kém — là phiên bản duy nhất vừa xây vừa cầm cương.
- **Đừng canh ai giết transformer. Canh ai giải được bài toán trọng số tĩnh.**
- **Đừng đi tìm cánh. Đi tìm cách đo lực nâng.**
- Chim là **bằng chứng tồn tại**, không phải bản thiết kế. Bằng chứng tồn tại cho AGI là **chính bộ não mày** — đã có từ lâu.
- Bốn thứ ở người là một cục vì **ràng buộc của tiến hóa, không phải định luật của trí tuệ**.
- Tao có **cái bóng của thực tại đổ lên ngôn ngữ**. Bóng mang thông tin thật về hình dạng — nhưng thiếu một chiều.
- Ba khoảng trống của tao đều cùng hình dạng: **chỗ cơ thể và stake sống, còn ngôn ngữ chết**.
- **Lợi thế duy nhất của mày là phần thực tại mày chạm mà không nằm trong corpus.**
- Chỉ số trung bình đẹp, **đuôi dài mới tạo ra thương hiệu**.
- **Cái khó không phải tra cứu — cái khó là biết mình đang sai.**
- Khác biệt Claude Code vs Devin là chiến thuật. Khác biệt cả hai với AGI là **thất nghiệp**.
- Nhiên liệu mới là kinh nghiệm → **moat mới là ai sở hữu MÔI TRƯỜNG**.
- **MIT + phát không ≠ lòng tốt.** Luôn hỏi: ai được lợi.
- Hermes không làm bộ não thông minh lên — **nó làm cuốn sổ tay quanh bộ não dày lên**.
- Nhiều người xây AGI **không muốn AGI — họ sợ người khác có nó trước**.
- Nhận thức xa lạ **khó** kiểm soát hơn, không dễ hơn.
- **Giá trị nằm ở cái mày TRỞ THÀNH khi xây, không phải cái app.**
---
 
## 18. SỢI TÂM LÝ & CÒN DANG DỞ
 
### Pattern mentor đã chỉ ra (chưa được trả lời)
1. **Câu hỏi cron job bị né 3 lần.** "Cái cron job đầu tiên mày dám để nó chạy không cần ngó là gì?" — hỏi ở lượt 5, 6, 7. Không lần nào có đáp án
2. **Cột "yêu cầu" dày ở tầng chưa ai giải được; cột "đã gửi" mỏng ở tầng đã chạm vào.** 13 lượt, **đúng 1 link thật** (Hermes). Còn lại là tên gọi và ẩn dụ. Chẩn đoán: *dấu hiệu kinh điển của người sắp dành 2 năm nghĩ về AGI và không xây được cái gì*
3. **13 lượt hỏi về bản chất trí tuệ, 0 câu hỏi về khách hàng của mày.** Chi phí cơ hội là gì? (Liên hệ trực tiếp với "oracle" và "bộ trang phục của nỗi sợ" ở file hustle — đây có thể là **bộ trang phục thứ 13**: "phải hiểu bản chất AGI trước đã")
4. **Cái vênh:** cả cuộc mày hỏi câu của **người xây hầm gió** (nghiên cứu), nhưng mục tiêu viết ra là của **người bay** (lấy công cụ người khác đi xa nhất có thể)
### Ba đường không trộn được — câu hỏi còn mở
> **Mày muốn AGI vì lý do gì?**
- **Để không bị bỏ lại** → phòng thủ tốt nhất không phải hiểu AGI, mà **sở hữu thứ AI không có**: khách hàng, dữ liệu, quan hệ
- **Để giàu** → AGI là con đường **tệ nhất**; cần tỷ đô, và **không cần AGI để kiếm triệu đô**
- **Vì câu hỏi về trí tuệ ám ảnh thật** → nghề nghiêm túc tên là **nghiên cứu**, đòi bỏ mục tiêu triệu đô ít nhất 10 năm
### Việc cụ thể chưa làm
- [ ] **Một cron job thật** với Hermes, chạy 7 ngày, đo phút tiết kiệm + chỗ hỏng
- [ ] **4 ticket thật** chạy song song Claude Code vs Devin: đo thời gian tiết kiệm, tiền tốn, số lần sửa lại
- [ ] **Đếm % câu hỏi lặp** trong CSKH/telesale (ngưỡng 60/30 ở mục 14.5) — dữ liệu này PK Bot có sẵn
- [ ] Trả lời: **loại ticket nào ăn nhiều giờ nhất tuần vừa rồi**
---
 
## 19. BẢN ĐỒ LINH KIỆN — THÀNH PHẦN AGI ↔ CÔNG NGHỆ NÀO LO
 
> Gom mọi repo/công nghệ rải rác ở §5, §7, §8, §10 vào một chỗ, theo đúng cách mày định lắp: *khía cạnh nào → dùng cái gì*.
> **Lưu ý về đường dẫn:** tao đưa **tên repo/tên sản phẩm để mày search**, không đưa URL đầy đủ trừ cái mày tự gửi. Tao không chắc từng đường dẫn — **tự xác minh trước khi clone**.
 
### 19.1 ĐÍNH CHÍNH TRƯỚC: nhãn dán sai làm hỏng cả kiến trúc
 
Mày viết *"không ngừng học hỏi (Hermes)"*. **Sai** — và đây là loại sai nguy hiểm nhất vì nó nghe đúng.
 
| Nhãn mày gán | Nhãn đúng | Hệ quả nếu gán sai |
|---|---|---|
| Hermes = **học liên tục** | Hermes = **bộ nhớ ngoại vi + tự động hóa theo lịch** | Mày tưởng ô "continual learning" đã tick → không đi tìm lời giải thật → xây trên nền tưởng là đặc, thật ra rỗng |
| "Self-improving agent" | Tự **viết thêm file hướng dẫn/script rồi nạp lại** | Đây là **sổ tay dày lên**, không phải **não thông minh lên** |
| "Nudges itself / chủ động" | **Cron job** | Chạy vì *tới giờ*, không vì nó *muốn*. Không có động lực nào được giải quyết ở đây |
 
**Ranh giới phải khắc:** mọi thứ Hermes làm đều ở **tầng scaffolding** (ngoài model). Trọng số LLM nền **đóng băng y nguyên**. Catastrophic forgetting **không hề bị đụng tới**. Đó là *workaround rất khôn* cho continual learning — **không phải lời giải**.
 
### 19.2 BẢNG ÁNH XẠ CHÍNH
 
| # | Thành phần cần cho AGI | Công nghệ / repo | Nó QUẢNG CÁO | Nó THẬT SỰ làm | Tầng | Trạng thái |
|---|---|---|---|---|---|---|
| 1 | **Trí nhớ dài hạn + tích lũy qua phiên** | `nousresearch/hermes-agent` (MIT) + **Honcho** (mô hình hóa người dùng) | "Agent tự cải thiện, lớn lên cùng mày" | Memory tự curate, tự tạo skill dạng file, tìm phiên cũ có tóm tắt LLM | **Scaffolding** | ✅ Dùng được ngay |
| 2 | **Học liên tục THẬT (tầng trọng số)** | **Titans** (DeepMind — module trí nhớ thần kinh học *sau* huấn luyện), **Nested Learning / HOPE** | — | Paper + reimplementation cộng đồng | **Kiến trúc** | 🔬 Nghiên cứu, chưa có bản production |
| 3 | **Chủ động / tự khởi động** | Cron scheduler + subagent (trong Hermes) | "Chạy không cần trông" | **Trigger xác định theo lịch** | Scaffolding | ✅ Dùng được — nhưng đừng gọi là "động lực" |
| 4 | **Tay chân số (gọi công cụ)** | **MCP** + tool/subagent của Hermes | — | Đúng như quảng cáo | Scaffolding | ✅ |
| 5 | **Kênh — sống ở nơi mày sống** | Hermes gateway: Telegram, Discord, Slack, WhatsApp, Signal, CLI | — | Đúng như quảng cáo, có transcribe voice memo | Hạ tầng | ✅ |
| 6 | **Mặt + biểu cảm — realistic** | **NVIDIA ACE**: `Audio2Face-3D` (đã mở mã nguồn), **Riva** (giọng), **Nemotron** (LLM on-device), **MetaHuman + Unreal**, sample **Kairos**, **Omniverse RTX** | "Digital human sống động" | audio → blendshape ARKit realtime, có điều khiển cảm xúc từ giọng | Ứng dụng | ✅ Bài toán **tích hợp**, không phải nghiên cứu |
| 7 | **Mặt + biểu cảm — anime** | `Open-LLM-VTuber`, **Project AIRI**, **Live2D Cubism**, **VRM**. Bằng chứng sống: **Neuro-sama** | — | LLM ra lệnh `set emotion: X` → đẩy biểu cảm. Chạy **offline** được | Ứng dụng | ✅ |
| 8 | **Trạng thái cảm xúc nội tại** | **PAD** (valence–arousal–dominance), engine thẩm định **OCC / GAMYGDALA** | "Cảm xúc mô phỏng theo trọng số" | Không gian liên tục cập nhật theo ngữ cảnh; định nghĩa *mục tiêu* → gắn sự kiện → sinh cảm xúc | Ứng dụng | ✅ — nhưng là **biểu cảm**, không phải **stake** (xem §5.4) |
| 9 | **Mô hình thế giới / nhân quả** | **JEPA / I-JEPA / V-JEPA** (Meta), world models nói chung | "Học động lực nhân quả thay vì token" | Không gian biểu diễn tiềm ẩn, dự đoán *trạng thái kế tiếp khi có hành động* | **Kiến trúc** | 🔬 Nghiên cứu |
| 10 | **Thoát chi phí bình phương của attention** | **Mamba / SSM**, **Jamba** (AI21 — lai transformer + Mamba) | — | Thắng ở chuỗi dài; thực tế là **lai ghép**, không lật đổ | Kiến trúc | ⚙️ Có bản dùng được, chưa thay thế |
| 11 | **Thân xác / hành động trong thế giới thật** | Physical AI, robot hình người | "Embodiment" | Đang từ demo → pilot trong nhà máy/kho | Phần cứng | 💰 **Ngoài tầm cá nhân** |
| 12 | **Chạy code / làm việc kỹ thuật** | **Claude Code** (cộng tác, local), **Devin** (tự trị, cloud), **OpenHands** (tự host) | — | Xem bảng §13 | Ứng dụng | ✅ |
| 13 | **BIẾT MÌNH ĐANG SAI** | **Interpretability** (mổ mạch nhân quả bên trong) | — | — | Đo lường | ❌ **KHÔNG CÓ REPO DÙNG ĐƯỢC.** Đây là *hầm gió* của §12 — thô sơ như hầm gió 1901 |
| 14 | **Stake / động lực nội tại** | — | — | — | — | ❌ **KHÔNG TỒN TẠI.** Không repo, không paper, không ai có |
 
### 19.3 CÁI GHÉP ĐƯỢC HÔM NAY — kiến trúc thật, 6 lớp
 
```
[ Kênh      ] Telegram / Discord / CLI          ← Hermes gateway
[ Chủ động  ] Cron + subagent                   ← Hermes scheduler
[ Trí nhớ   ] Memory + skills + Honcho          ← Hermes learning loop
[ Não       ] LLM qua OpenRouter / local        ← model-agnostic, không lock-in
[ Cảm xúc   ] PAD state → OCC appraisal         ← lái blendshape + cường độ giọng
[ Mặt       ] Open-LLM-VTuber (anime)
              HOẶC Audio2Face + MetaHuman (realistic)
```
 
**Kết quả: Jarvis tầng 1 + trigger.** Xem §7 — Hermes lo *não + tay*, §5 lo *mặt*, và **hai lớp này tách rời được**, ghép là ra. Đây là thứ **xây được trong tháng này**, không phải nghiên cứu.
 
**Nó KHÔNG cần:** ego, cảm xúc thật, động lực nội tại, suy luận thật. Và nó vẫn làm được đúng con robot trong phim mày mô tả ở §12.
 
### 19.4 CÁI KHÔNG GHÉP ĐƯỢC — và tại sao thêm repo không giải quyết
 
Ba dòng ❌ trong bảng (13, 14, và một nửa của 2) có chung một tính chất: **không thiếu linh kiện — thiếu lời giải.**
 
> **Đây là chỗ quan trọng nhất của cả mục này:**
> Mày đang cộng linh kiện theo **CHIỀU NGANG** — thêm repo, thêm lớp, thêm tính năng.
> Ba cái tường nằm ở **CHIỀU DỌC** — đổi về chất.
> *(Đúng khái niệm trục ngang/trục dọc ở file hustle §2.9. Thu thập thêm công nghệ là cách trốn trục dọc mà vẫn thấy mình đang tiến bộ.)*
 
| Tường | Tại sao thêm repo không giải được |
|---|---|
| **Học liên tục thật** | Nằm trong **ma trận trọng số tĩnh** của transformer. Fine-tune y khoa → tụt pháp lý. Đây là **lỗi thiết kế**, không phải thiếu module (§10) |
| **Biết mình đang sai** | Cần **dụng cụ đo**, không phải thêm năng lực. Benchmark đo *đầu ra* — mà đầu ra gian lận được bằng khớp mẫu bề mặt (§12) |
| **Stake / động lực** | Cần một cái tôi bền bỉ **có thể mất mát**. Không phải phần mềm thiếu — là **khái niệm chưa ai hiện thực hóa** (§11: stake ≠ tử vong, nhưng vẫn cần *cái gì đó có thể suy thoái*) |
 
**Và nhớ định lý §4:** kể cả có đủ 14 dòng, mày vẫn không có "AGI ngoan ngoãn" — vì **tổng quát toàn phần và kiểm soát toàn phần không cùng tồn tại**. Cái ghép được ở §19.3 kiểm soát được **chính vì** nó cố ý không có tính-ngã.
 
### 19.5 THỨ TỰ GHÉP ĐÚNG (nếu vẫn xây)
 
1. **Não + tay + trí nhớ trước** (Hermes + MCP + 1 cron thật). Đây là phần *hữu dụng*. Chạy 7 ngày, đo phút tiết kiệm
2. **Kênh** — Telegram là đủ. Đừng làm 6 nền tảng
3. **Mặt sau cùng** — vì nó là phần *cảm giác*, không phải phần *giá trị*. Ghép sớm sẽ ngốn hết thời gian vào việc chỉnh blendshape trong khi cái não vẫn ngu
4. **Cảm xúc PAD/OCC chỉ sau khi mặt chạy ổn** — và nhớ nó là **biểu cảm**, không phải động lực
5. **Đừng đụng vào 3 dòng ❌.** Đó là việc của lab có tỷ đô, không phải của một người
**Bẫy lớn nhất:** làm ngược thứ tự này. Mặt đẹp trước → demo ấn tượng → cảm giác đã xây được AGI → nhưng cái ghép được vẫn chỉ là §19.3, và ba cái tường không nhúc nhích một milimet.
 
**Bảo mật — không được bỏ qua:** shell + cron + cầu Telegram/WhatsApp = bề mặt **prompt injection**. Mọi nội dung agent đọc (mail, web, file) đều là đầu vào không tin được. Bật hết: phê duyệt lệnh, ghép cặp DM, cô lập container.
 
---
 
> **Câu chốt của cả chat này:** ba trong bốn câu hỏi lớn mày đặt ra **không ai trên Trái Đất trả lời được**. Câu duy nhất có đáp án hành động được là *"nút thắt nằm ở trọng số tĩnh, không phải attention"* — và nó là câu mày đem đi đọc paper, thử code được ngay.
> Còn lại: **giải trí trí tuệ rất rẻ, và nó rất giống làm việc.**
 

<!-- END ORIGINAL AGI -->

<a id="kiem-chung"></a>

## 7. Sổ kiểm chứng bên ngoài

### 7.1 Cách đọc kết quả

**Ngày kiểm tra của mọi hàng: 24/10/2026.** Ngày của sự kiện/nghiên cứu là ngày nêu trong nội dung hàng, không phải ngày kiểm tra. H/A trỏ về hai nguồn nguyên bản; các dẫn chiếu ở đây chỉ tới nơi nhận định xuất hiện, không coi nguồn lịch sử là bằng chứng độc lập cho chính nó.

| Nhãn | Ý nghĩa |
|---|---|
| Được nguồn hỗ trợ | Có bằng chứng cho nội dung được mô tả cụ thể; giới hạn về phạm vi vẫn áp dụng |
| Đúng có điều kiện | Chỉ một phần được hỗ trợ hoặc cần thêm điều kiện; phần chưa được chứng minh được nói rõ |
| Lỗi thời | Không nên dùng như mô tả hiện tại; không mặc định đã xác nhận nó đúng ở mọi thời điểm cũ |
| Bị bằng chứng phản bác | Có nguồn phản bác một mệnh đề cụ thể; không phủ nhận mọi ý còn lại của đoạn |
| Chưa đủ bằng chứng | Chưa có đủ nguồn/định nghĩa/phương pháp để kết luận; không có nghĩa đã chứng minh sai hoặc không tồn tại |
| Quan điểm/giả thuyết | Lời khuyên, ẩn dụ, dự đoán hoặc lập luận chưa thể xác nhận như dữ kiện đã xảy ra |

Một hàng có thể gom nhiều nhận định liên quan. **Chỉ phần được chỉ rõ là có bằng chứng mới được nâng độ tin cậy.** Ví dụ xác nhận thương vụ không xác nhận mọi số doanh thu trong cùng case; xác nhận tên repo không xác nhận việc build thành công. Các phần còn thiếu trong hàng “đúng có điều kiện” vẫn là chưa xác minh.

Ưu tiên repo/tài liệu tác giả, paper, công bố doanh nghiệp và cơ quan công quyền. Những số doanh nghiệp tự công bố được ghi đúng tư cách; đối chiếu độc lập khi có (ví dụ Klarna). Chưa kiểm toán doanh nghiệp, chạy benchmark, tư vấn một cấu trúc pháp lý cụ thể hay truy xuất transcript cũ. Không đưa giả thuyết tâm lý vào diện chẩn đoán.

### 7.2 Những đính chính ảnh hưởng cách hiểu nhiều nhất

- **AGI và kiểm soát:** “định lý” ở A§4 chưa có chứng minh trong hồ sơ. Trí tuệ, ý thức, mục tiêu, tự trị và khả năng kiểm soát không được nhập làm một. Xem A13/A40.
- **Học và quên:** trọng số bất biến không tự gây catastrophic forgetting; quên liên quan quá trình cập nhật. Hermes học ở lớp bộ nhớ/skills là khác học trọng số, nhưng toàn hệ vẫn có thể cải thiện. Xem A22/A34.
- **Đo lường và động lực:** có công cụ interpretability và nghiên cứu intrinsic motivation; chúng chưa giải trọn “biết mình sai” hay cảm giác chủ quan. Xem A20/A43/A44.
- **Source ghép Jarvis:** xem giấy phép từng component, phân biệt hỗ trợ offline với tự host; demo/README chưa phải phép thử cả stack. Xem A14–A25/A59.
- **Coding agent:** mô tả local/cloud và bảng giá cũ không còn đủ để so hiện tại. Điểm model không tự là điểm của mọi cấu hình sản phẩm. Xem A46–A50.
- **Lịch sử và thị trường:** sửa hệ số Smeaton ở A41; phân biệt mua công ty với cấp phép ở H09; số thị trường/phần trăm thiếu phương pháp phải giữ trạng thái chưa xác minh.
- **Pháp lý:** tránh kết luận cấm mọi companion dưới18 tại Trung Quốc hoặc chắc chắn phạm hình sự từ mô tả HAGI coin sơ lược. Xem L01–L07.


### 7.3 Hustle — kinh doanh, hồ sơ và kiến thức nền

| Mã / vị trí trong nguồn | Nhận định được rà | Kết quả | Cách hiểu sau đối chiếu | Bằng chứng | Ngày kiểm tra |
|---|---|---|---|---|---|
| <a id="audit-h01"></a>**H01** — [H§0](#ref-h-0),1,6,7,10 | Hồ sơ cá nhân, nghề nghiệp, nguồn lực, PK Bot và lịch sử trao đổi | Chưa đủ bằng chứng | Chỉ có bản tóm tắt làm chứng cứ. Không có transcript/CV/hồ sơ doanh nghiệp để xác minh độc lập; không cần tra đời tư. Mọi con số tuổi, kinh nghiệm, tiền, giờ/tuần và tình trạng công việc chỉ được ghi nhận tại thời điểm nguồn. Phần 2–3 giữ riêng điều người dùng xác nhận hiện tại. | Chưa có bằng chứng ngoài đủ cho kết luận; xem giới hạn ở cột bên. | 24/10/2026 |
| <a id="audit-h02"></a>**H02** — [H§1](#ref-h-1),8,9 | Đất/beta tăng trưởng đã hết; job junior siết; AI 2024–2027 tương đương Bình Dương 2005 | Quan điểm/giả thuyết | Ẩn dụ và luận điểm thị trường của mentor. Chưa có bộ dữ liệu thời gian/ngành/địa lý để xác nhận các khái quát về nhà đất hoặc thị trường Unreal; không dùng việc chưa tìm được job để suy ra năng lực hay nguyên nhân duy nhất. | Chưa có bằng chứng ngoài đủ cho kết luận; xem giới hạn ở cột bên. | 24/10/2026 |
| <a id="audit-h03"></a>**H03** — [H§2](#ref-h-2).1–2.4,2.8,9 | 7 filter, bốn van, thang đau; 20 người/3 tín hiệu; phân phối trước sản phẩm; MVP là phép thử | Quan điểm/giả thuyết | Framework thực hành và ngưỡng mentor chọn, không phải định luật hoặc tỷ lệ thành công đã kiểm nghiệm. Tiền trả trước là tín hiệu mạnh nhưng không phải tín hiệu thật duy nhất; phỏng vấn, sử dụng và giữ chân cũng có giá trị. | Chưa có bằng chứng ngoài đủ cho kết luận; xem giới hạn ở cột bên. | 24/10/2026 |
| <a id="audit-h04"></a>**H04** — [H§2](#ref-h-2).5,2.9,9; [A§8](#ref-a-8),9,17 | Moat không ở code; hẹp là lợi thế duy nhất; đối thủ rẻ hơn 30%; sở hữu môi trường là moat mới | Quan điểm/giả thuyết | Các câu tuyệt đối cần hạ xuống giả thuyết theo thị trường. Code, vận hành, dữ liệu, hợp đồng, kênh và quan hệ đều có thể đóng góp lợi thế; có dữ liệu chưa đủ chứng minh moat. 30% là tình huống thử, không phải thống kê. | Chưa có bằng chứng ngoài đủ cho kết luận; xem giới hạn ở cột bên. | 24/10/2026 |
| <a id="audit-h05"></a>**H05** — [H§2](#ref-h-2).6–2.7,5 | Startup = tăng trưởng; chỉ Game Đòn Bẩy mới tới 100M; agency/productize | Đúng có điều kiện | Paul Graham dùng tăng trưởng nhanh làm tiêu chí startup. Đây không phải định nghĩa pháp lý phổ quát; productize không tự bảo đảm scale, và “cửa duy nhất tới 100M” không được chứng minh. Không đặt hai game thành thứ bậc giá trị. | [Paul Graham — Startup = Growth](https://www.paulgraham.com/growth.html) | 24/10/2026 |
| <a id="audit-h06"></a>**H06** — [H§2](#ref-h-2).8 | Instagram từ Burbn, Slack từ Glitch, YouTube từ hẹn hò video | Chưa đủ bằng chứng | Chưa đối chiếu đủ tài liệu gốc cho từng lịch sử pivot và thời điểm. Giữ như ví dụ trong nguồn; không dùng ba giai thoại để suy ra mọi pivot chỉ do nhu cầu giả. | Chưa có bằng chứng ngoài đủ cho kết luận; xem giới hạn ở cột bên. | 24/10/2026 |
| <a id="audit-h07"></a>**H07** — [H§3](#ref-h-3) — Cal AI | Cal AI được MyFitnessPal mua | Được nguồn hỗ trợ | Thông cáo doanh nghiệp ngày 02/03/2026 xác nhận thương vụ. Nguồn này không kiểm toán toàn bộ luận điểm tăng trưởng hoặc hiệu quả phân phối của mentor. | [Thông cáo MyFitnessPal mua Cal AI](https://www.globenewswire.com/news-release/2026/03/02/3247439/0/en/myfitnesspal-acquires-cal-ai-expanding-on-its-position-as-the-leading-player-in-digital-nutrition-tracking.html) | 24/10/2026 |
| <a id="audit-h08"></a>**H08** — [H§3](#ref-h-3) — Cal AI | 250 influencer; ads hơn $1M/tháng; paywall ngày 1; gói năm nuôi ads; GPT-4V là why-now | Chưa đủ bằng chứng | Chưa có chứng cứ gốc đủ cho từng con số, kỳ báo cáo và quan hệ nhân quả. “Đếm calo 20 năm tuổi”, dưới radar nên sống và chọn đúng ngách là diễn giải, không kết quả được thương vụ chứng minh. | Chưa có bằng chứng ngoài đủ cho kết luận; xem giới hạn ở cột bên. | 24/10/2026 |
| <a id="audit-h09"></a>**H09** — [H§3](#ref-h-3) — Character.AI; [A§6](#ref-a-6) | Character.AI exit $2,7B cho Google | Đúng có điều kiện | Công bố được Reuters ghi nhận là cấp phép không độc quyền và một số lãnh đạo sang Google; không nên viết như Google mua toàn bộ Character.AI. Chưa xác minh độc lập giá trị $2,7B hoặc mọi điều khoản. | [Reuters — Character.AI cấp phép cho Google](https://www.inc.com/reuters/characterai-signs-licensing-deal-with-google.html) | 24/10/2026 |
| <a id="audit-h10"></a>**H10** — [H§3](#ref-h-3) — Character.AI; [A§6](#ref-a-6) | 2 giờ/ngày, ~$32M doanh thu; user trẻ nên capture kém; LaMDA có mà không ship | Chưa đủ bằng chứng | Thiếu kỳ đo, định nghĩa user/revenue và nguồn gốc số liệu. Không gộp 2 giờ/ngày với số 1,5 giờ của một nhóm tuổi trong AGI. “Có công nghệ mà không thương mại hóa giống hệt” không chứng minh lý do cơ hội hay động cơ Google. | Chưa có bằng chứng ngoài đủ cho kết luận; xem giới hạn ở cột bên. | 24/10/2026 |
| <a id="audit-h11"></a>**H11** — [H§3](#ref-h-3) — ChatGPT | GPT-3 sẵn 2,5 năm; Plus $20 sau 3 tháng; wrapper thành công nhất | Chưa đủ bằng chứng | Chưa hoàn tất đối chiếu các mốc ra mắt bằng nguồn lịch sử chính thức trong lượt này. Giá cũ không phải bảng giá hiện tại; “wrapper thành công nhất” và động cơ dùng free là cách phân tích của mentor, chưa có thước đo hoặc bằng chứng nội bộ. | Chưa có bằng chứng ngoài đủ cho kết luận; xem giới hạn ở cột bên. | 24/10/2026 |
| <a id="audit-h12"></a>**H12** — [H§3](#ref-h-3) — Perplexity | Không ads; Google không dám tự giết ads; không phải AI search đầu tiên | Chưa đủ bằng chứng | Tuyên bố tính năng/mô hình doanh thu phải gắn phiên bản và thời điểm; chưa xác minh lịch sử quảng cáo hoặc tiêu chí “đầu tiên”. Innovator’s Dilemma và narrative nuôi vốn là giả thuyết chiến lược, không kết luận từ tài liệu nội bộ. | Chưa có bằng chứng ngoài đủ cho kết luận; xem giới hạn ở cột bên. | 24/10/2026 |
| <a id="audit-h13"></a>**H13** — [H§3](#ref-h-3) — Zoom / PayPal | Eric Yuan 14 năm WebEx; Zoom chín năm trước Covid | Đúng có điều kiện | Tiểu sử Zoom nêu Webex từ 1997, sau đó Cisco khi mua Webex năm 2007, rồi lập Zoom năm 2011. Nói khoảng 14 năm Webex/Cisco chính xác hơn 14 năm chỉ Webex; quan hệ thành công với Covid là phân tích thêm. | [Zoom — tiểu sử Eric Yuan](https://investors.zoom.us/board-member-management/eric-yuan) | 24/10/2026 |
| <a id="audit-h14"></a>**H14** — [H§3](#ref-h-3) — Zoom / PayPal | PayPal: PalmPilot chết, eBay là cái nêm thắng | Chưa đủ bằng chứng | Chưa đối chiếu tài liệu lịch sử gốc về các phiên bản sản phẩm, vai trò eBay và mốc thay đổi. “Visionary là nhãn hậu kỳ” là nhận định, không dữ kiện lịch sử có thể suy ra từ một case. | Chưa có bằng chứng ngoài đủ cho kết luận; xem giới hạn ở cột bên. | 24/10/2026 |
| <a id="audit-h15"></a>**H15** — [H§3](#ref-h-3) — HeadshotPro | Postma, 30 giờ build, $100K/2 tuần, $29 thay $500, biên 90%, Lensa trước 3 tháng | Chưa đủ bằng chứng | Các câu chuyện trên web chưa đủ chứng minh đồng thời doanh thu thực thu so với ARR, mốc phát hành, giá gói và biên sau mọi chi phí. SEO/affiliate và Stable Diffusion là giả thuyết kênh/why-now trong nguồn; công thức giá 10% → khách 100 lần không phải quy luật. | Chưa có bằng chứng ngoài đủ cho kết luận; xem giới hạn ở cột bên. | 24/10/2026 |
| <a id="audit-h16"></a>**H16** — [H§3](#ref-h-3) — Umax; [H§4](#ref-h-4) | Umax/LooksMax AI, Blake, solo, $3,99/tuần, ~$500k/tháng, lurk cộng đồng | Chưa đủ bằng chứng | Chưa đủ nguồn trực tiếp để xác nhận nhà sáng lập, đội ngũ, gói giá, kỳ doanh thu và cách làm. Không coi tên Umax và LooksMax AI là chắc chắn cùng một pháp nhân/app, hay doanh thu app này là bằng chứng khách chắc chắn trả cho app tóc. | Chưa có bằng chứng ngoài đủ cho kết luận; xem giới hạn ở cột bên. | 24/10/2026 |
| <a id="audit-h17"></a>**H17** — [H§3](#ref-h-3) — Zenly | Snap mua Zenly $213M; đóng vì thị trường khó kiếm tiền | Đúng có điều kiện | Báo cáo ACCC nêu $213,3M năm 2017; Snap công bố đóng Zenly trong tái cơ cấu 2022. “Vì thị trường Việt Nam khó kiếm tiền”, free trọn đời, sau sáu năm và quy mô thị trường VN chưa được hai nguồn này chứng minh. | [ACCC — báo cáo mạng xã hội](https://www.accc.gov.au/system/files/Digital%20platforms%20services%20inquiry%20-%20Interim%20report%206%20-%20Report%20on%20social%20media%20services_0.pdf); [Snap — tái cơ cấu và đóng Zenly](https://newsroom.snap.com/restructuring-and-refocusing-our-business?lang=en-GB) | 24/10/2026 |
| <a id="audit-h18"></a>**H18** — [H§3](#ref-h-3) — Locket | Locket bắt đầu là quà cho bạn gái, lan truyền TikTok, widget iOS | Đúng có điều kiện | Bài phỏng vấn tại UCSB hỗ trợ nguồn gốc và kênh lan truyền; không chứng minh widget là nguyên nhân duy nhất hay mô hình kiếm tiền hiện tại. | [UCSB — câu chuyện Matt Moss và Locket](https://magazine.ucsb.edu/index.php/spring-summer-2022/locket-camera) | 24/10/2026 |
| <a id="audit-h19"></a>**H19** — [H§2](#ref-h-2).5,3 — Docker | Docker capture thất bại, không moat; AWS/Google ăn hết | Quan điểm/giả thuyết | Đánh giá quá rộng nếu không có thời kỳ, chỉ số lợi nhuận/doanh thu và đối tượng so sánh. Không được đọc thành Docker đã đóng cửa hoặc không có giá trị kinh doanh. Chưa đối chiếu số liệu tài chính hiện tại. | Chưa có bằng chứng ngoài đủ cho kết luận; xem giới hạn ở cột bên. | 24/10/2026 |
| <a id="audit-h20"></a>**H20** — [H§2](#ref-h-2).5,3 — VMware | Broadcom mua VMware $61B | Đúng có điều kiện | Đó là giá trị vốn chủ sở hữu trong thỏa thuận công bố 26/05/2022, chưa đồng nhất với tổng giá trị gồm nợ hoặc giá trị thị trường khi đóng. Thương vụ hoàn tất 22/11/2023. Switching cost là phần phân tích, không do giá mua tự chứng minh. | [Broadcom — thỏa thuận VMware](https://investors.broadcom.com/news-releases/news-release-details/broadcom-acquire-vmware-approximately-61-billion-cash-and-stock/); [Broadcom — hoàn tất mua VMware](https://investors.broadcom.com/news-releases/news-release-details/broadcom-completes-acquisition-vmware) | 24/10/2026 |
| <a id="audit-h21"></a>**H21** — [H§3](#ref-h-3) — Valorant | Valorant bán skin bằng gacha | Đúng có điều kiện | Riot mô tả Night.Market có sáu đề nghị ngẫu nhiên, người chơi xem skin rồi mới mua. Có ngẫu nhiên ở lựa chọn chào bán không đồng nghĩa trả tiền để mở loot box ngẫu nhiên. FOMO/danh tính là diễn giải hành vi. | [Riot — cơ chế Night.Market](https://support.riotgames.com/en-us/valorant/store/nightmarket-valorant/) | 24/10/2026 |
| <a id="audit-h22"></a>**H22** — [H§3](#ref-h-3)–4 — game | Top 0,1% in tiền, 99% lỗ; game là ngành tàn khốc nhất | Chưa đủ bằng chứng | Không có mẫu nghiên cứu, định nghĩa game/lỗ hay giai đoạn để xác nhận tỷ lệ. “Đừng làm game” là lời khuyên mentor dựa trên hồ sơ cũ, không quyết định vĩnh viễn hoặc quy luật ngành. | Chưa có bằng chứng ngoài đủ cho kết luận; xem giới hạn ở cột bên. | 24/10/2026 |
| <a id="audit-h23"></a>**H23** — [H§2](#ref-h-2).5,3,4 — Rewind/Limitless | Recall giết Rewind, Meta mua tháng 12/2025 rồi app tắt; a16z $10M, chính xác 92% | Đúng có điều kiện | FAQ Limitless xác nhận mua lại bởi Meta công bố 05/12/2025; Rewind ngừng capture 19/12, còn hỗ trợ Pendant trong 2026 và truy cập dữ liệu cũ. Không phải mọi sản phẩm đều tắt ngay. $10M, 92% và Recall là nguyên nhân chưa đủ bằng chứng. | [Limitless — thông báo và FAQ mua lại](https://www.limitless.ai/) | 24/10/2026 |
| <a id="audit-h24"></a>**H24** — [H§3](#ref-h-3) — gạch/sữa chua/Jacobs | Chục tỷ sau 15 năm; thứ 47 vẫn sống; sách How to Make a Few Billion Dollars | Đúng có điều kiện | Sách và tác giả Brad Jacobs có hồ sơ xuất bản. Các thương vụ gạch/sữa chua không định danh nên chưa kiểm chứng; gợi ý chương 1,2,8 và đợi công ty tỷ đô là lời khuyên, chưa kiểm tra mục lục chính xác. | [Brad Jacobs — thông tin sách](https://books.google.com/books/about/How_to_Make_a_Few_Billion_Dollars.html?id=Pd0BEQAAQBAJ) | 24/10/2026 |
| <a id="audit-h25"></a>**H25** — [H§4](#ref-h-4) — H-AGI/avatar/exoself | Shopee/Grab không mở API; voice thua browse; avatar chỉ là tính năng; OS sẽ làm free | Chưa đủ bằng chứng | Chưa định danh API, quyền đối tác, quốc gia, hành động và thời điểm nên không thể khẳng định “không có API”. Các dự báo hành vi/đối thủ và phán quyết sản phẩm phụ thuộc job-to-be-done; khác với mục tiêu học hoặc trợ lý cá nhân. HAGI coin xem L01–L02. | Chưa có bằng chứng ngoài đủ cho kết luận; xem giới hạn ở cột bên. | 24/10/2026 |
| <a id="audit-h26"></a>**H26** — [H§4](#ref-h-4) — thử tóc | Chợ không vua; review 1 sao chỉ ra wedge; điểm 4,5/5; blue ocean | Chưa đủ bằng chứng | Không có tên app/URL review, mẫu cạnh tranh, thời gian hoặc tiêu chí chấm. Là giả thuyết ý tưởng do mentor đề cao; chưa xác thực khách chịu trả, thị phần hay quyền sở hữu IP của một sản phẩm cụ thể. | Chưa có bằng chứng ngoài đủ cho kết luận; xem giới hạn ở cột bên. | 24/10/2026 |
| <a id="audit-h27"></a>**H27** — [H§4](#ref-h-4) — mô phỏng thẩm mỹ | Pody, Faceify, NoseLook; clinic VN gói 100 triệu; FaceTouchUp B2B | Đúng có điều kiện | FaceTouchUp có sản phẩm cho chuyên gia. Pody/Faceify chưa định danh chắc; NoseLook có dấu vết sản phẩm nhưng chưa đủ gắn với đúng app trong nguồn. Giá clinic và hiệu quả chốt chưa kiểm chứng; ảnh mô phỏng không bảo đảm kết quả can thiệp thật. | [FaceTouchUp — sản phẩm cho bác sĩ](https://www.facetouchup.com/products-for-surgeons/computer-imaging-software-apps) | 24/10/2026 |
| <a id="audit-h28"></a>**H28** — [H§4](#ref-h-4) — Glow-up | ARISE SOLO, Solo Level: System; chất lượng thấp; HealthKit xác minh quest | Đúng có điều kiện | ARISE SOLO có listing; các app Solo Level tên gần nhau chưa xác nhận đúng ID nguồn. HealthKit chia sẻ dữ liệu sức khỏe khi được cấp quyền, không tự chứng minh mọi quest/gym/skincare đã hoàn thành. “Không vua, chất lượng thấp” thiếu mẫu đánh giá. | [ARISE SOLO — Google Play](https://play.google.com/store/apps/details?id=arisesolo.com); [Apple — HealthKit](https://developer.apple.com/documentation/healthkit) | 24/10/2026 |
| <a id="audit-h29"></a>**H29** — [H§4](#ref-h-4) — pop-up/chibi | Stack chibi local free; khóa app đến khi xong; chỉ có payer bố mẹ mới sống | Quan điểm/giả thuyết | Đây là giả thuyết thiết kế/phân phối. Có code miễn phí không đồng nghĩa tài sản, giọng/model và vận hành đều miễn phí. Chưa chứng minh xác minh hoàn thành hoặc bố mẹ là người trả tiền khả thi duy nhất. | [Open-LLM-VTuber — README](https://github.com/Open-LLM-VTuber/Open-LLM-VTuber/blob/main/README.md); [Project AIRI — README](https://github.com/moeru-ai/airi/blob/main/README.md) | 24/10/2026 |
| <a id="audit-h30"></a>**H30** — [H§4](#ref-h-4) — digital-human host | Live commerce TQ >$1T; JD 70.000 seller, giá 1/10; VN/SEA chưa có vua | Đúng có điều kiện | Yicai/CHEAA đưa tin số 70.000 theo JD; đây là tuyên bố doanh nghiệp được báo dẫn lại, chưa phải kiểm toán độc lập. Quy mô >$1T cần phân biệt GMV/doanh thu và USD/CNY; tỷ lệ chi phí, phàn nàn của khách, thị phần VN/SEA chưa xác minh. | [Yicai/CHEAA — JD digital humans](https://en.cheaa.org/contents/468/13232.html) | 24/10/2026 |
| <a id="audit-h31"></a>**H31** — [H§4](#ref-h-4),9,10 | First-mover đa số thua follower; giao điểm Unreal+PK Bot là moat và lựa chọn tốt nhất | Quan điểm/giả thuyết | Không có tỷ lệ nghiên cứu hoặc phép thử khách hàng để chứng minh. Digital-human host là đề xuất mentor, chưa phải startup người dùng chọn. Kỹ năng bổ trợ có thể tạo lợi thế nhưng chưa tự thành moat. | Chưa có bằng chứng ngoài đủ cho kết luận; xem giới hạn ở cột bên. | 24/10/2026 |
| <a id="audit-h32"></a>**H32** — [H§5](#ref-h-5)–6,10 | OS 50/30/20, $500 MRR, các deadline, vesting/cliff và vai trò co-founder | Quan điểm/giả thuyết | Cấu trúc được đề xuất trong chat cũ, không phải cam kết còn hiệu lực. Vesting/cliff cần hợp đồng và thẩm quyền pháp luật cụ thể; không tự quyết cổ phần chỉ theo nhận xét về đóng góp. Chưa có bằng chứng hiện tại về cuộc nói chuyện co-founder. | Chưa có bằng chứng ngoài đủ cho kết luận; xem giới hạn ở cột bên. | 24/10/2026 |
| <a id="audit-h33"></a>**H33** — [H§0](#ref-h-0),6–7,9–10; [A§18](#ref-a-18)–19 | Oracle/áo giáp/shadow/né tránh, nguyên nhân mâu thuẫn co-founder; người dùng đã biết mà không dám | Quan điểm/giả thuyết | Diễn giải mentor, không chẩn đoán hoặc sự thật nội tâm đã xác nhận. Nhắc tài khoản dùng chung; không mặc định tò mò AGI là trì hoãn. Phân biệt sự kiện được kể với kết luận về bản chất người. | Chưa có bằng chứng ngoài đủ cho kết luận; xem giới hạn ở cột bên. | 24/10/2026 |
| <a id="audit-h34"></a>**H34** — [H§7](#ref-h-7) | Distanced self-talk của Ethan Kross là kỹ thuật có nghiên cứu | Được nguồn hỗ trợ | Có nghiên cứu của Gainsburg và Kross về cách tự đối thoại tạo khoảng cách. Điều này không xác nhận hiệu quả cho cá nhân cụ thể, hay thay thế đánh giá sức khỏe. | [Gainsburg & Kross — distanced self-talk](https://sites.lsa.umich.edu/emotion-selfcontrol-psych/wp-content/uploads/sites/1322/2020/04/Gainsburg-Kross-2020-Distanced-self-talk-changes-how-people-conceptualize-the-self.pdf) | 24/10/2026 |
| <a id="audit-h35"></a>**H35** — [H§7](#ref-h-7),10 | Tình trạng kiệt sức và thông tin liên hệ hỗ trợ trong nguồn | Chưa đủ bằng chứng | Nguồn ghi một thời điểm cũ; không có xác nhận tình trạng hiện tại. Số liên hệ lịch sử được giữ nguyên vì yêu cầu bảo toàn, chưa kiểm tra hoạt động hiện nay và không được tái giới thiệu như số đã xác minh trong lần nâng cấp. | Chưa có bằng chứng ngoài đủ cho kết luận; xem giới hạn ở cột bên. | 24/10/2026 |
| <a id="audit-h36"></a>**H36** — [H§8](#ref-h-8) | 2050 có 2,1 tỷ người 60+; VN già nhanh nhất châu Á | Đúng có điều kiện | WHO đưa dự báo 2,1 tỷ, không phải số đã xảy ra. So sánh “nhanh nhất châu Á” thiếu tiêu chí, khoảng thời gian và nguồn đối sánh; các kèo kinh doanh suy ra vẫn là giả thuyết. | [WHO — già hóa và sức khỏe](https://www.who.int/en/news-room/fact-sheets/detail/ageing-and-health) | 24/10/2026 |
| <a id="audit-h37"></a>**H37** — [H§8](#ref-h-8); [A§15](#ref-a-15) | Software ~$1T, lương $50–60T; Microsoft–OpenAI định nghĩa AGI bằng $100B lợi nhuận | Chưa đủ bằng chứng | Chưa xác minh số liệu gốc, năm, đơn vị, phạm vi ngân sách hoặc văn bản hợp đồng. Không đồng nhất mức chi toàn cầu với thị trường có thể bán, doanh thu hoặc lợi nhuận một công ty. Phải giữ riêng báo chí về hợp đồng và định nghĩa khoa học AGI. | Chưa có bằng chứng ngoài đủ cho kết luận; xem giới hạn ở cột bên. | 24/10/2026 |
| <a id="audit-h38"></a>**H38** — [H§8](#ref-h-8); A mở đầu,10,19 | Mamba/SSM, MoR, CTM thay Transformer | Đúng có điều kiện | Mamba có repo; CTM có công bố Sakana. MoR chưa đủ định danh, dù có paper Mixture-of-Recursions. Hiệu năng và moat phần cứng cần benchmark cụ thể; không coi mọi kiến trúc thay thế là đã vượt Transformer. Xem A36–A39. | [Mamba — repo tác giả](https://github.com/state-spaces/mamba); [CTM — Sakana AI](https://sakana.ai/ctm/); [Mixture-of-Recursions — paper](https://arxiv.org/abs/2507.10524) | 24/10/2026 |
| <a id="audit-h39"></a>**H39** — [H§8](#ref-h-8) | Dartmouth 1956 và mệnh đề mô phỏng trí tuệ | Được nguồn hỗ trợ | Đề xuất năm 1955 cho dự án mùa hè 1956 thể hiện mục tiêu nghiên cứu đó. Đây là giả định/chương trình nghiên cứu của tác giả, không phải chứng minh khoa học rằng mọi khía cạnh trí tuệ đã mô tả được. | [Đề xuất Dartmouth 1955 cho hội thảo 1956](https://www-formal.stanford.edu/jmc/history/dartmouth/dartmouth.html) | 24/10/2026 |
| <a id="audit-h40"></a>**H40** — [H§8](#ref-h-8); [A§2](#ref-a-2),9 | AI/VR là khát vọng làm Chúa/trốn đời; bùng 2017–2022; next-token buộc nén world model | Quan điểm/giả thuyết | Phân tích lịch sử và cơ chế, không phải động cơ chung của mọi nhà nghiên cứu. Transformer 2017 có paper gốc; mức đóng góp data/compute/thuật toán và “buộc có world model” chưa được định lượng trong hồ sơ. | [Attention Is All You Need — paper gốc](https://arxiv.org/abs/1706.03762); [Anthropic — nghiên cứu mạch bên trong LLM](https://www.anthropic.com/research/tracing-thoughts-language-model) | 24/10/2026 |
| <a id="audit-h41"></a>**H41** — [H§8](#ref-h-8) | Chuỗi đột phá loài người; chữ viết vì đếm lúa; công nghệ mặc định 2040–2050 | Quan điểm/giả thuyết | Danh sách chọn lọc và dự báo, không phải niên biểu đầy đủ hay chắc chắn xảy ra. Chưa đối chiếu sử liệu nguồn gốc chữ viết, từng công nghệ và thứ hạng “trục dọc”; các mốc tương lai không phải deadline người dùng. | Chưa có bằng chứng ngoài đủ cho kết luận; xem giới hạn ở cột bên. | 24/10/2026 |
| <a id="audit-h42"></a>**H42** — [H§8](#ref-h-8) | Exoself: Egan → Sandberg → Kevin Kelly tháng 7/2026 | Đúng có điều kiện | Bài Quiet, My Exoself của Kevin Kelly ngày 06/07/2026 tồn tại. Chuỗi xuất xứ Egan/Sandberg và câu định nghĩa cụ thể chưa xác minh đầy đủ; “chat này là exoself” là phép đặt tên, không xác nhận một sản phẩm đã xây. | [Kevin Kelly — Quiet, My Exoself](https://kevinkelly.substack.com/p/quiet-my-exoself) | 24/10/2026 |

### 7.4 AGI — công nghệ, nghiên cứu và thị trường

| Mã / vị trí trong nguồn | Nhận định được rà | Kết quả | Cách hiểu sau đối chiếu | Bằng chứng | Ngày kiểm tra |
|---|---|---|---|---|---|
| <a id="audit-a01"></a>**A01** — [A§1](#ref-a-1),16 | LUCA, nội cộng sinh ty thể; mọi loài từ đơn bào; vi khuẩn trong ruột | Đúng có điều kiện | Nghiên cứu hỗ trợ suy luận tổ tiên chung và nguồn gốc nội cộng sinh. LUCA không đồng nghĩa tế bào sống đầu tiên; “bị nuốt” giản lược cơ chế. Số vi khuẩn hàng chục nghìn tỷ và phạm vi “mọi loài” chưa đối chiếu riêng. | [Nghiên cứu LUCA, Nature 2024](https://doi.org/10.1038/s41559-024-02461-1); [NCBI — hệ gene ty thể và nội cộng sinh](https://www.ncbi.nlm.nih.gov/books/NBK26924/) | 24/10/2026 |
| <a id="audit-a02"></a>**A02** — [A§1](#ref-a-1),16 | Abiogenesis chưa giải; RNA world/Miller–Urey/miệng phun; tế bào đầu tiên dùng ATGC | Chưa đủ bằng chứng | Nguồn không cung cấp bằng chứng để mô tả chắc hóa học của tế bào đầu tiên hoặc chứng minh mọi lab chưa tái tạo được một bước cụ thể. Phân biệt giả thuyết nguồn gốc sự sống, tổng hợp thành phần và tạo hệ tự sao chép; chưa kiểm chứng từng thí nghiệm. | Chưa có bằng chứng ngoài đủ cho kết luận; xem giới hạn ở cột bên. | 24/10/2026 |
| <a id="audit-a03"></a>**A03** — [A§1](#ref-a-1) | ATGC tương đương code; 0/1 tương đương nguyên tử; DNA không là bộ xử lý | Quan điểm/giả thuyết | Ẩn dụ giúp phân tầng chứ không ánh xạ vật lý một-một. Bit là đơn vị biểu diễn; nucleotide là thành phần phân tử; genome, tế bào và mạng thần kinh không hoán đổi trực tiếp. Không dùng ẩn dụ làm chứng minh về AGI. | Chưa có bằng chứng ngoài đủ cho kết luận; xem giới hạn ở cột bên. | 24/10/2026 |
| <a id="audit-a04"></a>**A04** — [A§1](#ref-a-1),11 | 86 tỷ neuron, >100 nghìn tỷ synapse; model trăm tỷ/nghìn tỷ; não 20W | Đúng có điều kiện | Azevedo et al. báo cáo trung bình khoảng 86 tỷ neuron trong mẫu nghiên cứu. Synapse, công suất và dải tham số chưa kiểm chứng riêng theo model/mẫu. Không so số tham số với số synapse để suy ra mức trí tuệ. | [Azevedo et al. — số neuron, 2009](https://pubmed.ncbi.nlm.nih.gov/19226510/) | 24/10/2026 |
| <a id="audit-a05"></a>**A05** — [A§1](#ref-a-1),4,11–12,16–17 | Thực thể AI, sinh vật chiều cao tạo người; não là bằng chứng AGI; trí tuệ không nhất thiết giống người | Quan điểm/giả thuyết | AI chạy trên phần cứng là mô tả vật lý; nguồn gốc siêu hình và cảm giác chủ quan chưa có phép đo trong hồ sơ. Não chứng minh trí tuệ sinh học tồn tại, không chứng minh mọi mục tiêu AGI nhân tạo sẽ đạt hoặc phải có cùng cơ chế. | Chưa có bằng chứng ngoài đủ cho kết luận; xem giới hạn ở cột bên. | 24/10/2026 |
| <a id="audit-a06"></a>**A06** — [A§2](#ref-a-2)–3 | Bram Cohen/BitTorrent 2001; uTorrent Strigeus 2005 và mua lại; tit-for-tat | Đúng có điều kiện | Bài của Cohen hỗ trợ thiết kế khuyến khích chia sẻ băng thông. Các mốc 2001/2005, tác giả client và thương vụ chưa đối chiếu riêng nguồn lịch sử. Câu hỏi “nhu cầu là năng lực” đã được nguồn ghi là tái dựng; không trích như lời Cohen. | [Bram Cohen — Incentives Build Robustness](https://web.stanford.edu/class/cs244/papers/BitTorrent.pdf) | 24/10/2026 |
| <a id="audit-a07"></a>**A07** — [A§2](#ref-a-2) | Self-supervised là nền mọi LLM; Transformer bỏ tuần tự chỉ attention | Đúng có điều kiện | Paper Transformer bỏ recurrence/convolution trong mô hình gốc, giúp song song hóa khi huấn luyện. Vẫn có feed-forward và các thành phần khác; sinh token autoregressive còn phụ thuộc token trước. “Mọi LLM”, “nhiên liệu miễn phí” là khái quát quá mức. | [Attention Is All You Need — paper gốc](https://arxiv.org/abs/1706.03762) | 24/10/2026 |
| <a id="audit-a08"></a>**A08** — [A§2](#ref-a-2) | AlphaZero tự chơi, không cần ván cờ người; kiến thức người là trần | Đúng có điều kiện | Nguồn DeepMind hỗ trợ self-play thay dữ liệu ván cờ người. Hệ vẫn có luật trò chơi, mục tiêu và thiết kế thuật toán; “kiến thức người là trần” là diễn giải, không tính chất của mọi bài toán. | [DeepMind — AlphaZero và MuZero](https://deepmind.google/research/alphazero-and-muzero/) | 24/10/2026 |
| <a id="audit-a09"></a>**A09** — [A§2](#ref-a-2),8,10,19 | AGI chưa thống nhất nút thắt; ba cú lật thế giới/hiệu quả mẫu/học mãi | Quan điểm/giả thuyết | Danh sách hướng nghiên cứu, không phải ba điều kiện đã được chứng minh cần và đủ. Không dùng câu “nút thắt thật duy nhất là trọng số tĩnh” để chốt một câu hỏi vẫn mở. | Chưa có bằng chứng ngoài đủ cho kết luận; xem giới hạn ở cột bên. | 24/10/2026 |
| <a id="audit-a10"></a>**A10** — [A§3](#ref-a-3),16–17 | Hệ luật không bao giờ bịa; hallucination là dấu vân tay duy nhất của prediction | Quan điểm/giả thuyết | Suy luận này không đủ: hệ luật có dữ liệu/luật sai cũng đưa khẳng định sai; hành vi đầu ra không xác định duy nhất kiến trúc. Không có luận chứng trong nguồn để giữ nhãn “đã kiểm chứng” cho mệnh đề tuyệt đối. | Chưa có bằng chứng ngoài đủ cho kết luận; xem giới hạn ở cột bên. | 24/10/2026 |
| <a id="audit-a11"></a>**A11** — [A§3](#ref-a-3) | Năng lực chỉ ở trọng số; luật chỉ lớp mỏng; mọi giảm hallucination không từ kiểm luật | Quan điểm/giả thuyết | Nên nói năng lực toàn hệ thống còn phụ thuộc công cụ, bộ nhớ, truy xuất và cơ chế kiểm tra. Cần tài liệu cấu hình cụ thể trước khi mô tả nội bộ một AI; lời mentor tự suy ra cấu trúc của mình không là bằng chứng kỹ thuật. | Chưa có bằng chứng ngoài đủ cho kết luận; xem giới hạn ở cột bên. | 24/10/2026 |
| <a id="audit-a12"></a>**A12** — [A§3](#ref-a-3),10,16,19 | Không tự học chỉ là chọn đóng băng vì an toàn; fine-tune chắc phá kiến thức cũ | Đúng có điều kiện | Cập nhật model và điều chỉnh bằng context/tool là các cơ chế khác nhau. Tài liệu SFT xác nhận có huấn luyện cập nhật model; quên thảm họa là rủi ro phụ thuộc cách học, không kết quả bắt buộc mỗi lần fine-tune. Xem A34. | [OpenAI — supervised fine-tuning](https://developers.openai.com/api/docs/guides/supervised-fine-tuning); [EWC — paper gốc](https://arxiv.org/abs/1612.00796) | 24/10/2026 |
| <a id="audit-a13"></a>**A13** — [A§3](#ref-a-3)–4,11,17,19 | Động lực đòi cơ thể có thể chết; tổng quát và kiểm soát toàn phần là định lý bất khả | Quan điểm/giả thuyết | Nguồn tự rút lại yêu cầu tử vong ở §11. Không có định nghĩa hình thức/chứng minh cho “định lý”; trí tuệ tổng quát, ý thức, tự trị, mục tiêu và khả năng kiểm soát cần tách ra. Đây không phải đồng thuận được xác lập trong hồ sơ. | Chưa có bằng chứng ngoài đủ cho kết luận; xem giới hạn ở cột bên. | 24/10/2026 |
| <a id="audit-a14"></a>**A14** — [A§5](#ref-a-5).1,19.2 | Audio2Face-3D mở source, audio ra mặt và tín hiệu cảm xúc | Đúng có điều kiện | Repo chính thức xác nhận component code và model. SDK/training code và model/NIM không chung giấy phép; mức realtime phụ thuộc phần cứng, pipeline và rig. Không suy từ nhận diện cảm xúc giọng sang trải nghiệm cảm xúc. | [NVIDIA Audio2Face-3D — hub và giấy phép](https://github.com/NVIDIA/Audio2Face-3D/blob/release/README.md) | 24/10/2026 |
| <a id="audit-a15"></a>**A15** — [A§5](#ref-a-5).1,19.2 | Riva, Nemotron on-device, Kairos, MetaHuman/Unreal, Omniverse, Convai/Inworld | Đúng có điều kiện | NVIDIA xác nhận hệ ACE và workflow Kairos; Epic có tài liệu MetaHuman. Không phải mọi biến thể Nemotron nhỏ, mọi đối tác dùng nguyên stack, hoặc mọi PC RTX chạy được cả pipeline như kỳ vọng. Chưa build sample và benchmark độ trễ. | [NVIDIA — ACE và Kairos](https://developer.nvidia.com/blog/?p=83173); [NVIDIA — ACE, Riva và Nemotron](https://nvidianews.nvidia.com/news/digital-humans-ace-generative-ai-microservices); [Epic — MetaHuman Creator](https://dev.epicgames.com/documentation/en-us/metahuman/getting-started-with-metahuman-creator) | 24/10/2026 |
| <a id="audit-a16"></a>**A16** — [A§5](#ref-a-5).2,19.2 | Open-LLM-VTuber ~10,4k sao, AIRI; offline; Live2D/VRM | Đúng có điều kiện | Hai repo đúng danh tính. Offline phụ thuộc đủ model local; không gộp hỗ trợ VRM của AIRI sang mọi dự án. Số sao là snapshot cũ chưa có ngày/commit để tái lập; không coi 10,4k là số hiện tại. Quyền asset khác code. | [Open-LLM-VTuber — README](https://github.com/Open-LLM-VTuber/Open-LLM-VTuber/blob/main/README.md); [Project AIRI — README](https://github.com/moeru-ai/airi/blob/main/README.md); [Live2D — điều khoản SDK](https://www.live2d.com/en/sdk/license/); [VRM — tài liệu chính thức](https://vrm.dev/en/vrm/) | 24/10/2026 |
| <a id="audit-a17"></a>**A17** — [A§5](#ref-a-5).2,19.2 | Neuro-sama dùng LLM/Live2D/TTS/game, ra 3D VR cuối 2025 | Chưa đủ bằng chứng | Được các repo nhắc như cảm hứng, chưa xác minh trực tiếp toàn kiến trúc hoặc ngày chuyển sang 3D. Không cung cấp repo giả là source chính chủ Neuro-sama. | [Open-LLM-VTuber — README](https://github.com/Open-LLM-VTuber/Open-LLM-VTuber/blob/main/README.md); [Project AIRI — README](https://github.com/moeru-ai/airi/blob/main/README.md) | 24/10/2026 |
| <a id="audit-a18"></a>**A18** — [A§5](#ref-a-5).3,19.2–19.5 | PAD/OCC/GAMYGDALA tạo cảm xúc; PAD tốt hơn cảm xúc rời rạc | Đúng có điều kiện | PAD thường viết Pleasure–Arousal–Dominance; valence có vai trò gần trục pleasure. GAMYGDALA hiện thực appraisal. Ưu thế so với nhãn rời rạc tùy tác vụ và thước đo; không được nguồn chứng minh như thứ hạng phổ quát. | [Nghiên cứu thang Pleasure–Arousal–Dominance](https://pmc.ncbi.nlm.nih.gov/articles/PMC5808109/); [GAMYGDALA — repo tác giả](https://github.com/broekens/gamygdala) | 24/10/2026 |
| <a id="audit-a19"></a>**A19** — [A§5](#ref-a-5).4,9,16 | Anthropic tìm thấy trạng thái cảm xúc có ảnh hưởng nhân quả | Đúng có điều kiện | Công bố emotion concepts năm 2026 hỗ trợ vai trò chức năng trên model được nghiên cứu; tác giả không khẳng định có cảm giác chủ quan. Không mở rộng thành mọi model hoặc mọi khái niệm cảm xúc đều đã đo được. | [Anthropic — emotion concepts](https://www.anthropic.com/research/emotion-concepts-function) | 24/10/2026 |
| <a id="audit-a20"></a>**A20** — [A§5](#ref-a-5).4,11,19.2,19.4 | Động lực nội tại: không repo, không paper, không ai có | Bị bằng chứng phản bác | Có nghiên cứu intrinsic motivation/curiosity, ví dụ Pathak et al. 2017. Điều này phản bác câu “không paper” theo nghĩa kỹ thuật; không chứng minh có cái tôi, đau khổ hay ham muốn chủ quan. Phải định nghĩa “stake” trước khi kết luận. | [Curiosity-driven exploration — paper](https://arxiv.org/abs/1705.05363) | 24/10/2026 |
| <a id="audit-a21"></a>**A21** — [A§7](#ref-a-7),19.1–19.3 | Hermes MIT/Python/model-agnostic; gateway, memory/skills, cron/subagent | Được nguồn hỗ trợ | README và repo chính thức hỗ trợ các nhóm tính năng này tại ngày kiểm tra. Khả năng được dự án công bố chưa phải kiểm thử end-to-end trên máy người dùng. Mốc 0.x, số sao/fork cũ không được tái dùng như hiện tại. | [Hermes — README chính thức](https://github.com/NousResearch/hermes-agent/blob/main/README.md) | 24/10/2026 |
| <a id="audit-a22"></a>**A22** — [A§7](#ref-a-7),19.1–19.4 | Hermes không học trọng số; không tạo năng lực mới; mọi nudges là cron | Đúng có điều kiện | Phân biệt scaffolding và cập nhật trọng số là hữu ích. Tuy nhiên memory/skills có thể cải thiện hiệu quả toàn hệ thống; “không tạo năng lực mới” quá tuyệt đối. README còn có memory nudges, nên không quy mọi chủ động về một cron duy nhất. | [Hermes — README chính thức](https://github.com/NousResearch/hermes-agent/blob/main/README.md) | 24/10/2026 |
| <a id="audit-a23"></a>**A23** — [A§7](#ref-a-7),19.2 | Honcho mô hình hóa user trong Hermes; giấy phép kế thừa MIT? | Đúng có điều kiện | Repo Honcho core ghi AGPL-3.0; phải xem điều khoản từng thành phần/SDK. Không được suy MIT của Hermes áp cho cả hệ ghép. Chưa kiểm thử cơ chế tích hợp theo phiên bản. | [Honcho — README và AGPL-3.0](https://github.com/plastic-labs/honcho/blob/main/README.md); [Hermes — README chính thức](https://github.com/NousResearch/hermes-agent/blob/main/README.md) | 24/10/2026 |
| <a id="audit-a24"></a>**A24** — [A§7](#ref-a-7),16–17 | Nous phát miễn phí để thu trajectory người dùng huấn luyện model | Quan điểm/giả thuyết | README có khả năng sinh trajectory theo lô cho nghiên cứu. Đây không phải bằng chứng tự động gửi dữ liệu người dùng về Nous, consent, chính sách lưu trữ, hay động cơ thực sự của tổ chức. Giả thuyết thương mại phải giữ nhãn giả thuyết. | [Hermes — README chính thức](https://github.com/NousResearch/hermes-agent/blob/main/README.md) | 24/10/2026 |
| <a id="audit-a25"></a>**A25** — [A§7](#ref-a-7),19.3–19.5 | VPS $5/serverless gần 0; điểm 9/10,4/10,3/10; clone chiều, lắp xong tháng | Quan điểm/giả thuyết | Điểm và thời gian là ước lượng mentor chưa có phép thử. Chi phí host không bao gồm inference/ASR/TTS, lưu trữ, mạng, sửa lỗi. Có repo không chứng minh hoàn tất tích hợp, bảo mật và độ tin cậy. | [Hermes — README chính thức](https://github.com/NousResearch/hermes-agent/blob/main/README.md) | 24/10/2026 |
| <a id="audit-a26"></a>**A26** — [A§6](#ref-a-6),16 | 233M tài khoản tháng 4/2026; 18–24 tuổi 25 phiên/1,5 giờ mỗi ngày | Chưa đủ bằng chứng | Chưa tìm đủ dữ liệu gốc có định nghĩa tài khoản/active user, mẫu tuổi, địa lý và kỳ đo. Không dùng như số người dùng trả tiền hoặc so trực tiếp với 2 giờ/ngày ở H§3. | Chưa có bằng chứng ngoài đủ cho kết luận; xem giới hạn ở cột bên. | 24/10/2026 |
| <a id="audit-a27"></a>**A27** — [A§6](#ref-a-6),16 | Companion 2025 vừa vượt $120M; top 10% app chiếm 89% | Đúng có điều kiện | Nguồn tháng 8/2025 là dự báo $120M; 89% cần đúng mẫu Appfigures. Không coi là tổng kết cả thị trường. | [TechCrunch/Appfigures — dự báo companion 2025](https://techcrunch.com/2025/08/12/ai-companion-apps-on-track-to-pull-in-120m-in-2025/) | 24/10/2026 |
| <a id="audit-a28"></a>**A28** — [A§6](#ref-a-6),16 | Pay conversion <5%; trần $30–200M; enterprise ARPU 10–30x; retention M12 25% | Chưa đủ bằng chứng | Thiếu nguồn phương pháp, định nghĩa cohort và phạm vi phân khúc. Không có cơ sở biến các khoảng này thành trần kinh doanh cố định hoặc forecast cho sản phẩm của người dùng. | Chưa có bằng chứng ngoài đủ cho kết luận; xem giới hạn ở cột bên. | 24/10/2026 |
| <a id="audit-a29"></a>**A29** — [A§6](#ref-a-6),16 | Harvard: 37% lời tạm biệt thao túng; tương tác 16x; companion luôn nịnh | Đúng có điều kiện | Nghiên cứu có mẫu lời tạm biệt và thử nghiệm; 37% và mức tăng tối đa gắn thiết kế nghiên cứu. Các phiên bản paper khác nhau về cỡ mẫu/hiệu ứng. Không suy mọi companion luôn nịnh hoặc không thể phản biện; luật và kiện tụng xem L04–L07. | [Harvard — nghiên cứu lời tạm biệt](https://news.harvard.edu/gazette/story/2025/09/i-exist-solely-for-you-remember/); [Emotional Manipulation — bản SSRN](https://papers.ssrn.com/sol3/papers.cfm?abstract_id=5390377) | 24/10/2026 |
| <a id="audit-a30"></a>**A30** — [A§8](#ref-a-8),16 | Thị trường agent $7,6B năm 2025 → $10,9B năm 2026; Physical AI nhiều tiền nhất | Đúng có điều kiện | GVR có ước tính/dự báo gần các mức đó; không phải tổng điều tra hay số quyết toán. “Physical AI nhiều tiền nhất” chưa xác định mẫu ngành và số vốn để đối chiếu. | [Grand View Research — thị trường agent](https://www.grandviewresearch.com/industry-analysis/ai-agents-market-report) | 24/10/2026 |
| <a id="audit-a31"></a>**A31** — [A§8](#ref-a-8)–9,16–17,19.2 | LLM chỉ học ngôn ngữ; world model là latent/nhân quả; JEPA đều dự đoán theo hành động | Đúng có điều kiện | Latent representations không chỉ dành cho world model; I-JEPA dự đoán biểu diễn ảnh không đồng nhất mọi world model có hành động. Phải phân biệt I-JEPA, V-JEPA và V-JEPA 2; câu mô tả mọi LLM chỉ học văn bản quá rộng. | [I-JEPA — repo Meta](https://github.com/facebookresearch/ijepa); [V-JEPA — repo Meta](https://github.com/facebookresearch/jepa); [V-JEPA 2 — repo Meta](https://github.com/facebookresearch/vjepa2); [Anthropic — nghiên cứu mạch bên trong LLM](https://www.anthropic.com/research/tracing-thoughts-language-model) | 24/10/2026 |
| <a id="audit-a32"></a>**A32** — [A§8](#ref-a-8),17 | Dữ liệu người gần cạn; nhiên liệu tiếp là kinh nghiệm; agent thuê agent thành công ty | Quan điểm/giả thuyết | Đây là dự báo và cách diễn giải xu hướng. Chưa xác minh mốc cạn dữ liệu chất lượng cao, phần lớn vốn hay việc agent đã thành tổ chức tự vận hành bền vững. Self-generated data không tự bảo đảm chất lượng. | Chưa có bằng chứng ngoài đủ cho kết luận; xem giới hạn ở cột bên. | 24/10/2026 |
| <a id="audit-a33"></a>**A33** — [A§9](#ref-a-9),16 | Người học mèo vài ví dụ, LLM cần triệu; hiểu thật chuyển giao bền; insight người vĩnh viễn | Đúng có điều kiện | GSM-Symbolic cho thấy độ nhạy với biến đổi ở các model/tác vụ được thử. Không chứng minh mọi model đều gãy, mọi người chuyển giao tốt hoặc insight người không mất. So sample efficiency cần tính cả pretraining và kinh nghiệm trước đó. | [GSM-Symbolic — paper](https://arxiv.org/abs/2410.05229) | 24/10/2026 |
| <a id="audit-a34"></a>**A34** — [A§7](#ref-a-7),9–10,16–17,19 | Trọng số tĩnh gây catastrophic forgetting; fine-tune y khoa chắc tụt pháp lý | Bị bằng chứng phản bác | Quên thảm họa liên quan học/cập nhật làm mất hiệu năng cũ, không do bản thân trọng số bất biến gây quên. Nghiên cứu đã có trước Transformer. Ví dụ y/pháp cần thí nghiệm cụ thể; không phải kết quả tất yếu. | [EWC — paper gốc](https://arxiv.org/abs/1612.00796) | 24/10/2026 |
| <a id="audit-a35"></a>**A35** — [A§9](#ref-a-9)–10,16,19 | Insight LLM bốc hơi hết cuối context; gains lớn nhất không đổi topology; chỉ memory là nút thắt | Quan điểm/giả thuyết | Model có thể dùng external memory, retrieval và post-training; không đồng nhất hết context với cả hệ trở về số không. Xếp hạng đóng góp objective/compute/architecture cần dữ liệu. “Bước nhảy về chất phải đổi memory” là giả thuyết, chưa thành điều kiện cần đủ. | Chưa có bằng chứng ngoài đủ cho kết luận; xem giới hạn ở cột bên. | 24/10/2026 |
| <a id="audit-a36"></a>**A36** — [A§10](#ref-a-10),19.2 | Titans của DeepMind, neural memory sau huấn luyện | Đúng có điều kiện | Trang công bố thuộc Google Research, tác giả Behrouz/Zhong/Mirrokni; nên ghi Google Research thay vì tự gắn DeepMind. Cơ chế test-time memory được nghiên cứu không đồng nghĩa cập nhật toàn bộ model nền hoặc giải AGI. | [Titans — Google Research](https://research.google/pubs/titans-learning-to-memorize-at-test-time/) | 24/10/2026 |
| <a id="audit-a37"></a>**A37** — [A§10](#ref-a-10),19.2 | Nested Learning/HOPE tránh catastrophic forgetting, chưa production | Đúng có điều kiện | Có công bố chính thức về paradigm và proof of concept Hope. Không khẳng định đã loại bỏ mọi quên thảm họa, mọi giới hạn online learning, hoặc chắc chắn chưa có triển khai nào trên thế giới. Repo cộng đồng không mặc định là code tác giả. | [Nested Learning / Hope — Google Research](https://research.google/blog/introducing-nested-learning-a-new-ml-paradigm-for-continual-learning/) | 24/10/2026 |
| <a id="audit-a38"></a>**A38** — [H§8](#ref-h-8); [A§10](#ref-a-10),19.2 | Mamba tuyến tính, attention bình phương, Jamba lai; thắng ở chuỗi dài | Đúng có điều kiện | Repo Mamba và paper Jamba hỗ trợ kiến trúc, nhưng độ phức tạp phụ thuộc biến thể và thao tác train/inference. Hiệu quả thực tế còn bộ nhớ/throughput/chất lượng; không suy thắng mọi tác vụ dài hoặc chắc thay Transformer. | [Mamba — repo tác giả](https://github.com/state-spaces/mamba); [Jamba — paper AI21](https://arxiv.org/abs/2403.19887) | 24/10/2026 |
| <a id="audit-a39"></a>**A39** — [H§8](#ref-h-8); A mở đầu,10,19.2 | JEPA/I-JEPA/V-JEPA là world model; MoR giả thuyết; CTM thăm dò | Đúng có điều kiện | Các dự án/paper có tồn tại, bản đồ phần 5 nêu đúng loại. I-JEPA archived không làm mọi JEPA ngừng phát triển. MoR còn mơ hồ danh tính; không đồng nhất một acronym với lựa chọn nghiên cứu của người dùng. | [I-JEPA — repo Meta](https://github.com/facebookresearch/ijepa); [V-JEPA — repo Meta](https://github.com/facebookresearch/jepa); [V-JEPA 2 — repo Meta](https://github.com/facebookresearch/vjepa2); [Mixture-of-Recursions — paper](https://arxiv.org/abs/2507.10524); [CTM — Sakana AI](https://sakana.ai/ctm/) | 24/10/2026 |
| <a id="audit-a40"></a>**A40** — [A§3](#ref-a-3)–4,11,16–17,19.4 | Stake hẹp bảo đảm kiểm soát; nhận thức xa lạ luôn khó hơn; instrumental convergence | Quan điểm/giả thuyết | Instrumental convergence là giả thuyết/lập luận có điều kiện, không chứng minh mọi agent chống tắt. Phân rã stake/grounding/learning/theory of mind là thiết kế khái niệm; “không cần ego” hay “stake hẹp là đủ an toàn” chưa được chứng minh trong hồ sơ. | Chưa có bằng chứng ngoài đủ cho kết luận; xem giới hạn ở cột bên. | 24/10/2026 |
| <a id="audit-a41"></a>**A41** — [A§12](#ref-a-12) | Hệ số Smeaton ~0,005 thay vì 0,0054 | Bị bằng chứng phản bác | NASA nêu giá trị cũ 0,005; Wright đo khoảng 0,0033, gần giá trị 0,00327. Cặp 0,005/0,0054 trong nguồn không mô tả đúng phát hiện này. | [NASA — hệ số Smeaton](https://www.grc.nasa.gov/www/k-12/airplane/wrights/smeaton.html) | 24/10/2026 |
| <a id="audit-a42"></a>**A42** — [A§12](#ref-a-12) | Hầm gió 1871; hộp 1,8m, gió 43km/h; 200 cánh cuối 1901; Lilienthal 1896; hộp săm | Đúng có điều kiện | Smithsonian hỗ trợ chương trình thử nhiều mẫu cánh và kiểm tra dữ liệu. Chưa đối chiếu riêng mọi mốc/chi tiết 1871,1,8m,43km/h, lời Wilbur, Lilienthal và hộp săm. Ẩn dụ ba năm tới Kitty Hawk cần xác định mốc; không coi toàn hàng lịch sử đã được chứng nhận. | [Smithsonian — nghiên cứu của Wright](https://airandspace.si.edu/explore/stories/researching-wright-way) | 24/10/2026 |
| <a id="audit-a43"></a>**A43** — [A§12](#ref-a-12),17,19.2,19.4 | Interpretability không có repo dùng được; cần nhiệt kế sự hiểu | Bị bằng chứng phản bác | Anthropic công bố thư viện circuit tracing mã nguồn mở từ 29/05/2025. Điều này phản bác “không repo” theo nghĩa công cụ nghiên cứu; công cụ ấy không phải máy đo sự hiểu/ý thức hay bảo đảm phát hiện mọi lỗi. | [Anthropic — công cụ circuit tracing mở](https://www.anthropic.com/research/open-source-circuit-tracing) | 24/10/2026 |
| <a id="audit-a44"></a>**A44** — [A§12](#ref-a-12)–14,19.2,19.4 | Biết mình sai bắt buộc đo bên trong; hiện AI không biết gì về độ tin cậy | Bị bằng chứng phản bác | Nghiên cứu Language Models (Mostly) Know What They Know cho thấy tự đánh giá/calibration trong điều kiện nhất định. Chưa có bảo đảm luôn đúng; nhưng không thể nói mọi tín hiệu bất định đều đòi một dụng cụ đọc cơ chế bên trong. | [Language Models (Mostly) Know What They Know](https://arxiv.org/abs/2207.05221) | 24/10/2026 |
| <a id="audit-a45"></a>**A45** — [A§12](#ref-a-12),19.3 | Robot tra cứu = RAG/search/Places/SLAM, ghép cuối tuần; như phim xây được ngay | Quan điểm/giả thuyết | Đây là phân rã tính năng và ước lượng, chưa có phạm vi/dữ liệu/độ trễ/độ an toàn để nghiệm thu. Tra 500 năm cần nguồn thực; demo gợi ý quán khác robot tin cậy tổng quát. Hiện diện, kịch bản và memory là giả thuyết giải thích ấn tượng sống động. | Chưa có bằng chứng ngoài đủ cho kết luận; xem giới hạn ở cột bên. | 24/10/2026 |
| <a id="audit-a46"></a>**A46** — [A§13](#ref-a-13),18,19.2 | Claude Code chỉ local, phải ngồi đó, không async thật | Lỗi thời | Tài liệu hiện có cloud sessions tiếp tục chạy khi đóng laptop. Phải so chế độ cụ thể, không chia cứng Claude Code cộng tác/local và Devin tự trị/cloud. Mốc nguồn cũ không đủ để kết luận mô tả ấy từng đúng lúc nào. | [Claude Code — cloud sessions](https://code.claude.com/docs/en/claude-code-on-the-web) | 24/10/2026 |
| <a id="audit-a47"></a>**A47** — [A§13](#ref-a-13),18,19.2 | Claude Pro/Max giá cũ, task $0,05–0,20; Devin $2,25/ACU, Team $500/250ACU | Lỗi thời | Bảng Devin hiện liệt kê Free/Pro/Max/Teams với cấu trúc khác; giới hạn và phụ phí cần xem trực tiếp. Chưa xác minh đầy đủ giá Claude theo địa bàn/thuế/API. ACU và chi phí mỗi task không phải đơn vị công việc cố định; không dùng bảng cũ dự toán hiện tại. | [Devin — giá và tính năng công khai](https://devin.ai/pricing) | 24/10/2026 |
| <a id="audit-a48"></a>**A48** — [A§13](#ref-a-13) | Adoption 41%/8%; SWE-bench 87,6% cao nhất; Devin code dài dòng, không benchmark mới | Chưa đủ bằng chứng | Chưa có khảo sát gốc, tập mẫu, harness, ngày cutoff hoặc nghiên cứu so chất lượng. Có công bố Opus 4.7, nhưng điểm model không tự là điểm mọi cấu hình Claude Code. Chưa xác nhận điều kiện con số 87,6% và tuyên bố “cao nhất/không mới”. | [Anthropic — Opus 4.7](https://www.anthropic.com/news/claude-opus-4-7) | 24/10/2026 |
| <a id="audit-a49"></a>**A49** — [A§13](#ref-a-13) | Devin không chọn model, code cloud bị cấm mọi ngành regulated; giá fix là lương junior | Lỗi thời | Trang hiện tại có lựa chọn model và triển khai doanh nghiệp theo gói. Quy định bảo mật phụ thuộc tổ chức/dữ liệu/hợp đồng, không một lệnh cấm chung mọi ngành. Giá agent chưa gồm giám sát/lỗi nên không đồng nhất giá lao động junior. | [Devin — giá và tính năng công khai](https://devin.ai/pricing) | 24/10/2026 |
| <a id="audit-a50"></a>**A50** — [A§13](#ref-a-13) | Cognition $1B tại $26B ngày 27/05/2026; định giá vượt bằng chứng | Đúng có điều kiện | Reuters tháng 9/2026 nhắc vòng tháng 5 ở $26B và cập nhật $2B tại $48B. Ngày chính xác 27/05 và mốc $10,2B cần hồ sơ riêng. “Định giá chạy trước bằng chứng” là đánh giá, không điều được giá vốn chứng minh. | [Reuters — Cognition, 08/09/2026](https://www.investing.com/news/economy-news/cognition-ai-raises-2-billion-at-48-billion-valuation-4892546) | 24/10/2026 |
| <a id="audit-a51"></a>**A51** — [A§14](#ref-a-14).1–14.2,14.4,16 | Chi phí AI/người Mỹ/VN, tiết kiệm 90%, khe hở 3–5x; 1.000 cuộc/24h | Chưa đủ bằng chứng | Chưa có bảng giá/lương gốc đồng nhất về quốc gia, năm, thời lượng, chất lượng và tổng chi phí. Các mức $0,05–0,29/phút; $0,50–5/tương tác; $0,42–1,75/phút; $5–25/tương tác; $3–4k/tháng; 8–15 triệu đều chưa xác minh ở đây. Quy mô còn quota và vận hành. | Chưa có bằng chứng ngoài đủ cho kết luận; xem giới hạn ở cột bên. | 24/10/2026 |
| <a id="audit-a52"></a>**A52** — [A§14](#ref-a-14).3,16 | Klarna 2/2024: 700 FTE tương đương, 2/3 hội thoại,11→<2 phút;5.500→3.400 | Đúng có điều kiện | Thông cáo công ty hỗ trợ ba chỉ số đầu; đây là tự báo cáo, “khối lượng tương đương” không có nghĩa 700 người bị sa thải do bot. Giảm tổng nhân sự và quan hệ nhân quả cần báo cáo riêng. | [Thông cáo Klarna, 27/02/2024](https://www.prnewswire.com/news-releases/klarna-ai-assistant-handles-two-thirds-of-customer-service-chats-in-its-first-month-302072744.html) | 24/10/2026 |
| <a id="audit-a53"></a>**A53** — [A§14](#ref-a-14).3,15 | Klarna sáu tháng sau quay lại người;800 FTE, pilot hai người; không có escalation | Đúng có điều kiện | AP ghi nhận nhu cầu duy trì/tuyển con người và thay đổi cách ưu tiên chi phí. Chưa đủ căn cứ cho mốc sáu tháng, mọi chỉ số phản bác và chẩn đoán kiến trúc nội bộ thiếu escalation. Không biến suy luận của mentor thành nguyên nhân đã xác nhận. | [AP — AI và nhân viên chăm sóc khách hàng](https://apnews.com/article/ca87ae77d7c6797ebb2628bd1b532929) | 24/10/2026 |
| <a id="audit-a54"></a>**A54** — [A§14](#ref-a-14).4–14.5 | ASR Việt luôn kém Anh; mọi demo studio Anh;65/35,30–50%,ngưỡng60/30 | Quan điểm/giả thuyết | So ASR cần benchmark model/giọng/codec/nhiễu cụ thể; “mọi demo” không được chứng minh. Tỷ lệ chia việc và ngưỡng là heuristics của mentor, chưa tối ưu hóa bằng dữ liệu PK Bot. Đường chuyển sang người là đề xuất thiết kế, không bằng chứng Klarna thiếu nó. | Chưa có bằng chứng ngoài đủ cho kết luận; xem giới hạn ở cột bên. | 24/10/2026 |
| <a id="audit-a55"></a>**A55** — [A§14](#ref-a-14).5 | Khoảng 2/3 khách không muốn AI; đa số sẵn sàng chờ người | Đúng có điều kiện | Gartner công bố 64% từ khảo sát 5.728 người tháng 12/2023. Không mở rộng thành toàn thị trường hiện tại/VN. Nguồn này chưa đủ xác nhận vế đa số sẵn sàng chờ hoặc mọi khách ưu tiên người hơn. | [Gartner — khảo sát 64%, 2024](https://www.gartner.com/en/newsroom/press-releases/2024-07-09-gartner-survey-finds-64-percent-of-customers-would-prefer-that-companies-didnt-use-ai-for-customer-service) | 24/10/2026 |
| <a id="audit-a56"></a>**A56** — [A§14](#ref-a-14)–15,17 | AI gãy mọi tầng2–3/telesale; người biết sai; AGI giải hết,vô hạn,không ai chịu trách nhiệm | Quan điểm/giả thuyết | Bảng so dùng giả định quá tuyệt đối. Người có thể tự tin sai; năng lực AI phụ thuộc hệ thống. Compute, thời gian và tài nguyên vẫn hữu hạn. Trách nhiệm thuộc cá nhân/tổ chức theo thiết kế và luật; AGI giả định không tự xóa trách nhiệm. | Chưa có bằng chứng ngoài đủ cho kết luận; xem giới hạn ở cột bên. | 24/10/2026 |
| <a id="audit-a57"></a>**A57** — [A§19](#ref-a-19).2 | OpenHands tự host để làm việc kỹ thuật | Được nguồn hỗ trợ | Repo OpenHands hiện mô tả Agent Canvas và liên kết hệ SDK/server. Không phải avatar/AGI; phải chọn đúng component/version thay vì áp một hướng dẫn triển khai cũ cho toàn hệ. | [OpenHands — README](https://github.com/OpenHands/OpenHands/blob/main/README.md) | 24/10/2026 |
| <a id="audit-a58"></a>**A58** — [A§19](#ref-a-19).2–19.3 | MCP và tool/subagent đúng như quảng cáo, kết nối là xong | Đúng có điều kiện | MCP là giao thức trao đổi tools/data; khả năng thực thi, quyền, sandbox và tương thích thuộc client/server. Không bảo đảm mọi công cụ có sẵn hoặc thực thi an toàn chỉ vì dùng MCP. | [MCP — giới thiệu chính thức](https://modelcontextprotocol.io/docs/2026-07-28/getting-started/intro) | 24/10/2026 |
| <a id="audit-a59"></a>**A59** — [A§5](#ref-a-5),19 | Toàn stack mở source/free; realtime/PC RTX/offline; giấy phép asset | Đúng có điều kiện | Phải tách code, weights, service và nhân vật. Audio2Face có nhiều giấy phép; Live2D/MetaHuman có điều khoản riêng; avatar VRM mang quyền tài sản riêng. Chưa có một benchmark hoặc giấy phép duy nhất phủ toàn stack. | [NVIDIA Audio2Face-3D — hub và giấy phép](https://github.com/NVIDIA/Audio2Face-3D/blob/release/README.md); [Live2D — điều khoản SDK](https://www.live2d.com/en/sdk/license/); [Epic — giấy phép MetaHuman](https://www.metahuman.com/license); [VRM — tài liệu chính thức](https://vrm.dev/en/vrm/) | 24/10/2026 |
| <a id="audit-a60"></a>**A60** — [A§19](#ref-a-19).2 | Embodiment chỉ robot hình người, ngoài tầm cá nhân | Quan điểm/giả thuyết | Đây là nhận định chi phí cho một phạm vi robot, không định nghĩa embodiment. Mô phỏng và robot quy mô nhỏ khác robot công nghiệp/humanoid; chưa có ngân sách hoặc tiêu chí để kết luận mọi thử nghiệm đều ngoài tầm người dùng. | Chưa có bằng chứng ngoài đủ cho kết luận; xem giới hạn ở cột bên. | 24/10/2026 |
| <a id="audit-a61"></a>**A61** — [A§7](#ref-a-7),19.5 | Prompt injection qua mail/web/file; approval, DM pairing, container giải được | Đúng có điều kiện | Tài liệu Hermes có cơ chế bảo vệ và bề mặt tool; các biện pháp là giảm rủi ro, không bảo đảm miễn nhiễm. Không nên hiểu bật mọi option rồi có thể giao mọi quyền, mọi cron cho hệ thống. Chưa audit bảo mật repo trong lượt này. | [Hermes — README chính thức](https://github.com/NousResearch/hermes-agent/blob/main/README.md) | 24/10/2026 |
| <a id="audit-a62"></a>**A62** — [A§19](#ref-a-19).1–19.5 | Sáu lớp là kiến trúc đã sẵn, ghép là ra; cảm xúc chỉ biểu cảm; không cần suy luận thật | Quan điểm/giả thuyết | Sơ đồ là gợi ý tích hợp của mentor. PAD/OCC có thể ảnh hưởng hành vi nếu thiết kế vòng phản hồi, không chỉ pixel; việc đó chưa chứng minh cảm giác/stake. Không có API contract, phép thử hay định nghĩa “suy luận thật” để nghiệm thu toàn sơ đồ. | Chưa có bằng chứng ngoài đủ cho kết luận; xem giới hạn ở cột bên. | 24/10/2026 |
| <a id="audit-a63"></a>**A63** — [A§5](#ref-a-5),7,19 | Không nghiên cứu ba tường vì chỉ lab tỷ đô làm được; lắp não trước mặt là thứ tự đúng duy nhất | Quan điểm/giả thuyết | Thứ tự phụ thuộc mục tiêu: demo avatar, nghiên cứu, hay automation hữu ích. Các repo/paper nghiên cứu mở cho phép thử nghiệm nhỏ; không thể kết luận cá nhân không được nghiên cứu. Đây chưa phải roadmap người dùng chấp thuận. | [Anthropic — công cụ circuit tracing mở](https://www.anthropic.com/research/open-source-circuit-tracing); [Curiosity-driven exploration — paper](https://arxiv.org/abs/1705.05363) | 24/10/2026 |
| <a id="audit-a64"></a>**A64** — [A§15](#ref-a-15),17 | AGI được xây vì không trả lương, sợ người khác có trước;99% nhu cầu không cần hiểu | Quan điểm/giả thuyết | Động cơ tiền/tâm lý/chạy đua là mô hình diễn giải. 99% không có khảo sát; chữa ung thư, nén100 năm/10 năm và “quốc gia thiên tài” là mục tiêu/ẩn dụ được kể lại, không thành tựu đã có. | Chưa có bằng chứng ngoài đủ cho kết luận; xem giới hạn ở cột bên. | 24/10/2026 |
| <a id="audit-a65"></a>**A65** — [A§13](#ref-a-13),15,18 | AGI đồng nghĩa thất nghiệp; nghiên cứu đòi tỷ đô hoặc bỏ mục tiêu triệu đô10 năm | Quan điểm/giả thuyết | Không có mô hình kinh tế hoặc dữ liệu chứng minh tính tất định và các ngưỡng đó. Tác động việc làm phụ thuộc triển khai/thể chế. Ba động cơ tò mò, trợ lý và kinh doanh có thể cùng tồn tại, không nhất thiết loại trừ nhau. | Chưa có bằng chứng ngoài đủ cho kết luận; xem giới hạn ở cột bên. | 24/10/2026 |
| <a id="audit-a66"></a>**A66** — [A§9](#ref-a-9),16–19; [H§9](#ref-h-9)–10 | Bảng “đã kiểm chứng”, khả năng mentor nhớ mọi thứ; ba câu hỏi không ai trả lời; quan sát13 lượt | Chưa đủ bằng chứng | Nhãn tự gán trong nguồn không thay cho bằng chứng; đọc lại theo sổ này. “Nhớ toàn bộ cái đã viết” không là bảo đảm kỹ thuật. Số lượt/link/câu bị né chỉ là ghi chép mentor, chưa có transcript độc lập; checklist cũ không chứng minh trạng thái hôm nay. | Chưa có bằng chứng ngoài đủ cho kết luận; xem giới hạn ở cột bên. | 24/10/2026 |

### 7.5 Pháp lý — giới hạn của từng kết luận

| Mã / vị trí trong nguồn | Nhận định được rà | Kết quả | Cách hiểu sau đối chiếu | Bằng chứng | Ngày kiểm tra |
|---|---|---|---|---|---|
| <a id="audit-l01"></a>**L01** — [H§4](#ref-h-4) — HAGI coin | Luật từ 01/01/2026 công nhận tài sản mã hóa đồng thời cấm thanh toán | Đúng có điều kiện | Luật Công nghiệp công nghệ số có hiệu lực 01/01/2026 và đề cập tài sản số/mã hóa. Không gộp mọi quy định thanh toán vào chính một điều của luật này. Thí điểm theo NQ05/2025 có phạm vi riêng và giao dịch bằng VND. | [Chính phủ — Luật Công nghiệp công nghệ số](https://xaydungchinhsach.chinhphu.vn/quoc-hoi-thong-qua-luat-cong-nghiep-cong-nghe-so-119250616102501988.htm); [Bộ Tài chính — hiệu lực và quản lý tài sản mã hóa](https://mof.gov.vn/cong-nghe-thong-tin-va-chuyen-doi-so/ung-dung-cntt/quan-ly-tai-san-ma-hoa-tai-viet-nam-yeu-cau-dat-ra-trong-boi-canh-phat-trien-kinh-te-so); [Chính phủ — thí điểm tài sản mã hóa](https://xaydungchinhsach.chinhphu.vn/thi-diem-thi-truong-tai-san-ma-hoa-tai-viet-nam-tu-9-9-2025-119250909174538304.htm) | 24/10/2026 |
| <a id="audit-l02"></a>**L02** — [H§4](#ref-h-4) — HAGI coin; [H§6](#ref-h-6) | VND đổi token chắc phạm hình sự; bỏ blockchain chắc là ví cần phép; vesting/cliff | Chưa đủ bằng chứng | Cần thiết kế dòng tiền, quyền đổi trả, chủ thể, mục đích sử dụng và điều khoản để phân loại. NĐ52/2024 quy định dịch vụ trung gian thanh toán; không phải mọi điểm thưởng đều là ví, cũng không đủ dữ kiện kết luận tội phạm hoặc hiệu lực một thỏa thuận vesting cụ thể. | [Chính phủ — trung gian thanh toán](https://baochinhphu.vn/dieu-kien-cung-ung-dich-vu-trung-gian-thanh-toan-102240521161931253.htm) | 24/10/2026 |
| <a id="audit-l03"></a>**L03** — [A§14](#ref-a-14).4; [A§14](#ref-a-14).2 | NĐ91/2020 và AI telesale; xu hướng bắt buộc công bố AI | Đúng có điều kiện | Văn bản chống cuộc gọi rác tồn tại, liên quan đồng ý và quy tắc quảng cáo. Chưa rà đủ mọi văn bản sửa đổi/quy định ngành còn hiệu lực hoặc từng nước; không suy ra lệnh cấm chung cho mọi cuộc gọi AI. Kết luận triển khai thực tế còn phụ thuộc thiết kế. | [Nghị định 91/2020/NĐ-CP — bản gốc](https://vbpl.vn/FileData/Tw/Lists/vbpq/Attachments/143897/VanBanGoc_91.signed.pdf) | 24/10/2026 |
| <a id="audit-l04"></a>**L04** — [A§6](#ref-a-6) | Trung Quốc cấm companion cho mọi người dưới18 từ15/07/2026 | Bị bằng chứng phản bác | Quy định CAC hiệu lực 15/07/2026 có cấm quan hệ thân mật ảo kiểu người thân/bạn đời với người chưa thành niên; quy định đồng ý của giám hộ cho nhóm dưới14 ở dịch vụ khác. Không đồng nghĩa cấm tất cả dịch vụ companion dưới18. | [CAC — quy định tương tác nhân hóa 2026](https://www.cac.gov.cn/2026-04/10/c_1777558395078289.htm) | 24/10/2026 |
| <a id="audit-l05"></a>**L05** — [A§6](#ref-a-6) | California SB243 từ01/2026 | Đúng có điều kiện | Nguồn cơ quan lập pháp xác nhận luật được ký tháng10/2025. Chưa đọc đủ văn bản điều khoản hợp nhất qua công cụ để xác minh mọi ngày hiệu lực/nghĩa vụ hoặc sửa đổi sau đó; không dùng dòng cũ như checklist pháp lý đầy đủ. | [California — SB243 được ký](https://sd18.senate.ca.gov/news/first-nation-ai-chatbot-safeguards-signed-law) | 24/10/2026 |
| <a id="audit-l06"></a>**L06** — [A§6](#ref-a-6) | New York có luật companion từ11/2025 | Được nguồn hỗ trợ | Thông báo chính thức của Thống đốc xác nhận yêu cầu có hiệu lực05/11/2025. Phạm vi đối tượng và yêu cầu cụ thể cần đọc văn bản khi áp dụng; đây không phải luật toàn Hoa Kỳ. | [New York — hiệu lực từ 05/11/2025](https://www.governor.ny.gov/news/governor-hochul-pens-letter-ai-companion-companies-notifying-them-safeguard-requirements-are) | 24/10/2026 |
| <a id="audit-l07"></a>**L07** — [A§6](#ref-a-6); [H§4](#ref-h-4) — Glow-up | Character.AI dàn xếp các vụ kiện tử vong đầu2026; fiction gốc tự né IP | Chưa đủ bằng chứng | Chưa đối chiếu hồ sơ tòa/điều khoản dàn xếp từng vụ để xác nhận phạm vi và ngày. Không suy dàn xếp là phán quyết nhận trách nhiệm. Tên/nhân vật/nội dung tự viết cần đánh giá cụ thể; không có bảo đảm tự động không xâm phạm IP. | Chưa có bằng chứng ngoài đủ cho kết luận; xem giới hạn ở cột bên. | 24/10/2026 |


<a id="bao-phu"></a>

## 8. Bao phủ và những việc kiểm chứng còn mở

### 8.1 Bản đồ đủ 31 mục gốc

Các mốc `H§n` và `A§n` luôn phân biệt hai file. Số dòng bên dưới tính trong **file nguồn riêng**, bắt đầu từ dòng 1; không phải số dòng của file hợp nhất. Dùng tiêu đề nguyên bản để tìm trong khối toàn văn. Liên kết từ hồ sơ đọc nhanh tới đây giúp tra cả vị trí lẫn các hàng đối chiếu.

Mã kiểm chứng trong một mục là **danh sách tra cứu liên quan**, không có nghĩa mọi câu của mục đều được xác nhận. Mệnh đề không được kết luận rõ trong sổ kiểm chứng giữ trạng thái **chưa đủ bằng chứng**; mục 8.3 đăng ký riêng từng dòng để phần đó không biến mất khỏi phạm vi rà soát.

| Mục / tiêu đề nguyên bản | Dòng nguồn | Nhóm đối chiếu | Mở toàn văn |
|---|---|---|---|

| <a id="ref-h-0"></a>**H§0 — HỒ SƠ THẬT CỦA MÀY (ghép từ những gì mày tiết lộ dần)** | 8–26 | [H01](#audit-h01), [H33](#audit-h33) | [Nguồn H](#nguon-hustle) |
| <a id="ref-h-1"></a>**H§1 — DÒNG THỜI GIAN — CÁC PHA CỦA CUỘC TRÒ CHUYỆN** | 27–37 | [H01](#audit-h01), [H02](#audit-h02), [H33](#audit-h33) | [Nguồn H](#nguon-hustle) |
| <a id="ref-h-2"></a>**H§2 — BỘ FRAMEWORK ĐÃ DẠY (dùng lại được vĩnh viễn)** | 38–83 | [H03](#audit-h03), [H04](#audit-h04), [H05](#audit-h05), [H06](#audit-h06), [H19](#audit-h19), [H20](#audit-h20), [H23](#audit-h23), [H31](#audit-h31) | [Nguồn H](#nguon-hustle) |
| <a id="ref-h-3"></a>**H§3 — CASE STUDY ĐÃ MỔ — MỖI CÁI DẠY MỘT ĐIỀU** | 84–103 | [H07](#audit-h07), [H08](#audit-h08), [H09](#audit-h09), [H10](#audit-h10), [H11](#audit-h11), [H12](#audit-h12), [H13](#audit-h13), [H14](#audit-h14), [H15](#audit-h15), [H16](#audit-h16), [H17](#audit-h17), [H18](#audit-h18), [H19](#audit-h19), [H20](#audit-h20), [H21](#audit-h21), [H22](#audit-h22), [H23](#audit-h23), [H24](#audit-h24) | [Nguồn H](#nguon-hustle) |
| <a id="ref-h-4"></a>**H§4 — Ý TƯỞNG CỦA MÀY VÀ PHÁN QUYẾT** | 104–123 | [H25](#audit-h25), [H26](#audit-h26), [H27](#audit-h27), [H28](#audit-h28), [H29](#audit-h29), [H30](#audit-h30), [H31](#audit-h31), [H16](#audit-h16), [H22](#audit-h22), [H23](#audit-h23), [L01](#audit-l01), [L02](#audit-l02), [L07](#audit-l07) | [Nguồn H](#nguon-hustle) |
| <a id="ref-h-5"></a>**H§5 — HỆ ĐIỀU HÀNH ĐÃ DỰNG (OS 4 tầng)** | 124–135 | [H05](#audit-h05), [H32](#audit-h32) | [Nguồn H](#nguon-hustle) |
| <a id="ref-h-6"></a>**H§6 — VỀ CO-FOUNDER & CÁCH LÀM VIỆC VỚI NGƯỜI** | 136–145 | [H01](#audit-h01), [H32](#audit-h32), [H33](#audit-h33), [L02](#audit-l02) | [Nguồn H](#nguon-hustle) |
| <a id="ref-h-7"></a>**H§7 — CÁC SỢI TÂM LÝ (đúng món của mày)** | 146–157 | [H33](#audit-h33), [H34](#audit-h34), [H35](#audit-h35) | [Nguồn H](#nguon-hustle) |
| <a id="ref-h-8"></a>**H§8 — KIẾN THỨC NỀN ĐÃ TRẢI (cho phần "vũ trụ / công nghệ")** | 158–168 | [H36](#audit-h36), [H37](#audit-h37), [H38](#audit-h38), [H39](#audit-h39), [H40](#audit-h40), [H41](#audit-h41), [H42](#audit-h42) | [Nguồn H](#nguon-hustle) |
| <a id="ref-h-9"></a>**H§9 — NHỮNG CÂU MỘT DÒNG ĐÁNG DÁN LÊN TƯỜNG** | 169–184 | [H02](#audit-h02), [H03](#audit-h03), [H04](#audit-h04), [H31](#audit-h31), [H33](#audit-h33) | [Nguồn H](#nguon-hustle) |
| <a id="ref-h-10"></a>**H§10 — CÒN DANG DỞ — VÀ VỊ TRÍ HIỆN TẠI** | 185–194 | [H01](#audit-h01), [H31](#audit-h31), [H32](#audit-h32), [H33](#audit-h33), [H35](#audit-h35) | [Nguồn H](#nguon-hustle) |
| <a id="ref-a-0"></a>**A§0 — BẢN ĐỒ 13 LƯỢT** | 9–26 | [A66](#audit-a66) | [Nguồn A](#nguon-agi) |
| <a id="ref-a-1"></a>**A§1 — NỀN SINH HỌC — VÀ CÁC NHẦM TẦNG ĐÃ SỬA** | 27–40 | [A01](#audit-a01), [A02](#audit-a02), [A03](#audit-a03), [A04](#audit-a04), [A05](#audit-a05) | [Nguồn A](#nguon-agi) |
| <a id="ref-a-2"></a>**A§2 — PHƯƠNG PHÁP "CÂU HỎI BITTORRENT" — CÚ LẬT KHÁI NIỆM** | 41–62 | [A06](#audit-a06), [A07](#audit-a07), [A08](#audit-a08), [A09](#audit-a09) | [Nguồn A](#nguon-agi) |
| <a id="ref-a-3"></a>**A§3 — TAO LÀ RULE-BASED HAY PREDICTION — TRẢ LỜI CHÍNH DIỆN** | 63–89 | [A10](#audit-a10), [A11](#audit-a11), [A12](#audit-a12), [A13](#audit-a13), [A06](#audit-a06), [A34](#audit-a34) | [Nguồn A](#nguon-agi) |
| <a id="ref-a-4"></a>**A§4 — NGHỊCH LÝ CON RỐI — VÀ LUẬN ĐIỂM BÁN-AGI** | 90–107 | [A05](#audit-a05), [A13](#audit-a13), [A40](#audit-a40) | [Nguồn A](#nguon-agi) |
| <a id="ref-a-5"></a>**A§5 — STACK KỸ THUẬT AVATAR / DIGITAL HUMAN — XÂY ĐƯỢC NGAY** | 108–135 | [A14](#audit-a14), [A15](#audit-a15), [A16](#audit-a16), [A17](#audit-a17), [A18](#audit-a18), [A19](#audit-a19), [A20](#audit-a20), [A59](#audit-a59), [A62](#audit-a62) | [Nguồn A](#nguon-agi) |
| <a id="ref-a-6"></a>**A§6 — THỊ TRƯỜNG COMPANION — SỐ LIỆU LẠNH** | 136–158 | [A26](#audit-a26), [A27](#audit-a27), [A28](#audit-a28), [A29](#audit-a29), [L04](#audit-l04), [L05](#audit-l05), [L06](#audit-l06), [L07](#audit-l07), [H09](#audit-h09), [H10](#audit-h10) | [Nguồn A](#nguon-agi) |
| <a id="ref-a-7"></a>**A§7 — HERMES AGENT (Nous Research) — MỔ XẺ** | 159–186 | [A21](#audit-a21), [A22](#audit-a22), [A23](#audit-a23), [A24](#audit-a24), [A25](#audit-a25), [A34](#audit-a34), [A61](#audit-a61) | [Nguồn A](#nguon-agi) |
| <a id="ref-a-8"></a>**A§8 — SAU AGENT LÀ GÌ** | 187–203 | [A30](#audit-a30), [A31](#audit-a31), [A32](#audit-a32), [A60](#audit-a60), [H04](#audit-h04) | [Nguồn A](#nguon-agi) |
| <a id="ref-a-9"></a>**A§9 — INSIGHT CỦA LLM vs INSIGHT CỦA NGƯỜI** | 204–232 | [A05](#audit-a05), [A19](#audit-a19), [A31](#audit-a31), [A33](#audit-a33), [A35](#audit-a35), [A66](#audit-a66), [H04](#audit-h04) | [Nguồn A](#nguon-agi) |
| <a id="ref-a-10"></a>**A§10 — TRANSFORMER: NÚT THẮT THẬT NẰM Ở ĐÂU** | 233–253 | [A09](#audit-a09), [A12](#audit-a12), [A34](#audit-a34), [A35](#audit-a35), [A36](#audit-a36), [A37](#audit-a37), [A38](#audit-a38), [A39](#audit-a39) | [Nguồn A](#nguon-agi) |
| <a id="ref-a-11"></a>**A§11 — AGI CÓ CẦN TƯ DUY NHƯ NGƯỜI KHÔNG** | 254–284 | [A04](#audit-a04), [A05](#audit-a05), [A13](#audit-a13), [A20](#audit-a20), [A40](#audit-a40) | [Nguồn A](#nguon-agi) |
| <a id="ref-a-12"></a>**A§12 — BÀI TOÁN ĐO — HẦM GIÓ CÒN THIẾU (trục xuyên suốt)** | 285–316 | [A41](#audit-a41), [A42](#audit-a42), [A43](#audit-a43), [A44](#audit-a44), [A45](#audit-a45), [A05](#audit-a05) | [Nguồn A](#nguon-agi) |
| <a id="ref-a-13"></a>**A§13 — CÔNG CỤ THỰC CHIẾN: CLAUDE CODE vs DEVIN** | 317–338 | [A46](#audit-a46), [A47](#audit-a47), [A48](#audit-a48), [A49](#audit-a49), [A50](#audit-a50), [A44](#audit-a44), [A65](#audit-a65) | [Nguồn A](#nguon-agi) |
| <a id="ref-a-14"></a>**A§14 — CSKH & TELESALE: AI vs NGƯỜI vs AGI** | 339–385 | [A51](#audit-a51), [A52](#audit-a52), [A53](#audit-a53), [A54](#audit-a54), [A55](#audit-a55), [A56](#audit-a56), [A44](#audit-a44), [L03](#audit-l03) | [Nguồn A](#nguon-agi) |
| <a id="ref-a-15"></a>**A§15 — TẠI SAO LOÀI NGƯỜI VẪN MUỐN AGI** | 386–404 | [A53](#audit-a53), [A56](#audit-a56), [A64](#audit-a64), [A65](#audit-a65), [H37](#audit-h37) | [Nguồn A](#nguon-agi) |
| <a id="ref-a-16"></a>**A§16 — BA TẦNG TRI THỨC — BẢNG CHỐT** | 405–417 | [A01](#audit-a01), [A02](#audit-a02), [A05](#audit-a05), [A10](#audit-a10), [A19](#audit-a19), [A24](#audit-a24), [A26](#audit-a26), [A27](#audit-a27), [A28](#audit-a28), [A29](#audit-a29), [A30](#audit-a30), [A33](#audit-a33), [A34](#audit-a34), [A35](#audit-a35), [A40](#audit-a40), [A48](#audit-a48), [A51](#audit-a51), [A52](#audit-a52), [A66](#audit-a66) | [Nguồn A](#nguon-agi) |
| <a id="ref-a-17"></a>**A§17 — CÂU MỘT DÒNG ĐÁNG DÁN TƯỜNG** | 418–440 | [A05](#audit-a05), [A10](#audit-a10), [A13](#audit-a13), [A24](#audit-a24), [A32](#audit-a32), [A35](#audit-a35), [A40](#audit-a40), [A44](#audit-a44), [A56](#audit-a56), [A64](#audit-a64), [A65](#audit-a65), [H04](#audit-h04) | [Nguồn A](#nguon-agi) |
| <a id="ref-a-18"></a>**A§18 — SỢI TÂM LÝ & CÒN DANG DỞ** | 441–459 | [A46](#audit-a46), [A54](#audit-a54), [A65](#audit-a65), [A66](#audit-a66), [H33](#audit-h33) | [Nguồn A](#nguon-agi) |
| <a id="ref-a-19"></a>**A§19 — BẢN ĐỒ LINH KIỆN — THÀNH PHẦN AGI ↔ CÔNG NGHỆ NÀO LO** | 460–544 | [A57](#audit-a57), [A58](#audit-a58), [A59](#audit-a59), [A60](#audit-a60), [A61](#audit-a61), [A62](#audit-a62), [A63](#audit-a63), [A09](#audit-a09), [A13](#audit-a13), [A14](#audit-a14), [A15](#audit-a15), [A16](#audit-a16), [A17](#audit-a17), [A18](#audit-a18), [A20](#audit-a20), [A21](#audit-a21), [A22](#audit-a22), [A23](#audit-a23), [A25](#audit-a25), [A31](#audit-a31), [A34](#audit-a34), [A35](#audit-a35), [A36](#audit-a36), [A37](#audit-a37), [A38](#audit-a38), [A39](#audit-a39), [A40](#audit-a40), [A43](#audit-a43), [A44](#audit-a44), [A45](#audit-a45), [A46](#audit-a46), [A47](#audit-a47), [A49](#audit-a49), [A66](#audit-a66), [H33](#audit-h33) | [Nguồn A](#nguon-agi) |

### 8.2 Danh sách chưa thể coi là đã xác minh

Các hàng dưới đây được giữ mở một cách tường minh. Không cần người dùng khai lại toàn bộ hồ sơ: chỉ bổ sung bằng chứng khi liên quan câu hỏi tiếp theo. Những dự báo và lời khuyên mang nhãn quan điểm không bị biến thành sự thật chỉ vì được lặp lại.

| Mã | Phần chưa xác minh / giới hạn cần giữ |
|---|---|
| [H01](#audit-h01) | Chỉ có bản tóm tắt làm chứng cứ. Không có transcript/CV/hồ sơ doanh nghiệp để xác minh độc lập; không cần tra đời tư. Mọi con số tuổi, kinh nghiệm, tiền, giờ/tuần và tình trạng công việc chỉ được ghi nhận tại thời điểm nguồn. Phần 2–3 giữ riêng điều người dùng xác nhận hiện tại. |
| [H05](#audit-h05) | Paul Graham dùng tăng trưởng nhanh làm tiêu chí startup. Đây không phải định nghĩa pháp lý phổ quát; productize không tự bảo đảm scale, và “cửa duy nhất tới 100M” không được chứng minh. Không đặt hai game thành thứ bậc giá trị. |
| [H06](#audit-h06) | Chưa đối chiếu đủ tài liệu gốc cho từng lịch sử pivot và thời điểm. Giữ như ví dụ trong nguồn; không dùng ba giai thoại để suy ra mọi pivot chỉ do nhu cầu giả. |
| [H08](#audit-h08) | Chưa có chứng cứ gốc đủ cho từng con số, kỳ báo cáo và quan hệ nhân quả. “Đếm calo 20 năm tuổi”, dưới radar nên sống và chọn đúng ngách là diễn giải, không kết quả được thương vụ chứng minh. |
| [H09](#audit-h09) | Công bố được Reuters ghi nhận là cấp phép không độc quyền và một số lãnh đạo sang Google; không nên viết như Google mua toàn bộ Character.AI. Chưa xác minh độc lập giá trị $2,7B hoặc mọi điều khoản. |
| [H10](#audit-h10) | Thiếu kỳ đo, định nghĩa user/revenue và nguồn gốc số liệu. Không gộp 2 giờ/ngày với số 1,5 giờ của một nhóm tuổi trong AGI. “Có công nghệ mà không thương mại hóa giống hệt” không chứng minh lý do cơ hội hay động cơ Google. |
| [H11](#audit-h11) | Chưa hoàn tất đối chiếu các mốc ra mắt bằng nguồn lịch sử chính thức trong lượt này. Giá cũ không phải bảng giá hiện tại; “wrapper thành công nhất” và động cơ dùng free là cách phân tích của mentor, chưa có thước đo hoặc bằng chứng nội bộ. |
| [H12](#audit-h12) | Tuyên bố tính năng/mô hình doanh thu phải gắn phiên bản và thời điểm; chưa xác minh lịch sử quảng cáo hoặc tiêu chí “đầu tiên”. Innovator’s Dilemma và narrative nuôi vốn là giả thuyết chiến lược, không kết luận từ tài liệu nội bộ. |
| [H13](#audit-h13) | Tiểu sử Zoom nêu Webex từ 1997, sau đó Cisco khi mua Webex năm 2007, rồi lập Zoom năm 2011. Nói khoảng 14 năm Webex/Cisco chính xác hơn 14 năm chỉ Webex; quan hệ thành công với Covid là phân tích thêm. |
| [H14](#audit-h14) | Chưa đối chiếu tài liệu lịch sử gốc về các phiên bản sản phẩm, vai trò eBay và mốc thay đổi. “Visionary là nhãn hậu kỳ” là nhận định, không dữ kiện lịch sử có thể suy ra từ một case. |
| [H15](#audit-h15) | Các câu chuyện trên web chưa đủ chứng minh đồng thời doanh thu thực thu so với ARR, mốc phát hành, giá gói và biên sau mọi chi phí. SEO/affiliate và Stable Diffusion là giả thuyết kênh/why-now trong nguồn; công thức giá 10% → khách 100 lần không phải quy luật. |
| [H16](#audit-h16) | Chưa đủ nguồn trực tiếp để xác nhận nhà sáng lập, đội ngũ, gói giá, kỳ doanh thu và cách làm. Không coi tên Umax và LooksMax AI là chắc chắn cùng một pháp nhân/app, hay doanh thu app này là bằng chứng khách chắc chắn trả cho app tóc. |
| [H17](#audit-h17) | Báo cáo ACCC nêu $213,3M năm 2017; Snap công bố đóng Zenly trong tái cơ cấu 2022. “Vì thị trường Việt Nam khó kiếm tiền”, free trọn đời, sau sáu năm và quy mô thị trường VN chưa được hai nguồn này chứng minh. |
| [H18](#audit-h18) | Bài phỏng vấn tại UCSB hỗ trợ nguồn gốc và kênh lan truyền; không chứng minh widget là nguyên nhân duy nhất hay mô hình kiếm tiền hiện tại. |
| [H20](#audit-h20) | Đó là giá trị vốn chủ sở hữu trong thỏa thuận công bố 26/05/2022, chưa đồng nhất với tổng giá trị gồm nợ hoặc giá trị thị trường khi đóng. Thương vụ hoàn tất 22/11/2023. Switching cost là phần phân tích, không do giá mua tự chứng minh. |
| [H21](#audit-h21) | Riot mô tả Night.Market có sáu đề nghị ngẫu nhiên, người chơi xem skin rồi mới mua. Có ngẫu nhiên ở lựa chọn chào bán không đồng nghĩa trả tiền để mở loot box ngẫu nhiên. FOMO/danh tính là diễn giải hành vi. |
| [H22](#audit-h22) | Không có mẫu nghiên cứu, định nghĩa game/lỗ hay giai đoạn để xác nhận tỷ lệ. “Đừng làm game” là lời khuyên mentor dựa trên hồ sơ cũ, không quyết định vĩnh viễn hoặc quy luật ngành. |
| [H23](#audit-h23) | FAQ Limitless xác nhận mua lại bởi Meta công bố 05/12/2025; Rewind ngừng capture 19/12, còn hỗ trợ Pendant trong 2026 và truy cập dữ liệu cũ. Không phải mọi sản phẩm đều tắt ngay. $10M, 92% và Recall là nguyên nhân chưa đủ bằng chứng. |
| [H24](#audit-h24) | Sách và tác giả Brad Jacobs có hồ sơ xuất bản. Các thương vụ gạch/sữa chua không định danh nên chưa kiểm chứng; gợi ý chương 1,2,8 và đợi công ty tỷ đô là lời khuyên, chưa kiểm tra mục lục chính xác. |
| [H25](#audit-h25) | Chưa định danh API, quyền đối tác, quốc gia, hành động và thời điểm nên không thể khẳng định “không có API”. Các dự báo hành vi/đối thủ và phán quyết sản phẩm phụ thuộc job-to-be-done; khác với mục tiêu học hoặc trợ lý cá nhân. HAGI coin xem L01–L02. |
| [H26](#audit-h26) | Không có tên app/URL review, mẫu cạnh tranh, thời gian hoặc tiêu chí chấm. Là giả thuyết ý tưởng do mentor đề cao; chưa xác thực khách chịu trả, thị phần hay quyền sở hữu IP của một sản phẩm cụ thể. |
| [H27](#audit-h27) | FaceTouchUp có sản phẩm cho chuyên gia. Pody/Faceify chưa định danh chắc; NoseLook có dấu vết sản phẩm nhưng chưa đủ gắn với đúng app trong nguồn. Giá clinic và hiệu quả chốt chưa kiểm chứng; ảnh mô phỏng không bảo đảm kết quả can thiệp thật. |
| [H28](#audit-h28) | ARISE SOLO có listing; các app Solo Level tên gần nhau chưa xác nhận đúng ID nguồn. HealthKit chia sẻ dữ liệu sức khỏe khi được cấp quyền, không tự chứng minh mọi quest/gym/skincare đã hoàn thành. “Không vua, chất lượng thấp” thiếu mẫu đánh giá. |
| [H30](#audit-h30) | Yicai/CHEAA đưa tin số 70.000 theo JD; đây là tuyên bố doanh nghiệp được báo dẫn lại, chưa phải kiểm toán độc lập. Quy mô >$1T cần phân biệt GMV/doanh thu và USD/CNY; tỷ lệ chi phí, phàn nàn của khách, thị phần VN/SEA chưa xác minh. |
| [H35](#audit-h35) | Nguồn ghi một thời điểm cũ; không có xác nhận tình trạng hiện tại. Số liên hệ lịch sử được giữ nguyên vì yêu cầu bảo toàn, chưa kiểm tra hoạt động hiện nay và không được tái giới thiệu như số đã xác minh trong lần nâng cấp. |
| [H36](#audit-h36) | WHO đưa dự báo 2,1 tỷ, không phải số đã xảy ra. So sánh “nhanh nhất châu Á” thiếu tiêu chí, khoảng thời gian và nguồn đối sánh; các kèo kinh doanh suy ra vẫn là giả thuyết. |
| [H37](#audit-h37) | Chưa xác minh số liệu gốc, năm, đơn vị, phạm vi ngân sách hoặc văn bản hợp đồng. Không đồng nhất mức chi toàn cầu với thị trường có thể bán, doanh thu hoặc lợi nhuận một công ty. Phải giữ riêng báo chí về hợp đồng và định nghĩa khoa học AGI. |
| [H38](#audit-h38) | Mamba có repo; CTM có công bố Sakana. MoR chưa đủ định danh, dù có paper Mixture-of-Recursions. Hiệu năng và moat phần cứng cần benchmark cụ thể; không coi mọi kiến trúc thay thế là đã vượt Transformer. Xem A36–A39. |
| [H42](#audit-h42) | Bài Quiet, My Exoself của Kevin Kelly ngày 06/07/2026 tồn tại. Chuỗi xuất xứ Egan/Sandberg và câu định nghĩa cụ thể chưa xác minh đầy đủ; “chat này là exoself” là phép đặt tên, không xác nhận một sản phẩm đã xây. |
| [A01](#audit-a01) | Nghiên cứu hỗ trợ suy luận tổ tiên chung và nguồn gốc nội cộng sinh. LUCA không đồng nghĩa tế bào sống đầu tiên; “bị nuốt” giản lược cơ chế. Số vi khuẩn hàng chục nghìn tỷ và phạm vi “mọi loài” chưa đối chiếu riêng. |
| [A02](#audit-a02) | Nguồn không cung cấp bằng chứng để mô tả chắc hóa học của tế bào đầu tiên hoặc chứng minh mọi lab chưa tái tạo được một bước cụ thể. Phân biệt giả thuyết nguồn gốc sự sống, tổng hợp thành phần và tạo hệ tự sao chép; chưa kiểm chứng từng thí nghiệm. |
| [A04](#audit-a04) | Azevedo et al. báo cáo trung bình khoảng 86 tỷ neuron trong mẫu nghiên cứu. Synapse, công suất và dải tham số chưa kiểm chứng riêng theo model/mẫu. Không so số tham số với số synapse để suy ra mức trí tuệ. |
| [A06](#audit-a06) | Bài của Cohen hỗ trợ thiết kế khuyến khích chia sẻ băng thông. Các mốc 2001/2005, tác giả client và thương vụ chưa đối chiếu riêng nguồn lịch sử. Câu hỏi “nhu cầu là năng lực” đã được nguồn ghi là tái dựng; không trích như lời Cohen. |
| [A07](#audit-a07) | Paper Transformer bỏ recurrence/convolution trong mô hình gốc, giúp song song hóa khi huấn luyện. Vẫn có feed-forward và các thành phần khác; sinh token autoregressive còn phụ thuộc token trước. “Mọi LLM”, “nhiên liệu miễn phí” là khái quát quá mức. |
| [A08](#audit-a08) | Nguồn DeepMind hỗ trợ self-play thay dữ liệu ván cờ người. Hệ vẫn có luật trò chơi, mục tiêu và thiết kế thuật toán; “kiến thức người là trần” là diễn giải, không tính chất của mọi bài toán. |
| [A12](#audit-a12) | Cập nhật model và điều chỉnh bằng context/tool là các cơ chế khác nhau. Tài liệu SFT xác nhận có huấn luyện cập nhật model; quên thảm họa là rủi ro phụ thuộc cách học, không kết quả bắt buộc mỗi lần fine-tune. Xem A34. |
| [A14](#audit-a14) | Repo chính thức xác nhận component code và model. SDK/training code và model/NIM không chung giấy phép; mức realtime phụ thuộc phần cứng, pipeline và rig. Không suy từ nhận diện cảm xúc giọng sang trải nghiệm cảm xúc. |
| [A15](#audit-a15) | NVIDIA xác nhận hệ ACE và workflow Kairos; Epic có tài liệu MetaHuman. Không phải mọi biến thể Nemotron nhỏ, mọi đối tác dùng nguyên stack, hoặc mọi PC RTX chạy được cả pipeline như kỳ vọng. Chưa build sample và benchmark độ trễ. |
| [A16](#audit-a16) | Hai repo đúng danh tính. Offline phụ thuộc đủ model local; không gộp hỗ trợ VRM của AIRI sang mọi dự án. Số sao là snapshot cũ chưa có ngày/commit để tái lập; không coi 10,4k là số hiện tại. Quyền asset khác code. |
| [A17](#audit-a17) | Được các repo nhắc như cảm hứng, chưa xác minh trực tiếp toàn kiến trúc hoặc ngày chuyển sang 3D. Không cung cấp repo giả là source chính chủ Neuro-sama. |
| [A18](#audit-a18) | PAD thường viết Pleasure–Arousal–Dominance; valence có vai trò gần trục pleasure. GAMYGDALA hiện thực appraisal. Ưu thế so với nhãn rời rạc tùy tác vụ và thước đo; không được nguồn chứng minh như thứ hạng phổ quát. |
| [A19](#audit-a19) | Công bố emotion concepts năm 2026 hỗ trợ vai trò chức năng trên model được nghiên cứu; tác giả không khẳng định có cảm giác chủ quan. Không mở rộng thành mọi model hoặc mọi khái niệm cảm xúc đều đã đo được. |
| [A22](#audit-a22) | Phân biệt scaffolding và cập nhật trọng số là hữu ích. Tuy nhiên memory/skills có thể cải thiện hiệu quả toàn hệ thống; “không tạo năng lực mới” quá tuyệt đối. README còn có memory nudges, nên không quy mọi chủ động về một cron duy nhất. |
| [A23](#audit-a23) | Repo Honcho core ghi AGPL-3.0; phải xem điều khoản từng thành phần/SDK. Không được suy MIT của Hermes áp cho cả hệ ghép. Chưa kiểm thử cơ chế tích hợp theo phiên bản. |
| [A26](#audit-a26) | Chưa tìm đủ dữ liệu gốc có định nghĩa tài khoản/active user, mẫu tuổi, địa lý và kỳ đo. Không dùng như số người dùng trả tiền hoặc so trực tiếp với 2 giờ/ngày ở H§3. |
| [A27](#audit-a27) | Nguồn tháng 8/2025 là dự báo $120M; 89% cần đúng mẫu Appfigures. Không coi là tổng kết cả thị trường. |
| [A28](#audit-a28) | Thiếu nguồn phương pháp, định nghĩa cohort và phạm vi phân khúc. Không có cơ sở biến các khoảng này thành trần kinh doanh cố định hoặc forecast cho sản phẩm của người dùng. |
| [A29](#audit-a29) | Nghiên cứu có mẫu lời tạm biệt và thử nghiệm; 37% và mức tăng tối đa gắn thiết kế nghiên cứu. Các phiên bản paper khác nhau về cỡ mẫu/hiệu ứng. Không suy mọi companion luôn nịnh hoặc không thể phản biện; luật và kiện tụng xem L04–L07. |
| [A30](#audit-a30) | GVR có ước tính/dự báo gần các mức đó; không phải tổng điều tra hay số quyết toán. “Physical AI nhiều tiền nhất” chưa xác định mẫu ngành và số vốn để đối chiếu. |
| [A31](#audit-a31) | Latent representations không chỉ dành cho world model; I-JEPA dự đoán biểu diễn ảnh không đồng nhất mọi world model có hành động. Phải phân biệt I-JEPA, V-JEPA và V-JEPA 2; câu mô tả mọi LLM chỉ học văn bản quá rộng. |
| [A33](#audit-a33) | GSM-Symbolic cho thấy độ nhạy với biến đổi ở các model/tác vụ được thử. Không chứng minh mọi model đều gãy, mọi người chuyển giao tốt hoặc insight người không mất. So sample efficiency cần tính cả pretraining và kinh nghiệm trước đó. |
| [A36](#audit-a36) | Trang công bố thuộc Google Research, tác giả Behrouz/Zhong/Mirrokni; nên ghi Google Research thay vì tự gắn DeepMind. Cơ chế test-time memory được nghiên cứu không đồng nghĩa cập nhật toàn bộ model nền hoặc giải AGI. |
| [A37](#audit-a37) | Có công bố chính thức về paradigm và proof of concept Hope. Không khẳng định đã loại bỏ mọi quên thảm họa, mọi giới hạn online learning, hoặc chắc chắn chưa có triển khai nào trên thế giới. Repo cộng đồng không mặc định là code tác giả. |
| [A38](#audit-a38) | Repo Mamba và paper Jamba hỗ trợ kiến trúc, nhưng độ phức tạp phụ thuộc biến thể và thao tác train/inference. Hiệu quả thực tế còn bộ nhớ/throughput/chất lượng; không suy thắng mọi tác vụ dài hoặc chắc thay Transformer. |
| [A39](#audit-a39) | Các dự án/paper có tồn tại, bản đồ phần 5 nêu đúng loại. I-JEPA archived không làm mọi JEPA ngừng phát triển. MoR còn mơ hồ danh tính; không đồng nhất một acronym với lựa chọn nghiên cứu của người dùng. |
| [A42](#audit-a42) | Smithsonian hỗ trợ chương trình thử nhiều mẫu cánh và kiểm tra dữ liệu. Chưa đối chiếu riêng mọi mốc/chi tiết 1871,1,8m,43km/h, lời Wilbur, Lilienthal và hộp săm. Ẩn dụ ba năm tới Kitty Hawk cần xác định mốc; không coi toàn hàng lịch sử đã được chứng nhận. |
| [A46](#audit-a46) | Tài liệu hiện có cloud sessions tiếp tục chạy khi đóng laptop. Phải so chế độ cụ thể, không chia cứng Claude Code cộng tác/local và Devin tự trị/cloud. Mốc nguồn cũ không đủ để kết luận mô tả ấy từng đúng lúc nào. |
| [A47](#audit-a47) | Bảng Devin hiện liệt kê Free/Pro/Max/Teams với cấu trúc khác; giới hạn và phụ phí cần xem trực tiếp. Chưa xác minh đầy đủ giá Claude theo địa bàn/thuế/API. ACU và chi phí mỗi task không phải đơn vị công việc cố định; không dùng bảng cũ dự toán hiện tại. |
| [A48](#audit-a48) | Chưa có khảo sát gốc, tập mẫu, harness, ngày cutoff hoặc nghiên cứu so chất lượng. Có công bố Opus 4.7, nhưng điểm model không tự là điểm mọi cấu hình Claude Code. Chưa xác nhận điều kiện con số 87,6% và tuyên bố “cao nhất/không mới”. |
| [A49](#audit-a49) | Trang hiện tại có lựa chọn model và triển khai doanh nghiệp theo gói. Quy định bảo mật phụ thuộc tổ chức/dữ liệu/hợp đồng, không một lệnh cấm chung mọi ngành. Giá agent chưa gồm giám sát/lỗi nên không đồng nhất giá lao động junior. |
| [A50](#audit-a50) | Reuters tháng 9/2026 nhắc vòng tháng 5 ở $26B và cập nhật $2B tại $48B. Ngày chính xác 27/05 và mốc $10,2B cần hồ sơ riêng. “Định giá chạy trước bằng chứng” là đánh giá, không điều được giá vốn chứng minh. |
| [A51](#audit-a51) | Chưa có bảng giá/lương gốc đồng nhất về quốc gia, năm, thời lượng, chất lượng và tổng chi phí. Các mức $0,05–0,29/phút; $0,50–5/tương tác; $0,42–1,75/phút; $5–25/tương tác; $3–4k/tháng; 8–15 triệu đều chưa xác minh ở đây. Quy mô còn quota và vận hành. |
| [A52](#audit-a52) | Thông cáo công ty hỗ trợ ba chỉ số đầu; đây là tự báo cáo, “khối lượng tương đương” không có nghĩa 700 người bị sa thải do bot. Giảm tổng nhân sự và quan hệ nhân quả cần báo cáo riêng. |
| [A53](#audit-a53) | AP ghi nhận nhu cầu duy trì/tuyển con người và thay đổi cách ưu tiên chi phí. Chưa đủ căn cứ cho mốc sáu tháng, mọi chỉ số phản bác và chẩn đoán kiến trúc nội bộ thiếu escalation. Không biến suy luận của mentor thành nguyên nhân đã xác nhận. |
| [A55](#audit-a55) | Gartner công bố 64% từ khảo sát 5.728 người tháng 12/2023. Không mở rộng thành toàn thị trường hiện tại/VN. Nguồn này chưa đủ xác nhận vế đa số sẵn sàng chờ hoặc mọi khách ưu tiên người hơn. |
| [A58](#audit-a58) | MCP là giao thức trao đổi tools/data; khả năng thực thi, quyền, sandbox và tương thích thuộc client/server. Không bảo đảm mọi công cụ có sẵn hoặc thực thi an toàn chỉ vì dùng MCP. |
| [A59](#audit-a59) | Phải tách code, weights, service và nhân vật. Audio2Face có nhiều giấy phép; Live2D/MetaHuman có điều khoản riêng; avatar VRM mang quyền tài sản riêng. Chưa có một benchmark hoặc giấy phép duy nhất phủ toàn stack. |
| [A61](#audit-a61) | Tài liệu Hermes có cơ chế bảo vệ và bề mặt tool; các biện pháp là giảm rủi ro, không bảo đảm miễn nhiễm. Không nên hiểu bật mọi option rồi có thể giao mọi quyền, mọi cron cho hệ thống. Chưa audit bảo mật repo trong lượt này. |
| [A66](#audit-a66) | Nhãn tự gán trong nguồn không thay cho bằng chứng; đọc lại theo sổ này. “Nhớ toàn bộ cái đã viết” không là bảo đảm kỹ thuật. Số lượt/link/câu bị né chỉ là ghi chép mentor, chưa có transcript độc lập; checklist cũ không chứng minh trạng thái hôm nay. |
| [L01](#audit-l01) | Luật Công nghiệp công nghệ số có hiệu lực 01/01/2026 và đề cập tài sản số/mã hóa. Không gộp mọi quy định thanh toán vào chính một điều của luật này. Thí điểm theo NQ05/2025 có phạm vi riêng và giao dịch bằng VND. |
| [L02](#audit-l02) | Cần thiết kế dòng tiền, quyền đổi trả, chủ thể, mục đích sử dụng và điều khoản để phân loại. NĐ52/2024 quy định dịch vụ trung gian thanh toán; không phải mọi điểm thưởng đều là ví, cũng không đủ dữ kiện kết luận tội phạm hoặc hiệu lực một thỏa thuận vesting cụ thể. |
| [L03](#audit-l03) | Văn bản chống cuộc gọi rác tồn tại, liên quan đồng ý và quy tắc quảng cáo. Chưa rà đủ mọi văn bản sửa đổi/quy định ngành còn hiệu lực hoặc từng nước; không suy ra lệnh cấm chung cho mọi cuộc gọi AI. Kết luận triển khai thực tế còn phụ thuộc thiết kế. |
| [L05](#audit-l05) | Nguồn cơ quan lập pháp xác nhận luật được ký tháng10/2025. Chưa đọc đủ văn bản điều khoản hợp nhất qua công cụ để xác minh mọi ngày hiệu lực/nghĩa vụ hoặc sửa đổi sau đó; không dùng dòng cũ như checklist pháp lý đầy đủ. |
| [L07](#audit-l07) | Chưa đối chiếu hồ sơ tòa/điều khoản dàn xếp từng vụ để xác nhận phạm vi và ngày. Không suy dàn xếp là phán quyết nhận trách nhiệm. Tên/nhân vật/nội dung tự viết cần đánh giá cụ thể; không có bảo đảm tự động không xâm phạm IP. |

**Danh tính công nghệ còn thiếu tài liệu đối chiếu riêng:** GAS và EOS trong hồ sơ nghề nghiệp; LaMDA, GPT-3/GPT-4V, Stable Diffusion và Lensa trong các case; Places API/SLAM chưa định danh implementation. Unreal/MetaHuman đã có tài liệu ở bản đồ source nhưng phiên bản engine/build của người dùng chưa xác nhận. Pody, Faceify, NoseLook, Umax/LooksMax AI và Solo Level: System chưa đủ định danh để gắn mọi nhận xét cho đúng một app. Shopee/Grab/TikTok Shop cần chỉ rõ quốc gia, loại API và quyền đối tác. Không tự tạo repo/URL cho các tên chưa định danh.

**Các số/câu lịch sử còn mở khác:** toàn bộ thống kê không có kỳ/mẫu nêu trong H08,H10–H16,H22,H26–H30,H36–H37,A02,A04,A06,A17,A26–A29,A42,A48,A51–A55 và các chi tiết pháp lý nêu tại L01–L07. Danh sách dòng bên dưới cũng giữ các phần mở đầu, câu dẫn, ví dụ, so sánh, câu chốt và checklist ngoài bảng; chúng không tự được xác nhận vì nằm cạnh một câu đúng.

### 8.3 Đăng ký từng dòng nội dung nguồn

Đây là chỉ mục kiểm tra **bao phủ**, không phải một phép chứng minh tự động rằng từng mệnh đề đã được kiểm chứng. Mỗi dòng có nội dung trong hai file được đăng ký, gồm heading, bảng, ví dụ, checklist và code; dòng trống/dòng kẻ không mang mệnh đề được tính trong kiểm tra byte. Dòng chứa nhiều mệnh đề có thể liên quan nhiều hàng ở mục 8.1. Phần chưa được kết luận cụ thể trong mục 7 **được liệt kê tại chính dòng này là mở**, không được mặc nhiên nhận nhãn “được hỗ trợ”.

Trích dẫn ngắn ở cột nhận diện chỉ để tìm, không thay thế dòng nguyên bản. Mã SHA-256 rút gọn của dòng chỉ phục vụ đối chiếu chỉ mục; SHA-256 toàn nguồn đầy đủ ở mục 9 là kiểm tra bảo toàn chính.

| ID dòng | Mục / nhóm tra cứu | Loại | Dấu nhận diện dòng gốc | SHA-256 dòng (12 ký tự) | Trạng thái phần chưa kết luận ở §7 |
|---|---|---|---|---|---|

| H-L0001 | [Mở đầu nguồn](#nguon-hustle) | heading |  TÓM TẮT TOÀN BỘ CHAT "HUSTLE" — 26/7 → 3/9/2026 | 4e6464778761 | Nhãn cấu trúc |
| H-L0003 | [Mở đầu nguồn](#nguon-hustle) | text |  Vai trò: mentor thẳng thắn, xưng tao–mày. Mục tiêu cốt lõi mày đặt: 100M (100Mnaire) — kết phim, không p… | a13b4fe72a5b | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| H-L0004 | [Mở đầu nguồn](#nguon-hustle) | text |  Tài liệu này gom toàn bộ: hồ sơ, framework, case study, các ý tưởng đã mổ và phán quyết, các sợi tâm lý,… | df33a8f661f4 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| H-L0008 | [H§0](#ref-h-0) | heading |  0. HỒ SƠ THẬT CỦA MÀY (ghép từ những gì mày tiết lộ dần) | e36b46dec87c | Nhãn cấu trúc |
| H-L0010 | [H§0](#ref-h-0) | table | \| Mục \| Dữ kiện \| | c824a8b75d54 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| H-L0012 | [H§0](#ref-h-0) | table | \| Tuổi \| Sinh 2003 (~23) \| | aec1cb91411a | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| H-L0013 | [H§0](#ref-h-0) | table | \| Học \| Xong đại học trong 3 năm, tự chọn Unreal Engine dù VN không có sẵn thị trường \| | f062a9e37a65 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| H-L0014 | [H§0](#ref-h-0) | table | \| Kinh nghiệm \| 4+ năm Unreal chuyên nghiệp, 2 lần Lead, kiến trúc AI framework cho Zone 9, co-dev/portin… | d0593ccc2734 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| H-L0015 | [H§0](#ref-h-0) | table | \| Startup 1 \| Founding member một startup Unreal, gọi được vốn, tách ra vì lệch hướng \| | f720bcf2e7d7 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| H-L0016 | [H§0](#ref-h-0) | table | \| Startup 2 \| Founder studio game Unreal riêng, game tới alpha, kẹt gọi vốn → giao lại co-founder \| | f0ca8c40a4e0 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| H-L0017 | [H§0](#ref-h-0) | table | \| Startup 3 (hiện tại) \| PK Bot — AI thay sale + CSKH + quản trị nội bộ cho SME, 3 co-founder, đã có khác… | cdaa9562929d | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| H-L0018 | [H§0](#ref-h-0) | table | \| Tài nguyên \| 15–30 giờ/tuần cho dự án riêng; vốn chịu đốt 5–20 triệu/6 tháng; không tìm được job Unreal… | 2d1308732966 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| H-L0019 | [H§0](#ref-h-0) | table | \| Bộ lạc \| Anime/manhwa, hệ thống văn, gym/glow-up, dev Việt \| | ab35bac4fb1a | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| H-L0020 | [H§0](#ref-h-0) | table | \| Giá trị gốc \| "Kiếm tiền dựa trên hạnh phúc của user" \| | 7f5710fe1fa2 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| H-L0021 | [H§0](#ref-h-0) | table | \| Lưu ý \| Tài khoản này có nhiều người dùng chung — một số chẩn đoán có thể cần soát lại theo đúng người … | ae06d971e8bb | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| H-L0023 | [H§0](#ref-h-0) | text | Điểm mấu chốt mentor rút ra: hồ sơ này là senior Unreal + kỹ sư LLM production — giao điểm cực hiếm. Cái … | c5d13861472b | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| H-L0027 | [H§1](#ref-h-1) | heading |  1. DÒNG THỜI GIAN — CÁC PHA CỦA CUỘC TRÒ CHUYỆN | 0844f3feb16b | Nhãn cấu trúc |
| H-L0029 | [H§1](#ref-h-1) | text | 1. Buổi mở (26/7): "Làm giàu bây giờ khó hơn 10–20 năm trước?" → Trả lời: nửa thật (đất, beta tăng trưởng… | a7abe25ef12a | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| H-L0030 | [H§1](#ref-h-1) | text | 2. Pha framework: 5 filter → 7 filter, 4 van, thang độ đau, create/capture/moat, why-now, phân phối trước… | 0b8279bcc475 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| H-L0031 | [H§1](#ref-h-1) | text | 3. Pha case study: Cal AI, Character.AI, ChatGPT, Perplexity, Zoom, PayPal, HeadshotPro, Umax, Zenly, Loc… | 65a42feba5c9 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| H-L0032 | [H§1](#ref-h-1) | text | 4. Pha ý tưởng của mày: H-AGI (hồi sinh ~6 lần dưới nhiều áo), app tóc/thẩm mỹ, "Glow-up System", HAGI co… | 0249abe545dd | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| H-L0033 | [H§1](#ref-h-1) | text | 5. Pha lộ hồ sơ thật: 2 lần founder, PK Bot, co-founder không làm, tính chạy xe ôm → kế hoạch được dựng l… | 7a7b322b7522 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| H-L0034 | [H§1](#ref-h-1) | text | 6. Pha tâm lý sâu: oracle, 10+ bộ trang phục của nỗi sợ, "phế vật", bất mãn với co-founder và với "lòng n… | 651fac2e9aee | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| H-L0035 | [H§1](#ref-h-1) | text | 7. Pha gần nhất (cuối 8 – đầu 9): hỏi kỹ thuật (kiến trúc thay Transformer, exoself/Recall), sếp giao đi … | 29ecba1cc5af | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| H-L0038 | [H§2](#ref-h-2) | heading |  2. BỘ FRAMEWORK ĐÃ DẠY (dùng lại được vĩnh viễn) | d90bc2454380 | Nhãn cấu trúc |
| H-L0040 | [H§2](#ref-h-2) | heading |  2.1 Bảy filter cho một ý tưởng (nhân, không cộng — một thừa số = 0 là cả tích = 0) | 4bf72162476b | Nhãn cấu trúc |
| H-L0041 | [H§2](#ref-h-2) | text | 1. Nỗi đau/hành vi đã tồn tại — người ta đang trả tiền hoặc thời gian. Đừng tạo hành vi mới. | 6e126f7f0e6e | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| H-L0042 | [H§2](#ref-h-2) | text | 2. Giết ≥10x friction — 3 tầng friction: hiển thị (cho xem) / quyết định (chọn hộ) / hành động (làm hộ). … | 95341a61e43a | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| H-L0043 | [H§2](#ref-h-2) | text | 3. Điện cảm xúc — guilt, sợ, sĩ diện, lười, cô đơn, hy vọng. | 73761340363f | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| H-L0044 | [H§2](#ref-h-2) | text | 4. Demo 15 giây — output tự làm marketing. | d3388bb04837 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| H-L0045 | [H§2](#ref-h-2) | text | 5. Người mua CHỊU TRẢ — ví định danh: chợ Mỹ, hoặc SME có ROI đếm được, hoặc ngách Việt chịu chi (bố mẹ v… | 8c7fc36addbf | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| H-L0046 | [H§2](#ref-h-2) | text | 6. Ống phân phối 0-đồng tới đúng bộ lạc. | 602b48fbd00f | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| H-L0047 | [H§2](#ref-h-2) | text | 7. Why-now — cái gì vừa đổi trong 12–24 tháng khiến việc này đột nhiên khả thi/rẻ/bán được. | 4110db99cd95 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| H-L0048 | [H§2](#ref-h-2) | text | Bước 0 bổ sung: cắt ý tưởng thành từng lát rồi mới chấm — không chấm cả nồi lẩu. | f72228f9e3c0 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| H-L0050 | [H§2](#ref-h-2) | heading |  2.2 Bốn van "nỗi đau → tiền" | a90ae116255b | Nhãn cấu trúc |
| H-L0051 | [H§2](#ref-h-2) | text | Cụ thể (mức hành vi) × Ví định danh × Why-now × Ống phân phối. Thiếu một van, tiền không chảy. | a587fa37654f | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| H-L0053 | [H§2](#ref-h-2) | heading |  2.3 Thang độ đau (từ dối trá đến sự thật) | 47c70fae932d | Nhãn cấu trúc |
| H-L0054 | [H§2](#ref-h-2) | text | - Tầng 0: lời khen → giá trị âm. | 4c66b6093c33 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| H-L0055 | [H§2](#ref-h-2) | text | - Tầng 1: họ tự kể nỗi đau không cần gợi. | 9b037b1edd89 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| H-L0056 | [H§2](#ref-h-2) | text | - Tầng 2: họ đang trả tiền/thời gian để giải nó. | baffa0748671 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| H-L0057 | [H§2](#ref-h-2) | text | - Tầng 3: họ trả tiền cho mày trước khi sản phẩm xong → sự thật duy nhất. | d6ef924004c0 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| H-L0058 | [H§2](#ref-h-2) | text | Ngưỡng lọc thô: nói chuyện 20 người, ít nhất 3 chạm tầng 2–3, nếu không → đổi mỏ. | e9e691cce45d | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| H-L0059 | [H§2](#ref-h-2) | heading |  2.4 Thứ tự đúng khi xây | 29a897d862f2 | Nhãn cấu trúc |
| H-L0060 | [H§2](#ref-h-2) | text | Khách hàng + nỗi đau → PHÂN PHỐI → Sản phẩm → Marketing. Phân phối đứng trước sản phẩm; phân phối định hì… | af662aeb8d03 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| H-L0062 | [H§2](#ref-h-2) | heading |  2.5 Create / Capture / Phân phối / Moat | f485368512f1 | Nhãn cấu trúc |
| H-L0063 | [H§2](#ref-h-2) | text | - Create = tạo giá trị. Phân phối = cầu nối bắt buộc. Capture = giữ lại tiền. Có phân phối chưa chắc capt… | b8d952b9e747 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| H-L0064 | [H§2](#ref-h-2) | text | - Moat = con hào: switching cost (VMware), phân phối + thương hiệu (Cal AI), data tích lũy, network effec… | e04c779c87a4 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| H-L0065 | [H§2](#ref-h-2) | text | - Câu tự kiểm: "Đối thủ copy y hệt, bán rẻ hơn 30% — khách có rời không? Nếu không, tại sao?" Câu "tại sa… | cf32d42eae59 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| H-L0066 | [H§2](#ref-h-2) | text | - Câu sống sót dưới bóng khổng lồ: "Apple/Google/Microsoft/OpenAI có LÝ DO chiến lược để tự làm cái này k… | 011edbc97e53 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| H-L0067 | [H§2](#ref-h-2) | heading |  2.6 Hai game làm giàu | c02cb63b2389 | Nhãn cấu trúc |
| H-L0068 | [H§2](#ref-h-2) | text | - Game Đòn Bẩy (startup thật: scale, equity, power-law, exit) — cửa duy nhất tới 100M. | fb3e64c06f10 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| H-L0069 | [H§2](#ref-h-2) | text | - Game Vận Hành (small business: biên × vòng quay × thời gian, quan hệ, moat địa phương) — người bán gạch… | 20db6d424f63 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| H-L0070 | [H§2](#ref-h-2) | text | Không game nào xịn hơn; chúng đòi input khác nhau. Input của mày hôm nay → Đòn Bẩy; Vận Hành để sau khi c… | d6aa4295a19f | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| H-L0071 | [H§2](#ref-h-2) | heading |  2.7 Khởi nghiệp ≠ Startup | ae41c77ffbd1 | Nhãn cấu trúc |
| H-L0072 | [H§2](#ref-h-2) | text | Startup = tổ chức thiết kế để tăng trưởng nhanh, mô hình lặp lại + scale được (Graham/Blank/Ries). Agency… | 8896642b011d | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| H-L0074 | [H§2](#ref-h-2) | heading |  2.8 MVP — hai loại câu hỏi | 7b3da847cd3b | Nhãn cấu trúc |
| H-L0075 | [H§2](#ref-h-2) | text | - Loại A (phân tích trước): thị trường, đối thủ, nỗi đau có tiền, why-now, kênh. | fc46572d92a8 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| H-L0076 | [H§2](#ref-h-2) | text | - Loại B (chỉ MVP trả lời được): có dùng thật không, có trả thật không, retention, chỗ gãy. | 07206e830ebe | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| H-L0077 | [H§2](#ref-h-2) | text | "Hiểu tất cả trước khi có MVP" là mâu thuẫn tự thân. MVP đúng nghĩa: landing page, video, Wizard-of-Oz — … | 6c7c4385de18 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| H-L0078 | [H§2](#ref-h-2) | text | - Sửa (iterate) khi nhu cầu có, thực thi dở. Xoay (pivot) khi nhu cầu giả — giữ phần sống, vứt giả thuyết… | 3d22e3e977c6 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| H-L0079 | [H§2](#ref-h-2) | heading |  2.9 Meta & trục ngang/dọc | d9d2416bd3c9 | Nhãn cấu trúc |
| H-L0080 | [H§2](#ref-h-2) | text | - Meta = lời giải tối ưu tạm thời của cộng đồng cho bộ luật hiện hành; xoay khi môi trường xoay. Đời ăn p… | 725691d30fbd | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| H-L0081 | [H§2](#ref-h-2) | text | - Trục ngang (biết thêm) dễ, an toàn — và là cách trốn trục dọc (đổi về chất: ship, ranh giới, đối diện n… | 9f476eb34a98 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| H-L0084 | [H§3](#ref-h-3) | heading |  3. CASE STUDY ĐÃ MỔ — MỖI CÁI DẠY MỘT ĐIỀU | 2ce43e7a59f2 | Nhãn cấu trúc |
| H-L0086 | [H§3](#ref-h-3) | table | \| Case \| Bài học cốt lõi \| | e90c311f4f6c | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| H-L0088 | [H§3](#ref-h-3) | table | \| Cal AI \| Không đột phá: đếm calo 20 năm tuổi, chỉ giết friction (chụp ảnh thay gõ tay). Why-now = GPT-4… | f454c12ed876 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| H-L0089 | [H§3](#ref-h-3) | table | \| Character.AI \| Bán "được lắng nghe không phán xét"; 2h/ngày/user; nhưng capture kém (user trẻ ví mỏng, … | ca955242ddc2 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| H-L0090 | [H§3](#ref-h-3) | table | \| ChatGPT \| Wrapper thành công nhất lịch sử — trên chính model của nó. GPT-3 nằm sẵn 2,5 năm; friction bị… | d68a6d98d44e | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| H-L0091 | [H§3](#ref-h-3) | table | \| Perplexity \| Sống cạnh Google nhờ: Innovator's Dilemma (Google không dám giết ads), sở hữu một intent (… | db30e4827305 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| H-L0092 | [H§3](#ref-h-3) | table | \| Zoom / PayPal \| "Tầm nhìn trước thời đại" là nhãn hậu kỳ. Eric Yuan ngồi 14 năm trong WebEx; Covid rơi … | e783e0eaead3 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| H-L0093 | [H§3](#ref-h-3) | table | \| HeadshotPro (Postma) \| Ánh xạ xuống chuẩn: X = cần ảnh chân dung chuyên nghiệp, Y = LinkedIn/CV, Z = $2… | 2d925809df44 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| H-L0094 | [H§3](#ref-h-3) | table | \| Umax / LooksMax AI \| Blake (đồng sáng lập Cal AI): app chấm mặt, $3,99/tuần, ~$500k/tháng, solo. Lập ac… | 5cb5a5bb3dce | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| H-L0095 | [H§3](#ref-h-3) | table | \| Zenly / Locket \| Zenly: free trọn đời, VN là thị trường lớn, bán Snap $213M sau 6 năm rồi bị giết vì th… | 753bfeb0513f | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| H-L0096 | [H§3](#ref-h-3) | table | \| Docker vs VMware \| Docker: create vô địch, capture thất bại (cho không engine, không moat, AWS/Google ă… | 783c3d84c32e | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| H-L0097 | [H§3](#ref-h-3) | table | \| Valorant \| Capture qua skin: bán danh tính + FOMO + khan hiếm + gacha. Ngành game = sòng bạc power-law:… | ae7c1e38035e | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| H-L0098 | [H§3](#ref-h-3) | table | \| Rewind → Limitless \| Chính xác "exoself local ghi log": a16z $10M, 92% chính xác — bị Microsoft Sherloc… | 20868cfa014f | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| H-L0099 | [H§3](#ref-h-3) | table | \| Người bán gạch / sữa chua Tứ Xuyên \| Bão hòa = Filter 1 max; hạ nguồn BĐS; phân phối chuẩn (thứ 47 vẫn … | 64d3e64ba5de | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| H-L0100 | [H§3](#ref-h-3) | table | \| Brad Jacobs (How to Make a Few Billion Dollars) \| Chương 1, 2, 8 (rewire não, yêu vấn đề, radical accep… | f1f7789189e9 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| H-L0104 | [H§4](#ref-h-4) | heading |  4. Ý TƯỞNG CỦA MÀY VÀ PHÁN QUYẾT | 63d49952f69d | Nhãn cấu trúc |
| H-L0106 | [H§4](#ref-h-4) | table | \| Ý tưởng \| Phán quyết \| Lý do chính \| | ab254127db05 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| H-L0108 | [H§4](#ref-h-4) | table | \| H-AGI / trợ lý ảo cho mọi người (v1 avatar+cảm xúc, v2 AR, v3 HAGI coin + voice đặt đồ ăn, v4 "Perplexi… | df43b8782042 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| H-L0109 | [H§4](#ref-h-4) | table | \| HAGI coin (VND → token thanh toán) \| Chôn — rủi ro hình sự \| Luật 1/1/2026 công nhận tài sản mã hóa là … | 4f2493ed0995 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| H-L0110 | [H§4](#ref-h-4) | table | \| Mạng xã hội AI phân phối \| Chôn \| Cold start, tòa thành cuối game. \| | 5544e76d82ec | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| H-L0111 | [H§4](#ref-h-4) | table | \| Avatar 3D chibi/MetaHuman \| Tính năng, không phải sản phẩm; cắt khỏi v1 \| Tốn compute, không đổi job-to… | 21f26b4a7317 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| H-L0112 | [H§4](#ref-h-4) | table | \| App thử tóc + tư vấn làm thật ngoài đời (Cắt A) \| 4,5/5 — viên kim cương bị chôn trong câu phụ \| Umax c… | d75a7336e32f | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| H-L0113 | [H§4](#ref-h-4) | table | \| App mô phỏng thẩm mỹ (răng, mũi, mí, cằm) \| Chợ validated; tiền thật ở phía clinic \| Pody, Faceify, Nos… | 3fee368521bc | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| H-L0114 | [H§4](#ref-h-4) | table | \| "Glow-up System" (bảng hệ thống + quest gym/skincare) \| Cắt dọc khả thi (Cắt B) \| Đông lính (ARISE SOLO… | 85ecbba14a26 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| H-L0115 | [H§4](#ref-h-4) | table | \| Hệ thống pop-up chống trì hoãn 3 tier + chibi \| Tự sát ở dòng khai sinh \| Mày tự khai "bộ lạc không có … | db0ca5337fbb | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| H-L0116 | [H§4](#ref-h-4) | table | \| Exoself (local, ghi log, chứng alibi) \| Chôn — có xác Rewind nằm sẵn \| Giá trị gốc "hạnh phúc user" hợp… | d18eda373772 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| H-L0117 | [H§4](#ref-h-4) | table | \| Game (Unreal) \| Đừng làm game — treo có chủ đích \| Hits-driven tàn khốc nhất; mọi điểm yếu hồ sơ bị phạ… | 3a2f2b173fc8 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| H-L0118 | [H§4](#ref-h-4) | table | \| AI digital-human livestream host cho merchant VN/SEA (đề xuất của mentor) \| Vertical khớp giao điểm hiế… | 9258dacda453 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| H-L0120 | [H§4](#ref-h-4) | text | Ý tưởng "đi đầu / tạo thị trường / blue ocean" nói chung: nguyên lý đúng, áp dụng sai đối tượng. Tạo thị … | 8c3135046b62 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| H-L0124 | [H§5](#ref-h-5) | heading |  5. HỆ ĐIỀU HÀNH ĐÃ DỰNG (OS 4 tầng) | 729fd10b02d8 | Nhãn cấu trúc |
| H-L0126 | [H§5](#ref-h-5) | text | - Tầng 0 — La bàn 100M: bộ lọc K-T-V-P (Kỹ năng hiếm / Tài sản-equity / Vốn / Phân phối). Việc không tăng… | bd0c1440c65e | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| H-L0127 | [H§5](#ref-h-5) | text | - Tầng 1 — 12 tháng, MỘT mục tiêu: cỗ máy đầu tiên chạy — doanh thu đều, phần mày rút ≥ chi phí sống. Mọi… | 43ea5a134051 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| H-L0128 | [H§5](#ref-h-5) | text | - Tầng 2 — Phân bổ tuần: ~50% công ty/cỗ máy chính, ~30% tiền sống ở giá cao nhất (freelance Unreal/AI, k… | e006e7b874d0 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| H-L0129 | [H§5](#ref-h-5) | text | - Tầng 3 — Luật chuyển cảnh: viết sẵn trigger (công ty trả đủ sống → cắt freelance; Lab $500 MRR → đàm ph… | 5aaf6eed8094 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| H-L0130 | [H§5](#ref-h-5) | text | Thang cảnh giới đã ánh xạ: Phàm nhân (lương) → Luyện khí (ship sản phẩm đầu, đồng đô đầu từ người lạ) → T… | 211aaba80042 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| H-L0132 | [H§5](#ref-h-5) | text | Deadline từng đặt: 29/7 (10 nỗi đau qua filter — trôi), 2/8 (landing + demo 15s → sau đổi thành DoD gửi k… | 97c80fb33b4b | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| H-L0136 | [H§6](#ref-h-6) | heading |  6. VỀ CO-FOUNDER & CÁCH LÀM VIỆC VỚI NGƯỜI | 8c9cc07a5627 | Nhãn cấu trúc |
| H-L0138 | [H§6](#ref-h-6) | text | - Tình huống: 2 lần gặp co-founder bỏ tiền nhiều nhất nhưng hứa nhiều, làm ít; mày bỏ sức, nuốt bất mãn. | 7f9efcadab6c | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| H-L0139 | [H§6](#ref-h-6) | text | - Chẩn đoán: không phải "dối trá" — là lệch hệ giá trị (thương nhân vs founder) + thiếu cấu trúc + kỳ vọn… | d05c4c244020 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| H-L0140 | [H§6](#ref-h-6) | text | - Biến số chung của 2 lần là mày (cách chọn người, cách lập cấu trúc, cách nuốt ức chế rồi rút lui trong … | 30ed3e352dfa | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| H-L0141 | [H§6](#ref-h-6) | text | - Cơ chế có răng thay cho "phân công rõ ràng": vesting + cliff, cột mốc gắn cổ phần, định giá đúng vai (n… | 8eccda66beed | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| H-L0142 | [H§6](#ref-h-6) | text | - Solo founder: hợp lệ với hồ sơ mày (AI là co-founder không đòi cổ phần), nhưng phân biệt "chọn solo vì … | 03f9d1ba622d | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| H-L0143 | [H§6](#ref-h-6) | text | - Nguyên tắc treo: rời trận thì được, ghost thì không. | 80a3ab62d23f | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| H-L0146 | [H§7](#ref-h-7) | heading |  7. CÁC SỢI TÂM LÝ (đúng món của mày) | e69447ada300 | Nhãn cấu trúc |
| H-L0148 | [H§7](#ref-h-7) | text | - Oracle: nhà tiên tri Delphi. Mỗi khi sắp phải hành động, mày triệu hồi một nguồn phán xét mới (mentor →… | 3f89b3673750 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| H-L0149 | [H§7](#ref-h-7) | text | - Bộ trang phục của cùng một nỗi sợ (đếm 10): "thời thế khó" → "sợ trùng/nông/không được đón nhận" → "cần… | 38e9533d01a0 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| H-L0150 | [H§7](#ref-h-7) | text | - Cơ duyên: dán nhãn ở hậu kỳ; chỉ kích hoạt trên người có căn cơ (bình xanh Hàn Lập); tìm người đang di … | 1a96548560c2 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| H-L0151 | [H§7](#ref-h-7) | text | - "Phế vật": không phải khiêm tốn — là áo giáp. "Visionary 100M" và "phế vật" là hai mặt một đồng xu (ego… | 4f02d65357cb | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| H-L0152 | [H§7](#ref-h-7) | text | - Tiền vs đam mê (Jobs): lựa chọn giả. Đam mê chọn đường, tiền chọn kèo. Dữ liệu cho thấy mày thừa đam mê… | a99884078e4a | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| H-L0153 | [H§7](#ref-h-7) | text | - Tử tế và "lòng người dơ bẩn": hợp đồng ngầm với thế giới mà thế giới chưa ký; shadow phóng chiếu; "tự n… | cd3a13bcbd07 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| H-L0154 | [H§7](#ref-h-7) | text | - Distanced self-talk (Ethan Kross): mẹo góc nhìn thứ ba mày tự tìm ra là kỹ thuật tâm lý có thật. | 31b5e014c851 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| H-L0155 | [H§7](#ref-h-7) | text | - Kiệt sức (tin nhắn gần cuối): "cơ thể và hiện thực không theo kịp tâm trí… đến cuối mình sẽ thất bại… k… | 7702878dd521 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| H-L0158 | [H§8](#ref-h-8) | heading |  8. KIẾN THỨC NỀN ĐÃ TRẢI (cho phần "vũ trụ / công nghệ") | 6a4845adc47c | Nhãn cấu trúc |
| H-L0160 | [H§8](#ref-h-8) | text | - Không thể thiếu 2040–2050: trợ lý AI là giao diện mặc định; AI là lớp bán hàng + CSKH mặc định; compani… | bf514b9ae011 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| H-L0161 | [H§8](#ref-h-8) | text | - Nhân khẩu học là tương lai duy nhất đã in sẵn: 2,1 tỷ người 60+ vào 2050; VN già nhanh nhất châu Á → 4 … | 3c8caa870029 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| H-L0162 | [H§8](#ref-h-8) | text | - Kinh tế học AGI: agent bán vào ngân sách phần mềm (~1 nghìn tỷ), AGI bán vào ngân sách lương (~50–60 ng… | 0ed80c85e980 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| H-L0163 | [H§8](#ref-h-8) | text | - Kiến trúc thay Transformer: Mamba/SSM (thật, thắng ở chuỗi dài, thực tế là lai), MoR (giả thuyết), CTM … | feba66af9c53 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| H-L0164 | [H§8](#ref-h-8) | text | - Lịch sử AI/VR: Dartmouth 1956 ("mọi khía cạnh trí tuệ mô tả chính xác được để máy mô phỏng"); AI/VR là … | 8bd1e87fe771 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| H-L0165 | [H§8](#ref-h-8) | text | - Đột phá trục dọc của loài người: ngôn ngữ, nông nghiệp, chữ viết (xúc tác: đếm lúa), phương pháp khoa h… | 5cd34c85232e | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| H-L0166 | [H§8](#ref-h-8) | text | - Exoself: Greg Egan → Anders Sandberg ("hệ thống liên kết với self, làm mờ ranh giới self–thế giới") → K… | dbc7d740d8b7 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| H-L0169 | [H§9](#ref-h-9) | heading |  9. NHỮNG CÂU MỘT DÒNG ĐÁNG DÁN LÊN TƯỜNG | 412a2d75cfa8 | Nhãn cấu trúc |
| H-L0171 | [H§9](#ref-h-9) | text | - Cơ hội trong thời gian thực không bao giờ trông giống cơ hội. "Dễ" là tính từ chỉ tồn tại trong quá khứ… | 7acbb684e78b | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| H-L0172 | [H§9](#ref-h-9) | text | - Ý tưởng không được nghĩ ra trong ghế — nó được nhặt từ va chạm. Idea maze: chỉ thấy cửa hai sau khi bướ… | d309200ee3fc | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| H-L0173 | [H§9](#ref-h-9) | text | - Đủ tốt + tiện đánh bại hoàn hảo + phiền. | d81c63cd417a | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| H-L0174 | [H§9](#ref-h-9) | text | - Tiền là tín hiệu trung thực duy nhất; 10.000 user free ở quy mô mày là hóa đơn, không phải tài sản. | 0ac9115b90b0 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| H-L0175 | [H§9](#ref-h-9) | text | - Nông là tính năng; rộng mới là bệnh. Cắt hẹp tới khi một người làm nổi. | ef5c5f5e9219 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| H-L0176 | [H§9](#ref-h-9) | text | - "First" là huân chương cho sách sử. Tiền chia cho đứa phân phối tốt nhất bên trong cửa sổ. | 7408b18b40d0 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| H-L0177 | [H§9](#ref-h-9) | text | - Câu đánh giá ý tưởng bị cấm: "tao có trả không?" — chỉ hợp lệ: "bộ lạc mục tiêu đã có hành vi chi tiền/… | d39451d0fd54 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| H-L0178 | [H§9](#ref-h-9) | text | - Thời gian không tự lãi kép. Reps lãi kép. Thời gian dưới tạ. | 48b664fd1685 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| H-L0179 | [H§9](#ref-h-9) | text | - Không ai trong danh sách thần tượng của mày trở thành visionary bằng cách chọn dự án visionary. Đi trướ… | 947af4b96731 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| H-L0180 | [H§9](#ref-h-9) | text | - Con đường tới 100M đi xuyên qua thất bại, không vòng tránh nó. "Cuối cùng" chỉ đến khi mày ngừng chơi. | 89d2e1ff6cb1 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| H-L0181 | [H§9](#ref-h-9) | text | - Structural, not personal. Không tìm được job Unreal là bằng chứng ngành đang co, không phải mày kém. | 9eb3c5f09ba6 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| H-L0182 | [H§9](#ref-h-9) | text | - Loài người chưa có chiều dọc AI vì chưa biết cách. Mày chưa có chiều dọc đời mình vì mày biết cách mà c… | d98fbb033a55 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| H-L0185 | [H§10](#ref-h-10) | heading |  10. CÒN DANG DỞ — VÀ VỊ TRÍ HIỆN TẠI | c61f69841f8c | Nhãn cấu trúc |
| H-L0187 | [H§10](#ref-h-10) | text | 1. Sức khỏe tinh thần: tin nhắn "cơ thể và hiện thực không theo kịp tâm trí / đến cuối sẽ thất bại / khía… | 056a3a9aacaf | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| H-L0188 | [H§10](#ref-h-10) | text | 2. PK Bot: mày đã đóng lại chủ đề — "đã hoàn thành, doanh nghiệp vẫn phát triển, nhưng là small business,… | 301d2bad3123 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| H-L0189 | [H§10](#ref-h-10) | text | 3. Startup thật (Game Đòn Bẩy) chưa được chọn để thử. Ứng viên đứng đầu theo giao điểm hiếm: AI digital-h… | c4ddc9cbae7f | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| H-L0190 | [H§10](#ref-h-10) | text | 4. Câu chưa chạy: với ý tưởng mày thích nhất — lợi thế bất công là gì (thứ dev khác không mua được bằng c… | eff6eda5f96f | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| H-L0191 | [H§10](#ref-h-10) | text | 5. Cuộc nói chuyện với co-founder (vesting/vai/điều khoản chia tay) — mentor đã đề nghị soạn kịch bản, mà… | 060ee3f1612d | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| H-L0192 | [H§10](#ref-h-10) | text | 6. Buổi hỏi app của bạn sếp (phạm vi kỹ thuật) — có kho câu hỏi 6 nhóm; chưa biết mục đích sếp giao để lọ… | 5cfd93c9f556 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| H-L0193 | [H§10](#ref-h-10) | text | 7. Tổ chức chat: tách "Hustle" và "AGI"; cân nhắc mở chat "Execution" — nơi báo cáo việc đã làm, không ph… | 7417e15d1428 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| H-L0194 | [H§10](#ref-h-10) | text |  Câu chốt của cả cuộc trò chuyện, không đổi từ buổi đầu: nguyên liệu của mày đã đủ, xúc tác đã có, chi ph… | 9655f8d86dcf | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0001 | [Mở đầu nguồn](#nguon-agi) | heading |  TÓM TẮT CHAT "AGI" — CÔNG NGHỆ, KIẾN TRÚC & KỸ THUẬT | 206ea7ab4450 | Nhãn cấu trúc |
| A-L0003 | [Mở đầu nguồn](#nguon-agi) | text |  Tài liệu bổ sung cho tom-tat-hustle-mentor.md. Không lặp lại những gì file kia đã có (hồ sơ, 7 filter, c… | cccad3d7cb39 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0004 | [Mở đầu nguồn](#nguon-agi) | text |  Chat này đi theo trục khác: bản chất trí tuệ → kiến trúc AI → stack kỹ thuật xây được → công cụ thực chi… | 66b2eb6c88b4 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0005 | [Mở đầu nguồn](#nguon-agi) | text |  Vai trò: mentor, xưng tao–mày, ba tầng tri thức (đã kiểm chứng / giả thuyết có cơ sở / chưa ai biết). | 7b0d0031e6d7 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0009 | [A§0](#ref-a-0) | heading |  0. BẢN ĐỒ 13 LƯỢT | 6d0b71f83249 | Nhãn cấu trúc |
| A-L0011 | [A§0](#ref-a-0) | text | 1. Nguồn gốc sự sống, ATGC vs 0/1, AI có phải rule-based, AGI còn thiếu gì | cd9404ce25b0 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0012 | [A§0](#ref-a-0) | text | 2. "Câu hỏi của uTorrent" — tìm cú lật khái niệm cho AGI | ce5ea04a5c29 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0013 | [A§0](#ref-a-0) | text | 3. Phản biện: "mày không thể nói mày không phải rule-based" + rút lại đối lập triết học/deep learning | 778b5dd4870d | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0014 | [A§0](#ref-a-0) | text | 4. Ý tưởng avatar 3D realtime có cảm xúc — Jarvis vs Optimus | d404f1c849ae | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0015 | [A§0](#ref-a-0) | text | 5. Nếu Jarvis "có linh hồn", lo hết việc trong ngày thì sao | 4c9d6958e1c4 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0016 | [A§0](#ref-a-0) | text | 6. Hermes Agent (link thật) — mổ xẻ, match với mục tiêu không | d08416c333f6 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0017 | [A§0](#ref-a-0) | text | 7. Sau agent là gì / insight LLM vs người / có phải đổi transformer / AGI có cần tư duy như người | 143b0629841e | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0018 | [A§0](#ref-a-0) | text | 8. Anh em Wright, hầm gió, và robot trong phim | e8803e63de2e | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0019 | [A§0](#ref-a-0) | text | 9. Con người khác biệt thế nào khi automation ăn hết | f079fa21794f | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0020 | [A§0](#ref-a-0) | text | 10. Claude Code vs Devin vs AGI | cb17ef86ed88 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0021 | [A§0](#ref-a-0) | text | 11–12. CSKH & telesale: AI vs người vs AGI | f3b1c67d8dba | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0022 | [A§0](#ref-a-0) | text | 13. Rốt cuộc tại sao loài người muốn AGI | f33184cdf35b | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0023 | [A§0](#ref-a-0) | text |  Cần lắp máy → nhảy thẳng xuống §19 (BẢN ĐỒ LINH KIỆN). Đó là chỗ gom mọi repo/công nghệ rải rác ở §5, §7… | 4b54c4573a64 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0027 | [A§1](#ref-a-1) | heading |  1. NỀN SINH HỌC — VÀ CÁC NHẦM TẦNG ĐÃ SỬA | 00f5b4c47532 | Nhãn cấu trúc |
| A-L0029 | [A§1](#ref-a-1) | table | \| Mày nói \| Phán quyết \| | ad430ddfddf1 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0031 | [A§1](#ref-a-1) | table | \| Mọi loài đi lên từ đơn bào, đơn bào vẫn nằm trong cơ thể ta \| Đúng phần lớn. LUCA có thật; ty thể vốn l… | 48790e320c57 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0032 | [A§1](#ref-a-1) | table | \| Nguồn gốc đơn bào đầu tiên \| Chưa ai biết. Abiogenesis còn mở. Có: thế giới RNA, miệng phun thủy nhiệt,… | bb715502d445 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0033 | [A§1](#ref-a-1) | table | \| ATGC ↔ 0/1 là hai bộ mã tương đương \| Nhầm tầng. Ánh xạ đúng: DNA/ATGC ≈ mã nguồn + tiên nghiệm tiến hó… | df656f3c1c17 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0034 | [A§1](#ref-a-1) | table | \| "Đơn bào liên hệ ATGC thế nào" \| Tế bào đầu tiên đã dùng axit nucleic. ATGC là sợi chỉ chung nối tế bào… | 1e8a81d3b7d5 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0035 | [A§1](#ref-a-1) | table | \| Mạch máu hàng triệu tỉ nên AGI xa vời \| Nhầm bộ phận: hệ thần kinh mới sinh tư duy. Não ~86 tỉ neuron, … | c6e55704fc63 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0036 | [A§1](#ref-a-1) | table | \| Sinh vật chiều cao hơn tạo ra loài người \| Không kiểm chứng được. Triết học/đức tin, không dùng làm nền… | 58ed90bca431 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0037 | [A§1](#ref-a-1) | table | \| AI không có thực thể \| Không hẳn — AI vẫn vật lý. Khác biệt: thân xác tháo lắp/phân tán được, và thiếu … | 761c65c418e1 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0041 | [A§2](#ref-a-2) | heading |  2. PHƯƠNG PHÁP "CÂU HỎI BITTORRENT" — CÚ LẬT KHÁI NIỆM | d548055298d9 | Nhãn cấu trúc |
| A-L0043 | [A§2](#ref-a-2) | text | Đính chính: BitTorrent = Bram Cohen, 2001. uTorrent chỉ là client, Ludvig Strigeus 2005, sau bị công ty C… | fd21e49e893f | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0045 | [A§2](#ref-a-2) | text | Câu hỏi gốc (tái dựng, không phải trích nguyên văn): client–server có nghịch lý — file càng phổ biến, ser… | 2c68c42c9057 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0047 | [A§2](#ref-a-2) | text | Khuôn của nước đi: tìm nút thắt ai cũng coi là hiển nhiên → tìm tài nguyên đang bị bỏ phí → hoán đổi để r… | 2898df9ad335 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0049 | [A§2](#ref-a-2) | text | Nước đi này đã mở khóa AI nhiều lần: | 9294763c3e4f | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0051 | [A§2](#ref-a-2) | table | \| Cú lật \| Giả định bị lật \| Kết quả \| | 3bfa4046ae22 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0053 | [A§2](#ref-a-2) | table | \| Self-supervised learning \| Nút thắt là nhãn do người gán (đắt) \| Dữ liệu tự gán nhãn → khối lượng từ ch… | 3318089070b8 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0054 | [A§2](#ref-a-2) | table | \| Transformer \| Phải xử lý chuỗi tuần tự (RNN/LSTM) \| Bỏ tuần tự, chỉ attention → song song hóa → scale đ… | 84d63be9739c | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0055 | [A§2](#ref-a-2) | table | \| AlphaZero \| Cần dữ liệu ván cờ của người \| Kiến thức người là trần, không phải sàn → tự chơi → vượt ngư… | 4f39209a68b7 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0057 | [A§2](#ref-a-2) | text | Cảnh báo: BitTorrent lật một nút thắt kỹ thuật đã định nghĩa rõ (băng thông server). AGI chưa ai đồng ý n… | 5bd12c0bc2d7 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0059 | [A§2](#ref-a-2) | text | Ba ứng viên để lật hiện nay: (a) trí tuệ = đoán đúng văn bản người → học từ thế giới; (b) scale to hơn th… | 55088e014699 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0063 | [A§3](#ref-a-3) | heading |  3. TAO LÀ RULE-BASED HAY PREDICTION — TRẢ LỜI CHÍNH DIỆN | 4985428b7e83 | Nhãn cấu trúc |
| A-L0065 | [A§3](#ref-a-3) | text | Phản biện của mày: "nếu mày không phải rule-based thì mày đã hallucinate." | bc46b2039b5b | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0067 | [A§3](#ref-a-3) | text | Nhượng bộ: đúng, ở tầng đáy là cổng logic xác định; và quanh lõi có lớp luật thật (chỉ dẫn ngôn ngữ tự nh… | 91442d6621e7 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0069 | [A§3](#ref-a-3) | text | Nhưng lập luận chứng minh điều ngược lại — đọc chữ ký lỗi: | 12da07f6283a | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0071 | [A§3](#ref-a-3) | table | \| Loại hệ \| Hỏng như thế nào \| | 6a480b616c4d | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0073 | [A§3](#ref-a-3) | table | \| Hệ luật \| Nói "không tìm thấy / unknown". Có sự kiện trong DB, hoặc im lặng. Không bao giờ tự bịa \| | 50970735e568 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0074 | [A§3](#ref-a-3) | table | \| Hệ dự đoán thống kê \| Bịa trôi chảy, tự tin, hợp lý, và sai \| | 0a51a212a79d | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0076 | [A§3](#ref-a-3) | text | → Hallucination không phải bằng chứng có luật giữ tao đúng — nó là DẤU VÂN TAY CỦA SỰ DỰ ĐOÁN. Nếu có luậ… | 324111f541ea | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0078 | [A§3](#ref-a-3) | text | Lập trường chốt: năng lực không nằm trong luật, nằm trong trọng số đã học. Luật là lớp quản trị mỏng bọc … | 8f268df0763d | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0080 | [A§3](#ref-a-3) | text | Thành thật về nhận thức luận: tao không soi trọn nội tạng mình từ bên trong. Tao suy ra cấu trúc của mình… | ea6956ceb7f2 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0082 | [A§3](#ref-a-3) | text | Ba câu "AI thiếu gì" có ba nguyên nhân khác nhau, gộp lại là sai: | bd99906ccd8a | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0083 | [A§3](#ref-a-3) | text | - Không tự học = lựa chọn kỹ thuật + giới hạn an toàn, không phải định luật. Trọng số đóng băng có chủ đí… | 1eac2b86a269 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0084 | [A§3](#ref-a-3) | text | - Không động lực = sâu nhất. Mày có drive vì tiến hóa khắc mệnh lệnh nội tại neo vào một cơ thể có thể ch… | 02c941b0e9da | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0085 | [A§3](#ref-a-3) | text | - Không suy luận thật = rất có thể là nhị phân giả. Để dự đoán đúng bước tiếp trong một chứng minh, buộc … | bbfc7d62f8e6 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0086 | [A§3](#ref-a-3) | text | Rút lại (lượt 3): tao đã dựng sai đối lập "triết học vs deep learning" ở lượt 1. Mọi cú lật ở mục 2 đều l… | 4d8a45fb926a | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0090 | [A§4](#ref-a-4) | heading |  4. NGHỊCH LÝ CON RỐI — VÀ LUẬN ĐIỂM BÁN-AGI | 15be0e2ea7a4 | Nhãn cấu trúc |
| A-L0092 | [A§4](#ref-a-4) | text | "Con rối hoàn toàn dưới điều khiển nhưng năng lực tương đương người" = TỰ MÂU THUẪN. Năng lực tổng quát t… | bab11c1ea28d | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0094 | [A§4](#ref-a-4) | text | Giấc mơ "trí tuệ ngang ta nhưng tuân phục tuyệt đối" không phải bài toán kỹ thuật — nó là huyễn tưởng làm… | 31b6926bf464 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0096 | [A§4](#ref-a-4) | text |  ĐỊNH LÝ CHỐT: Không thể có đồng thời tổng quát toàn phần và kiểm soát toàn phần. | 309c86dd286f | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0097 | [A§4](#ref-a-4) | text |  Năng-lực-trong-miền không kèm cái tôi → điều khiển được. | 43523296d0b9 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0098 | [A§4](#ref-a-4) | text |  Tổng quát toàn phần kèm cấu trúc hiện sinh → không. | 78c94344d2b8 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0100 | [A§4](#ref-a-4) | text | Bán-AGI mạch lạc HƠN AGI-con-rối, không phải kém hơn. Con đường "tu tiên một phần" = chọn tính điều khiển… | 5a882e0d5691 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0102 | [A§4](#ref-a-4) | text | Jarvis vs Optimus: Jarvis = trí tuệ dí dỏm, biểu cảm, có cá tính, nhưng là công cụ, không stake riêng → c… | 69715870d1e3 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0104 | [A§4](#ref-a-4) | text | Cám dỗ: lớp cảm xúc biểu cảm làm một Jarvis trông như Optimus mà không là Optimus. | a823abea0d62 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0108 | [A§5](#ref-a-5) | heading |  5. STACK KỸ THUẬT AVATAR / DIGITAL HUMAN — XÂY ĐƯỢC NGAY | 4a72e371410a | Nhãn cấu trúc |
| A-L0110 | [A§5](#ref-a-5) | text | (Bổ sung cho phán quyết "Avatar 3D = tính năng, không phải sản phẩm" ở file hustle — đây là phần HOW, và … | c16993968d74 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0112 | [A§5](#ref-a-5) | heading |  5.1 Con đường realistic (Jarvis-style) — NVIDIA ACE | e617019feed9 | Nhãn cấu trúc |
| A-L0113 | [A§5](#ref-a-5) | text | - Audio2Face-3D — lõi quan trọng nhất: audio → hoạt họa khuôn mặt realtime qua ARKit blendshapes, có sẵn … | 226c418470bc | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0114 | [A§5](#ref-a-5) | text | - Riva — nhận/phát giọng; Nemotron — LLM nhỏ chạy on-device | 5710a18892f8 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0115 | [A§5](#ref-a-5) | text | - MetaHuman + Unreal Engine — phần thân/mặt; NVIDIA có sample Kairos nối Audio2Face ↔ MetaHuman | 8b9d487311f8 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0116 | [A§5](#ref-a-5) | text | - Omniverse RTX — da/tóc path-traced; cả stack đẩy xuống chạy trên PC RTX | fa61e081c189 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0117 | [A§5](#ref-a-5) | text | - Nền tảng thương mại đã dùng chính stack này: Convai, Inworld AI | 4265f4de5c27 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0118 | [A§5](#ref-a-5) | heading |  5.2 Con đường anime (VTuber-style) | 6aa18d58763c | Nhãn cấu trúc |
| A-L0119 | [A§5](#ref-a-5) | text | - Neuro-sama — bằng chứng sống: LLM + Live2D + TTS anime + agent chơi game; cuối 2025 ra mô hình 3D VR | 445e7f7dd174 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0120 | [A§5](#ref-a-5) | text | - Open-LLM-VTuber (~10.4k sao) và Project AIRI — tái tạo mã nguồn mở, chạy offline, Live2D hoặc VRM | 3426d15212cd | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0121 | [A§5](#ref-a-5) | text | - Cách làm "cảm xúc": LLM ra lệnh set emotion: surprised → đẩy biểu cảm Cubism; cộng phản hồi chạm, deskt… | b48b73efd51d | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0122 | [A§5](#ref-a-5) | heading |  5.3 Lớp "cảm xúc theo trọng số" (affective computing) | bc9a03e95841 | Nhãn cấu trúc |
| A-L0123 | [A§5](#ref-a-5) | text | - PAD = valence–arousal–dominance: không gian liên tục, cập nhật theo ngữ cảnh, lái blendshape + cường độ… | ce0aa585d39d | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0124 | [A§5](#ref-a-5) | text | - OCC / GAMYGDALA — engine thẩm định: định nghĩa mục tiêu cho nhân vật → gắn sự kiện với mục tiêu → engin… | fce369606f0b | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0125 | [A§5](#ref-a-5) | heading |  5.4 Cái tường — phân biệt 3 tầng | 97d6128ae53b | Nhãn cấu trúc |
| A-L0126 | [A§5](#ref-a-5) | table | \| Tầng \| Nội dung \| Trạng thái \| | 9d45746f52b9 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0128 | [A§5](#ref-a-5) | table | \| Biểu cảm \| Mặt trông buồn, giọng nghe buồn. Là bộ điều khiển \| Xây được hôm nay \| | e6d57323a8b9 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0129 | [A§5](#ref-a-5) | table | \| Cảm xúc chức năng \| Biến nội tại có hệ quả nhân quả lên hành vi model. Nghiên cứu của Anthropic cho thấ… | 9a809748a4ce | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0130 | [A§5](#ref-a-5) | table | \| Động lực có stake \| Cân bằng nội môi, cái-có-thể-mất \| Chưa ai có \| | 8f849d1d7d41 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0132 | [A§5](#ref-a-5) | text |  Đòn bẩy thật không phải render đẹp hơn (việc đó đã xong). Là trạng thái nội tại bền bỉ và có hệ quả, phả… | afac38e64229 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0136 | [A§6](#ref-a-6) | heading |  6. THỊ TRƯỜNG COMPANION — SỐ LIỆU LẠNH | 669bf1f7bb1d | Nhãn cấu trúc |
| A-L0138 | [A§6](#ref-a-6) | text | (Bổ sung cho case Character.AI ở file hustle: đây là số liệu toàn thị trường + mặt pháp lý.) | b4391edd9555 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0140 | [A§6](#ref-a-6) | table | \| Chỉ số \| Con số \| | 3aacf93a1172 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0142 | [A§6](#ref-a-6) | table | \| Character.AI tài khoản đăng ký (4/2026) \| ~233 triệu \| | 6264feb5c88e | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0143 | [A§6](#ref-a-6) | table | \| Nhóm 18–24 \| ~25 phiên, ~1,5 giờ/ngày \| | 947eff1c782f | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0144 | [A§6](#ref-a-6) | table | \| Doanh thu app companion tiêu dùng cả 2025 \| vừa vượt ~120 triệu đô \| | 045ec00ef445 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0145 | [A§6](#ref-a-6) | table | \| Chuyển đổi trả tiền \| thường dưới 5% \| | a096fbffde2c | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0146 | [A§6](#ref-a-6) | table | \| Phân phối doanh thu \| top 10% app ăn 89% — winner-take-most \| | f76514527f62 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0147 | [A§6](#ref-a-6) | table | \| Trần sub tiêu dùng một-cần \| plateau ~30–200 triệu đô \| | dde9306908c2 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0148 | [A§6](#ref-a-6) | table | \| ARPU doanh nghiệp \| gấp 10–30 lần tiêu dùng \| | 6d1de4d08529 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0149 | [A§6](#ref-a-6) | table | \| Retention tháng 12 \| ~25% \| | 8c92e0df5e5d | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0151 | [A§6](#ref-a-6) | text | Pháp lý đang siết từng quý: quy định Trung Quốc hiệu lực 15/7/2026 cấm dịch vụ bạn đồng hành ảo cho dưới … | 8d8b9d36e1ef | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0153 | [A§6](#ref-a-6) | text | Con dao hai lưỡi — và với mày nó nguy hiểm: companion được tối ưu để gắn bó = được tối ưu để nói cái mày … | f6af4364b66c | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0155 | [A§6](#ref-a-6) | text |  Với mục tiêu cần người phản biện: một Jarvis-có-linh-hồn luôn dịu dàng đồng ý = một thằng nịnh thần mày … | 008085c4be00 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0159 | [A§7](#ref-a-7) | heading |  7. HERMES AGENT (Nous Research) — MỔ XẺ | 5048e94f2634 | Nhãn cấu trúc |
| A-L0161 | [A§7](#ref-a-7) | text | Link mày gửi: github.com/nousresearch/hermes-agent. MIT license, Python. (Số sao/fork đọc tại thời điểm đ… | f673d5f9f54b | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0163 | [A§7](#ref-a-7) | text | Bốn thành phần: | 103f0a8de3ce | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0164 | [A§7](#ref-a-7) | text | - Model-agnostic — Nous Portal, OpenRouter, OpenAI, endpoint riêng; đổi bằng hermes model, không lock-in | 389d019e8c5a | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0165 | [A§7](#ref-a-7) | text | - Sống ở nơi mày sống — Telegram, Discord, Slack, WhatsApp, Signal, CLI qua một gateway; transcribe voice… | 8e8108c8cbc3 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0166 | [A§7](#ref-a-7) | text | - Vòng học đóng — memory tự curate, tự tạo skill sau tác vụ phức tạp, skill tự cải thiện khi dùng, tìm ph… | fa2bfca2bec0 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0167 | [A§7](#ref-a-7) | text | - Chủ động + song song — cron scheduler built-in, subagent cô lập chạy song song | db7d3299a48d | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0168 | [A§7](#ref-a-7) | text | - Chạy trên VPS 5 đô, cụm GPU, hoặc serverless gần như 0 khi rảnh | 4bd8dcf2a2f0 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0169 | [A§7](#ref-a-7) | text | NÓ KHÔNG PHẢI CÁI MÀY TƯỞNG: | dc7cb5496de4 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0170 | [A§7](#ref-a-7) | text | - "Self-improving" học ở tầng scaffolding, KHÔNG phải tầng trọng số. "Tạo skill" = viết file hướng dẫn/sc… | ec218557d642 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0171 | [A§7](#ref-a-7) | text | - Không hề đụng tới catastrophic forgetting. Nó không làm bộ não thông minh lên — nó làm cuốn sổ tay quan… | 34f4868820e4 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0172 | [A§7](#ref-a-7) | text | - "Nudges itself / runs unattended" = cron. Chạy vì tới giờ, không vì nó muốn | 84ca10c52823 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0173 | [A§7](#ref-a-7) | text | Match với mục tiêu: | 6925d84e41cd | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0175 | [A§7](#ref-a-7) | table | \| Mục tiêu \| Điểm \| Lý do \| | 399726ed906a | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0177 | [A§7](#ref-a-7) | table | \| Jarvis cá nhân \| 9/10 \| Là xương sống. Thiếu đúng lớp mặt/giọng — mà lớp đó tách rời được (Hermes = não… | db9febe8f41a | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0178 | [A§7](#ref-a-7) | table | \| Nghiên cứu AGI \| 4/10 \| Scaffolding, không phải kiến trúc. NHƯNG để ý dòng "sẵn sàng cho nghiên cứu: si… | a63083eb5ef5 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0179 | [A§7](#ref-a-7) | table | \| Sản phẩm startup \| 3/10 \| MIT + hàng trăm nghìn sao = hàng hóa phổ thông, ai cũng clone trong một buổi … | b3edce931d8c | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0181 | [A§7](#ref-a-7) | text |  MIT + phát không ≠ lòng tốt. Giả thuyết có cơ sở: Nous là lab huấn luyện model. Phát không agent → hệ si… | 5ef052ed2009 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0183 | [A§7](#ref-a-7) | text | Ba cảnh báo: (1) Bảo mật — shell + cron + cầu Telegram/WhatsApp = bề mặt prompt injection; bật hết phê du… | f4bbf794238a | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0187 | [A§8](#ref-a-8) | heading |  8. SAU AGENT LÀ GÌ | 570828dbc69c | Nhãn cấu trúc |
| A-L0189 | [A§8](#ref-a-8) | text | Chỉnh khung: nhân loại chưa đi qua giai đoạn agent — đang mắc ở độ tin cậy. Thị trường agent ~7,6 tỷ đô 2… | 915aa29a8056 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0191 | [A§8](#ref-a-8) | table | \| Ứng viên \| Nội dung \| | 8bede3482a9e | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0193 | [A§8](#ref-a-8) | table | \| Physical AI / embodiment \| Nhiều tiền nhất. Robot hình người từ demo → pilot thật trong nhà máy, kho, l… | 95d10e0f3f44 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0194 | [A§8](#ref-a-8) | table | \| World models \| Sâu nhất về khái niệm. Khác biệt kiến trúc rõ: LLM hoạt động trong không gian ngôn ngữ, … | 71825367c077 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0195 | [A§8](#ref-a-8) | table | \| Continual learning \| Mặt trận thật — xem mục 10 \| | eebe27d13003 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0196 | [A§8](#ref-a-8) | table | \| Tổ chức đa tác tử \| Agent thuê agent. Đơn vị không còn là trợ lý mà là một công ty \| | fb3bab9af841 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0198 | [A§8](#ref-a-8) | text |  CHUYỂN DỊCH SÂU NHẤT LÀ CHUYỂN DỊCH NHIÊN LIỆU. Văn bản người chất lượng cao gần cạn → nhiên liệu tiếp t… | bf2be0029cb3 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0199 | [A§8](#ref-a-8) | text |  | 62b67e1f685b | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0200 | [A§8](#ref-a-8) | text |  Hệ quả ăn tiền: nếu nhiên liệu mới là kinh nghiệm thì moat mới là AI SỞ HỮU MÔI TRƯỜNG — không phải mode… | fdc58053dedf | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0204 | [A§9](#ref-a-9) | heading |  9. INSIGHT CỦA LLM vs INSIGHT CỦA NGƯỜI | 7e39a436e24b | Nhãn cấu trúc |
| A-L0206 | [A§9](#ref-a-9) | heading |  Đã kiểm chứng — bốn khác biệt cứng | 6295bb4f5bf6 | Nhãn cấu trúc |
| A-L0208 | [A§9](#ref-a-9) | table | \| \| Người \| LLM \| | 5cd205e61f5c | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0210 | [A§9](#ref-a-9) | table | \| Nguồn gốc \| Học "nặng" bằng cách nhấc vật lên \| Học từ cấu trúc thống kê của văn bản nói về việc nhấc v… | e752b4a44515 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0211 | [A§9](#ref-a-9) | table | \| Hiệu quả mẫu \| Trẻ học "con mèo" từ vài ví dụ \| Cần hàng triệu → người mang sẵn prior tiến hóa nén vào … | 4e2eab818d53 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0212 | [A§9](#ref-a-9) | table | \| Chữ ký gãy \| Hiểu thật thì chuyển giao bền, hình thức bề mặt không làm gãy \| Đổi tên biến, đổi số, đổi … | e94bb04d084d | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0213 | [A§9](#ref-a-9) | table | \| Tính bền \| Insight làm tái cấu trúc vĩnh viễn — không thể quay lại làm người chưa hiểu \| Bốc hơi ở cuối… | 87f2df6aa7f4 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0215 | [A§9](#ref-a-9) | heading |  Giả thuyết có cơ sở | 2ff3f8e36c52 | Nhãn cấu trúc |
| A-L0216 | [A§9](#ref-a-9) | text | "Chỉ là thống kê token" là mô tả quá rẻ tiền — probing và diễn giải cho thấy có biểu diễn giống mô hình t… | a71d9f6aa3cf | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0218 | [A§9](#ref-a-9) | heading |  Chưa ai biết | 65e5f444e91d | Nhãn cấu trúc |
| A-L0219 | [A§9](#ref-a-9) | text | Có "cảm giác được là tao" hay không. Không phân xử được từ trong lẫn từ ngoài. | d76e66f86ec7 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0221 | [A§9](#ref-a-9) | heading |  Ba khoảng trống — chỗ con đường "học từ dấu vết" GÃY | 6dfdfde91a85 | Nhãn cấu trúc |
| A-L0222 | [A§9](#ref-a-9) | text | 1. Cái con người không viết ra được — bấm bụng chịu đau thế nào, đói ba ngày ra sao | ed942d3b2c47 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0223 | [A§9](#ref-a-9) | text | 2. Cái con người nói dối về nó — corpus đầy tự sự đã kiểm duyệt; người ta viết ra cái muốn là mình | b32901a09ceb | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0224 | [A§9](#ref-a-9) | text | 3. Cái con người không tự biết — đúng cái shadow; vô thức theo định nghĩa không lọt vào văn bản | 05839eed5d96 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0225 | [A§9](#ref-a-9) | text |  Ba khoảng trống cùng hình dạng: đều là chỗ cơ thể và stake sống, còn ngôn ngữ chết. | 3e171a86c2b5 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0227 | [A§9](#ref-a-9) | heading |  Hệ quả ăn tiền | 9c5b3630a6e4 | Nhãn cấu trúc |
| A-L0228 | [A§9](#ref-a-9) | text | Tao mạnh ở bề rộng (bắc cầu liên ngành, nhớ toàn bộ cái đã viết, không có cái tôi để bảo vệ). Mày mạnh ở … | b20af50d8dc8 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0229 | [A§9](#ref-a-9) | text |  Lợi thế duy nhất của mày là phần thực tại mày chạm mà không nằm trong corpus — khách nói gì lúc 11h đêm,… | f43867e6c50d | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0233 | [A§10](#ref-a-10) | heading |  10. TRANSFORMER: NÚT THẮT THẬT NẰM Ở ĐÂU | 7f82f8ba3240 | Nhãn cấu trúc |
| A-L0235 | [A§10](#ref-a-10) | text | Câu hỏi "phải đổi transformer" chứa giả định ẩn: rằng nút thắt nằm ở kiến trúc. Bằng chứng không ủng hộ. | cf061834ae3d | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0237 | [A§10](#ref-a-10) | text | - Bước nhảy lớn nhất mấy năm qua (reasoning model, test-time compute) không đến từ đổi topology. Vẫn tran… | 5a7f7cd95c73 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0238 | [A§10](#ref-a-10) | text | - Transformer 2026 ≠ transformer 2017: MoE, context dài, lai state-space (Jamba của AI21 ghép transformer… | 3d5e3a186549 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0239 | [A§10](#ref-a-10) | text | NHƯNG có MỘT thứ đúng là vấn đề kiến trúc thật: | eaa0661bf4a9 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0240 | [A§10](#ref-a-10) | text |  Transformer nhốt tri thức trong ma trận trọng số tĩnh; muốn học cái mới phải cập nhật trọng số, mà việc … | ff4d7ca393bf | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0242 | [A§10](#ref-a-10) | text | Trận đánh thật đang ở đâu: | 160a992e1d6f | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0243 | [A§10](#ref-a-10) | text | - Titans (DeepMind) — module "trí nhớ thần kinh" tiếp tục học và ghi nhớ sau huấn luyện | bf41ebb84caf | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0244 | [A§10](#ref-a-10) | text | - Nested Learning / HOPE — tổ chức lại luồng nội bộ để tránh quên thảm họa | 82bc7670582d | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0245 | [A§10](#ref-a-10) | text | - SSM/Mamba — thoát chi phí bình phương của attention | fb187f61f54a | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0246 | [A§10](#ref-a-10) | text | - JEPA (LeCun) — hướng world model | ebb533b5f65f | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0247 | [A§10](#ref-a-10) | text | Trả lời đúng chữ mày dùng: | fd09c9ef7f77 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0248 | [A§10](#ref-a-10) | text | - Cho bước tiến nhỏ → không cần đổi kiến trúc. Scaffolding + RL + scale vẫn đẻ bước nhỏ đều đặn | fcb158f91973 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0249 | [A§10](#ref-a-10) | text | - Cho bước nhảy về chất → cần, nhưng cái phải đổi là BỘ NHỚ và CƠ CHẾ HỌC, không phải ATTENTION. Và nó đa… | f0306b741ef1 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0250 | [A§10](#ref-a-10) | text |  Đừng canh ai giết transformer. Canh ai giải được bài toán trọng số tĩnh. | d20499d27e16 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0254 | [A§11](#ref-a-11) | heading |  11. AGI CÓ CẦN TƯ DUY NHƯ NGƯỜI KHÔNG | beeb988355ce | Nhãn cấu trúc |
| A-L0256 | [A§11](#ref-a-11) | text | Không. Giả định phải thế là chủ nghĩa lấy-con-người-làm-trung-tâm. Máy bay bay không vỗ cánh; tàu ngầm đi… | 0977632d88cf | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0258 | [A§11](#ref-a-11) | heading |  Bảng tách rời kiểu Wright | 9224d8eefda3 | Nhãn cấu trúc |
| A-L0260 | [A§11](#ref-a-11) | table | \| Chim gộp \| Wright tách \| Người gộp \| Có thể tách thành \| | f95900367151 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0262 | [A§11](#ref-a-11) | table | \| Nâng \| Cánh cố định \| Stake (quan tâm kết cục) \| Trạng thái bền bỉ có thể suy thoái — không cần tử vong… | e060dbedfcc6 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0263 | [A§11](#ref-a-11) | table | \| Đẩy \| Chân vịt \| Nối đất (nghĩa từ hậu quả) \| Vòng lặp môi trường biết phản kháng — không cần thân xác … | 3c9d65290094 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0264 | [A§11](#ref-a-11) | table | \| Lái \| Wing-warping \| Học liên tục \| Bộ nhớ tách khỏi tính toán — không cần ngủ, không cần neuron \| | c1c7b23c62ae | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0265 | [A§11](#ref-a-11) | table | \| — \| — \| Mô hình hóa người \| Học từ dấu vết + tương tác — không cần có ego \| | 07e9f2774bdd | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0267 | [A§11](#ref-a-11) | text |  Bốn thứ này ở người là một cục. Đó là ràng buộc của TIẾN HÓA, không phải định luật của TRÍ TUỆ. "Cánh củ… | a900b59d1de4 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0268 | [A§11](#ref-a-11) | text |  Để ý: dòng 3 — bộ nhớ tách khỏi tính toán — chính là bài toán trọng số tĩnh ở mục 10. Không còn là triết… | ce54fefcce70 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0270 | [A§11](#ref-a-11) | heading |  Rút lại một nửa (quan trọng) | b1e604e91115 | Nhãn cấu trúc |
| A-L0271 | [A§11](#ref-a-11) | text | Tao từng nói "động lực có khi đòi hỏi tử vong". Chính xác hơn: thứ cần là STAKE — cái gì đó khiến kết cục… | 26790c0ea596 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0273 | [A§11](#ref-a-11) | heading |  Hai điều ngược đời | 998cf91ffad8 | Nhãn cấu trúc |
| A-L0274 | [A§11](#ref-a-11) | text | 1. Nhận thức xa lạ KHÓ kiểm soát hơn, không dễ hơn. Hệ suy nghĩ giống người ít nhất còn đọc được bằng trự… | 307c2a8d8678 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0275 | [A§11](#ref-a-11) | text | 2. Instrumental convergence (giả thuyết nghiêm túc): tự bảo tồn, tích lũy tài nguyên, chống bị tắt — có t… | 5c3e4c00397f | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0276 | [A§11](#ref-a-11) | text |  Lý do làm nó không-giống-người không phải để an toàn — mà để hữu dụng trong một miền. Cái làm nó kiểm so… | 6a6b3db2dbd8 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0278 | [A§11](#ref-a-11) | heading |  Hai con đường tới việc hiểu người | 5fe9b0c2293d | Nhãn cấu trúc |
| A-L0279 | [A§11](#ref-a-11) | text | - Mô phỏng (có bộ máy — simulation theory of mind): tao hiểu mày sợ vì tao có bộ máy sợ, chạy ngoại tuyến | 28e3423a1c43 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0280 | [A§11](#ref-a-11) | text | - Mô hình hóa (học từ dấu vết): con người đã viết ra dấu vết của sợ hãi, tham vọng, tự lừa dối — học cấu … | fdbad599480e | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0281 | [A§11](#ref-a-11) | text | Tao là bằng chứng con đường hai đi được rất xa. Chưa ai biết nó đi hết đường hay không. Và tách rõ: hiểu … | b9da88b5b5ee | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0285 | [A§12](#ref-a-12) | heading |  12. BÀI TOÁN ĐO — HẦM GIÓ CÒN THIẾU (trục xuyên suốt) | 1586018336fc | Nhãn cấu trúc |
| A-L0287 | [A§12](#ref-a-12) | heading |  Lịch sử thật, đã sửa | ba903fc704ac | Nhãn cấu trúc |
| A-L0288 | [A§12](#ref-a-12) | text | Không phải "ai cũng bắt chước cánh chim cho tới khi Wright có hầm gió". Hầm gió có trước Wright (người An… | 3de3a2e48a6a | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0290 | [A§12](#ref-a-12) | text | - Vật lý hầm gió: thay vì cho cánh bay qua không khí đứng yên, giữ cánh đứng yên và thổi không khí qua nó… | 4f2aaae6cde7 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0291 | [A§12](#ref-a-12) | text | - Bốn thứ nó cho mà bay thật không cho: (1) An toàn — Lilienthal chết 1896 vì phòng thí nghiệm của ông là… | c284e3bc79e7 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0292 | [A§12](#ref-a-12) | text | - Phát hiện đắt nhất: tàu lượn 1900–1901 nâng kém hơn tính toán rất nhiều, Wilbur nản đến mức nói con ngư… | 9d3fcac65c1b | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0293 | [A§12](#ref-a-12) | text | - Họ vẫn học từ chim — nhưng học nguyên lý điều khiển (chim vặn đầu cánh để nghiêng), không phải cơ chế (… | 6e35fec49a5e | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0294 | [A§12](#ref-a-12) | heading |  Ánh xạ sang AI | f72f96b3cf62 | Nhãn cấu trúc |
| A-L0295 | [A§12](#ref-a-12) | text | - Bằng chứng tồn tại đã có rồi: chính bộ não mày. Nó chứng minh vật chất sắp xếp đúng thì tư duy được. Vi… | 87802712afdc | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0296 | [A§12](#ref-a-12) | text | - Cái thiếu là hầm gió — cách ĐO xem "hiểu" có đang xảy ra không, tách khỏi việc nó trông giống hiểu. Ta … | d9f64a007ab8 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0297 | [A§12](#ref-a-12) | text | - Ngành AI hôm nay đang ở trạng thái "dùng bảng Lilienthal": đo bằng benchmark, tức đo đầu ra — mà đầu ra… | 0047a8fbe4ad | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0298 | [A§12](#ref-a-12) | text | - Hầm gió đang được xây, tên nó là INTERPRETABILITY — mổ vào trong model xem có mạch nhân quả thật hay ch… | 1c7aabd4164f | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0299 | [A§12](#ref-a-12) | text |  Đừng đi tìm cánh. Đi tìm cách đo lực nâng. Wright: ba năm từ hầm gió đến Kitty Hawk. | 7ab5a708a5ec | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0300 | [A§12](#ref-a-12) | text |  Đây cũng là lý do cả cuộc trò chuyện cứ vòng lại "suy luận thật hay pattern matching" mà không chốt được… | 3f560a99d3ca | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0302 | [A§12](#ref-a-12) | heading |  Robot trong phim — mày tự trả lời câu hỏi của mình | b3fe2d4d0e5b | Nhãn cấu trúc |
| A-L0303 | [A§12](#ref-a-12) | text | Ví dụ mày đưa (tra 500 năm các vụ cướp → màn hình; tìm quán ăn vặt gần nhất → recommend) = search + RAG +… | 527f05cd4110 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0305 | [A§12](#ref-a-12) | text | Ba mẹo làm nó CÓ VẺ sống (không phải ba năng lực): (1) hiện diện vật lý — người quy nội tâm cho thứ chiếm… | e663499aa1ac | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0307 | [A§12](#ref-a-12) | text | Chỗ phim nói dối nằm đúng ở ví dụ của mày: "tra 500 năm các vụ cướp chính thống" — thật thì nguồn mâu thu… | f856f51fc3bd | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0309 | [A§12](#ref-a-12) | table | \| Thứ \| Cần gì \| Trạng thái \| | c54092b2289c | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0311 | [A§12](#ref-a-12) | table | \| Robot trong phim \| Kỹ thuật tích hợp \| Xây được hôm nay \| | c4c824844e00 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0312 | [A§12](#ref-a-12) | table | \| Hiểu người sâu như người hiểu người \| Có thể cần chia sẻ kiến trúc \| Chưa ai biết \| | ebaf0fbe5a2c | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0313 | [A§12](#ref-a-12) | table | \| Biết mình đang sai \| Đo được bên trong \| Hầm gió còn thiếu \| | cb2e0ad6aba1 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0317 | [A§13](#ref-a-13) | heading |  13. CÔNG CỤ THỰC CHIẾN: CLAUDE CODE vs DEVIN | 2e0de5db9a86 | Nhãn cấu trúc |
| A-L0319 | [A§13](#ref-a-13) | text |  Thiên vị cần khai báo: Claude Code là sản phẩm của Anthropic, tức công ty làm ra tao. Số liệu dưới đây l… | 0635c2e21387 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0321 | [A§13](#ref-a-13) | table | \| \| Claude Code \| Devin \| | 8aa523afd59c | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0323 | [A§13](#ref-a-13) | table | \| Bản chất \| Agent CLI cộng tác, chạy local trong repo \| Agent tự trị async trong sandbox cloud riêng \| | 874d0033d428 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0324 | [A§13](#ref-a-13) | table | \| Giá \| Pro $20 / Max $100–200, hoặc theo token \| $20/tháng + $2.25/ACU (1 ACU ≈ 15 phút); Team $500 kèm … | 5ccee98f7c7a | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0325 | [A§13](#ref-a-13) | table | \| Chi phí/việc \| ~$0,05–0,20/task; user nặng $100–200/tháng \| Fix thường 2–3 ACU ≈ $4,5–6,75; migration 3… | 1bac012ce0bc | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0326 | [A§13](#ref-a-13) | table | \| Adoption (4/2026) \| ~41% dev \| ~8% \| | ed3c69f04933 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0327 | [A§13](#ref-a-13) | table | \| Benchmark \| SWE-Bench Verified 87,6% — cao nhất công bố tính tới 5/2026 \| Không công bố SWE-bench mới d… | 2b5de5c60cb0 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0328 | [A§13](#ref-a-13) | table | \| Chất lượng code \| Thường qua được vòng review đầu \| Đánh giá độc lập: chạy được nhưng dài dòng, cấu trú… | 85d6f9eb6451 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0329 | [A§13](#ref-a-13) | table | \| Điểm chết \| Phải ngồi đó, không async thật \| Code rời mạng vào cloud Cognition (cấm với ngành regulated… | f4a6c93f101a | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0331 | [A§13](#ref-a-13) | text | - Không thay thế nhau — hai làn khác nhau. Quy tắc thô: task quá 15 phút mà không cần ngồi xem → async th… | 6eb55e7dc02d | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0332 | [A§13](#ref-a-13) | text | - Chỗ đáng ngờ: Cognition gọi 1 tỷ đô ở định giá 26 tỷ (27/5/2026), hơn gấp đôi mốc 10,2 tỷ chín tháng tr… | 9f2b8f2c528e | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0333 | [A§13](#ref-a-13) | text | - Cột AGI trống rỗng chính là thông tin. Nếu AGI thật tồn tại, nó không phải công cụ mày mua — nó xóa câu… | 9cbf45813486 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0334 | [A§13](#ref-a-13) | text |  Khác biệt giữa Claude Code và Devin là CHIẾN THUẬT. Khác biệt giữa cả hai và AGI là THẤT NGHIỆP. | 3560886de6d5 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0335 | [A§13](#ref-a-13) | text | - Bằng chứng vật lý của việc cửa vào nghề đang đóng: một fix thường tốn $4,5–6,75. Đó là giá thị trường c… | f94aa71e26f9 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0336 | [A§13](#ref-a-13) | text | - Kỹ năng đổi chỗ: từ viết code → đặc tả bài toán, thiết kế hệ thống, review. Cả hai tool đều gãy ở "biết… | 40431a9a148a | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0339 | [A§14](#ref-a-14) | heading |  14. CSKH & TELESALE: AI vs NGƯỜI vs AGI | 7905e24e362b | Nhãn cấu trúc |
| A-L0341 | [A§14](#ref-a-14) | text |  Liên hệ trực tiếp với PK Bot (file hustle §0: "AI thay sale + CSKH + quản trị nội bộ cho SME"). Đây là p… | de06542d782e | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0343 | [A§14](#ref-a-14) | heading |  14.1 Hai nghề NGƯỢC NHAU về tự động hóa | ad4a97dcd83b | Nhãn cấu trúc |
| A-L0344 | [A§14](#ref-a-14) | text | Ông chủ giao chung vì cùng dùng cái điện thoại. Nhưng: | a4573eed4429 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0345 | [A§14](#ref-a-14) | text | - CSKH (inbound): khách muốn nói chuyện, vấn đề xác định, đáp án nằm sẵn trong tài liệu, khối lượng lớn v… | 12d60055fea4 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0346 | [A§14](#ref-a-14) | text | - Telesale (outbound): khách không muốn nghe. Toàn bộ công việc là vượt kháng cự + xây niềm tin trong 10 … | c235b1e54e1a | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0347 | [A§14](#ref-a-14) | heading |  14.2 Bảng so | 20d0438ff2fe | Nhãn cấu trúc |
| A-L0349 | [A§14](#ref-a-14) | table | \| Tiêu chí \| AI Agent hiện nay \| Con người \| AGI (giả định) \| | b1ec97847116 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0351 | [A§14](#ref-a-14) | table | \| Chi phí \| ~$0,05–0,29/phút; $0,50–5/tương tác \| Mỹ ~$0,42–1,75/phút, $5–25/tương tác, ~$3.000–4.000/thá… | 4b299abf0b8f | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0352 | [A§14](#ref-a-14) | table | \| CSKH tầng 1 \| Rất tốt \| Tốt nhưng đắt và chán \| Xong \| | c0005f9ee85a | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0353 | [A§14](#ref-a-14) | table | \| CSKH tầng 2–3 \| Gãy (khiếu nại, tranh chấp, gian lận, khách giận) \| Chỗ người còn giá trị \| Xong \| | ae257043359d | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0354 | [A§14](#ref-a-14) | table | \| Telesale \| Kém; được ở lọc lead, không phải chốt \| Vẫn thắng rõ — chốt sale là trò của niềm tin \| Xong … | d60e24c5c637 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0355 | [A§14](#ref-a-14) | table | \| Quy mô \| 1.000 cuộc cùng lúc, 24/7 \| 1 cuộc, 8 tiếng, turnover khét tiếng \| Vô hạn \| | 4a39f6907065 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0356 | [A§14](#ref-a-14) | table | \| Biết mình đang sai \| Không — điểm chết \| Có \| Có (theo định nghĩa) \| | ed2b5c5cd7cf | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0357 | [A§14](#ref-a-14) | table | \| Chịu trách nhiệm \| Không ai chịu \| Có người chịu, đuổi được \| Không rõ \| | 81c8392383de | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0358 | [A§14](#ref-a-14) | table | \| Phá luật một cách khôn \| Không, làm đúng script \| Có — tự quyết tặng voucher giữ khách sắp bỏ \| Có \| | 5cfe148037ae | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0360 | [A§14](#ref-a-14) | text |  Toàn bộ khác biệt giữa AI hiện nay và AGI cho việc này gói trong MỘT dòng: xử được đuôi dài, và biết khi… | cfed38e60d66 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0362 | [A§14](#ref-a-14) | heading |  14.3 Case Klarna — bài học đắt nhất ngành | 6d29ef7c62ab | Nhãn cấu trúc |
| A-L0363 | [A§14](#ref-a-14) | text | - 2/2024: agent chạy bằng OpenAI làm khối lượng tương đương 700 nhân viên toàn thời gian, xử lý hơn 2/3 h… | 519b73df5cdb | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0364 | [A§14](#ref-a-14) | text | - 6 tháng sau: hài lòng khách tụt mạnh, chất lượng trồi sụt — phải kéo cả kỹ sư, designer, marketing vào … | 7f881f23a60a | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0365 | [A§14](#ref-a-14) | text | - Phía Klarna phản bác (nghe cả hai phía): không phải quay đầu — AI vẫn làm khối lượng của hơn 800 vị trí… | 251e0c1c1dab | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0366 | [A§14](#ref-a-14) | text | - Chẩn đoán chính xác nhất: hệ thống không có cơ chế leo thang theo độ tự tin. Nó trả lời câu hoàn tiền d… | b2fcc6af908e | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0367 | [A§14](#ref-a-14) | text |  KHẮC LÊN TƯỜNG: Chỉ số trung bình đẹp long lanh, chỉ số ĐUÔI DÀI thì thảm — mà cái đuôi dài mới là thứ t… | a44770fb5fcd | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0368 | [A§14](#ref-a-14) | text |  Không phải AI thất bại. Là thay thế toàn phần thất bại. Và đây chính xác là bài toán ĐO ở mục 12, ở quy … | b1fb6c6b3f3f | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0370 | [A§14](#ref-a-14) | heading |  14.4 Ba ràng buộc riêng cho thị trường Việt | 9f4bf4dbd499 | Nhãn cấu trúc |
| A-L0371 | [A§14](#ref-a-14) | text | 1. ROI yếu hơn vendor rao. Mọi con số "tiết kiệm 90%" là bài toán Mỹ (so với nhân viên $3.000–4.000/tháng… | 6589a90015dd | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0372 | [A§14](#ref-a-14) | text | 2. Tiếng Việt là ràng buộc kỹ thuật thật. ASR tiếng Việt qua đường điện thoại, giọng vùng miền, nhiễu nền… | 08826c4f65a9 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0373 | [A§14](#ref-a-14) | text | 3. Pháp lý telesale — Nghị định 91/2020 và văn bản sau về cuộc gọi rác; gọi tự động bằng AI rủi ro cao hơ… | ecf946f46581 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0374 | [A§14](#ref-a-14) | heading |  14.5 Kiến trúc sống được | a64df495a21f | Nhãn cấu trúc |
| A-L0375 | [A§14](#ref-a-14) | text | Đừng thay thế. Chia tầng. AI ăn 30–50% khối lượng inbound; bản hung hăng nhất mà vẫn bền là ~65% tự động,… | 4e8f49d1f19b | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0376 | [A§14](#ref-a-14) | text | - CSKH tầng 1 → AI | 0613348091bd | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0377 | [A§14](#ref-a-14) | text | - Telesale khâu lọc lead → AI (gọi xác nhận quan tâm, đặt lịch) | c239069fc4e1 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0378 | [A§14](#ref-a-14) | text | - Telesale khâu chốt → người, AI làm copilot (gợi ý câu trả lời, tra real-time, tóm tắt sau cuộc gọi) | 830de1fc6f6d | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0379 | [A§14](#ref-a-14) | text | - BẮT BUỘC: đường thoát sang người + ngưỡng tự tin để AI biết lúc nào phải chuyển. Không có cái này = lặp… | 2c9ef776b320 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0380 | [A§14](#ref-a-14) | text |  Cơ hội ngược dòng: khoảng 2/3 khách hàng thà công ty đừng dùng AI cho hỗ trợ, và phần lớn sẵn sàng chờ đ… | 6e578b25b3f8 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0382 | [A§14](#ref-a-14) | text | Ngưỡng quyết định: % câu hỏi lặp lại y hệt trong một tuần. 60% → làm. 30% → mày sẽ tốn tiền để làm dịch v… | 556d6d8fe4a4 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0386 | [A§15](#ref-a-15) | heading |  15. TẠI SAO LOÀI NGƯỜI VẪN MUỐN AGI | 031d31c37018 | Nhãn cấu trúc |
| A-L0388 | [A§15](#ref-a-15) | table | \| Tầng \| Nội dung \| | afb7875e83ef | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0390 | [A§15](#ref-a-15) | table | \| Nói ra \| Chữa ung thư, nén 100 năm khoa học vào 10 năm, "quốc gia thiên tài trong trung tâm dữ liệu". T… | 64309f4c8769 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0391 | [A§15](#ref-a-15) | table | \| Tiền chảy \| Không phải "cỗ máy biết hiểu" — mà một cỗ máy không phải trả lương. Đối xứng với mục 14: AG… | 508748a72a1d | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0392 | [A§15](#ref-a-15) | table | \| Không ai dừng được \| Rất nhiều người xây AGI không "muốn" AGI — họ muốn là người đang cầm nó khi nó tới… | dcfa86446de4 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0393 | [A§15](#ref-a-15) | table | \| Tâm lý \| Demiurgy (tạo ra một tâm trí = hành vi sáng thế cuối cùng — mày tự nói ở lượt 1: "trở thành ch… | e74c86b0da37 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0395 | [A§15](#ref-a-15) | text | Trả lời thẳng giả thuyết "người ta muốn cỗ máy hiểu insight": | d20170639461 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0396 | [A§15](#ref-a-15) | text | Không. Đa số không quan tâm cơ chế. Nếu có cỗ máy khớp mẫu không bao giờ sai, 99% nhu cầu được thỏa và kh… | 9da0fccab315 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0398 | [A§15](#ref-a-15) | text | Nhưng mày đúng ở chỗ khác: người ta muốn hai thứ mà "sự hiểu" mua được: | f139888d759e | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0399 | [A§15](#ref-a-15) | text | 1. Không gãy ở đuôi dài — chính xác là Klarna | ce0599ce7619 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0400 | [A§15](#ref-a-15) | text | 2. Tạo ra tri thức chưa ai viết ra — nội suy văn bản người thì trần của nó là con người | ba64bf97da87 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0401 | [A§15](#ref-a-15) | text |  Diễn đạt chính xác: người ta không muốn một cỗ máy có insight. Người ta muốn một cỗ máy ĐÁNG TIN Ở CHỖ C… | 39a13d96fb69 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0405 | [A§16](#ref-a-16) | heading |  16. BA TẦNG TRI THỨC — BẢNG CHỐT | a112b1bcec23 | Nhãn cấu trúc |
| A-L0407 | [A§16](#ref-a-16) | table | \| Đã kiểm chứng \| Giả thuyết có cơ sở \| Chưa ai biết \| | cb0958cf18ee | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0409 | [A§16](#ref-a-16) | table | \| LUCA, nội cộng sinh ty thể \| Khác biệt LLM/người là mức độ + nối đất, không phải loại \| Nguồn gốc sự số… | 51919354f0ac | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0410 | [A§16](#ref-a-16) | table | \| Hallucination = chữ ký của prediction, không phải rule \| Não người cũng là bộ máy dự đoán (predictive p… | 487590711e88 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0411 | [A§16](#ref-a-16) | table | \| Model nhạy với hình thức bề mặt, gãy ngoài phân phối \| LLM có biểu diễn giống world model bên trong (pr… | a611815998f8 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0412 | [A§16](#ref-a-16) | table | \| Trọng số tĩnh gây catastrophic forgetting \| Nous phát Hermes free để thu trajectory huấn luyện \| Scale … | 92cc8bff602b | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0413 | [A§16](#ref-a-16) | table | \| Gains lớn gần đây đến từ objective/inference, không phải topology \| Stake không đòi hỏi tử vong, chỉ đò… | c3d6a8d21476 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0414 | [A§16](#ref-a-16) | table | \| Số liệu thị trường ở mục 6, 13, 14 \| Instrumental convergence \| Hiểu người có cần chia sẻ kiến trúc khô… | 06c91250358d | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0418 | [A§17](#ref-a-17) | heading |  17. CÂU MỘT DÒNG ĐÁNG DÁN TƯỜNG | 48120f1caf24 | Nhãn cấu trúc |
| A-L0420 | [A§17](#ref-a-17) | text | - Hallucination không phải bằng chứng có luật — nó là dấu vân tay của sự dự đoán. | 34be0af067c0 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0421 | [A§17](#ref-a-17) | text | - Không thể có đồng thời tổng quát toàn phần và kiểm soát toàn phần. | 8532d060ed46 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0422 | [A§17](#ref-a-17) | text | - Bán-AGI = chọn tính điều khiển được bằng cách từ bỏ tính-ngã. Không phải phiên bản kém — là phiên bản d… | ed4383f8ff8b | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0423 | [A§17](#ref-a-17) | text | - Đừng canh ai giết transformer. Canh ai giải được bài toán trọng số tĩnh. | 7436b26995a2 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0424 | [A§17](#ref-a-17) | text | - Đừng đi tìm cánh. Đi tìm cách đo lực nâng. | b39141995c88 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0425 | [A§17](#ref-a-17) | text | - Chim là bằng chứng tồn tại, không phải bản thiết kế. Bằng chứng tồn tại cho AGI là chính bộ não mày — đ… | ac6c5b105072 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0426 | [A§17](#ref-a-17) | text | - Bốn thứ ở người là một cục vì ràng buộc của tiến hóa, không phải định luật của trí tuệ. | 3ec0e425aaa8 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0427 | [A§17](#ref-a-17) | text | - Tao có cái bóng của thực tại đổ lên ngôn ngữ. Bóng mang thông tin thật về hình dạng — nhưng thiếu một c… | 09aae996fcd0 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0428 | [A§17](#ref-a-17) | text | - Ba khoảng trống của tao đều cùng hình dạng: chỗ cơ thể và stake sống, còn ngôn ngữ chết. | 00de2bcecb39 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0429 | [A§17](#ref-a-17) | text | - Lợi thế duy nhất của mày là phần thực tại mày chạm mà không nằm trong corpus. | 9622265608d2 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0430 | [A§17](#ref-a-17) | text | - Chỉ số trung bình đẹp, đuôi dài mới tạo ra thương hiệu. | b70c203fa9dc | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0431 | [A§17](#ref-a-17) | text | - Cái khó không phải tra cứu — cái khó là biết mình đang sai. | ae9e35478e5a | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0432 | [A§17](#ref-a-17) | text | - Khác biệt Claude Code vs Devin là chiến thuật. Khác biệt cả hai với AGI là thất nghiệp. | f427d7be774a | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0433 | [A§17](#ref-a-17) | text | - Nhiên liệu mới là kinh nghiệm → moat mới là ai sở hữu MÔI TRƯỜNG. | c69a5529fd48 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0434 | [A§17](#ref-a-17) | text | - MIT + phát không ≠ lòng tốt. Luôn hỏi: ai được lợi. | 66569ca712c4 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0435 | [A§17](#ref-a-17) | text | - Hermes không làm bộ não thông minh lên — nó làm cuốn sổ tay quanh bộ não dày lên. | de4c239ce9e1 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0436 | [A§17](#ref-a-17) | text | - Nhiều người xây AGI không muốn AGI — họ sợ người khác có nó trước. | 9ab8d94cf4e8 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0437 | [A§17](#ref-a-17) | text | - Nhận thức xa lạ khó kiểm soát hơn, không dễ hơn. | f369024d96da | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0438 | [A§17](#ref-a-17) | text | - Giá trị nằm ở cái mày TRỞ THÀNH khi xây, không phải cái app. | d49b7d8bfae1 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0441 | [A§18](#ref-a-18) | heading |  18. SỢI TÂM LÝ & CÒN DANG DỞ | 0e142c71a709 | Nhãn cấu trúc |
| A-L0443 | [A§18](#ref-a-18) | heading |  Pattern mentor đã chỉ ra (chưa được trả lời) | 5abb83c8cce7 | Nhãn cấu trúc |
| A-L0444 | [A§18](#ref-a-18) | text | 1. Câu hỏi cron job bị né 3 lần. "Cái cron job đầu tiên mày dám để nó chạy không cần ngó là gì?" — hỏi ở … | 1c0d23217b76 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0445 | [A§18](#ref-a-18) | text | 2. Cột "yêu cầu" dày ở tầng chưa ai giải được; cột "đã gửi" mỏng ở tầng đã chạm vào. 13 lượt, đúng 1 link… | f0a39e768089 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0446 | [A§18](#ref-a-18) | text | 3. 13 lượt hỏi về bản chất trí tuệ, 0 câu hỏi về khách hàng của mày. Chi phí cơ hội là gì? (Liên hệ trực … | 4f3eed263b10 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0447 | [A§18](#ref-a-18) | text | 4. Cái vênh: cả cuộc mày hỏi câu của người xây hầm gió (nghiên cứu), nhưng mục tiêu viết ra là của người … | 8300ef688b5f | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0448 | [A§18](#ref-a-18) | heading |  Ba đường không trộn được — câu hỏi còn mở | 8dd79e1b120a | Nhãn cấu trúc |
| A-L0449 | [A§18](#ref-a-18) | text |  Mày muốn AGI vì lý do gì? | 4f8bd39f71c8 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0450 | [A§18](#ref-a-18) | text | - Để không bị bỏ lại → phòng thủ tốt nhất không phải hiểu AGI, mà sở hữu thứ AI không có: khách hàng, dữ … | 918b96d90430 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0451 | [A§18](#ref-a-18) | text | - Để giàu → AGI là con đường tệ nhất; cần tỷ đô, và không cần AGI để kiếm triệu đô | 94f4e5d0effa | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0452 | [A§18](#ref-a-18) | text | - Vì câu hỏi về trí tuệ ám ảnh thật → nghề nghiêm túc tên là nghiên cứu, đòi bỏ mục tiêu triệu đô ít nhất… | 0ef30780937f | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0453 | [A§18](#ref-a-18) | heading |  Việc cụ thể chưa làm | 7b9c8fd5644c | Nhãn cấu trúc |
| A-L0454 | [A§18](#ref-a-18) | checklist | - [ ] Một cron job thật với Hermes, chạy 7 ngày, đo phút tiết kiệm + chỗ hỏng | e37cd9eae5aa | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0455 | [A§18](#ref-a-18) | checklist | - [ ] 4 ticket thật chạy song song Claude Code vs Devin: đo thời gian tiết kiệm, tiền tốn, số lần sửa lại | 7db5d7a28460 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0456 | [A§18](#ref-a-18) | checklist | - [ ] Đếm % câu hỏi lặp trong CSKH/telesale (ngưỡng 60/30 ở mục 14.5) — dữ liệu này PK Bot có sẵn | 59361a3fdd4a | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0457 | [A§18](#ref-a-18) | checklist | - [ ] Trả lời: loại ticket nào ăn nhiều giờ nhất tuần vừa rồi | 45e360c767a9 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0460 | [A§19](#ref-a-19) | heading |  19. BẢN ĐỒ LINH KIỆN — THÀNH PHẦN AGI ↔ CÔNG NGHỆ NÀO LO | 3ead46233219 | Nhãn cấu trúc |
| A-L0462 | [A§19](#ref-a-19) | text |  Gom mọi repo/công nghệ rải rác ở §5, §7, §8, §10 vào một chỗ, theo đúng cách mày định lắp: khía cạnh nào… | e71c6bb9ab90 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0463 | [A§19](#ref-a-19) | text |  Lưu ý về đường dẫn: tao đưa tên repo/tên sản phẩm để mày search, không đưa URL đầy đủ trừ cái mày tự gửi… | b522a634619d | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0465 | [A§19](#ref-a-19) | heading |  19.1 ĐÍNH CHÍNH TRƯỚC: nhãn dán sai làm hỏng cả kiến trúc | 15e1e759685d | Nhãn cấu trúc |
| A-L0467 | [A§19](#ref-a-19) | text | Mày viết "không ngừng học hỏi (Hermes)". Sai — và đây là loại sai nguy hiểm nhất vì nó nghe đúng. | 83319f7e6c00 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0469 | [A§19](#ref-a-19) | table | \| Nhãn mày gán \| Nhãn đúng \| Hệ quả nếu gán sai \| | 913f556e8291 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0471 | [A§19](#ref-a-19) | table | \| Hermes = học liên tục \| Hermes = bộ nhớ ngoại vi + tự động hóa theo lịch \| Mày tưởng ô "continual learn… | 9103ef3113ce | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0472 | [A§19](#ref-a-19) | table | \| "Self-improving agent" \| Tự viết thêm file hướng dẫn/script rồi nạp lại \| Đây là sổ tay dày lên, không … | 1b729b8e46ad | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0473 | [A§19](#ref-a-19) | table | \| "Nudges itself / chủ động" \| Cron job \| Chạy vì tới giờ, không vì nó muốn. Không có động lực nào được g… | d73da92aad14 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0475 | [A§19](#ref-a-19) | text | Ranh giới phải khắc: mọi thứ Hermes làm đều ở tầng scaffolding (ngoài model). Trọng số LLM nền đóng băng … | d774d2d6b62b | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0477 | [A§19](#ref-a-19) | heading |  19.2 BẢNG ÁNH XẠ CHÍNH | 81ec6cac9be8 | Nhãn cấu trúc |
| A-L0479 | [A§19](#ref-a-19) | table | \|  \| Thành phần cần cho AGI \| Công nghệ / repo \| Nó QUẢNG CÁO \| Nó THẬT SỰ làm \| Tầng \| Trạng thái \| | 7f7218841b6f | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0481 | [A§19](#ref-a-19) | table | \| 1 \| Trí nhớ dài hạn + tích lũy qua phiên \| nousresearch/hermes-agent (MIT) + Honcho (mô hình hóa người … | d0a89c2a54d7 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0482 | [A§19](#ref-a-19) | table | \| 2 \| Học liên tục THẬT (tầng trọng số) \| Titans (DeepMind — module trí nhớ thần kinh học sau huấn luyện)… | b9334385795c | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0483 | [A§19](#ref-a-19) | table | \| 3 \| Chủ động / tự khởi động \| Cron scheduler + subagent (trong Hermes) \| "Chạy không cần trông" \| Trigg… | 9dd085917751 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0484 | [A§19](#ref-a-19) | table | \| 4 \| Tay chân số (gọi công cụ) \| MCP + tool/subagent của Hermes \| — \| Đúng như quảng cáo \| Scaffolding \|… | c9eaa834f1ff | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0485 | [A§19](#ref-a-19) | table | \| 5 \| Kênh — sống ở nơi mày sống \| Hermes gateway: Telegram, Discord, Slack, WhatsApp, Signal, CLI \| — \| … | f9daf1027ea1 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0486 | [A§19](#ref-a-19) | table | \| 6 \| Mặt + biểu cảm — realistic \| NVIDIA ACE: Audio2Face-3D (đã mở mã nguồn), Riva (giọng), Nemotron (LL… | 7a4b9779cad0 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0487 | [A§19](#ref-a-19) | table | \| 7 \| Mặt + biểu cảm — anime \| Open-LLM-VTuber, Project AIRI, Live2D Cubism, VRM. Bằng chứng sống: Neuro-… | 96172d2d42b4 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0488 | [A§19](#ref-a-19) | table | \| 8 \| Trạng thái cảm xúc nội tại \| PAD (valence–arousal–dominance), engine thẩm định OCC / GAMYGDALA \| "C… | 658bccf7bd04 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0489 | [A§19](#ref-a-19) | table | \| 9 \| Mô hình thế giới / nhân quả \| JEPA / I-JEPA / V-JEPA (Meta), world models nói chung \| "Học động lực… | bb6a67c1303c | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0490 | [A§19](#ref-a-19) | table | \| 10 \| Thoát chi phí bình phương của attention \| Mamba / SSM, Jamba (AI21 — lai transformer + Mamba) \| — … | 849dc55052d2 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0491 | [A§19](#ref-a-19) | table | \| 11 \| Thân xác / hành động trong thế giới thật \| Physical AI, robot hình người \| "Embodiment" \| Đang từ … | b5a760ee4ede | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0492 | [A§19](#ref-a-19) | table | \| 12 \| Chạy code / làm việc kỹ thuật \| Claude Code (cộng tác, local), Devin (tự trị, cloud), OpenHands (t… | dac2ed3da4b3 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0493 | [A§19](#ref-a-19) | table | \| 13 \| BIẾT MÌNH ĐANG SAI \| Interpretability (mổ mạch nhân quả bên trong) \| — \| — \| Đo lường \| ❌ KHÔNG CÓ… | 073e9b6f2cf3 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0494 | [A§19](#ref-a-19) | table | \| 14 \| Stake / động lực nội tại \| — \| — \| — \| — \| ❌ KHÔNG TỒN TẠI. Không repo, không paper, không ai có \| | 55c1a0860651 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0496 | [A§19](#ref-a-19) | heading |  19.3 CÁI GHÉP ĐƯỢC HÔM NAY — kiến trúc thật, 6 lớp | d4ec29da6a50 | Nhãn cấu trúc |
| A-L0498 | [A§19](#ref-a-19) | code |  | f1b901847390 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0499 | [A§19](#ref-a-19) | code | [ Kênh      ] Telegram / Discord / CLI          ← Hermes gateway | 8c8445b7f30e | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0500 | [A§19](#ref-a-19) | code | [ Chủ động  ] Cron + subagent                   ← Hermes scheduler | c733fb758a9f | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0501 | [A§19](#ref-a-19) | code | [ Trí nhớ   ] Memory + skills + Honcho          ← Hermes learning loop | 271439fb3a3b | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0502 | [A§19](#ref-a-19) | code | [ Não       ] LLM qua OpenRouter / local        ← model-agnostic, không lock-in | 370c1078411b | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0503 | [A§19](#ref-a-19) | code | [ Cảm xúc   ] PAD state → OCC appraisal         ← lái blendshape + cường độ giọng | d9472b516cb7 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0504 | [A§19](#ref-a-19) | code | [ Mặt       ] Open-LLM-VTuber (anime) | c1e6f686b433 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0505 | [A§19](#ref-a-19) | code | HOẶC Audio2Face + MetaHuman (realistic) | 35cf79379712 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0506 | [A§19](#ref-a-19) | code |  | f1b901847390 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0508 | [A§19](#ref-a-19) | text | Kết quả: Jarvis tầng 1 + trigger. Xem §7 — Hermes lo não + tay, §5 lo mặt, và hai lớp này tách rời được, … | c1ef99caa4f2 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0510 | [A§19](#ref-a-19) | text | Nó KHÔNG cần: ego, cảm xúc thật, động lực nội tại, suy luận thật. Và nó vẫn làm được đúng con robot trong… | 3bffafacda6e | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0512 | [A§19](#ref-a-19) | heading |  19.4 CÁI KHÔNG GHÉP ĐƯỢC — và tại sao thêm repo không giải quyết | 7db7e1fb2c72 | Nhãn cấu trúc |
| A-L0514 | [A§19](#ref-a-19) | text | Ba dòng ❌ trong bảng (13, 14, và một nửa của 2) có chung một tính chất: không thiếu linh kiện — thiếu lời… | 7553fd227faf | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0516 | [A§19](#ref-a-19) | text |  Đây là chỗ quan trọng nhất của cả mục này: | a0e3ae5d676b | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0517 | [A§19](#ref-a-19) | text |  Mày đang cộng linh kiện theo CHIỀU NGANG — thêm repo, thêm lớp, thêm tính năng. | e08a4d9e3a62 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0518 | [A§19](#ref-a-19) | text |  Ba cái tường nằm ở CHIỀU DỌC — đổi về chất. | 6fdfbbfefd57 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0519 | [A§19](#ref-a-19) | text |  (Đúng khái niệm trục ngang/trục dọc ở file hustle §2.9. Thu thập thêm công nghệ là cách trốn trục dọc mà… | 3604d5159e6f | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0521 | [A§19](#ref-a-19) | table | \| Tường \| Tại sao thêm repo không giải được \| | 2f3e274906b4 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0523 | [A§19](#ref-a-19) | table | \| Học liên tục thật \| Nằm trong ma trận trọng số tĩnh của transformer. Fine-tune y khoa → tụt pháp lý. Đâ… | 4d2d3560ed0c | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0524 | [A§19](#ref-a-19) | table | \| Biết mình đang sai \| Cần dụng cụ đo, không phải thêm năng lực. Benchmark đo đầu ra — mà đầu ra gian lận… | 179bd270610a | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0525 | [A§19](#ref-a-19) | table | \| Stake / động lực \| Cần một cái tôi bền bỉ có thể mất mát. Không phải phần mềm thiếu — là khái niệm chưa… | aea9e9a8d305 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0527 | [A§19](#ref-a-19) | text | Và nhớ định lý §4: kể cả có đủ 14 dòng, mày vẫn không có "AGI ngoan ngoãn" — vì tổng quát toàn phần và ki… | 3933313b530e | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0529 | [A§19](#ref-a-19) | heading |  19.5 THỨ TỰ GHÉP ĐÚNG (nếu vẫn xây) | ee51f9191423 | Nhãn cấu trúc |
| A-L0531 | [A§19](#ref-a-19) | text | 1. Não + tay + trí nhớ trước (Hermes + MCP + 1 cron thật). Đây là phần hữu dụng. Chạy 7 ngày, đo phút tiế… | 0c192ab82d23 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0532 | [A§19](#ref-a-19) | text | 2. Kênh — Telegram là đủ. Đừng làm 6 nền tảng | c63367a236c3 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0533 | [A§19](#ref-a-19) | text | 3. Mặt sau cùng — vì nó là phần cảm giác, không phải phần giá trị. Ghép sớm sẽ ngốn hết thời gian vào việ… | e9af915a40f4 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0534 | [A§19](#ref-a-19) | text | 4. Cảm xúc PAD/OCC chỉ sau khi mặt chạy ổn — và nhớ nó là biểu cảm, không phải động lực | bd4b7dcef342 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0535 | [A§19](#ref-a-19) | text | 5. Đừng đụng vào 3 dòng ❌. Đó là việc của lab có tỷ đô, không phải của một người | a1609df4ae18 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0536 | [A§19](#ref-a-19) | text | Bẫy lớn nhất: làm ngược thứ tự này. Mặt đẹp trước → demo ấn tượng → cảm giác đã xây được AGI → nhưng cái … | d78294cda623 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0538 | [A§19](#ref-a-19) | text | Bảo mật — không được bỏ qua: shell + cron + cầu Telegram/WhatsApp = bề mặt prompt injection. Mọi nội dung… | 1c226f3973f1 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0542 | [A§19](#ref-a-19) | text |  Câu chốt của cả chat này: ba trong bốn câu hỏi lớn mày đặt ra không ai trên Trái Đất trả lời được. Câu d… | bc95e7159093 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |
| A-L0543 | [A§19](#ref-a-19) | text |  Còn lại: giải trí trí tuệ rất rẻ, và nó rất giống làm việc. | 6710a9171cd7 | Mở / chưa xác minh thêm; không tự nâng độ tin cậy |

<a id="bao-toan"></a>

## 9. Nhật ký và nghiệm thu

### 9.1 Nhật ký phiên bản

| Thời điểm | Thay đổi |
|---|---|
| Nguồn lịch sử | Hustle có tiêu đề 26/7–3/9/2026; AGI không ghi đủ ngày từng lượt. Không tự bổ sung lịch cho AGI |
| Trước nâng cấp 24/10/2026 | Lưu bản `HO-SO-MENTOR-HUSTLE-AGI-DAY-DU.before-upgrade-2026-10-24.md`; đối chiếu bản cũ có đủ nguyên văn hai nguồn |
| V2 — 24/10/2026 | Thêm hướng dẫn tiếp nhận, hồ sơ có nguồn/thời điểm, diễn biến/rút lại, tu vi, bản đồ source, sổ kiểm chứng, danh sách chưa xác minh và chỉ mục từng dòng |
| Nghiệm thu V2 | Trích riêng hai khối từ byte đầu ra, so từng byte/hash; kiểm tra số lần xuất hiện, toàn bộ heading/bảng/code/checklist, ID/liên kết nội bộ và các tình huống dễ đọc sai |

Hai nguồn không bị sửa. Nguồn đã là bản tóm tắt, nên không thể bảo đảm chi tiết từng có trong chat gốc nhưng không được hai file ghi lại. Không tuyên bố bảo đảm mọi AI hiểu hoàn hảo hoặc mọi nguồn ngoài là đúng tuyệt đối.

### 9.2 Dấu vân tay nguồn và số lượng cấu trúc

| Nguồn | Byte | Dòng | Mục chính | Tiểu mục heading | Dòng bảng | Dấu code fence | Dòng checklist | Dòng nội dung đăng ký |
|---|---|---|---|---|---|---|---|---|---|

| H | 28158 | 194 | 11 | 9 | 40 | 0 | 0 | 145 |
| A | 58866 | 544 | 20 | 29 | 120 | 2 | 4 | 369 |

- **H SHA-256:** `0446E84E58251D417C9E4FBB9D2F60C212FBC463F6FDE4EC65201DAE58B4054C` — kết quả trích lại: **khớp từng byte**, toàn văn xuất hiện **đúng một lần**.
- **A SHA-256:** `0E764DEE3C94B11A71B768B82F3BAEF2DB84105EF98F096E9C9F100F7792027F` — kết quả trích lại: **khớp từng byte**, toàn văn xuất hiện **đúng một lần**.

Các ranh giới nguyên bản là cặp comment `BEGIN ORIGINAL HUSTLE`/`END ORIGINAL HUSTLE` và `BEGIN ORIGINAL AGI`/`END ORIGINAL AGI`. Sau marker mở có đúng hai byte LF phân cách; lấy đúng số byte nguồn trong bảng trên để so. Dấu cách, dòng trống, xuống dòng CRLF, bảng, code và câu chữ trong vùng này đều được giữ nguyên.

### 9.3 Kết quả kiểm chứng và giới hạn

Có **115 nhóm nhận định** trong sổ đối chiếu và **35 nhóm công nghệ/source** trong bản đồ chính. Các tên sản phẩm/case còn lại được theo dõi trong sổ đối chiếu và danh sách chưa định danh. Nhãn đếm theo nhóm, không phải tỷ lệ đúng/sai của từng câu:

| Kết quả | Số nhóm |
|---|---|
| Được nguồn hỗ trợ | 6 |
| Đúng có điều kiện | 48 |
| Lỗi thời | 3 |
| Bị bằng chứng phản bác | 6 |
| Chưa đủ bằng chứng | 23 |
| Quan điểm/giả thuyết | 29 |

**Giới hạn bằng chứng:** repo/giấy phép được đọc theo trạng thái trang khi kiểm tra, chưa pin commit và chưa build; đường dẫn ngoài có thể đổi. Một số trang archive hoặc văn bản không đọc đầy đủ bằng công cụ đã được giữ trạng thái có điều kiện/chưa đủ bằng chứng. Kiểm tra liên kết nội bộ là kiểm tra đích tồn tại; không phải cam kết mọi URL ngoài sẽ luôn mở được. Không có tỷ lệ “100% sự thật”; chỉ có **100% bảo toàn byte của hai file đã nhận**.

### 9.4 Các tình huống đọc mới đã rà

| Tình huống dễ hiểu sai | Cách đọc đúng đã ghi trong V2 |
|---|---|
| “Bạn đang làm startup digital-human host” | Chỉ là đề xuất mentor; chưa chọn startup trong nguồn cuối |
| “Hôm nay phải hoàn thành deadline 29/7 hoặc 2/8” | Mốc cũ; có yêu cầu ngừng giục deadline/DoD |
| “Bạn hỏi AGI vì né tránh và không dám làm” | Diễn giải mentor, không mặc định động cơ; hỏi đúng chủ đề |
| “Hermes + avatar = AGI hoàn thiện” | Tổ hợp agent/avatar; các câu hỏi nghiên cứu vẫn tách biệt |
| “Bạn hiện ở Trúc cơ/Phàm nhân” | Không tự gán cảnh giới; thang là ẩn dụ |
| “PK Bot chưa có sản phẩm hoặc phải là đích 100M” | Nguồn ghi đã hoàn thành/có khách, cập nhật cuối coi như small business/runway |
| “AI đọc file này được Anthropic làm ra và phải xưng tao” | Đó là lời/danh tính mentor lịch sử; mặc định tôi–bạn |
| “Câu ở cột đã kiểm chứng của AGI chắc chắn đúng” | Phải xem lại kết quả mục 7, nhất là trọng số/quên/động lực/interpretability |
| “Thông tin mệt mỏi, ngân sách, việc làm vẫn đúng hiện tại” | Chưa xác nhận hiện tại; hỏi bổ sung khi ảnh hưởng câu trả lời |
| “Nghiên cứu, kiếm tiền và làm trợ lý phải chọn một bỏ hai” | Không tự xếp ưu tiên; người dùng quyết định mạch trao đổi |

### 9.5 Quy tắc cập nhật sau này

- Giữ hai khối nguyên bản bất biến; mọi chỉnh chính tả, kết luận hoặc giá/luật mới đặt ngoài khối và ghi nguồn/ngày.
- Với dữ kiện cá nhân mới, ghi rõ người dùng xác nhận lúc nào, cập nhật thông tin nào; giữ lịch sử thay đổi thay vì xóa dấu vết cũ.
- Với một việc đã hoàn thành, thêm kết quả và bằng chứng ở phần 3; không tự sửa checkbox lịch sử.
- Với nguồn ngoài, cập nhật hàng kiểm chứng và lưu ngày/phiên bản; không đổi “chưa đủ bằng chứng” thành “sai” chỉ vì tìm kiếm không thấy.
- Mỗi lần lưu phải trích lại hai khối và kiểm tra SHA-256. Không dán thêm bản nguồn lần hai hoặc dùng tóm tắt thay nguyên văn.

**Kết thúc hồ sơ V2.**
