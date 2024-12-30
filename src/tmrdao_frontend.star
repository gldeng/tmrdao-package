
SERVICE_NAME = "tmrdao-frontend"
IMAGE_NAME = "gldeng/tomorrowdao-interface:sha-66540df"


def run(
    plan,
    public_ip,
    aelf_node_url,
    api_server_url,
    relayer_url,
    gateway_token,
    pinata_jwt,
    sentry_auth_token,
    port=3000,
):
    public_aelf_node_url = "http://{}:{}".format(public_ip, aelf_node_url.split(":")[-1])
    public_relayer_url = "http://{}:{}".format(public_ip, relayer_url.split(":")[-1])
    public_api_server_url = "http://{}:{}".format(public_ip, api_server_url.split(":")[-1])

    config = ServiceConfig(
        image = IMAGE_NAME,
        ports={
            "http": PortSpec(number=port),
        },
        public_ports={
            "http": PortSpec(number=port),
        },
        env_vars={
            "HOSTNAME": "0.0.0.0",
            "NEXT_PUBLIC_GATEWAY_TOKEN": gateway_token,
            "NEXT_PUBLIC_PINATA_JWT":pinata_jwt,
            "SENTRY_AUTH_TOKEN": sentry_auth_token,
            "NEXT_PUBLIC_RPC_URL_AELF": public_aelf_node_url,
            "NEXT_PUBLIC_RPC_URL_TDVV": public_aelf_node_url,
            "NEXT_PUBLIC_RPC_URL_TDVW": public_aelf_node_url,
            "NEXT_PUBLIC_TX_RELAYER_URL": public_relayer_url,
            "NEXT_PUBLIC_API_SERVER_BASE": public_api_server_url,
        }
    )
    plan.add_service(SERVICE_NAME, config)
    return "http://{}:{}".format(SERVICE_NAME, port)