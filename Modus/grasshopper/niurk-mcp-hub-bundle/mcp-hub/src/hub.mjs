#!/usr/bin/env node
/*
 * niurk-mcp-hub: dependency-free MCP-style stdio JSON-RPC server.
 * Default behavior is read-only or plan-generating. Local probes are gated by
 * NIURK_ALLOW_COMMANDS=1. Mutating deploys are not performed by this server.
 */
import { spawnSync } from 'node:child_process';
import { readFileSync, existsSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const root = resolve(__dirname, '../..');
const configDir = resolve(root, 'config');

const env = process.env;
const allowCommands = env.NIURK_ALLOW_COMMANDS === '1';
const allowDeploy = env.NIURK_ALLOW_DEPLOY === '1' && env.NIURK_DRY_RUN === '0';

function readText(path, fallback = '') {
  try { return readFileSync(path, 'utf8'); } catch { return fallback; }
}

function jsonText(obj) {
  return JSON.stringify(obj, null, 2);
}

function content(obj) {
  return { content: [{ type: 'text', text: typeof obj === 'string' ? obj : jsonText(obj) }] };
}

function fail(message, extra = {}) {
  return content({ ok: false, error: message, ...extra });
}

function safeRun(cmd, args = [], timeout = 9000) {
  if (!allowCommands) {
    return { skipped: true, reason: 'NIURK_ALLOW_COMMANDS is not 1', cmd: [cmd, ...args].join(' ') };
  }
  const res = spawnSync(cmd, args, { encoding: 'utf8', timeout });
  return {
    cmd: [cmd, ...args].join(' '),
    status: res.status,
    signal: res.signal,
    stdout: (res.stdout || '').trim(),
    stderr: (res.stderr || '').trim()
  };
}

const TOOLS = [
  {
    name: 'hub_status',
    description: 'Return MCP hub configuration, source skill registry, model routes, and safety gates.',
    inputSchema: { type: 'object', properties: {} }
  },
  {
    name: 'cluster_preflight',
    description: 'Run safe read-only preflight probes for LXD, Ceph, Bitcoin Core, Node.js, and dashboard state. Requires NIURK_ALLOW_COMMANDS=1 for command execution.',
    inputSchema: { type: 'object', properties: { includeBitcoin: { type: 'boolean' }, includeCeph: { type: 'boolean' } } }
  },
  {
    name: 'lxd_inventory',
    description: 'Collect LXD cluster and instance inventory using read-only lxc commands. Requires NIURK_ALLOW_COMMANDS=1.',
    inputSchema: { type: 'object', properties: { project: { type: 'string' }, remote: { type: 'string' } } }
  },
  {
    name: 'ceph_probe',
    description: 'Collect Ceph status, filesystem status, and RBD pool list using read-only commands. Requires NIURK_ALLOW_COMMANDS=1.',
    inputSchema: { type: 'object', properties: { rbdPool: { type: 'string' } } }
  },
  {
    name: 'bitcoin_readonly',
    description: 'Run allowlisted read-only Bitcoin Core RPC through bitcoin-cli. Wallet, signing, and broadcast RPC are blocked.',
    inputSchema: { type: 'object', required: ['method'], properties: { method: { type: 'string' }, params: { type: 'array', items: { type: 'string' } } } }
  },
  {
    name: 'render_env_directives',
    description: 'Generate a concrete .env directive block for cluster deployment or client MCP configuration.',
    inputSchema: { type: 'object', properties: { targetNode: { type: 'string' }, vmName: { type: 'string' }, storagePool: { type: 'string' }, bridge: { type: 'string' } } }
  },
  {
    name: 'deploy_plan',
    description: 'Generate a dry-run deployment plan for host systemd or LXD instance integration. Does not mutate cluster state.',
    inputSchema: { type: 'object', properties: { mode: { type: 'string', enum: ['systemd', 'lxd', 'compose'] }, targetNode: { type: 'string' }, instance: { type: 'string' } } }
  },
  {
    name: 'integrity_reasoning_pack',
    description: 'Apply Integrity routing: cognitive-superposition lenses plus superforecasting risk breakdown for a deployment objective.',
    inputSchema: { type: 'object', required: ['objective'], properties: { objective: { type: 'string' }, evidence: { type: 'array', items: { type: 'string' } }, horizonDays: { type: 'number' } } }
  },
  {
    name: 'deployment_forecast',
    description: 'Generate a calibrated pre-mortem/forecast envelope for a cluster automation change.',
    inputSchema: { type: 'object', required: ['change'], properties: { change: { type: 'string' }, blockers: { type: 'array', items: { type: 'string' } }, baseRate: { type: 'number' } } }
  },
  {
    name: 'vision_pipeline_plan',
    description: 'Generate a scikit-image scientific image-processing pipeline plan with dtype, segmentation, morphology, and measurement steps.',
    inputSchema: { type: 'object', properties: { imageType: { type: 'string' }, goal: { type: 'string' }, operations: { type: 'array', items: { type: 'string' } } } }
  },
  {
    name: 'particles_route',
    description: 'Route holographic/particle simulation requirements to CPU, Canvas2D, WebGL point sprites, instancing, or GPU buffers.',
    inputSchema: { type: 'object', properties: { particleCount: { type: 'number' }, dimensionality: { type: 'string' }, interaction: { type: 'string' }, targetFps: { type: 'number' } } }
  },
  {
    name: 'holography_manifest',
    description: 'Render dashboard overlay manifest for the included infrasys-webgl standalone surface.',
    inputSchema: { type: 'object', properties: { topology: { type: 'string' }, metrics: { type: 'array', items: { type: 'string' } } } }
  },
  {
    name: 'alpha_attention_model',
    description: 'Return a working-memory-inspired prioritization gate for agent/tool routing: active alpha-like attention for prioritized tasks, quiescent latent queue for deprioritized tasks.',
    inputSchema: { type: 'object', properties: { prioritized: { type: 'array', items: { type: 'string' } }, latent: { type: 'array', items: { type: 'string' } } } }
  }
];

function hubStatus() {
  return content({
    ok: true,
    name: env.NIURK_HUB_NAME || 'niurk-mcp-hub',
    mode: env.NIURK_HUB_MODE || 'stdio',
    allowCommands,
    allowDeploy,
    dryRun: env.NIURK_DRY_RUN !== '0',
    root,
    registry: readText(resolve(configDir, 'skills.registry.yaml')),
    models: readText(resolve(configDir, 'models.yaml')),
    policy: readText(resolve(configDir, 'hub.policy.yaml'))
  });
}

function clusterPreflight(args = {}) {
  const probes = {
    node: safeRun('node', ['--version'], 3000),
    npm: safeRun('npm', ['--version'], 3000),
    lxc: safeRun('lxc', ['--version'], 3000),
    lxdCluster: safeRun('lxc', ['cluster', 'list'], 9000),
    lxdStorage: safeRun('lxc', ['storage', 'list'], 9000),
    dashboard: existsSync(resolve(root, 'dashboard/infrasys-webgl/index.html'))
  };
  if (args.includeCeph !== false) {
    probes.cephStatus = safeRun('ceph', ['-s'], 9000);
    probes.cephFs = safeRun('ceph', ['fs', 'status'], 9000);
  }
  if (args.includeBitcoin) {
    probes.bitcoin = safeRun(env.BITCOIN_CLI || 'bitcoin-cli', ['getblockchaininfo'], 9000);
  }
  return content({ ok: true, allowCommands, probes });
}

function lxdInventory(args = {}) {
  const project = args.project || env.NIURK_PROJECT || 'default';
  const remote = args.remote || env.NIURK_PRIMARY_LXD_REMOTE || 'local';
  const prefix = remote === 'local' ? [] : [remote + ':'];
  return content({
    ok: true,
    project,
    remote,
    commandsExecuted: allowCommands,
    cluster: safeRun('lxc', ['cluster', 'list'], 12000),
    instances: safeRun('lxc', [...prefix, 'list', '--project', project, '--format', env.NIURK_LXD_LIST_FORMAT || 'json'], 15000),
    storage: safeRun('lxc', ['storage', 'list', '--format', 'yaml'], 12000),
    networks: safeRun('lxc', ['network', 'list', '--format', 'yaml'], 12000)
  });
}

function cephProbe(args = {}) {
  const pool = args.rbdPool || env.NIURK_RBD_POOL || 'lxd-rbd-ark';
  return content({
    ok: true,
    commandsExecuted: allowCommands,
    cephStatus: safeRun('ceph', ['-s'], 12000),
    cephFs: safeRun('ceph', ['fs', 'status'], 12000),
    rbdList: safeRun('rbd', ['--pool', pool, 'list'], 12000),
    pool
  });
}

const allowedBitcoin = new Set((env.BITCOIN_ALLOWED_METHODS || 'getblockchaininfo,getmempoolinfo,getnetworkinfo,getblockcount,getblockhash,getblock,getrawtransaction').split(',').map(s => s.trim()).filter(Boolean));
const deniedBitcoin = new Set(['sendrawtransaction','walletprocesspsbt','walletcreatefundedpsbt','dumpprivkey','importprivkey','listwallets','loadwallet','unloadwallet','encryptwallet','getwalletinfo','listunspent','sendtoaddress','signrawtransactionwithwallet']);
function bitcoinReadonly(args = {}) {
  const method = String(args.method || '');
  const params = Array.isArray(args.params) ? args.params.map(String) : [];
  if (!method) return fail('missing method');
  if (deniedBitcoin.has(method) || !allowedBitcoin.has(method)) {
    return fail('Bitcoin RPC method is not allowlisted by the hub', { method, allowed: [...allowedBitcoin].sort() });
  }
  return content({ ok: true, method, params, result: safeRun(env.BITCOIN_CLI || 'bitcoin-cli', [method, ...params], 12000) });
}

function renderEnv(args = {}) {
  const targetNode = args.targetNode || env.NIURK_ORCHESTRATOR_NODE || 'ark-rhiz';
  const vmName = args.vmName || env.NIURK_DEFAULT_VM || 'niurk-19';
  const storagePool = args.storagePool || env.NIURK_VM_POOL || 'rhiz-storage';
  const bridge = args.bridge || env.NIURK_BRIDGE || 'br0';
  const block = [
    `NIURK_ORCHESTRATOR_NODE=${targetNode}`,
    `NIURK_DEFAULT_VM=${vmName}`,
    `NIURK_VM_POOL=${storagePool}`,
    `NIURK_BRIDGE=${bridge}`,
    `NIURK_ALLOW_COMMANDS=${allowCommands ? '1' : '0'}`,
    `NIURK_ALLOW_DEPLOY=0`,
    `NIURK_DRY_RUN=1`,
    `BITCOIN_ALLOWED_METHODS=${[...allowedBitcoin].join(',')}`
  ].join('\n');
  return content({ ok: true, env: block, client: { command: 'node', args: [resolve(root, 'mcp-hub/src/hub.mjs')], envFile: 'env/mcp-hub.env' } });
}

function deployPlan(args = {}) {
  const mode = args.mode || 'systemd';
  const targetNode = args.targetNode || env.NIURK_ORCHESTRATOR_NODE || 'ark-rhiz';
  const instance = args.instance || env.MCP_HUB_INSTANCE || 'mcp-hub';
  const shared = [
    '1. Copy bundle to /opt/niurk-mcp-hub on orchestrator.',
    '2. Copy env/mcp-hub.env.example to env/mcp-hub.env and keep NIURK_DRY_RUN=1 for first boot.',
    '3. Run bin/cluster-preflight.sh and inspect read-only probes.',
    '4. Enable tool execution only with NIURK_ALLOW_COMMANDS=1 after preflight succeeds.'
  ];
  const modes = {
    systemd: [...shared, '5. Run sudo bin/deploy-systemd.sh after setting DRY_RUN=0 when ready.', '6. Add client config from generated mcp-client.json.'],
    lxd: [...shared, `5. Create LXD instance ${instance} on ${targetNode}; bind only required directories/sockets.`, '6. Prefer host systemd if direct LXD socket access is needed.'],
    compose: [...shared, '5. Use compose/mcp-hub.compose.yaml for dashboard/proxy surfaces only; stdio MCP remains local process.']
  };
  return content({ ok: true, mode, targetNode, instance, allowDeploy, dryRun: env.NIURK_DRY_RUN !== '0', plan: modes[mode] || modes.systemd });
}

function integrityPack(args = {}) {
  const objective = args.objective;
  if (!objective) return fail('missing objective');
  const evidence = Array.isArray(args.evidence) ? args.evidence : [];
  const horizonDays = args.horizonDays || 7;
  return content({
    ok: true,
    objective,
    horizonDays,
    cognitive_superposition: {
      lenses: ['category/invariant map', 'compression-progress delta', 'causal intervention graph', 'self-improvement loop'],
      collapse_rule: 'choose action preserving cluster invariants with smallest operational entropy and highest reversibility',
      invariants: ['no destructive LXD DB actions', 'Ceph mount readiness before VM placement', 'Bitcoin read-only boundary', 'dry-run first']
    },
    superforecasting: {
      outside_view: 'compare against prior LXD/Ceph join, mount, KVM, bridge, and agent fallback incidents',
      fermi_decomposition: ['package boot', 'client registration', 'safe probes', 'cluster connectivity', 'storage readiness', 'dashboard render'],
      update_rule: 'decrease confidence after each failed preflight class; increase only after live read-only evidence',
      premortem: ['missing node/npm', 'LXD permission denied', 'Ceph keyring absent', 'Bitcoin Core not synced', 'wrong bridge parent', 'dashboard path mismatch']
    },
    evidence
  });
}

function deploymentForecast(args = {}) {
  const base = typeof args.baseRate === 'number' ? args.baseRate : 0.62;
  const blockers = Array.isArray(args.blockers) ? args.blockers : [];
  const penalty = Math.min(0.45, blockers.length * 0.08);
  const probability = Math.max(0.05, Math.min(0.95, base - penalty));
  return content({
    ok: true,
    change: args.change || 'unspecified change',
    estimated_success_probability: Number(probability.toFixed(2)),
    blockers,
    confidence: blockers.length ? 'medium-low until preflight evidence is collected' : 'medium',
    next_evidence: ['cluster_preflight', 'lxd_inventory', 'ceph_probe', 'hub_selftest'],
    mitigation_queue: blockers.map((b, i) => ({ rank: i + 1, blocker: b, action: 'create reversible diagnostic/rollback step before deploy' }))
  });
}

function visionPipeline(args = {}) {
  const operations = Array.isArray(args.operations) && args.operations.length ? args.operations : ['normalize dtype', 'denoise', 'segment', 'morphology', 'measure regions', 'export overlay'];
  return content({
    ok: true,
    imageType: args.imageType || 'scientific/dashboard image',
    goal: args.goal || 'extract measurable structures',
    pipeline: operations.map((op, i) => ({ step: i + 1, op, notes: stepNote(op) })),
    python_entrypoint: 'tools/scikit_image_pipeline.py',
    outputs: ['features.json', 'mask.png', 'overlay.png']
  });
}
function stepNote(op) {
  const s = String(op).toLowerCase();
  if (s.includes('dtype') || s.includes('normal')) return 'convert with img_as_float/img_as_ubyte consciously; avoid silent intensity rescaling';
  if (s.includes('denoise')) return 'prefer gaussian, median, or non-local means depending on noise model';
  if (s.includes('segment')) return 'use threshold/watershed/SLIC depending on topology and markers';
  if (s.includes('morph')) return 'clean binary masks with opening/closing/remove_small_objects/skeletonize';
  if (s.includes('measure')) return 'regionprops_table to JSON/CSV for downstream graph ledger';
  return 'keep operation deterministic and record parameters in metadata';
}

function particlesRoute(args = {}) {
  const n = Number(args.particleCount || 5000);
  const fps = Number(args.targetFps || 60);
  let tier = 'canvas2d';
  let recipe = 'simple sprites';
  if (n > 100000) { tier = 'gpu-compute-or-webgpu'; recipe = 'storage buffers + compute/update pass + instanced draw'; }
  else if (n > 30000) { tier = 'webgl2-instanced'; recipe = 'instanced quads/points + transform feedback or texture state'; }
  else if (n > 5000) { tier = 'webgl-point-sprites'; recipe = 'single VBO point-sprite swarm + shader noise'; }
  return content({
    ok: true,
    particleCount: n,
    targetFps: fps,
    dimensionality: args.dimensionality || '3d',
    interaction: args.interaction || 'force-layout + metrics pulses',
    tier,
    recipe,
    budgets: { frame_ms: Number((1000 / fps).toFixed(2)), update: '30-45%', render: '40-55%', ui: '10-15%' },
    integration: 'dashboard/infrasys-webgl with generated holography manifest'
  });
}

function holographyManifest(args = {}) {
  const topology = args.topology || 'config/cluster-topology.yaml';
  const metrics = Array.isArray(args.metrics) && args.metrics.length ? args.metrics : ['lxd_state', 'ceph_health', 'vm_migration', 'bitcoin_mempool', 'agent_attention'];
  return content({
    ok: true,
    manifest: {
      version: '0.1',
      topology,
      layers: [
        { id: 'cluster_nodes', type: 'graph', source: topology },
        { id: 'attention_alpha', type: 'pulse-field', metric: 'priority' },
        { id: 'ceph_storage', type: 'surface-grid', metric: 'health' },
        { id: 'bitcoin_mempool', type: 'particle-stream', metric: 'vsize_fee_density' }
      ],
      metrics
    }
  });
}

function alphaAttention(args = {}) {
  const prioritized = Array.isArray(args.prioritized) ? args.prioritized : ['deployment safety', 'cluster preflight'];
  const latent = Array.isArray(args.latent) ? args.latent : ['optional visualization polish', 'future model swaps'];
  return content({
    ok: true,
    active_attention: prioritized.map((x, i) => ({ item: x, gate: 'alpha-priority', rank: i + 1, action: 'keep continuously decodable in operator loop' })),
    quiescent_queue: latent.map((x, i) => ({ item: x, gate: 'activity-quiescent', rank: i + 1, action: 'store as latent trace; re-illuminate when probed' })),
    router_rule: 'prioritized tasks receive live probes; deprioritized tasks remain in manifest/state until triggered'
  });
}

async function handle(req) {
  if (!req || typeof req !== 'object') return null;
  const { id, method, params = {} } = req;
  try {
    let result;
    if (method === 'initialize') {
      result = {
        protocolVersion: params.protocolVersion || '2024-11-05',
        capabilities: { tools: {} },
        serverInfo: { name: 'niurk-mcp-hub', version: '0.1.0' }
      };
    } else if (method === 'notifications/initialized') {
      return null;
    } else if (method === 'tools/list') {
      result = { tools: TOOLS };
    } else if (method === 'tools/call') {
      const name = params.name;
      const args = params.arguments || {};
      const dispatch = {
        hub_status: hubStatus,
        cluster_preflight: clusterPreflight,
        lxd_inventory: lxdInventory,
        ceph_probe: cephProbe,
        bitcoin_readonly: bitcoinReadonly,
        render_env_directives: renderEnv,
        deploy_plan: deployPlan,
        integrity_reasoning_pack: integrityPack,
        deployment_forecast: deploymentForecast,
        vision_pipeline_plan: visionPipeline,
        particles_route: particlesRoute,
        holography_manifest: holographyManifest,
        alpha_attention_model: alphaAttention
      };
      if (!dispatch[name]) throw new Error(`Unknown tool: ${name}`);
      result = dispatch[name](args);
    } else {
      throw new Error(`Unsupported method: ${method}`);
    }
    if (id === undefined) return null;
    return { jsonrpc: '2.0', id, result };
  } catch (err) {
    if (id === undefined) return null;
    return { jsonrpc: '2.0', id, error: { code: -32000, message: err.message || String(err) } };
  }
}

let buffer = '';
process.stdin.setEncoding('utf8');
process.stdin.on('data', chunk => {
  buffer += chunk;
  let idx;
  while ((idx = buffer.indexOf('\n')) >= 0) {
    const line = buffer.slice(0, idx).trim();
    buffer = buffer.slice(idx + 1);
    if (!line) continue;
    let req;
    try { req = JSON.parse(line); } catch (err) {
      process.stdout.write(JSON.stringify({ jsonrpc: '2.0', id: null, error: { code: -32700, message: 'Parse error' } }) + '\n');
      continue;
    }
    Promise.resolve(handle(req)).then(resp => { if (resp) process.stdout.write(JSON.stringify(resp) + '\n'); });
  }
});
process.stdin.on('end', () => process.exit(0));
