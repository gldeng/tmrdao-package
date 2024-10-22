SERVICE_NAME = "tmrdao-silo"

IMAGE_NAME = "gldeng/tomorrowdaoserver.silo:sha-5d1c36e"

APPSETTINGS_TEMPLATE_FILE = "/static_files/tmrdao-backend/silo/appsettings.json.template"

trmdao_indexer_module = import_module("./../indexer/indexer_launcher.star")

def launch_tmrdao_silo(
    plan, 
    aelf_node_url,
    app_url,
    app_id,
    advertised_ip,
    redis_url,
    mongodb_url,
    elasticsearch_url,
    kafka_host_port,
    rabbitmq_node_names,
    gateway_port=20011,
    silo_port=10011
):
    rabbitmq_service = plan.get_service(rabbitmq_node_names[0])

    raw_appsettings_artifact_name = plan.render_templates(
        config = {
            "appsettings.json": struct(
                template=read_file(APPSETTINGS_TEMPLATE_FILE),
                data={
                    "AppUrl": app_url,
                    "AppId": app_id,
                    "AdvertisedIP": advertised_ip,
                    "GatewayPort": gateway_port,
                    "SiloPort": silo_port,
                    "RedisHostPort": redis_url.split("/")[-1],
                    "MongoDbUrl": mongodb_url,
                    "ElasticsearchUrl": elasticsearch_url,
                    "RabbitMqHost": rabbitmq_service.hostname,
                    "RabbitMqPort": rabbitmq_service.ports["amqp"].number,
                    "AelfNodeUrl": aelf_node_url,
                },
            ),
        },
    )


    app_version_artifact = plan.get_files_artifact(
        name = trmdao_indexer_module.APP_VERSION_ARTIFACT_NAME
    )

    final_appsettings_artifact_name = "final_appsettings_for_tmrdao_backend_silo"

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
        ports={
            "gateway": PortSpec(number=gateway_port),
            "silo": PortSpec(number=silo_port),
        },
        public_ports={
            "gateway": PortSpec(number=gateway_port),
            "silo": PortSpec(number=silo_port),
        },
        entrypoint = [
            "/bin/sh", 
            "-c", 
            "cp /app/config/appsettings.json /app/appsettings.json && cat /app/appsettings.json && dotnet /app/TomorrowDAOServer.Silo.dll"
        ],
    )
    plan.add_service(SERVICE_NAME, config)
