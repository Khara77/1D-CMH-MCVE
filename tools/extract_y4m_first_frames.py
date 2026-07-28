#!/usr/bin/env python3
import argparse
import binascii
import re
import struct
import zlib
from pathlib import Path


def parse_y4m_header(line):
    parts = line.decode("ascii", "replace").strip().split()
    if not parts or parts[0] != "YUV4MPEG2":
        raise ValueError("not a YUV4MPEG2 file")

    fields = {}
    for part in parts[1:]:
        fields[part[0]] = part[1:]

    width = int(fields["W"])
    height = int(fields["H"])
    chroma = fields.get("C", "420jpeg")
    return width, height, chroma


def read_first_frame(path):
    with path.open("rb") as handle:
        width, height, chroma = parse_y4m_header(handle.readline())
        frame_header = handle.readline()
        if not frame_header.startswith(b"FRAME"):
            raise ValueError("missing first frame marker")

        if not re.match(r"^420", chroma):
            raise ValueError(f"unsupported chroma format: {chroma}")

        y_size = width * height
        uv_width = (width + 1) // 2
        uv_height = (height + 1) // 2
        uv_size = uv_width * uv_height

        y_plane = handle.read(y_size)
        u_plane = handle.read(uv_size)
        v_plane = handle.read(uv_size)

    if len(y_plane) != y_size or len(u_plane) != uv_size or len(v_plane) != uv_size:
        raise ValueError("first frame is incomplete")

    return width, height, y_plane, u_plane, v_plane


def clamp(value):
    return 0 if value < 0 else 255 if value > 255 else value


def yuv420_to_rgb_rows(width, height, y_plane, u_plane, v_plane):
    uv_width = (width + 1) // 2
    rows = []

    for row in range(height):
        rgb = bytearray()
        y_offset = row * width
        uv_offset = (row // 2) * uv_width

        for col in range(width):
            y = y_plane[y_offset + col]
            u = u_plane[uv_offset + (col // 2)]
            v = v_plane[uv_offset + (col // 2)]

            c = y - 16
            d = u - 128
            e = v - 128

            r = clamp((298 * c + 409 * e + 128) >> 8)
            g = clamp((298 * c - 100 * d - 208 * e + 128) >> 8)
            b = clamp((298 * c + 516 * d + 128) >> 8)
            rgb.extend((r, g, b))

        rows.append(bytes(rgb))

    return rows


def png_chunk(kind, data):
    return (
        struct.pack(">I", len(data))
        + kind
        + data
        + struct.pack(">I", binascii.crc32(kind + data) & 0xFFFFFFFF)
    )


def write_png(path, width, height, rows):
    raw = b"".join(b"\x00" + row for row in rows)
    payload = b"\x89PNG\r\n\x1a\n"
    payload += png_chunk(b"IHDR", struct.pack(">IIBBBBB", width, height, 8, 2, 0, 0, 0))
    payload += png_chunk(b"IDAT", zlib.compress(raw, level=6))
    payload += png_chunk(b"IEND", b"")
    path.write_bytes(payload)


def convert_file(src, dst):
    width, height, y_plane, u_plane, v_plane = read_first_frame(src)
    rows = yuv420_to_rgb_rows(width, height, y_plane, u_plane, v_plane)
    write_png(dst, width, height, rows)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("input_dir", type=Path)
    parser.add_argument("output_dir", type=Path)
    args = parser.parse_args()

    args.output_dir.mkdir(parents=True, exist_ok=True)

    converted = []
    for src in sorted(args.input_dir.glob("*.y4m")):
        dst = args.output_dir / f"{src.stem}_first_frame.png"
        convert_file(src, dst)
        converted.append(dst)

    for dst in converted:
        print(dst)


if __name__ == "__main__":
    main()
