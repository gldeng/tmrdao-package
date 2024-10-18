SERVICE_NAME = "elasticsearch"

IMAGE_NAME = "docker.elastic.co/elasticsearch/elasticsearch:7.15.1"


def get_config():
    return ServiceConfig(
        image = IMAGE_NAME,
        ports = {
            "http": PortSpec(9200)
        },
        env_vars = {
            "ES_JAVA_OPTS": "-Xms1g -Xmx4g",
            "network.host": "0.0.0.0",
            "transport.host": "0.0.0.0",
            "http.host": "0.0.0.0",
            "cluster.routing.allocation.disk.threshold_enabled": "false",
            "discovery.type": "single-node",
            "xpack.security.authc.anonymous.roles": "remote_monitoring_collector",
            "xpack.security.authc.realms.file.file1.order": "0",
            "xpack.security.authc.realms.native.native1.order": "1",
            "xpack.security.enabled": "false",
            "xpack.license.self_generated.type": "trial",
            "xpack.security.authc.token.enabled": "false",
            "xpack.security.authc.api_key.enabled": "false",
            "action.destructive_requires_name": "false",
        },
    )


def launch_elasticsearch(plan):
    plan.add_service(SERVICE_NAME, get_config())
