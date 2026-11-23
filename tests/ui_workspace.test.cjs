const test=require('node:test'),assert=require('node:assert/strict'),vm=require('node:vm'),fs=require('node:fs');
const code=fs.readFileSync('ui/app.js','utf8'),tick=()=>new Promise(resolve=>setImmediate(resolve));
async function fixture(){
 const events={},nodes={},calls=[];
 const node=selector=>nodes[selector]??={innerHTML:'',textContent:'',value:'',classList:{toggle(){}},focus(){},showModal(){},close(){}};
 const state={sync_jobs:[],ui_protocol:'commentlab-local-20261019-4',accounts:[{account_id:'123',name:'Fixture',revision:1}],active_account_id:'123',groups:[],history:[],csrf:'fake',busy:false};
 const responses={};
 const context=vm.createContext({URL,document:{querySelector:node,querySelectorAll:()=>[],addEventListener:(name,fn)=>events[name]=fn},window:{addEventListener(){}},fetch:async(path,opts)=>{calls.push({path,data:opts.body?JSON.parse(opts.body):null});if(path==='/api/accounts/select')state.active_account_id=JSON.parse(opts.body).account_id;const value=responses[path]??state;return {ok:!value.error,status:value.status||200,json:async()=>JSON.parse(JSON.stringify(value))};},setTimeout,clearTimeout,console});
 vm.runInContext(code,context);await tick();calls.length=0;
 const click=(id,dataset={})=>events.click({target:{closest:()=>({id,dataset,disabled:false,form:null})}});
 return {events,nodes,calls,context,click,state,responses};
}
test('current account preserves draft without API',async()=>{
 const f=await fixture();vm.runInContext("draftId='draft';texts={'1000':'reply'};selected.add('1000')",f.context);
 f.click('',{account:'123'});await tick();assert.equal(f.calls.length,0);assert.equal(vm.runInContext('draftId',f.context),'draft');assert.equal(vm.runInContext("selected.has('1000')",f.context),true);
});
test('another account has independent draft',async()=>{
 const f=await fixture();vm.runInContext("draftId='draft';commonText='reply'",f.context);f.click('',{account:'456'});await tick();assert.equal(f.calls[0].path,'/api/accounts/select');assert.equal(vm.runInContext('draftId',f.context),null);assert.equal(vm.runInContext('commonText',f.context),'');
});
test('delete needs inline confirmation',async()=>{
 const f=await fixture();f.click('delete');await tick();assert.match(f.nodes['#content'].innerHTML,/confirm-delete/);assert.equal(f.calls.length,0);f.click('confirm-delete');await tick();assert.equal(f.calls[0].path,'/api/accounts/delete');
});
test('direct send needs no preview or approval and passes 50 total',async()=>{
 const f=await fixture();vm.runInContext("links='https://www.facebook.com/groups/456/';commonText='Hello';count=50",f.context);f.click('direct-send');await tick();
 assert.deepEqual(f.calls[0],{path:'/api/send/direct',data:{account_id:'123',links:'https://www.facebook.com/groups/456/',count:50,text:'Hello',confirm:true}});assert.ok(!f.calls.some(c=>c.path.includes('/review/')));
});
test('optional preview only reads',async()=>{
 const f=await fixture();vm.runInContext("links='https://www.facebook.com/groups/456/'",f.context);f.click('load');await tick();assert.equal(f.calls[0].path,'/api/links/load');assert.ok(!f.calls.some(c=>c.path.includes('send')));
});
test('preview sends selected current text without per-post approval',async()=>{
 const f=await fixture();vm.runInContext("draftId='draft';posts=[{post_id:'1000'},{post_id:'2000'}];texts={'1000':'old'};selected.add('1000')",f.context);
 f.events.input({target:{dataset:{text:'1000'},value:'changed'}});f.responses['/api/review/prepare']={operation_id:'new'};f.click('send-preview');await tick();
 assert.deepEqual(f.calls[0].data,{account_id:'123',draft_id:'draft',items:[{post_id:'1000',text:'changed'}]});assert.equal(f.calls[1].path,'/api/review/send');assert.equal(f.calls[1].data.operation_id,'new');
});
test('source and common-text changes invalidate old preview',async()=>{
 const f=await fixture();for(const id of ['links','common-text']){vm.runInContext("draftId='old';posts=[{}]",f.context);f.events.input({target:{id,dataset:{},value:'changed'}});assert.equal(vm.runInContext('draftId',f.context),null);}
 vm.runInContext("draftId='old'",f.context);f.events.change({target:{id:'count',value:'50',dataset:{}}});assert.equal(vm.runInContext('draftId',f.context),null);assert.match(f.nodes['#content'].innerHTML,/Tối đa 50 bài/);
});
test('send error preserves inputs and displays recovery',async()=>{
 const f=await fixture();vm.runInContext("links='bad link';commonText='my text'",f.context);f.responses['/api/send/direct']={error:'Sửa link'};f.click('direct-send');await tick();assert.equal(vm.runInContext('commonText',f.context),'my text');assert.equal(vm.runInContext('links',f.context),'bad link');assert.equal(f.nodes['#banner'].textContent,'Sửa link');
});
test('help restores session instructions, optional preview and partial read limits',async()=>{
 const f=await fixture();f.click('',{tab:'help'});await tick();const html=f.nodes['#content'].innerHTML;assert.match(html,/Application/);assert.match(html,/c_user/);assert.match(html,/xs/);assert.match(html,/Xem trước là tùy chọn/);assert.match(html,/đọc tiếp qua các trang/);
});
test('history renders account/group names safely with pagination',async()=>{
 const f=await fixture();f.responses['/api/history']={items:[{account_name:'An <script>',actor_id:'123',group_name:'Nhóm & bạn',group_url:'https://www.facebook.com/groups/456/',target:{post_id:'1000',url:'https://www.facebook.com/groups/456/posts/1000/'},created_at:1,status:'confirmed_by_response'}],offset:0,has_more:true};f.click('',{tab:'history'});await tick();const html=f.nodes['#content'].innerHTML+f.nodes['#history-rows'].innerHTML;assert.match(html,/An &lt;script&gt;/);assert.match(html,/Nhóm &amp; bạn/);assert.match(html,/history-next/);assert.match(html,/noopener noreferrer/);assert.doesNotMatch(html,/<script>/);
});
test('finishing direct job replaces pending banner',async()=>{
 const f=await fixture();f.state.batch={batch_id:'one',state:'completed',completed:1,total:1,items:[]};f.click('refresh');await tick();assert.equal(f.nodes['#banner'].textContent,'Đã hoàn tất lượt gửi.');
});

test('old backend route error explains restart without losing input',async()=>{
 const f=await fixture();vm.runInContext("commonText='keep'",f.context);f.responses['/api/send/direct']={error:'Không có thao tác này.',status:404};f.click('direct-send');await tick();assert.match(f.nodes['#banner'].textContent,/khác phiên bản/);assert.equal(vm.runInContext('commonText',f.context),'keep');
});

test('old server state stops API writes before missing routes are called',async()=>{
 const f=await fixture();delete f.state.ui_protocol;
 await assert.rejects(vm.runInContext('refresh()',f.context),/bản app cũ/);
 f.calls.length=0;
 await assert.rejects(vm.runInContext("api('/api/accounts/save',{name:'test'})",f.context),/bản app cũ/);
 assert.equal(f.calls.length,0);
});

test('future incompatible protocol is rejected without erasing draft',async()=>{
 const f=await fixture();vm.runInContext("commonText='preserve me';links='keep link'",f.context);
 f.state.ui_protocol='future-incompatible';
 await assert.rejects(vm.runInContext('refresh()',f.context),/không cùng phiên bản/);
 assert.equal(vm.runInContext('commonText',f.context),'preserve me');
 assert.equal(vm.runInContext('links',f.context),'keep link');
});

test('app hold is not presented as proof Facebook locked the account',async()=>{
 const f=await fixture();f.state.accounts[0].blocked='verification_required';
 f.click('refresh');await tick();
 assert.match(f.nodes['#account-hold'].innerHTML,/App đang tạm dừng gửi; không đồng nghĩa Facebook khóa tài khoản/);
});

test('history distinguishes request errors from account/session signals',async()=>{
 const f=await fixture();
 const value=vm.runInContext("diagnosticLabel({scope:'request',stage:'comment'})",f.context);
 assert.match(value,/bài\/nguồn yêu cầu/);
 assert.match(value,/giai đoạn gửi/);
 assert.equal(vm.runInContext('diagnosticLabel(null)',f.context),'');
});


test('switching back restores per-account composer and selected sources',async()=>{
 const f=await fixture();vm.runInContext("commonText='draft A';links='link A';chosen.add('group A')",f.context);
 f.click('',{account:'456'});await tick();assert.equal(vm.runInContext('commonText',f.context),'');
 vm.runInContext("commonText='draft B'",f.context);f.click('',{account:'123'});await tick();
 assert.equal(vm.runInContext('commonText',f.context),'draft A');assert.equal(vm.runInContext('links',f.context),'link A');assert.equal(vm.runInContext("chosen.has('group A')",f.context),true);
});

test('sync polling preserves mounted composer, caret owner and editor fields',async()=>{
 const f=await fixture();vm.runInContext("commonText='typing';links='manual draft'",f.context);
 f.nodes['#content'].innerHTML='MOUNTED';f.state.sync_jobs=[{id:'job',account_id:'123',state:'running',completed:0,total:null,message:'Reading'}];
 await vm.runInContext('refresh()',f.context);assert.equal(f.nodes['#content'].innerHTML,'MOUNTED');assert.equal(vm.runInContext('commonText',f.context),'typing');
 vm.runInContext("tab='editor'",f.context);f.nodes['#content'].innerHTML='EDITOR';await vm.runInContext('refresh()',f.context);assert.equal(f.nodes['#content'].innerHTML,'EDITOR');
 vm.runInContext('clearTimeout(pollTimer)',f.context);
});

test('unknown sync total never manufactures a percentage',async()=>{
 const f=await fixture();f.state.sync_jobs=[{id:'j',account_id:'123',state:'running',completed:12,total:null,message:'Đang đọc'}];await vm.runInContext('refresh()',f.context);
 const html=vm.runInContext('syncPanel()',f.context);assert.match(html,/<progress/);assert.doesNotMatch(html,/value=|100%/);vm.runInContext('clearTimeout(pollTimer)',f.context);
});

test('stop sync targets only explicit account and job',async()=>{
 const f=await fixture();vm.runInContext("state.sync_jobs=[{id:'j',account_id:'123',state:'running'}]",f.context);f.click('stop-sync');await tick();
 assert.deepEqual(f.calls[0],{path:'/api/groups/stop',data:{account_id:'123',job_id:'j'}});
});


test('unknown write directs to history instead of promising session recheck unlocks it',async()=>{
 const f=await fixture();f.state.accounts[0].blocked='unrecognized_response';f.state.accounts[0].app_hold='unrecognized_response';
 f.click('refresh');await tick();const html=f.nodes['#account-hold'].innerHTML;
 assert.match(html,/Xem lịch sử/);assert.match(html,/không xác nhận kết quả gửi trước/);assert.match(html,/Kiểm tra khả năng đọc/);
});

const pending={operation_id:'pending',actor_id:'123',status:'outcome_unknown',can_skip_after_review:true,target:{post_id:'1000',url:'https://www.facebook.com/groups/456/posts/1000/'}};
test('skip requires confirmation and targets exact history owner/post, never sends',async()=>{
 const f=await fixture();vm.runInContext(`showDetails(${JSON.stringify(pending)})`,f.context);
 assert.match(f.nodes['#detail-content'].innerHTML,/Bài cần kiểm tra/);assert.match(f.nodes['#detail-content'].innerHTML,/groups\/456\/posts\/1000/);
 f.click('begin-skip-review');await tick();assert.equal(f.calls.length,0);assert.match(f.nodes['#skip-review-actions'].innerHTML,/Xác nhận bỏ qua/);
 f.responses['/api/history/skip-reviewed']={review:{action:'skip_keep_duplicate_lock'},message:'Đã bỏ qua'};
 f.click('confirm-skip-review');f.click('confirm-skip-review');await tick();
 assert.deepEqual(f.calls.filter(c=>c.path==='/api/history/skip-reviewed'),[{path:'/api/history/skip-reviewed',data:{account_id:'123',revision:1,operation_id:'pending',post_id:'1000',confirm:true}}]);
 assert.ok(!f.calls.some(c=>c.path.includes('/send')));assert.equal(f.nodes['#skip-review-result'].textContent,'Đã bỏ qua');
});
test('failed acknowledgement preserves dialog and review target',async()=>{
 const f=await fixture();vm.runInContext(`showDetails(${JSON.stringify(pending)})`,f.context);
 f.responses['/api/history/skip-reviewed']={error:'Phiên đã thay đổi',status:409};f.click('confirm-skip-review');await tick();
 assert.equal(f.nodes['#skip-review-result'].textContent,'Phiên đã thay đổi');assert.equal(vm.runInContext('detailItem.operation_id',f.context),'pending');
});
test('session error has no skip action; reviewed outcome stays visibly unknown',async()=>{
 const f=await fixture();vm.runInContext(`showDetails(${JSON.stringify({...pending,can_skip_after_review:false})})`,f.context);
 assert.doesNotMatch(f.nodes['#detail-content'].innerHTML,/begin-skip-review/);
 f.responses['/api/history']={items:[{...pending,operator_review:{action:'skip_keep_duplicate_lock'}}],offset:0,has_more:false};f.click('',{tab:'history'});await tick();
 assert.match(f.nodes['#history-rows'].innerHTML,/Đã kiểm tra · bỏ qua bài/);
});
