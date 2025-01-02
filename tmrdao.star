aefinder_module = import_module("github.com/gldeng/aefinder-package/aefinder.star")
tmrdao_backend_dbmigrator_module = import_module("./src/tmrdao-backend/dbmigrator/dbmigrator.star")
tmrdao_backend_authserver_module = import_module("./src/tmrdao-backend/authserver/authserver_launcher.star")
tmrdao_backend_silo_module = import_module("./src/tmrdao-backend/silo/silo_launcher.star")
tmrdao_backend_eventhandler_module = import_module("./src/tmrdao-backend/eventhandler/eventhandler_launcher.star")
tmrdao_backend_api_module = import_module("./src/tmrdao-backend/api/api_launcher.star")
tmrdao_backend_nginx_module = import_module("./src/tmrdao-backend/nginx/nginx_launcher.star")


def run(
    plan,
    advertised_ip,
    public_ip,
    authserver_url,
    api_url,
    aelf_node_url,
    redis_url,
    mongodb_url,
    elasticsearch_url,
    kafka_host_port,
    rabbitmq_node_names,
    relayer_url,
    gateway_token,
    pinata_jwt,
    sentry_auth_token,
):
    dll_artifact = plan.upload_files(
        src = "/static_files/aeindexer/TomorrowDAOIndexer.dll",
        name = "tmrdao-indexer-dll",
    )
    manifest_artifact = plan.upload_files(
        src = "/static_files/aeindexer/manifest.json",
        name = "tmrdao-indexer-manifest",
    )

    app_id = "tomorrowdao_indexer"
    app_name = '"TomorrowDAO Indexer"'
    output = {}
    aefinder_apphost_output = aefinder_module.run_apphost(
        plan,
        authserver_url=authserver_url,
        api_url=api_url,
        app_id=app_id,
        app_name=app_name,
        dll_artifact=dll_artifact,
        manifest_artifact=manifest_artifact,
        aelf_node_url=aelf_node_url,
        mongodb_url=mongodb_url,
        elasticsearch_url=elasticsearch_url,
        kafka_host_port=kafka_host_port,
        rabbitmq_node_names=rabbitmq_node_names
    )
    output |= aefinder_apphost_output
    app_url = output["app_url"]

    tmrdao_backend_dbmigrator_module.run_tmrdao_backend_dbmigrator(plan, mongodb_url, elasticsearch_url)
    tmrdao_backend_silo_module.launch_tmrdao_silo(plan, aelf_node_url, app_url, app_id, advertised_ip, redis_url, mongodb_url, elasticsearch_url, kafka_host_port, rabbitmq_node_names)
    tmrdao_backend_eventhandler_module.launch_tmrdao_backend_eventhandler(plan, aelf_node_url, api_url, app_url, app_id, redis_url, mongodb_url, elasticsearch_url, kafka_host_port)
    backend_authserver_url = tmrdao_backend_authserver_module.launch_tmrdao_backend_authserver(plan, aelf_node_url, app_url, app_id, redis_url, mongodb_url, elasticsearch_url, rabbitmq_node_names)
    backend_api_url = tmrdao_backend_api_module.launch_tmrdao_backend_api(plan, backend_authserver_url, aelf_node_url, app_url, app_id, redis_url, mongodb_url, elasticsearch_url, kafka_host_port)
    nginx_url = tmrdao_backend_nginx_module.launch_nginx(plan, app_url, backend_api_url, backend_authserver_url, port_is_public=True)

    return output