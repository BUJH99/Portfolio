"""Original procedural demo assets for the recovered rhythm-game runtime.

No archived music, fonts, or graphics are needed. Existing user-supplied assets
can still be placed at the original paths; missing assets use these fallbacks.
"""
import array
import io
import math
from pathlib import Path
import pygame
from PIL import Image

TRACKS = ['Pulse Steps', 'Four Corners', 'Neon Practice']

def font(path, size):
    return pygame.font.Font(str(path) if Path(path).is_file() else None, max(1,int(size)))

def image(path):
    p=Path(path)
    if p.is_file(): return pygame.image.load(str(p))
    if p.suffix.lower()=='.jpg' or p.name=='BG.png':
        surface=pygame.Surface((800,450))
        surface.fill((10,20,35))
        for x in range(0,800,50): pygame.draw.line(surface,(18,40,58),(x,0),(x,450))
        for y in range(0,450,50): pygame.draw.line(surface,(18,40,58),(0,y),(800,y))
        pygame.draw.circle(surface,(18,70,92),(400,225),150,3)
        pygame.draw.circle(surface,(30,122,145),(400,225),110,2)
        return surface
    surface=pygame.Surface((128,128),pygame.SRCALPHA)
    if p.name.startswith('GEAR'):
        pygame.draw.rect(surface,(30,100,125),(4,0,120,128),3)
        for x in (35,64,93): pygame.draw.line(surface,(25,65,85),(x,0),(x,128),1)
    elif p.name=='RATE_LINE.png':
        pygame.draw.rect(surface,(64,230,195),(0,55,128,18),border_radius=4)
    elif p.name.startswith('effect') or p.name.startswith('fever'):
        pygame.draw.circle(surface,(65,230,205,170),(64,64),48,5)
    else:
        pygame.draw.rect(surface,(50,210,180),(5,5,118,118),border_radius=16)
        pygame.draw.rect(surface,(175,255,240),(9,9,110,110),3,border_radius=13)
    return surface

def pil_image(path):
    if Path(path).is_file(): return Image.open(path)
    surface=image(path)
    return Image.frombytes('RGB',surface.get_size(),pygame.image.tobytes(surface,'RGB'))

def chart(path, mode='r'):
    if Path(path).is_file(): return open(path,mode,encoding='utf-8')
    # Fixed-width chart layout expected by the recovered parser.
    lines=['NOTE_START=0.0000','SONG_START=2.0000','BPM_VALUE =120.00']
    for idx in range(32):
        lanes=str((idx%4)+1).ljust(4,'0')
        lines.append(f'{lanes} 4.0 0.0 2.0')
    return io.StringIO('\n'.join(lines)+'\n')

def sound(path):
    if Path(path).is_file(): return pygame.mixer.Sound(str(path))
    rate,_,channels=pygame.mixer.get_init()
    samples=array.array('h')
    frequencies=[220.0,277.18,329.63,440.0]
    for index in range(rate*20):
        beat=int(index/(rate/2)); offset=index%(rate//2)
        envelope=max(0.0,1.0-offset/(rate*0.18))
        value=int(5000*envelope*math.sin(2*math.pi*frequencies[beat%4]*index/rate))
        samples.extend([value]*channels)
    return pygame.mixer.Sound(buffer=samples)
