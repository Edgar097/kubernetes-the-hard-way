#!/bin/bash
# ---- Ejemplo ----
## En master1 (el principal):
# export STATE=MASTER
# export PRIORITY=100
# sudo ./setup-haproxy-keepalived.sh
#
# -------- CONFIGURABLE VARIABLES --------
VIP="192.168.100.100"
INTERFACE="eth0"           # Verificá con `ip a`
STATE="${STATE:-MASTER}"   # MASTER o BACKUP
PRIORITY="${PRIORITY:-100}" # 100 para el nodo principal, 90/80 para los otros

echo "🔧 Instalando HAProxy y Keepalived en ${HOSTNAME}..."

apt update && apt install -y haproxy keepalived

# -------- CONFIGURACIÓN HAProxy --------
cat <<EOF > /etc/haproxy/haproxy.cfg
global
    log /dev/log    local0
    maxconn 2000
    user haproxy
    group haproxy
    daemon

defaults
    log     global
    mode    tcp
    option  tcplog
    timeout connect 10s
    timeout client  1m
    timeout server  1m

frontend kubernetes-api
    bind ${VIP}:6443
    default_backend k8s-masters

backend k8s-masters
    balance roundrobin
    server master1 192.168.100.149:6443 check
    server master2 192.168.100.150:6443 check
    server master3 192.168.100.151:6443 check
EOF

systemctl enable haproxy
systemctl restart haproxy

# -------- CONFIGURACIÓN Keepalived --------
cat <<EOF > /etc/keepalived/keepalived.conf
vrrp_instance VI_1 {
    state ${STATE}
    interface ${INTERFACE}
    virtual_router_id 51
    priority ${PRIORITY}
    advert_int 1
    authentication {
        auth_type PASS
        auth_pass 42KubeHA
    }
    virtual_ipaddress {
        ${VIP}
    }
}
EOF

systemctl enable keepalived
systemctl restart keepalived

echo "✅ Configuración completada en ${HOSTNAME}."
echo "   - VIP: ${VIP}"
echo "   - STATE: ${STATE}"
echo "   - PRIORITY: ${PRIORITY}"
