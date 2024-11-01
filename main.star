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
aelfnode_module = import_module("./src/aelf-node/aelfnode_launcher.star")
apphost_module = import_module("./src/aeindexer/apphost_launcher.star")
tmrdao_backend_dbmigrator_module = import_module("./src/tmrdao-backend/dbmigrator/dbmigrator.star")
tmrdao_backend_authserver_module = import_module("./src/tmrdao-backend/authserver/authserver_launcher.star")
tmrdao_backend_silo_module = import_module("./src/tmrdao-backend/silo/silo_launcher.star")
tmrdao_backend_eventhandler_module = import_module("./src/tmrdao-backend/eventhandler/eventhandler_launcher.star")
tmrdao_backend_api_module = import_module("./src/tmrdao-backend/api/api_launcher.star")
tmrdao_backend_nginx_module = import_module("./src/tmrdao-backend/nginx/nginx_launcher.star")
tmrdao_initialize_module = import_module("./src/scripts/intialize.star")

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
    # Note: confusing usage of app_id and app_name. To avoid confusion, use app_id that aligns with app_name.
    # See: https://github.com/AeFinderProject/aefinder/blob/c1ff566e2c0ea192842d0451dbe92aa4f47ec895/src/AeFinder.Application/Apps/AppService.cs#L61-L78
    app_id = "tomorrowdao_indexer"
    app_name = '"TomorrowDAO Indexer"'
    aefinder_trmdao_indexer_module.create_trmdao_indexer(plan, authserver_url, api_url, app_id, app_name)

    aelf_node_url = aelfnode_module.launch_aelf_node(plan, redis_url, rabbitmq_node_names["node_names"])
    app_url = apphost_module.launch_apphost(plan, app_id, aelf_node_url, api_url, mongodb_url, elasticsearch_url, kafka_bootstrap_server_host_port, rabbitmq_node_names["node_names"])

    tmrdao_backend_dbmigrator_module.run_tmrdao_backend_dbmigrator(plan, mongodb_url, elasticsearch_url)
    tmrdao_backend_silo_module.launch_tmrdao_silo(plan, aelf_node_url, app_url, app_id, advertised_ip, redis_url, mongodb_url, elasticsearch_url, kafka_bootstrap_server_host_port, rabbitmq_node_names["node_names"])
    tmrdao_backend_eventhandler_module.launch_tmrdao_backend_eventhandler(plan, aelf_node_url, api_url, app_url, app_id, redis_url, mongodb_url, elasticsearch_url, kafka_bootstrap_server_host_port)
    backend_authserver_url = tmrdao_backend_authserver_module.launch_tmrdao_backend_authserver(plan, aelf_node_url, app_url, app_id, redis_url, mongodb_url, elasticsearch_url, rabbitmq_node_names["node_names"])
    backend_api_url = tmrdao_backend_api_module.launch_tmrdao_backend_api(plan, backend_authserver_url, aelf_node_url, app_url, app_id, redis_url, mongodb_url, elasticsearch_url, kafka_bootstrap_server_host_port)
    nginx_url = tmrdao_backend_nginx_module.launch_nginx(plan, backend_api_url, backend_authserver_url)

    tmrdao_initialize_module.run(plan, aelf_node_url)
