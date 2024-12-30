#! /bin/bash
ip=$(ifconfig | awk '/inet / && !/127.0.0.1/ {print $2; exit}')
if [[ "$(uname)" == "Darwin" ]]; then
    public_ip="localhost"
else
    public_ip=$(curl -s https://ipinfo.io/ip)
fi

kurtosis run . "{\"advertised_ip\":\"$ip\", \"public_ip\":\"$public_ip\", \"gateway_token\":\"$GATEWAY_TOKEN\", \"pinata_jwt\":\"$PINATA_JWT\", \"sentry_auth_token\":\"$SENTRY_AUTH_TOKEN\"}"
