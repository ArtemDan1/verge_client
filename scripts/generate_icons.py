#!/usr/bin/env python3
"""Генерирует иконки Verge (дизайн «Бумага») из векторных описаний.

  - assets/branding/verge-app-icon-{light,dark}.svg — исходники иконки;
  - assets/branding/verge-app-icon-1024.png — основная (светлая) для
    flutter_launcher_icons, verge-app-icon-{light,dark}-1024.png — варианты;
  - assets/tray/tray_{disconnected,connecting,connected}.png — macOS,
    монохромный template-образ 44×44 (22 pt @2x): цвет подставляет система;
  - assets/tray/tray_*.ico — Windows, цветные, 16/20/24/32/48 px.

Запуск:  pip install cairosvg pillow && python3 scripts/generate_icons.py
После — `dart run flutter_launcher_icons`, чтобы разложить иконку по
платформам.
"""

import io
from pathlib import Path

import cairosvg
from PIL import Image, ImageChops, ImageOps

ROOT = Path(__file__).resolve().parent.parent
BRANDING = ROOT / "assets" / "branding"
TRAY = ROOT / "assets" / "tray"

# Геометрия знака в сетке 1024: V и кобальтовая черта-основание.
V_PATH = "M 224 260 L 512 740 L 800 260"


def app_icon_svg(tile: str, border: str, ink: str, bar: str) -> str:
    return f"""<svg viewBox="0 0 1024 1024" xmlns="http://www.w3.org/2000/svg">
  <rect width="1024" height="1024" rx="230" fill="{tile}"/>
  <rect x="8" y="8" width="1008" height="1008" rx="222" fill="none" stroke="{border}" stroke-width="16"/>
  <path d="{V_PATH}" stroke="{ink}" stroke-width="128" fill="none" stroke-linecap="round" stroke-linejoin="round"/>
  <rect x="304" y="832" width="416" height="56" rx="28" fill="{bar}"/>
</svg>
"""


APP_LIGHT = app_icon_svg("#FBFAF7", "#DEDBD2", "#1C1B18", "#2E5BFF")
APP_DARK = app_icon_svg("#26241F", "#3A3832", "#EDEBE5", "#5C80FF")

# --- Трей: плитка вокруг V в сетке 22×22 --------------------------------------
# Пустая плитка — отключено, пунктир — подключение, залитая плитка с
# вырезанной V — подключено. Форма различима и без цвета (template на macOS).
TRAY_V = "M6.5 7 L11 14.5 L15.5 7"


def tray_svg(state: str, *, stroke: str, v: str, fill: str | None = None,
             dashed: bool = False) -> str:
    if state == "connected":
        # Залитая плитка; V рисуется поверх (Windows) или вырезается из неё
        # отдельно, в knock_out() (macOS template).
        vpath = (
            f'<path d="{TRAY_V}" stroke="{v}" stroke-width="2.2" fill="none" '
            'stroke-linecap="round" stroke-linejoin="round"/>'
            if v != "transparent" else ""
        )
        return (
            '<svg viewBox="0 0 22 22" xmlns="http://www.w3.org/2000/svg">'
            f'<rect x="1.7" y="1.7" width="18.6" height="18.6" rx="5.6" '
            f'fill="{fill}"/>{vpath}</svg>'
        )
    dash = ' stroke-dasharray="4 2.2"' if dashed else ""
    return (
        '<svg viewBox="0 0 22 22" xmlns="http://www.w3.org/2000/svg">'
        f'<rect x="2.5" y="2.5" width="17" height="17" rx="5" fill="none" '
        f'stroke="{stroke}" stroke-width="1.8"{dash}/>'
        f'<path d="{TRAY_V}" stroke="{v}" stroke-width="2" fill="none" '
        'stroke-linecap="round" stroke-linejoin="round"/></svg>'
    )


# Штрих V отдельно — для выреза из залитой плитки.
TRAY_V_ONLY = (
    '<svg viewBox="0 0 22 22" xmlns="http://www.w3.org/2000/svg">'
    f'<path d="{TRAY_V}" stroke="#000" stroke-width="2.2" fill="none" '
    'stroke-linecap="round" stroke-linejoin="round"/></svg>'
)


# macOS: чистый чёрный с альфой — система сама перекрасит template-образ.
MAC = {
    "disconnected": tray_svg("disconnected", stroke="#000", v="#000"),
    "connecting": tray_svg("connecting", stroke="#000", v="#000", dashed=True),
    "connected": tray_svg("connected", stroke="#000", v="transparent",
                          fill="#000"),
}

# Windows: панель задач бывает и светлой, и тёмной — берём средние тона,
# читающиеся на обеих. На 16 px пунктир превращается в кашу, поэтому
# подключение там отличается цветом, а не штрихом.
WIN = {
    "disconnected": tray_svg("disconnected", stroke="#8C8C8C", v="#8C8C8C"),
    "connecting": tray_svg("connecting", stroke="#E09B3D", v="#E09B3D"),
    "connected": tray_svg("connected", stroke="#3D63FF", v="#FFFFFF",
                          fill="#3D63FF"),
}

ICO_SIZES = [16, 20, 24, 32, 48]


def render(svg: str, size: int) -> Image.Image:
    png = cairosvg.svg2png(bytestring=svg.encode(), output_width=size,
                           output_height=size)
    return Image.open(io.BytesIO(png)).convert("RGBA")


def knock_out(img: Image.Image, size: int) -> Image.Image:
    """Вырезает V из залитой плитки: альфа = плитка × (1 − V).

    Маски SVG cairosvg в таком виде не поддерживает, поэтому считаем руками —
    сквозь вырез на macOS виден фон строки меню.
    """
    v_alpha = render(TRAY_V_ONLY, size).split()[3]
    r, g, b, a = img.split()
    cut = ImageChops.multiply(a, ImageOps.invert(v_alpha))
    return Image.merge("RGBA", (r, g, b, cut))


def main() -> None:
    (BRANDING / "verge-app-icon-light.svg").write_text(APP_LIGHT)
    (BRANDING / "verge-app-icon-dark.svg").write_text(APP_DARK)
    render(APP_LIGHT, 1024).save(BRANDING / "verge-app-icon-1024.png")
    render(APP_LIGHT, 1024).save(BRANDING / "verge-app-icon-light-1024.png")
    render(APP_DARK, 1024).save(BRANDING / "verge-app-icon-dark-1024.png")

    for state, svg in MAC.items():
        img = render(svg, 44)
        if state == "connected":
            img = knock_out(img, 44)
        img.save(TRAY / f"tray_{state}.png")
    for state, svg in WIN.items():
        # Каждый размер рендерим отдельно из вектора — даунскейл мылит линии.
        images = [render(svg, s) for s in ICO_SIZES]
        images[-1].save(
            TRAY / f"tray_{state}.ico",
            format="ICO",
            sizes=[(s, s) for s in ICO_SIZES],
            append_images=images[:-1],
        )


if __name__ == "__main__":
    main()
