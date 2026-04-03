# vivaldi-peek

**Auto-collapsing vertical tabs for [Vivaldi](https://vivaldi.com).** Your tab bar hides when you're not using it and peeks back on hover — giving you a full-width browsing experience without losing quick tab access.

![peek-demo](https://github.com/user-attachments/assets/placeholder-replace-with-actual-gif)

## What it does

- Vertical tab bar slides off-screen when not in use, leaving a tiny 3px hover strip
- Hover near the edge to smoothly slide it back in (0.2s animation)
- Stays visible during tab drags and workspace popups
- Works with tabs on left **or** right side
- Compatible with Vivaldi workspaces

## Why this approach

Older Vivaldi CSS mods required editing files inside `Program Files\Vivaldi\Application\<version>\...` — which got **wiped on every update**. This repo uses Vivaldi's modern CSS injection system that stores everything in your User Data profile. Updates don't touch it.

## Quick install

Close Vivaldi first, then:

### Windows (PowerShell)

```powershell
git clone https://github.com/xpltdco/vivaldi-peek.git
cd vivaldi-peek
.\install.ps1
```

### macOS / Linux

```bash
git clone https://github.com/xpltdco/vivaldi-peek.git
cd vivaldi-peek
chmod +x install.sh
./install.sh
```

> **Note (macOS/Linux):** Requires [`jq`](https://jqlang.github.io/jq/) — install with `brew install jq` or `sudo apt install jq`.

Then open Vivaldi. That's it.

## What the installer does

1. **Copies** the CSS files to `<Vivaldi User Data>/vivaldi-peek-css/`
2. **Backs up** your current Preferences file (as `Preferences.vivaldi-peek-backup`)
3. **Enables** the "Allow CSS modifications" experiment flag (`vivaldi.features.css_mods`)
4. **Sets** the custom CSS directory path (`vivaldi.appearance.css_ui_mods_directory`)

All changes are in your Vivaldi **User Data** directory — never in the application folder — so they survive updates.

## Prerequisite: vertical tabs

If you haven't already, set your tab bar to vertical:

1. Open Vivaldi Settings (`Ctrl+F12` / `Cmd+,`)
2. Go to **Tabs** > **Tab Bar Position**
3. Select **Left** or **Right**

<details>
<summary>Screenshot: Tab Bar Position setting</summary>

```
Settings > Tabs > Tab Bar Position
  ○ Top
  ● Left    ← select this
  ○ Right
  ○ Bottom
```

</details>

## Customization

Edit `css/custom.css` and tweak the variables at the top:

```css
:root {
  /* How fast the tab bar slides in/out */
  --tabbar-transition: transform .2s ease-out, opacity .2s ease-out;

  /* Thin strip visible when tabs are hidden (hover target) */
  --tabbar-peek-width: 3px;
}
```

| Variable | What it controls | Default |
|----------|-----------------|---------|
| `--tabbar-transition` | Slide animation speed and easing | `0.2s ease-out` |
| `--tabbar-peek-width` | Width of the visible hover strip (px) | `3px` |
| `--scrollbar-width` | Tab list scrollbar width | `10px` |

After editing, re-run the installer to deploy the updated CSS, then restart Vivaldi.

## Uninstall

### Windows

```powershell
.\install.ps1 -Uninstall
```

### macOS / Linux

```bash
./install.sh --uninstall
```

This removes the CSS folder and reverts the Preferences changes. Restart Vivaldi after.

## How it works (for the curious)

Vivaldi's UI is built with web technologies (HTML/CSS/JS). Since version ~2.9, Vivaldi has an experimental feature that injects user CSS files into the browser chrome. The flow:

1. `vivaldi://experiments` has a flag called **"Allow CSS modifications"** — we enable this via `vivaldi.features.css_mods = true` in Preferences
2. `vivaldi://settings/appearance/` has a **Custom UI Modifications** folder picker — we set this via `vivaldi.appearance.css_ui_mods_directory` in Preferences
3. Vivaldi loads all `*.css` files from that folder and injects them into the browser UI
4. Our CSS uses `position: absolute` + `transform: translateX(...)` to slide the `.tabbar-wrapper` off-screen, with `:hover` rules to bring it back

Because the CSS folder and Preferences live in **User Data** (not the versioned Application folder), nothing is overwritten during updates.

## Troubleshooting

**Tabs aren't hiding after install**
- Make sure Vivaldi was fully closed before running the installer
- Verify your tabs are set to Left or Right position (not Top/Bottom)
- Try restarting Vivaldi

**Want to verify it's working**
- Open `vivaldi://experiments` — "Allow CSS modifications" should be checked
- Open `vivaldi://settings/appearance/` — "Custom UI Modifications" should show the CSS folder path

**CSS changes aren't showing up**
- Re-run the installer after editing CSS to copy the updated files
- Restart Vivaldi (or press `Ctrl+Shift+F5` to reload the UI without restarting)

## Credits

CSS based on [Felvesthe's Arc-like auto-hide gist](https://gist.github.com/Felvesthe/8a13560ed3135ab1fbec2b06a18402da) with modifications for robustness.

## License

MIT
