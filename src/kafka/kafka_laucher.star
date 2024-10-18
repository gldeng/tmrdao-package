flink_kafka_module = import_module("github.com/kurtosis-tech/awesome-kurtosis/flink-kafka-example/kurtosis-package/main.star@7c449fea3cad317ff38dbe98aa537b08e2e0b605")



def launch_kafka(plan):
    ### Start the Kafka cluster: first Zookeeper then Kafka itself
    flink_kafka_module.create_service_zookeeper(plan, flink_kafka_module.ZOOKEEPER_SERVICE_NAME, flink_kafka_module.ZOOKEEPER_IMAGE, flink_kafka_module.ZOOKEEPER_PORT_NUMBER)
    flink_kafka_module.create_service_kafka(plan, flink_kafka_module.KAFKA_SERVICE_NAME, flink_kafka_module.ZOOKEEPER_SERVICE_NAME, flink_kafka_module.KAFKA_SERVICE_PORT_INTERNAL_NUMBER, flink_kafka_module.KAFKA_SERVICE_PORT_EXTERNAL_NUMBER)

    ### Check that the Kafka Cluster is ready:
    kafka_bootstrap_server_host_port = "%s:%d" % (flink_kafka_module.KAFKA_SERVICE_NAME, flink_kafka_module.KAFKA_SERVICE_PORT_EXTERNAL_NUMBER)
    flink_kafka_module.check_kafka_is_ready(plan, flink_kafka_module.KAFKA_SERVICE_NAME, flink_kafka_module.KAFKA_SERVICE_PORT_EXTERNAL_NUMBER)

    return kafka_bootstrap_server_host_port
