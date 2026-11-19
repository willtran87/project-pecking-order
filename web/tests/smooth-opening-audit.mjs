import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import { chromium } from 'playwright';
const output=path.resolve('../output/web-game/smooth-opening');fs.mkdirSync(output,{recursive:true});
const browser=await chromium.launch({headless:true,args:['--use-gl=angle',`--use-angle=${process.env.WEBGL_BACKEND === 'd3d11' ? 'd3d11' : 'swiftshader'}`]});
const page=await browser.newPage({viewport:{width:2560,height:1600}});page.setDefaultTimeout(120000);
const errors=[];page.on('pageerror',e=>errors.push(String(e)));page.on('console',m=>{if(m.type()==='error')errors.push(m.text());});
const state=()=>page.evaluate(()=>JSON.parse(window.render_game_to_text?.()??'{}'));
async function until(predicate,label){const end=Date.now()+120000;let s;while(Date.now()<end){s=await state();if(predicate(s))return s;await page.waitForTimeout(200);}throw new Error(label+': '+JSON.stringify({first:s.first_clutch,pending:s.pending_decision_kind,dialogue:s.character_dialogue,clock:s.clock_speed_index}));}
async function shot(label){if(process.argv.includes('--quick')&&/^(01|02|03|04)-/.test(label))return;await page.waitForTimeout(750);await page.screenshot({path:path.join(output,label+'.png'),fullPage:true});fs.writeFileSync(path.join(output,label+'.json'),JSON.stringify(await state(),null,2));}
async function primary(){const s=await state(),r=s.first_clutch.primary_button.rect;assert.ok(s.first_clutch.primary_button.visible);const b=await page.locator('canvas').boundingBox();assert.ok(r.height*b.height/720>=43.5,'primary coach action must retain a 44px physical target');await page.mouse.click(b.x+b.width*(r.x+r.width/2)/1280,b.y+b.height*(r.y+r.height/2)/720);}
const evidence={errors};
try {
 const start=Date.now();await page.goto('http://localhost:3001/',{waitUntil:'domcontentloaded'});await until(s=>s.loaded&&s.campaign_stage==='title','title');evidence.bootMs=Date.now()-start;
 evidence.canvas=await page.locator('canvas').evaluate(c=>({width:c.width,height:c.height}));assert.equal(evidence.canvas.width,1600);
 await page.keyboard.press('KeyN');await until(s=>s.first_clutch?.first_hen_prelude,'meet hen');await shot('01-meet-2560');
 await page.keyboard.press('Enter');await until(s=>s.pending_decision_kind==='directive','first policy');await page.keyboard.press('Digit3');await page.keyboard.press('Enter');
 await until(s=>s.pending_decision_kind===''&&s.first_clutch?.stage==='specialty_route','route instruction');
 const dialogue=(await state()).character_dialogue;assert.ok(!dialogue?.visible||dialogue.presentation_mode==='ambient',JSON.stringify(dialogue));await primary();
 await until(s=>s.first_clutch?.stage==='delivery'&&s.clock_speed_index===1,'work begins');await shot('02-work-2560');
 const focus=(await state()).focused_worker_id;const observedFocus=[];const deadline=Date.now()+120000;let reward;
 while(Date.now()<deadline){const s=await state();observedFocus.push(s.focused_worker_id);if(s.first_clutch?.stage==='reinvestment'){reward=s;break;}await page.waitForTimeout(300);}
 assert.ok(reward,'first egg must lead to reward');assert.ok(observedFocus.every(id=>id===focus),'egg must not steal hen focus');
 await page.waitForTimeout(2700);const held=await state();assert.equal(held.pending_decision_kind,'');assert.equal(held.clock_speed_index,0);assert.equal(held.first_clutch.primary_button.label,'CHOOSE UPGRADE');
 await page.setViewportSize({width:1440,height:900});await shot('03-earned-reward-1440');await primary();await until(s=>s.first_clutch?.reinvestment?.modal_visible,'explicit upgrade');await shot('04-upgrade');
 await page.keyboard.press('Digit1');await page.keyboard.press('Enter');const upgraded=await until(s=>s.first_clutch?.reinvestment?.status==='purchased'||s.first_clutch?.reinvestment?.status==='banked','upgrade filed');assert.equal(upgraded.focused_worker_id,focus);evidence.reward=upgraded.first_clutch.reinvestment;
 await page.waitForTimeout(3000);await page.setViewportSize({width:900,height:800});await shot('05-goals-900');assert.equal((await state()).first_clutch.primary_button.label,'CONTINUE SHIFT');await primary();const continued=await until(s=>s.first_clutch?.orders_handoff_acknowledged&&s.clock_speed_index===1,'direct continuation');assert.equal(continued.flockwatch.visible,false,'Continue must resume without a dashboard detour');assert.equal(continued.focused_worker_id,focus,'Continue must retain hen focus');await shot('06-continued-shift');
 await page.keyboard.press('KeyV');await until(s=>s.flockwatch?.visible,'optional full goals');await shot('06-goals-open');await page.keyboard.press('Escape');await until(s=>!s.flockwatch?.visible,'goals closed');const resumed=await until(s=>s.clock_speed_index===1,'return to live shift');assert.match(resumed.shift_objective.readout,new RegExp('QUOTA.* / '+resumed.quota_target));await shot('07-live-shift');
 assert.equal((await state()).flockwatch.visible,false,'resuming must not reopen the focused goals button');
 const live=await until(s=>s.next_action?.copy?.includes('EGGS TO GO'),'stable quota guidance');assert.match(live.next_action.copy,/HENS AUTO-WORK/);assert.equal(parseInt(live.next_action.copy,10),live.quota_target-live.eggs_today,'guidance must match the authoritative remaining quota');evidence.liveGuidance=live.next_action;
 await page.keyboard.press('Space');const paused=await until(s=>s.clock_speed_index===0&&s.next_action?.action_id==='resume_shift','direct resume prompt');assert.match(paused.next_action.copy,/RESUME SHIFT/);assert.equal(paused.next_action.activation_behavior,'execute');await shot('08-paused-resume');
 await page.keyboard.press('Space');await until(s=>s.clock_speed_index===1,'resume again');assert.deepEqual(errors,[]);evidence.passed=true;
} finally {fs.writeFileSync(path.join(output,'audit.json'),JSON.stringify(evidence,null,2));await browser.close();}
console.log('SMOOTH_OPENING_AUDIT_PASSED');
