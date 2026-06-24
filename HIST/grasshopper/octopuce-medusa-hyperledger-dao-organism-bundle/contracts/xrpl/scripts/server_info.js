import xrpl from "xrpl";
const client = new xrpl.Client(process.env.XRPL_WS_URL || "ws://127.0.0.1:8001");
await client.connect();
const info = await client.request({ command: "server_info" });
console.log(JSON.stringify(info.result.info, null, 2));
await client.disconnect();
