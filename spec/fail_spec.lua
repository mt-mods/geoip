require("mineunit")

mineunit("core")
mineunit("player")
mineunit("common/after")
mineunit("server")
mineunit("http")

fixture("geoip_server")

describe("geoip", function()

	-- Replace configuration file for current tests
	local core_settings = core.settings
	core.settings = Settings("minetest_noop.conf")
	teardown(function()
		core.settings = core_settings
	end)

	-- Load current mod executing init.lua
	sourcefile("init")

	-- Execute on mods loaded callbacks to finish loading.
	mineunit:mods_loaded()

	-- Tell mods that 1 minute passed already to execute possible weird minetest.after hacks.
	mineunit:execute_globalstep(60)

	describe("geoip.lookup", function()

		it("not handling requests", function()
			mineunit.http_server:set_response(geoip_response.success)
			local result
			geoip.lookup("95.111.231.234", function(data) result = true end)
			mineunit:execute_globalstep(60)
			assert.is_nil(result)
		end)

	end)

	describe("geoip on_joinplayer", function()

		local Sam = Player("Sam")

		-- Track registered event handler execution
		local event_handler_called
		geoip.register_on_joinplayer(function() event_handler_called = true end)

		before_each(function()
			event_handler_called = nil
			spy.on(geoip, "lookup")
		end)

		after_each(function()
			mineunit:execute_on_leaveplayer(Sam)
		end)

		it("not handling success reply", function()
			mineunit.http_server:set_response(geoip_response.success)
			mineunit:execute_on_joinplayer(Sam)
			mineunit:execute_globalstep(60)
			-- Make sure lookup and event handler wre not called
			assert.spy(geoip.lookup).not_called()
			assert.is_nil(event_handler_called)
		end)

		it("handles private reply", function()
			mineunit.http_server:set_response(geoip_response.private)
			mineunit:execute_on_joinplayer(Sam)
			mineunit:execute_globalstep(60)
			-- Make sure lookup and event handler wre not called
			assert.spy(geoip.lookup).not_called()
			assert.is_nil(event_handler_called)
		end)

		it("handles failure reply", function()
			mineunit.http_server:set_response(geoip_response.invalid)
			mineunit:execute_on_joinplayer(Sam)
			mineunit:execute_globalstep(60)
			-- Make sure lookup and event handler wre not called
			assert.spy(geoip.lookup).not_called()
			assert.is_nil(event_handler_called)
		end)

		it("not handling empty reply", function()
			mineunit.http_server:set_response({code=200,data=""})
			mineunit:execute_on_joinplayer(Sam)
			mineunit:execute_globalstep(60)
			-- Make sure lookup and event handler wre not called
			assert.spy(geoip.lookup).not_called()
			assert.is_nil(event_handler_called)
		end)

	end)

end)
