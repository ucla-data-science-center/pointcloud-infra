#!/usr/bin/env python3
"""Pack a directory into a reproducible tar for upload.

Same input files produce a byte-identical archive on any machine (sorted
entries, fixed owner, no compression timestamp), so Ansible's checksum-based
copy only uploads when collection content really changed.

File mtimes come from each file's last git commit, so the directory listing's
"Last modified" column is meaningful and identical on every checkout. Files
not yet committed fall back to their filesystem mtime.

Usage: pack_content.py [--file-times] <src_dir> <dest_tar> [subdir ...]

--file-times uses filesystem mtimes and skips git entirely (for a local
Potree build, where reproducibility across machines doesn't matter).

With subdirs, only those subdirectories of src_dir are packed (used to ship
just build/ and libs/ from a local Potree checkout, skipping node_modules).

The archive includes MANIFEST.sha256 (sha256sum format) so the server can
verify an installed release with `sha256sum --check` and repair it if files
were deleted or changed.

Refuses shallow git clones: their history is truncated, so file times (and
therefore the archive bytes) would differ from a full clone's.
"""
import hashlib
import io
import os
import subprocess
import sys
import tarfile

MANIFEST = "MANIFEST.sha256"


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
    shallow = subprocess.run(
        ["git", "-C", top, "rev-parse", "--is-shallow-repository"],
        capture_output=True, text=True, check=False,
    ).stdout.strip()
    if shallow == "true":
        sys.exit(
            "pack_content.py: refusing to pack from a shallow git clone "
            "(file times would differ from a full clone). "
            "Run `git fetch --unshallow`, or use fetch-depth: 0 in CI."
        )
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
    args = sys.argv[1:]
    use_git = True
    if args and args[0] == "--file-times":
        use_git = False
        args = args[1:]
    src, dest = args[0], args[1]
    roots = [os.path.join(src, d) for d in args[2:]] or [src]
    paths = []
    for root, dirs, files in (entry for r in roots for entry in os.walk(r)):
        dirs[:] = sorted(d for d in dirs if not d.startswith("."))
        for name in sorted(files):
            if name.startswith("."):
                continue
            paths.append(os.path.join(root, name))
    times = git_mtimes(src) if use_git else {}
    tmp = dest + ".tmp"
    manifest_lines = []
    newest = 0
    with tarfile.open(tmp, "w", format=tarfile.PAX_FORMAT) as tar:
        for path in paths:
            real = os.path.realpath(path)
            mtime = times.get(real) or int(os.path.getmtime(path))
            newest = max(newest, mtime)
            arcname = os.path.relpath(path, src)
            with open(path, "rb") as fh:
                digest = hashlib.sha256(fh.read()).hexdigest()
            manifest_lines.append(f"{digest}  {arcname}\n")
            tar.add(path, arcname=arcname, recursive=False,
                    filter=lambda info, m=mtime: normalize(info, m))
        data = "".join(manifest_lines).encode()
        info = normalize(tarfile.TarInfo(MANIFEST), newest)
        info.size = len(data)
        tar.addfile(info, io.BytesIO(data))
    os.replace(tmp, dest)
    return 0


if __name__ == "__main__":
    sys.exit(main())
