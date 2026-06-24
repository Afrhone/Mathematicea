import express from 'express';
import fs from 'fs';
import path from 'path';
import { WebSocketServer } from 'ws';
import http from 'http';
import zlib from 'zlib';
import crypto from 'crypto';

const PORT = Number(process.env.PORT || 8787);
const DATA_DIR = process.env.DATA_DIR || '/data';
const GRAPH_PATH = path.join(DATA_DIR, 'graph.json');
const METRICS_PATH = path.join(DATA_DIR, 'metrics.json');
const ADMIN_STATE_PATH = path.join(DATA_DIR, 'admin-state.json');
const QUANTUM_STATE_PATH = path.join(DATA_DIR, 'quantum-state.json');

const ECOSYSTEM_CONFIG_PATH = process.env.ECOSYSTEM_CONFIG_PATH || path.resolve('./config/ecosystem.modules.json');
const CIPHER_SCHEMA_SOURCE_PATH = process.env.CIPHER_SCHEMA_PATH || '/home/kobalts71-n--1/hypergraph_meta_cluster_bundle/numeral/grapheme numeral/phoneme/numeral.encoder.cipher.json';
const CIPHER_SCHEMA_FALLBACK_PATH = path.resolve('./config/numeral.encoder.cipher.json');
const ECOSYSTEM_URL_MODE = process.env.ECOSYSTEM_URL_MODE || 'auto';
const ADMIN_TOKEN = process.env.ADMIN_TOKEN || 'admin-change-me';
const IBM_QUANTUM_ENDPOINT = process.env.IBM_QUANTUM_ENDPOINT || '';
const IBM_QUANTUM_API_KEY = process.env.IBM_QUANTUM_API_KEY || '';
const RUNNING_IN_DOCKER = fs.existsSync('/.dockerenv');
const URL_MODE = ECOSYSTEM_URL_MODE === 'auto'
  ? (RUNNING_IN_DOCKER ? 'internal' : 'external')
  : ECOSYSTEM_URL_MODE;

function safeReadJson(p, fallback) {
  try { return JSON.parse(fs.readFileSync(p, 'utf8')); } catch { return fallback; }
}
function safeWriteJson(p, obj) {
  fs.mkdirSync(path.dirname(p), { recursive: true });
  fs.writeFileSync(p, JSON.stringify(obj, null, 2), 'utf8');
}

const DEFAULT_GRAPH = {
  meta: { id: 'demo', created_at: Date.now(), schema: 'hp-graph-v1' },
  nodes: [
    { id: 'axiom:A0', label: 'A0 Nomos/Ethos', kind: 'axiom' },
    { id: 'inv:digest', label: 'Invariant: digest', kind: 'invariant' },
    { id: 'op:publish', label: 'Publish Anchor', kind: 'action' },
    { id: 'belief:mesh', label: 'Belief Mesh', kind: 'belief' }
  ],
  links: [
    { source: 'axiom:A0', target: 'belief:mesh', w: 0.8, kind: 'constrains' },
    { source: 'inv:digest', target: 'op:publish', w: 0.9, kind: 'requires' },
    { source: 'op:publish', target: 'belief:mesh', w: 0.5, kind: 'anchors' }
  ],
  hyperedges: [
    { id: 'h:stage', label: 'Stage Edge', members: ['axiom:A0', 'inv:digest', 'op:publish'], kind: 'hyperedge' }
  ]
};

const DEFAULT_ECOSYSTEM_CONFIG = {
  version: '1.0.0',
  name: 'hypergraph-polyfractal-ecosystem',
  updated_at: new Date().toISOString().slice(0, 10),
  workflow: {
    name: 'fallback-workflow',
    steps: ['polyfractal-gateway']
  },
  artifacts: {
    cipher_schema: {
      source_path: CIPHER_SCHEMA_SOURCE_PATH,
      fallback_path: CIPHER_SCHEMA_FALLBACK_PATH,
      kind: 'schema',
      domain: 'phoneme-numeral-encoder'
    }
  },
  modules: [
    {
      id: 'polyfractal-gateway',
      name: 'Hypergraph Polyfractal Gateway',
      domain: 'architecture',
      internal_url: 'http://hypergraph-polyfractal:8787',
      external_url: 'http://localhost:8787',
      web_ui: 'http://localhost:8787/',
      health_path: '/api/health',
      depends_on: [],
      capabilities: ['workflow-orchestration', 'business-intelligence', 'webui', 'gated-monitoring', 'admin-management'],
      bi_signals: ['entropy', 'drift'],
      gated_monitoring: true,
      admin_managed: true
    }
  ]
};

if (!fs.existsSync(GRAPH_PATH)) safeWriteJson(GRAPH_PATH, DEFAULT_GRAPH);

function sanitizeEcosystemConfig(rawConfig) {
  const cfg = rawConfig && typeof rawConfig === 'object' ? rawConfig : DEFAULT_ECOSYSTEM_CONFIG;
  const modules = Array.isArray(cfg.modules) ? cfg.modules : [];
  const rawCipherArtifact = cfg.artifacts?.cipher_schema || {};
  const cipherArtifact = {
    source_path: String(rawCipherArtifact.source_path || CIPHER_SCHEMA_SOURCE_PATH),
    fallback_path: String(rawCipherArtifact.fallback_path || CIPHER_SCHEMA_FALLBACK_PATH),
    kind: String(rawCipherArtifact.kind || 'schema'),
    domain: String(rawCipherArtifact.domain || 'phoneme-numeral-encoder')
  };
  return {
    version: cfg.version || DEFAULT_ECOSYSTEM_CONFIG.version,
    name: cfg.name || DEFAULT_ECOSYSTEM_CONFIG.name,
    updated_at: cfg.updated_at || DEFAULT_ECOSYSTEM_CONFIG.updated_at,
    workflow: {
      name: cfg.workflow?.name || DEFAULT_ECOSYSTEM_CONFIG.workflow.name,
      steps: Array.isArray(cfg.workflow?.steps)
        ? cfg.workflow.steps.map((step) => String(step))
        : [...DEFAULT_ECOSYSTEM_CONFIG.workflow.steps]
    },
    artifacts: {
      cipher_schema: cipherArtifact
    },
    modules: modules.map((m) => ({
      id: String(m.id || ''),
      name: String(m.name || m.id || 'unnamed-module'),
      domain: String(m.domain || 'unknown'),
      internal_url: m.internal_url ? String(m.internal_url) : undefined,
      external_url: m.external_url ? String(m.external_url) : undefined,
      public_url: m.public_url ? String(m.public_url) : undefined,
      web_ui: m.web_ui ? String(m.web_ui) : undefined,
      health_path: m.health_path ? String(m.health_path) : '/api/health',
      depends_on: Array.isArray(m.depends_on) ? m.depends_on.map((x) => String(x)) : [],
      capabilities: Array.isArray(m.capabilities) ? m.capabilities.map((x) => String(x)) : [],
      bi_signals: Array.isArray(m.bi_signals) ? m.bi_signals.map((x) => String(x)) : [],
      gated_monitoring: Boolean(m.gated_monitoring),
      admin_managed: m.admin_managed !== false
    })).filter((m) => m.id)
  };
}

function loadEcosystemConfig() {
  const raw = safeReadJson(ECOSYSTEM_CONFIG_PATH, DEFAULT_ECOSYSTEM_CONFIG);
  return sanitizeEcosystemConfig(raw);
}

function resolveCipherSchemaPaths(config) {
  const artifact = config?.artifacts?.cipher_schema || {};
  const fromArtifact = [
    artifact.source_path ? String(artifact.source_path) : '',
    artifact.fallback_path ? String(artifact.fallback_path) : ''
  ];
  const defaults = [CIPHER_SCHEMA_SOURCE_PATH, CIPHER_SCHEMA_FALLBACK_PATH];
  const ordered = [...fromArtifact, ...defaults].filter(Boolean);
  return [...new Set(ordered)];
}

function loadCipherSchema(config) {
  const paths = resolveCipherSchemaPaths(config || loadEcosystemConfig());
  for (const candidate of paths) {
    const raw = safeReadJson(candidate, null);
    if (raw && typeof raw === 'object') {
      return { ok: true, schema: raw, path: candidate };
    }
  }
  return { ok: false, schema: null, path: null };
}

function nonEmptyString(v) {
  return typeof v === 'string' && v.trim().length > 0;
}

function validateCipherPayload(payload, schema) {
  const errors = [];
  if (!payload || typeof payload !== 'object' || Array.isArray(payload)) {
    return { valid: false, kind: 'Unknown', errors: ['Payload must be a JSON object'] };
  }

  const defs = schema?.$defs || {};
  const reqRequired = Array.isArray(defs?.EncodeRequest?.required) ? defs.EncodeRequest.required : ['key'];
  const resRequired = Array.isArray(defs?.EncodeResponse?.required)
    ? defs.EncodeResponse.required
    : [
      'ipa_tokens',
      'symbol_ids',
      'radix',
      'integer_base10',
      'integer_base16',
      'magnitude_bits',
      'pointers',
      'metrics',
      'invariants'
    ];

  const looksLikeResponse = resRequired.some((k) => Object.prototype.hasOwnProperty.call(payload, k));
  const kind = looksLikeResponse ? 'EncodeResponse' : 'EncodeRequest';

  if (kind === 'EncodeRequest') {
    for (const field of reqRequired) {
      if (!Object.prototype.hasOwnProperty.call(payload, field)) errors.push(`Missing required field: ${field}`);
    }
    if (!nonEmptyString(payload.key)) errors.push('Field key must be a non-empty string');
    if (payload.mode != null && !['auto', 'ipa'].includes(String(payload.mode))) {
      errors.push('Field mode must be one of: auto, ipa');
    }
    if (String(payload.mode || 'auto') === 'ipa' && !nonEmptyString(payload.ipa)) {
      errors.push('Field ipa is required when mode=ipa');
    }
    if (payload.text != null && typeof payload.text !== 'string') {
      errors.push('Field text must be a string when provided');
    }
  } else {
    for (const field of resRequired) {
      if (!Object.prototype.hasOwnProperty.call(payload, field)) errors.push(`Missing required field: ${field}`);
    }
    if (!Array.isArray(payload.ipa_tokens)) errors.push('Field ipa_tokens must be an array');
    if (!Array.isArray(payload.symbol_ids)) errors.push('Field symbol_ids must be an array');
    if (payload.integer_base10 != null && !/^[0-9]+$/.test(String(payload.integer_base10))) {
      errors.push('Field integer_base10 must match ^[0-9]+$');
    }
    if (payload.integer_base16 != null && !/^0x[0-9a-fA-F]+$/.test(String(payload.integer_base16))) {
      errors.push('Field integer_base16 must match ^0x[0-9a-fA-F]+$');
    }
    if (payload.pointers && typeof payload.pointers === 'object') {
      if (payload.pointers.kv_ptr64 != null && !/^0x[0-9a-fA-F]{16}$/.test(String(payload.pointers.kv_ptr64))) {
        errors.push('Field pointers.kv_ptr64 must match ^0x[0-9a-fA-F]{16}$');
      }
      if (payload.pointers.vram_ptr64 != null && !/^0x[0-9a-fA-F]{16}$/.test(String(payload.pointers.vram_ptr64))) {
        errors.push('Field pointers.vram_ptr64 must match ^0x[0-9a-fA-F]{16}$');
      }
    }
  }

  return {
    valid: errors.length === 0,
    kind,
    errors
  };
}

function clamp01(v) {
  const n = Number(v);
  if (!Number.isFinite(n)) return 0;
  return Math.max(0, Math.min(1, n));
}

function sha256Hex(value) {
  return crypto.createHash('sha256').update(String(value)).digest('hex');
}

function computeUniverseDiffusionHash(payload, context = {}) {
  return sha256Hex(JSON.stringify({ payload, context }));
}

function readQuantumStateStore() {
  const store = safeReadJson(QUANTUM_STATE_PATH, { updated_at: null, latest_id: null, states: [] });
  if (!store || typeof store !== 'object') return { updated_at: null, latest_id: null, states: [] };
  if (!Array.isArray(store.states)) store.states = [];
  return store;
}

function writeQuantumStateStore(store) {
  safeWriteJson(QUANTUM_STATE_PATH, {
    updated_at: new Date().toISOString(),
    latest_id: store.latest_id || null,
    states: Array.isArray(store.states) ? store.states.slice(-128) : []
  });
}

function riskBand(score) {
  if (score < 0.25) return 'low';
  if (score < 0.5) return 'moderate';
  if (score < 0.75) return 'elevated';
  return 'critical';
}

function fallbackQuantumResult(payload, seedHash) {
  const source = JSON.stringify({ payload, seedHash });
  const diffusionHash = sha256Hex(source);
  const a = parseInt(diffusionHash.slice(0, 8), 16);
  const b = parseInt(diffusionHash.slice(8, 16), 16);
  const c = parseInt(diffusionHash.slice(16, 24), 16);
  const d = parseInt(diffusionHash.slice(24, 32), 16);
  const total = a + b + c + d || 1;

  return {
    provider: 'systemic-hyperbolic-fallback',
    counts: {
      '00': a,
      '01': b,
      '10': c,
      '11': d
    },
    probabilities: {
      '00': Number((a / total).toFixed(6)),
      '01': Number((b / total).toFixed(6)),
      '10': Number((c / total).toFixed(6)),
      '11': Number((d / total).toFixed(6))
    },
    diffusion_hash: diffusionHash,
    linear_functor_projection: {
      seed_modulus: (a ^ b ^ c ^ d) % 9973,
      curvature_term: Number((((a + d) - (b + c)) / total).toFixed(6))
    }
  };
}

function readAdminState() {
  const state = safeReadJson(ADMIN_STATE_PATH, { updated_at: null, gates: {} });
  if (!state || typeof state !== 'object') return { updated_at: null, gates: {} };
  if (!state.gates || typeof state.gates !== 'object') state.gates = {};
  return state;
}

function writeAdminState(nextState) {
  safeWriteJson(ADMIN_STATE_PATH, {
    updated_at: new Date().toISOString(),
    gates: nextState.gates || {}
  });
}

function resolveModuleUrl(moduleDef) {
  if (URL_MODE === 'internal') return moduleDef.internal_url || moduleDef.external_url || '';
  if (URL_MODE === 'external') return moduleDef.external_url || moduleDef.internal_url || '';
  return moduleDef.external_url || moduleDef.internal_url || '';
}

function getGateEntry(moduleId, state) {
  const entry = state?.gates?.[moduleId];
  if (entry == null) return null;
  if (typeof entry === 'boolean') return { enabled: entry, reason: null, updated_at: null };
  if (typeof entry === 'object') {
    return {
      enabled: entry.enabled !== false,
      reason: entry.reason ? String(entry.reason) : null,
      updated_at: entry.updated_at ? String(entry.updated_at) : null
    };
  }
  return null;
}

function isModuleEnabled(moduleId, state) {
  const gate = getGateEntry(moduleId, state);
  return gate ? gate.enabled !== false : true;
}

function withGateState(moduleDef, state) {
  const gate = getGateEntry(moduleDef.id, state);
  const enabled = gate ? gate.enabled !== false : true;
  return {
    ...moduleDef,
    resolved_url: resolveModuleUrl(moduleDef),
    gate: {
      enabled,
      reason: gate?.reason || null,
      updated_at: gate?.updated_at || null
    }
  };
}

async function probeModule(moduleDef, enabled = true, timeoutMs = 2500) {
  const targetBase = resolveModuleUrl(moduleDef);
  const healthPath = moduleDef.health_path || '/api/health';

  if (!enabled) {
    return {
      id: moduleDef.id,
      name: moduleDef.name,
      status: 'gated',
      gated: true,
      ok: false,
      url: targetBase,
      health_path: healthPath,
      latency_ms: 0
    };
  }

  if (!targetBase) {
    return {
      id: moduleDef.id,
      name: moduleDef.name,
      status: 'unknown',
      gated: false,
      ok: false,
      error: 'missing module URL',
      url: '',
      health_path: healthPath,
      latency_ms: 0
    };
  }

  let url = '';
  try {
    url = new URL(healthPath, targetBase).toString();
  } catch {
    return {
      id: moduleDef.id,
      name: moduleDef.name,
      status: 'unknown',
      gated: false,
      ok: false,
      error: 'invalid URL',
      url: targetBase,
      health_path: healthPath,
      latency_ms: 0
    };
  }

  const started = Date.now();
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), timeoutMs);

  try {
    const res = await fetch(url, {
      method: 'GET',
      signal: controller.signal,
      headers: {
        Accept: 'application/json, text/plain;q=0.8, */*;q=0.5'
      }
    });
    const bodyText = await res.text();

    let body = null;
    try { body = bodyText ? JSON.parse(bodyText) : null; } catch { body = null; }

    const status = res.ok ? 'healthy' : (res.status < 500 ? 'degraded' : 'down');
    return {
      id: moduleDef.id,
      name: moduleDef.name,
      status,
      gated: false,
      ok: res.ok,
      http_status: res.status,
      latency_ms: Date.now() - started,
      url,
      health_path: healthPath,
      response: body || (bodyText ? bodyText.slice(0, 180) : null)
    };
  } catch (err) {
    return {
      id: moduleDef.id,
      name: moduleDef.name,
      status: 'down',
      gated: false,
      ok: false,
      url,
      health_path: healthPath,
      latency_ms: Date.now() - started,
      error: err?.name === 'AbortError' ? 'timeout' : String(err?.message || err)
    };
  } finally {
    clearTimeout(timer);
  }
}

function buildWorkflow(config, modulesWithGateState) {
  const stepOrder = Array.isArray(config.workflow?.steps)
    ? config.workflow.steps
    : modulesWithGateState.map((m) => m.id);
  const orderMap = new Map(stepOrder.map((id, idx) => [id, idx]));

  const nodes = [...modulesWithGateState]
    .sort((a, b) => {
      const ai = orderMap.has(a.id) ? orderMap.get(a.id) : Number.MAX_SAFE_INTEGER;
      const bi = orderMap.has(b.id) ? orderMap.get(b.id) : Number.MAX_SAFE_INTEGER;
      if (ai === bi) return a.id.localeCompare(b.id);
      return ai - bi;
    })
    .map((m) => ({
      id: m.id,
      name: m.name,
      domain: m.domain,
      enabled: m.gate?.enabled !== false,
      workflow_order: orderMap.has(m.id) ? orderMap.get(m.id) : null,
      capabilities: m.capabilities || [],
      depends_on: m.depends_on || []
    }));

  const edges = [];
  for (const m of modulesWithGateState) {
    for (const dep of m.depends_on || []) {
      edges.push({
        source: dep,
        target: m.id,
        type: 'depends_on'
      });
    }
  }

  return {
    name: config.workflow?.name || 'systemic-workflow',
    steps: stepOrder,
    nodes,
    edges
  };
}

function summarizeChecks(checks) {
  const summary = {
    total: checks.length,
    active: 0,
    gated: 0,
    healthy: 0,
    degraded: 0,
    down: 0,
    unknown: 0
  };

  for (const c of checks) {
    if (c.gated) {
      summary.gated += 1;
      continue;
    }
    summary.active += 1;
    if (c.status === 'healthy') summary.healthy += 1;
    else if (c.status === 'degraded') summary.degraded += 1;
    else if (c.status === 'down') summary.down += 1;
    else summary.unknown += 1;
  }
  return summary;
}

function biScore(metrics, checks) {
  const entropyIdx = Number(metrics?.entropy?.index_0_1 ?? 0);
  const driftStable = metrics?.drift?.stable ? 1 : 0;
  const activeChecks = checks.filter((c) => !c.gated);
  const healthyRatio = activeChecks.length
    ? activeChecks.filter((c) => c.status === 'healthy').length / activeChecks.length
    : 1;

  const score = 0.55 * entropyIdx + 0.35 * healthyRatio + 0.10 * driftStable;
  return Math.max(0, Math.min(1, score));
}

function adminTokenFromReq(req) {
  const auth = req.headers.authorization;
  if (typeof auth === 'string' && auth.toLowerCase().startsWith('bearer ')) {
    return auth.slice(7).trim();
  }
  const direct = req.headers['x-admin-token'];
  if (typeof direct === 'string') return direct.trim();
  return '';
}

function requireAdmin(req, res, next) {
  const provided = adminTokenFromReq(req);
  if (!provided || provided !== ADMIN_TOKEN) {
    return res.status(401).json({
      error: 'admin token required',
      hint: 'Provide x-admin-token header or Authorization: Bearer <token>'
    });
  }
  next();
}

async function ecosystemSnapshot({ probe = false } = {}) {
  const config = loadEcosystemConfig();
  const adminState = readAdminState();
  const modules = config.modules.map((m) => withGateState(m, adminState));
  let checks = [];

  if (probe) {
    checks = await Promise.all(
      modules.map((m) => probeModule(m, m.gate?.enabled !== false))
    );
  }

  return {
    ts: Date.now(),
    url_mode: URL_MODE,
    config,
    modules,
    checks,
    admin_state: {
      updated_at: adminState.updated_at || null,
      gates: adminState.gates || {}
    }
  };
}

// ---- Entropy metrics
function histFromArray(arr) {
  const h = new Map();
  for (const k of arr) h.set(k, (h.get(k) || 0) + 1);
  return h;
}
function histToProb(hist) {
  let sum = 0;
  for (const v of hist.values()) sum += v;
  const p = new Map();
  for (const [k, v] of hist.entries()) p.set(k, sum ? v / sum : 0);
  return p;
}
function entropyFromProb(p) {
  let H = 0;
  for (const v of p.values()) {
    if (v > 0) H += -v * (Math.log(v) / Math.log(2));
  }
  return H;
}
function klDiv(p, q, eps = 1e-9) {
  // KL(p||q) with smoothing
  const keys = new Set([...p.keys(), ...q.keys()]);
  let kl = 0;
  for (const k of keys) {
    const pv = (p.get(k) ?? 0) + eps;
    const qv = (q.get(k) ?? 0) + eps;
    kl += pv * (Math.log(pv / qv) / Math.log(2));
  }
  return kl;
}
function bucketDegree(d) {
  if (d <= 0) return '0';
  if (d === 1) return '1';
  if (d === 2) return '2';
  if (d <= 4) return '3-4';
  if (d <= 8) return '5-8';
  if (d <= 16) return '9-16';
  return '17+';
}
function computeMetrics(graph) {
  const nodes = Array.isArray(graph?.nodes) ? graph.nodes : [];
  const links = Array.isArray(graph?.links) ? graph.links : [];
  const hyperedges = Array.isArray(graph?.hyperedges) ? graph.hyperedges : [];

  const kinds = nodes.map((n) => String(n.kind || 'unknown'));
  const kindHist = histFromArray(kinds);
  const kindProb = histToProb(kindHist);

  // degrees on simple links + incidence links from hyperedges (approx)
  const deg = new Map();
  for (const n of nodes) deg.set(String(n.id), 0);
  for (const l of links) {
    const s = typeof l.source === 'string' ? l.source : l.source?.id;
    const t = typeof l.target === 'string' ? l.target : l.target?.id;
    if (s != null) deg.set(String(s), (deg.get(String(s)) || 0) + 1);
    if (t != null) deg.set(String(t), (deg.get(String(t)) || 0) + 1);
  }
  for (const h of hyperedges) {
    for (const m of (h.members || [])) {
      deg.set(String(m), (deg.get(String(m)) || 0) + 1);
    }
  }
  const degreeBuckets = [];
  for (const v of deg.values()) degreeBuckets.push(bucketDegree(Number(v) || 0));
  const degHist = histFromArray(degreeBuckets);
  const degProb = histToProb(degHist);

  const kindEntropy = entropyFromProb(kindProb);
  const degreeEntropy = entropyFromProb(degProb);

  const jsonText = JSON.stringify(graph);
  const jsonBytes = Buffer.byteLength(jsonText, 'utf8');
  const gz = zlib.gzipSync(Buffer.from(jsonText, 'utf8'), { level: 9 });
  const gzipBytes = gz.length;
  const compressionRatio = jsonBytes ? gzipBytes / jsonBytes : 1;

  // Normalize into a single "Entropy Index" in [0,1] (rough heuristic)
  // - High kind entropy + high degree entropy => more structural diversity
  // - High compressionRatio => more randomness (less compressible)
  // We'll treat "useful complexity" as diversity with some compressibility.
  const Hk = Math.min(1, kindEntropy / 4); // 4 bits cap-ish
  const Hd = Math.min(1, degreeEntropy / 4);
  const R = Math.max(0, Math.min(1, compressionRatio)); // 0..1 (usually 0.2..0.9)
  const entropyIndex = Math.max(0, Math.min(1, 0.45 * Hk + 0.45 * Hd + 0.10 * R));

  return {
    ts: Date.now(),
    counts: { nodes: nodes.length, links: links.length, hyperedges: hyperedges.length },
    entropy: { kind_bits: kindEntropy, degree_bits: degreeEntropy, compression_ratio: compressionRatio, index_0_1: entropyIndex },
    hists: {
      kind: Object.fromEntries(kindHist),
      degree_bucket: Object.fromEntries(degHist)
    },
    bytes: { json: jsonBytes, gzip: gzipBytes }
  };
}

function readMetrics() {
  return safeReadJson(METRICS_PATH, null);
}
function writeMetrics(metrics) {
  safeWriteJson(METRICS_PATH, metrics);
}

function updateMetricsAndPersist(graph) {
  const prev = readMetrics();
  const curr = computeMetrics(graph);

  // KL drift using probabilities from hist
  if (prev?.hists) {
    const pKind = histToProb(new Map(Object.entries(curr.hists.kind).map(([k, v]) => [k, Number(v)])));
    const qKind = histToProb(new Map(Object.entries(prev.hists.kind || {}).map(([k, v]) => [k, Number(v)])));
    const pDeg = histToProb(new Map(Object.entries(curr.hists.degree_bucket).map(([k, v]) => [k, Number(v)])));
    const qDeg = histToProb(new Map(Object.entries(prev.hists.degree_bucket || {}).map(([k, v]) => [k, Number(v)])));

    curr.drift = {
      kl_kind_bits: klDiv(pKind, qKind),
      kl_degree_bits: klDiv(pDeg, qDeg),
      stable: (klDiv(pKind, qKind) + klDiv(pDeg, qDeg)) < 0.25
    };
  } else {
    curr.drift = { kl_kind_bits: 0, kl_degree_bits: 0, stable: true };
  }

  writeMetrics(curr);
  return curr;
}

// init metrics
const initialGraph = safeReadJson(GRAPH_PATH, DEFAULT_GRAPH);
if (!fs.existsSync(METRICS_PATH)) updateMetricsAndPersist(initialGraph);
if (!fs.existsSync(ADMIN_STATE_PATH)) writeAdminState({ gates: {} });
if (!fs.existsSync(QUANTUM_STATE_PATH)) writeQuantumStateStore({ latest_id: null, states: [] });

// ---- Express
const app = express();
app.use(express.json({ limit: '2mb' }));

app.use('/', express.static(path.resolve('./dist')));
app.use('/plugins', express.static(path.resolve('./plugins')));
app.use('/module', express.static(path.resolve('./module')));

app.get('/api/health', async (req, res) => {
  const snapshot = await ecosystemSnapshot({ probe: false });
  const cipher = loadCipherSchema(snapshot.config);
  res.json({
    ok: true,
    ts: Date.now(),
    modules: snapshot.modules.length,
    url_mode: snapshot.url_mode,
    admin_token_configured: Boolean(ADMIN_TOKEN && ADMIN_TOKEN !== 'admin-change-me'),
    ibm_quantum_configured: Boolean(IBM_QUANTUM_ENDPOINT),
    artifacts: {
      cipher_schema: {
        loaded: cipher.ok,
        path: cipher.path
      }
    },
    domains: {
      shockwave_risk: 'https://shockwave.afthermath.afrho.net'
    }
  });
});

app.get('/api/plugins', (req, res) => {
  const dir = path.resolve('./plugins');
  const items = [];
  for (const name of fs.readdirSync(dir, { withFileTypes: true })) {
    if (!name.isDirectory()) continue;
    const manifestPath = path.join(dir, name.name, 'plugin.json');
    if (!fs.existsSync(manifestPath)) continue;
    const manifest = safeReadJson(manifestPath, null);
    if (!manifest) continue;
    items.push(manifest);
  }
  res.json({ plugins: items });
});

app.get('/api/graph', (req, res) => {
  res.json(safeReadJson(GRAPH_PATH, DEFAULT_GRAPH));
});

app.get('/api/metrics', (req, res) => {
  res.json(readMetrics() || computeMetrics(safeReadJson(GRAPH_PATH, DEFAULT_GRAPH)));
});

app.get('/api/workflow/cipher/schema', async (req, res) => {
  const config = loadEcosystemConfig();
  const loaded = loadCipherSchema(config);
  if (!loaded.ok) {
    return res.status(404).json({
      error: 'cipher schema not found',
      attempted_paths: resolveCipherSchemaPaths(config)
    });
  }

  res.json({
    ok: true,
    source_path: loaded.path,
    artifact: config.artifacts?.cipher_schema || null,
    schema: loaded.schema
  });
});

app.post('/api/workflow/cipher/validate', async (req, res) => {
  const config = loadEcosystemConfig();
  const loaded = loadCipherSchema(config);
  if (!loaded.ok) {
    return res.status(404).json({
      error: 'cipher schema not found',
      attempted_paths: resolveCipherSchemaPaths(config)
    });
  }

  const payload = req.body?.payload ?? req.body;
  const result = validateCipherPayload(payload, loaded.schema);
  res.json({
    ok: true,
    schema_path: loaded.path,
    valid: result.valid,
    kind: result.kind,
    errors: result.errors
  });
});

app.post('/api/risk/predictive-assessment', async (req, res) => {
  const payload = req.body || {};
  const telemetry = payload.telemetry || {};
  const policy = payload.policy || {};
  const fallbackThreshold = clamp01(policy.fallback_threshold ?? 0.62);

  const snapshot = await ecosystemSnapshot({ probe: true });
  const summary = summarizeChecks(snapshot.checks);
  const metrics = readMetrics() || computeMetrics(safeReadJson(GRAPH_PATH, DEFAULT_GRAPH));

  const driftBits = (metrics?.drift?.kl_kind_bits ?? 0) + (metrics?.drift?.kl_degree_bits ?? 0);
  const entropyIndex = Number(metrics?.entropy?.index_0_1 ?? 0);
  const availabilityRisk = summary.active ? 1 - (summary.healthy / summary.active) : 0;
  const driftRisk = clamp01(driftBits / 1.5);
  const entropyRisk = clamp01(Math.abs(0.5 - entropyIndex) * 2);
  const telemetryRisk = clamp01(
    0.50 * clamp01(telemetry.volatility ?? 0) +
    0.30 * clamp01(telemetry.anomaly ?? 0) +
    0.20 * clamp01(telemetry.exposure ?? 0)
  );

  const riskScore = clamp01(
    0.35 * availabilityRisk +
    0.30 * driftRisk +
    0.20 * entropyRisk +
    0.15 * telemetryRisk
  );
  const fallbackActivated = riskScore >= fallbackThreshold || summary.down > 0 || metrics?.drift?.stable === false;
  const regime = fallbackActivated ? 'systemic-hyperbolic-fallback' : 'linear-functor-operational';
  const diffusionHash = computeUniverseDiffusionHash(payload, {
    entropyIndex,
    driftBits,
    healthy: summary.healthy,
    active: summary.active
  });

  res.json({
    ok: true,
    ts: Date.now(),
    domain: 'shockwave.afthermath.afrho.net',
    regime,
    risk: {
      score_0_1: Number(riskScore.toFixed(4)),
      band: riskBand(riskScore),
      fallback_threshold_0_1: Number(fallbackThreshold.toFixed(4)),
      fallback_activated: fallbackActivated
    },
    components: {
      availability_risk_0_1: Number(availabilityRisk.toFixed(4)),
      drift_risk_0_1: Number(driftRisk.toFixed(4)),
      entropy_risk_0_1: Number(entropyRisk.toFixed(4)),
      telemetry_risk_0_1: Number(telemetryRisk.toFixed(4))
    },
    systemic_hyperbolic_fallback: fallbackActivated
      ? {
        strategy: 'curvature-compression',
        actions: [
          'reduce deployment velocity',
          'route to monitoring-only mode',
          'increase sampling window before actuation'
        ]
      }
      : null,
    linear_functor: {
      basis: ['availability', 'drift', 'entropy', 'telemetry'],
      weights: [0.35, 0.30, 0.20, 0.15],
      projection_0_1: Number(riskScore.toFixed(4))
    },
    universe_diffusion_hash: diffusionHash,
    service_health: summary
  });
});

app.post('/api/quantum/universe/diffusion-hash', async (req, res) => {
  const payload = req.body || {};
  const snapshot = await ecosystemSnapshot({ probe: true });
  const summary = summarizeChecks(snapshot.checks);
  const metrics = readMetrics() || computeMetrics(safeReadJson(GRAPH_PATH, DEFAULT_GRAPH));
  const diffusionHash = computeUniverseDiffusionHash(payload, {
    entropy: metrics.entropy,
    drift: metrics.drift,
    service_health: summary
  });

  res.json({
    ok: true,
    ts: Date.now(),
    domain: 'shockwave.afthermath.afrho.net',
    universe_diffusion_hash: diffusionHash
  });
});

app.post('/api/quantum/state/save', requireAdmin, async (req, res) => {
  const payload = req.body || {};
  const store = readQuantumStateStore();
  const nextId = payload.state_id ? String(payload.state_id) : `qstate:${Date.now()}`;
  const statePayload = payload.state ?? payload;
  const entryHash = sha256Hex(JSON.stringify(statePayload));
  const entry = {
    id: nextId,
    ts: Date.now(),
    provider: String(payload.provider || 'manual'),
    metadata: payload.metadata && typeof payload.metadata === 'object' ? payload.metadata : {},
    state: statePayload,
    hash: entryHash
  };

  store.states.push(entry);
  store.latest_id = entry.id;
  writeQuantumStateStore(store);

  res.json({
    ok: true,
    saved: entry.id,
    state_hash: entry.hash,
    universe_diffusion_hash: computeUniverseDiffusionHash(entry.state, { id: entry.id, provider: entry.provider })
  });
});

app.post('/api/quantum/query', requireAdmin, async (req, res) => {
  const payload = req.body || {};
  const provider = String(payload.provider || 'ibm').toLowerCase();
  const timeoutMs = Number(payload.timeout_ms || 8000);

  const store = readQuantumStateStore();
  const latest = store.states.length ? store.states[store.states.length - 1] : null;
  const stateRef = payload.state_id
    ? store.states.find((s) => s.id === String(payload.state_id)) || latest
    : latest;

  const fallback = () => {
    const seed = stateRef?.hash || 'zeroth';
    return fallbackQuantumResult(payload, seed);
  };

  let result = null;
  let usedProvider = provider;
  let fallbackReason = null;

  if (provider === 'ibm' && IBM_QUANTUM_ENDPOINT) {
    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), timeoutMs);
    try {
      const headers = {
        'Content-Type': 'application/json',
        ...(IBM_QUANTUM_API_KEY ? { Authorization: `Bearer ${IBM_QUANTUM_API_KEY}` } : {})
      };
      const ibmRes = await fetch(IBM_QUANTUM_ENDPOINT, {
        method: 'POST',
        headers,
        signal: controller.signal,
        body: JSON.stringify({
          circuit: payload.circuit || null,
          shots: Number(payload.shots || 1024),
          state: stateRef?.state || null
        })
      });
      const text = await ibmRes.text();
      if (!ibmRes.ok) throw new Error(`IBM endpoint HTTP ${ibmRes.status}`);
      let parsed = null;
      try { parsed = text ? JSON.parse(text) : null; } catch { parsed = { raw: text }; }
      result = { provider: 'ibm', response: parsed };
    } catch (err) {
      usedProvider = 'systemic-hyperbolic-fallback';
      fallbackReason = err?.name === 'AbortError' ? 'ibm-timeout' : `ibm-error:${err?.message || err}`;
      result = fallback();
    } finally {
      clearTimeout(timer);
    }
  } else {
    usedProvider = 'systemic-hyperbolic-fallback';
    fallbackReason = provider === 'ibm' ? 'ibm-endpoint-not-configured' : 'provider-requested-fallback';
    result = fallback();
  }

  const diffusionHash = computeUniverseDiffusionHash(result, {
    provider: usedProvider,
    state_id: stateRef?.id || null,
    domain: 'shockwave.afthermath.afrho.net'
  });

  res.json({
    ok: true,
    ts: Date.now(),
    provider_requested: provider,
    provider_used: usedProvider,
    fallback_reason: fallbackReason,
    state_ref: stateRef ? { id: stateRef.id, hash: stateRef.hash } : null,
    result,
    universe_diffusion_hash: diffusionHash
  });
});

app.post('/api/graph', (req, res) => {
  const g = req.body;
  if (!g || !Array.isArray(g.nodes) || !Array.isArray(g.links)) {
    return res.status(400).json({ error: 'Invalid graph payload' });
  }
  safeWriteJson(GRAPH_PATH, g);
  const metrics = updateMetricsAndPersist(g);
  broadcast({ type: 'graph:update', graph: g, ts: Date.now() });
  broadcast({ type: 'metrics:update', metrics, ts: Date.now() });
  res.json({ ok: true, metrics });
});

app.post('/api/graph/reset', (req, res) => {
  safeWriteJson(GRAPH_PATH, DEFAULT_GRAPH);
  const metrics = updateMetricsAndPersist(DEFAULT_GRAPH);
  broadcast({ type: 'graph:update', graph: DEFAULT_GRAPH, ts: Date.now() });
  broadcast({ type: 'metrics:update', metrics, ts: Date.now() });
  res.json({ ok: true, metrics });
});

app.get('/api/ecosystem/modules', async (req, res) => {
  const probe = req.query.probe === '1' || req.query.probe === 'true';
  const snapshot = await ecosystemSnapshot({ probe });

  const checksById = new Map(snapshot.checks.map((c) => [c.id, c]));
  const modules = snapshot.modules.map((m) => {
    const c = checksById.get(m.id);
    return {
      ...m,
      status: c ? c.status : 'not-probed',
      latency_ms: c ? c.latency_ms : null,
      http_status: c ? c.http_status || null : null
    };
  });

  res.json({
    ts: snapshot.ts,
    ecosystem: snapshot.config.name,
    version: snapshot.config.version,
    url_mode: snapshot.url_mode,
    artifacts: snapshot.config.artifacts || {},
    modules,
    checks: snapshot.checks,
    summary: probe ? summarizeChecks(snapshot.checks) : null
  });
});

app.get('/api/ecosystem/workflow', async (req, res) => {
  const snapshot = await ecosystemSnapshot({ probe: false });
  const workflow = buildWorkflow(snapshot.config, snapshot.modules);
  const cipher = loadCipherSchema(snapshot.config);
  res.json({
    ts: snapshot.ts,
    ecosystem: snapshot.config.name,
    workflow,
    artifacts: {
      cipher_schema: {
        loaded: cipher.ok,
        path: cipher.path,
        source: snapshot.config.artifacts?.cipher_schema || null
      }
    }
  });
});

app.get('/api/bi/summary', async (req, res) => {
  const snapshot = await ecosystemSnapshot({ probe: true });
  const graph = safeReadJson(GRAPH_PATH, DEFAULT_GRAPH);
  const metrics = readMetrics() || computeMetrics(graph);
  const summary = summarizeChecks(snapshot.checks);
  const cipher = loadCipherSchema(snapshot.config);

  const score = biScore(metrics, snapshot.checks);
  const workflow = buildWorkflow(snapshot.config, snapshot.modules);
  const driftBits = (metrics?.drift?.kl_kind_bits ?? 0) + (metrics?.drift?.kl_degree_bits ?? 0);
  const availabilityRisk = summary.active ? 1 - (summary.healthy / summary.active) : 0;
  const entropyRisk = clamp01(Math.abs(0.5 - Number(metrics?.entropy?.index_0_1 ?? 0)) * 2);
  const predictiveRiskBaseline = clamp01(0.40 * availabilityRisk + 0.35 * clamp01(driftBits / 1.5) + 0.25 * entropyRisk);

  res.json({
    ts: Date.now(),
    ecosystem: snapshot.config.name,
    score_0_1: Number(score.toFixed(3)),
    entropy: metrics.entropy,
    drift: metrics.drift,
    service_health: summary,
    kpis: {
      entropy_index: Number((metrics?.entropy?.index_0_1 ?? 0).toFixed(3)),
      healthy_service_ratio: summary.active ? Number((summary.healthy / summary.active).toFixed(3)) : 1,
      workflow_coverage: workflow.nodes.length,
      cipher_schema_loaded: cipher.ok,
      predictive_risk_baseline_0_1: Number(predictiveRiskBaseline.toFixed(3))
    },
    modules: snapshot.checks,
    workflow,
    artifacts: {
      cipher_schema: {
        loaded: cipher.ok,
        path: cipher.path
      }
    },
    domains: {
      shockwave_risk: 'https://shockwave.afthermath.afrho.net'
    }
  });
});

app.get('/api/monitoring/gated', requireAdmin, async (req, res) => {
  const snapshot = await ecosystemSnapshot({ probe: true });
  const metrics = readMetrics() || computeMetrics(safeReadJson(GRAPH_PATH, DEFAULT_GRAPH));

  res.json({
    ts: Date.now(),
    monitoring_scope: 'gated',
    entropy: metrics.entropy,
    drift: metrics.drift,
    summary: summarizeChecks(snapshot.checks),
    checks: snapshot.checks,
    admin_state: snapshot.admin_state
  });
});

app.get('/api/admin/state', requireAdmin, async (req, res) => {
  const snapshot = await ecosystemSnapshot({ probe: false });
  res.json({
    ts: Date.now(),
    admin_state: snapshot.admin_state,
    modules: snapshot.modules.map((m) => ({
      id: m.id,
      name: m.name,
      enabled: m.gate?.enabled !== false,
      reason: m.gate?.reason || null,
      updated_at: m.gate?.updated_at || null,
      admin_managed: m.admin_managed !== false
    }))
  });
});

app.post('/api/admin/gates/:moduleId', requireAdmin, async (req, res) => {
  const moduleId = String(req.params.moduleId || '');
  const enable = req.body?.enabled !== false;
  const reason = req.body?.reason ? String(req.body.reason) : null;

  const config = loadEcosystemConfig();
  if (!config.modules.some((m) => m.id === moduleId)) {
    return res.status(404).json({ error: 'Unknown module id' });
  }

  const state = readAdminState();
  state.gates[moduleId] = {
    enabled: enable,
    reason,
    updated_at: new Date().toISOString()
  };
  writeAdminState(state);

  const snapshot = await ecosystemSnapshot({ probe: false });
  broadcast({ type: 'admin:gates:update', admin_state: snapshot.admin_state, ts: Date.now() });

  res.json({
    ok: true,
    module_id: moduleId,
    gate: state.gates[moduleId],
    admin_state: snapshot.admin_state
  });
});

app.post('/api/admin/gates/reset', requireAdmin, async (req, res) => {
  writeAdminState({ gates: {} });
  const snapshot = await ecosystemSnapshot({ probe: false });
  broadcast({ type: 'admin:gates:update', admin_state: snapshot.admin_state, ts: Date.now() });
  res.json({
    ok: true,
    admin_state: snapshot.admin_state
  });
});

const server = http.createServer(app);
const wss = new WebSocketServer({ server, path: '/ws' });

function broadcast(msg) {
  const data = JSON.stringify(msg);
  for (const ws of wss.clients) {
    if (ws.readyState === 1) ws.send(data);
  }
}

wss.on('connection', async (ws) => {
  ws.send(JSON.stringify({ type: 'hello', ts: Date.now() }));
  // push latest graph + metrics + ecosystem state
  const g = safeReadJson(GRAPH_PATH, DEFAULT_GRAPH);
  const m = readMetrics() || computeMetrics(g);
  ws.send(JSON.stringify({ type: 'graph:update', graph: g, ts: Date.now() }));
  ws.send(JSON.stringify({ type: 'metrics:update', metrics: m, ts: Date.now() }));

  const snapshot = await ecosystemSnapshot({ probe: false });
  ws.send(JSON.stringify({ type: 'ecosystem:update', modules: snapshot.modules, ts: Date.now() }));

  ws.on('message', async (buf) => {
    let msg = null;
    try { msg = JSON.parse(buf.toString('utf8')); } catch { return; }
    if (msg?.type === 'ping') ws.send(JSON.stringify({ type: 'pong', ts: Date.now() }));
    if (msg?.type === 'graph:request') ws.send(JSON.stringify({ type: 'graph:update', graph: safeReadJson(GRAPH_PATH, DEFAULT_GRAPH), ts: Date.now() }));
    if (msg?.type === 'metrics:request') ws.send(JSON.stringify({ type: 'metrics:update', metrics: (readMetrics() || computeMetrics(safeReadJson(GRAPH_PATH, DEFAULT_GRAPH))), ts: Date.now() }));
    if (msg?.type === 'ecosystem:request') {
      const es = await ecosystemSnapshot({ probe: false });
      ws.send(JSON.stringify({ type: 'ecosystem:update', modules: es.modules, ts: Date.now() }));
    }
  });
});

server.listen(PORT, () => {
  console.log(`[hypergraph-polyfractal] listening on :${PORT}`);
  console.log(`  UI   http://localhost:${PORT}/`);
  console.log(`  API  http://localhost:${PORT}/api`);
  console.log(`  WS   ws://localhost:${PORT}/ws`);
  console.log(`  Ecosystem config: ${ECOSYSTEM_CONFIG_PATH}`);
  console.log(`  Cipher schema source: ${CIPHER_SCHEMA_SOURCE_PATH}`);
  console.log(`  IBM quantum endpoint configured: ${Boolean(IBM_QUANTUM_ENDPOINT)}`);
  console.log(`  URL mode: ${URL_MODE}`);
  if (ADMIN_TOKEN === 'admin-change-me') {
    console.log('  WARNING: using default ADMIN_TOKEN (set ADMIN_TOKEN in environment)');
  }
});
