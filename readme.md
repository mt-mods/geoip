
geoip mod for minetest

![luacheck](https://github.com/pandorabox-io/geoip/workflows/luacheck/badge.svg)

# Overview

Lets you resolve geoip requests on a player

powered by [IP Location Finder by KeyCDN](https://tools.keycdn.com/geo)

### minetest.conf
```
# enable curl/http on that mod
secure.http_mods = geoip
```

### Commands
```
/geoip <playername>
```

### privs

* `geoip` can make a geoip query
