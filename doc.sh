#!/bin/bash

echo "======================================"
echo "🚀 INSTALLATION ESANTE ULTRA COMPLETE"
echo "======================================"

BASE="/var/www/html"

# ==========================================
# UPDATE SYSTEM
# ==========================================

apt update -y

apt install -y \
curl \
git \
unzip \
zip \
nano \
libzip-dev \
libcurl4-openssl-dev

# ==========================================
# INSTALL COMPOSER
# ==========================================

if ! command -v composer &> /dev/null
then
    echo "📦 Installation Composer..."

    curl -sS https://getcomposer.org/installer | php

    mv composer.phar /usr/local/bin/composer
fi

# ==========================================
# INSTALL REDIS EXTENSION
# ==========================================

echo "⚡ Installation Redis PHP..."

apt install -y \
autoconf \
g++ \
make

yes "" | pecl install redis

echo "extension=redis.so" > /usr/local/etc/php/conf.d/redis.ini

docker-php-ext-enable redis

# ==========================================
# INSTALL PHP OPTIMIZATIONS
# ==========================================

echo "🚀 Optimisation PHP..."

cat > /usr/local/etc/php/conf.d/performance.ini <<EOL

memory_limit=512M
upload_max_filesize=64M
post_max_size=64M
max_execution_time=300

opcache.enable=1
opcache.memory_consumption=256
opcache.max_accelerated_files=20000
opcache.validate_timestamps=0
opcache.revalidate_freq=0
opcache.interned_strings_buffer=16
opcache.fast_shutdown=1

realpath_cache_size=4096K
realpath_cache_ttl=600

EOL

# ==========================================
# INSTALL ELASTICSEARCH PACKAGE
# ==========================================

echo "🔍 Installation Elasticsearch PHP..."

cd $BASE

composer require elasticsearch/elasticsearch:^8.0 -W

# ==========================================
# CREATE REDIS CONFIG
# ==========================================

echo "⚡ Création config Redis..."

cat > $BASE/config/redis.php <<EOL
<?php

class RedisClient {

    private \$redis;

    public function __construct() {

        \$this->redis = new Redis();

        \$this->redis->connect('redis', 6379);
    }

    public function set(\$key, \$value, \$ttl = 3600) {

        return \$this->redis->set(\$key, \$value, \$ttl);
    }

    public function get(\$key) {

        return \$this->redis->get(\$key);
    }
}
EOL

# ==========================================
# CREATE ELASTIC CONFIG
# ==========================================

echo "🔍 Création config Elasticsearch..."

cat > $BASE/config/elasticsearch.php <<EOL
<?php

require __DIR__ . '/../vendor/autoload.php';

use Elastic\\Elasticsearch\\ClientBuilder;

class ElasticClient {

    private \$client;

    public function __construct() {

        \$this->client = ClientBuilder::create()
            ->setHosts(['http://elasticsearch:9200'])
            ->build();
    }

    public function client() {

        return \$this->client;
    }
}
EOL

# ==========================================
# CREATE REDIS TEST
# ==========================================

echo "🧪 Création Redis Test..."

cat > $BASE/public/redis-test.php <<EOL
<?php

require __DIR__ . '/../config/redis.php';

\$redis = new RedisClient();

\$redis->set('test', 'Redis OK');

echo \$redis->get('test');
EOL

# ==========================================
# CREATE ELASTIC TEST
# ==========================================

echo "🧪 Création Elastic Test..."

cat > $BASE/public/elastic-test.php <<EOL
<?php

require __DIR__ . '/../config/elasticsearch.php';

\$elastic = new ElasticClient();

echo json_encode(
    \$elastic->client()->info()->asArray(),
    JSON_PRETTY_PRINT
);
EOL

# ==========================================
# NGINX PERFORMANCE
# ==========================================

echo "🚀 Optimisation NGINX..."

cat > /etc/nginx/conf.d/default.conf <<EOL

server {

    listen 80;

    root /var/www/html/public;

    index index.php index.html;

    client_max_body_size 64M;

    gzip on;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript;

    location / {

        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location ~ \.php$ {

        fastcgi_pass php:9000;

        fastcgi_index index.php;

        include fastcgi_params;

        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;

        fastcgi_buffers 16 16k;
        fastcgi_buffer_size 32k;
    }
}
EOL

# ==========================================
# CACHE FOLDERS
# ==========================================

mkdir -p $BASE/storage/cache
mkdir -p $BASE/storage/sessions
mkdir -p $BASE/storage/logs

chmod -R 777 $BASE/storage

# ==========================================
# FINAL
# ==========================================

echo "======================================"
echo "✅ INSTALLATION TERMINÉE"
echo "======================================"

echo ""
echo "TESTS :"
echo ""
echo "Redis :"
echo "http://localhost/redis-test.php"
echo ""
echo "Elastic :"
echo "http://localhost/elastic-test.php"
echo ""
echo "======================================"