import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import { chromium } from 'playwright';

const output = path.resolve('../output/web-game/hen-identity-progression');
fs.mkdirSync(output, { recursive: true });
const evidence = [];
for (const build of process.argv.includes('--after-only') ? ['after'] : ['before', 'after']) {
  const browser = await chromium.launch({ headless: true, args: ['--use-gl=angle', '--use-angle=d3d11'] });
  const page = await browser.newPage({ viewport: { width: 2560, height: 1600 } });
  const errors = [];
  page.on('pageerror', e => errors.push(String(e)));
  page.on('console', m => { if (m.type() === 'error') errors.push(m.text()); });
  if (build === 'before') await page.route('**/game/*', route => {
    const name = new URL(route.request().url()).pathname.split('/').pop();
    const file = path.resolve('../output/identity-before-runtime', name);
    if (!fs.existsSync(file)) return route.continue();
    return route.fulfill({ body: fs.readFileSync(file), contentType: name.endsWith('.wasm') ? 'application/wasm' : name.endsWith('.js') ? 'text/javascript' : name.endsWith('.html') ? 'text/html' : 'application/octet-stream' });
  });
  const state = () => page.evaluate(() => JSON.parse(window.render_game_to_text?.() ?? '{}'));
  const until = async predicate => {
    const end = Date.now() + 120000;
    while (Date.now() < end) { const s = await state(); if (predicate(s)) return s; await page.waitForTimeout(150); }
    fs.writeFileSync(path.join(output, `${build}-failure.json`), JSON.stringify(await state(), null, 2));
    await page.screenshot({ path: path.join(output, `${build}-failure.png`) });
    throw new Error('Identity preview did not settle');
  };
  const shot = async name => { await page.waitForTimeout(900); await page.screenshot({ path: path.join(output, `${build}-${name}.png`), fullPage: true }); };
  try {
    for (const stage of build === 'before' ? ['new'] : ['new', 'earned']) {
      await page.setViewportSize({ width: 2560, height: 1600 });
      await page.goto(`http://localhost:3001/?preview=hen-social&identity=${stage}`, { waitUntil: 'domcontentloaded' });
      await until(s => s.loaded && s.clock_speed_index === 0 && (build === 'before'
        ? s.hen_social?.serial >= 1
        : s.dispatch?.work_progress?.desks?.filter(d => d.worker_id >= 0).length >= 4
          && s.dispatch.work_progress.desks[0].career_seals === (stage === 'earned' ? 1 : 0)
          && (stage === 'new' ? s.hen_social?.serial >= 1 : s.hen_social?.pending >= 1)));
      await page.locator('canvas').focus();
      if ((await state()).character_dialogue?.visible) await page.keyboard.press('Enter');
      // The older social art fixture clears its dialogue without refreshing
      // floor input ownership. Closing Settings restores the normal context.
      await page.keyboard.press('F10');
      await until(s => s.settings?.visible);
      await page.keyboard.press('Escape');
      await until(s => !s.settings?.visible && s.camera?.input_enabled);
      await shot(`${stage}-overview`);
      const settled = await state();
      const desks = settled.dispatch.work_progress.desks.filter(d => d.worker_id >= 0);
      if (build === 'after') {
        assert.ok(desks.length >= 3);
        assert.equal(new Set(desks.map(d => d.desk_identity)).size, desks.length);
        assert.ok(desks.every(d => d.career_seals === (stage === 'earned' ? Math.min(d.worker_id + 1, 3) : 0)));
      }
      for (let hen = 0; hen < 3; hen++) {
        await page.keyboard.press('Escape');
        await until(s => !s.camera.focused);
        await page.waitForTimeout(900);
        const point = (await state()).camera.context_points.find(p => p.worker_id === hen && p.visible);
        const [x, y] = point.screen_position.match(/-?[\d.]+/g).map(Number);
        const bounds = await page.locator('canvas').boundingBox();
        await page.mouse.click(bounds.x + x * bounds.width / 1280, bounds.y + y * bounds.height / 720);
        const focused = await until(s => s.focused_worker_id === hen);
        await shot(`${stage}-hen-${focused.focused_worker_id}`);
      }
      await page.setViewportSize({ width: 900, height: 800 });
      await shot(`${stage}-compact`);
      evidence.push({ build, stage, desks, performance: settled.performance, errors });
    }
    assert.deepEqual(errors, []);
  } finally { await browser.close(); fs.writeFileSync(path.join(output, 'audit.json'), JSON.stringify(evidence, null, 2)); }
}
console.log('HEN_IDENTITY_PROGRESSION_AUDIT_PASSED identities=stable careers=earned materials=rendered errors=0');
