local awful = require("awful")

local wp = {}

-- Load wallpaper database from file
local function load_database(root)
  local index = 1
  local db = {}
  local lines
  if pcall(function() lines = io.lines(root .. "/.db") end) then
    for line in lines do
      -- Timestamps are of no use here
      for timestamp, width, height, path in string.gmatch(line, "([%d]+):([%d]+):([%d]+) (.+)") do
        db[index] = {}
        db[index].width = tonumber(width)
        db[index].height = tonumber(height)
        db[index].path = path
        index = index + 1
      end
    end
    return db
  else
    local naughty = require("naughty")
    naughty.notify({title = "Wallpaper database error", text = "Cannot load database from " .. root .. "\n Maybe you should rebuild the database"} )
    return {}
  end
end

-- Filter images loaded from database
local function filter_image(s, images, filters)
  local output = {}
  local output_idx = 1
  for image_idx, image in pairs(images) do
    -- Only allow images that pass the check
    local pass = true
    for _, filter in pairs(filters) do
      if not filter(s, image_idx, image) then goto fail end
    end
    output[output_idx] = image
    output_idx = output_idx + 1
    :: fail ::
  end
  return output
end

-- Filter the images, and set the image as wallpaper
local function do_set(s, images, filter, setter, root)
  local filtered_images = filter_image(s, images, filters)
  if #filtered_images == 0 then return end
  local the_image = filtered_images[math.random(#filtered_images)]
  setter(s, the_image, root .. "/" .. the_image.path)
end

-- Prepare the database, filters and setter for given settings
-- settings:
--   root: (required) root directory to the wallpapers
--   filters: a series of filter functions
--   setter: a function that actually set the wallpaper
local function prepare(settings)
  local images = load_database(settings.root)
  local filters = settings.filters or { wp.filter_by_ratio(0.8) }
  local setter = settings.setter or wp.set_maximized
  return images, filters, setter
end

-- Ignore images whose ratio significantly differ from the screen ratio
-- max_factor <= 1: When the image is fitted to the max size to the screen, how
-- much space is allowed to be blank
function wp.filter_by_ratio(min_factor)
  local naughty = require("naughty")
  return function(s, image_idx, image)
    local geometry = screen[s].geometry
    local fit_width_factor = geometry.width / image.width * image.height / geometry.height
    local fit_height_factor = geometry.height / image.height * image.width / geometry.width
    local fit_factor = math.min(fit_width_factor, fit_height_factor)
    return fit_factor > min_factor
  end
end

-- Default strategy: set by stretching the image (because the images have been
-- filtered by ratio already)
function wp.set_maximized(s, image, image_path)
  local gears = require("gears")
  gears.wallpaper.maximized(image_path, s)
end

-- Set wallpaper for one given screen
function wp.set_one(s, settings)
  images, filters, setter = prepare(settings)
  do_set(s, images, filters, setter, settings.root)
end

-- Set wallpaper for all screens
function wp.set_all(settings)
  images, filters, setter = prepare(settings)
  for s = 1, screen.count() do
    do_set(s, images, filters, setter, settings.root)
  end
end

math.randomseed(os.time());
return wp
