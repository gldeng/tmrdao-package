
shared_utils = import_module("./src/shared_utils/shared_utils.star")

SERVICE_NAME = "elasticsearch"

IMAGE_NAME = "docker.elastic.co/elasticsearch/elasticsearch:7.15.1"

HTTP_PORT_ID = "http"
HTTP_PORT_NUMBER_UINT16 = 9200

USED_PORTS = {
    HTTP_PORT_ID: shared_utils.new_port_spec(
        HTTP_PORT_NUMBER_UINT16,
        shared_utils.TCP_PROTOCOL,
        shared_utils.HTTP_APPLICATION_PROTOCOL,
    )
}

def get_config():
    return ServiceConfig(
        image = IMAGE_NAME,
        ports = USED_PORTS,
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
