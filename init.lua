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

-- Default TTL for cached results: 3 hours
local cache_ttl = tonumber(minetest.settings:get("geoip.cache.ttl")) or 10800
local cache = {}

-- Execute cache cleanup every cache_ttl seconds
local function cache_cleanup()
	local expire = minetest.get_us_time() - (cache_ttl * 1000 * 1000)
	for ip, data in pairs(cache) do
		if expire > data.timestamp then
			cache[ip] = nil
		end
	end
	minetest.after(cache_ttl, cache_cleanup)
end
minetest.after(cache_ttl, cache_cleanup)

-- Main geoip lookup function, callback function gets result table as first argument
function geoip.lookup(ip, callback, playername)
	if cache[ip] then
		if playername and not cache[ip].players[playername] then
			cache[ip].players[playername] = minetest.get_us_time()
		end
		callback(cache[ip])
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
				local timestamp = minetest.get_us_time()
				local result = type(data.data) == "table" and type(data.data.geo) == "table" and data.data.geo or {}
				result.success = data.status == "success"
				result.status = data.status
				result.description = data.description
				result.timestamp = timestamp
				result.players = playername and {[playername]=timestamp} or {}
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

local on_joinplayer_handlers = {}
function geoip.register_on_joinplayer(fn)
	assert(type(fn) == "function", "geoip.register_on_joinplayer expects function as a first argument")
	table.insert(on_joinplayer_handlers, fn)
end

local on_prejoinplayer_handlers = {}
function geoip.register_on_prejoinplayer(fn)
	assert(type(fn) == "function", "geoip.register_on_prejoinplayer expects function as a first argument")
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
	end, name)
end)

local function format_message(name, result)
	local txt = format_result(result)
	if not txt then
		return "Geoip error: " .. (result.description or "unknown error")
	end
	minetest.log("action", "[geoip] result for player " .. name .. ": " .. txt)
	return txt
end

local function format_matches_by_name(name)
	local formatted_results = {}
	local now = minetest.get_us_time()
	local count = 0
	for _, result in pairs(cache) do
		if result.players[name] then
			table.insert(formatted_results, {
				time = now - result.players[name],
				txt = format_message(name, result)
			})
			count = count + 1
		end
	end
	if count > 0 then
		table.sort(formatted_results, function(a,b)
			return a.time < b.time
		end)
		local msg = ""
		for i = 1, count do
			local s = math.floor(formatted_results[i].time / 1000000)
			local m = math.floor(s / 60) % 60
			local h = math.floor(s / 60 / 60)
			local time = ("%dh %dm %ds ago: "):format(h, m, s % 60)
			msg = msg .. time .. formatted_results[i].txt .. (i < count and "\n" or "")
		end
		return msg
	end
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

		local ip = minetest.get_player_ip(param)

		if ip then
			-- go through lookup if ip is available, this might still return cached result
			geoip.lookup(ip, function()
				local msg = format_matches_by_name(param) or "No matching geoip results found."
				minetest.chat_send_player(name, msg)
			end, param)
		else
			local msg = format_matches_by_name(param) or "No ip or cached result available."
			return true, msg
		end

	end
})
