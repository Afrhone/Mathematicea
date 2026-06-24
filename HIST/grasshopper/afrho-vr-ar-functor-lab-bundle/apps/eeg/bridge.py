import asyncio, json, math, time, websockets
async def handler(ws):
    while True:
        t=time.time()
        await ws.send(json.dumps({"alpha": .5+.5*math.sin(t/4), "beta": .5+.5*math.cos(t/6), "t": t}))
        await asyncio.sleep(.2)
async def main():
    async with websockets.serve(handler, "0.0.0.0", 9001):
        await asyncio.Future()
asyncio.run(main())
