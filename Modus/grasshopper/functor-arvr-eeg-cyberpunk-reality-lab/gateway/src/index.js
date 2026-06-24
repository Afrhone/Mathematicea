import express from "express";
import dotenv from "dotenv";
import crypto from "node:crypto";
import fs from "node:fs";

dotenv.config();

const app = express();
app.use(express.json());

const PORT = Number(process.env.GATEWAY_PORT || 7150);
const BIND = process.env.GATEWAY_BIND || "0.0.0.0";
const phrase = process.env.HANDSHAKE_PHRASE || "YETI gates the stem, Raven tastes sweet, axiom before retry, rhizome remembers, entropy bows to proof.";

function sha256(s) {
  return crypto.createHash("sha256").update(s).digest("hex");
}

function sink(path, obj) {
  fs.mkdirSync(path.split("/").slice(0, -1).join("/"), { recursive: true });
  fs.appendFileSync(path, JSON.stringify(obj) + "\n");
}

app.get("/health", (_req, res) => {
  res.json({
    ok: true,
    service: "reality-lab-gateway",
    namespace: process.env.NAMESPACE || "factory-rhizome-lab-studio",
    badge: process.env.BADGE || "YETI-715",
    time: Date.now() / 1000
  });
});

app.get("/handshake", (_req, res) => {
  const hash = sha256(phrase);
  res.json({
    attestor: "YETI-715",
    phrase,
    sha256: hash,
    expected: process.env.HANDSHAKE_SHA256 || hash,
    ok: (process.env.HANDSHAKE_SHA256 || hash) === hash
  });
});

app.post("/event", (req, res) => {
  const path = process.env.SIM_SINK || "/var/lib/reality-lab/sim.ndjson";
  sink(path, { time: Date.now() / 1000, source: "gateway", event: req.body });
  res.json({ ok: true, sink: path });
});

app.get("/functor/state", (_req, res) => {
  res.json({
    functor: "C_form × C_world × C_ops → C_experience",
    tau_threshold: Number(process.env.SIM_TAU_THRESHOLD || 0.82),
    domains: ["topology", "quantum", "relativity", "thermodynamics", "electromagnetism"],
    status: "scaffold-ready"
  });
});

app.get("/eeg/status", (_req, res) => {
  res.json({
    mode: process.env.EEG_MODE || "mock",
    sample_rate: Number(process.env.EEG_SAMPLE_RATE || 250),
    channels: Number(process.env.EEG_CHANNELS || 8),
    note: "EEG is interaction telemetry, not medical/consciousness detection."
  });
});

app.listen(PORT, BIND, () => {
  console.log(`reality-lab-gateway listening on ${BIND}:${PORT}`);
});
