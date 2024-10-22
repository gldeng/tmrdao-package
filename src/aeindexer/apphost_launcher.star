SERVICE_NAME = "apphost"
APPSETTINGS_TEMPLATE_FILE = "/static_files/aeindexer/appsettings.json.template"
IMAGE_NAME = "aefinder/aefinder-app-host:master-202410020747"
trmdao_indexer_module = import_module("./trmdao_indexer.star")

def launch_apphost(
    plan,
    aelf_node_url,
    api_url,
    mongodb_url,
    elasticsearch_url,
    kafka_host_port,
    rabbitmq_node_names,
    port_number=8800
):
    rabbitmq_service = plan.get_service(rabbitmq_node_names[0])

    raw_appsettings_artifact_name = plan.render_templates(
        config = {
            "appsettings.json": struct(
                template=read_file(APPSETTINGS_TEMPLATE_FILE),
                data={
                    "AelfNodeUrl": aelf_node_url,
                    "ApiUrl": api_url,
                    "MongoDbUrl": mongodb_url,
                    "ElasticsearchUrl": elasticsearch_url,
                    "KafkaHostPort": kafka_host_port,
                    "RabbitMqHost": rabbitmq_service.hostname,
                    "RabbitMqPort": rabbitmq_service.ports["amqp"].number,
                    "Port": port_number,
                },
            ),
        },
    )

    app_version_artifact = plan.get_files_artifact(
        name = trmdao_indexer_module.APP_VERSION_ARTIFACT_NAME
    )

    final_appsettings_artifact_name = "final_appsettings_for_apphost"

    result = plan.run_sh(
        run = "VERSION=$(cat /app/app_version/app_version.txt) && jq --arg version \"$VERSION\" '.AppInfo.Version = $version' -i /app/raw/appsettings.json > /app/out/appsettings.json",
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
        ports={
            "http": PortSpec(number=port_number),
        },
        entrypoint = [
            "/bin/sh", 
            "-c", 
            "cp /app/config/appsettings.json /app/appsettings.json && cat /app/appsettings.json && dotnet /app/AeFinder.App.Host.dll"
        ],
    )
    plan.add_service(SERVICE_NAME, config)