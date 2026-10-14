-- Interface language (English / Japanese).
--
-- Strings are written in English in the code and looked up in
-- core/locale/<lang>.lua when another language is selected. The choice is
-- stored in USERDIR/language.lua and takes effect immediately.
local i18n = {}

i18n.languages = {
  { id = "en", name = "English" },
  { id = "ja", name = "日本語" },
}

i18n.lang = "en"

local dictionaries = {}

local function dictionary(lang)
  if dictionaries[lang] == nil then
    local ok, dict = pcall(require, "core.locale." .. lang)
    dictionaries[lang] = ok and type(dict) == "table" and dict or false
  end
  return dictionaries[lang]
end

---Translates an English interface string.
---@param text any
---@return any
function i18n.t(text)
  if i18n.lang == "en" or type(text) ~= "string" then return text end
  local dict = dictionary(i18n.lang)
  return dict and dict[text] or text
end

---Translates a format string, then formats it.
---@param fmt string
function i18n.f(fmt, ...)
  return string.format(i18n.t(fmt), ...)
end

local function settings_file()
  return USERDIR .. PATHSEP .. "language.lua"
end

local function is_supported(lang)
  for _, l in ipairs(i18n.languages) do
    if l.id == lang then return true end
  end
  return false
end

local function detect_system_language()
  for _, var in ipairs { "LC_ALL", "LC_MESSAGES", "LANGUAGE", "LANG" } do
    local value = os.getenv(var)
    if value and value ~= "" then
      return value:match("^ja") and "ja" or "en"
    end
  end
  return "en"
end

---Loads the saved language, or picks one from the system locale.
function i18n.load()
  local fn = loadfile(settings_file())
  local ok, saved = false, nil
  if fn then ok, saved = pcall(fn) end
  if ok and is_supported(saved) then
    i18n.lang = saved
  else
    i18n.lang = detect_system_language()
  end
end

---Changes the interface language and remembers it.
---@param lang string
function i18n.set(lang)
  if not is_supported(lang) then return end
  i18n.lang = lang
  local fp = io.open(settings_file(), "w")
  if fp then
    fp:write(string.format("return %q\n", lang))
    fp:close()
  end
end

return i18n
