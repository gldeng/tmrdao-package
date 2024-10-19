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
            "KAFKA_ZOOKEEPER_CONNECT": "{hostname}:{port}/kafka".format(
                hostname=zookeeper_service.hostname,
                port=ZOOKEEPER_PORT
            ),
            "KAFKA_ADVERTISED_LISTENERS": "PLAINTEXT://{hostname}:{port}".format(
                hostname=SERVICE_NAME,
                port=KAFKA_PORT
            ),
            "KAFKA_LISTENERS": "PLAINTEXT://0.0.0.0:{port}".format(
                port=KAFKA_PORT
            ),
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

    return "{hostname}:{port}".format(
        hostname=kafka_service.hostname,
        port=KAFKA_PORT
    )
