
### minetest.conf
```
# enable curl/http on that mod
secure.http_mods = geoip

# the url to the geoip server
geoip.url = http://127.0.0.1:5000
```

### Commands
```
/geoip <playername>
```


### privs

* `geoip` geoip query with basic responses (country, city)
* `geoip_verbose` geoip query with additional ip-address

### docker compose

```yml
version: "2"

services:
 geoip:
  image: klauspost/geoip-service
  restart: always
  ports:
   - "5000:5000"
  volumes:
   - "./GeoLite2-City.mmdb:/data/geodb.mmdb"
```
