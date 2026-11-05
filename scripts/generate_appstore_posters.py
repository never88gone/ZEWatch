import os
import math
from PIL import Image, ImageDraw, ImageFont, ImageFilter

FONT_SERIF = "/System/Library/Fonts/Supplemental/Songti.ttc"
FONT_SANS = "/System/Library/Fonts/Hiragino Sans GB.ttc"

def create_background(w, h, glow_color=(25, 60, 130)):
    bg = Image.new("RGBA", (w, h), (7, 10, 19, 255))
    draw = ImageDraw.Draw(bg)
    
    top_color = (14, 25, 46)
    bot_color = (6, 9, 16)
    
    for y in range(h):
        ratio = y / float(h)
        r = int(top_color[0] * (1 - ratio) + bot_color[0] * ratio)
        g = int(top_color[1] * (1 - ratio) + bot_color[1] * ratio)
        b = int(top_color[2] * (1 - ratio) + bot_color[2] * ratio)
        draw.line([(0, y), (w, y)], fill=(r, g, b, 255))
        
    glow = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    glow_draw = ImageDraw.Draw(glow)
    center_x = w // 2
    center_y = int(h * 0.32)
    max_radius = int(w * 0.75)
    
    for r in range(max_radius, 0, -25):
        alpha = int((1.0 - r / max_radius) ** 2 * 45)
        glow_draw.ellipse(
            [center_x - r, center_y - r, center_x + r, center_y + r],
            fill=(glow_color[0], glow_color[1], glow_color[2], alpha)
        )
    
    return Image.alpha_composite(bg, glow)

def draw_pill_badge(base_img, text, cx, cy, font, fill_color=(255, 215, 0)):
    bbox = font.getbbox(text)
    tw = bbox[2] - bbox[0]
    th = bbox[3] - bbox[1]
    
    pw = tw + 56
    ph = th + 28
    rx = cx - pw // 2
    ry = cy - ph // 2
    
    # 在独立透明图层上合成，保证完美的半透明质感
    layer = Image.new("RGBA", base_img.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)
    
    # 雅致半透明暗金底色与高光金边
    draw.rounded_rectangle(
        [rx, ry, rx + pw, ry + ph],
        radius=ph // 2,
        fill=(fill_color[0], fill_color[1], fill_color[2], 35),
        outline=(fill_color[0], fill_color[1], fill_color[2], 180),
        width=2
    )
    draw.text((cx - tw // 2, cy - th // 2 - 2), text, font=font, fill=(fill_color[0], fill_color[1], fill_color[2], 255))
    
    return Image.alpha_composite(base_img, layer)

def add_phone_mockup(base_img, screenshot_path, target_rect):
    sx, sy, sw, sh = target_rect
    screen = Image.open(screenshot_path).convert("RGBA")
    screen = screen.resize((sw, sh), Image.Resampling.LANCZOS)
    
    corner_radius = 56
    mask = Image.new("L", (sw, sh), 0)
    mask_draw = ImageDraw.Draw(mask)
    mask_draw.rounded_rectangle([0, 0, sw, sh], radius=corner_radius, fill=255)
    
    border_thickness = 16
    fx = sx - border_thickness
    fy = sy - border_thickness
    fw = sw + border_thickness * 2
    fh = sh + border_thickness * 2
    
    shadow_pad = 90
    shadow_img = Image.new("RGBA", (fw + shadow_pad * 2, fh + shadow_pad * 2), (0, 0, 0, 0))
    s_draw = ImageDraw.Draw(shadow_img)
    s_draw.rounded_rectangle(
        [shadow_pad, shadow_pad, shadow_pad + fw, shadow_pad + fh],
        radius=corner_radius + border_thickness,
        fill=(0, 0, 0, 210)
    )
    shadow_img = shadow_img.filter(ImageFilter.GaussianBlur(40))
    
    base_img.paste(shadow_img, (fx - shadow_pad, fy - shadow_pad + 25), shadow_img)
    
    frame_img = Image.new("RGBA", (fw, fh), (0, 0, 0, 0))
    f_draw = ImageDraw.Draw(frame_img)
    f_draw.rounded_rectangle(
        [0, 0, fw, fh],
        radius=corner_radius + border_thickness,
        fill=(22, 25, 32, 255),
        outline=(70, 78, 96, 220),
        width=3
    )
    
    base_img.paste(frame_img, (fx, fy), frame_img)
    base_img.paste(screen, (sx, sy), mask)

def render_poster(badge, title, subtitle, screenshot_path, output_path, canvas_size=(1290, 2796), extra_watch_path=None, glow_rgb=(30, 75, 150), is_gold_badge=True):
    cw, ch = canvas_size
    img = create_background(cw, ch, glow_rgb)
    
    scale = ch / 2796.0
    
    font_badge = ImageFont.truetype(FONT_SANS, int(34 * scale))
    font_title = ImageFont.truetype(FONT_SERIF, int(94 * scale))
    font_sub = ImageFont.truetype(FONT_SANS, int(42 * scale))
    
    # 顶部小徽章胶囊
    badge_color = (255, 215, 0) if is_gold_badge else (100, 220, 255)
    badge_y = int(230 * scale)
    img = draw_pill_badge(img, badge, cw // 2, badge_y, font_badge, badge_color)
    
    draw = ImageDraw.Draw(img)
    
    # 苍劲主标题
    t_box = font_title.getbbox(title)
    tw = t_box[2] - t_box[0]
    title_y = int(325 * scale)
    draw.text(((cw - tw) // 2, title_y), title, font=font_title, fill=(255, 253, 246, 255))
    
    # 优雅副标题
    s_box = font_sub.getbbox(subtitle)
    sw = s_box[2] - s_box[0]
    sub_y = int(455 * scale)
    draw.text(((cw - sw) // 2, sub_y), subtitle, font=font_sub, fill=(160, 178, 204, 255))
    
    # 机身展示
    phone_w = int(1060 * (cw / 1290.0) * 0.95)
    phone_h = int(phone_w / 0.687)
    phone_x = (cw - phone_w) // 2
    phone_y = int(610 * scale)
    
    add_phone_mockup(img, screenshot_path, (phone_x, phone_y, phone_w, phone_h))
    
    # 若有 Apple Watch 悬浮联动
    if extra_watch_path and os.path.exists(extra_watch_path):
        watch_screen = Image.open(extra_watch_path).convert("RGBA")
        ww = int(420 * scale)
        wh = int(500 * scale)
        watch_screen = watch_screen.resize((ww, wh), Image.Resampling.LANCZOS)
        
        bw = ww + int(44 * scale)
        bh = wh + int(44 * scale)
        watch_frame = Image.new("RGBA", (bw, bh), (0, 0, 0, 0))
        wf_draw = ImageDraw.Draw(watch_frame)
        wf_draw.rounded_rectangle([0, 0, bw, bh], radius=int(80 * scale), fill=(26, 28, 34, 255), outline=(100, 110, 130, 230), width=4)
        
        w_mask = Image.new("L", (ww, wh), 0)
        wm_draw = ImageDraw.Draw(w_mask)
        wm_draw.rounded_rectangle([0, 0, ww, wh], radius=int(62 * scale), fill=255)
        
        pad = (bw - ww) // 2
        watch_frame.paste(watch_screen, (pad, pad), w_mask)
        
        watch_shadow = Image.new("RGBA", (bw + int(80 * scale), bh + int(80 * scale)), (0, 0, 0, 0))
        ws_draw = ImageDraw.Draw(watch_shadow)
        ws_pad = int(40 * scale)
        ws_draw.rounded_rectangle([ws_pad, ws_pad, ws_pad + bw, ws_pad + bh], radius=int(80 * scale), fill=(0, 0, 0, 220))
        watch_shadow = watch_shadow.filter(ImageFilter.GaussianBlur(int(35 * scale)))
        
        wx = int(75 * (cw / 1290.0))
        wy = ch - bh - int(240 * scale)
        img.paste(watch_shadow, (wx - ws_pad, wy - ws_pad + int(20 * scale)), watch_shadow)
        img.paste(watch_frame, (wx, wy), watch_frame)
        
        watch_tag_font = ImageFont.truetype(FONT_SANS, int(26 * scale))
        img = draw_pill_badge(img, "腕间实时同步流转", wx + bw // 2, wy + bh + int(48 * scale), watch_tag_font, (100, 225, 255))
    
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    img.convert("RGB").save(output_path, "PNG", quality=95)
    print(f"Generated: {output_path}")

def generate_all():
    src = "AppStore_Screenshots/iPhone_Duo_Outer"
    
    pages = [
        {
            "name": "1_宣传页_修仙表盘工坊.png",
            "badge": "1.0.2 震撼上线 · 修仙表盘",
            "title": "万千灵盘 · 一念化境",
            "subtitle": "五大专属修仙表盘 · 实时同步 Apple Watch",
            "screenshot": os.path.join(src, "1_修仙表盘工坊.png"),
            "extra_watch": "/Users/never88gone/.gemini/antigravity/brain/3d53d6b9-28dc-448d-aa2a-d1e21705b69a/watch_face_taiji.png",
            "glow": (30, 80, 160),
            "gold": True
        },
        {
            "name": "2_宣传页_洞府大盘.png",
            "badge": "全新健康修行体系",
            "title": "步履为阶 · 渡劫飞升",
            "subtitle": "日常步数化作五行真元 · 随时感应天地灵气",
            "screenshot": os.path.join(src, "2_洞府大盘.png"),
            "extra_watch": None,
            "glow": (180, 110, 30),
            "gold": True
        },
        {
            "name": "3_宣传页_识海伴修.png",
            "badge": "端侧 AI 智能仙尊",
            "title": "老爷爷随身 · 识海伴修",
            "subtitle": "戒指中的仙尊残魂 · 随时点拨传音指引道途",
            "screenshot": os.path.join(src, "3_识海伴修.png"),
            "extra_watch": None,
            "glow": (140, 40, 160),
            "gold": False
        },
        {
            "name": "4_宣传页_天降机缘.png",
            "badge": "健身正向激励",
            "title": "天降机缘 · 气运造化",
            "subtitle": "达成运动里程 · 开启仙道气运盲盒获得修为",
            "screenshot": os.path.join(src, "4_天降机缘.png"),
            "extra_watch": None,
            "glow": (200, 140, 20),
            "gold": True
        },
        {
            "name": "5_宣传页_法器宝阁.png",
            "badge": "完全离线 · 极客隐私",
            "title": "端侧神念 · 零网络泄露",
            "subtitle": "本地沙盒极速推理大模型 · 隐私安全固若金汤",
            "screenshot": os.path.join(src, "5_法器宝阁.png"),
            "extra_watch": None,
            "glow": (20, 140, 120),
            "gold": False
        },
        {
            "name": "6_宣传页_健康五行法则.png",
            "badge": "HealthKit 深度融合",
            "title": "健康法则 · 灵脉归一",
            "subtitle": "步数/心率/卡路里/睡眠 · 完美映射五行道果",
            "screenshot": os.path.join(src, "6_健康五行法则.png"),
            "extra_watch": None,
            "glow": (40, 120, 80),
            "gold": True
        }
    ]
    
    # 1. 6.7 英寸 (1290 x 2796)
    out_67 = "AppStore_Screenshots/Promotional_Pages/6.7-inch"
    for p in pages:
        render_poster(
            badge=p["badge"],
            title=p["title"],
            subtitle=p["subtitle"],
            screenshot_path=p["screenshot"],
            output_path=os.path.join(out_67, p["name"]),
            canvas_size=(1290, 2796),
            extra_watch_path=p["extra_watch"],
            glow_rgb=p["glow"],
            is_gold_badge=p["gold"]
        )
        
    # 2. iPhone Duo (1398 x 2034)
    out_duo = "AppStore_Screenshots/Promotional_Pages/iPhone_Duo"
    for p in pages:
        render_poster(
            badge=p["badge"],
            title=p["title"],
            subtitle=p["subtitle"],
            screenshot_path=p["screenshot"],
            output_path=os.path.join(out_duo, p["name"]),
            canvas_size=(1398, 2034),
            extra_watch_path=p["extra_watch"],
            glow_rgb=p["glow"],
            is_gold_badge=p["gold"]
        )

if __name__ == "__main__":
    generate_all()
