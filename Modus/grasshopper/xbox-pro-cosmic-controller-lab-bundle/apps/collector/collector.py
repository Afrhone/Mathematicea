
import time,os,asyncio,httpx
try: import evdev
except Exception: evdev=None
GATEWAY=os.getenv('GATEWAY_URL','http://gateway:8097')
async def main():
 if evdev is None:
  print('evdev unavailable; collector idle')
  while True: await asyncio.sleep(30)
 async with httpx.AsyncClient(timeout=5) as c:
  while True:
   devices=[evdev.InputDevice(p) for p in evdev.list_devices()]
   pads=[d for d in devices if any(x in d.name for x in ['Xbox','Gamepad','Controller'])]
   payload={'source':'evdev','devices':[{'path':d.path,'name':d.name,'phys':d.phys} for d in pads],'ts':time.time()}
   try: await c.post(GATEWAY+'/telemetry',json=payload)
   except Exception as e: print('telemetry error',e)
   await asyncio.sleep(2)
asyncio.run(main())
