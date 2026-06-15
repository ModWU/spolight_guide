from __future__ import annotations

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
        "same_step_scroll.gif",
        [
            *[
                (f"same_step_scroll_{index:02}.png", "Same-step auto scroll")
                for index in range(1, 16)
            ],
            *[
                ("same_step_scroll_16.png", "Hint appears after scroll settles")
                for _ in range(4)
            ],
        ],
        duration=120,
    )
    build_barrier_dismiss_gif()
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
        "lazy_target_reveal.gif",
        [
            *[
                (f"lazy_target_scroll_{index:02}.png", "Lazy target reveal")
                for index in range(1, 26)
            ],
            *[
                ("lazy_target_scroll_26.png", "Hint appears after reveal settles")
                for _ in range(8)
            ],
        ],
        duration=95,
    )
    build_gif(
        "horizontal_auto.gif",
        [
            ("side_anchor_left_01.png", "Auto picks the right side"),
            ("side_anchor_right_01.png", "Auto picks the left side"),
        ],
        duration=1250,
    )
    build_gif(
        "target_decoration.gif",
        [
            ("target_decoration_01.png", "Layered border halo"),
            ("target_decoration_02.png", "Soft blurred glow"),
            ("target_decoration_03.png", "Shape-aware oval glow"),
            ("target_decoration_04.png", "Dashed outline layer"),
        ],
        duration=1300,
    )


def build_gif(name: str, frames: list[tuple[str, str]], duration: int) -> None:
    rendered = [render_frame(file_name, caption) for file_name, caption in frames]
    save_gif(name, rendered, duration)


def save_gif(name: str, rendered: list[Image.Image], duration: int) -> None:
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


def build_barrier_dismiss_gif() -> None:
    rendered = []
    rendered.extend(
        hold_frames(
            "barrier_dismiss_01.png",
            "Anytime mode: tap outside",
            count=4,
        )
    )
    rendered.extend(
        touch_frames(
            "barrier_dismiss_01.png",
            "Anytime mode: tap outside",
            x=32,
            y=760,
        )
    )
    rendered.extend(
        hold_frames(
            "barrier_dismiss_02.png",
            "Guide closes immediately",
            count=5,
        )
    )
    rendered.extend(
        hold_frames(
            "barrier_dismiss_03.png",
            "Final-only mode: first tap waits",
            count=4,
        )
    )
    rendered.extend(
        touch_frames(
            "barrier_dismiss_03.png",
            "Final-only mode: first tap waits",
            x=32,
            y=760,
        )
    )
    rendered.extend(
        hold_frames(
            "barrier_dismiss_04.png",
            "Still showing before final step",
            count=4,
        )
    )
    rendered.extend(
        hold_frames(
            "barrier_dismiss_05.png",
            "Final step: tap outside",
            count=4,
        )
    )
    rendered.extend(
        touch_frames(
            "barrier_dismiss_05.png",
            "Final step: tap outside",
            x=32,
            y=760,
        )
    )
    rendered.extend(
        hold_frames(
            "barrier_dismiss_06.png",
            "Guide closes after completion",
            count=5,
        )
    )
    save_gif("barrier_dismiss.gif", rendered, duration=130)


def hold_frames(file_name: str, caption: str, *, count: int) -> list[Image.Image]:
    return [render_frame(file_name, caption) for _ in range(count)]


def touch_frames(
    file_name: str,
    caption: str,
    *,
    x: float,
    y: float,
) -> list[Image.Image]:
    radii = [8, 16, 26, 38]
    frames = []
    for index, radius in enumerate(radii):
        frame = render_frame(file_name, caption)
        draw_touch(frame, x=x, y=y, radius=radius, opacity=180 - index * 35)
        frames.append(frame)
    return frames


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


def draw_touch(
    image: Image.Image,
    *,
    x: float,
    y: float,
    radius: int,
    opacity: int,
) -> None:
    scale = image.width / 390
    center = (x * scale, y * scale)
    overlay = Image.new("RGBA", image.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay)
    fill_color = (255, 255, 255, max(40, opacity // 5))
    stroke_color = (255, 255, 255, opacity)
    bounds = (
        center[0] - radius,
        center[1] - radius,
        center[0] + radius,
        center[1] + radius,
    )
    draw.ellipse(bounds, fill=fill_color, outline=stroke_color, width=3)
    inner_radius = 5
    draw.ellipse(
        (
            center[0] - inner_radius,
            center[1] - inner_radius,
            center[0] + inner_radius,
            center[1] + inner_radius,
        ),
        fill=(255, 255, 255, min(255, opacity + 35)),
    )
    composited = Image.alpha_composite(image.convert("RGBA"), overlay).convert("RGB")
    image.paste(composited, (0, 0))


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
