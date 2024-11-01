SERVICE_NAME = "tmrdao-backend-nginx"
IMAGE_NAME = "nginx:1.27.2"
NGINX_CONF_TEMPLATE_FILE = "/static_files/tmrdao-backend/nginx/nginx.conf.template"

def launch_nginx(plan, api_url, auth_server_url, port_is_public=False):
    conf_artifact_name = plan.render_templates(
        config = {
            "nginx.conf": struct(
                template=read_file(NGINX_CONF_TEMPLATE_FILE),
                data={
                    "ApiUrl": api_url.replace("http://", ""),
                    "AuthServerUrl": auth_server_url.replace("http://", ""),
                },
            ),
        },
    )

    public_ports = {}
    if port_is_public:
        public_ports["http"] = PortSpec(number=80)

    config = ServiceConfig(
        image = IMAGE_NAME,
        ports = {
            "http": PortSpec(number = 80, transport_protocol = "TCP"),
        },
        public = public_ports,
        # Update the entrypoint to use the custom configuration file
        entrypoint=["/docker-entrypoint.sh", "nginx", "-c", "/config/nginx.conf"],
        files = {
            "/config": conf_artifact_name,
        },
    )

    plan.add_service(SERVICE_NAME, config)
    return "http://{}:80".format(SERVICE_NAME)
