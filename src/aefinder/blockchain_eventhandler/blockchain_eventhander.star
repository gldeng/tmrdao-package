
SERVICE_NAME = "aefinder-blockchain-eventhandler"
IMAGE_NAME = "aefinder/aefinder-blockchaineventhandler:master-202409300921"
APPSETTINGS_TEMPLATE_FILE = "/static_files/aefinder/blockchain_eventhandler/appsettings.json.template"


def launch_blockchain_eventhandler(
    plan,
    redis_url,
    mongodb_url,
    elasticsearch_url,
    kafka_host_port,
    rabbitmq_node_names
):
    rabbitmq_service = plan.get_service(rabbitmq_node_names[0])

    artifact_name = plan.render_templates(
        config = {
            "appsettings.json": struct(
                template=read_file(APPSETTINGS_TEMPLATE_FILE),
                data={
                    "RedisHostPort": redis_url.split("/")[-1],
                    "MongoDbUrl": mongodb_url,
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
        entrypoint = [
            "/bin/sh", 
            "-c", 
            "cp /app/config/appsettings.json /app/appsettings.json && cat /app/appsettings.json && dotnet AeFinder.Silo.dll"
        ],
    )
    plan.add_service(SERVICE_NAME, config)