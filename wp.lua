local awful = require("awful")

local function load_db(root)
  local index = 0
  local db = {}
  for line in io.lines(root .. "/.db") do
    db[index] = {}
    for timestamp, width, height, path in string.gmatch(line, "([%d]+):([%d]+):([%d]+) (.+)") do
      db[index].width = tonumber(width)
      db[index].height = tonumber(height)
      db[index].path = path
      index = index + 1
    end
  end
  return db
end

local function filter_image(imgs, filters)
  local output = {}
  local output_idx = 0
  for img_idx, img in pairs(imgs) do
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

local wp = {}

function wp.filter_by_ratio(max_diff, geometry)
  local naughty = require("naughty")
  return function(img_idx, img)
    naughty.notify({text = string.format("%dx%d(%f) %dx%d(%f) %f",
                        img.width, img.height, img.width / img.height,
                        geometry.width, geometry.height, geometry.width / geometry.height,
                        img.width / img.height - geometry.width / geometry.height)
    })
      return math.abs(img.width / img.height - geometry.width / geometry.height) < max_diff
  end
end

function wp.fit_image(s, img, img_path)
  local gears = require("gears")
  gears.wallpaper.maximized(img_path, s)
end

function wp.set(s, params)
  local do_set = function()
    local imgs = load_db(params.root)
    local filters = { wp.filter_by_ratio(0.5, screen[s].geometry) }
    if type(params.filters) == "table" then filters = params.filters end

    local filtered_imgs = filter_image(imgs, filters)
    if #filtered_imgs == 0 then return end
    local the_img = filtered_imgs[math.random(#filtered_imgs)]

    local fit = wp.fit_image
    if type(params.fit) == "function" then fit = params.fit end
    fit(s, the_img, params.root .. "/" .. the_img.path)
  end

  if params.update_db then
    awful.spawn.easy_async({ "./wp_update", params.root},
      { exit=function(code) do_set() end })
  else
    do_set()
  end
end

return wp
