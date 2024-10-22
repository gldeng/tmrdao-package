SERVICE_NAME = "aelf-node"
IMAGE_NAME = "gldeng/aelf-test-node@sha256:40726dd019a01d51fd186ff7ad694f4f65f24cb1d51c873ab90ac92fc77fe13c"
APPSETTINGS_TEMPLATE_FILE = "/static_files/aelf-node/appsettings.json.template"


def launch_aelf_node(
    plan, 
    redis_url,
    rabbitmq_node_names,
    port_number=8000
):
    rabbitmq_service = plan.get_service(rabbitmq_node_names[0])

    artifact_name = plan.render_templates(
        config = {
            "appsettings.json": struct(
                template=read_file(APPSETTINGS_TEMPLATE_FILE),
                data={
                    "RedisHostPort": redis_url.split("/")[-1],
                    "RabbitMqHost": rabbitmq_service.hostname,
                    "RabbitMqPort": rabbitmq_service.ports["amqp"].number,
                    "Host": SERVICE_NAME,
                    "Port": port_number,
                },
            ),
        },
    )
    plan.add_service(SERVICE_NAME, ServiceConfig(
        image=IMAGE_NAME,
        ports={
            "http": PortSpec(number=port_number),
            # "p2p": PortSpec(number=6801),
            # "grpc": PortSpec(number=5001),
        },
        files={
            "/app/config": artifact_name,
        },
        entrypoint = [
            "/bin/sh", 
            "-c", 
            "cp /app/config/* /app/ && cat /app/appsettings.json && dotnet AElf.Launcher.dll"
        ],
    ))
    return "http://{host}:{port}".format(host=SERVICE_NAME, port=port_number)