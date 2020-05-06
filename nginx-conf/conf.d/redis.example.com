server {
  listen         80;
  server_name    redis.example.com;
  return         301 https://$server_name$request_uri;
}

server {
  server_name  redis.example.com;
  
  include example_auth;
  include example_ssl;

  client_max_body_size 10M;
 
  root  /home/user/repo/phpRedisAdmin;
  index  index.php;

  access_log /var/log/nginx/access.log;
  error_log /var/log/nginx/error.log;

  if (-f $document_root/maintenance_on.html) {
    return 503;
  }
  error_page 503 @maintenance;
  location @maintenance {
    rewrite ^(.*)$ /maintenance_on.html break;
  }

  location ~ ^/(angular-app/|css/|img/|js/|atp/|fonts/|favicon.ico) {
    access_log off;
    expires max;
  }

  location / {
    try_files $uri $uri/ /index.php?$args;
  }

  location ~ \.php$ {
    try_files $uri =404;
    include /etc/nginx/fastcgi_params;
    fastcgi_pass    127.0.0.1:9000;
    fastcgi_index   index.php;
    fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
    fastcgi_buffer_size 16k;
    fastcgi_buffers 4 16k;
#    client_max_body_size 10M;
   }

}