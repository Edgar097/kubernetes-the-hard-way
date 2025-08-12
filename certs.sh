#!/usr/bin/env bash

# Certificados que faltan (excluyendo los de etcd)
certs=(
  kube-api-server
  kube-controller-manager
  kube-scheduler
  admin
  service-accounts
  kube-proxy
  worker1
  worker2
  worker3
)

for i in "${certs[@]}"; do
  echo "🔧 Generando clave privada para $i..."
  openssl genrsa -out "${i}.key" 4096

  echo "📄 Generando CSR para $i..."
  openssl req -new -key "${i}.key" \
    -sha256 \
    -config ca.conf \
    -section "${i}" \
    -out "${i}.csr"

  echo "🔏 Firmando certificado para $i..."
  openssl x509 -req -days 3653 \
    -in "${i}.csr" \
    -copy_extensions copyall \
    -sha256 \
    -CA ca.crt \
    -CAkey ca.key \
    -CAcreateserial \
    -out "${i}.crt"

  echo "✅ Certificado ${i}.crt generado con éxito."
  echo "-------------------------------------------"
done
#  etcd
# openssl genrsa -out etcd-master3.key 4096

# openssl req -new -key etcd-master3.key -sha256 \
#   -config ca.conf -extensions etcd-master3_req_extensions \
#   -subj "/CN=master3" \
#   -out etcd-master3.csr

# openssl x509 -req -in etcd-master3.csr \
#   -CA ca.crt -CAkey ca.key -CAcreateserial \
#   -out etcd-master3.crt -days 3653 \
#   -extensions etcd-master3_req_extensions -extfile ca.conf

# kube-api-server

# # Paso 1: Generar la clave privada
# openssl genrsa -out kube-api-server.key 4096

# # Paso 2: Generar el CSR usando la sección adecuada del archivo de configuración
# openssl req -new -key kube-api-server.key \
#   -out kube-api-server.csr \
#   -config ca.conf \
#   -reqexts kube-api-server_req_extensions


# # Paso 3: Firmar el CSR con la CA, especificando la sección de extensiones desde el archivo
# openssl x509 -req -days 3653 \
#   -in kube-api-server.csr \
#   -CA ca.crt \
#   -CAkey ca.key \
#   -CAcreateserial \
#   -out kube-api-server.crt \
#   -extfile ca.conf \
#   -extensions kube-api-server_req_extensions

#!/usr/bin/env bash

# Certificados que faltan (excluyendo los de etcd)
# certs=(
#   kube-api-server
#   kube-controller-manager
#   kube-scheduler
#   admin
#   service-accounts
#   kube-proxy
#   worker1
#   worker2
#   worker3
# )

# for i in "${certs[@]}"; do
#   echo "🔧 Generando clave privada para $i..."
#   openssl genrsa -out "${i}.key" 4096

#   echo "📄 Generando CSR para $i..."
#   openssl req -new -key "${i}.key" \
#     -out "${i}.csr" \
#     -config ca.conf \
#     -reqexts "${i}_req_extensions"

#   echo "🔏 Firmando certificado para $i..."
#   openssl x509 -req -days 3653 \
#     -in "${i}.csr" \
#     -CA ca.crt \
#     -CAkey ca.key \
#     -CAcreateserial \
#     -out "${i}.crt" \
#     -extfile ca.conf \
#     -extensions "${i}_req_extensions"

#   echo "✅ Certificado ${i}.crt generado con éxito."
#   echo "-------------------------------------------"
# done

# scp ca.crt \
#     kube-api-server.crt kube-api-server.key \
#     service-accounts.crt service-accounts.key \
#     encryption-config.yaml \
#     kube-controller-manager.crt kube-controller-manager.key \
#     kube-scheduler.crt kube-scheduler.key \
#     kube-proxy.crt kube-proxy.key \
#     ubuntu@192.168.100.149:/var/lib/kubernetes/

scp ca.crt \
    kube-api-server.crt kube-api-server.key \
    service-accounts.crt service-accounts.key \
    encryption-config.yaml \
    kube-controller-manager.crt kube-controller-manager.key \
    kube-scheduler.crt kube-scheduler.key \
    kube-proxy.crt kube-proxy.key \
    ubuntu@master1:/var/lib/kubernetes
