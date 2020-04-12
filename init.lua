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
		url = "https://tools.keycdn.com/geo.json?host=" .. ip,
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

		lookup(ip, function(result)
			local txt = "Geoip result: "

			if result and result.status == "success" and result.data and result.data.geo then
				if result.data.geo.country_name then
					txt = txt .. " Country: " .. result.data.geo.country_name
				end
				if result.data.geo.city then
					txt = txt .. " City: " .. result.data.geo.city
				end
				if result.data.geo.timezone then
					txt = txt .. " Timezone: " .. result.data.geo.timezone
				end
				if is_verbose then
					txt = txt .. " IP: " .. ip
				end
			else
				minetest.chat_send_player(name, "Geoip error: " .. (result.description or "unknown error"))
			end

			minetest.log("action", "[geoip] result for player " .. param .. ": " .. txt)

			minetest.chat_send_player(name, txt)
		end)


	end
})
