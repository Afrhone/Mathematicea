import os, httpx
from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse

PORT = int(os.getenv("PORT","8102"))
API_URL = os.getenv("API_URL","http://api:8100")
app = FastAPI(title="Subtext MCP", version="0.1.0")
TOOLS = {"subtext.ingest":"Ingest text","subtext.compile":"Compile wiki","subtext.lint":"Lint","subtext.search":"Search tree","constellation.graph":"Return graph","promotion.create":"Promote node"}

@app.get("/health")
def health():
    return {"ok": True, "service": "mcp", "tools": list(TOOLS)}

@app.post("/rpc")
async def rpc(req: Request):
    body = await req.json()
    method = body.get("method")
    params = body.get("params", {})
    async with httpx.AsyncClient(timeout=120) as client:
        if method == "tools/list": return {"tools": TOOLS}
        if method == "subtext.ingest": return (await client.post(API_URL+"/ingest/text", json=params)).json()
        if method == "subtext.compile": return (await client.post(API_URL+"/compile")).json()
        if method == "subtext.lint": return (await client.post(API_URL+"/lint")).json()
        if method == "subtext.search": return (await client.get(API_URL+"/search", params={"q": params.get("q","")})).json()
        if method == "constellation.graph": return (await client.get(API_URL+"/graph")).json()
        if method == "promotion.create": return (await client.post(API_URL+"/promote/"+params["node_id"])).json()
    return JSONResponse({"error":"unknown method"}, status_code=404)

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=PORT)
