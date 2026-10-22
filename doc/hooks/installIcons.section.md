# `installIcons` {#installicons}

This hook installs icons into the hicolor icon theme, in the directory that matches the size of each icon.

## Install the icons of an application {#installicons-usage}

:::{.example #ex-installicons-usage}

# Install PNG icons of several sizes and an SVG icon

```nix
{
  nativeBuildInputs = [ installIcons ];

  postInstall = ''
    installIcon --name foobar icons/foobar-*.png icons/foobar.svg
  '';
}
```

:::

Each PNG icon goes into the directory for its size, such as `share/icons/hicolor/48x48/apps/foobar.png`, and the SVG icon goes into `share/icons/hicolor/scalable/apps/foobar.svg`.
The hook reads the size from each PNG file, so the icons need no loop over sizes.
It does not resize icons, because icon lookups scale the closest size they find.

## Install icons for high pixel densities {#installicons-scale}

:::{.example #ex-installicons-scale}

# Install a 1024x1024 icon

```nix
{
  nativeBuildInputs = [ installIcons ];

  postInstall = ''
    installIcon --name foobar --scale 2 foobar-1024.png
  '';
}
```

:::

The hicolor theme has no `1024x1024` directory, so icon lookups never find icons installed there.
With `--scale 2`, the icon goes into `512x512@2`, the directory for 512x512 icons at twice the pixel density.

## Reference {#installicons-reference}

### `installIcon` {#installicons-installicon}

```
installIcon [--name <name>] [--context <context>] [--scale <scale>] [--] <file>...
```

Installs PNG and SVG icons into `share/icons/hicolor` in [`$outputBin`](#outputbin).
Options also take the form `--<option>=<value>`, such as `--name=foobar`.

`--name <name>`
:   Name of the icon, without an extension, for all the files.
    Desktop entries, such as those made with [`makeDesktopItem`](#trivial-builder-makeDesktopItem), refer to the icon by this name.
    Defaults to the name of each file without its extension.

`--context <context>`
:   Context directory of the icons, such as `apps`, `mimetypes` or `status`.
    Defaults to `apps`.

`--scale <scale>`
:   Scale of the PNG icons.
    An icon of `<pixels>` by `<pixels>` goes into the directory for icons of `<pixels> / <scale>` at that scale.
    SVG icons accept only the default scale, because the hicolor theme has no scaled directories for them.
    Defaults to `1`.

The build fails if:

- a file does not exist, or is not a PNG or SVG file,
- the icon name, from `--name` or from a file name without its extension, is empty, contains a directory or an extension, or starts with a dot,
- a PNG icon is not square, or its size is not a multiple of the scale,
- `--scale` is greater than `1` for an SVG icon,
- the hicolor theme has no directory for the context, or for the size and scale of an icon,
- an icon of the same name is already installed in that directory.
