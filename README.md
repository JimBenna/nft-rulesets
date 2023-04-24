# nft-rulesets
Repository to store a script and all details that downloads and prepare GeoIP database to be used with nftables rulesets
I found an awesome script on the [WireFalls Github](https://github.com/wirefalls/geo-nft). 
the idea was brilliant.
But this script was using the GeoIP database from [db-ip.com](https//db-ip.com).
And I wasn't happy for that for several reasons.
1. I already use the free [Maxmind GeoIP database](https://maxmind.com) with nginx
2. I prefer the [Maxmind GeoIP database](https://maxmind.com). 
I believe that it's one of the most accurate one, and all subnets are written in CIDR mode, and I personnally think it's clearer, this way
