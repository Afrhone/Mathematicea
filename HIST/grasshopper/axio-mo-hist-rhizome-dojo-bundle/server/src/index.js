import express from "express";
import dotenv from "dotenv";
import fs from "node:fs/promises";

dotenv.config();

const app = express();
app.use(express.json());

const PORT = process.env.DOJO_PORT || 7150;
const BIND = process.env.DOJO_BIND || "0.0.0.0";

async function readJSON(path) {
  const url = new URL(path, import.meta.url);
  return JSON.parse(await fs.readFile(url, "utf8"));
}

app.get("/health", (_req, res) => {
  res.json({
    ok: true,
    service: "axio-mo-hist-rhizome-dojo",
    node: process.env.DOJO_NODE_NAME || "unknown",
    tribe: process.env.DOJO_TRIBE || "rhiz-kobalt",
    time: new Date().toISOString()
  });
});

app.get("/archetype", async (_req, res) => {
  res.json(await readJSON("./data/archetype.json"));
});

app.get("/badges", async (_req, res) => {
  res.json(await readJSON("./data/badges.json"));
});

app.post("/badge/yeti", (req, res) => {
  res.json({
    id: "YETI-715",
    title: "Certified Snowblind Debugger",
    awarded_to: req.body.awarded_to || req.body.agent || "unknown",
    awarded_by: req.body.awarded_by || "rhizome-dojo",
    oath: "No retry without a gate.",
    status: "earned",
    timestamp: new Date().toISOString()
  });
});

app.get("/gates", async (_req, res) => {
  res.json(await readJSON("./data/gates.json"));
});

app.listen(PORT, BIND, () => {
  console.log(`axio-mo-hist-rhizome-dojo listening on ${BIND}:${PORT}`);
});
