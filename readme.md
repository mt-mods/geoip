
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

# Api

```lua
geoip.lookup("213.152.186.35", function(result)
	--[[
result = {
  "status": "success",
  "description": "Data successfully received.",
  "data": {
    "geo": {
      "host": "213.152.186.35",
      "ip": "213.152.186.35",
      "rdns": "213.152.186.35",
      "asn": 49453,
      "isp": "Global Layer B.V.",
      "country_name": "Netherlands",
      "country_code": "NL",
      "region_name": null,
      "region_code": null,
      "city": null,
      "postal_code": null,
      "continent_name": "Europe",
      "continent_code": "EU",
      "latitude": 52.3824,
      "longitude": 4.8995,
      "metro_code": null,
      "timezone": "Europe/Amsterdam",
      "datetime": "2021-05-20 08:45:56"
    }
  }
}
	--]]
end)
```
