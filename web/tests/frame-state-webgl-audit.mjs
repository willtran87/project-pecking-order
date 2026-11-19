import assert from 'node:assert/strict';
import fs from 'node:fs';
import { chromium } from 'playwright';
import { installFrameStateTracking, prepareFrameState } from '../../tools/web-runtime/frame-state.mjs';

const source = prepareFrameState(fs.readFileSync('../docs/index.js', 'utf8'));
const start = source.indexOf('blitOffscreenFramebuffer:') + 'blitOffscreenFramebuffer:'.length;
const body = source.slice(start, source.indexOf(',registerContext:', start));
const original = body.replace('context.peckingFrameState.scissor', 'gl.getParameter(3089)').replace('context.peckingFrameState.drawFramebuffer', 'gl.getParameter(36006)');
const browser = await chromium.launch({ headless: true, args: ['--use-gl=angle', '--use-angle=d3d11'] });
try {
  const page = await browser.newPage();
  const result = await page.evaluate(async ({ installer, body, original }) => {
    const install = (0, eval)(`(${installer})`);
    const trackedBlit = (0, eval)(`(${body})`);
    const originalBlit = (0, eval)(`(${original})`);
    async function run(tracked) {
      const canvas = document.createElement('canvas');
      document.body.append(canvas);
      const gl = canvas.getContext('webgl2', { antialias: false, alpha: false });
      if (!gl) throw new Error('WebGL2 is required');
      const state = tracked ? install(gl) : null;
      const images = [];
      const blit = tracked ? trackedBlit : originalBlit;
      function frame(width, height, scissor) {
        canvas.width = width; canvas.height = height;
        const texture = gl.createTexture();
        gl.bindTexture(gl.TEXTURE_2D, texture);
        gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA8, width, height, 0, gl.RGBA, gl.UNSIGNED_BYTE, null);
        const fbo = gl.createFramebuffer();
        gl.bindFramebuffer(gl.FRAMEBUFFER, fbo);
        gl.framebufferTexture2D(gl.FRAMEBUFFER, gl.COLOR_ATTACHMENT0, gl.TEXTURE_2D, texture, 0);
        gl.disable(gl.SCISSOR_TEST);
        gl.clearColor(.8, .3, .1, 1); gl.clear(gl.COLOR_BUFFER_BIT);
        gl.enable(gl.SCISSOR_TEST); gl.scissor(1, 1, 3, 4);
        gl.clearColor(.1, .7, .3, 1); gl.clear(gl.COLOR_BUFFER_BIT);
        if (!scissor) gl.disable(gl.SCISSOR_TEST);
        blit({ GLctx: gl, defaultFbo: fbo, peckingFrameState: state });
        if (gl.getParameter(gl.DRAW_FRAMEBUFFER_BINDING) !== fbo || gl.isEnabled(gl.SCISSOR_TEST) !== scissor) throw new Error('Presentation changed renderer state');
        gl.bindFramebuffer(gl.READ_FRAMEBUFFER, null);
        const pixels = new Uint8Array(width * height * 4);
        gl.readPixels(0, 0, width, height, gl.RGBA, gl.UNSIGNED_BYTE, pixels);
        images.push(Array.from(pixels));
        gl.deleteFramebuffer(fbo);
        if (tracked && state.drawFramebuffer !== null) throw new Error('Deleted framebuffer remained tracked');
        gl.deleteTexture(texture);
        if (gl.getError() !== gl.NO_ERROR) throw new Error('WebGL error');
      }
      frame(8, 8, false); frame(13, 9, true); frame(8, 8, false);
      const extension = gl.getExtension('WEBGL_lose_context');
      if (!extension) throw new Error('Context restoration test unavailable');
      const restored = new Promise((resolve, reject) => {
        const timer = setTimeout(() => reject(new Error('Context did not restore')), 10000);
        canvas.addEventListener('webglcontextlost', event => {
          event.preventDefault(); setTimeout(() => extension.restoreContext(), 100);
        }, { once: true });
        canvas.addEventListener('webglcontextrestored', () => { clearTimeout(timer); resolve(); }, { once: true });
      });
      extension.loseContext(); await restored;
      frame(13, 9, true);
      canvas.remove();
      return images;
    }
    const before = await run(false), after = await run(true);
    return { equal: JSON.stringify(before) === JSON.stringify(after), frames: after.length, hasColors: new Set(after[0]).size > 3 };
  }, { installer: installFrameStateTracking.toString(), body, original });
  assert.deepEqual(result, { equal: true, frames: 4, hasColors: true });
  console.log('FRAME_STATE_WEBGL_AUDIT_PASSED pixels=identical resize=preserved context-restoration=passed errors=0');
} finally { await browser.close(); }
