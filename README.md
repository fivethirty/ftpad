# ftpad

A minimal menubar scratchpad for macOS.

![screenshot](screenshot.png) Press `Ctrl+Shift+Space` to show/hide. Content is saved automatically.

## Install

Requires Xcode.

```sh
git clone https://github.com/fivethirty/ftpad
cd ftpad
git checkout $(git describe --tags --abbrev=0)
sh build.sh
cp -r ftpad.app /Applications/
```

## Configuration

Create `~/.config/ftpad/config.json` to customize. All fields are optional and fall back to defaults.

```json
{
  "font": "Menlo",
  "fontSize": 14,
  "backgroundColor": "#1e1e1e",
  "textColor": "#d4d4d4",
  "lightScrollbar": true,
  "shortcut": "ctrl+shift+space",
  "width": 700,
  "height": 500
}
```

Changes are picked up automatically — no restart needed.
