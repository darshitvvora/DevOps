server {
  listen  80;
  server_name    standalone.example.com;
  return         301 https://$server_name$request_uri;
}

server {
  listen 443 ssl; include /etc/nginx/statsd;
  server_name standalone.example.com;
  root /home/user/repo/standalone.dist/client;


  location /api {
    client_max_body_size 20M;
    proxy_redirect off;
    proxy_set_header   X-Real-IP         $remote_addr;
    proxy_set_header   X-Forwarded-For   $proxy_add_x_forwarded_for;
    proxy_set_header   X-Forwarded-Proto $scheme;
    proxy_set_header   Host              $http_host;
    proxy_pass http://127.0.0.1:6517;
  }	

  include frontend_support;
}