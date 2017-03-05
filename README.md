# Awesome Wallpaper Changer

## Description

Awesome Wallpaper Changer is a better replacement of `gears.wallpaper` in [awesomewm](https://awesomewm.org/). It's provides a filtering mechanism for easy customization of the wallpaper-picking process.

It's especially suitable for a setup with a vertical monitor which you plug and unplug from your laptop frequently.

## Feature

- Randomly pick wallpaper from your wallpaper directory
- Recognize screen aspect ratio and choose wallpapers that fit the screen
- Configurable behavior: 

## Configuration
Clone the repository to your configuration path.

```sh
cd ~/.config/awesome
git clone https://github.com/hghwng/awesome-wallpaper-changer -o wp
````

And add the configuration to `rc.lua`

```lua
local wp = require("wp/wp")
wp_config = { root = "PATH_TO_YOUR_WALLPAPERS" }
awful.spawn({awful.util.get_configuration_dir() .. "wp/wp_update", wp_config.root })
local set_wallpaper = function(s)
  wp.set_one(s, wp_config)
end
```
