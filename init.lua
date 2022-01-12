local http = QoS and QoS(minetest.request_http_api(), 1) or minetest.request_http_api()

geoip = {}

if not http or not minetest.get_player_ip then
	minetest.log("error", "[geoip] not in the trusted http mods or minetest.get_player_ip not available!")
	setmetatable(geoip, {
		__index = function()
			return function() minetest.log("warning", "[geoip] API disabled, see load time errors!") end
		end
	})
	return
end

minetest.register_privilege("geoip", {
	description = "can do geoip lookups on players",
	give_to_singleplayer = false
})

local cache_ttl = tonumber(minetest.settings:get("geoip.cache.ttl")) or 3600
local cache = {}

local function cleanup()
	local expire = minetest.get_us_time() - (cache_ttl * 1000 * 1000)
	for ip, data in pairs(cache) do
		if expire > data.timestamp then
			cache[ip] = nil
		end
	end
end

function geoip.lookup(ip, callback)
	if cache[ip] then
		-- Might return expired entries but that should not really matter here
		callback(cache[ip])
		cleanup()
		return
	end
	http.fetch({
		url = "https://tools.keycdn.com/geo.json?host=" .. ip,
		extra_headers = {
			"User-Agent: keycdn-tools:https://minetest.net"
		},
		timeout = 1,
	}, function(res)
		if res.code == 200 and callback then
			local data = minetest.parse_json(res.data)
			if type(data) == "table" then
				local result = type(data.data) == "table" and type(data.data.geo) == "table" and data.data.geo or {}
				result.success = data.status == "success"
				result.status = data.status
				result.description = data.description
				result.timestamp = minetest.get_us_time()
				cache[ip] = result
				callback(result)
				return
			end
		end
		minetest.log("warning", "[geoip] http request returned status: " .. res.code)
	end)
end

local function format_result(result)
	if result and result.success then
		local txt = "Geoip result: "
		if result.country_name then
			txt = txt .. " Country: " .. result.country_name
		end
		if result.city then
			txt = txt .. " City: " .. result.city
		end
		if result.timezone then
			txt = txt .. " Timezone: " .. result.timezone
		end
		if result.asn then
			txt = txt .. " ASN: " .. result.asn
		end
		if result.isp then
			txt = txt .. " ISP: " .. result.isp
		end
		if result.ip then
			txt = txt .. " IP: " .. result.ip
		end
		return txt
	else
		return false
	end
end

-- function(name, result, last_login)
geoip.joinplayer_callback = function() end

-- function(name, result, last_login)
local on_joinplayer_handlers = {}
function geoip.register_on_joinplayer(fn)
	table.insert(on_joinplayer_handlers, fn)
end

local on_prejoinplayer_handlers = {}
function geoip.register_on_prejoinplayer(fn)
	table.insert(on_prejoinplayer_handlers, fn)
end

minetest.register_on_prejoinplayer(function(name,ip)
	-- Execute prejoin callbacks if we already know IP, this allows acting before account is created or joined
	if cache[ip] then
		minetest.log("info", "[geoip] executing prejoin callbacks: " .. name .. " (".. ip .. ")")
		local auth_handler = minetest.get_auth_handler()
		local auth = auth_handler.get_auth(name)
		local last_login = auth and auth.last_login or nil
		-- execute registered event handler callbacks
		for _,fn in ipairs(on_prejoinplayer_handlers) do
			local result = fn(name, cache[ip], last_login, auth)
			if type(result) == "string" then
				-- Event handler asked to stop propagation and disconnect player, bail out
				return result
			end
		end
	end
end)

-- query ip on join, record in logs and execute callback
minetest.register_on_joinplayer(function(player, last_login)
	local name = player:get_player_name()
	local ip = minetest.get_player_ip(name)
	if not ip then
		minetest.log("warning", "[geoip] get player IP address failed: " .. name)
		return
	end

	geoip.lookup(ip, function(data)
		-- log to debug.txt
		local txt = format_result(data)
		if txt then
			minetest.log("action", "[geoip] result for player " .. name .. ": " .. txt)
		else
			local msg = "Lookup failed for " .. name .. "@" .. ip .. " Reason: " .. tostring(data.description)
			minetest.log("warning", "[geoip] ".. msg)
		end

		-- execute registered event handler callbacks
		for _,fn in ipairs(on_joinplayer_handlers) do
			if fn(name, data, last_login) == true then
				-- Event handler asked to stop propagation, bail out
				return
			end
		end

		-- execute function override callback
		geoip.joinplayer_callback(name, data, last_login)
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
