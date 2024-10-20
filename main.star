elasticsearch = import_module("./src/elasticsearch/elasticsearch_launcher.star")
kibana = import_module("./src/kibana/kibana_launcher.star")
redis_module = import_module("github.com/kurtosis-tech/redis-package/main.star")
mongodb_module = import_module("./src/mongodb/mongodb_launcher.star")
rabbitmq_module = import_module("github.com/kurtosis-tech/rabbitmq-package/main.star")
zookeeper_module = import_module("./src/zookeeper/zookeeper_launcher.star")
kafka_module = import_module("./src/kafka/kafka_launcher.star")
aefinder_dbmigrator_module = import_module("./src/aefinder/dbmigrator/dbmigrator.star")
aefinder_silo_module = import_module("./src/aefinder/silo/silo_launcher.star")
aefinder_blockchain_eventhandler_module = import_module("./src/aefinder/blockchain_eventhandler/blockchain_eventhander.star")
aefinder_eventhandler_module = import_module("./src/aefinder/eventhandler/eventhandler_launcher.star")
aefinder_authserver_module = import_module("./src/aefinder/authserver/authserver_launcher.star")
aefinder_api_module = import_module("./src/aefinder/api/api_launcher.star")
aefinder_utils_module = import_module("./src/aeindexer/utils.star")
aefinder_trmdao_indexer_module = import_module("./src/aeindexer/trmdao_indexer.star")

def run(plan, advertised_ip):
    elasticsearch_url = elasticsearch.launch_elasticsearch(plan)
    kibana.launch_kibana(plan, elasticsearch_url, "/kibana")
    redis_info = redis_module.run(plan)
    redis_url = redis_info.url
    mongodb_info = mongodb_module.run(plan, {})
    mongodb_url = mongodb_info.url
    rabbitmq_node_names = rabbitmq_module.run(plan, {
        "rabbitmq_num_nodes": 1,
        "rabbitmq_image": "rabbitmq:3.13-management",
        "rabbitmq_vhost": "/"
    })

    zookeeper_service = zookeeper_module.launch_zookeeper(plan)
    kafka_bootstrap_server_host_port = kafka_module.launch_kafka(plan)

    aefinder_dbmigrator_module.run_dbmigrator(plan, mongodb_url)

    aefinder_silo_module.launch_aefinder_silo(
        plan,
        advertised_ip,
        redis_url=redis_url, 
        mongodb_url=mongodb_url, 
        elasticsearch_url=elasticsearch_url, 
        kafka_host_port=kafka_bootstrap_server_host_port, 
        rabbitmq_node_names=rabbitmq_node_names["node_names"]
    )
    aefinder_blockchain_eventhandler_module.launch_blockchain_eventhandler(
        plan,
        redis_url,
        mongodb_url,
        rabbitmq_node_names["node_names"]
    )

    aefinder_eventhandler_module.launch_eventhandler(
        plan,
        redis_url,
        mongodb_url,
        elasticsearch_url,
        rabbitmq_node_names["node_names"]
    )

    authserver_url = aefinder_authserver_module.launch_authserver(
        plan,
        mongodb_url,
        redis_url
    )
    api_url = aefinder_api_module.launch_api(
        plan,
        authserver_url,
        redis_url,
        mongodb_url,
        elasticsearch_url,
        rabbitmq_node_names["node_names"]
    )

    aefinder_utils_module.create_org_and_user(plan, authserver_url, api_url)
    # Note: confusing usage of app_id and app_name. To avoid confusion, use app_name that aligns with app_id.
    # See: https://github.com/AeFinderProject/aefinder/blob/c1ff566e2c0ea192842d0451dbe92aa4f47ec895/src/AeFinder.Application/Apps/AppService.cs#L61-L78
    aefinder_trmdao_indexer_module.create_trmdao_indexer(plan, authserver_url, api_url, "tomorrowdao_indexer", '"TomorrowDAO Indexer"')
