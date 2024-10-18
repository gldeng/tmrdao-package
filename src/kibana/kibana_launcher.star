SERVICE_NAME = "kibana"


def get_config(elasticsearch_url):
    return ServiceConfig(
        image = "docker.elastic.co/kibana/kibana:7.14.2",
        ports = {
            "http": PortSpec(5601, transport_protocol = "TCP")
        },
        env_vars = {
            "ELASTICSEARCH_HOSTS": elasticsearch_url
        },
    )


def launch_kibana(plan, elasticsearch_url):
    plan.add_service(
        name = SERVICE_NAME,
        config = get_config(elasticsearch_url)
    )
