# -*- coding: utf-8 -*-
"""Generate StudyMate Pro app icon - brain + lightning bolt design"""
from PIL import Image, ImageDraw, ImageFont
import math, os

SIZE = 1024
WHITE = (255, 255, 255, 255)
TRANSPARENT = (0, 0, 0, 0)

# ─── Colors ───
CYAN_TOP    = (14, 165, 233)    # #0EA5E9
CYAN_BOTTOM = (2, 80, 160)      # deep blue
ORANGE_TOP  = (251, 191, 36)    # #FBBF24 gold
ORANGE_BOT  = (220, 80, 30)     # orange-red
LIGHTNING   = (251, 191, 36, 255)  # #FBBF24
DARK_BLUE   = (30, 58, 95)      # #1E3A5F
CYAN_TEXT   = (14, 165, 233)    # #0EA5E9

# ─── Brain bounding box ───
BX1 = int(SIZE * 0.10)
BY1 = int(SIZE * 0.04)
BX2 = int(SIZE * 0.90)
BY2 = int(SIZE * 0.68)
BW = BX2 - BX1
BH = BY2 - BY1
BCX = (BX1 + BX2) // 2
BCY = (BY1 + BY2) // 2

# ─── Lightning bolt path (Z-shape, diagonal through center) ───
bolt_hw = int(BW * 0.08)  # half-width of bolt
bolt_pts = [
    (BCX - bolt_hw, BY1 + int(BH * 0.05)),       # top-left
    (BCX + bolt_hw, BY1 + int(BH * 0.15)),       # top-right
    (BCX - bolt_hw, BY1 + int(BH * 0.35)),       # mid-left
    (BCX + bolt_hw, BY1 + int(BH * 0.55)),       # mid-right
    (BCX - bolt_hw, BY1 + int(BH * 0.75)),       # bot-left
    (BCX + bolt_hw, BY1 + int(BH * 0.88)),       # bot-right
]

def create_gradient(w, h, c1, c2):
    """Vertical linear gradient"""
    grad = Image.new('RGBA', (w, h))
    for y in range(h):
        t = y / max(h - 1, 1)
        r = int(c1[0] + (c2[0] - c1[0]) * t)
        g = int(c1[1] + (c2[1] - c1[1]) * t)
        b = int(c1[2] + (c2[2] - c1[2]) * t)
        for x in range(w):
            grad.putpixel((x, y), (r, g, b, 255))
    return grad

def brain_outline_path():
    """Return list of (x,y) points tracing the brain outline (clockwise)"""
    pts = []
    n = 120
    # Top half of ellipse (left to right)
    for i in range(n + 1):
        angle = math.pi + math.pi * i / n  # pi to 2pi
        x = BCX + (BW / 2) * math.cos(angle)
        y = BCY + (BH / 2) * math.sin(angle)
        pts.append((x, y))
    # Bottom with cleft: go from right-bottom toward center, dip down, back up
    cleft_depth = BH * 0.06
    cleft_w = BW * 0.06
    # right-bottom to cleft
    pts.append((BCX + cleft_w, BY2))
    pts.append((BCX, BY2 + cleft_depth))
    pts.append((BCX - cleft_w, BY2))
    return pts

def draw_brain_gyrus(draw, cx, cy, rx, ry, color, alpha):
    """Draw semi-transparent arc lines simulating brain folds"""
    overlay = Image.new('RGBA', (SIZE, SIZE), TRANSPARENT)
    odraw = ImageDraw.Draw(overlay)
    c = (*color, alpha)
    # Arc 1 - upper
    odraw.arc(
        [cx - int(rx * 0.7), cy - int(ry * 0.5), cx + int(rx * 0.7), cy + int(ry * 0.3)],
        start=200, end=340, fill=c, width=3
    )
    # Arc 2 - lower
    odraw.arc(
        [cx - int(rx * 0.6), cy + int(ry * 0.05), cx + int(rx * 0.6), cy + int(ry * 0.7)],
        start=190, end=350, fill=c, width=3
    )
    return overlay

# ─── Build icon ───
img = Image.new('RGBA', (SIZE, SIZE), WHITE)

# 1. Create full brain mask
brain_mask = Image.new('L', (SIZE, SIZE), 0)
mdraw = ImageDraw.Draw(brain_mask)
# Main ellipse
mdraw.ellipse([BX1, BY1, BX2, BY2], fill=255)
# Bottom cleft
cw = int(BW * 0.07)
ch = int(BH * 0.08)
mdraw.ellipse([BCX - cw, BY2 - ch, BCX + cw, BY2 + ch], fill=0)
# Side indentations (temporal)
iw = int(BW * 0.06)
ih = int(BH * 0.10)
iy = BCY + int(BH * 0.08)
mdraw.ellipse([BX1 - iw//2, iy - ih, BX1 + iw, iy + ih], fill=0)
mdraw.ellipse([BX2 - iw, iy - ih, BX2 + iw//2, iy + ih], fill=0)

# 2. Create left-half mask (everything left of lightning bolt)
left_mask = brain_mask.copy()
ldraw = ImageDraw.Draw(left_mask)
# Erase right side of lightning bolt
ldraw.polygon(bolt_pts + [(SIZE, BY2), (SIZE, 0)], fill=0)

# 3. Create right-half mask (everything right of lightning bolt)
right_mask = brain_mask.copy()
rdraw = ImageDraw.Draw(right_mask)
rdraw.polygon(bolt_pts + [(0, BY2), (0, 0)], fill=0)

# 4. Create gradient images
left_grad = create_gradient(SIZE, SIZE, CYAN_TOP, CYAN_BOTTOM)
right_grad = create_gradient(SIZE, SIZE, ORANGE_TOP, ORANGE_BOT)

# 5. Composite brain halves
left_brain = Image.new('RGBA', (SIZE, SIZE), TRANSPARENT)
left_brain.paste(left_grad, mask=left_mask)
right_brain = Image.new('RGBA', (SIZE, SIZE), TRANSPARENT)
right_brain.paste(right_grad, mask=right_mask)

img.paste(left_brain, mask=left_brain)
img.paste(right_brain, mask=right_brain)

# 6. Draw brain gyrus texture
gyrus_left = draw_brain_gyrus(None, BCX - int(BW * 0.18), BCY, BW * 0.28, BH * 0.40, (200, 230, 255), 60)
gyrus_right = draw_brain_gyrus(None, BCX + int(BW * 0.18), BCY, BW * 0.28, BH * 0.40, (255, 220, 180), 60)
img.paste(gyrus_left, mask=left_mask)
img.paste(gyrus_right, mask=right_mask)

# 7. Draw lightning bolt
bolt_overlay = Image.new('RGBA', (SIZE, SIZE), TRANSPARENT)
bdraw = ImageDraw.Draw(bolt_overlay)
# White stroke (wider)
bdraw.polygon(bolt_pts, fill=LIGHTNING, outline=(255, 255, 255, 255), width=10)
img.paste(bolt_overlay, mask=bolt_overlay)

# 8. Draw text "studymate"
text_y = int(SIZE * 0.78)
try:
    font = ImageFont.truetype("C:/Windows/Fonts/seguiemj.ttf", int(SIZE * 0.09))
except:
    try:
        font = ImageFont.truetype("C:/Windows/Fonts/segoeui.ttf", int(SIZE * 0.09))
    except:
        font = ImageFont.load_default()

# Split text: "study" + "mate"
text_draw = ImageDraw.Draw(img)
study_w = text_draw.textbbox((0, 0), "study", font=font)[2]
mate_w = text_draw.textbbox((0, 0), "mate", font=font)[2]
total_w = study_w + mate_w
start_x = (SIZE - total_w) // 2

text_draw.text((start_x, text_y), "study", fill=DARK_BLUE + (255,), font=font)
text_draw.text((start_x + study_w, text_y), "mate", fill=CYAN_TEXT + (255,), font=font)

# 9. Save
output = os.path.join(os.path.dirname(__file__), '..', 'assets', 'icon', 'app_icon.png')
os.makedirs(os.path.dirname(output), exist_ok=True)
img.save(output, 'PNG')
print(f"Icon saved to: {output}")

# Also save as ic_launcher for Android
android_path = os.path.join(os.path.dirname(__file__), '..', 'android', 'app', 'src', 'main', 'res')
for density, dim in [('mdpi', 48), ('hdpi', 72), ('xhdpi', 96), ('xxhdpi', 144), ('xxxhdpi', 192)]:
    d = os.path.join(android_path, f'mipmap-{density}')
    os.makedirs(d, exist_ok=True)
    resized = img.resize((dim, dim), Image.LANCZOS)
    resized.save(os.path.join(d, 'ic_launcher.png'), 'PNG')
    print(f"  Saved mipmap-{density} ({dim}x{dim})")

# 10. Generate adaptive icon foreground (brain+bolt, transparent bg, no text)
fg = Image.new('RGBA', (SIZE, SIZE), TRANSPARENT)
fg.paste(left_brain, mask=left_brain)
fg.paste(right_brain, mask=right_brain)
fg.paste(gyrus_left, mask=left_mask)
fg.paste(gyrus_right, mask=right_mask)
fg.paste(bolt_overlay, mask=bolt_overlay)

for density, dim in [('mdpi', 108), ('hdpi', 162), ('xhdpi', 216), ('xxhdpi', 324), ('xxxhdpi', 432)]:
    d = os.path.join(android_path, f'drawable-{density}')
    os.makedirs(d, exist_ok=True)
    resized = fg.resize((dim, dim), Image.LANCZOS)
    resized.save(os.path.join(d, 'ic_launcher_foreground.png'), 'PNG')
    print(f"  Saved drawable-{density} foreground ({dim}x{dim})")

# 11. Generate Windows .ico
ico_path = os.path.join(os.path.dirname(__file__), '..', 'windows', 'runner', 'resources', 'app_icon.ico')
os.makedirs(os.path.dirname(ico_path), exist_ok=True)
sizes = [(256, 256), (128, 128), (64, 64), (48, 48), (32, 32), (16, 16)]
img_rgba = img.convert('RGBA')
img_rgba.save(ico_path, format='ICO', sizes=sizes)
print(f"  Saved Windows ICO: {ico_path}")

print("Done!")
