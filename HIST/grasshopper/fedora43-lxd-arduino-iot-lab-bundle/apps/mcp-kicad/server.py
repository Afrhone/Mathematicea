from fastapi import FastAPI
from pydantic import BaseModel
from pathlib import Path
import time, os, json

app=FastAPI(title="KiCad MCP Bridge", version="1.0.0")
ROOT=Path(os.getenv("KICAD_PROJECT_ROOT","/workspace/kicad-projects"))
ROOT.mkdir(parents=True, exist_ok=True)

class BoardSpec(BaseModel):
    name: str
    modules: list[str] = []
    notes: str = ""

@app.get("/health")
def health(): return {"ok": True, "service":"kicad-mcp", "root": str(ROOT)}

@app.get("/mcp/tools")
def tools():
    return {"tools":[
        {"name":"create_board_scaffold","description":"Create a KiCad project scaffold from modules"},
        {"name":"list_projects","description":"List generated KiCad project scaffolds"},
        {"name":"export_netlist_stub","description":"Return placeholder netlist/spec"}
    ]}

@app.post("/mcp/create_board_scaffold")
def create(spec: BoardSpec):
    safe=''.join(c for c in spec.name if c.isalnum() or c in '-_')[:64] or 'board'
    p=ROOT/safe
    p.mkdir(parents=True, exist_ok=True)
    manifest={
        "name": safe,
        "created": time.time(),
        "modules": spec.modules,
        "notes": spec.notes,
        "boundary": "scaffold only; operator validates electrical design before fabrication"
    }
    (p/"manifest.json").write_text(json.dumps(manifest,indent=2))
    (p/f"{safe}.kicad_pro").write_text(json.dumps({"meta":{"version":1},"project":{"name":safe}}, indent=2))
    (p/"README.md").write_text(f"# {safe}\n\nModules: {', '.join(spec.modules)}\n\n{spec.notes}\n")
    return {"ok": True, "path": str(p), "manifest": manifest}

@app.get("/mcp/projects")
def projects():
    return {"projects":[x.name for x in ROOT.iterdir() if x.is_dir()]}
