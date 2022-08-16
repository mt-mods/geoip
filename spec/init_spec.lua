require("mineunit")

mineunit("core")
mineunit("player")
mineunit("common/after")
mineunit("server")
mineunit("http")
mineunit("auth")

fixture("geoip_server")

describe("geoip", function()

	-- Load current mod executing init.lua
	sourcefile("init")

	-- Execute on mods loaded callbacks to finish loading.
	mineunit:mods_loaded()

	-- Tell mods that 1 minute passed already to execute possible weird minetest.after hacks.
	mineunit:execute_globalstep(60)

	describe("geoip.lookup", function()

		it("handles success reply", function()
			mineunit.http_server:set_response(geoip_response.success)
			local result
			geoip.lookup("95.111.231.234", function(data) result = data end)
			mineunit:execute_globalstep(60)
			assert.not_nil(result)
		end)

		it("handles private reply", function()
			mineunit.http_server:set_response(geoip_response.private)
			local result
			geoip.lookup("127.0.0.1", function(data) result = data end)
			mineunit:execute_globalstep(60)
			assert.not_nil(result)
		end)

		it("handles invalid reply", function()
			mineunit.http_server:set_response(geoip_response.invalid)
			local result
			geoip.lookup("invalid query", function(data) result = data end)
			mineunit:execute_globalstep(60)
			assert.not_nil(result)
		end)

		it("handles empty reply", function()
			pending("TBD: Should callbacks be executed when there's no useful incoming data?")
			mineunit.http_server:set_response({code=200,data=""})
			local result
			geoip.lookup("server error", function(data) result = true end)
			mineunit:execute_globalstep(60)
			assert.not_nil(result)
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

		it("handles success reply", function()
			mineunit.http_server:set_response(geoip_response.success)
			mineunit:execute_on_joinplayer(Sam)
			-- Make sure geoip.lookup was called immediately
			assert.spy(geoip.lookup).was.called()
			mineunit:execute_globalstep(60)
			-- Make sure event handler was called after globalstep
			assert.not_nil(event_handler_called)
		end)

		it("handles private reply", function()
			mineunit.http_server:set_response(geoip_response.private)
			mineunit:execute_on_joinplayer(Sam)
			-- Make sure geoip.lookup was called immediately
			assert.spy(geoip.lookup).was.called()
			mineunit:execute_globalstep(60)
			-- Make sure event handler was called after globalstep
			assert.not_nil(event_handler_called)
		end)

		it("handles failure reply", function()
			mineunit.http_server:set_response(geoip_response.invalid)
			mineunit:execute_on_joinplayer(Sam)
			-- Make sure geoip.lookup was called immediately
			assert.spy(geoip.lookup).was.called()
			mineunit:execute_globalstep(60)
			-- Make sure event handler was called after globalstep
			assert.not_nil(event_handler_called)
		end)

		it("handles empty reply", function()
			mineunit.http_server:set_response({code=200,data=""})
			mineunit:execute_on_joinplayer(Sam)
			-- Make sure geoip.lookup was called immediately
			assert.spy(geoip.lookup).was.called()
			mineunit:execute_globalstep(60)
			-- Make sure event handler was called after globalstep
			pending("TBD: Should callbacks be executed when there's no useful incoming data?")
			assert.not_nil(event_handler_called)
		end)

	end)

end)
