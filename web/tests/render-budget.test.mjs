import assert from 'node:assert/strict';
import test from 'node:test';
import { gameRenderSize } from '../lib/game-render-budget.ts';

test('balanced limits high-DPI fill cost while high preserves showcase resolution', () => {
  assert.deepEqual(gameRenderSize(2560, 2, 'balanced'), { width: 1600, height: 900 });
  assert.deepEqual(gameRenderSize(1440, 2, 'balanced'), { width: 1440, height: 810 });
  assert.deepEqual(gameRenderSize(1440, 2, 'high'), { width: 2560, height: 1440 });
  assert.deepEqual(gameRenderSize(2560, 2, 'low'), { width: 1280, height: 720 });
});
test('compact screens and malformed dimensions keep a readable finite canvas', () => {
  assert.deepEqual(gameRenderSize(700, 3, 'balanced'), { width: 1280, height: 720 });
  assert.deepEqual(gameRenderSize(NaN, Infinity, 'unknown'), { width: 1280, height: 720 });
});
