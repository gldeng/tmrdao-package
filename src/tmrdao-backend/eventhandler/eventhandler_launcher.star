
SERVICE_NAME = "tmrdao-backend-eventhandler"
IMAGE_NAME = "tmrdao-backend-eventhandler"
APPSETTINGS_TEMPLATE_FILE = "/static_files/tmrdao-backend/eventhandler/appsettings.json.template"
trmdao_indexer_module = import_module("/src/aeindexer/trmdao_indexer.star")

def launch_tmrdao_backend_eventhandler(
    plan,
    aelf_node_url,
    app_url,
    app_id,
    redis_url,
    mongodb_url,
    elasticsearch_url,
    kafka_host_port,
):
    raw_appsettings_artifact_name = plan.render_templates(
        config = {
            "appsettings.json": struct(
                template=read_file(APPSETTINGS_TEMPLATE_FILE),
                data={
                    "AppUrl": app_url,
                    "AppId": app_id,
                    "RedisHostPort": redis_url.split("/")[-1],
                    "MongoDbUrl": mongodb_url,
                    "ElasticsearchUrl": elasticsearch_url,
                    "AelfNodeUrl": aelf_node_url,
                    "KafkaHostPort": kafka_host_port,
                },
            ),
        },
    )


    app_version_artifact = plan.get_files_artifact(
        name = trmdao_indexer_module.APP_VERSION_ARTIFACT_NAME
    )

    final_appsettings_artifact_name = "final_appsettings_for_tmrdao_backend_eventhandler"

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
            StoreSpec(src = "/app/out/appsettings.json", name = final_appsettings_artifact_name)
        ]
    )

    config = ServiceConfig(
        image = IMAGE_NAME,
        files={
            "/app/config": result.files_artifacts[0],
        },
        entrypoint = [
            "/bin/sh", 
            "-c", 
            "cp /app/config/appsettings.json /app/appsettings.json && cat /app/appsettings.json && dotnet /app/TomorrowDAOServer.EntityEventHandler.dll"
        ],
    )
    plan.add_service(SERVICE_NAME, config)
