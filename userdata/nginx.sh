#!/bin/bash

# RPM

yum -y install --setopt=tsflags=nodocs https://nginx.org/packages/rhel/7/x86_64/RPMS/nginx-1.16.0-1.el7.ngx.x86_64.rpm
rm -f /usr/share/nginx/html/* || true
cp -v /mnt/*jar /usr/share/nginx/html/ || true

# START

cat <<EOF > /etc/nginx/nginx-container.conf
daemon off;
user  nginx;
worker_processes  auto;

error_log  /dev/sdterr;
pid        /var/run/nginx.pid;

events {
    worker_connections  1024;
}

http {
    include       /etc/nginx/mime.types;
    default_type  application/octet-stream;

  log_format main
    '\${remote_addr}\t\${host}\t\${request_method}\t\${request_uri}\t\${server_protocol}'
    '\t\${http_referer}\t\${http_x_mobile_group}'
    '\tLocal:\t\${status}\t*\${connection}\t\${body_bytes_sent}\t\${request_time}'
    '\tProxy:\t\${upstream_addr}\t\${upstream_status}\t-'
    '\t\${upstream_response_length}\t\${upstream_response_time}\t\${uri}'
    '\tAgent:\t\${http_user_agent}'
    '\tFwd:\t\${http_x_forwarded_for}'
    '\tSSL:\t\${http2}\t\${ssl_server_name}\t\${ssl_session_id}\t\${ssl_session_reused}\t\${ssl_protocol}\t\${ssl_cipher}'
    ;

    access_log  /dev/stdout  main;
    sendfile        on;
    tcp_nopush     on;
    keepalive_timeout  65;

    server {
        listen       80;
        server_name  localhost;

        location / {
            root   /usr/share/nginx/html;
            autoindex on;
            autoindex_exact_size off;
            autoindex_localtime off;
            autoindex_format json;
        }

        error_page   500 502 503 504  /50x.html;
        location = /50x.html {
            root   /usr/share/nginx/html;
        }
    }
}
EOF

nginx -c /etc/nginx/nginx-container.conf

#EOF
