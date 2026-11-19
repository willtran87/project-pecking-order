import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import { gzipSync } from 'node:zlib';
import { fileURLToPath } from 'node:url';
import { prepareFrameState } from './web-runtime/frame-state.mjs';

// Run after export. Fail closed if the pinned Emscripten glue changes.
export const originalLink = 'var _emscripten_glLinkProgram=program=>{program=GL.programs[program];GLctx.linkProgram(program);program.uniformLocsById=0;program.uniformSizeAndIdsByName={}};';
export const adoptedLink = 'var _emscripten_glLinkProgram=id=>{var program=GL.programs[id];var prepared=globalThis.__pecking_order_shader_startup?.take(GLctx,program);if(prepared){prepared.name=id;for(var field of ["maxUniformLength","maxAttributeLength","maxUniformBlockNameLength","uniformIdCounter"]){prepared[field]=program[field]}GL.programs[id]=prepared;GLctx.deleteProgram(program);program=prepared;for(var stage of prepared.__pecking_order_shader_stages??[]){GL.shaders[stage.id]=stage.shader;GLctx.deleteShader(stage.original)}delete prepared.__pecking_order_shader_stages}else{GLctx.linkProgram(program)}program.uniformLocsById=0;program.uniformSizeAndIdsByName={}};';

export const originalCompile = 'var _emscripten_glCompileShader=shader=>{GLctx.compileShader(GL.shaders[shader])};';
export const deferredCompile = 'var _emscripten_glCompileShader=id=>{var shader=GL.shaders[id];if(!globalThis.__pecking_order_shader_startup?.deferCompile(GLctx,shader,id)){GLctx.compileShader(shader)}};';

export function addGameplayPrograms(qualityPrograms, audits, runtimeKey) {
  const key = p => JSON.stringify([p.vertex, p.fragment, [...p.attributes].sort((a, b) => a[1].localeCompare(b[1])), p.feedback]);
  for (const audit of audits) {
    if (audit.runtimeKey !== runtimeKey || !qualityPrograms[audit.quality] || audit.errors?.length
      || !Array.isArray(audit.programs) || !Array.isArray(audit.checks) || audit.checks.some(c => !c.success)) {
      throw new Error('Gameplay shader capture must be successful and match this runtime and quality');
    }
    const programs = qualityPrograms[audit.quality];
    const known = new Set(programs.map(key));
    const counts = new Map();
    for (let i = 0; i < audit.programs.length; i++) {
      const p = audit.programs[i];
      if (!audit.checks.some(c => c.index === i && c.success)) continue;
      // Capture the actual createShader type, not attachment order (Godot and
      // the warm-up bridge attach stages in different orders).
      if (p.sources?.length !== 2 || !p.sources.every(s => typeof s === 'string')
        || typeof p.vertex !== 'string' || typeof p.fragment !== 'string'
        || JSON.stringify([...p.sources].sort()) !== JSON.stringify([p.vertex, p.fragment].sort())) throw new Error('Invalid gameplay shader stages');
      const item = { vertex: p.vertex, fragment: p.fragment, attributes: p.attributes, feedback: p.feedback };
      counts.set(key(item), (counts.get(key(item)) ?? 0) + 1);
      if (known.has(key(item))) continue;
      programs.push({ ...item, gameplay: true }); known.add(key(item));
    }
    for (const p of programs) if (p.gameplay) {
      p.copies = Math.max(p.copies ?? 1, counts.get(key(p)) ?? 1);
      if (p.copies > 4) throw new Error('Too many identical first-use gameplay programs');
    }
    if (programs.reduce((n, p) => n + (p.copies ?? 1), 0) > 96 || programs.filter(p => p.gameplay).reduce((n, p) => n + p.copies, 0) > 24) throw new Error('Gameplay shader preparation exceeds its bounded budget');
  }
}

export function prepareRuntime(directory, auditPaths, gameplayAuditPaths = []) {
  const jsPath = path.join(directory, 'index.js');
  let js = fs.readFileSync(jsPath, 'utf8');
  js = prepareFrameState(js);
  if (!js.includes(originalLink) && !js.includes(adoptedLink)) throw new Error('Unsupported Web runtime link bridge; export the pinned engine before preparing startup.');
  if (!js.includes('program.maxUniformLength=program.maxAttributeLength=program.maxUniformBlockNameLength=0;program.uniformIdCounter=1;')) {
    throw new Error('Unsupported Emscripten program bookkeeping; update and verify the adoption bridge before preparing startup.');
  }
  if (!js.includes(originalCompile) && !js.includes(deferredCompile)) throw new Error('Unsupported Web shader compilation bridge');
  const hash = crypto.createHash('sha256');
  for (const file of ['index.wasm', 'index.pck']) hash.update(fs.readFileSync(path.join(directory, file)));
  const runtimeKey = hash.digest('hex');
  const qualityPrograms = {};
  for (const auditPath of Array.isArray(auditPaths) ? auditPaths : [auditPaths]) {
    const audit = JSON.parse(fs.readFileSync(auditPath, 'utf8'));
    if (audit.errors?.length || audit.shaderFailures?.length || !audit.state?.boot?.ready || audit.shaderWarmup) throw new Error('Only successful unprepared real-office captures can produce the startup manifest.');
    const quality = audit.state.settings?.visual_quality ?? 'balanced';
    if (!['low', 'balanced', 'high'].includes(quality) || qualityPrograms[quality]) throw new Error('Invalid or duplicate quality capture');
    qualityPrograms[quality] = audit.programs.slice(1).map((p, index) => {
      const vertex = audit.shaders[(index + 1) * 2], fragment = audit.shaders[(index + 1) * 2 + 1];
      if (JSON.stringify([...p.sources].sort()) !== JSON.stringify([vertex, fragment].sort())) throw new Error('Shader capture ordering mismatch');
      return { vertex, fragment, attributes: p.attributes, feedback: p.feedback };
    });
  }
  if (!qualityPrograms.balanced) throw new Error('A balanced-quality opening capture is required');
  addGameplayPrograms(qualityPrograms, gameplayAuditPaths.map(p => JSON.parse(fs.readFileSync(p, 'utf8'))), runtimeKey);
  // Factor shared GLSL lines before gzip: complete shader strings are larger
  // than gzip's dictionary and otherwise repeat the engine shader library.
  const strings = [], indices = new Map();
  const encode = source => (source.match(/[^\n]*\n|[^\n]+$/g) ?? []).map(line => {
    if (!indices.has(line)) { indices.set(line, strings.length); strings.push(line); }
    return indices.get(line);
  });
  const encodedQualities = Object.fromEntries(Object.entries(qualityPrograms).map(([quality, programs]) => [quality,
    programs.map(p => ({ ...p, vertex: encode(p.vertex), fragment: encode(p.fragment) }))]));
  const manifest = { schema: 2, runtimeKey, strings, programs: encodedQualities.balanced, qualityPrograms: encodedQualities };
  const manifestPath = path.join(directory, 'index.startup-shaders.json.gz');
  fs.writeFileSync(manifestPath, gzipSync(JSON.stringify(manifest), { level: 9 }));
  js = js.replace(originalCompile, deferredCompile).replace(originalLink, adoptedLink).replace(/^globalThis\.__pecking_order_shader_runtime_key="[a-f0-9]+";\n/, '');
  fs.writeFileSync(jsPath, `globalThis.__pecking_order_shader_runtime_key="${runtimeKey}";\n${js}`);
  return { runtimeKey, programs: Object.fromEntries(Object.entries(qualityPrograms).map(([q, p]) => [q, p.reduce((n, item) => n + (item.copies ?? 1), 0)])), gameplayPrograms: Object.fromEntries(Object.entries(qualityPrograms).map(([q, p]) => [q, p.filter(item => item.gameplay).reduce((n, item) => n + item.copies, 0)])), compressedBytes: fs.statSync(manifestPath).size };
}

if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  if (!process.argv[2] || !process.argv[3]) throw new Error('Usage: node tools/prepare_web_startup.mjs EXPORT_DIRECTORY STARTUP_AUDIT_JSON');
  const args = process.argv.slice(3);
  console.log(prepareRuntime(path.resolve(process.argv[2]), args.filter(p => !p.startsWith('--gameplay=')).map(p => path.resolve(p)), args.filter(p => p.startsWith('--gameplay=')).map(p => path.resolve(p.slice('--gameplay='.length)))));
}
