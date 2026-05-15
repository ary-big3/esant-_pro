#!/bin/bash

echo "======================================"
echo "🚀 ESANTE DOCKER FULL AUTO (COMPLETE)"
echo "======================================"

# ======================================
# 1. DOCKERFILE PHP
# ======================================

cat > Dockerfile <<'EOF'
FROM php:8.2-fpm

RUN apt-get update && apt-get install -y \
    libzip-dev unzip git \
    && docker-php-ext-install mysqli pdo pdo_mysql

RUN pecl install redis && docker-php-ext-enable redis
EOF

echo "🐘 Dockerfile OK"

# ======================================
# 2. DOCKER COMPOSE
# ======================================

cat > docker-compose.yml <<'EOF'
version: "3.9"

services:

  php:
    build: .
    container_name: esante_php
    volumes:
      - ./backend:/var/www/html
    depends_on:
      - mysql
      - redis
      - elasticsearch
    environment:
      DB_HOST: mysql
      REDIS_HOST: redis
      ELASTIC_HOST: elasticsearch

  nginx:
    image: nginx:latest
    container_name: esante_nginx
    ports:
      - "80:80"
    volumes:
      - ./backend:/var/www/html
      - ./docker/nginx/default.conf:/etc/nginx/conf.d/default.conf
    depends_on:
      - php

  mysql:
    image: mysql:8
    container_name: esante_mysql
    restart: always
    environment:
      MYSQL_ROOT_PASSWORD: root
      MYSQL_DATABASE: esante_db
    ports:
      - "3307:3306"

  redis:
    image: redis:7-alpine
    container_name: esante_redis
    restart: always
    ports:
      - "6379:6379"

  elasticsearch:
    image: docker.elastic.co/elasticsearch/elasticsearch:8.13.0
    container_name: esante_elasticsearch
    restart: always
    environment:
      - discovery.type=single-node
      - xpack.security.enabled=false
      - ES_JAVA_OPTS=-Xms512m -Xmx512m
    ports:
      - "9200:9200"

EOF

echo "🐳 docker-compose OK"

# ======================================
# 3. STOP OLD CONTAINERS
# ======================================

echo "🧹 Stop anciens containers..."
docker compose down --volumes 2>/dev/null

# ======================================
# 4. BUILD & START
# ======================================

echo "🔨 Build + Start Docker..."
docker compose up -d --build

echo "⏳ Attente services..."
sleep 15

# ======================================
# 5. BACKEND TEST FILES CREATION
# ======================================

mkdir -p backend/public

# ------------------------------
# REDIS TEST
# ------------------------------
cat > backend/public/redis-test.php <<'EOF'
<?php

try {
    $redis = new Redis();
    $redis->connect('redis', 6379);

    $redis->set("test", "Redis OK ESANTE");
    echo $redis->get("test");

} catch (Exception $e) {
    echo "Redis Error: " . $e->getMessage();
}
EOF

echo "🟢 redis-test.php créé"

# ------------------------------
# ELASTIC TEST
# ------------------------------
cat > backend/public/elastic-test.php <<'EOF'
<?php

$url = "http://elasticsearch:9200";

$response = file_get_contents($url);

echo $response;
EOF

echo "🔵 elastic-test.php créé"

# ======================================
# 6. TESTS CONTAINERS
# ======================================

echo "======================================"
echo "🧪 TEST REDIS"
echo "======================================"
docker exec esante_redis redis-cli ping

echo "======================================"
echo "🧪 TEST MYSQL"
echo "======================================"
docker exec esante_mysql mysql -uroot -proot -e "SHOW DATABASES;"

echo "======================================"
echo "🧪 TEST ELASTICSEARCH"
echo "======================================"
curl -s http://localhost:9200 | head

# ======================================
# 7. FIN
# ======================================

echo "======================================"
echo "✅ ESANTE FULL STACK READY"
echo "======================================"
echo "🌍 Redis test: http://localhost/esante/backend/public/redis-test.php"
echo "🌍 Elastic test: http://localhost/esante/backend/public/elastic-test.php"
echo "======================================"