import assert from 'node:assert/strict';
import fs from 'node:fs';
import vm from 'node:vm';
import { test } from 'node:test';
import { installFrameStateTracking, prepareFrameState } from '../../tools/web-runtime/frame-state.mjs';

function fixture(scissor = false, framebuffer = null) {
  const listeners = {};
  const actual = { scissor, drawFramebuffer: framebuffer, readFramebuffer: framebuffer };
  const calls = [];
  let queries = 0;
  const gl = {
    canvas: { width: 1440, height: 900, addEventListener: (name, fn) => { listeners[name] = fn; } },
    getParameter(p) { queries++; return p === 3089 ? actual.scissor : actual.drawFramebuffer; },
    enable(cap) { calls.push(['enable', cap]); if (cap === 3089) actual.scissor = true; },
    disable(cap) { calls.push(['disable', cap]); if (cap === 3089) actual.scissor = false; },
    bindFramebuffer(target, fbo) {
      calls.push(['bind', target, fbo]);
      if (target === 36160 || target === 36009) actual.drawFramebuffer = fbo;
      if (target === 36160 || target === 36008) actual.readFramebuffer = fbo;
    },
    deleteFramebuffer(fbo) {
      if (actual.drawFramebuffer === fbo) actual.drawFramebuffer = null;
      if (actual.readFramebuffer === fbo) actual.readFramebuffer = null;
    },
    blitFramebuffer(...args) { calls.push(['blit', ...args]); },
  };
  return { gl, actual, calls, listeners, queries: () => queries };
}

test('renderer state stays exact across target changes, deletion, and context restoration', () => {
  const first = {}, second = {};
  const f = fixture(true, first);
  const tracked = installFrameStateTracking(f.gl);
  assert.deepEqual(tracked, { scissor: true, drawFramebuffer: first });
  const enable = f.gl.enable;
  assert.equal(installFrameStateTracking(f.gl), tracked);
  assert.equal(f.gl.enable, enable, 'installation must not stack wrappers');
  f.gl.disable(3089);
  f.gl.enable(3042);
  assert.equal(tracked.scissor, false);
  f.gl.bindFramebuffer(36008, second);
  assert.equal(tracked.drawFramebuffer, first, 'read-only binding must not change draw state');
  f.gl.bindFramebuffer(36009, second);
  assert.equal(tracked.drawFramebuffer, second);
  f.gl.deleteFramebuffer(first);
  assert.equal(tracked.drawFramebuffer, second);
  f.gl.deleteFramebuffer(second);
  assert.equal(tracked.drawFramebuffer, null);
  f.gl.bindFramebuffer(36160, first);
  f.gl.enable(3089);
  assert.equal(tracked.drawFramebuffer, f.actual.drawFramebuffer);
  assert.equal(tracked.scissor, f.actual.scissor);
  assert.equal(f.queries(), 2, 'normal changes must not query the driver');
  f.actual.drawFramebuffer = null;
  f.actual.scissor = false;
  f.listeners.webglcontextrestored();
  assert.deepEqual(tracked, { scissor: false, drawFramebuffer: null });
  assert.equal(f.queries(), 4, 'restoration initializes from real driver state once');
});

const source = fs.readFileSync(new URL('../../docs/index.js', import.meta.url), 'utf8');
const prepared = prepareFrameState(source);
test('pinned bridge is idempotent and rejects an unsupported presenter', () => {
  assert.equal(prepareFrameState(prepared), prepared);
  assert.throws(() => prepareFrameState('unsupported engine'), /Unsupported Web frame presenter/);
});

test('WebGL2 presentation keeps the exact blit and restoration with no per-frame queries', () => {
  const start = prepared.indexOf('blitOffscreenFramebuffer:') + 'blitOffscreenFramebuffer:'.length;
  const end = prepared.indexOf(',registerContext:', start);
  assert.ok(start > 0 && end > start);
  const body = prepared.slice(start, end);
  const trackedBlit = vm.runInNewContext(`(${body})`);
  const originalBlit = vm.runInNewContext(`(${body.replace('context.peckingFrameState.scissor', 'gl.getParameter(3089)').replace('context.peckingFrameState.drawFramebuffer', 'gl.getParameter(36006)')})`);
  for (const scissor of [false, true]) {
    for (const fbo of [null, { id: 'render-target' }]) {
      const before = fixture(scissor, fbo), after = fixture(scissor, fbo);
      const offscreen = { id: 'offscreen' };
      const state = installFrameStateTracking(after.gl);
      for (let frame = 0; frame < 120; frame++) {
        originalBlit({ GLctx: before.gl, defaultFbo: offscreen });
        trackedBlit({ GLctx: after.gl, defaultFbo: offscreen, peckingFrameState: state });
      }
      assert.deepEqual(after.calls, before.calls, 'draw commands, sizes, filter and state restoration must match');
      assert.deepEqual(after.actual, before.actual);
      assert.equal(after.queries(), 2, 'only the initial state read is allowed');
      assert.equal(before.queries(), 240);
    }
  }
});
