import { readFile, writeFile, mkdir } from 'node:fs/promises';
import { fileURLToPath } from 'node:url';
import path from 'node:path';
import { Resvg } from '@resvg/resvg-js';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../assets/icons/mingcute');
const manifest = JSON.parse(await readFile(path.join(root, 'manifest.json'), 'utf8'));
await mkdir(path.join(root, 'png'), { recursive: true });
for (const [name, entry] of Object.entries(manifest.icons)) {
  const original = await readFile(path.join(root, entry.svg), 'utf8');
  // White artwork can be tinted by ImageColor3 without changing its alpha.
  const svg = original.replaceAll('currentColor', '#ffffff');
  const renderer = new Resvg(svg, { fitTo: { mode: 'width', value: manifest.size }, font: { loadSystemFonts: false } });
  const png = renderer.render().asPng();
  await writeFile(path.join(root, entry.png), png);
  console.log(`${name}: ${manifest.size}px PNG, ${png.length} bytes`);
}
