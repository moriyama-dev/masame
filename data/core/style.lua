local common = require "core.common"
local style = {}

style.padding = { x = common.round(14 * SCALE), y = common.round(7 * SCALE) }
style.divider_size = common.round(1 * SCALE)
style.scrollbar_size = common.round(4 * SCALE)
style.expanded_scrollbar_size = common.round(12 * SCALE)
style.caret_width = common.round(2 * SCALE)
style.tab_width = common.round(170 * SCALE)

-- The function renderer.font.load can accept an option table as a second optional argument.
-- It shoud be like the following:
--
-- {antialiasing= "grayscale", hinting = "full"}
--
-- The possible values for each option are:
-- - for antialiasing: grayscale, subpixel
-- - for hinting: none, slight, full
--
-- The defaults values are antialiasing subpixel and hinting slight for optimal visualization
-- on ordinary LCD monitor with RGB patterns.
--
-- On High DPI monitor or non RGB monitor you may consider using antialiasing grayscale instead.
-- The antialiasing grayscale with full hinting is interesting for crisp font rendering.
-- Japanese text is drawn with a system font: the bundled fonts have no
-- Japanese glyphs, so it is added to each font group as a fallback.
local function find_japanese_font()
  local candidates
  if PLATFORM == "Windows" then
    local fonts = (os.getenv("WINDIR") or "C:\\Windows") .. "\\Fonts\\"
    candidates = {
      fonts .. "YuGothM.ttc", fonts .. "YuGothR.ttc", fonts .. "meiryo.ttc",
      fonts .. "msgothic.ttc",
    }
  elseif PLATFORM == "Mac OS X" then
    candidates = {
      "/System/Library/Fonts/ヒラギノ角ゴシック W3.ttc",
      "/System/Library/Fonts/Hiragino Sans GB.ttc",
      "/System/Library/Fonts/Supplemental/Arial Unicode.ttf",
      "/Library/Fonts/Arial Unicode.ttf",
    }
  else
    candidates = {
      "/usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc",
      "/usr/share/fonts/opentype/noto/NotoSansCJKjp-Regular.otf",
      "/usr/share/fonts/noto-cjk/NotoSansCJK-Regular.ttc",
      "/usr/share/fonts/opentype/ipaexfont-gothic/ipaexg.ttf",
      "/usr/share/fonts/truetype/fonts-japanese-gothic.ttf",
    }
  end
  for _, path in ipairs(candidates) do
    if system.get_file_info(path) then return path end
  end
  if PLATFORM == "Windows" or PLATFORM == "Mac OS X" then return end
  local ok, fp = pcall(io.popen, "fc-match -f '%{file}' ':lang=ja' 2>/dev/null")
  if ok and fp then
    local path = fp:read("*a")
    fp:close()
    if path and path ~= "" and system.get_file_info(path) then return path end
  end
end

style.japanese_font_path = find_japanese_font()

local function with_japanese(font, size)
  if not style.japanese_font_path then return font end
  local ok, jp = pcall(renderer.font.load, style.japanese_font_path, size)
  if not ok then return font end
  return renderer.font.group { font, jp }
end

style.font = with_japanese(renderer.font.load(DATADIR .. "/fonts/FiraSans-Regular.ttf", 15 * SCALE), 15 * SCALE)
style.big_font = style.font:copy(46 * SCALE)
style.icon_font = renderer.font.load(DATADIR .. "/fonts/icons.ttf", 16 * SCALE, {antialiasing="grayscale", hinting="full"})
style.icon_big_font = style.icon_font:copy(23 * SCALE)
style.code_font = with_japanese(renderer.font.load(DATADIR .. "/fonts/JetBrainsMono-Regular.ttf", 15 * SCALE), 15 * SCALE)

style.syntax = {}

-- This can be used to override fonts per syntax group.
-- The syntax highlighter will take existing values from this table and
-- override style.code_font on a per-token basis, so you can choose to eg.
-- render comments in an italic font if you want to.
style.syntax_fonts = {}
-- style.syntax_fonts["comment"] = renderer.font.load(path_to_font, size_of_font, rendering_options)

style.log = {}

return style
