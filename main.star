
elasticsearch = import_module("./src/elasticsearch/elasticsearch_launcher.star")

def run(plan):
    elasticsearch.launch_elasticsearch(plan)
