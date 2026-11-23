'use strict';
// Isolated UI prototype. No fetch, storage, cookies, app API or external scripts.
const $ = selector => document.querySelector(selector);
const esc = value => String(value ?? '').replace(/[&<>"']/g, c => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
const arrow = '<svg viewBox="0 0 24 24" aria-hidden="true"><path d="m9 5 7 7-7 7"/></svg>';
const people = [
  {id:'demo-an', name:'Minh An', initials:'MA', state:'Bản nháp đang mở'},
  {id:'demo-linh', name:'Thảo Linh', initials:'TL', state:'App tạm dừng'}
];
const scenarios = {
  permission:{title:'Nguồn từ chối truy cập',status:'Lỗi tại nguồn',tone:'warn',scope:'Bài / nguồn yêu cầu',stage:'Đọc nội dung bài',evidence:'Nguồn trả HTTP 403.',uncertain:'Chưa xác định được nguyên nhân từ quyền bài, nhóm hay phiên.',decision:'Dừng yêu cầu tại nguồn này',explanation:'Phản hồi của một nguồn chưa đủ để kết luận tài khoản bị khóa.',next:'Kiểm tra quyền xem bài trên Facebook.',steps:['Bắt đầu đọc nội dung','Nguồn trả HTTP 403','Ghi nhận lỗi tại nguồn']},
  verification:{title:'Dấu hiệu yêu cầu xác minh',status:'App tạm dừng',tone:'error',scope:'Phiên / tài khoản',stage:'Kiểm tra phiên',evidence:'Phản hồi chuyển tới đường dẫn xác minh.',uncertain:'Chưa xác nhận tình trạng tài khoản sau khi mở Facebook.',decision:'App tạm dừng',explanation:'Phản hồi có dấu hiệu yêu cầu xác minh. Đây không phải kết luận tài khoản đã bị khóa.',next:'Kiểm tra phiên trực tiếp trên Facebook.',steps:['Bắt đầu kiểm tra phiên','Nhận đường dẫn xác minh','App tạm dừng công việc']},
  network:{title:'Mất kết nối khi nhận phản hồi',status:'Chưa rõ kết quả',tone:'warn',scope:'Chưa xác định',stage:'Chờ phản hồi',evidence:'Hết thời gian chờ; chưa nhận được kết quả.',uncertain:'Không biết thao tác đã hoàn tất ở nguồn hay chưa.',decision:'App tạm dừng',explanation:'Mất kết nối không có nghĩa thao tác đã thất bại.',next:'Kiểm tra kết quả tại bài trước khi quyết định bước tiếp theo.',steps:['Bắt đầu thao tác','Hết thời gian chờ','Giữ trạng thái chưa rõ kết quả']},
  unknown:{title:'Phản hồi chưa nhận diện được',status:'Chưa rõ kết quả',tone:'warn',scope:'Chưa xác định',stage:'Đọc phản hồi',evidence:'Có phản hồi nhưng chưa đủ dữ liệu để xác nhận kết quả.',uncertain:'Chưa phân biệt được lỗi nguồn, thay đổi định dạng hay lỗi xử lý.',decision:'App tạm dừng',explanation:'Không có bằng chứng để kết luận Facebook khóa tài khoản.',next:'Xem mã chẩn đoán và kiểm tra kết quả tại bài.',steps:['Nhận phản hồi từ nguồn','Không xác định được cấu trúc kết quả','Lưu thông tin để kiểm tra']},
  success:{title:'Đã xác nhận từ phản hồi',status:'Đã xác nhận',tone:'success',scope:'Một bài viết',stage:'Ghi nhận kết quả',evidence:'Phản hồi mẫu có định danh kết quả tương ứng.',uncertain:'Trạng thái hiển thị hoặc duyệt nội dung cần được kiểm tra riêng.',decision:'Đã ghi vào lịch sử',explanation:'Mục này minh họa một kết quả đã được xác nhận từ phản hồi.',next:'Không có việc cần xử lý trong bản thử.',steps:['Nhận phản hồi','Đối chiếu định danh kết quả','Lưu lịch sử']},
  pending:{title:'Chưa thực hiện',status:'Chưa thực hiện',tone:'neutral',scope:'Một mục công việc',stage:'Chưa bắt đầu',evidence:'Chưa có thao tác nào được thực hiện.',uncertain:'Chưa có phản hồi từ nguồn.',decision:'Giữ nguyên mục công việc',explanation:'Mục này chưa được thực hiện, không phải một lần gửi thất bại.',next:'Có thể xem lại nội dung đã chuẩn bị.',steps:['Chuẩn bị mục công việc','Chưa bắt đầu']}
};
const results = [
  {id:'DEMO-104',account:'demo-an',source:'Cộng đồng sáng tạo',post:'Bài mẫu 104',time:'10:42',kind:'permission'},
  {id:'DEMO-103',account:'demo-linh',source:'Góc chia sẻ thiết kế',post:'Bài mẫu 103',time:'10:39',kind:'verification'},
  {id:'DEMO-102',account:'demo-an',source:'Câu lạc bộ sản phẩm',post:'Bài mẫu 102',time:'10:36',kind:'network'},
  {id:'DEMO-101',account:'demo-an',source:'Góc làm việc',post:'Bài mẫu 101',time:'10:34',kind:'unknown'},
  {id:'DEMO-100',account:'demo-linh',source:'Cộng đồng sáng tạo',post:'Bài mẫu 100',time:'10:31',kind:'success'},
  {id:'DEMO-099',account:'demo-an',source:'Chuyện học mỗi ngày',post:'Bài mẫu 099',time:'10:28',kind:'success'},
  {id:'DEMO-098',account:'demo-linh',source:'Góc làm việc',post:'Bài mẫu 098',time:'10:24',kind:'pending'},
  {id:'DEMO-097',account:'demo-an',source:'Câu lạc bộ sản phẩm',post:'Bài mẫu 097',time:'10:20',kind:'pending'}
];
let drafts = {
  'demo-an':{source:'https://example.test/groups/sang-tao',text:'Cảm ơn bạn đã chia sẻ. Mình đã lưu lại để đọc kỹ hơn.',closed:false,saved:'Đã giữ bản nháp'},
  'demo-linh':{source:'https://example.test/groups/thiet-ke',text:'Mình muốn trao đổi thêm về cách bạn thực hiện phần này.',closed:false,saved:'Đã giữ bản nháp'}
};
const clone = value => JSON.parse(JSON.stringify(value));
let backups = [
  {id:'backup-2',name:'Trước cập nhật',time:'19/10/2026 · 09:15',size:'24 KB',snapshot:clone(drafts)},
  {id:'backup-1',name:'Sao lưu thủ công',time:'18/10/2026 · 16:30',size:'22 KB',snapshot:clone(drafts)}
];
let active='demo-an',tab='work',historySearch='',historyAccount='all',historyStatus='all',backupSequence=2;
let pendingRestore=null,returnFocus=null,toastTimer,backupBusy=false,connectionBusy=false;
const person = id => people.find(a=>a.id===id);
const groupNames=['Cộng đồng sáng tạo','Góc chia sẻ thiết kế','Câu lạc bộ sản phẩm','Góc làm việc','Chuyện học mỗi ngày','Thiết kế ứng dụng','Cộng đồng đọc sách','Góc nhiếp ảnh','Học cùng nhau','Sản phẩm số','Không gian sáng tạo','Chia sẻ kinh nghiệm'];
const groupState={};
let accountSequence=0;
function initGroups(id,count=0){groupState[id]={items:groupNames.slice(0,count).map((name,i)=>({id:'group-'+i,name,url:'https://example.test/groups/'+(i+1),origin:'sync'})),selected:new Set(),mode:'joined',search:'',manual:'',feedback:'',job:null};}
initGroups('demo-an',6);initGroups('demo-linh',3);
groupState['demo-an'].selected.add('group-0');
function chosen(id=active){const s=groupState[id];return s.items.filter(g=>s.selected.has(g.id));}
function selectedHTML(){const list=chosen();return list.length?`<span class="selection-count">${list.length} nguồn đã chọn</span><div class="source-chips">${list.map(g=>`<span>${esc(g.name)}</span>`).join('')}</div>`:'<span class="muted">Chọn nhóm ở panel bên cạnh hoặc gắn link.</span>';}
function renderAccounts(){
  $('#account-count').textContent=people.length;
  $('#accounts').innerHTML=people.map(a=>`<button class="account ${a.id===active?'active':''}" data-account="${a.id}" aria-pressed="${a.id===active}"><span class="avatar">${esc(a.initials)}</span><span class="account-copy"><span class="account-name">${esc(a.name)}</span><small data-account-status="${a.id}"></small><progress data-account-progress="${a.id}" max="100" value="0" hidden aria-label="Tiến độ đồng bộ ${esc(a.name)}"></progress></span></button>`).join('');
  refreshSync();
}
function syncHTML(s){const j=s.job;if(!j)return '<div class="sync-caption"><small>Nhóm của tài khoản</small><button class="link-button" id="restart-sync">Đồng bộ</button></div>';
  const label=j.status==='running'?'Đang đồng bộ nhóm':j.status==='paused'?'Đồng bộ đã tạm dừng':'Đồng bộ hoàn tất';
  return `<div class="sync-caption"><strong>${label}</strong><span class="tabular">${j.percent}%</span></div><progress max="100" value="${j.percent}" aria-label="Tiến độ đồng bộ nhóm"></progress><div class="sync-caption"><small>${j.loaded} / 12 nhóm mẫu</small>${j.status==='done'?'<button class="link-button" id="restart-sync">Đồng bộ lại</button>':`<button class="link-button" id="${j.status==='paused'?'resume-sync':'pause-sync'}">${j.status==='paused'?'Tiếp tục':'Tạm dừng'}</button>`}</div>`;
}
function refreshSync(){
  for(const a of people){const s=groupState[a.id],j=s.job,copy=document.querySelector(`[data-account-status="${a.id}"]`),bar=document.querySelector(`[data-account-progress="${a.id}"]`);if(!copy)continue;
    copy.textContent=j&&j.status!=='done'?`${j.status==='paused'?'Tạm dừng':'Đồng bộ nhóm'} · ${j.percent}%`:`${s.items.length} nhóm / nguồn`;
    bar.hidden=!j||j.status==='done';if(j)bar.value=j.percent;
  }
  if(tab==='work'&&$('#group-sync')){const focused=$('#group-sync').contains(document.activeElement)?document.activeElement.id:null;$('#group-sync').innerHTML=syncHTML(groupState[active]);if(focused)document.getElementById(focused)?.focus({preventScroll:true});}
}
function startSync(id){const s=groupState[id];if(s.job?.timer)clearInterval(s.job.timer);s.job={status:'running',percent:0,loaded:0,timer:null};
  s.job.timer=setInterval(()=>{const j=s.job;if(j.status!=='running')return;j.percent=Math.min(100,j.percent+5);const loaded=Math.floor(j.percent*12/100);
    let added=false;for(let i=j.loaded;i<loaded;i++){if(!s.items.some(g=>g.id==='group-'+i)){s.items.push({id:'group-'+i,name:groupNames[i],url:'https://example.test/groups/'+(i+1),origin:'sync'});added=true;}}
    j.loaded=loaded;if(j.percent===100){j.status='done';clearInterval(j.timer);toast('Đã đồng bộ nhóm mẫu của '+person(id).name);}
    refreshSync();if(added&&active===id&&tab==='work'&&s.mode==='joined')renderGroupRows();
  },1400);refreshSync();if(active===id&&tab==='work'&&s.mode==='joined')renderGroupRows();
}
function renderGroupRows(){const s=groupState[active],host=$('#group-rows');if(!host)return;const query=s.search.trim().toLocaleLowerCase('vi');const focused=host.contains(document.activeElement)?document.activeElement.dataset.group:null,scroll=host.scrollTop;const rows=s.items.filter(g=>g.origin==='sync'&&g.name.toLocaleLowerCase('vi').includes(query));
  host.innerHTML=rows.length?rows.map(g=>`<label class="group-row"><input type="checkbox" data-group="${g.id}" ${s.selected.has(g.id)?'checked':''}><span><strong>${esc(g.name)}</strong><small>Đã tham gia · dữ liệu mẫu</small></span></label>`).join(''):`<div class="group-empty">${query?'Không tìm thấy nhóm.':s.job?.status==='running'?'Đang lấy danh sách nhóm…':s.job?.status==='paused'?'Đã tạm dừng. Bấm Tiếp tục để lấy nhóm.':'Chưa có nhóm. Đồng bộ hoặc gắn link thủ công.'}</div>`;
  host.scrollTop=scroll;if(focused)host.querySelector(`[data-group="${focused}"]`)?.focus({preventScroll:true});if($('#group-count'))$('#group-count').textContent=s.items.filter(g=>g.origin==='sync').length;
}
function renderGroupBody(){const s=groupState[active];$('#group-body').innerHTML=s.mode==='joined'?`<label class="sr-only" for="group-search">Tìm nhóm</label><input id="group-search" type="search" placeholder="Tìm nhóm trong tài khoản" value="${esc(s.search)}"><div id="group-rows" class="group-rows"></div>`:`<label for="manual-links">Link nhóm hoặc bài trong nhóm</label><textarea id="manual-links" rows="5" placeholder="Mỗi dòng một link">${esc(s.manual)}</textarea><button id="attach-links" class="primary">Thêm vào danh sách</button><div id="link-feedback" role="status">${esc(s.feedback)}</div><div class="manual-list">${s.items.filter(g=>g.origin==='manual').map(g=>`<label class="group-row"><input type="checkbox" data-group="${g.id}" ${s.selected.has(g.id)?'checked':''}><span><strong>${esc(g.name)}</strong><small>Gắn thủ công · chưa kiểm tra</small></span></label>`).join('')}</div>`;if(s.mode==='joined')renderGroupRows();}
function attachLinks(){const s=groupState[active];let added=0,duplicate=0;const errors=[];
  s.manual.split(/\r?\n/).forEach((line,i)=>{if(!line.trim())return;try{const u=new URL(line.trim());if(u.protocol!=='https:'||!['facebook.com','www.facebook.com','m.facebook.com','example.test'].includes(u.hostname)||!/^\/groups\/[^/]+(?:\/(?:posts|permalink)\/[^/]+)?\/?$/.test(u.pathname))throw Error();u.search='';u.hash='';u.hostname=u.hostname==='example.test'?'example.test':'www.facebook.com';u.pathname=u.pathname.replace(/\/$/,'').replace('/permalink/','/posts/');const url=u.href;const existing=s.items.find(g=>g.url===url);if(existing){duplicate++;s.selected.add(existing.id);return;}const id='manual-'+Date.now()+'-'+i;s.items.push({id,url,name:decodeURIComponent(u.pathname.split('/')[2])+(u.pathname.includes('/posts/')?' · bài viết':''),origin:'manual'});s.selected.add(id);added++;}catch{errors.push('Dòng '+(i+1)+': cần link HTTPS nhóm hoặc bài trong nhóm.');}});
  s.feedback=[added?`Đã thêm ${added} link.`:'',duplicate?`${duplicate} link đã có.`:'',...errors].filter(Boolean).join(' ')||'Dán ít nhất một link.';renderGroupBody();updateSelected();refreshSync();
}
function updateSelected(){const host=$('#selected-sources');if(host)host.innerHTML=selectedHTML();drafts[active].source=chosen().map(g=>g.url).join('\n');}
const pill = kind => `<span class="pill ${scenarios[kind].tone}">${scenarios[kind].status}</span>`;

function toast(text){clearTimeout(toastTimer);$('#toast').textContent=text;$('#toast').hidden=false;toastTimer=setTimeout(()=>{$('#toast').hidden=true;},3200);}
function heading(title,subtitle){return `<div class="page-heading"><div><h1>${title}</h1><p>${subtitle}</p></div><span class="selection-label"><span class="dot"></span>${esc(person(active).name)}</span></div>`;}
function render(){
  renderAccounts();
  document.querySelectorAll('[data-tab]').forEach(b=>b.setAttribute('aria-current',b.dataset.tab===tab?'page':'false'));
  if(tab==='work')renderWork();else if(tab==='history')renderHistory();else if(tab==='settings')renderSettings();else renderHelp();
}
function renderWork(){
  const d=drafts[active];
  $('#view').innerHTML=heading('Làm việc với '+esc(person(active).name),'Chọn nguồn, rồi soạn nội dung.')+`<div class="work-layout"><aside class="groups-panel" aria-label="Nhóm của tài khoản"><div class="section-title compact"><h2>Nhóm / nguồn</h2><span id="group-count" class="count"></span></div><div id="group-sync" class="group-sync">${syncHTML(groupState[active])}</div><div class="source-tabs"><button data-source-mode="joined" aria-pressed="${groupState[active].mode==='joined'}">Nhóm tài khoản</button><button data-source-mode="manual" aria-pressed="${groupState[active].mode==='manual'}">Gắn link</button></div><div id="group-body"></div></aside><div class="work-content">`+(d.closed?
    `<section class="panel draft-closed"><div><h2>Bản nháp của ${esc(person(active).name)}</h2><p>Nội dung của bạn vẫn được giữ.</p></div><button id="open-composer" class="primary">Mở lại soạn thảo</button></section>`:
    `<section class="panel composer" aria-label="Soạn thảo"><div class="section-title"><h2>Soạn nội dung</h2><button id="close-composer" class="quiet">Đóng soạn thảo</button></div><div id="selected-sources" class="selected-sources">${selectedHTML()}</div><div class="field"><div class="field-meta"><label for="draft-text">Nội dung</label><small id="char-count">${d.text.length} / 2.000</small></div><textarea id="draft-text" rows="4" maxlength="2000" placeholder="Nhập nội dung bản nháp">${esc(d.text)}</textarea></div><div class="draft-footer"><small id="draft-status" aria-live="polite">${esc(d.saved)}</small><div class="actions"><button id="preview-draft">Xem bản nháp</button><button id="save-draft" class="primary">Lưu bản nháp</button></div></div></section>`)+
    `<section class="section-gap"><div class="section-title compact"><h2>Kết quả gần đây</h2><button class="link-button" data-tab="history">Xem tất cả</button></div><div class="result-list">${results.slice(0,4).map(r=>`<div class="result-row"><div><strong>${r.source}</strong><small>${esc(person(r.account).name)} · ${r.post} · ${r.time}</small></div>${pill(r.kind)}<button class="icon-button result-open" data-result="${r.id}" aria-label="Chi tiết ${r.post}: ${scenarios[r.kind].title}">${arrow}</button></div>`).join('')}</div></section></div></div>`;
  renderGroupBody();
  updateSelected();
}
function renderHistory(){
  $('#view').innerHTML=heading('Lịch sử','Xem kết quả theo tài khoản và nguồn.')+`<div class="filters"><label for="search-history">Tìm kiếm<input id="search-history" type="search" placeholder="Tên nguồn, bài hoặc mã kết quả" value="${esc(historySearch)}"></label><label for="filter-account">Tài khoản<select id="filter-account"><option value="all">Tất cả tài khoản</option>${people.map(a=>`<option value="${a.id}" ${historyAccount===a.id?'selected':''}>${esc(a.name)}</option>`).join('')}</select></label><label for="filter-status">Kết quả<select id="filter-status"><option value="all">Tất cả kết quả</option>${[['success','Đã xác nhận'],['pending','Chưa thực hiện'],['unknown','Chưa rõ kết quả'],['verification','App tạm dừng'],['permission','Lỗi tại nguồn']].map(([v,t])=>`<option value="${v}" ${historyStatus===v?'selected':''}>${t}</option>`).join('')}</select></label></div><div id="history-results"></div>`;
  renderHistoryRows();
}
function matchingResults(){
  const query=historySearch.trim().toLocaleLowerCase('vi');
  return results.filter(r=>(historyAccount==='all'||r.account===historyAccount)&&(historyStatus==='all'||r.kind===historyStatus||(historyStatus==='unknown'&&r.kind==='network'))&&`${r.source} ${r.post} ${r.id} ${esc(person(r.account).name)}`.toLocaleLowerCase('vi').includes(query));
}
function renderHistoryRows(){
  const rows=matchingResults();
  $('#history-results').innerHTML=rows.length?`<div class="table-wrap"><table><thead><tr><th>Tài khoản</th><th>Nguồn / bài</th><th>Kết quả</th><th>Thời gian</th><th><span class="muted">Chi tiết</span></th></tr></thead><tbody>${rows.map(r=>`<tr><td>${esc(person(r.account).name)}</td><td>${r.source}<small>${r.post}</small></td><td>${pill(r.kind)}</td><td><time>${r.time}</time><small>19/10/2026</small></td><td><button class="icon-button" data-result="${r.id}" aria-label="Chi tiết ${r.post}">${arrow}</button></td></tr>`).join('')}</tbody></table></div><p class="history-meta">${rows.length} kết quả</p>`:'<div class="empty"><p>Không có kết quả phù hợp.</p><button id="reset-filters">Xóa bộ lọc</button></div>';
}
function renderSettings(){
  $('#view').innerHTML=heading('Cài đặt','Ứng dụng và dữ liệu của bạn.')+`<section class="settings-section"><h2>Ứng dụng</h2><div class="settings-rows"><div class="settings-row"><strong>Phiên bản</strong><span>2.0 · Mẫu giao diện</span></div><div class="settings-row"><strong>Kết nối local</strong><span class="actions"><span id="connection-status" class="pill neutral">Mô phỏng: sẵn sàng</span><button id="check-connection" ${connectionBusy?'disabled':''}>${connectionBusy?'Đang kiểm tra…':'Kiểm tra'}</button></span></div><div class="settings-row"><strong>Nơi lưu dữ liệu mẫu</strong><span class="path">Bộ nhớ của trang</span></div></div></section><section class="settings-section"><div class="section-title compact"><h2>Sao lưu</h2><button id="create-backup" class="primary" ${backupBusy?'disabled':''}>${backupBusy?'Đang tạo…':'Tạo bản sao lưu'}</button></div><div id="backup-list">${backups.map(b=>`<div class="backup-row"><div><strong>${esc(b.name)}</strong><small>${esc(b.time)} · ${b.size}</small></div><button class="link-button" data-backup-info="${b.id}">Chi tiết</button><button data-restore="${b.id}">Khôi phục</button></div>`).join('')}</div></section>`;
}
function renderHelp(){
  $('#view').innerHTML=heading('Hướng dẫn','Mở phần bạn cần, rồi quay lại thao tác.')+`<div class="help-list"><details open><summary>Thử nhanh giao diện</summary><ol><li>Thêm tài khoản mẫu để thử đồng bộ nhóm nền; bạn vẫn có thể làm việc ở các tab khác.</li><li>Chọn nhóm của tài khoản hoặc chuyển sang Gắn link.</li><li>Sửa bản nháp, chuyển tài khoản rồi quay lại.</li><li>Bấm một kết quả để xem phạm vi lỗi và bằng chứng.</li><li>Vào Cài đặt để thử sao lưu, sửa nội dung rồi khôi phục.</li></ol></details><details><summary>App tạm dừng có phải tài khoản bị khóa?</summary><p>Không. Panel chi tiết phân biệt trạng thái của app với dấu hiệu từ phản hồi. Khi chưa đủ bằng chứng, kết quả được giữ là chưa rõ.</p></details><details><summary>Dữ liệu trong bản thử nằm ở đâu?</summary><p>Chỉ trong bộ nhớ trang. Tài khoản, kết quả và backup đều là dữ liệu giả. Tải lại trang đặt lại toàn bộ bản thử; không có kết nối Facebook hoặc API app thật.</p></details><details><summary>Dùng bàn phím</summary><p>Tab để di chuyển giữa các điều khiển, Enter để chọn. Escape hoặc bấm vùng ngoài panel để đóng chi tiết.</p></details></div>`;
}
function openSheet(html){returnFocus=document.activeElement;$('#detail-content').innerHTML=html;$('#detail').showModal();}
function closeDialog(id){$('#'+id).close();if(returnFocus?.isConnected)returnFocus.focus();}
function showResult(id){
  const r=results.find(x=>x.id===id),s=scenarios[r.kind];
  openSheet(`${pill(r.kind)}<h2 id="detail-title">${s.title}</h2><p>${r.source} · ${r.post}</p><div class="scope-notice"><strong>${s.decision}</strong>${s.explanation}</div><dl class="fact-list"><div><dt>Tài khoản</dt><dd>${esc(person(r.account).name)}</dd></div><div><dt>Phạm vi</dt><dd>${s.scope}</dd></div><div><dt>Giai đoạn</dt><dd>${s.stage}</dd></div><div><dt>Đã biết</dt><dd>${s.evidence}</dd></div><div><dt>Chưa biết</dt><dd>${s.uncertain}</dd></div><div><dt>Mã chẩn đoán</dt><dd>${r.id}</dd></div></dl><section class="sheet-section"><h3>Diễn biến</h3><ol class="timeline">${s.steps.map((t,i)=>`<li><time>${r.time}:${String(i*2).padStart(2,'0')}</time>${t}</li>`).join('')}</ol></section><section class="sheet-section"><h3>Bước tiếp theo</h3><p>${s.next}</p></section><div class="sheet-actions"><button data-close="detail">Đóng chi tiết</button></div>`);
}
function restoreConfirmation(id){
  pendingRestore=id;returnFocus=document.activeElement;
  const b=backups.find(x=>x.id===id);
  $('#confirm-content').innerHTML=`<h2 id="confirm-title">Khôi phục bản nháp mẫu?</h2><p>Dùng bản <strong>${esc(b.name)}</strong> — ${esc(b.time)}.</p><p>Các bản nháp có trong bản sao lưu sẽ được thay thế. Dữ liệu app thật không bị ảnh hưởng.</p><div class="actions"><button data-close="confirmation" autofocus>Hủy</button><button id="confirm-restore" class="primary">Khôi phục mẫu</button></div>`;
  $('#confirmation').showModal();
}
document.addEventListener('input',event=>{
  const e=event.target;
  if(e.id==='group-search'){groupState[active].search=e.value;renderGroupRows();return;}
  if(e.id==='manual-links'){groupState[active].manual=e.value;return;}
  if(e.id==='search-history'){historySearch=e.value;renderHistoryRows();return;}
  if(e.id==='source'||e.id==='draft-text'){
    drafts[active][e.id==='source'?'source':'text']=e.value;
    drafts[active].saved='Đã giữ thay đổi trong bản nháp';$('#draft-status').textContent=drafts[active].saved;
    if(e.id==='draft-text')$('#char-count').textContent=`${e.value.length} / 2.000`;
  }
});
document.addEventListener('change',event=>{
  if(event.target.dataset.group){const s=groupState[active],id=event.target.dataset.group;event.target.checked?s.selected.add(id):s.selected.delete(id);updateSelected();return;}
  if(event.target.id==='filter-account'){historyAccount=event.target.value;renderHistoryRows();}
  if(event.target.id==='filter-status'){historyStatus=event.target.value;renderHistoryRows();}
});
document.addEventListener('click',event=>{
  const b=event.target.closest('button');if(!b||b.disabled)return;
  if(b.id==='add-account'){$('#account-form').hidden=false;$('#add-account').hidden=true;$('#account-name').focus();return;}
  if(b.id==='cancel-account'){$('#account-form').hidden=true;$('#add-account').hidden=false;$('#add-account').focus();return;}
  if(b.dataset.sourceMode){groupState[active].mode=b.dataset.sourceMode;document.querySelectorAll('[data-source-mode]').forEach(e=>e.setAttribute('aria-pressed',e===b));renderGroupBody();return;}
  if(b.id==='attach-links'){attachLinks();return;}
  if(b.id==='pause-sync'||b.id==='resume-sync'){groupState[active].job.status=b.id==='pause-sync'?'paused':'running';refreshSync();if(groupState[active].mode==='joined')renderGroupRows();return;}
  if(b.id==='restart-sync'){startSync(active);return;}
  if(b.dataset.account){active=b.dataset.account;render();return;}
  if(b.dataset.tab){tab=b.dataset.tab;render();return;}
  if(b.dataset.close){closeDialog(b.dataset.close);return;}
  if(b.dataset.result){showResult(b.dataset.result);return;}
  if(b.dataset.restore){restoreConfirmation(b.dataset.restore);return;}
  if(b.dataset.backupInfo){const info=backups.find(x=>x.id===b.dataset.backupInfo);openSheet(`<span class="pill neutral">Backup mẫu</span><h2 id="detail-title">${esc(info.name)}</h2><p>${esc(info.time)}</p><dl class="fact-list"><div><dt>Dung lượng</dt><dd>${info.size}</dd></div><div><dt>Nội dung</dt><dd>Bản nháp của ${Object.keys(info.snapshot).length} tài khoản mẫu</dd></div><div><dt>Nơi lưu</dt><dd>Bộ nhớ trang</dd></div></dl><div class="sheet-actions"><button data-close="detail">Đóng chi tiết</button></div>`);return;}
  if(b.id==='help'){tab='help';render();}
  if(b.id==='close-composer'||b.id==='open-composer'){drafts[active].closed=b.id==='close-composer';render();$(b.id==='close-composer'?'#open-composer':'#draft-text').focus();}
  if(b.id==='save-draft'){drafts[active].saved='Vừa lưu bản nháp';$('#draft-status').textContent=drafts[active].saved;toast('Đã lưu bản nháp của '+person(active).name);}
  if(b.id==='preview-draft'){const d=drafts[active];openSheet(`<span class="pill neutral">Bản nháp</span><h2 id="detail-title">${esc(person(active).name)}</h2><dl class="fact-list"><div><dt>Nguồn</dt><dd class="draft-preview">${esc(d.source)||'Chưa chọn nguồn'}</dd></div></dl><section class="sheet-section"><h3>Nội dung</h3><p class="draft-preview">${esc(d.text)||'Chưa nhập nội dung'}</p></section><div class="sheet-actions"><button data-close="detail">Quay lại soạn thảo</button></div>`);}
  if(b.id==='reset-filters'){historySearch='';historyAccount=historyStatus='all';renderHistory();$('#search-history').focus();}
  if(b.id==='create-backup'){
    backupBusy=true;const snapshot=clone(drafts);renderSettings();
    setTimeout(()=>{backups.unshift({id:'backup-'+(++backupSequence),name:'Bản sao lưu mới',time:new Date().toLocaleString('vi-VN',{dateStyle:'short',timeStyle:'short'}),size:'24 KB',snapshot});backupBusy=false;if(tab==='settings')renderSettings();toast('Đã tạo bản sao lưu mẫu');},550);
  }
  if(b.id==='check-connection'){
    connectionBusy=true;renderSettings();setTimeout(()=>{connectionBusy=false;if(tab==='settings')renderSettings();toast('Mô phỏng hoàn tất: kết nối local sẵn sàng');},500);
  }
  if(b.id==='confirm-restore'){
    const backup=backups.find(x=>x.id===pendingRestore);drafts={...drafts,...clone(backup.snapshot)};pendingRestore=null;closeDialog('confirmation');render();toast('Đã khôi phục bản nháp mẫu');
  }
});
$('#account-form').addEventListener('submit',event=>{
  event.preventDefault();const name=$('#account-name').value.trim();if(!name){$('#account-name').setCustomValidity('Nhập tên tài khoản mẫu.');$('#account-name').reportValidity();return;}
  const id='demo-new-'+(++accountSequence);people.push({id,name,initials:name.split(/\s+/).slice(-2).map(x=>x[0]).join('').toUpperCase(),state:'Sẵn sàng'});
  drafts[id]={source:'',text:'',closed:false,saved:'Bản nháp mới'};initGroups(id);active=id;tab='work';$('#account-form').reset();$('#account-form').hidden=true;$('#add-account').hidden=false;render();startSync(id);$('#draft-text').focus();
});
$('#account-name').addEventListener('input',()=>$('#account-name').setCustomValidity(''));
for(const id of ['detail','confirmation']){
  const dialog=$('#'+id);
  dialog.addEventListener('click',event=>{if(event.target===dialog){const r=dialog.getBoundingClientRect();if(event.clientX<r.left||event.clientX>r.right||event.clientY<r.top||event.clientY>r.bottom)closeDialog(id);}});
  dialog.addEventListener('close',()=>{if(id==='confirmation')pendingRestore=null;});
}
render();
