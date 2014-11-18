global
    maxconn 4096
    stats socket /var/run/haproxy.stats
defaults
    log global
    mode    http
    option  httplog
    option  dontlognull
    retries 3
    redispatch
    maxconn 2000
    contimeout  5000
    clitimeout  50000
    srvtimeout  50000

frontend http-in
    bind *:8000
    default_backend http

backend http
    option httpchk GET /hello/test?format=json
    http-check expect status 200
{{range .}}     server {{.Ip}}:{{.Port}} {{.Ip}}:{{.Port}} maxconn 100 check inter 5s rise 2 fall 1 weight 10
{{end}}

#system wide stats
listen stats :8888
   stats enable
   stats hide-version
   stats uri /
   stats realm dwww1\ statistics
   stats auth admin:g4m30n
   stats refresh 15s
        stats admin if TRUE
