'use strict';
const UI_PROTOCOL='commentlab-local-20261019-4';
const VERSION_ERROR='Đang mở bản app cũ hoặc không cùng phiên bản. Đóng cửa sổ này và mở CommentLab.exe mới; không dùng lại địa chỉ 8790 cũ.';
let compatible=false;
const $=s=>document.querySelector(s),esc=s=>String(s??'').replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
let state={accounts:[],groups:[],history:[]},tab='groups',links='',rows=[],chosen=new Set(),count=10;
let draftId=null,posts=[],texts={},selected=new Set(),commonText='',working=false,lastRead=null,lastSync=null,pollTimer;
let historyItems=[],historyOffset=0,historyMore=false,lastBatch=null;
const draftsByAccount=new Map();
let sourceMode='joined',groupQuery='',composerClosed=false,historyQuery='',historyStatus='all',refreshing=false,detailReturn=null,detailItem=null;
const liveSync=j=>j&&['queued','running','stopping'].includes(j.state);
const syncFor=id=>(state.sync_jobs||[]).find(j=>j.account_id===id);
const statuses={pending:'Đang chờ',sending:'Đang gửi',not_sent:'Chưa gửi',outcome_unknown:'Chưa rõ kết quả',reserved:'Chưa rõ kết quả',confirmed_by_response:'Đã xác nhận phản hồi',unconfirmed:'Chưa xác nhận'};
const reasons={session_expired:'Phiên hết hạn',verification_required:'App dừng: dấu hiệu xác minh',restricted:'App dừng: dấu hiệu hạn chế',permission_denied:'Nguồn từ chối truy cập',network_error:'Lỗi kết nối',unrecognized_response:'App dừng: chưa rõ phản hồi',remote_error:'Lỗi nguồn'};
function diagnosticLabel(d){if(!d)return '';const scope={session:'Dấu hiệu ở phiên/tài khoản',request:'Dấu hiệu ở bài/nguồn yêu cầu',unknown:'Chưa xác định phạm vi lỗi'};const stage={read:'đọc bài',sync:'đồng bộ nhóm',preflight:'chuẩn bị thao tác',comment:'giai đoạn gửi',recheck:'kiểm tra phiên'};return `${scope[d.scope]||scope.unknown} · ${stage[d.stage]||'giai đoạn chưa rõ'}`;}
const actor=()=>state.active_account_id,account=()=>state.accounts.find(a=>a.account_id===actor());
const sourceInput=()=>[links,...chosen].filter(Boolean).join('\n');
const stamp=value=>value?new Date(value*1000).toLocaleString('vi-VN'):'Chưa lưu thời gian';
function safeLink(url){try{const u=new URL(url);return u.protocol==='https:'&&['www.facebook.com','facebook.com','m.facebook.com','web.facebook.com'].includes(u.hostname)&&!u.username&&!u.password?u.href:'';}catch{return '';}}
function link(url,label){const href=safeLink(url);return href?`<a href="${esc(href)}" target="_blank" rel="noopener noreferrer">${esc(label)}</a>`:esc(label);}
function message(text,error=false){$('#banner').textContent=text;$('#banner').className=text?(error?'error':'notice'):'';}
async function api(path,data){
 if(data&&!compatible)throw Error(VERSION_ERROR);
 let response;
 try{response=await fetch(path,{method:data?'POST':'GET',headers:data?{'Content-Type':'application/json','X-Lab-CSRF':state.csrf}:{},body:data?JSON.stringify(data):undefined});}
 catch{throw Error('Mất kết nối với app. Nếu vừa gửi, kiểm tra lịch sử trước khi thử tiếp.');}
 let value;try{value=await response.json();}catch{throw Error('Phản hồi không hợp lệ. Không tự gửi lại.');}
 if(!response.ok){if(response.status===404&&path.startsWith('/api/'))throw Error('Giao diện và chương trình đang chạy khác phiên bản. Đóng app cũ, mở lại CommentLab.exe rồi tải lại trang.');throw Error(value.error||'Không hoàn tất thao tác.');}return value;
}
function stashDraft(id=actor()){if(id)draftsByAccount.set(id,{links,rows,chosen:new Set(chosen),count,draftId,posts,texts:{...texts},selected:new Set(selected),commonText,lastRead,lastBatch,sourceMode,groupQuery,composerClosed});}
function restoreDraft(id){clearDraft();const d=draftsByAccount.get(id);sourceMode='joined';groupQuery='';composerClosed=false;if(d)({links,rows,chosen,count,draftId,posts,texts,selected,commonText,lastRead,lastBatch,sourceMode,groupQuery,composerClosed}=d);}
function clearDraft(){draftId=null;posts=[];texts={};selected.clear();lastRead=null;rows=[];chosen.clear();links='';commonText='';}
function invalidatePreview(){draftId=null;posts=[];texts={};selected.clear();}
function syncLabel(j){return ({queued:'Chờ đồng bộ',running:'Đang đọc nhóm',stopping:'Đang dừng',cancelled:'Đã dừng',interrupted:'Bị gián đoạn',completed:'Đã đồng bộ',partial:'Đồng bộ một phần',unavailable:'Chưa đồng bộ được'})[j?.state]||'Chưa đồng bộ';}
function renderAccounts(){
 const html=state.accounts.map(a=>{const j=syncFor(a.account_id);return `<button class="account ${a.account_id===actor()?'active':''}" aria-pressed="${a.account_id===actor()}" data-account="${esc(a.account_id)}" ${state.busy?'disabled':''}><strong>${esc(a.name)}</strong><small>${esc(reasons[a.blocked]||'Đã lưu phiên')}</small>${j?`<small>${syncLabel(j)}${j.completed?' · '+j.completed+' nhóm':''}</small>${liveSync(j)?`<progress aria-label="Đồng bộ nhóm của ${esc(a.name)}"></progress>`:''}`:''}</button>`;}).join('')||'<p class="muted">Chưa có tài khoản.</p>';
 if($('#accounts').innerHTML!==html)$('#accounts').innerHTML=html;
 for(const id of ['edit','delete'])$('#'+id).disabled=!account()||state.busy;
 $('#add').disabled=state.busy;
 $('#heading').textContent=tab==='help'?'Hướng dẫn':tab==='history'?'Lịch sử':tab==='settings'?'Cài đặt':account()?'Làm việc với '+account().name:'Thêm tài khoản để bắt đầu';
 document.querySelectorAll('[data-tab]').forEach(b=>b.classList.toggle('active',b.dataset.tab===tab));
}
function render(){renderAccounts();if(tab==='groups')renderGroups();else if(tab==='review')renderReview();else if(tab==='history')renderHistory();else if(tab==='help')renderHelp();else if(tab==='settings')renderSettings();}
function syncPanel(){const j=syncFor(actor());return `<div class="sync-progress"><strong>${syncLabel(j)}</strong>${liveSync(j)?'<progress aria-label="Đang đồng bộ nhóm; chưa biết tổng số"></progress>':''}<small>${esc(j?.message||'Đồng bộ hoặc gắn link để chọn nguồn.')}</small><div class="sync-actions">${liveSync(j)?`<button id="stop-sync" ${j.state==='stopping'?'disabled':''}>Dừng đồng bộ</button>`:`<button id="sync" ${!account()?'disabled':''}>${j?'Đồng bộ lại':'Đồng bộ nhóm'}</button>`}${j?.diagnostic?'<button id="sync-detail" class="quiet">Chi tiết</button>':''}</div></div>`;}
function renderSourceList(){
 const list=(state.groups||[]).filter(g=>(sourceMode==='joined'?g.source==='sync':g.source!=='sync')&&g.name.toLocaleLowerCase('vi').includes(groupQuery.toLocaleLowerCase('vi')));
 const host=$('#source-list');if(!host)return;
 const html=list.map(g=>`<label class="group-row"><input type="checkbox" aria-label="Chọn ${esc(g.name)}" data-group="${esc(g.url)}" ${chosen.has(g.url)?'checked':''}><span><strong>${esc(g.name)}</strong><small>${g.state==='member'?'Đã tham gia':g.state==='readable'?'Đọc được':'Chưa kiểm tra'} · ${g.source==='sync'?'Đồng bộ':'Nhập tay'}</small></span></label>`).join('')||'<p class="group-empty">Chưa có nhóm phù hợp. Bạn có thể gắn link thủ công.</p>';
 if(host.innerHTML!==html){const focus=document.activeElement?.dataset?.group,scroll=host.scrollTop;host.innerHTML=html;host.scrollTop=scroll;if(focus)for(const el of host.querySelectorAll?.('[data-group]')||[])if(el.dataset.group===focus)el.focus({preventScroll:true});}
}
function selectedSources(){return `${chosen.size} nhóm đã chọn${links.trim()?' · có link nhập tay':''}`;}
function updateWork(){
 renderAccounts();
 const panel=$('#sync-progress');if(panel){const html=syncPanel();if(panel.innerHTML!==html)panel.innerHTML=html;}
 renderSourceList();
 if($('#selected-sources'))$('#selected-sources').textContent=selectedSources();
 const disabled=!account()||!!account()?.blocked||state.busy||state.network_busy;
 if($('#load'))$('#load').disabled=disabled;
 if($('#direct-send'))$('#direct-send').disabled=disabled||!commonText.trim();
 if($('#network-hint'))$('#network-hint').textContent=state.network_busy?'Đồng bộ đang dùng kết nối. Bạn vẫn có thể soạn; chờ xong hoặc dừng đồng bộ để đọc/gửi.':'';
 if($('#account-hold'))$('#account-hold').innerHTML=account()?.blocked?`<div class="notice danger">${esc(reasons[account().blocked])}. App đang tạm dừng gửi; không đồng nghĩa Facebook khóa tài khoản. ${account().app_hold?'Kiểm tra bài ở Lịch sử; kiểm tra phiên không xác nhận kết quả gửi trước. <button data-tab="history">Xem lịch sử</button>':''} <button id="recheck" ${state.busy||state.network_busy?'disabled':''}>Kiểm tra khả năng đọc</button></div>`:'';
}
function renderGroups(){
 $('#content').innerHTML=`<div id="account-hold"></div><div class="work-layout"><section class="groups-panel" aria-label="Nhóm của tài khoản"><h2>Nhóm / nguồn</h2><div id="sync-progress">${syncPanel()}</div><div class="source-tabs"><button data-source-mode="joined" aria-pressed="${sourceMode==='joined'}">Nhóm tài khoản</button><button data-source-mode="manual" aria-pressed="${sourceMode==='manual'}">Gắn link</button></div>${sourceMode==='manual'?`<label for="links">Link nhóm hoặc bài trong nhóm</label><textarea id="links" rows="4" placeholder="Mỗi dòng một link HTTPS">${esc(links)}</textarea><div class="toolbar"><button id="check" ${!account()||state.busy?'disabled':''}>Kiểm tra & lưu nhóm</button></div>${rows.map(r=>`<div class="import-result ${r.valid?'':'warn'}">Dòng ${r.line}: ${esc(r.error||(r.kind==='post'?'Bài '+r.target.post_id:'Nhóm '+r.group.slug))}</div>`).join('')}`:'<label class="sr-only" for="group-query">Tìm nhóm</label>'}<input id="group-query" aria-label="Tìm nhóm đã lưu" type="search" placeholder="Tìm nhóm đã lưu" value="${esc(groupQuery)}"><div id="source-list" class="group-rows"></div></section><div class="work-content">${composerClosed?'<div class="panel composer"><h2>Đã giữ bản nháp</h2><button id="open-composer">Mở lại soạn thảo</button></div>':`<section class="panel composer"><div class="section-title"><h2>Soạn nội dung</h2><button id="close-composer" class="quiet">Thu gọn</button></div><div id="selected-sources" class="selected-sources">${selectedSources()}</div><label for="common-text">Nội dung bình luận</label><textarea id="common-text" rows="6" maxlength="10000" placeholder="Nhập nội dung">${esc(commonText)}</textarea><div class="toolbar bottom"><label for="count">Số bài tối đa</label><select id="count">${[10,20,50].map(n=>`<option value="${n}" ${count===n?'selected':''}>${n}</option>`).join('')}</select></div><div class="bottom"><small>Tối đa ${count} bài tổng cộng · giữ chống trùng</small><div class="toolbar"><button id="load">Xem trước</button><button id="direct-send" class="primary">Gửi bình luận</button></div></div></section>`}<p id="network-hint" class="muted"></p><div class="section-gap"><div class="section-title"><h2>Kết quả gần đây</h2><button data-tab="history" class="link-button">Xem lịch sử</button></div>${(state.history||[]).slice(0,4).map((h,i)=>`<div class="result-row"><div><strong>${esc(h.group_name||'Chưa lưu tên nhóm')}</strong><small>${esc(h.account_name||h.actor_id)} · ${esc(statuses[h.status]||h.status)}</small></div><button data-recent-detail="${i}">Chi tiết</button></div>`).join('')||'<p class="muted">Chưa có kết quả.</p>'}</div></div></div>`;
 updateWork();
}
function progress(){
 const job=state.read_job;
 return `<div class="notice">${job?.state==='running'?(job.total?`Đang đọc ${job.completed}/${job.total} nguồn${job.mode==='send'?' để gửi':''}…`:'Đang đồng bộ nhóm…'):'Đang xử lý…'} <button id="stop">Dừng</button></div>`;
}
function renderReview(){
 if(state.batch&&(!draftId||state.busy)&&state.read_job?.state!=='running'){
  const b=state.batch;
  $('#content').innerHTML=`<div class="notice">${b.state==='running'?'Đang gửi':b.state==='completed'?'Hoàn tất':'Đã dừng'} · ${b.completed}/${b.total} ${b.state==='running'?'<button id="stop">Dừng</button>':''}<p>${esc(b.note||'')}${b.skipped?` Bỏ qua ${b.skipped} bài trùng hoặc thiếu quyền.`:''}</p></div>${(b.sources||[]).filter(r=>r.error).map(r=>`<p class="error">Dòng ${r.line}: ${esc(r.error)}</p>`).join('')}${b.items.map(i=>`<article class="review"><strong>${esc(i.group_name||'Nhóm '+i.target.group)}</strong><small>${link(i.target.url,'Bài '+i.post_id)}</small><p class="comment-body">${esc(i.text)}</p><span class="status">${esc(statuses[i.status]||i.status)}</span><small>${esc(diagnosticLabel(i.report?.diagnostic))}</small><button data-batch-detail="${b.items.indexOf(i)}" class="result-detail-trigger">Chi tiết</button></article>`).join('')}`;return;
 }
 if(state.busy){$('#content').innerHTML=progress();return;}
 if(!draftId||!posts.length){$('#content').innerHTML='<div class="empty"><h2>Chưa có danh sách xem trước</h2><button data-tab="groups">Nhập nhóm và nội dung</button></div>';return;}
 $('#content').innerHTML=`<div class="bottom preview-actions"><small>${posts.length} bài đọc được · có thể bỏ chọn hoặc sửa nội dung</small><button id="send-preview" class="primary" ${!selected.size?'disabled':''}>Gửi các bài đã chọn</button></div>`+posts.map(p=>`<article class="review"><h3>${esc(p.group_name||'Nhóm '+p.target.group)}</h3><small>${link(p.target.url,'Bài '+p.post_id)}</small><blockquote>${esc(p.excerpt)}</blockquote>${p.blocked?'<p class="notice warn">Bài đã có lần xử lý hoặc chưa được phép bình luận.</p>':`<label><input type="checkbox" data-selected="${p.post_id}" ${selected.has(p.post_id)?'checked':''}> Chọn bài này</label><label>Nội dung bình luận<textarea data-text="${p.post_id}" maxlength="10000">${esc(texts[p.post_id]||'')}</textarea></label>`}</article>`).join('');
}
function renderHistory(){
 $('#content').innerHTML=`<div class="filters"><label>Tìm trong trang lịch sử<input id="history-query" type="search" value="${esc(historyQuery)}" placeholder="Tài khoản, nhóm, bài"></label><label>Kết quả<select id="history-status"><option value="all">Tất cả</option>${Object.entries(statuses).map(([v,t])=>`<option value="${v}" ${v===historyStatus?'selected':''}>${t}</option>`).join('')}</select></label></div><div id="history-rows"></div><div class="toolbar"><button id="history-prev" ${historyOffset===0?'disabled':''}>Mới hơn</button><span>${historyItems.length?historyOffset+1:0}–${historyOffset+historyItems.length}</span><button id="history-next" ${historyMore?'':'disabled'}>Cũ hơn</button></div>`;renderHistoryRows();
}
function renderHistoryRows(){
 const list=historyItems.filter(h=>(historyStatus==='all'||h.status===historyStatus)&&[h.account_name,h.actor_id,h.group_name,h.target?.post_id].join(' ').toLocaleLowerCase('vi').includes(historyQuery.toLocaleLowerCase('vi')));
 const html=list.length?`<div class="table-wrap"><table><thead><tr><th>Tài khoản</th><th>Nhóm / bài</th><th>Kết quả</th><th>Thời gian</th><th>Chi tiết</th></tr></thead><tbody>${list.map(h=>`<tr class="history-row"><td>${esc(h.account_name||h.actor_id)}<small>${esc(h.actor_id)}${h.account_name_is_current?' · tên hiện tại':''}</small></td><td>${link(h.group_url,h.group_name||'Chưa lưu tên nhóm')}<small>${link(h.target?.url,'Bài '+(h.target?.post_id||''))}</small></td><td>${esc(statuses[h.status]||h.status)}${h.operator_review?'<small>Đã kiểm tra · bỏ qua bài</small>':''}<small>${esc(diagnosticLabel(h.diagnostic))}</small></td><td>${esc(stamp(h.created_at))}</td><td><button data-history-detail="${historyItems.indexOf(h)}">Chi tiết</button></td></tr>`).join('')}</tbody></table></div>`:'<div class="empty">Không có kết quả phù hợp.</div>';
 $('#history-rows').innerHTML=html;
}
function renderSettings(){ $('#content').innerHTML=`<div class="settings-rows"><div class="settings-row"><strong>Phiên bản</strong><span>${esc(state.app_version||UI_PROTOCOL)}</span></div><div class="settings-row"><strong>Kết nối local</strong><span>Đã kết nối</span></div><div class="settings-row"><strong>Thư mục dữ liệu</strong><code>${esc(state.data_directory||'Chưa có thông tin')}</code></div></div><p class="muted">Đóng app sẽ dừng công việc nền. Mở lại không tự gửi tiếp.</p>`;}
const evidenceLabels={verification_redirect:'Chuyển hướng tới bước xác minh.',login_redirect_or_401:'Phản hồi yêu cầu đăng nhập.',http_rate_limit:'Nguồn trả giới hạn yêu cầu.',http_forbidden:'Nguồn trả HTTP 403; chưa rõ nguyên nhân.',graphql_target_permission_message:'Phản hồi đề cập quyền tại bài; chưa đủ xác nhận kết quả gửi.',target_not_commentable:'Bài không có quyền bình luận trong dữ liệu đã đọc.',ambiguous_checkpoint_marker:'Có dấu hiệu văn bản liên quan xác minh; chưa đủ để kết luận.',local_or_parser_exception:'Lỗi xử lý hoặc định dạng dữ liệu.',unclassified_graphql_error:'Phản hồi có lỗi chưa phân loại.'};
function showDetails(h){if(!h)return;detailItem={...h};detailReturn=document.activeElement;const d=h.diagnostic||{};const success=h.status==='confirmed_by_response';$('#detail-content').innerHTML=`<h2 id="detail-title">${esc(statuses[h.status]||syncLabel(h))}</h2><p>${esc(h.note||h.message||'')}</p><div class="scope-notice">${success?'Đã nhận phản hồi xác nhận thao tác. Cần kiểm tra hiển thị hoặc duyệt ở nguồn.':esc(diagnosticLabel(d)||'Chưa có thông tin chẩn đoán.')+'<br>Trạng thái app không phải kết luận tài khoản bị khóa.'}</div><dl class="fact-list"><div><dt>Tài khoản</dt><dd>${esc(h.account_name||h.actor_id||h.account_id||'Chưa ghi nhận')}</dd></div><div><dt>Nguồn</dt><dd>${link(h.group_url||h.target?.url,h.group_name||h.target?.post_id||'Đồng bộ nhóm')}</dd></div><div><dt>Bài cần kiểm tra</dt><dd>${link(h.target?.url,h.target?.post_id||'Chưa lưu link bài')}</dd></div><div><dt>Đã xác nhận</dt><dd>${esc(success?'Phản hồi được nhận diện là thành công.':evidenceLabels[d.evidence]||'Chỉ ghi nhận trạng thái trong lịch sử.')} ${d.http_status?'HTTP '+esc(d.http_status):''}</dd></div><div><dt>Chưa xác nhận</dt><dd>${['outcome_unknown','reserved','unconfirmed'].includes(h.status)?'Chưa biết thao tác đã hoàn tất ở nguồn hay chưa. Không tự gửi lại.':'Không suy ra quyền tại các bài khác từ kết quả này.'}</dd></div><div><dt>Mã lần xử lý</dt><dd>${esc(h.operation_id||h.id||'Chưa có')}</dd></div></dl>${skipReviewPanel(h)}`;$('#detail').showModal();}
function skipReviewPanel(h){
 const owner=state.accounts.find(a=>a.account_id===h.actor_id);
 if(!h.can_skip_after_review||!owner)return '';
 return `<section class="scope-notice"><p>${h.operator_review?'Đã ghi nhận kiểm tra. Kết quả gửi vẫn chưa rõ; bài này tiếp tục bị chặn gửi lại.':'Mở đúng bài và kiểm tra trước. Bỏ qua không đánh dấu gửi thành công hay thất bại, và không gửi lại bài này.'}</p><div id="skip-review-actions"><button id="begin-skip-review" ${state.busy||state.network_busy?'disabled':''}>Đã kiểm tra — bỏ qua bài này</button></div><p id="skip-review-result" role="status"></p></section>`;
}
const sessionHelp=`<ol><li>Mở Facebook trên Chrome và đăng nhập đúng tài khoản của bạn.</li><li>Mở công cụ dành cho nhà phát triển (F12 hoặc Ctrl+Shift+I), chọn <strong>Application → Cookies → https://www.facebook.com</strong>.</li><li>Tìm <strong>c_user</strong> và <strong>xs</strong>. Sao chép giá trị vào hai ô tương ứng trong CommentLab, rồi Lưu.</li></ol><p>c_user là ID tài khoản; xs là phiên đăng nhập. Chỉ nhập trong app trên máy của bạn, không gửi qua chat hoặc chụp ảnh chứa giá trị xs. App không tự lấy cookie từ Chrome.</p><p>datr, fr và sb là cookie bổ sung, không bắt buộc. Có thể nhập file JSON dạng danh sách cookie thay cho nhập tay.</p>`;
function renderHelp(){
 $('#content').innerHTML=`<section class="help-panel"><h2>Bắt đầu</h2><ol><li>Thêm hoặc chọn tài khoản ở bên trái.</li><li>Dán link nhóm/bài, hoặc chọn nhóm đã lưu. Chọn tối đa 10, 20 hoặc 50 bài cho toàn lượt.</li><li>Nhập bình luận và bấm <strong>Gửi bình luận</strong>. App tự lấy bài, bỏ qua bài đã xử lý rồi gửi tuần tự.</li></ol><p><strong>Xem trước là tùy chọn.</strong> Dùng khi muốn xem bài, bỏ chọn hoặc sửa nội dung riêng. Không cần đánh dấu duyệt.</p><details><summary>Lấy c_user và xs từ Chrome</summary>${sessionHelp}</details><details><summary>Sửa, đổi hoặc xóa tài khoản</summary><p>Để trống xs khi sửa sẽ giữ phiên cũ. Đổi c_user tạo tài khoản khác. Xóa chỉ gỡ phiên và nhóm đã lưu; lịch sử và khóa chống trùng được giữ. Trong lúc đồng bộ nhóm có thể chuyển tài khoản và soạn nội dung. Khi đang gửi, danh tính của lượt gửi được cố định.</p></details><details><summary>Link và đồng bộ nhóm</summary><p>Mỗi dòng một link https://www.facebook.com/groups/… hoặc link /posts/ID hay /permalink/ID. Chưa hỗ trợ Page, link share hoặc pfbid. Link bài cũ ngoài danh sách mới nhất có thể chưa đọc được.</p><p>Lưu tài khoản mới tự đồng bộ nhóm ở nền. Thanh tiến độ không có phần trăm khi chưa biết tổng số nhóm. Đồng bộ đọc tiếp từng trang đến khi Facebook báo hết nhóm; tiến độ hiển thị số nhóm và số trang đã đọc. Nếu nguồn lỗi hoặc lặp mốc phân trang, app báo chưa đầy đủ. Danh sách bài được đọc tiếp qua các trang để lấy đủ số đã chọn. Nếu hết bài truy cập được hoặc chưa đọc tiếp được, app báo số thực tế.</p></details><details><summary>Dừng, lỗi và chống trùng</summary><p>Bài đã gửi, đang gửi hoặc chưa rõ kết quả bị khóa trên mọi tài khoản trong app. Dừng chờ request hiện tại rồi bỏ phần còn lại. App không retry hoặc đổi tài khoản để gửi tiếp khi Facebook chặn, yêu cầu xác minh hay kết quả chưa rõ.</p><p>Hãy kiểm tra trên Facebook khi kết quả chưa rõ. Với lần chưa rõ kết quả: mở Lịch sử → Chi tiết → mở bài kiểm tra → Đã kiểm tra — bỏ qua bài này. Xác nhận chỉ ghi nhận bỏ qua và giữ khóa bài; app không tự gửi tiếp lượt cũ. Lỗi phiên/xác minh/hạn chế không được gỡ bằng nút này. Đổi cookie không tự xóa trạng thái hạn chế. Kiểm tra đọc thành công không chứng minh được phép bình luận trở lại.</p></details><details><summary>Lịch sử và dữ liệu</summary><p>Lịch sử ghi tên tài khoản, nhóm, bài, thời gian và kết quả. Tên mới được lưu tại thời điểm gửi; bản ghi cũ chưa có tên sẽ ghi rõ thay vì đoán. Dùng Mới hơn / Cũ hơn để xem tiếp.</p><p>Cookie mã hóa theo người dùng Windows. EXE lưu dữ liệu ở %LOCALAPPDATA%\\CommentLab; bản nguồn có kho riêng. Giữ _internal cạnh EXE, không chia sẻ kho phiên.</p></details></section>`;
}
function editor(edit=false){
 tab='editor';const a=edit?account():null;
 $('#content').innerHTML=`<section class="account-editor"><h2>${a?'Sửa tài khoản':'Thêm tài khoản'}</h2><form id="account-form" autocomplete="off"><label>Tên gợi nhớ<input id="name" maxlength="60" required value="${esc(a?.name||'')}"></label><label>c_user<input id="actor" inputmode="numeric" required value="${esc(a?.account_id||'')}"></label><label>xs<input id="xs" type="password" autocomplete="new-password" placeholder="${a?'Để trống để giữ phiên cũ':'Nhập xs'}"></label><button type="button" id="show-secret">Hiện</button><details><summary>Lấy c_user và xs thế nào?</summary>${sessionHelp}</details><details><summary>Cookie bổ sung / JSON</summary><label>datr<input id="datr"></label><label>fr<input id="fr"></label><label>sb<input id="sb"></label><label>Nhập file JSON<input id="json-file" type="file" accept="application/json,.json"></label></details><p class="muted">Đổi c_user tạo danh tính khác; giữ tài khoản cũ và lịch sử.</p><div class="toolbar"><button class="primary" type="submit">Lưu</button><button type="button" data-tab="groups">Hủy</button></div></form></section>`;$('#name').focus();
}
async function historyPage(offset=0){const v=await api('/api/history',{offset});historyItems=v.items;historyOffset=v.offset;historyMore=v.has_more;}
async function refresh(){
 if(refreshing)return;refreshing=true;
 try{
 const next=await api('/api/state');
 compatible=next.ui_protocol===UI_PROTOCOL;
 if(!compatible){clearTimeout(pollTimer);document.querySelectorAll('button,input,textarea,select').forEach(el=>{el.disabled=true;});throw Error(VERSION_ERROR);}
 const previous=actor(),revision=account()?.revision;
 if(previous!==next.active_account_id){stashDraft(previous);restoreDraft(next.active_account_id);}
 state=next;
 if(previous===actor()&&revision!==undefined&&revision!==account()?.revision)invalidatePreview();
 if(state.read_job?.state==='completed'&&state.read_job.mode!=='send'&&state.read_job.draft_id&&lastRead!==state.read_job.draft_id){
  lastRead=state.read_job.draft_id;draftId=lastRead;posts=state.read_job.posts;texts=Object.fromEntries(posts.map(p=>[p.post_id,commonText]));selected=new Set(posts.filter(p=>!p.blocked).map(p=>p.post_id));tab='review';
  const errors=state.read_job.rows.filter(r=>r.error);message(`Đọc được ${posts.length} bài (tối đa ${state.read_job.requested_count||count}).`+(errors.length?' '+errors.map(r=>`Dòng ${r.line}: ${r.error}`).join(' '):''),!!errors.length);
 }
 if(state.read_job?.state==='stopped'&&!state.busy){const errors=state.read_job.rows.filter(r=>r.error);message(state.read_job.error||errors.map(r=>r.error).join(' ')||'Đã dừng đọc.',true);}
 if(state.batch&&lastBatch!==state.batch.batch_id+state.batch.state){lastBatch=state.batch.batch_id+state.batch.state;message(state.batch.state==='running'?'Đang gửi…':state.batch.state==='completed'?'Đã hoàn tất lượt gửi.':state.batch.note||'Lượt gửi đã dừng.',state.batch.state==='stopped');}
 if(state.sync_job?.account_id===actor()&&state.sync_job.state!=='running'&&lastSync!==state.sync_job.id){lastSync=state.sync_job.id;message(state.sync_job.message,state.sync_job.state==='unavailable');}
 if(tab==='history')await historyPage(historyOffset);
 if(tab==='groups'&&previous===actor()&&$('#source-list'))updateWork();else if(!['editor','delete'].includes(tab))render();if(state.migration_error)message(state.migration_error,true);schedule();
 }finally{refreshing=false;}
}
function schedule(){clearTimeout(pollTimer);if(state.busy||(state.sync_jobs||[]).some(liveSync))pollTimer=setTimeout(()=>refresh().catch(e=>{message(e.message,true);schedule();}),800);}
async function action(fn){if(working)return;working=true;try{await fn();}catch(e){message(e.message,true);}finally{working=false;}}
document.addEventListener('submit',e=>{
 if(e.target.id!=='account-form')return;e.preventDefault();
 action(async()=>{let cookies;const file=$('#json-file').files[0];if(file){if(file.size>90000)throw Error('File JSON quá lớn.');cookies=JSON.parse(await file.text());}
 const payload={account_id:$('#actor').value.trim(),name:$('#name').value.trim(),xs:$('#xs').value,extra:{datr:$('#datr').value,fr:$('#fr').value,sb:$('#sb').value}};if(cookies)payload.cookies=cookies;
 await api('/api/accounts/save',payload);$('#xs').value='';tab='groups';await refresh();render();message('Đã lưu tài khoản. Nhóm sẽ đồng bộ ở nền khi có phiên mới.');});
});
document.addEventListener('input',e=>{
 if(e.target.id==='group-query'){groupQuery=e.target.value;renderSourceList();return;}
 if(e.target.id==='history-query'){historyQuery=e.target.value;renderHistoryRows();return;}
 if(e.target.id==='links'){links=e.target.value;rows=[];invalidatePreview();}
 if(e.target.id==='common-text'){commonText=e.target.value;invalidatePreview();if($('#direct-send'))$('#direct-send').disabled=!account()||!!account()?.blocked||state.busy||state.network_busy||!commonText.trim();}
 if(e.target.dataset.text)texts[e.target.dataset.text]=e.target.value;
});
document.addEventListener('change',e=>{
 const x=e.target;if(x.id==='history-status'){historyStatus=x.value;renderHistoryRows();return;}if(x.dataset.group){x.checked?chosen.add(x.dataset.group):chosen.delete(x.dataset.group);invalidatePreview();if($('#selected-sources'))$('#selected-sources').textContent=selectedSources();}
 if(x.dataset.selected){x.checked?selected.add(x.dataset.selected):selected.delete(x.dataset.selected);$('#send-preview').disabled=!selected.size;}
 if(x.id==='count'){count=Number(x.value);invalidatePreview();renderGroups();}
});
document.addEventListener('click',e=>{
 const b=e.target.closest('button');if(!b||(b.form&&b.type==='submit')||b.disabled||working)return;
 if(b.dataset.sourceMode){sourceMode=b.dataset.sourceMode;renderGroups();return;}
 if(b.id==='close-composer'||b.id==='open-composer'){composerClosed=b.id==='close-composer';renderGroups();return;}
 if(b.id==='begin-skip-review'){$('#skip-review-actions').innerHTML='<p>Giữ khóa bài này. Chỉ cho tài khoản dùng tiếp nếu không còn lần chưa xử lý hoặc lỗi phiên/hạn chế khác.</p><button id="confirm-skip-review">Xác nhận bỏ qua</button> <button id="cancel-skip-review">Hủy</button>';return;}
 if(b.id==='cancel-skip-review'){$('#skip-review-actions').innerHTML='<button id="begin-skip-review">Đã kiểm tra — bỏ qua bài này</button>';return;}
 if(b.id==='confirm-skip-review'){
  const h=detailItem,owner=state.accounts.find(a=>a.account_id===h?.actor_id);if(!h||!owner)return;
  working=true;b.disabled=true;
  (async()=>{try{
   const result=await api('/api/history/skip-reviewed',{account_id:h.actor_id,revision:owner.revision,operation_id:h.operation_id,post_id:h.target.post_id,confirm:true});
   await refresh();if(tab==='history'){await historyPage(historyOffset);renderHistory();}
   detailItem={...h,operator_review:result.review};$('#skip-review-actions').innerHTML='';$('#skip-review-result').textContent=result.message;message(result.message);
  }catch(err){$('#skip-review-result').textContent=err.message;b.disabled=false;}finally{working=false;}})();return;
 }
 if(b.id==='close-detail'){$('#detail').close();detailReturn?.focus();return;}
 if(b.dataset.historyDetail!==undefined){showDetails(historyItems[Number(b.dataset.historyDetail)]);return;}
 if(b.dataset.recentDetail!==undefined){showDetails(state.history[Number(b.dataset.recentDetail)]);return;}
 if(b.dataset.batchDetail!==undefined){const i=state.batch.items[Number(b.dataset.batchDetail)];showDetails({...i.report,status:i.status,group_name:i.group_name,group_url:i.source,target:i.target,actor_id:state.batch.account_id});return;}
 if(b.id==='sync-detail'){showDetails(syncFor(actor()));return;}
 if(b.id==='show-secret'){const x=$('#xs');x.type=x.type==='password'?'text':'password';b.textContent=x.type==='password'?'Hiện':'Ẩn';return;}
 if(b.dataset.tab){action(async()=>{tab=b.dataset.tab;if(tab==='history')await historyPage();message('');render();});return;}
 if(b.id==='add'){editor();return;}if(b.id==='edit'){editor(true);return;}
 if(b.id==='delete'){tab='delete';$('#content').innerHTML=`<section class="review"><h2>Xóa ${esc(account().name)} khỏi tool?</h2><p>Phiên và nhóm đã lưu sẽ bị xóa. Lịch sử và trạng thái khóa vẫn được giữ.</p><button class="danger" id="confirm-delete">Xóa tài khoản</button> <button data-tab="groups">Hủy</button></section>`;return;}
 action(async()=>{
  if(b.dataset.account){if(b.dataset.account===actor())return;await api('/api/accounts/select',{account_id:b.dataset.account});tab='groups';await refresh();message('');}
  if(b.id==='refresh')await refresh();
  if(b.id==='confirm-delete'){const deleted=actor();await api('/api/accounts/delete',{account_id:actor(),confirm:true});draftsByAccount.delete(deleted);clearDraft();tab='groups';await refresh();draftsByAccount.delete(deleted);}
  if(b.id==='stop-sync'){const j=syncFor(actor());await api('/api/groups/stop',{account_id:actor(),job_id:j.id});await refresh();}
  if(b.id==='sync'){await api('/api/groups/sync',{account_id:actor()});message('Đang đồng bộ nhóm…');await refresh();}
  if(b.id==='recheck'){message('Đang kiểm tra phiên…');const v=await api('/api/accounts/recheck',{account_id:actor()});await refresh();message(v.message);}
  if(b.id==='check'){const v=await api('/api/links/check',{account_id:actor(),links});rows=v.rows;state.groups=v.groups;renderGroups();}
  if(b.id==='load'||b.id==='direct-send'){
   const direct=b.id==='direct-send';await api(direct?'/api/send/direct':'/api/links/load',{account_id:actor(),links:sourceInput(),count,...(direct?{text:commonText,confirm:true}:{})});
   draftId=null;posts=[];tab='review';message(direct?'Đang lấy bài để gửi…':'Đang lấy bài để xem trước…');await refresh();
  }
  if(b.id==='stop'){await api('/api/work/stop',{account_id:actor()});message('Đang dừng; chờ request hiện tại kết thúc.');}
  if(b.id==='send-preview'){
   const items=posts.filter(p=>selected.has(p.post_id)&&!p.blocked).map(p=>({post_id:p.post_id,text:texts[p.post_id]||''}));
   const ready=await api('/api/review/prepare',{account_id:actor(),draft_id:draftId,items});
   await api('/api/review/send',{account_id:actor(),operation_id:ready.operation_id,confirm:true});draftId=null;message('Đã bắt đầu gửi.');await refresh();
  }
  if(b.id==='history-next'||b.id==='history-prev'){await historyPage(historyOffset+(b.id==='history-next'?50:-50));renderHistory();}
 });
});
$('#detail').addEventListener?.('click',e=>{if(e.target===$('#detail')){const r=$('#detail').getBoundingClientRect();if(e.clientX<r.left||e.clientX>r.right||e.clientY<r.top||e.clientY>r.bottom)$('#detail').close();}});
window.addEventListener('beforeunload',e=>{if(state.busy||working){e.preventDefault();e.returnValue='';}});
refresh().catch(e=>message(e.message,true));
