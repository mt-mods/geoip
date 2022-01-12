-- geoip response samples for different address types
geoip_response = {
	-- `success` covers regular response for internet host.
	success = {
		code = 200,
		data = ([[{
			"status":"success",
			"description":"Data successfully received.",
			"data":{
				"geo":{
					"host":"95.111.231.234",
					"ip":"95.111.231.234",
					"rdns":"vmi519958.contaboserver.net",
					"asn":51167,
					"isp":"Contabo GmbH",
					"country_name":"Germany",
					"country_code":"DE",
					"region_name":"Bavaria",
					"region_code":"BY",
					"city":"Nuremberg",
					"postal_code":"90475",
					"continent_name":"Europe",
					"continent_code":"EU",
					"latitude":49.405,
					"longitude":11.1617,
					"metro_code":null,
					"timezone":"Europe\/Berlin",
					"datetime":"2021-12-12 12:34:56"
				}
			}
		}]]):gsub("[\t\n]","")
	},
	-- `private` covers responses for private networks including loopback.
	-- note that `asn` is empty string instead of number or null.
	private = {
		code = 200,
		data = ([[{
			"status":"success",
			"description":"Data successfully received.",
			"data":{
				"geo":{
					"host":"127.0.0.1",
					"ip":"127.0.0.1",
					"rdns":"localhost",
					"asn":"",
					"isp":"",
					"country_name":"",
					"country_code":"",
					"region_name":"",
					"region_code":"",
					"city":"",
					"postal_code":"",
					"continent_name":"",
					"continent_code":"",
					"latitude":"",
					"longitude":"",
					"metro_code":"",
					"timezone":"",
					"datetime":""
				}
			}
		}]]):gsub("[\t\n]","")
	},
	-- `invalid` covers responses for invalid host query.
	invalid = {
		code = 200,
		data = ([[{
			"status":"error",
			"description":"Hostname did not resolve any IP."
		}]]):gsub("[\t\n]","")
	}
}
