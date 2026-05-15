<?php

require __DIR__ . '/../config/redis.php';

$redis = new RedisClient();

$redis->set("test", "Redis OK");

echo $redis->get("test");
