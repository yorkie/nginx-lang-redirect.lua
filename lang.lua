--------------------------------------------------
-- HTTP Accept-Language header handler          --
-- @license MIT                                 --
-- @requires:                                   --
--  -gnu find                                   --
-- @description:                                --
--     redirects to subfolders according        --
--     to the http Accept-Language header       --
-- @example coinfguration:                      --
--                                              --
--     server {                                 --
--         listen 8080 default_server;          --
--         index index.html index.htm;          --
--         server_name localhost;               --
--                                              --
--         set $root /usr/share/nginx/html;     --
--         root $root;                          --
--                                              --
--         location /index.html {               --
--             # lua_code_cache off;            --
--             set $default_lang "cz";          --
--             set $ngx_html_path $root;        --
--             rewrite_by_lua_file lang.lua;    --
--         }                                    --
--     }                                        --
--                                              --
--------------------------------------------------

local default_lang = ngx.var.default_lang or "zh"
local lang_header = ngx.var.http_accept_language
local parsed_uri, _, _ = ngx.re.sub(ngx.var.uri, "(en|zh)", "")
local lang_corrects = { us = "en",
                        en = "en",
                        cn = "zh",
                        zh = "zh" }

local m_uri, _ = ngx.re.match(ngx.var.uri, "(en|zh)(.*)", "")
if m_uri then
  if m_uri[1] == default_lang then
    ngx.req.set_uri("/" .. m_uri[2])
  else
    ngx.req.set_uri("/en/" .. m_uri[2])
  end
  -- direct return if check /(en|zh)/..
  return
end

if lang_header == nil then
  return
end

local cleaned = ngx.re.sub(lang_header, "^.*:", "")
local options = {}
local iterator, err = ngx.re.gmatch(cleaned, "\\s*([a-z]+(?:-[a-z])*)\\s*(?:;q=([0-9]+(.[0-9]*)?))?\\s*(,|$)", "i")
for m, err in iterator do
  local lang = lang_corrects[m[1]:lower()]
  local priority = 1
  if m[2] ~= nil then
    priority = tonumber(m[2])
    if priority == nil then priority = 1 end
  end
  table.insert(options, {lang, priority})
end

table.sort(options, function(a,b) return b[2] < a[2] end)

for index, lang in pairs(options) do
  if lang[1]:lower() ~= default_lang then
    ngx.req.set_uri("/en/" .. parsed_uri)
    break
  end
end
