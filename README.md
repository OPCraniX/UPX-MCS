# UPX-MCS

UPX-MCS is a Windows batch utility for aggressively compressing `.exe` files with [UPX](https://upx.github.io/).

It remembers your UPX executable path, keeps a rolling history of the last 5 executables you compressed, and preserves an uncompressed backup beside the original file before packing.

## What It Does

- Prompts for `upx.exe` the first time you run it, then saves that path for future runs.
- Lets you pick from the 5 most recently compressed executables or enter a new path.
- Renames the original file to `*-uncompressed.exe`.
- Copies the backup back to the original filename.
- Runs UPX using:
  - `--best`
  - `--lzma`
  - `--ultra-brute`
  - `--compress-exports=1`
  - `--strip-relocs=1`
  - `--overlay=copy`
  - `--force`

## Files

- `compress.bat`
  - Main compression script.
- `upx_path.txt`
  - Stores the last valid path to `upx.exe`.
- `packed_history.txt`
  - Stores the 5 most recent executable paths.
- `UPX-MCS-help.txt`
  - Plain-text quick help.

## Requirements

- Windows
- [UPX](https://github.com/upx/upx/releases)
- Permission to rename and copy the target executable

## How To Use

1. Run `compress.bat`.
2. If prompted, enter the full path to `upx.exe`.
3. Choose a recent executable from the menu or press `N` to enter a new one.
4. Wait for the script to create the `-uncompressed` backup and compress the original filename.

## Output Behavior

If you compress:

`C:\Apps\Tool.exe`

the script will:

- Rename it to `C:\Apps\Tool-uncompressed.exe`
- Recreate `C:\Apps\Tool.exe`
- Compress the recreated `Tool.exe`

## Notes

- The history list shows only the most recent 5 entries.
- Recompressing a file moves it to the newest position in history instead of duplicating it.
- `upx_path.txt` and `packed_history.txt` are machine-specific runtime files and are ignored by git.
- Always test your packed executable after compression. Some executables do not behave correctly after aggressive UPX settings.
