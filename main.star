
elasticsearch = import_module("./src/elasticsearch/elasticsearch_launcher.star")
kibana = import_module("./src/kibana/kibana_launcher.star")

def run(plan):
    elasticsearch_url = elasticsearch.launch_elasticsearch(plan)
    kibana.launch_kibana(plan, elasticsearch_url, "/kibana")
