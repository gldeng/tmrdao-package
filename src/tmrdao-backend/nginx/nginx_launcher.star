
SERVICE_NAME = "tmrdao-backend-nginx"
IMAGE_NAME = "nginx:1.27.2"
NGINX_CONF_TEMPLATE_FILE = "/static_files/tmrdao-backend/nginx/nginx.conf.template"

def launch_nginx(plan, api_url, auth_server_url):
    conf_artifact_name = plan.render_templates(
        config = {
            "nginx.conf": struct(
                template=read_file(NGINX_CONF_TEMPLATE_FILE),
                data={
                    "ApiUrl": api_url,
                    "AuthServerUrl": auth_server_url,
                },
            ),
        },
    )
    config = ServiceConfig(
        image = IMAGE_NAME,
        ports = {
            "http": PortSpec(number = 80, transport_protocol = "TCP"),
        },
        entrypoint=["./docker-entrypoint.sh nginx -c /config/nginx.conf"],
        files = {
            "/config": conf_artifact_name,
        },
    )

    plan.add_service(SERVICE_NAME, config)
    return "http://{}:80".format(SERVICE_NAME)