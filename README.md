# Hand Mirror for DankMaterialShell

A cozy camera preview and microphone check widget for DankMaterialShell (DMS). Inspired by the macOS "Hand Mirror" app.

## Features

- **Cozy Camera Preview**: One-click camera check directly from the DankBar status pill.
- **Draggable & Resizable**: Drag the window anywhere on your Wayland workspace or double-click to center it.
- **Polaroid Snaps**: Capture frames as Polaroid-style cards, annotate/draw over them with a stylus/mouse, and save them directly to `~/Pictures/Snaps/`.
- **Mic Check**: Real-time microphone input level indicator on the side of the mirror window.
- **Visual Options**: Configurable digital zoom, border radius, window sizes, and spawn positions (Center, Top-Right, Top-Left, Bottom-Right, Bottom-Left).

## Installation

1. Copy or symlink this directory into your DMS plugins folder:
   ```bash
   ln -s /path/to/dms-hand-mirror ~/.config/DankMaterialShell/plugins/HandMirror
   ```
2. Run `dms restart` to reload the shell.
3. Open DMS Settings > Plugins, scan/enable **Hand Mirror**, and add it to your bar layout.

## License

MIT
