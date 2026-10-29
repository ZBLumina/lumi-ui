#!/usr/bin/env node
// A deliberately local module system: literal, source-root-relative Luau IDs.
import { mkdir, readFile, readdir, writeFile } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const compare = (a, b) => (a < b ? -1 : a > b ? 1 : 0);
const normalize = (source) => source.replace(/^\uFEFF/, '').replace(/\r\n?/g, '\n').replace(/\n*$/, '\n');
const quote = (value) => JSON.stringify(value);

async function collect(directory, prefix = '') {
  const files = [];
  const entries = await readdir(directory, { withFileTypes: true });
  entries.sort((a, b) => compare(a.name, b.name));
  for (const entry of entries) {
    const id = prefix + entry.name;
    if (entry.isSymbolicLink()) throw new Error(`Source symlinks are not supported: src/${id}`);
    if (entry.isDirectory()) files.push(...await collect(path.join(directory, entry.name), `${id}/`));
    else if (entry.isFile() && entry.name.endsWith('.luau')) files.push(id);
  }
  return files;
}

// Tokenize just enough Luau to distinguish real imports from comments, string
// contents and object.require calls. Interpolated strings are scanned only in
// their executable {...} expressions. Source offsets survive the rewrite.
function tokenize(source, filename) {
  const tokens = [];
  let at = 0;
  const fail = (message) => { throw new Error(`${filename}:${source.slice(0, at).split('\n').length}: ${message}`); };
  const push = (kind, start, value = source.slice(start, at)) => tokens.push({ kind, start, end: at, value });
  function longString() {
    const match = /^\[(=*)\[/.exec(source.slice(at));
    if (!match) return false;
    const start = at;
    const close = `]${match[1]}]`;
    const end = source.indexOf(close, at + match[0].length);
    if (end < 0) fail('Unterminated long string/comment');
    at = end + close.length;
    push('long-string', start);
    return true;
  }
  function scan(untilBrace = false) {
    while (at < source.length) {
      const char = source[at];
      const start = at;
      if (/\s/.test(char)) { at++; continue; }
      if (source.startsWith('--', at)) {
        at += 2;
        const length = tokens.length;
        if (longString()) tokens.length = length;
        else { const end = source.indexOf('\n', at); at = end < 0 ? source.length : end; }
        continue;
      }
      if (char === '"' || char === "'") {
        at++;
        while (at < source.length && source[at] !== char) {
          if (source[at] === '\\') at += 2;
          else at++;
        }
        if (at >= source.length) fail('Unterminated quoted string');
        at++;
        push('string', start, source.slice(start + 1, at - 1));
        continue;
      }
      if (char === '[' && longString()) continue;
      if (char === '`') {
        at++;
        push('boundary', start, '`');
        while (at < source.length && source[at] !== '`') {
          if (source[at] === '\\') at += 2;
          else if (source[at] === '{') { at++; push('boundary', at - 1, '{'); scan(true); }
          else at++;
        }
        if (at >= source.length) fail('Unterminated interpolated string');
        at++;
        push('boundary', at - 1, '`');
        continue;
      }
      if (/[A-Za-z_]/.test(char)) {
        at++;
        while (at < source.length && /[A-Za-z0-9_]/.test(source[at])) at++;
        push('identifier', start);
        continue;
      }
      const operator = source.startsWith('...', at) ? '...' : source.startsWith('..', at) ? '..' : source.startsWith('::', at) ? '::' : null;
      if (operator) { at += operator.length; push('punctuation', start); continue; }
      at++;
      push('punctuation', start);
      if (char === '{') scan(true);
      if (char === '}' && untilBrace) return;
    }
    if (untilBrace) fail('Unterminated brace expression');
  }
  scan();
  return tokens;
}

function imports(source, filename) {
  const tokens = tokenize(source, filename);
  const dependencies = [];
  const replacements = [];
  for (let index = 0; index < tokens.length; index++) {
    const token = tokens[index];
    if (token.kind !== 'identifier' || token.value !== 'require') continue;
    const previous = tokens[index - 1]?.value;
    if (previous === '.' || previous === ':') continue;
    const argument = tokens[index + 2];
    if (tokens[index + 1]?.value !== '(' || argument?.kind !== 'string' || tokens[index + 3]?.value !== ')') {
      throw new Error(`${filename}: imports must use require("Module") with one literal string ID`);
    }
    const id = argument.value;
    if (!/^[A-Za-z0-9_-]+(?:\/[A-Za-z0-9_-]+)*$/.test(id)) {
      throw new Error(`${filename}: invalid module ID ${quote(id)}; use extensionless source-root-relative IDs`);
    }
    dependencies.push(id);
    replacements.push(token);
  }
  let rewritten = source;
  for (const token of replacements.reverse()) {
    rewritten = rewritten.slice(0, token.start) + '__require' + rewritten.slice(token.end);
  }
  return { dependencies, source: rewritten };
}

function validate(modules) {
  const visited = new Set();
  const visiting = [];
  function visit(id) {
    if (visiting.includes(id)) throw new Error(`Circular import: ${[...visiting, id].join(' -> ')}`);
    if (visited.has(id)) return;
    const module = modules.get(id);
    if (!module) throw new Error(`Missing module ${quote(id)} imported by ${quote(visiting.at(-1) ?? '<entry>')}`);
    visiting.push(id);
    for (const dependency of module.dependencies) visit(dependency);
    visiting.pop();
    visited.add(id);
  }
  visit('init');
  // Also reject broken dependencies in modules that init does not yet import.
  for (const id of modules.keys()) visit(id);
}

function library(modules) {
  const factories = [...modules].map(([id, module]) =>
    `__factories[${quote(id)}] = function(__require)\n-- src/${id}.luau\n${module.source}end\n`).join('\n');
  return `-- Generated by scripts/build.mjs; edit src/*.luau instead.\nlocal __factories = {}\n${factories}\nlocal __cache, __loaded, __loading = {}, {}, {}\nlocal function __require(id)\n    if __loaded[id] then return __cache[id] end\n    if __loading[id] then error("[Lumi UI] Circular import: " .. tostring(id), 0) end\n    local factory = __factories[id]\n    if not factory then error("[Lumi UI] Missing module: " .. tostring(id), 0) end\n    __loading[id] = true\n    local ok, value = pcall(factory, __require)\n    __loading[id] = nil\n    if not ok then error(value, 0) end\n    __cache[id], __loaded[id] = value, true\n    return value\nend\nreturn __require("init")\n`;
}

async function main() {
  const args = process.argv.slice(2);
  if (args.length > 1 || (args.length === 1 && args[0] !== '--check')) throw new Error('Usage: node scripts/build.mjs [--check]');
  const check = args[0] === '--check';
  const files = await collect(path.join(root, 'src'));
  if (!files.includes('init.luau')) throw new Error('Missing entry: src/init.luau');
  const modules = new Map();
  for (const file of files.sort(compare)) {
    const id = file.slice(0, -'.luau'.length);
    if (!/^[A-Za-z0-9_-]+(?:\/[A-Za-z0-9_-]+)*$/.test(id)) throw new Error(`Invalid source module ID: ${file}`);
    modules.set(id, imports(normalize(await readFile(path.join(root, 'src', file), 'utf8')), `src/${file}`));
  }
  validate(modules);
  const built = library(modules);
  const demo = normalize(await readFile(path.join(root, 'examples', 'potassium-pilot.luau'), 'utf8'));
  const tests = normalize(await readFile(path.join(root, 'tests', 'runtime.spec.luau'), 'utf8'));
  const wrap = (body) => `-- Generated by scripts/build.mjs.\nlocal Lumi = (function()\n${built}end)()\n\n${body}`;
  // Compute and validate every artifact before touching an output directory.
  const outputs = new Map([
    ['dist/LumiUI.luau', built],
    ['dist/LumiUI.pilot.luau', wrap(demo)],
    ['tests/runtime.bundle.luau', `-- Generated by scripts/build.mjs.\nlocal function ReloadLumi()\n${built}end\nlocal Lumi = ReloadLumi()\n\n${tests}`],
  ]);
  const stale = [];
  for (const [file, content] of outputs) {
    let current;
    try { current = await readFile(path.join(root, file), 'utf8'); }
    catch (error) { if (error.code !== 'ENOENT') throw error; }
    if (current !== content) stale.push(file);
  }
  if (check) {
    if (stale.length) throw new Error(`Stale or missing generated artifacts: ${stale.join(', ')}. Run npm run build.`);
    console.log(`[Lumi build] check OK: ${outputs.size} artifacts, ${modules.size} modules`);
    return;
  }
  for (const file of stale) {
    await mkdir(path.dirname(path.join(root, file)), { recursive: true });
    await writeFile(path.join(root, file), outputs.get(file), 'utf8');
  }
  console.log(`[Lumi build] ${outputs.size} artifacts, ${modules.size} modules; ${stale.length} written`);
}

main().catch((error) => {
  console.error(`[Lumi build] ${error.message}`);
  process.exitCode = 1;
});
