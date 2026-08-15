import { mkdir, copyFile, writeFile } from 'node:fs/promises';
import { createGeneratorComputeTurnArray } from '../src/index.js';

await mkdir(new URL('../dist/', import.meta.url), { recursive: true });
await copyFile(new URL('../src/index.js', import.meta.url), new URL('../dist/generator-compute-turn-array.mjs', import.meta.url));
const bundle = createGeneratorComputeTurnArray({ turns: 64, radialSteps: 24 });
await writeFile(new URL('../dist/generator-compute-turn-array.bundle.json', import.meta.url), JSON.stringify(bundle.standalone, null, 2));
console.log(`Built ${bundle.samples.length} compute-turn samples.`);
