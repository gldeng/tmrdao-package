SERVICE_NAME = "aefinder-silo"

IMAGE_NAME = "aefinder/aefinder-silo:master-202409300916"

APPSETTINGS_TEMPLATE_FILE = "/static_files/aefinder/silo/appsettings.json.template"


def launch_aefinder_silo(plan, advertised_ip, gateway_port=20001, silo_port=10001, redis_url, mongodb_url, elasticsearch_url, kafka_host_port, rabbitmq_node_names):
    rabbitmq_service = plan.get_service(rabbitmq_node_names[0])

    artifact_name = plan.render_templates(
        config = {
            "appsettings.json": struct(
                template=read_file(APPSETTINGS_TEMPLATE_FILE),
                data={
                    "AdvertisedIP": advertised_ip,
                    "GatewayPort": gateway_port,
                    "SiloPort": silo_port,
                    "RedisHostPort": redis_url.split("/")[-1],
                    "MongoDbUrl": mongodb_url,
                    "ElasticsearchUrl": elasticsearch_url,
                    "KafkaHostPort": kafka_host_port,
                    "RabbitMqHost": rabbitmq_service.hostname,
                    "RabbitMqPort": rabbitmq_service.ports["amqp"].number,
                },
            ),
        },
    )

    config = ServiceConfig(
        image = IMAGE_NAME,
        files={
            "/app/config": artifact_name,
        },
        ports={
            "gateway": PortSpec(number=gateway_port, protocol="tcp"),
            "silo": PortSpec(number=silo_port, protocol="tcp"),
        },
        public_ports={
            "gateway": gateway_port,
            "silo": silo_port,
        },
        entrypoint = [
            "/bin/sh", 
            "-c", 
            "cp /app/config/appsettings.json /app/appsettings.json && dotnet AeFinder.Silo.dll"
        ],
    )
    plan.add_service(SERVICE_NAME, config)