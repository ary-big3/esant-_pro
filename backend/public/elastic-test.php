<?php

require __DIR__ . '/../config/elasticsearch.php';

$elastic = new ElasticClient();

echo json_encode($elastic->client()->info()->asArray());
