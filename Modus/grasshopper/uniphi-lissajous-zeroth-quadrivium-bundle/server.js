import express from 'express';
import path from 'path';
import fs from 'fs';

const app = express();
const PORT = Number(process.env.PORT || 8877);

const PUBLIC_DIR = path.resolve('./public');
app.use('/', express.static(PUBLIC_DIR, { maxAge: '1h' }));

app.get('/api/health', (req, res) => res.json({ ok: true, ts: Date.now() }));

app.get('/api/schemas', (req, res) => {
  const dir = path.join(PUBLIC_DIR, 'schemas');
  const out = [];
  if (fs.existsSync(dir)) {
    for (const f of fs.readdirSync(dir)) {
      if (!f.endsWith('.json')) continue;
      out.push({ name: f, path: `/schemas/${f}` });
    }
  }
  res.json({ schemas: out });
});

app.listen(PORT, () => {
  console.log(`[lissajous] listening on http://localhost:${PORT}`);
});
