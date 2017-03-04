local awful = require("awful")

local wp = {}

-- Load wallpaper database from file
local function load_database(root)
  local index = 0
  local db = {}
  for line in io.lines(root .. "/.db") do
    db[index] = {}
    -- Timestamps are of no use here
    for timestamp, width, height, path in string.gmatch(line, "([%d]+):([%d]+):([%d]+) (.+)") do
      db[index].width = tonumber(width)
      db[index].height = tonumber(height)
      db[index].path = path
      index = index + 1
    end
  end
  return db
end

-- Filter images loaded from database
local function filter_image(imgs, filters)
  local output = {}
  local output_idx = 0
  for img_idx, img in pairs(imgs) do
    -- Only allow images that pass the check
    local pass = true
    for _, filter in pairs(filters) do
      if not filter(img_idx, img) then goto fail end
    end
    output[output_idx] = img
    output_idx = output_idx + 1
    :: fail ::
  end
  return output
end

-- Ignore images whose ratio significantly differ from the screen ratio
function wp.filter_by_ratio(max_diff, geometry)
  local naughty = require("naughty")
  return function(img_idx, img)
    return math.abs(img.width / img.height - geometry.width / geometry.height) < max_diff
  end
end

-- Default strategy: set by stretching the image (because the images have been
-- filtered by ratio already)
function wp.maximized_setter(s, img, img_path)
  local gears = require("gears")
  gears.wallpaper.maximized(img_path, s)
end

-- Set the image
-- params:
--   root: (required) root directory to the wallpapers
--   filters: a series of filter functions
--   setter: a function that actually set the wallpaper
--   update_db: whether to update the database before setting wallpapers
function wp.set(s, params)
  local do_set = function()
    local imgs = load_database(params.root)
    local filters = { wp.filter_by_ratio(0.5, screen[s].geometry) }
    if type(params.filters) == "table" then filters = params.filters end

    local filtered_imgs = filter_image(imgs, filters)
    if #filtered_imgs == 0 then return end
    local the_img = filtered_imgs[math.random(#filtered_imgs)]

    local setter = wp.maximized_setter
    if type(params.setter) == "function" then fit = params.setter end
    setter(s, the_img, params.root .. "/" .. the_img.path)
  end

  if params.update_db then
    awful.spawn.easy_async({ "./wp_update", params.root},
      { exit=function(code) do_set() end })
  else
    do_set()
  end
end

math.randomseed(os.time());
return wp
