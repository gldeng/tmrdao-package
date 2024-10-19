SERVICE_NAME = "zookeeper"
IMAGE_NAME = "wurstmeister/zookeeper"
ZOOKEEPER_PORT = 2181

def launch_zookeeper(plan):
    config = ServiceConfig(
        image = IMAGE_NAME,
        ports = {
            "zookeeper": PortSpec(ZOOKEEPER_PORT),
        },
        public_ports = {
            "zookeeper": PortSpec(ZOOKEEPER_PORT),
        },
        env_vars = {
            "TZ": "UTC",  # This replaces the volume mount for /etc/localtime
        },
    )
    
    zookeeper_service = plan.add_service(SERVICE_NAME, config)
    
    # Wait for Zookeeper to be ready
    plan.wait(
        recipe=ExecRecipe(
            command=["/bin/sh", "-c", "echo ruok | nc localhost 2181 | grep imok"],
        ),
        field="code",
        assertion="==",
        target_value=0,
        timeout="60s",
        service_name=SERVICE_NAME,
    )

    return zookeeper_service
