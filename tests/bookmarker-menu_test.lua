-- Run: lua tests/bookmarker-menu_test.lua  (from the repo, or ~/.config/mpv)
-- Checks that bookmarks still work after the video file was moved to a new folder.
local props = { path = "/new/dir/xyz.mp4", filename = "xyz.mp4", ["time-pos"] = 0 }
local seeks, loads = {}, {}
mp = {
  get_property = function(k) return props[k] or "" end,
  get_property_number = function(k, d) return props[k] or d end,
  set_property_number = function(k, v) if k == "time-pos" then table.insert(seeks, v) end end,
  commandv = function(...) table.insert(loads, { ... }) end,
  osd_message = function() end,
  add_periodic_timer = function() return { kill = function() end, resume = function() end } end,
  register_script_message = function() end,
  add_forced_key_binding = function() end,
  remove_key_binding = function() end,
}
package.preload["mp.utils"] = function()
  return {
    getcwd = function() return "/cwd" end,
    join_path = function(a, b) if b:sub(1, 1) == "/" then return b end return a .. "/" .. b end,
    split_path = function(p) return p:match("^(.*/)([^/]*)$") end,
  }
end
local here = arg[0]:match("^(.*)/tests/") or "."
local script = here .. "/bookmarker-menu.lua"
if not io.open(script) then script = here .. "/scripts/bookmarker-menu.lua" end
dofile(script)

local saved
loadTable = function() return {
  { name = "a", pos = 10, path = "/old/dir/xyz.mp4", version = 2 },
  { name = "b", pos = 50, path = "/old/dir/xyz.mp4", version = 2 },
} end
saveTable = function(t) saved = t; return true end
fileExists = function(p) return p == props.path end

quickLoad()
assert(#loads == 0, "should not loadfile the old path")
assert(seeks[1] == 10, "b should seek to first bookmark, got " .. tostring(seeks[1]))
assert(saved and saved[1].path == "/new/dir/xyz.mp4" and saved[2].path == "/new/dir/xyz.mp4", "paths not relinked")

props["time-pos"] = 60
quickLoadPrev()
assert(seeks[2] == 50, "v should seek to 50, got " .. tostring(seeks[2]))

-- relative path from mpv's working dir is stored as absolute
props.path = "xyz.mp4"
assert(currentPath() == "/cwd/xyz.mp4")
print("OK")
