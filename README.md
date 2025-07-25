# diab2gcu_prototype
```sh
$ zig build run -- 'catacombs level 1' ~/Sources/blacha_diablo2/packages/map/d2_seed42_difficulty0.json
```
, or:
```
$ zig build -Dtarget=x86-windows-gnu
$ wine cmd
> zig-out\bin\diab2gcu_prototype.exe "catacombs level 1" "L:\blacha_diablo2\packages\map\d2_seed42_difficulty0.json"
```
## ds1-to-toml
```bash
$ { echo -ne "# This content's derived from Blizzard-copyrighted, free-of-charge-redistributable Diablo II Shareware v 1.04\n\n"; zig build run -- ds1-to-toml $(cd "/full/path/to/Diablo II Shareware v 1.04"/*.mpq/extracted/data/global/tiles/ACT1/Crypt && readlink -f .; echo *.dt1 *.ds1) ; } >assets/level_presets/crypt.toml
```
