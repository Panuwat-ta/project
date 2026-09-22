const DEVTOOLS=process.env.DEVTOOLS_URL || 'http://127.0.0.1:9223';
const APP=process.env.ADMIN_APP_URL || 'http://127.0.0.1:5174';
const targets=await fetch(`${DEVTOOLS}/json/list`).then(r=>r.json());
const page=targets.find(t=>t.type==='page'&&t.url.includes('5174'));
if(!page) throw new Error('page target not found');
const ws=new WebSocket(page.webSocketDebuggerUrl);
let seq=0; const pending=new Map(); const events=[];
ws.onmessage=e=>{const m=JSON.parse(e.data); if(m.id&&pending.has(m.id)){pending.get(m.id)(m);pending.delete(m.id);} else events.push(m);};
await new Promise((res,rej)=>{ws.onopen=res;ws.onerror=rej;});
const send=(method,params={})=>new Promise(res=>{const id=++seq;pending.set(id,res);ws.send(JSON.stringify({id,method,params}));});
await send('Runtime.enable'); await send('Page.enable'); await send('Log.enable');

const bootstrap=`(()=>{
  const token='eyJhbGciOiJub25lIn0.eyJleHAiOjQxMDI0NDQ4MDB9.sig';
  const user={id:999,email:'runtime@example.test',full_name:'Runtime Test',is_superadmin:true,role:'admin'};
  const reportSummary={id:1,category:'fake_slip',status:'pending',created_at:'2026-09-21T12:00:00Z',scan:{total_risk_score:82,thumbnail_url:null},user:{email:'user@example.test',full_name:'Test User'}};
  const reportDetail={...reportSummary,version:1,description:'Runtime fixture report',admin_note:'',allow_research_use:true,metadata:{dimensions:'1080x1080',device:'Test Device'},scan:{total_risk_score:82,visual_score:78,text_score:65,source_score:null,source_status:'unavailable',xai_explanation:'Runtime explanation',text_summary:'Runtime text summary',ocr_text:'runtime OCR',image_hash:'abc123',raw_image_url:null,heatmap_image_url:null,exif_data:{dimensions:'1080x1080'}},user:{email:'user@example.test',full_name:'Test User'}};
  const userSummary={id:1,email:'user@example.test',full_name:'Test User',role:'user',is_active:true,total_scans:3,created_at:'2026-09-01T10:00:00Z'};
  const userDetail={...userSummary,total_reports:1,recent_scans:[{id:'scan-1',total_risk_score:42,status:'completed',created_at:'2026-09-20T10:00:00Z'}]};
  const model={id:1,version_tag:'v1.0.0',is_active:true,status:'active',m_iou:.81,a_acc:.91,m_acc:.85,m_dice:.88,deployed_at:'2026-09-20T10:00:00Z',dataset_reference:'runtime-fixture',artifact_checksum:'abc123',file_path:'/models/model.onnx',framework_compatibility:'ONNX'};
  const audit={id:1,action:'user_status_update',entity_type:'user',entity_id:'1',admin_email:'runtime@example.test',ip_address:'127.0.0.1',user_agent:'Runtime Browser',created_at:'2026-09-21T12:00:00Z',reason:'runtime fixture',before_state:{is_active:true},after_state:{is_active:false}};
  const sessions=[
    {id:'session-1',is_current:true,user_agent:'Chrome Runtime',ip_address:'127.0.0.1',created_at:'2026-09-21T12:00:00Z',last_used_at:'2026-09-21T12:05:00Z'},
    {id:'session-2',is_current:false,user_agent:'Firefox Linux',ip_address:'127.0.0.2',created_at:'2026-09-21T11:00:00Z',last_used_at:'2026-09-21T11:30:00Z'},
  ];
  const dashboard={overview:{scans_today:12,total_scans:100,active_users_today:5,total_users:50},reports:{pending:2,reviewing:1},risk_distribution:{low:50,medium:30,high:20},model:{active_version:'v1.0.0'},category_breakdown:{fake_slip:3,romance_scam:2},scan_trend:[{date:'20 ก.ย.',count:8},{date:'21 ก.ย.',count:12}]};
  const health={database:'healthy',storage:'healthy',models:'healthy',queue:'healthy',last_check:'2026-09-21T12:00:00Z'};
  const json=(body,status=200)=>new Response(JSON.stringify(body),{status,headers:{'content-type':'application/json'}});
  const nativeFetch=window.fetch.bind(window);
  window.fetch=async(input,init={})=>{
    const raw=typeof input==='string'?input:input?.url||String(input);
    const url=new URL(raw,location.origin); const p=url.pathname; const method=(init.method||input?.method||'GET').toUpperCase();
    if(!p.startsWith('/api/v1/admin/')) return nativeFetch(input,init);
    if(p==='/api/v1/admin/refresh'&&method==='POST') return json({access_token:token,user});
    if(p==='/api/v1/admin/dashboard') return json(dashboard);
    if(p==='/api/v1/admin/health') return json(health);
    if(p==='/api/v1/admin/reports/1') return json(reportDetail);
    if(p==='/api/v1/admin/reports') return json({items:[reportSummary],total:1,page:1,limit:15,total_pages:1});
    if(p==='/api/v1/admin/users/1') return json(userDetail);
    if(p==='/api/v1/admin/users') return json({items:[userSummary],total:1,page:1,limit:15,total_pages:1});
    if(p==='/api/v1/admin/models') return json({items:[model],total:1});
    if(p==='/api/v1/admin/dataset/export-jobs') return json({items:[{id:'job-1',status:'succeeded',progress:100,total_rows:5,file_size_bytes:2048,created_at:'2026-09-21T12:00:00Z'}],total:1,page:1,limit:10});
    if(p==='/api/v1/admin/audit-logs') return json({items:[audit],total:1,page:1,limit:50});
    if(p==='/api/v1/admin/me') return json({...user,last_login_at:'2026-09-21T12:00:00Z'});
    if(p==='/api/v1/admin/sessions') return json({items:sessions,total:sessions.length});
    if(p==='/api/v1/admin/search') return json({items:[]});
    return json({detail:'Unhandled runtime fixture endpoint: '+method+' '+p},500);
  };
  const NativeWS=window.WebSocket;
  class FakeAdminWS {
    static CONNECTING=0; static OPEN=1; static CLOSING=2; static CLOSED=3;
    constructor(url,protocols){
      if(!String(url).includes('/api/v1/ws/admin/dashboard')) return new NativeWS(url,protocols);
      this.url=String(url);this.protocols=protocols;this.readyState=FakeAdminWS.CONNECTING;this.listeners=new Map();
      setTimeout(()=>{this.readyState=FakeAdminWS.OPEN;this.#emit('open',{});},0);
    }
    addEventListener(type,fn){const a=this.listeners.get(type)||[];a.push(fn);this.listeners.set(type,a)}
    removeEventListener(type,fn){this.listeners.set(type,(this.listeners.get(type)||[]).filter(x=>x!==fn))}
    send(){}
    close(){if(this.readyState===FakeAdminWS.CLOSED)return;this.readyState=FakeAdminWS.CLOSED;this.#emit('close',{})}
    #emit(type,event){try{this['on'+type]?.(event)}catch{} for(const fn of this.listeners.get(type)||[]){try{fn.call(this,event)}catch{}}}
  }
  window.WebSocket=FakeAdminWS;
})();`;
await send('Page.addScriptToEvaluateOnNewDocument',{source:bootstrap});

const routes=[
  ['/login','ScamGuard Admin'],
  ['/admin/dashboard','ภาพรวม'],
  ['/admin/reports','รายงานรอตรวจ'],
  ['/admin/reports/1','รายงานรอตรวจ'],
  ['/admin/users','ผู้ใช้งาน'],
  ['/admin/users/1','ผู้ใช้งาน'],
  ['/admin/models','โมเดล AI'],
  ['/admin/dataset','ส่งออกชุดข้อมูล'],
  ['/admin/audit-log','บันทึกกิจกรรม'],
  ['/admin/profile','บัญชีและความปลอดภัย'],
];
const viewports=[['mobile',390,844],['desktop',1440,1000]];
const themes=['dark','light'];
const sleep=ms=>new Promise(r=>setTimeout(r,ms));
async function evaluate(expression){const m=await send('Runtime.evaluate',{expression,returnByValue:true,awaitPromise:true});return {value:m.result?.result?.value,exception:m.result?.exceptionDetails};}
const results=[];
for(const [vp,width,height] of viewports){
  await send('Emulation.setDeviceMetricsOverride',{width,height,deviceScaleFactor:1,mobile:false});
  for(const theme of themes){
    for(const [route,expectedHeading] of routes){
      events.length=0;
      await evaluate(`localStorage.setItem('scamguard-admin-theme',${JSON.stringify(theme)})`);
      await send('Page.navigate',{url:APP+route});
      await sleep(650);
      const info=await evaluate(`(async()=>{
        let webmcp={available:!!document.modelContext,toolFound:false,result:null,error:null};
        if(document.modelContext){try{const tools=await document.modelContext.getTools();const tool=tools.find(t=>t.name==='get_admin_page_context');webmcp.toolFound=!!tool;if(tool){const raw=await document.modelContext.executeTool(tool,'{}');webmcp.result=JSON.parse(raw);}}catch(e){webmcp.error=String(e)}}
        const root=document.documentElement;const text=document.body?.innerText||'';
        const visibleError=[...document.querySelectorAll('[role="alert"]')].map(e=>e.textContent?.trim()).filter(Boolean);
        return {path:location.pathname,title:document.title,h1:document.querySelector('h1')?.textContent?.trim()||null,h2:document.querySelector('h2')?.textContent?.trim()||null,theme:root.classList.contains('dark')?'dark':root.classList.contains('light')?'light':'unknown',overflow:root.scrollWidth>root.clientWidth+1,scrollWidth:root.scrollWidth,clientWidth:root.clientWidth,unexpected:text.includes('Unexpected Application Error'),loadError:/ไม่สามารถโหลด|เกิดข้อผิดพลาดในการโหลด/.test(text),alerts:visibleError,scanStatusVisible:text.includes('เสร็จสิ้น'),profileSessionsOk:location.pathname!=='/admin/profile'||(text.includes('เซสชันปัจจุบัน')&&text.includes('เชื่อมต่ออยู่')&&text.includes('เข้าสู่ระบบล่าสุด')&&text.includes('21 ก.ย. 2569 19:00:00')),webmcp,bodySample:text.slice(0,160)};
      })()`);
      const runtimeExceptions=events.filter(e=>e.method==='Runtime.exceptionThrown').map(e=>({text:e.params?.exceptionDetails?.text||'exception',description:e.params?.exceptionDetails?.exception?.description||null,stack:e.params?.exceptionDetails?.stackTrace||null}));
      const consoleErrors=events.filter(e=>e.method==='Runtime.consoleAPICalled'&&e.params?.type==='error').map(e=>(e.params?.args||[]).map(a=>a.value||a.description||'').join(' '));
      const value=info.value||{};
      const web=value.webmcp?.result;
      const pass=!info.exception && value.path===route && value.theme===theme && !value.overflow && !value.unexpected && !value.loadError && runtimeExceptions.length===0 && consoleErrors.length===0 && (route!=='/admin/users/1' || value.scanStatusVisible) && (route!=='/admin/profile' || value.profileSessionsOk) && value.webmcp?.available && value.webmcp?.toolFound && web?.path===route && web?.theme===theme && web?.heading===expectedHeading;
      results.push({vp,width,height,theme,route,expectedHeading,pass,info:value,runtimeExceptions,consoleErrors,evalException:info.exception?.text||null});
    }
  }
}
await send('Emulation.clearDeviceMetricsOverride');
const summary={total:results.length,passed:results.filter(r=>r.pass).length,failed:results.filter(r=>!r.pass).length,failures:results.filter(r=>!r.pass)};
console.log(JSON.stringify({summary,results},null,2));
const {writeFile}=await import('node:fs/promises'); await writeFile(process.env.ADMIN_MATRIX_OUTPUT || '/tmp/admin-all-pages-matrix.json',JSON.stringify({summary,results},null,2));
ws.close();
