from PIL import Image, ImageDraw, ImageFont
import random
T = 'Media/Themes/'
SC = 2; W, H = 300 * SC, 150 * SC
cond = '/usr/share/fonts/truetype/dejavu/DejaVuSansCondensed.ttf'
sans = '/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf'
serif = '/usr/share/fonts/truetype/dejavu/DejaVuSerif.ttf'


def tile(name, shade=1.0, alpha=1.0):
    im = Image.open(T + name + '.tga').convert('RGBA').resize((256 * SC, 256 * SC), Image.NEAREST)
    out = Image.new('RGBA', (W, H))
    for x in range(0, W, im.width):
        for y in range(0, H, im.height):
            out.paste(im, (x, y))
    r, g, b, a = out.split()
    if shade != 1.0:
        r, g, b = [p.point(lambda v: int(v * shade)) for p in (r, g, b)]
    if alpha < 1:
        a = a.point(lambda v: int(v * alpha))
    return Image.merge('RGBA', (r, g, b, a))


def window(layers, border, bw, header, bar, title, tfont, lines, bfont, pre=None, post=None, icon=None):
    img = Image.new('RGBA', (W, H), (0, 0, 0, 255))
    for l in layers:
        img.alpha_composite(l)
    if pre:
        ov = Image.new('RGBA', (W, H)); pre(ImageDraw.Draw(ov)); img.alpha_composite(ov)
    d = ImageDraw.Draw(img)
    img.alpha_composite(Image.new('RGBA', (W, 24 * SC), header), (0, 0))
    d.rectangle([0, 24 * SC, W, 24 * SC + bar[1] * SC], fill=(30, 30, 30))
    d.rectangle([0, 24 * SC, int(W * 0.48), 24 * SC + bar[1] * SC], fill=bar[0])
    ft = ImageFont.truetype(tfont[0], tfont[1] * SC)
    x = 10 * SC
    if icon:
        icon(d); x = 30 * SC
    for seg, col in title:
        d.text((x, 5 * SC), seg, font=ft, fill=col); x += d.textlength(seg, font=ft)
    fb = ImageFont.truetype(bfont[0], bfont[1] * SC); y = 36 * SC
    for row in lines:
        x = 10 * SC
        for seg, col in row:
            d.text((x, y), seg, font=fb, fill=col); x += d.textlength(seg, font=fb)
        y += 17 * SC
    for i in range(bw * SC):
        d.rectangle([i, i, W - 1 - i, H - 1 - i], outline=border)
    if post:
        post(d)
    return img


STEP = [('Complete ', (255, 255, 255)), ('Bloodscalp Ears', (255, 210, 0))]
TITLE_FOG = [('stranglethorn vale 38-42  ', (184, 176, 168)), ('12/24', (110, 106, 102))]

fogw = window([tile('fog_world'), Image.new('RGBA', (W, H), (200, 200, 196, 22))], (115, 41, 26), 2, (90, 20, 13, 90),
              ((140, 31, 20), 3), TITLE_FOG, (cond, 13),
              [STEP, [("Bloodscalp trolls at Bal'lal Ruins.", (216, 210, 204))], [('Hand in at Booty Bay afterwards.', (168, 168, 168))]], (cond, 12))


def statics(d):
    random.seed(4)
    for _ in range(16):
        y = random.randint(30 * SC, H - 6); x = random.randint(4, 120 * SC); w = random.randint(60, 400)
        d.line([(x, y), (x + w, y)], fill=(255, 255, 255, random.randint(18, 40)), width=SC)


fogo = window([tile('fog_rust', 0.95), tile('fog_grate', 1.0, 0.85)], (178, 13, 8), 2, (90, 20, 13, 110), ((140, 31, 20), 3),
              TITLE_FOG, (cond, 13),
              [STEP, [('... ', (176, 58, 46)), ('Bloodscalp trolls come in pairs and flee.', (210, 96, 74))],
               [('Pull from the edge; kill runners first.', (190, 190, 190))]], (cond, 12), pre=statics)


def brackets(d):
    c = (128, 242, 255)
    for (x, y, sx, sy) in ((2, 2, 1, 1), (W - 3, 2, -1, 1), (2, H - 3, 1, -1), (W - 3, H - 3, -1, -1)):
        d.line([(x, y), (x + sx * 28, y)], fill=c, width=4); d.line([(x, y), (x, y + sy * 28)], fill=c, width=4)


def scan(d):
    d.line([(0, 95 * SC), (W, 95 * SC)], fill=(100, 230, 255, 45), width=2)


sp = window([tile('hud_hex')], (64, 217, 255), 1, (64, 217, 255, 26), ((77, 230, 255), 5),
            [('STRANGLETHORN VALE 38-42  ', (127, 231, 255)), ('[12/24]', (63, 167, 199))], (cond, 13),
            [STEP, [('WARNING: ', (255, 80, 80)), ('Bloodscalp trolls come in pairs.', (255, 176, 160))],
             [('INTEL: ', (127, 231, 255)), ('Pull from the edge; kill runners.', (191, 239, 255))]], (cond, 12), pre=scan, post=brackets)


def embers(d):
    random.seed(7)
    for _ in range(9):
        x = random.randint(10, W - 10); y = random.randint(H - 140, H - 8); a = random.randint(90, 230)
        d.ellipse([x, y, x + 4, y + 4], fill=(255, 140, 40, a))


ash = window([tile('ashen_stone', 0.9)], (255, 138, 42), 4, (230, 100, 25, 20), ((217, 115, 31), 3),
             [('Stranglethorn Vale 38-42  ', (232, 213, 176)), ('12/24', (138, 122, 98))], (serif, 14),
             [STEP, [('Beware: ', (208, 64, 32)), ('Bloodscalp trolls come in pairs.', (224, 160, 128))],
              [('Try ', (201, 163, 90)), ('pulling from the edge first.', (216, 200, 168))]], (sans, 12), pre=embers)


def skull(d):
    d.ellipse([10 * SC, 6 * SC, 24 * SC, 19 * SC], fill=(239, 226, 192))
    d.ellipse([13 * SC, 10 * SC, 16 * SC, 13 * SC], fill=(60, 10, 10)); d.ellipse([18 * SC, 10 * SC, 21 * SC, 13 * SC], fill=(60, 10, 10))


imp = window([tile('imperial_plate', 0.85)], (212, 175, 55), 4, (150, 12, 12, 115), ((217, 173, 56), 3),
             [('+++ ', (212, 175, 55)), ('Stranglethorn Vale 38-42', (239, 226, 192)), (' +++', (212, 175, 55))], (serif, 13),
             [STEP, [('HERETIC THREAT: ', (208, 32, 32)), ('Trolls come in pairs.', (232, 160, 144))],
              [('Thought for the day: ', (212, 175, 55)), ('Pull from the edge.', (239, 226, 192))]], (sans, 12), icon=skull)

seal = Image.open(T + 'imperial_seal.tga').convert('RGBA').resize((64, 128))
pad = 24
cols = [('Fog Town', fogw), ('Fog Town - the shift (danger step)', fogo), ('Spartan HUD', sp), ('Ashen Bonfire', ash), ('Imperial Gothic', imp)]
sheet = Image.new('RGBA', (W * 2 + pad * 3, (H + 70) * 3 + 120), (236, 234, 228, 255))
lab = ImageFont.truetype(sans, 22); dd = ImageDraw.Draw(sheet)
for i, (name, im) in enumerate(cols):
    cx = pad + (i % 2) * (W + pad); cy = pad + (i // 2) * (H + 70)
    dd.text((cx, cy), name, font=lab, fill=(60, 60, 60)); sheet.alpha_composite(im, (cx, cy + 30))
    if name == 'Imperial Gothic':
        sheet.alpha_composite(seal, (cx + 34 * SC - 32, cy + 30 + H - 20))
sheet.convert('RGB').save('theme_textures_preview.png')
print(sheet.size)
