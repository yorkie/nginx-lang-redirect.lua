# nginx-lang-redirect.lua

The Lua Script for supporting language redirections for Nginx/OpenResty.

## Dependencies

- nginx >= 1.7.*
- [OpenResty](http://openresty.org/)

## Example conf

```
location / {
  rewrite_by_lua_file   "path/to/lang.lua";
  proxy_pass            "http://backend.server"
}
```

## License

MIT
