from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parents[2]
IMAGE_DIR = ROOT / "doc" / "images" / "readme"
FRAME_DIR = IMAGE_DIR / "frames"


def main() -> None:
    IMAGE_DIR.mkdir(parents=True, exist_ok=True)
    build_gif(
        "basic_flow.gif",
        [
            ("basic_01.png", "Highlight a visible target"),
            ("basic_02.png", "Advance to the next step"),
        ],
        duration=1350,
    )
    build_gif(
        "scroll_and_reveal.gif",
        [
            ("same_step_scroll_01.png", "Same-step visible target"),
            ("same_step_scroll_02.png", "Auto-scroll to offscreen target"),
            ("same_step_scroll_03.png", "Show hint after scroll settles"),
            ("lazy_target_01.png", "Reveal a lazy-list target"),
        ],
        duration=1050,
    )
    build_gif(
        "barrier_dismiss.gif",
        [
            ("barrier_dismiss_01.png", "Outside tap dismiss modes"),
        ],
        duration=1500,
    )
    build_gif(
        "custom_anchors.gif",
        [
            ("anchor_group_01.png", "Large repeated target group"),
            ("anchor_group_02.png", "Custom droplet anchor"),
            ("anchor_group_03.png", "Switch to a curved arrow"),
            ("anchor_group_04.png", "Switch to a sharp arrow"),
            ("anchor_group_05.png", "No visible anchor option"),
        ],
        duration=1400,
    )
    build_gif(
        "horizontal_auto_left.gif",
        [
            ("side_anchor_left_01.png", "Auto picks the right side"),
        ],
        duration=1500,
    )
    build_gif(
        "horizontal_auto_right.gif",
        [
            ("side_anchor_right_01.png", "Auto picks the left side"),
        ],
        duration=1500,
    )


def build_gif(name: str, frames: list[tuple[str, str]], duration: int) -> None:
    rendered = [render_frame(file_name, caption) for file_name, caption in frames]
    output = IMAGE_DIR / name
    rendered[0].save(
        output,
        save_all=True,
        append_images=rendered[1:],
        duration=duration,
        loop=0,
        optimize=True,
    )
    print(f"wrote {output.relative_to(ROOT)}")


def render_frame(file_name: str, caption: str) -> Image.Image:
    source = Image.open(FRAME_DIR / file_name).convert("RGB")
    width = 312
    height = round(source.height * width / source.width)
    image = source.resize((width, height), Image.Resampling.LANCZOS)
    draw = ImageDraw.Draw(image)
    font = load_font(16)
    text_color = (255, 255, 255)
    overlay_color = (0, 0, 0)
    padding_x = 12
    padding_y = 10
    text_box = draw.textbbox((0, 0), caption, font=font)
    text_height = text_box[3] - text_box[1]
    bar_height = text_height + padding_y * 2
    draw.rounded_rectangle(
        (8, image.height - bar_height - 8, image.width - 8, image.height - 8),
        radius=10,
        fill=overlay_color,
    )
    draw.text(
        (padding_x + 8, image.height - bar_height - 8 + padding_y),
        caption,
        fill=text_color,
        font=font,
    )
    return image


def load_font(size: int) -> ImageFont.FreeTypeFont | ImageFont.ImageFont:
    candidates = [
        "/Users/wikiglobal/opt/last_flutter/bin/cache/artifacts/material_fonts/Roboto-Bold.ttf",
        "/System/Library/Fonts/Supplemental/Arial Bold.ttf",
    ]
    for path in candidates:
        if Path(path).exists():
            return ImageFont.truetype(path, size)
    return ImageFont.load_default()


if __name__ == "__main__":
    main()
