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

local m_uri, _ = ngx.re.match(ngx.var.uri, "^/(en|zh|cn)(/?)(.*)", "i")
if m_uri then
  local lang = lang_corrects[m_uri[1]]
  local has_slash = m_uri[2] == ""
  local real_path = m_uri[3]

  -- redirect rule:
  -- /en -> /en/
  -- /zh -> /zh/
  if has_slash then
    ngx.redirect(lang .. "/")
    return
  end

  if lang == default_lang then
    ngx.req.set_uri("/" .. real_path)
  else
    ngx.req.set_uri("/en/" .. real_path)
  end

  -- direct return if check /(en|zh)/..
  return
end

-- no Accept-Languages field
if lang_header == nil then
  ngx.req.set_uri(ngx.var.uri)
  return
end

-- check if the request is requesting a resource(js/css/image)
local m_uri_is_resource, _ = ngx.re.match(ngx.var.uri, "\\.(js|css|png|jpg)", "i")
if m_uri_is_resource then
  ngx.req.set_uri(ngx.var.uri)
  return
end

-- check Accept-Languages
local cleaned = ngx.re.sub(lang_header, "^.*:", "")
local options = {}
local re_lang = "\\s*([a-z]+(?:-[a-z])*)\\s*(?:;q=([0-9]+(.[0-9]*)?))?\\s*(,|$)"
local iterator, err = ngx.re.gmatch(cleaned, re_lang, "i")
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
    if parsed_uri == "/" then
      ngx.redirect("/en/")
    else
      ngx.redirect("/en/" .. parsed_uri)
    end
    break
  else
    ngx.req.set_uri("/" .. parsed_uri)
    break
  end
end
