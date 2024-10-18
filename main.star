
elasticsearch = import_module("./src/elasticsearch/elasticsearch_launcher.star")
kibana = import_module("./src/kibana/kibana_launcher.star")
redis_module = import_module("github.com/kurtosis-tech/redis-package/main.star")
mongodb_module = import_module("github.com/kurtosis-tech/mongodb-package/main.star")
rabbitmq_module = import_module("github.com/kurtosis-tech/rabbitmq-package/main.star")
kafka_module = import_module("./src/kafka/kafka_launcher.star")
aefinder_silo_module = import_module("./src/aefinder/silo/silo_launcher.star")

def run(plan):
    elasticsearch_url = elasticsearch.launch_elasticsearch(plan)
    kibana.launch_kibana(plan, elasticsearch_url, "/kibana")
    redis_info = redis_module.run(plan)
    redis_url = redis_info.url
    mongodb_info = mongodb_module.run(plan, {})
    mongodb_url = mongodb_info.url
    rabbitmq_node_names = rabbitmq_module.run(plan, {
        "rabbitmq_num_nodes": 1,
        "rabbitmq_image": "rabbitmq:3.13-management"
    })
    # TODO: Prefix management ui
    kafka_bootstrap_server_host_port = kafka_module.launch_kafka(plan)

    aefinder_silo_module.launch_aefinder_silo(
        plan,
        redis_url, 
        mongodb_url, 
        elasticsearch_url, 
        kafka_bootstrap_server_host_port, 
        rabbitmq_node_names
    )
