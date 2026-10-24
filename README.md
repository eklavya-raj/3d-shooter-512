# 3d-shooter-512

A 3D shooter in a boot sector. The game is 510 bytes, plus the 2 bytes the BIOS needs, so there's nothing left over.

Made it for a video on my channel: https://www.youtube.com/@CodingWalaXD

## run

```
nasm -f bin game.asm -o game.img
qemu-system-i386 -drive format=raw,file=game.img
```

or just boot the `game.img` that's already here. up arrow walks, left and right turn, space shoots. shoot all 5 before one reaches you. win or lose, it reboots into a new game.

`versions/` has the game at each step, from the first 223 byte one where the walls came out bent, to the final 510. some of them are over 510 bytes so they can't boot on their own. `python build.py versions/04-enemies-and-shooting.asm` puts `loader.asm` in front of those and makes a bigger disk image. `09-streak-bug.asm` is the one that filled the screen with vertical lines.
