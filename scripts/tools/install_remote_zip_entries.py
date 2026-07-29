#!/usr/bin/env python3
"""Install selected files from a remote ZIP without downloading the full archive.

The server must support HTTP byte ranges. Each extracted entry is CRC-checked before
it replaces the destination, so an interrupted download cannot leave a valid-looking
but incomplete export template behind.
"""

from __future__ import annotations

import argparse
import binascii
import os
from pathlib import Path
import struct
import tempfile
import time
import urllib.request
import zlib


EOCD_SIGNATURE = b"PK\x05\x06"
CENTRAL_SIGNATURE = b"PK\x01\x02"
LOCAL_SIGNATURE = b"PK\x03\x04"
TAIL_BYTES = 1024 * 1024
CHUNK_BYTES = 1024 * 1024
REQUEST_TIMEOUT_SECONDS = 60
REQUEST_ATTEMPTS = 3


def open_with_retry(request: urllib.request.Request):
    last_error: Exception | None = None
    for attempt in range(REQUEST_ATTEMPTS):
        try:
            return urllib.request.urlopen(request, timeout=REQUEST_TIMEOUT_SECONDS)
        except Exception as error:
            last_error = error
            if attempt + 1 < REQUEST_ATTEMPTS:
                time.sleep(2**attempt)
    raise RuntimeError(f"HTTP request failed after {REQUEST_ATTEMPTS} attempts") from last_error


def request_range(url: str, start: int, end: int) -> bytes:
    request = urllib.request.Request(
        url,
        headers={"Range": f"bytes={start}-{end}", "User-Agent": "LabEngineTemplateInstaller/1.0"},
    )
    with open_with_retry(request) as response:
        if response.status != 206:
            raise RuntimeError(f"Server ignored byte range {start}-{end}: HTTP {response.status}")
        return response.read()


def remote_size(url: str) -> int:
    request = urllib.request.Request(url, method="HEAD", headers={"User-Agent": "LabEngineTemplateInstaller/1.0"})
    with open_with_retry(request) as response:
        size = response.headers.get("Content-Length")
        if not size:
            raise RuntimeError("Remote archive did not provide Content-Length")
        return int(size)


def read_directory(url: str, archive_size: int) -> dict[str, tuple[int, int, int, int]]:
    tail_start = max(0, archive_size - TAIL_BYTES)
    tail = request_range(url, tail_start, archive_size - 1)
    eocd_at = tail.rfind(EOCD_SIGNATURE)
    if eocd_at < 0:
        raise RuntimeError("ZIP end-of-central-directory record was not found")
    _, _, _, _, entry_count, central_size, central_offset, _ = struct.unpack_from(
        "<4s4H2LH", tail, eocd_at
    )
    if entry_count == 0xFFFF or central_size == 0xFFFFFFFF or central_offset == 0xFFFFFFFF:
        raise RuntimeError("ZIP64 archives are not supported by this focused installer")

    central = request_range(url, central_offset, central_offset + central_size - 1)
    entries: dict[str, tuple[int, int, int, int]] = {}
    cursor = 0
    for _ in range(entry_count):
        if central[cursor : cursor + 4] != CENTRAL_SIGNATURE:
            raise RuntimeError(f"Invalid central directory entry at byte {cursor}")
        fields = struct.unpack_from("<4s6H3L5H2L", central, cursor)
        compression = fields[4]
        crc32 = fields[7]
        compressed_size = fields[8]
        uncompressed_size = fields[9]
        name_size, extra_size, comment_size = fields[10:13]
        local_offset = fields[16]
        name_start = cursor + 46
        name = central[name_start : name_start + name_size].decode("utf-8")
        entries[name] = (local_offset, compression, compressed_size, crc32)
        cursor = name_start + name_size + extra_size + comment_size
    return entries


def extract_entry(url: str, entry: tuple[int, int, int, int], destination: Path) -> None:
    local_offset, compression, compressed_size, expected_crc = entry
    header = request_range(url, local_offset, local_offset + 29)
    if header[:4] != LOCAL_SIGNATURE:
        raise RuntimeError(f"Invalid local ZIP header at byte {local_offset}")
    fields = struct.unpack("<4s5H3L2H", header)
    name_size, extra_size = fields[-2:]
    data_start = local_offset + 30 + name_size + extra_size
    decompressor = zlib.decompressobj(-zlib.MAX_WBITS) if compression == 8 else None
    if compression not in (0, 8):
        raise RuntimeError(f"Unsupported ZIP compression method: {compression}")

    destination.parent.mkdir(parents=True, exist_ok=True)
    crc = 0
    with tempfile.NamedTemporaryFile(dir=destination.parent, delete=False) as temporary:
        temporary_path = Path(temporary.name)
        remaining = compressed_size
        cursor = data_start
        while remaining:
            amount = min(CHUNK_BYTES, remaining)
            block = request_range(url, cursor, cursor + amount - 1)
            output = decompressor.decompress(block) if decompressor else block
            temporary.write(output)
            crc = binascii.crc32(output, crc)
            cursor += amount
            remaining -= amount
        if decompressor:
            output = decompressor.flush()
            temporary.write(output)
            crc = binascii.crc32(output, crc)

    if crc & 0xFFFFFFFF != expected_crc:
        temporary_path.unlink(missing_ok=True)
        raise RuntimeError(f"CRC mismatch for {destination.name}")
    os.replace(temporary_path, destination)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("url")
    parser.add_argument("destination", type=Path)
    parser.add_argument("entries", nargs="+")
    arguments = parser.parse_args()

    size = remote_size(arguments.url)
    directory = read_directory(arguments.url, size)
    for requested in arguments.entries:
        matches = [name for name in directory if name == requested or name.endswith("/" + requested)]
        if len(matches) != 1:
            candidates = [name for name in directory if Path(name).name == Path(requested).name]
            raise RuntimeError(f"Expected one match for {requested}, found {matches or candidates}")
        source_name = matches[0]
        target = arguments.destination / Path(requested).name
        print(f"Installing {source_name} -> {target}", flush=True)
        extract_entry(arguments.url, directory[source_name], target)
        print(f"Installed {target.stat().st_size} bytes", flush=True)


if __name__ == "__main__":
    main()
