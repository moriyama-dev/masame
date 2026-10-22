-- Interface language.
--
-- Strings are written in English in the code and looked up in
-- core/locale/<lang>.lua when another language is selected. The choice is
-- stored in USERDIR/language.lua and takes effect immediately.
local i18n = {}

-- Each language other than English has core/locale/<id>.lua. Names are
-- written in the language itself.
i18n.languages = {
  { id = "en", name = "English" },
  { id = "ja", name = "日本語" },
  { id = "zh_CN", name = "简体中文" },
  { id = "zh_TW", name = "繁體中文" },
  { id = "ko", name = "한국어" },
  { id = "es", name = "Español" },
  { id = "fr", name = "Français" },
  { id = "de", name = "Deutsch" },
  { id = "it", name = "Italiano" },
  { id = "pt_BR", name = "Português (Brasil)" },
  { id = "nl", name = "Nederlands" },
  { id = "pl", name = "Polski" },
  { id = "ru", name = "Русский" },
  { id = "uk", name = "Українська" },
  { id = "tr", name = "Türkçe" },
  { id = "vi", name = "Tiếng Việt" },
  { id = "id", name = "Bahasa Indonesia" },
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

-- Picks a supported language from a language code ("pt") and an optional
-- country code ("BR"); nil when there is none.
local function match_language(language, country)
  language = language and language:lower()
  country = country and country:upper()
  if not language or language == "" then return end
  if language == "zh" then
    -- Taiwan, Hong Kong and Macau write Traditional Chinese
    if country == "TW" or country == "HK" or country == "MO" or country == "HANT" then
      return "zh_TW"
    end
    return "zh_CN"
  end
  if language == "pt" then return "pt_BR" end
  if language == "in" then language = "id" end
  if is_supported(language) then return language end
end

local function detect_system_language()
  if PLATFORM ~= "Linux" and system.get_preferred_language then
    local ok, language, country = pcall(system.get_preferred_language)
    if ok and language then
      -- some systems put the script in the language ("zh-Hant")
      local lang, script = language:match("^(%a+)[-_](%a+)")
      return match_language(lang or language, country or script) or "en"
    end
  end
  for _, var in ipairs { "LC_ALL", "LC_MESSAGES", "LANGUAGE", "LANG" } do
    local value = os.getenv(var)
    if value and value ~= "" then
      -- "ja_JP.UTF-8", or a list such as "zh_TW:en" in LANGUAGE
      local first = value:match("^[^:]+")
      local language, country = first:match("^(%a+)[_-]?(%a*)")
      return match_language(language, country) or "en"
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
