import os, subprocess, sys, tempfile
from pathlib import Path

NASM = os.environ.get('NASM', 'nasm')
HERE = Path(__file__).resolve().parent


def nasm(text):
    with tempfile.TemporaryDirectory() as t:
        src, out = Path(t, 'a.asm'), Path(t, 'a.bin')
        src.write_text(text)
        subprocess.run([NASM, '-f', 'bin', str(src), '-o', str(out)], check=True)
        return out.read_bytes()


def build(path):
    path = Path(path)
    src = path.read_text()
    bare = '\n'.join(l for l in src.splitlines() if 'times 510' not in l and '0xAA55' not in l) + '\n'
    size = len(nasm(bare))
    img = path.with_suffix('.img')
    if size <= 510:
        img.write_bytes(nasm(src))
        print(f'{path.name}: {size} bytes, {510 - size} spare')
        return
    game = bare.replace('org 0x7C00', 'org 0x600').replace('        shl esi, 16', '        mov si, 0x7DFE\n        shl esi, 16', 1)
    data = nasm((HERE / 'loader.asm').read_text()) + nasm(game)
    img.write_bytes(data + bytes(65536 - len(data)))
    print(f'{path.name}: {size} bytes, {size - 510} over, boots through loader.asm')


for p in sys.argv[1:] or [HERE / 'game.asm']:
    build(p)
