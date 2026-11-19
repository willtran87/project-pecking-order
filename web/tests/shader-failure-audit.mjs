import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import { chromium } from 'playwright';

// Deliberately break one shader in an isolated browser. The optimized engine
// must still diagnose the compiler failure and never bind its failed program.
const output = path.resolve(process.argv[2] ?? '../output/web-game/shader-failure');
fs.mkdirSync(output, { recursive: true });
const browser = await chromium.launch({ headless: true, args: ['--use-gl=angle', `--use-angle=${process.env.WEBGL_BACKEND === 'd3d11' ? 'd3d11' : 'swiftshader'}`] });
const results = [];
try {
  for (const stage of ['vertex', 'fragment']) {
    const page = await browser.newPage({ viewport: { width: 900, height: 800 } });
    const diagnostics = [];
    page.on('console', message => {
      if (/Shader compilation failed|Program linking failed|shader failed to compile/.test(message.text())) diagnostics.push(message.text());
    });
    await page.addInitScript(targetStage => {
      const gl = WebGL2RenderingContext.prototype;
      const source = gl.shaderSource;
      const parameter = gl.getProgramParameter;
      const use = gl.useProgram;
      const failed = new WeakSet();
      window.__shaderFailureAudit = { injected: false, failedLinks: 0, invalidBinds: 0 };
      gl.shaderSource = function(shader, code) {
        const wanted = targetStage === 'vertex' ? this.VERTEX_SHADER : this.FRAGMENT_SHADER;
        // Skip the browser-support probe shaders. Target Godot's known copy
        // variant so this exercises ShaderGLES3's compile/link failure path.
        // Corrupt both optional preparation and the engine's retry. A failure
        // confined to preparation is correctly recovered without engine errors.
        if (code.includes('#define MODE_SIMPLE_COPY') && this.getShaderParameter(shader, this.SHADER_TYPE) === wanted) {
          code += '\n deliberately_invalid_shader_syntax !!!\n';
          window.__shaderFailureAudit.injected = true;
        }
        return source.call(this, shader, code);
      };
      gl.getProgramParameter = function(program, pname) {
        const result = parameter.call(this, program, pname);
        if (pname === this.LINK_STATUS && !result) {
          failed.add(program);
          window.__shaderFailureAudit.failedLinks++;
        }
        return result;
      };
      gl.useProgram = function(program) {
        if (program && failed.has(program)) window.__shaderFailureAudit.invalidBinds++;
        return use.call(this, program);
      };
    }, stage);
    await page.goto('http://localhost:3001/', { waitUntil: 'domcontentloaded' });
    await page.waitForFunction(() => window.__shaderFailureAudit?.failedLinks > 0, null, { timeout: 120000 });
    await page.waitForTimeout(1500);
    const state = await page.evaluate(() => window.__shaderFailureAudit);
    assert.equal(state.injected, true);
    assert.ok(state.failedLinks > 0);
    assert.equal(state.invalidBinds, 0, 'The engine must reject failed programs before use');
    assert.ok(diagnostics.some(line => line.includes('Shader compilation failed')), 'Stage diagnostics must survive batched compilation');
    assert.ok(diagnostics.some(line => line.includes('Program linking failed')), 'Link validation must remain active');
    results.push({ stage, ...state, diagnostics });
    await page.close();
  }
} finally {
  fs.writeFileSync(path.join(output, 'audit.json'), JSON.stringify(results, null, 2));
  await browser.close();
}
console.log('SHADER_FAILURE_AUDIT_PASSED vertex+fragment=diagnosed failed_programs=never_bound');
