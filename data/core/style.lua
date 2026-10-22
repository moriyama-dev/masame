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
-- Chinese, Japanese and Korean text is drawn with system fonts: the bundled
-- fonts have none of those glyphs, so they are added to each font group as
-- fallbacks. The font for the interface language comes first, as the three
-- draw some shared characters differently.
local cjk_fonts
if PLATFORM == "Windows" then
  local fonts = (os.getenv("WINDIR") or "C:\\Windows") .. "\\Fonts\\"
  cjk_fonts = {
    ja = { fonts .. "YuGothM.ttc", fonts .. "YuGothR.ttc", fonts .. "meiryo.ttc", fonts .. "msgothic.ttc" },
    ko = { fonts .. "malgun.ttf", fonts .. "gulim.ttc" },
    zh_CN = { fonts .. "msyh.ttc", fonts .. "simsun.ttc" },
    zh_TW = { fonts .. "msjh.ttc", fonts .. "mingliu.ttc" },
  }
elseif PLATFORM == "Mac OS X" then
  local any = { "/System/Library/Fonts/Supplemental/Arial Unicode.ttf", "/Library/Fonts/Arial Unicode.ttf" }
  cjk_fonts = {
    ja = { "/System/Library/Fonts/ヒラギノ角ゴシック W3.ttc", any[1], any[2] },
    ko = { "/System/Library/Fonts/AppleSDGothicNeo.ttc", any[1], any[2] },
    zh_CN = { "/System/Library/Fonts/PingFang.ttc", "/System/Library/Fonts/Hiragino Sans GB.ttc", any[1], any[2] },
    zh_TW = { "/System/Library/Fonts/PingFang.ttc", "/System/Library/Fonts/STHeiti Light.ttc", any[1], any[2] },
  }
else
  -- Noto Sans CJK covers all four in one file
  local noto = {
    "/usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc",
    "/usr/share/fonts/noto-cjk/NotoSansCJK-Regular.ttc",
  }
  cjk_fonts = {
    ja = { noto[1], noto[2], "/usr/share/fonts/opentype/noto/NotoSansCJKjp-Regular.otf",
      "/usr/share/fonts/opentype/ipaexfont-gothic/ipaexg.ttf",
      "/usr/share/fonts/truetype/fonts-japanese-gothic.ttf" },
    ko = { noto[1], noto[2], "/usr/share/fonts/truetype/nanum/NanumGothic.ttf" },
    zh_CN = { noto[1], noto[2], "/usr/share/fonts/truetype/wqy/wqy-microhei.ttc" },
    zh_TW = { noto[1], noto[2], "/usr/share/fonts/truetype/wqy/wqy-microhei.ttc" },
  }
end

local function find_cjk_font(lang, ask_fontconfig)
  for _, path in ipairs(cjk_fonts[lang]) do
    if system.get_file_info(path) then return path end
  end
  if not ask_fontconfig or PLATFORM == "Windows" or PLATFORM == "Mac OS X" then return end
  local fc_lang = ({ ja = "ja", ko = "ko", zh_CN = "zh-cn", zh_TW = "zh-tw" })[lang]
  local ok, fp = pcall(io.popen, "fc-match -f '%{file}' ':lang=" .. fc_lang .. "' 2>/dev/null")
  if ok and fp then
    local path = fp:read("*a")
    fp:close()
    if path and path ~= "" and system.get_file_info(path) then return path end
  end
end

-- The fonts to fall back to, in order, without repeating a file. Only the
-- first language asks fontconfig, which takes a moment at startup.
local function find_cjk_fonts()
  local i18n = require "core.i18n"
  i18n.load()
  local order = { "ja", "ko", "zh_CN", "zh_TW" }
  if cjk_fonts[i18n.lang] then
    table.insert(order, 1, i18n.lang)
  end
  local paths, seen = {}, {}
  for i, lang in ipairs(order) do
    local path = not seen[lang] and find_cjk_font(lang, i == 1)
    seen[lang] = true
    if path and not seen[path] then
      seen[path] = true
      table.insert(paths, path)
    end
  end
  return paths
end

style.cjk_font_paths = find_cjk_fonts()

local function with_cjk(font, size)
  local group = { font }
  for _, path in ipairs(style.cjk_font_paths) do
    local ok, fallback = pcall(renderer.font.load, path, size)
    if ok then table.insert(group, fallback) end
  end
  if #group == 1 then return font end
  return renderer.font.group(group)
end

style.font = with_cjk(renderer.font.load(DATADIR .. "/fonts/FiraSans-Regular.ttf", 15 * SCALE), 15 * SCALE)
style.big_font = style.font:copy(46 * SCALE)
style.icon_font = renderer.font.load(DATADIR .. "/fonts/icons.ttf", 16 * SCALE, {antialiasing="grayscale", hinting="full"})
style.icon_big_font = style.icon_font:copy(23 * SCALE)
style.code_font = with_cjk(renderer.font.load(DATADIR .. "/fonts/JetBrainsMono-Regular.ttf", 15 * SCALE), 15 * SCALE)

style.syntax = {}

-- This can be used to override fonts per syntax group.
-- The syntax highlighter will take existing values from this table and
-- override style.code_font on a per-token basis, so you can choose to eg.
-- render comments in an italic font if you want to.
style.syntax_fonts = {}
-- style.syntax_fonts["comment"] = renderer.font.load(path_to_font, size_of_font, rendering_options)

style.log = {}

return style
