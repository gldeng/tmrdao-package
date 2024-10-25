
SERVICE_NAME = "tmrdao-backend-authserver"
IMAGE_NAME = "gldeng/tomorrowdaoserver.authserver:sha-2b896ac"
APPSETTINGS_TEMPLATE_FILE = "/static_files/tmrdao-backend/authserver/appsettings.json.template"
FINAL_APPSSETTINGS_ARTIFACT_NAME = "final_appsettings_for_tmrdao_backend_authserver"

trmdao_indexer_module = import_module("/src/aeindexer/trmdao_indexer.star")

def launch_tmrdao_backend_authserver(
    plan,
    aelf_node_url, 
    app_url, 
    app_id,    
    redis_url,
    mongodb_url,
    elasticsearch_url,
    rabbitmq_node_names,
    port=8011
):
    rabbitmq_service = plan.get_service(rabbitmq_node_names[0])

    raw_appsettings_artifact_name = plan.render_templates(
        config = {
            "appsettings.json": struct(
                template=read_file(APPSETTINGS_TEMPLATE_FILE),
                data={
                    "AelfNodeUrl": aelf_node_url,
                    "AppUrl": app_url,
                    "AppId": app_id,
                    "Host": SERVICE_NAME,
                    "Port": port,
                    "RedisHostPort": redis_url.split("/")[-1],
                    "MongoDbUrl": mongodb_url,
                    "ElasticsearchUrl": elasticsearch_url,
                    "RabbitMqHost": rabbitmq_service.hostname,
                    "RabbitMqPort": rabbitmq_service.ports["amqp"].number,
                },
            ),
        },
    )


    app_version_artifact = plan.get_files_artifact(
        name = trmdao_indexer_module.APP_VERSION_ARTIFACT_NAME
    )

    result = plan.run_sh(
        run = '''mkdir -p /app/out && \
        VERSION=$(cat /app/app_version/app_version.txt) && \
        sed "s/__APP_VERSION__/$VERSION/g" /app/raw/appsettings.json > /app/out/appsettings.json \
        ''',
        files={
            "/app/raw": raw_appsettings_artifact_name,
            "/app/app_version": app_version_artifact,
        },
        store= [
            StoreSpec(src = "/app/out/appsettings.json", name = FINAL_APPSSETTINGS_ARTIFACT_NAME)
        ]
    )

    config = ServiceConfig(
        image = IMAGE_NAME,
        files={
            "/app/config": result.files_artifacts[0],
        },
        ports={
            "http": PortSpec(number=port),
        },
        entrypoint = [
            "/bin/sh", 
            "-c", 
            "cp /app/config/appsettings.json /app/appsettings.json && cat /app/appsettings.json && dotnet /app/TomorrowDAOServer.AuthServer.dll"
        ],
    )
    plan.add_service(SERVICE_NAME, config)
    return "http://{host}:{port}".format(host=SERVICE_NAME, port=port)