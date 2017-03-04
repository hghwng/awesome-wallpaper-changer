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
local function filter_image(images, filters)
  local output = {}
  local output_idx = 0
  for image_idx, image in pairs(images) do
    -- Only allow images that pass the check
    local pass = true
    for _, filter in pairs(filters) do
      if not filter(image_idx, image) then goto fail end
    end
    output[output_idx] = image
    output_idx = output_idx + 1
    :: fail ::
  end
  return output
end

-- Ignore images whose ratio significantly differ from the screen ratio
function wp.filter_by_ratio(max_diff, geometry)
  local naughty = require("naughty")
  return function(image_idx, image)
    return math.abs(image.width / image.height - geometry.width / geometry.height) < max_diff
  end
end

-- Default strategy: set by stretching the image (because the images have been
-- filtered by ratio already)
function wp.set_maximized(s, image, image_path)
  local gears = require("gears")
  gears.wallpaper.maximized(image_path, s)
end

-- Set the image
-- settings:
--   root: (required) root directory to the wallpapers
--   filters: a series of filter functions
--   setter: a function that actually set the wallpaper
function wp.set(s, settings)
  local images = load_database(settings.root)
  local filters = settings.filters or { wp.filter_by_ratio(0.5, screen[s].geometry) }
  local setter = settings.setter or wp.set_maximized

  local filtered_images = filter_image(images, filters)
  if #filtered_images == 0 then return end
  local the_image = filtered_images[math.random(#filtered_images)]
  setter(s, the_image, settings.root .. "/" .. the_image.path)
end

math.randomseed(os.time());
return wp
