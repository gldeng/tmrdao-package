SERVICE_NAME = "kafka1"
IMAGE_NAME = "wurstmeister/kafka"
KAFKA_PORT = 9091
ZOOKEEPER_SERVICE_NAME = "zookeeper"
ZOOKEEPER_PORT = 2181

def launch_kafka(plan):
    zookeeper_service = plan.get_service(ZOOKEEPER_SERVICE_NAME)

    config = ServiceConfig(
        image = IMAGE_NAME,
        ports = {
            "kafka": PortSpec(KAFKA_PORT),
        },
        public_ports = {
            "kafka": PortSpec(KAFKA_PORT),
        },
        env_vars = {
            "KAFKA_BROKER_ID": "0",
            "KAFKA_ZOOKEEPER_CONNECT": f"{zookeeper_service.hostname}:{ZOOKEEPER_PORT}/kafka",
            "KAFKA_ADVERTISED_LISTENERS": f"PLAINTEXT://{SERVICE_NAME}:{KAFKA_PORT}",
            "KAFKA_LISTENERS": f"PLAINTEXT://0.0.0.0:{KAFKA_PORT}",
            "TZ": "UTC",  # This replaces the volume mount for /etc/localtime
        },
    )
    
    kafka_service = plan.add_service(SERVICE_NAME, config)
    
    # Wait for Kafka to be ready
    plan.wait(
        recipe=ExecRecipe(
            command=["/bin/sh", "-c", f"kafka-topics.sh --bootstrap-server localhost:{KAFKA_PORT} --list"],
        ),
        field="code",
        assertion="==",
        target_value=0,
        timeout="2m",
        service_name=SERVICE_NAME,
    )

    return f"{kafka_service.hostname}:{KAFKA_PORT}"
