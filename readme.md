
geoip mod for minetest

[![luacheck](https://github.com/mt-mods/geoip/actions/workflows/luacheck.yml/badge.svg)](https://github.com/mt-mods/geoip/actions/workflows/luacheck.yml)
[![mineunit](https://github.com/mt-mods/geoip/actions/workflows/mineunit.yml/badge.svg)](https://github.com/mt-mods/geoip/actions/workflows/mineunit.yml)

# Overview

Lets you resolve geoip requests on a player

powered by [IP Location Finder by KeyCDN](https://tools.keycdn.com/geo)

### minetest.conf
```
# enable curl/http on that mod, required for geoip mod
secure.http_mods = geoip

# geoip result cache time-to-live value, default is 3 hours
geoip.cache.ttl = 10800
```

### Commands
```
/geoip <playername>
```

### privs

* `geoip` can make a geoip query

# Api

```lua
-- Geoip lookup command
geoip.lookup("213.152.186.35", function(result)
	-- See "Geoip result data"
end)

-- Event handler registration
geoip.register_on_joinplayer(function(playername, result, last_login)
  -- See "Geoip result data" for example result.
  if result.asn == 65535 then
    minetest.after(0, function()
      minetest.kick_player(playername, "No joining from reserved unused ASN")
    end)
    -- Return `true` to stop event handler propagation, should be used if player will be forcibly disconnected
    return true
  end
end)

-- Event handler registration
geoip.register_on_prejoinplayer(function(playername, result, last_login, auth_data)
  -- Only called if data is alre4ady cached.
  -- See "Geoip result data" for example result.
  if result.asn == 65535 then
    -- Return string to disconnect player with that string as a reason.
    return "No joining from reserved unused ASN"
  end
end)
```

## Geoip result data
```lua
{
  success = true,
  status = "success",
  description = "Data successfully received.",
  host = "213.152.186.35",
  ip = "213.152.186.35",
  rdns = "213.152.186.35",
  asn = 49453,
  isp = "Global Layer B.V.",
  country_name = "Netherlands",
  country_code = "NL",
  region_name = null,
  region_code = null,
  city = null,
  postal_code = null,
  continent_name = "Europe",
  continent_code = "EU",
  latitude = 52.3824,
  longitude = 4.8995,
  metro_code = null,
  timezone = "Europe/Amsterdam",
  datetime = "2021-05-20 08:45:56"
}
```

# License

MIT