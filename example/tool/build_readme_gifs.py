from __future__ import annotations

import shutil
import subprocess
import tempfile
from dataclasses import dataclass
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parents[2]
IMAGE_DIR = ROOT / "doc" / "images" / "readme"
DEVICE_FRAME_DIR = IMAGE_DIR / "device_frames"


@dataclass(frozen=True)
class Frame:
    file_name: str
    caption: str
    touch: tuple[float, float, int, int] | None = None


@dataclass(frozen=True)
class GifSpec:
    output_name: str
    source_dir: Path
    frames: list[Frame]
    duration_ms: int


def main() -> None:
    IMAGE_DIR.mkdir(parents=True, exist_ok=True)
    for spec in gif_specs():
        (IMAGE_DIR / spec.output_name).unlink(missing_ok=True)
        build_gif(spec)


def gif_specs() -> list[GifSpec]:
    return [
        GifSpec(
            "basic_flow.gif",
            DEVICE_FRAME_DIR,
            [
                Frame("device_basic_01.png", "Highlight a visible target"),
                Frame("device_basic_02.png", "Advance to the next step"),
            ],
            duration_ms=1150,
        ),
        GifSpec(
            "pointer_hint.gif",
            DEVICE_FRAME_DIR,
            [
                *hold(
                    "device_pointer_hint_01.png",
                    "Pointer, bubble and target chain",
                    4,
                ),
                *hold(
                    "device_pointer_hint_02.png",
                    "Pointer follows the resolved side",
                    4,
                ),
                *hold(
                    "device_pointer_hint_03.png",
                    "Use any widget as a pointer",
                    4,
                ),
                *hold(
                    "device_pointer_hint_04.png",
                    "Move the bubble anchor on the pointer",
                    4,
                ),
                *hold(
                    "device_pointer_hint_05.png",
                    "Auto side adapts to available space",
                    4,
                ),
                *hold(
                    "device_pointer_hint_06.png",
                    "Decorative pointer, target anchor",
                    4,
                ),
            ],
            duration_ms=210,
        ),
        GifSpec(
            "same_step_hints.gif",
            DEVICE_FRAME_DIR,
            [
                *hold(
                    "device_same_step_hints_01.png",
                    "Several hints in one step",
                    5,
                ),
                *touch_frames(
                    "device_same_step_hints_01.png",
                    "All hints share one step",
                    x=34,
                    y=820,
                ),
                *hold(
                    "device_same_step_hints_01.png",
                    "Use targetIds or multiple items",
                    4,
                ),
            ],
            duration_ms=120,
        ),
        GifSpec(
            "custom_anchors.gif",
            DEVICE_FRAME_DIR,
            [
                *hold("device_anchor_group_01.png", "Large repeated target group", 3),
                *hold("device_anchor_group_02.png", "Custom droplet anchor", 3),
                *hold("device_anchor_group_03.png", "Switch to a curved arrow", 3),
                *hold("device_anchor_group_04.png", "Switch to a sharp arrow", 3),
                *hold("device_anchor_group_05.png", "No visible anchor option", 3),
            ],
            duration_ms=260,
        ),
        GifSpec(
            "target_decoration.gif",
            DEVICE_FRAME_DIR,
            [
                *hold("device_target_decoration_01.png", "Layered border halo", 4),
                *hold("device_target_decoration_02.png", "Soft blurred glow", 4),
                *hold("device_target_decoration_03.png", "Shape-aware oval glow", 4),
                *hold("device_target_decoration_04.png", "Dashed outline layer", 4),
            ],
            duration_ms=230,
        ),
        GifSpec(
            "dynamic_steps.gif",
            DEVICE_FRAME_DIR,
            [
                *hold("device_dynamic_steps_01.png", "Runtime step 1", 4),
                *hold("device_dynamic_steps_02.png", "Optional target step", 4),
            ],
            duration_ms=260,
        ),
        GifSpec(
            "same_step_scroll.gif",
            DEVICE_FRAME_DIR,
            [
                *[
                    Frame(
                        f"device_same_step_scroll_{index:02}.png",
                        "Same-step auto-scroll",
                    )
                    for index in range(1, 114)
                ],
                *hold(
                    "device_same_step_scroll_113.png",
                    "Hint appears after scroll settles",
                    20,
                ),
            ],
            duration_ms=17,
        ),
        GifSpec(
            "lazy_target_reveal.gif",
            DEVICE_FRAME_DIR,
            [
                *[
                    Frame(
                        f"device_lazy_target_scroll_{index:02}.png",
                        "Lazy target reveal",
                    )
                    for index in range(1, 92)
                ],
                *hold(
                    "device_lazy_target_scroll_91.png",
                    "Nested target appears after reveal",
                    20,
                ),
            ],
            duration_ms=17,
        ),
        GifSpec(
            "barrier_dismiss.gif",
            DEVICE_FRAME_DIR,
            barrier_frames("device_barrier_dismiss", touch_y=820),
            duration_ms=120,
        ),
        GifSpec(
            "controller_api.gif",
            DEVICE_FRAME_DIR,
            [
                *hold("device_controller_01.png", "External controller API", 5),
                *touch_frames(
                    "device_controller_01.png",
                    "Drive the guide from buttons",
                    x=315,
                    y=760,
                ),
                *hold("device_controller_01.png", "showPortal and showSteps", 4),
            ],
            duration_ms=120,
        ),
        GifSpec(
            "horizontal_auto.gif",
            DEVICE_FRAME_DIR,
            [
                *hold("device_side_anchor_left_01.png", "Auto picks the right side", 4),
                *hold("device_side_anchor_right_01.png", "Auto picks the left side", 4),
            ],
            duration_ms=260,
        ),
    ]


def hold(file_name: str, caption: str, count: int) -> list[Frame]:
    return [Frame(file_name, caption) for _ in range(count)]


def barrier_frames(prefix: str, touch_y: float = 760) -> list[Frame]:
    return [
        *hold(f"{prefix}_01.png", "Anytime mode: tap outside", 4),
        *touch_frames(f"{prefix}_01.png", "Anytime mode: tap outside", x=32, y=touch_y),
        *hold(f"{prefix}_02.png", "Guide closes immediately", 5),
        *hold(f"{prefix}_03.png", "Final-only mode: first tap waits", 4),
        *touch_frames(
            f"{prefix}_03.png",
            "Final-only mode: first tap waits",
            x=32,
            y=touch_y,
        ),
        *hold(f"{prefix}_04.png", "Still showing before final step", 4),
        *hold(f"{prefix}_05.png", "Final step: tap outside", 4),
        *touch_frames(f"{prefix}_05.png", "Final step: tap outside", x=32, y=touch_y),
        *hold(f"{prefix}_06.png", "Guide closes after completion", 5),
    ]


def touch_frames(file_name: str, caption: str, *, x: float, y: float) -> list[Frame]:
    radii = [8, 16, 26, 38]
    return [
        Frame(file_name, caption, touch=(x, y, radius, 180 - index * 35))
        for index, radius in enumerate(radii)
    ]


def build_gif(spec: GifSpec) -> None:
    with tempfile.TemporaryDirectory(prefix="spotlight_readme_gif_") as temp_dir:
        rendered_paths = []
        for index, frame in enumerate(spec.frames):
            image = render_frame(spec.source_dir, frame)
            frame_path = Path(temp_dir) / f"{index:04}.png"
            image.save(frame_path)
            rendered_paths.append(frame_path)

        output = IMAGE_DIR / spec.output_name
        if shutil.which("gifski"):
            run_gifski(rendered_paths, output, spec.duration_ms)
        else:
            save_with_pillow(rendered_paths, output, spec.duration_ms)
    print(f"wrote {output.relative_to(ROOT)}")


def run_gifski(paths: list[Path], output: Path, duration_ms: int) -> None:
    fps = max(1, round(1000 / duration_ms))
    subprocess.run(
        [
            "gifski",
            "--quiet",
            "--fps",
            str(fps),
            "--quality",
            "86",
            "--output",
            str(output),
            *[str(path) for path in paths],
        ],
        check=True,
    )


def save_with_pillow(paths: list[Path], output: Path, duration_ms: int) -> None:
    images = [Image.open(path).convert("P", palette=Image.Palette.ADAPTIVE) for path in paths]
    images[0].save(
        output,
        save_all=True,
        append_images=images[1:],
        duration=duration_ms,
        loop=0,
        optimize=True,
    )


def render_frame(source_dir: Path, frame: Frame) -> Image.Image:
    source_path = source_dir / frame.file_name
    if not source_path.exists():
        raise FileNotFoundError(source_path.relative_to(ROOT))

    source = Image.open(source_path).convert("RGB")
    width = 312
    height = round(source.height * width / source.width)
    image = source.resize((width, height), Image.Resampling.LANCZOS)
    draw_caption(image, frame.caption)
    if frame.touch is not None:
        x, y, radius, opacity = frame.touch
        logical_width = source.width / 3 if source.width > 800 else source.width
        draw_touch(
            image,
            x=x,
            y=y,
            radius=radius,
            opacity=opacity,
            logical_width=logical_width,
        )
    return image


def draw_caption(image: Image.Image, caption: str) -> None:
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


def draw_touch(
    image: Image.Image,
    *,
    x: float,
    y: float,
    radius: int,
    opacity: int,
    logical_width: float,
) -> None:
    scale = image.width / logical_width
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
        fill=(255, 255, 255, min(255, opacity + 25)),
    )
    image.alpha_composite(overlay) if image.mode == "RGBA" else image.paste(
        Image.alpha_composite(image.convert("RGBA"), overlay).convert("RGB")
    )


def load_font(size: int) -> ImageFont.FreeTypeFont | ImageFont.ImageFont:
    candidates = [
        Path("/System/Library/Fonts/Supplemental/Arial.ttf"),
        Path("/Library/Fonts/Arial.ttf"),
        Path("/System/Library/Fonts/Helvetica.ttc"),
    ]
    for path in candidates:
        if path.exists():
            try:
                return ImageFont.truetype(str(path), size)
            except OSError:
                continue
    return ImageFont.load_default()


if __name__ == "__main__":
    main()
