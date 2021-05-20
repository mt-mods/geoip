local http = minetest.request_http_api()

geoip = {}

if not http then
	minetest.log("error", "geoip mod not in the trusted http mods!")
	return
end

minetest.register_privilege("geoip", {
	description = "can do geoip lookups on players",
	give_to_singleplayer = false
})

function geoip.lookup(ip, callback)
	http.fetch({
		url = "https://tools.keycdn.com/geo.json?host=" .. ip,
		extra_headers = {
			"User-Agent: keycdn-tools:https://minetest.net"
		},
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

local function format_result(result)
	if result and result.status == "success" and result.data and result.data.geo then
		local txt = "Geoip result: "
		if result.data.geo.country_name then
			txt = txt .. " Country: " .. result.data.geo.country_name
		end
		if result.data.geo.city then
			txt = txt .. " City: " .. result.data.geo.city
		end
		if result.data.geo.timezone then
			txt = txt .. " Timezone: " .. result.data.geo.timezone
		end
		if result.data.geo.asn then
			txt = txt .. " ASN: " .. result.data.geo.asn
		end
		if result.data.geo.isp then
			txt = txt .. " ISP: " .. result.data.geo.isp
		end
		if result.data.geo.ip then
			txt = txt .. " IP: " .. result.data.geo.ip
		end
		return txt
	else
		return false
	end
end

-- function(name, result)
geoip.joinplayer_callback = function() end

-- query ip on join, record in logs and execute callback
minetest.register_on_joinplayer(function(player)
	if not minetest.get_player_ip then
		return
	end

	local name = player:get_player_name()
	local ip = minetest.get_player_ip(name)
	if not ip then
		return
	end

	geoip.lookup(ip, function(data)
		-- log to debug.txt
		local txt = format_result(data)
		if txt then
			minetest.log("action", "[geoip] result for player " .. name .. ": " .. txt)
		end

		-- execute callback
		geoip.joinplayer_callback(name, data)
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

		if not minetest.get_player_ip then
			return true, "minetest.get_player_ip no available!"
		end

		local ip = minetest.get_player_ip(param)

		if not ip then
			return true, "no ip available!"
		end

		geoip.lookup(ip, function(result)
			local txt = format_result(result)

			if not txt then
				minetest.chat_send_player(name, "Geoip error: " .. (result.description or "unknown error"))
				return
			end

			minetest.log("action", "[geoip] result for player " .. param .. ": " .. txt)

			minetest.chat_send_player(name, txt)
		end)


	end
})
