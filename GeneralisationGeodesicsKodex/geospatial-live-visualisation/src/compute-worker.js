import { buildField } from './compute-engine.js';

self.onmessage = ev => {
  const msg = ev.data || {};
  if (msg.type === 'boot') self.postMessage({ type: 'ready' });
  if (msg.type === 'compute') {
    const field = buildField(msg.events || [], msg.t || Date.now(), msg.grid || { nx: 96, ny: 48 }, msg.gain || 1);
    self.postMessage({ type: 'field', field });
  }
};
