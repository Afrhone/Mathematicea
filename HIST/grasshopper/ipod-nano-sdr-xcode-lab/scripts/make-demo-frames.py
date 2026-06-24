#!/usr/bin/env python3
import math, sys
from pathlib import Path
from PIL import Image, ImageDraw
out=Path(sys.argv[1]); out.mkdir(parents=True, exist_ok=True)
for i in range(96):
    im=Image.new('RGB',(640,360),(5,4,12)); d=ImageDraw.Draw(im)
    for y in range(0,360,3):
        for x in range(0,640,4):
            v=(math.sin(x*.025+i*.08)+math.sin(y*.04+i*.13)+math.sin((x+y)*.012+i*.05))/3
            if v>.25:
                d.rectangle([x,y,x+3,y+2],fill=(int(120+120*v),int(80+120*v),255))
    d.text((20,20),f'Nano SDR Lab frame {i:03d}',fill=(255,255,255))
    im.save(out/f'frame_{i:04d}.png')
