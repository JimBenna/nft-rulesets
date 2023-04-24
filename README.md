# nft-rulesets
[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)

## Purpose
Repository to store a script and all details that downloads and prepare GeoIP database to be used with nftables rulesets
I found an awesome script on the [WireFalls Github](https://github.com/wirefalls/geo-nft). 
the idea was brilliant.
But this script was using the GeoIP database from [db-ip.com](https//db-ip.com).
And I wasn't happy for that for several reasons.
1. I already use the free [Maxmind GeoIP database](https://maxmind.com) with nginx
2. I prefer the [Maxmind GeoIP database](https://maxmind.com). 
I believe that it's one of the most accurate one, and all subnets are written in CIDR mode, and I personnally think it's clearer, this way

## Description
### What this script is doing ? :penguin:
1. Checks that all the programs that the script use can be accessed.
2. Create a small RamDrive to store its temporaries files to avoid storing data on HardDisks this increase spead.
3. Downloads the Maxmind Database GeoLite2-Country in csv format for IPv4 and IPv6.
and checks that the SHA256 checksumms are correct.
4. Correlates the data to create files for selected countries. Selected countries have to be mentionned according to their ISO code.
See this [webpage](https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2) for further details.
5. Create an archive files of the selected countries and store them on disk.
6. All steps are well logged and described.

## Future evolutions.
:gear: As mentioned the script is in his first stage. It hasn't reached a valid number. It's just a working file.
In a near future I plan to add the following features. 
* Taking in consideration the parameters defined in a configuration file.
* Taking in consideration command line arguments
* Setup the nft rules.
* And other ideas that will come when the scrtip evolves.

## What is expected from you.
Please use this script. Comment, improve and share your ideas.
Thanks for your help.
 
