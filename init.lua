geoip = {
	url = minetest.settings:get("geoip.url")
}

local http = minetest.request_http_api()

if not http then
	minetest.log("error", "geoip mod not in the trusted http mods!")
	return
end

minetest.register_privilege("geoip", {
	description = "can do geoip lookups on players",
	give_to_singleplayer = false
})

minetest.register_privilege("geoip_verbose", {
	description = "can do geoip lookups on players (with more infos)",
	give_to_singleplayer = false
})

local function lookup(ip, callback)
	http.fetch({
		url = geoip.url .. "/" .. ip,
		timeout = 1,
	}, function(res)
		if res.code == 200 and callback then
			local data = minetest.parse_json(res.data)
			callback(data)
		else
			minetest.log("warning", "[geoip] http request returned status: " .. res.code)
		end
	end)
end

-- query on join
-- save country and city in player-meta
-- useful for detection of multi-accounts and ban-evasion on certain ISP's
minetest.register_on_joinplayer(function(player)
	if not minetest.get_player_ip then
		return
	end

	local name = player:get_player_name()
	local ip = minetest.get_player_ip(name)

	if not ip then
		return
	end

	lookup(ip, function(data)
		local player_ref = minetest.get_player_by_name(name)
		if not player_ref then
			return
		end

		local meta = player_ref:get_meta()

		if data.Data then
			if data.Data.Country and data.Data.Country.Names and data.Data.Country.Names.en then
				meta:set_string("geo_country", data.Data.Country.Names.en)
			end
			if data.Data.City and data.Data.City.Names and data.Data.City.Names.en then
				meta:set_string("geo_city", data.Data.City.Names.en)
			end
		end
	end)

end)



-- manual query
minetest.register_chatcommand("geoip", {
	params = "<playername>",
	privs = {geoip=true},
	description = "Does a geoip lookup on the given player",
	func = function(name, param)

		if not param then
			return true, "usage: /geoip <playername>"
		end

		minetest.log("action", "[geoip] Player " .. name .. " queries the player: " .. param)

		local is_verbose = minetest.check_player_privs(name, {geoip_verbose = true})

		if not minetest.get_player_ip then
			return true, "minetest.get_player_ip no available!"
		end

		local ip = minetest.get_player_ip(param)

		if not ip then
			return true, "no ip available!"
		end

		lookup(ip, function(data)
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

			minetest.log("action", "[geoip] result for player " .. param .. ": " .. txt)

			minetest.chat_send_player(name, txt)
		end)


	end
})
