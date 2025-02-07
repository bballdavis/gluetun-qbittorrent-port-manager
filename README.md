# gluetun-qbittorrent Port Manager
Automatically updates the listening port for qbittorrent to the port forwarded by [Gluetun](https://github.com/qdm12/gluetun/).

## Description
This is my fork of [patrickaclark's](https://github.com/patrickaclark) (which is a fork of [snoringdragon's](https://github.com/SnoringDragon)) gluetun qbittorrent port forward update tool.  

[Gluetun](https://github.com/qdm12/gluetun/) has the ability to forward ports for supported VPN providers, but qbittorrent does not have the ability to update its listening port dynamically.

With Gluetun slow depricating access to both the file method (snoringdragon) and unauthorized API access, I modified the script by [patrickaclark](https://github.com/patrickaclark)  to reach out to the [Gluetun](https://github.com/qdm12/gluetun/) control server API with an Api key for authorization and updates the qbittorrent's listening port based on the response.  Once the port is updated, it then reaches out and has QBitorrent reannounce all torrents to the trackers.

## Setup
First, ensure you are able to successfully connect qbittorrent to the forwarded port manually (can be seen by a green globe at the bottom of the WebUI).

Second, ensure the [Gluetun](https://github.com/qdm12/gluetun/) control server port (default 8000) is exposed in your compose file. 

Third, ensure that you have correctly setup the route path and API key for Gluetun ([link](https://github.com/qdm12/gluetun-wiki/blob/main/setup/advanced/control-server.md#openvpn-and-wireguard)).  An example config TOML has also been provided ([link](https://github.com/bballdavis/gluetun-qbittorrent-port-manager/blob/main/config.toml)).

Finally, insert the template in `docker-compose.yml` into your docker-compose containing gluetun, substituting the default values for your own.
