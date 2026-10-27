"""Build the README animation from real AURA screenshots (Pillow required).

Run from the repository root: python3 tool/generate_showcase_gif.py
Only device framing, movement and transitions are added; no UI is repainted.
"""
from pathlib import Path
import math
from PIL import Image, ImageDraw, ImageFont, ImageFilter

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'docs/showcase/aura-themes.gif'
W, H, FPS, HOLD = 900, 680, 8, 8
COLORS = [('viola','#9750e8'),('blu','#2876dd'),('turchese','#008b8b'),('verde','#29834b'),('rosa','#c63e85'),('corallo','#c64c40'),('ambra','#a86b09'),('grafite','#646474')]
STATES = [(mode, color, accent) for color, accent in COLORS for mode in ('dark','light')]
N = len(STATES)*HOLD

def font(size, bold=False):
    names = [f'/System/Library/Fonts/Supplemental/Arial{" Bold" if bold else ""}.ttf', '/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf']
    for name in names:
        if Path(name).exists(): return ImageFont.truetype(name,size)
    return ImageFont.load_default(size=size)

bg = Image.new('RGB',(W,H)); d=ImageDraw.Draw(bg)
for y in range(H):
    t=y/H; d.line((0,y,W,y),fill=(int(10+7*t),int(9+4*t),int(16+12*t)))
glow=Image.new('RGB',(W,H));gd=ImageDraw.Draw(glow)
gd.ellipse((100,30,800,600),fill=(39,24,58));glow=glow.filter(ImageFilter.GaussianBlur(95))
bg=Image.blend(bg,glow,.38)
d=ImageDraw.Draw(bg)
icon=Image.open(ROOT/'assets/icons/aura-icon.png').convert('RGB').resize((35,35),Image.Resampling.LANCZOS)
mask=Image.new('L',(35,35));ImageDraw.Draw(mask).rounded_rectangle((0,0,34,34),radius=9,fill=255)
bg.paste(icon,(36,24),mask)
d.text((82,29),'AURA',font=font(19,True),fill='#f3edf9')
d.text((W-36,32),'YOUR MUSIC. YOUR UNIVERSE.',font=font(10),fill='#b6a5ca',anchor='ra')
d.text((W//2,81),'La musica, nel tuo stile.',font=font(30,True),fill='#f0e8fa',anchor='mm')
d.line((35,638,W-35,638),fill='#32263e')
d.text((35,658),'Schermate reali di AURA · iOS',font=font(10),fill='#9e8fb0',anchor='lm')
d.text((W-35,658),'Chiaro. Scuro. Tutti i tuoi colori.',font=font(10),fill='#9e8fb0',anchor='rm')

# Pre-render all screens once. Preserve screenshot aspect ratio inside the frame.
cache={}
def phone(state,width):
    key=(state,width)
    if key in cache:return cache[key]
    mode,color,_=STATES[state]
    pad=6; screen_w=width-pad*2; screen_h=round(screen_w*2622/1206)
    height=screen_h+pad*2
    im=Image.new('RGBA',(width+12,height+12));dr=ImageDraw.Draw(im)
    dr.rounded_rectangle((6,6,width+5,height+5),radius=34,fill='#777180',outline='#b5aabc',width=1)
    dr.rounded_rectangle((8,8,width+3,height+3),radius=32,fill='#08070a')
    shot=Image.open(ROOT/f'docs/showcase/themes/{mode}-{color}.jpg').convert('RGB').resize((screen_w,screen_h),Image.Resampling.LANCZOS)
    mask=Image.new('L',shot.size);ImageDraw.Draw(mask).rounded_rectangle((0,0,screen_w-1,screen_h-1),radius=27,fill=255)
    im.paste(shot,(6+pad,6+pad),mask)
    # Illustrative physical camera cutout, outside the app interface.
    dr.rounded_rectangle((6+width*.36,6+pad+7,6+width*.64,6+pad+21),radius=10,fill='black')
    cache[key]=im
    return im

# Shared palette avoids flickering between independently quantized frames.
samples=Image.new('RGB',(W*2,H*2))
for i,s in enumerate([0,1,6,11]):
    tile=bg.copy();p=phone(s,208);tile.paste(p,(W//2-p.width//2,115),p)
    samples.paste(tile,((i%2)*W,(i//2)*H))
palette=samples.quantize(colors=192,method=Image.Quantize.MEDIANCUT)
frames=[]
for frame in range(N):
    state=frame//HOLD; frac=(frame%HOLD)/HOLD
    next_state=(state+1)%len(STATES)
    blend=min(1,max(0,(frac-.6)/.275))
    phase=frame/N*2*math.pi
    canvas=bg.copy().convert('RGBA')
    for offset,width,x,base_y,angle in [(-1,173,205,149,-10),(1,173,695,149,10),(0,208,450,116,0)]:
        current=(state+offset)%len(STATES);future=(next_state+offset)%len(STATES)
        p=phone(current,width)
        if blend:p=Image.blend(p,phone(future,width),blend)
        tilt=angle+math.sin(phase+(offset+1)*1.3)*(2 if offset else 1.3)
        p=p.rotate(tilt,Image.Resampling.BICUBIC,expand=True)
        y=base_y+math.sin(phase+offset)*7
        shadow=Image.new('RGBA',canvas.size)
        sd=ImageDraw.Draw(shadow);sd.ellipse((x-width*.7,y+p.height-25,x+width*.7,y+p.height+19),fill=(0,0,0,170))
        canvas=Image.alpha_composite(canvas,shadow.filter(ImageFilter.GaussianBlur(15)))
        canvas.alpha_composite(p,(round(x-p.width/2),round(y)))
    draw=ImageDraw.Draw(canvas)
    mode,color,accent=STATES[state if blend<.5 else next_state]
    draw.text((450,592),f'{color.capitalize()}  ·  {"Scuro" if mode=="dark" else "Chiaro"}',font=font(15,True),fill='#e3d5f2',anchor='mm')
    for i,(name,hexcolor) in enumerate(COLORS):
        x=357+i*26
        if name==color:draw.ellipse((x-8,614-8,x+8,614+8),outline='#e8d8ff',width=1)
        draw.ellipse((x-5,609,x+5,619),fill=hexcolor)
    frames.append(canvas.convert('RGB').quantize(palette=palette,dither=Image.Dither.NONE))
OUT.parent.mkdir(exist_ok=True,parents=True)
frames[0].save(OUT,save_all=True,append_images=frames[1:],duration=[120,130]*(N//2),loop=0,optimize=True,disposal=1)
with Image.open(OUT) as check:
    assert check.n_frames==N
    assert check.info.get('loop')==0
    assert check.size==(W,H)
    total=0
    for i in range(check.n_frames):
        check.seek(i); total+=check.info['duration']
    assert total == 16000
print(f'{OUT.name}: {OUT.stat().st_size:,} bytes; {N} frames; {N/FPS:.0f}s; loops forever')
