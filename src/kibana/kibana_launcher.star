SERVICE_NAME = "kibana"


KIBANA_YML_ARTIFACT_PATH = "/configs/kibana/kibana.yml"
KIBANA_YML_ARTIFACT_NAME = "kibana_yml"

def launch_kibana(plan, elasticsearch_url, base_path=""):
    plan.add_service(
        name = SERVICE_NAME,
        config = get_config(plan, elasticsearch_url, base_path)
    )

def get_config(plan, elasticsearch_url, base_path=""):

    files = {}
    if base_path:
        kibana_yml = get_kibana_config_file(plan=plan, base_path=base_path)
        files["/usr/share/kibana/config/kibana.yml"] = kibana_yml

    return ServiceConfig(
        image = "docker.elastic.co/kibana/kibana:7.14.2",
        ports = {
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
            KIBANA_YML_ARTIFACT_PATH: struct(
                template='server.basePath: "{{.base_path}}"\nserver.rewriteBasePath: true',
                data={
                    base_path: base_path
                },
            ),
        },
        name = KIBANA_YML_ARTIFACT_NAME,
        description = "Kibana configuration"  
    )

    return kibana_yml
