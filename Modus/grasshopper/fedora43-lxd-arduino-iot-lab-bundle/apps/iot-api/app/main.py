import asyncio, json, os, time, glob, re, random
from typing import Dict, Any, List, Optional
from fastapi import FastAPI, WebSocket, WebSocketDisconnect, Header, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
try:
    import serial
except Exception:
    serial = None

API_TOKEN=os.getenv("IOT_API_TOKEN","change-me-token")
SERIAL_MATCH=os.getenv("ARDUINO_USB_MATCH","Arduino|UNO|Yun|WiFi|CH340|CP210|ACM|USB Serial")

app=FastAPI(title="Arduino IoT Lab API", version="1.0.0")
app.add_middleware(CORSMiddleware, allow_origins=["*"], allow_credentials=True, allow_methods=["*"], allow_headers=["*"])

latest: Dict[str, Any] = {
    "ts": time.time(),
    "bme280": {"temperature_c": None, "humidity_pct": None, "pressure_hpa": None},
    "bmm150": {"x_uT": None, "y_uT": None, "z_uT": None},
    "amg8833": {"pixels": []},
    "pn532": {"uid": None, "last_seen": None},
    "pins": {},
    "events": []
}
clients: List[WebSocket] = []

class Command(BaseModel):
    device: str
    command: str
    args: Dict[str, Any] = {}

class FlowNode(BaseModel):
    id: str
    type: str
    config: Dict[str, Any] = {}

class FlowGraph(BaseModel):
    nodes: List[FlowNode] = []
    edges: List[Dict[str, str]] = []

def require_auth(auth: Optional[str]):
    if API_TOKEN == "change-me-token":
        return
    if not auth or not auth.startswith("Bearer ") or auth.split(" ",1)[1] != API_TOKEN:
        raise HTTPException(status_code=401, detail="invalid token")

def serial_candidates():
    paths = sorted(glob.glob("/dev/arduino-*") + glob.glob("/dev/ttyACM*") + glob.glob("/dev/ttyUSB*"))
    return [{"path": p, "kind": "serial"} for p in paths]

async def broadcast(obj):
    dead=[]
    for ws in list(clients):
        try: await ws.send_json(obj)
        except Exception: dead.append(ws)
    for ws in dead:
        try: clients.remove(ws)
        except ValueError: pass

async def synthetic_loop():
    while True:
        latest["ts"]=time.time()
        latest["bme280"]={
            "temperature_c": round(21.5 + random.random()*2, 2),
            "humidity_pct": round(45 + random.random()*10, 2),
            "pressure_hpa": round(1008 + random.random()*4, 2),
        }
        latest["bmm150"]={
            "x_uT": round(random.uniform(-30,30),2),
            "y_uT": round(random.uniform(-30,30),2),
            "z_uT": round(random.uniform(-50,50),2),
        }
        latest["amg8833"]["pixels"]=[round(20+random.random()*8,2) for _ in range(64)]
        latest["pins"]={str(i): random.choice([0,1]) for i in range(2,14)}
        await broadcast({"type":"sensor.tick","data":latest})
        await asyncio.sleep(2)

@app.on_event("startup")
async def start():
    asyncio.create_task(synthetic_loop())

@app.get("/health")
async def health():
    return {"ok": True, "service": "arduino-iot-api", "time": time.time()}

@app.get("/api/devices")
async def devices():
    return {"serial": serial_candidates(), "wifi": [{"host": os.getenv("RUN_REV2_HOST","arduino-run.local"), "port": os.getenv("RUN_REV2_PORT","80")}]} 

@app.get("/api/sensors/latest")
async def sensors_latest():
    return latest

@app.post("/api/command")
async def command(cmd: Command, authorization: Optional[str]=Header(None)):
    require_auth(authorization)
    event={"ts": time.time(), "type":"command", "device": cmd.device, "command": cmd.command, "args": cmd.args}
    latest["events"].append(event)
    latest["events"]=latest["events"][-100:]
    await broadcast({"type":"command.accepted","data":event})
    return {"ok": True, "accepted": event, "note": "Serial write is intentionally gated; extend app/serial_worker.py for production."}

@app.post("/api/flow/validate")
async def validate_flow(flow: FlowGraph, authorization: Optional[str]=Header(None)):
    require_auth(authorization)
    allowed={"sensor","filter","threshold","mqtt","serial-command","kicad-export","canvas","agent"}
    errors=[]
    for n in flow.nodes:
        if n.type not in allowed:
            errors.append({"node": n.id, "error": f"type {n.type} not allowed"})
    return {"ok": not errors, "errors": errors, "summary": {"nodes": len(flow.nodes), "edges": len(flow.edges)}}

@app.get("/api/mcp/tools")
async def mcp_tools():
    return {
        "tools":[
            {"name":"list_arduino_devices","description":"List USB serial Arduino devices"},
            {"name":"read_latest_sensors","description":"Return latest sensor frame"},
            {"name":"generate_kicad_schematic_stub","description":"Create a KiCad project scaffold from selected modules"},
            {"name":"validate_signal_flow","description":"Check drag/drop signal-flow graph"}
        ]
    }

@app.websocket("/ws")
async def ws_endpoint(ws: WebSocket):
    await ws.accept()
    clients.append(ws)
    try:
        await ws.send_json({"type":"hello","data":{"service":"arduino-iot-api"}})
        while True:
            msg=await ws.receive_text()
            try: obj=json.loads(msg)
            except Exception: obj={"raw":msg}
            await ws.send_json({"type":"echo","data":obj})
    except WebSocketDisconnect:
        try: clients.remove(ws)
        except ValueError: pass
