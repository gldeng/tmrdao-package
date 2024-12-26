aelf_infra_module = import_module("github.com/gldeng/aelf-infra-package/main.star")
aelf_node_module = import_module("github.com/gldeng/aelf-node-package/aelf_node.star")
aefinder_module = import_module("github.com/gldeng/aefinder-package/aefinder.star")
relayer_module = import_module("github.com/gldeng/zk-vote-relayer-package/zkvoterelayer.star")
tmrdao_module = import_module("/tmrdao.star")
tmrdao_initialize_module = import_module("/src/scripts/intialize.star")
init_kibana_module = import_module("/src/scripts/init_kibana.star")

def run(plan, advertised_ip):
    output = {}
    aelf_infra_output = aelf_infra_module.run(
        plan,
        need_mongodb=True,
        need_redis=True,
        need_rabbitmq=True,
        need_elasticsearch=True,
        need_kafka=True,
        need_kibana=True
    )
    output |= aelf_infra_output

    aefinder_output = aefinder_module.run(
        plan,
        advertised_ip,
        mongodb_url=aelf_infra_output["mongodb_url"],
        redis_url=aelf_infra_output["redis_url"],
        elasticsearch_url=aelf_infra_output["elasticsearch_url"],
        kafka_host_port=aelf_infra_output["kafka_host_port"],
        rabbitmq_node_names=aelf_infra_output["rabbitmq_node_names"]
    )
    output |= aefinder_output

    # Run aelf node after aefinder is up so that aefinder can process messages sent from aelf node
    aelf_node_output = aelf_node_module.run(
        plan,
        with_aefinder_feeder=True,
        redis_url=aelf_infra_output["redis_url"],
        rabbitmq_node_hostname=aelf_infra_output["rabbitmq_node_hostname"],
        rabbitmq_node_port=aelf_infra_output["rabbitmq_node_port"]
    )
    output |= aelf_node_output

    relayer_output = relayer_module.run(
        plan,
        advertised_ip=advertised_ip,
        mongodb_url=output["mongodb_url"],
        redis_url=output["redis_url"],
        aelf_node_url=output["aelf_node_url"]
    )
    output |= relayer_output

    tmrdao_output = tmrdao_module.run(
        plan,
        advertised_ip=advertised_ip,
        authserver_url=output["authserver_url"],
        api_url=output["api_url"],
        aelf_node_url=output["aelf_node_url"],
        redis_url=output["redis_url"],
        mongodb_url=output["mongodb_url"],
        elasticsearch_url=output["elasticsearch_url"],
        kafka_host_port=output["kafka_host_port"],
        rabbitmq_node_names=output["rabbitmq_node_names"]
    )
    output |= tmrdao_output

    tmrdao_initialize_module.run(
        plan,
        aelf_node_url=output["aelf_node_url"]
    )
    init_kibana_module.run(plan)

    return output