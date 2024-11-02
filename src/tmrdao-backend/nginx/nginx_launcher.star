SERVICE_NAME = "tmrdao-backend-nginx"
IMAGE_NAME = "nginx:1.27.2"
NGINX_CONF_TEMPLATE_FILE = "/static_files/tmrdao-backend/nginx/nginx.conf.template"
FINAL_NGINX_CONF_ARTIFACT_NAME = "final_tomorrowdao_backend_nginx_conf"

trmdao_indexer_module = import_module("/src/aeindexer/trmdao_indexer.star")

def launch_nginx(plan, indexer_url, api_url, auth_server_url, port_number=8010, port_is_public=False):
    app_version_artifact = plan.get_files_artifact(
        name = trmdao_indexer_module.APP_VERSION_ARTIFACT_NAME
    )

    raw_conf_artifact_name = plan.render_templates(
        config = {
            "nginx.conf": struct(
                template=read_file(NGINX_CONF_TEMPLATE_FILE),
                data={
                    "Port": port_number,
                    "ApiUrl": api_url.replace("http://", ""),
                    "AuthServerUrl": auth_server_url.replace("http://", ""),
                    "IndexerUrl": indexer_url.replace("http://", ""),
                },
            ),
        },
    )

    result = plan.run_sh(
        run = '''mkdir -p /app/out && \
        VERSION=$(cat /app/app_version/app_version.txt) && \
        sed "s/__APP_VERSION__/$VERSION/g" /app/raw/nginx.conf > /app/out/nginx.conf \
        ''',
        files={
            "/app/raw": raw_conf_artifact_name,
            "/app/app_version": app_version_artifact,
        },
        store= [
            StoreSpec(src = "/app/out/nginx.conf", name = FINAL_NGINX_CONF_ARTIFACT_NAME)
        ]
    )

    public_ports = {}
    if port_is_public:
        public_ports["http"] = PortSpec(number=port_number)

    config = ServiceConfig(
        image = IMAGE_NAME,
        ports = {
            "http": PortSpec(number = port_number, transport_protocol = "TCP"),
        },
        public_ports = public_ports,
        # Update the entrypoint to use the custom configuration file
        entrypoint=["/docker-entrypoint.sh", "nginx", "-c", "/config/nginx.conf"],
        files = {
            "/config": result.files_artifacts[0],
        },
    )

    plan.add_service(SERVICE_NAME, config)
    return "http://{}:80".format(SERVICE_NAME)
