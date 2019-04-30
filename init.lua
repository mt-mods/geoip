geoip = {
	url = minetest.settings:get("geoip.url")
}

local http = minetest.request_http_api()

if not http then
  error("geoip mod not in the trusted http mods!")
end

minetest.register_privilege("geoip", {
	description = "can do geoip lookups on players",
	give_to_singleplayer = false
})

minetest.register_privilege("geoip_verbose", {
	description = "can do geoip lookups on players (with more infos)",
	give_to_singleplayer = false
})



minetest.register_chatcommand("geoip", {
	params = "<playername>",
  privs = {geoip=true},
	description = "Does a geoip lookup on the given player",
	func = function(name, param)

    if not param then
      return true, "usage: /geoip <playername>"
    end

		local player = minetest.get_player_by_name(name)
    local is_verbose = minetest.check_player_privs(name, {geoip_verbose = true})

    if not minetest.get_player_ip then
      return true, "minetest.get_player_ip no available!"
    end

    local ip = minetest.get_player_ip(param)

    if not ip then
      return true, "no ip available!"
    end

    http.fetch({
      url = geoip.url .. "/" .. ip,
      timeout = 1,
    }, function(res)
      if res.code == 200 then
        local data = minetest.parse_json(res.data)

        local txt = "Geoip result: "

        if data.Data then
          if data.Data.Country and data.Data.Country.Names and data.Data.Country.Names.en then
            txt = txt .. " Country: " .. data.Data.Country.Names.en
          end
          if data.Data.City and data.Data.City.Names and data.Data.City.Names.en then
            txt = txt .. " City: " .. data.Data.City.Names.en
          end
          if is_verbose then
            txt = txt .. " IP: " .. ip
          end
        end

        minetest.chat_send_player(name, txt)
      else
        minetest.chat_send_player(name, "http request returned status: " .. res.code)
      end
    end)


	end
})
