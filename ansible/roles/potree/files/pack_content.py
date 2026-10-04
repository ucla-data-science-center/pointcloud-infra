#!/usr/bin/env python3
"""Pack a directory into a reproducible tar for upload.

Same input files produce a byte-identical archive on any machine (sorted
entries, fixed owner, no compression timestamp), so Ansible's checksum-based
copy only uploads when collection content really changed.

File mtimes come from each file's last git commit, so the directory listing's
"Last modified" column is meaningful and identical on every checkout. Files
not yet committed fall back to their filesystem mtime.

Usage: pack_content.py <src_dir> <dest_tar>
"""
import os
import subprocess
import sys
import tarfile


def git_mtimes(src: str) -> dict[str, int]:
    """Map absolute path -> unix time of the last commit touching it."""
    try:
        top = subprocess.run(
            ["git", "-C", src, "rev-parse", "--show-toplevel"],
            capture_output=True, text=True, check=True,
        ).stdout.strip()
        log = subprocess.run(
            ["git", "-C", top, "log", "--format=%ct", "--name-only", "--", os.path.relpath(src, top)],
            capture_output=True, text=True, check=True,
        ).stdout
    except (OSError, subprocess.CalledProcessError):
        return {}
    times: dict[str, int] = {}
    current = 0
    for line in log.splitlines():
        if line.isdigit():
            current = int(line)
        elif line:
            times.setdefault(os.path.join(top, line), current)
    return times


def normalize(info: tarfile.TarInfo, mtime: int) -> tarfile.TarInfo:
    info.uid = info.gid = 0
    info.uname = info.gname = "root"
    info.mtime = mtime
    info.mode = 0o644
    return info


def main() -> int:
    src, dest = sys.argv[1], sys.argv[2]
    paths = []
    for root, dirs, files in os.walk(src):
        dirs[:] = sorted(d for d in dirs if not d.startswith("."))
        for name in sorted(files):
            if name.startswith("."):
                continue
            paths.append(os.path.join(root, name))
    times = git_mtimes(src)
    tmp = dest + ".tmp"
    with tarfile.open(tmp, "w", format=tarfile.PAX_FORMAT) as tar:
        for path in paths:
            real = os.path.realpath(path)
            mtime = times.get(real) or int(os.path.getmtime(path))
            tar.add(path, arcname=os.path.relpath(path, src), recursive=False,
                    filter=lambda info, m=mtime: normalize(info, m))
    os.replace(tmp, dest)
    return 0


if __name__ == "__main__":
    sys.exit(main())
