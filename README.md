# diab2gcu_prototype
```
$ zig build run -- 'catacombs level 1' ~/Sources/blacha_diablo2/packages/map/d2_seed42_difficulty0.json
```
, or:
```
$ zig build -Dtarget=x86-windows-gnu
$ wine cmd
> zig-out\bin\diab2gcu_prototype.exe "catacombs level 1" "L:\blacha_diablo2\packages\map\d2_seed42_difficulty0.json"
```
