# Nginx

Docker image for [Nginx] version 1.28.

Built from [libops/isle-buildkit nginx-php84](https://github.com/libops/buildkit/tree/main/images/nginx-php84)

Please refer to the [Nginx Documentation] for more in-depth information.

Acts as the Nginx web server layer for PHP based services. It extends the
[`libops/php:8.4`](../php84/README.md) image, so PHP-FPM settings are inherited
from that image.

## Dependencies

Requires `libops/php:8.4` Docker image to build. Please refer to the
[PHP 8.4 Image README](../php84/README.md) for additional information.

## Settings

> N.B. For all of the settings below images that descend from
> ``libops/nginx`` will apply prefix to every setting. So for example
> `NGINX_ERROR_LOG_LEVEL` would become `DRUPAL_NGINX_ERROR_LOG_LEVEL` this is to allow for
> different settings on a per-service basis.

| Environment Variable          | Default         | Description                                                                           |
| :---------------------------- | :-------------- | :------------------------------------------------------------------------------------ |
| NGINX_CLIENT_BODY_TIMEOUT     | 60s             | Timeout for reading client request body                                               |
| NGINX_CLIENT_MAX_BODY_SIZE    | 1m              | Specifies the maximum accepted body size of a client request                          |
| NGINX_ERROR_LOG_LEVEL         | warn            | Log Level of Error log                                                                |
| NGINX_FASTCGI_CONNECT_TIMEOUT | 60s             | Timeout for establishing a connection with a FastCGI server                           |
| NGINX_FASTCGI_READ_TIMEOUT    | 60s             | Timeout for reading a response from the FastCGI server                                |
| NGINX_FASTCGI_SEND_TIMEOUT    | 60s             | Timeout for transmitting a request to the FastCGI server.                             |
| NGINX_KEEPALIVE_TIMEOUT       | 75s             | Timeout for keep-alive connections                                                    |
| NGINX_LINGERING_TIMEOUT       | 5s              | The maximum waiting time for more client data to arrive                               |
| NGINX_PROXY_CONNECT_TIMEOUT   | 60s             | Timeout for establishing a connection with a proxied server                           |
| NGINX_PROXY_READ_TIMEOUT      | 60s             | Timeout for reading a response from the proxied server                                |
| NGINX_PROXY_SEND_TIMEOUT      | 60s             | Timeout for transmitting a request to the proxied server                              |
| NGINX_REAL_IP_HEADER          | X-Forwarded-For | Request header field whose value will be used to replace the client address.          |
| NGINX_REAL_IP_RECURSIVE       | off             | See https://nginx.org/en/docs/http/ngx_http_realip_module.html         |
| NGINX_SEND_TIMEOUT            | 60s             | Timeout for transmitting a response to the client                                     |
| NGINX_SET_REAL_IP_FROM        | 172.0.0.0/8     | Trusted addresses that are known to send correct replacement addresses                |
| NGINX_SET_REAL_IP_FROM2       | 172.0.0.0/8     | Trusted addresses that are known to send correct replacement addresses                |
| NGINX_SET_REAL_IP_FROM3       | 172.0.0.0/8     | Trusted addresses that are known to send correct replacement addresses                |
| NGINX_WORKER_CONNECTIONS      | 1024            | The maximum number of simultaneous connections that can be opened by a worker process |
| NGINX_WORKER_PROCESSES        | auto            | Set number of worker processes automatically based on number of CPU cores             |

[Nginx Documentation]: https://nginx.org/en/docs/
[Nginx Logging]: https://docs.nginx.com/nginx/admin-guide/monitoring/logging/
[Nginx]: https://www.nginx.com/
