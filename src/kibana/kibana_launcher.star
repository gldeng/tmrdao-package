SERVICE_NAME = "kibana"

KIBANA_CONF_ARTIFACT_NAME = "kibana_conf"

KIBANA_YML_TEMPLATE = '''
server.host: "0"
server.shutdownTimeout: "5s"
elasticsearch.hosts: [ "http://elasticsearch:9200" ]
monitoring.ui.container.elasticsearch.enabled: true
server.basePath: "{{.base_path}}"
server.rewriteBasePath: true
'''


def launch_kibana(plan, elasticsearch_url, base_path=""):
    plan.add_service(
        name = SERVICE_NAME,
        config = get_config(plan, elasticsearch_url, base_path)
    )

def get_config(plan, elasticsearch_url, base_path=""):

    files = {}
    if base_path:
        kibana_yml = get_kibana_config_file(plan=plan, base_path=base_path)
        files["/usr/share/kibana/config"] = kibana_yml

    return ServiceConfig(
        image = "docker.elastic.co/kibana/kibana:7.14.2",
        ports = {
            "http": PortSpec(5601, transport_protocol = "TCP")
        },
        public_ports = {
            "http": PortSpec(5601, transport_protocol = "TCP")
        },
        env_vars = {
            "ELASTICSEARCH_HOSTS": elasticsearch_url,
            "SERVER_BASEPATH": base_path
        },
        files = files
    )


def get_kibana_config_file(plan, base_path):

    kibana_yml = plan.render_templates(
        config = {
            "kibana.yml": struct(
                template=KIBANA_YML_TEMPLATE,
                data={
                    base_path: base_path
                },
            ),
        },
        name = KIBANA_CONF_ARTIFACT_NAME,
        description = "Kibana configuration"  
    )

    return kibana_yml
