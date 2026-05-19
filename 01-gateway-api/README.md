# 🌐 Lab 01: Kubernetes Gateway API — El Sucesor Moderno del Ingress

¡Bienvenido al laboratorio de **Gateway API**! 🚀 En este módulo aprenderás a instalar y configurar **Kubernetes Gateway API**, la evolución oficial del recurso `Ingress`. Esta API permite gestionar el tráfico de entrada al clúster de forma estandarizada, segura y con una clara separación de responsabilidades entre equipos de plataforma y de aplicación.

---

## 🎯 Objetivos de Aprendizaje

- Comprender por qué el Gateway API reemplaza al `Ingress` como estándar oficial de Kubernetes.
- Instalar los **CRDs de Gateway API** y el controlador **Envoy Gateway**.
- Crear y relacionar los tres recursos fundamentales: `GatewayClass`, `Gateway` y `HTTPRoute`.
- Aplicar los principios de seguridad (hardening) aprendidos en módulos anteriores a los workloads del laboratorio.
- Entender el modelo de separación de responsabilidades (RBAC orientado a recursos de red).

---

## 📖 Contexto: Gateway API vs. Ingress

| Característica              | `Ingress` (legado)                     | Gateway API (actual)                   |
|-----------------------------|----------------------------------------|----------------------------------------|
| **Configuración avanzada**  | Annotations propietarias inconsistentes | Recursos Kubernetes nativos y portables |
| **Separación de roles**     | Un solo recurso para todo              | `Gateway` (plataforma) + `Route` (app) |
| **Soporte de protocolos**   | Solo HTTP/HTTPS                        | HTTP, HTTPS, TCP, UDP, gRPC             |
| **Auditabilidad**           | Configuraciones ocultas en annotations  | Todo visible como recursos del API      |
| **Soporte a futuro**        | Sin desarrollo activo en Ingress-NGINX | Estándar oficial upstream de Kubernetes |

### Los tres recursos clave

```
[GatewayClass]  →  Define qué controlador gestiona los Gateways
    ↓
[Gateway]       →  Define el punto de entrada (puerto, protocolo, TLS)
    ↓
[HTTPRoute]     →  Define las reglas de enrutamiento hacia los Services
```

### Separación de Namespaces en este laboratorio

```
envoy-gateway-system/          ← Namespace de INFRAESTRUCTURA (equipo de plataforma)
├── EnvoyProxy                 ← Configuración del proxy (NodePort)
├── GatewayClass               ← Registro del controlador
├── Gateway                    ← Punto de entrada al clúster
└── Pods del controlador       ← envoy-gateway + envoy proxy

demo-app/                      ← Namespace de APLICACIÓN (equipo de desarrollo)
├── Deployment                 ← Aplicación Nginx con hardening
├── Service                    ← ClusterIP expone la app internamente
└── HTTPRoute                  ← Regla de enrutamiento (cross-namespace)
```

---

## ⚙️ Prerrequisitos

- Un clúster de Kubernetes activo (v1.26+).
- `kubectl` configurado y autenticado con permisos de `cluster-admin`.
- **Helm** instalado (`v3.0+`).
- Acceso a internet para descargar los CRDs y la imagen del controlador.

---

## 🛠️ Instrucciones Paso a Paso

### 1️⃣ Preparar los Namespaces

Este laboratorio utiliza **dos namespaces separados** para demostrar la separación de responsabilidades:

- **`envoy-gateway-system`**: Infraestructura de red (controlador, Gateway). Se crea automáticamente al instalar Envoy Gateway.
- **`demo-app`**: Aplicación de demostración (Deployment, Service, HTTPRoute). Se crea automáticamente al aplicar `02-demo-app.yaml`.

### 2️⃣ Instalar Envoy Gateway (Controlador + CRDs)

**Envoy Gateway** es el controlador oficial de la CNCF basado en el proxy de datos **Envoy**, el mismo utilizado internamente por Istio, Linkerd y los principales service meshes de la industria.

Su Helm chart empaqueta **todos** los CRDs necesarios: tanto los estándar de la Gateway API (`GatewayClass`, `Gateway`, `HTTPRoute`, etc.) como los propios de Envoy Gateway (`EnvoyProxy`, `SecurityPolicy`, etc.). Por lo tanto, una sola instalación configura todo lo necesario:

```bash
helm install eg oci://docker.io/envoyproxy/gateway-helm \
  --version v1.5.9 \
  --namespace envoy-gateway-system \
  --create-namespace
```

Espera a que el controlador esté listo:

```bash
kubectl wait --timeout=5m \
  -n envoy-gateway-system \
  deployment/envoy-gateway \
  --for=condition=Available
```

Verifica que los CRDs de la Gateway API se instalaron correctamente:

```bash
kubectl get crd | grep gateway.networking.k8s.io
```

Deberías ver al menos los siguientes recursos:
```
gatewayclasses.gateway.networking.k8s.io
gateways.gateway.networking.k8s.io
httproutes.gateway.networking.k8s.io
referencegrants.gateway.networking.k8s.io
grpcroutes.gateway.networking.k8s.io
```

### 3️⃣ Crear el GatewayClass y el Gateway

El manifiesto `01-gateway.yaml` crea tres recursos en el namespace de infraestructura:

- **`EnvoyProxy`**: Configura el proxy de datos de Envoy para usar un Service de tipo **NodePort** (en lugar del `LoadBalancer` por defecto), ideal para entornos de laboratorio sin proveedor de balanceo de carga.
- **`GatewayClass`**: Registra el controlador Envoy Gateway como implementación disponible y referencia la configuración del `EnvoyProxy`.
- **`Gateway`**: Define el punto de entrada al clúster. Acepta tráfico HTTP en el puerto 80 y permite `HTTPRoutes` desde **cualquier namespace** (`allowedRoutes.namespaces.from: All`).

```bash
kubectl apply -f manifests/01-gateway.yaml
```

Verifica que el `GatewayClass` fue aceptado por el controlador:

```bash
kubectl get gatewayclass
```

La columna `ACCEPTED` debe mostrar `True` para el `GatewayClass` llamado `eg`.

Verifica el estado del Gateway:

```bash
kubectl get gateway gateway-lab -n envoy-gateway-system
```

- La columna `ACCEPTED` debe mostrar `True` (el Gateway fue aceptado por Envoy Gateway).
- La columna `PROGRAMMED` puede mostrar `False` con la razón `AddressNotAssigned` — esto es **normal** en entornos de laboratorio que no cuentan con un proveedor de direcciones IP externas. El Gateway está completamente operativo y accesible vía **NodePort**.

Verifica que el pod del proxy Envoy esté corriendo:

```bash
kubectl get pods -n envoy-gateway-system
```

Deberías ver dos pods: el controlador `envoy-gateway` y el proxy de datos `envoy-envoy-gateway-system-gateway-lab-*` (ambos en estado `Running`).

### 4️⃣ Desplegar la Aplicación de Demostración

El manifiesto `02-demo-app.yaml` crea el namespace `demo-app` y despliega la aplicación dentro de él. Este Deployment aplica las buenas prácticas de *hardening* vistas en el módulo 02 (`readOnlyRootFilesystem`, `seccompProfile`, `automountServiceAccountToken: false`, etc.):

```bash
kubectl apply -f manifests/02-demo-app.yaml
```

Verifica que el Pod esté corriendo:

```bash
kubectl get pods -n demo-app
kubectl get service demo-app -n demo-app
```

### 5️⃣ Crear el HTTPRoute

El `HTTPRoute` se despliega en el namespace `demo-app` (junto a la aplicación), pero referencia al `Gateway` en `envoy-gateway-system`. Este **enrutamiento cross-namespace** es una de las ventajas clave de la Gateway API:

```bash
kubectl apply -f manifests/03-httproute.yaml
```

Verifica el estado del HTTPRoute:

```bash
kubectl get httproute -n demo-app
```

Revisa las columnas `ACCEPTED` y `RECONCILED`. Ambas deben estar en `True`.

Para ver los detalles del estado de resolución de los backends:

```bash
kubectl describe httproute demo-app-route -n demo-app
```

### 6️⃣ Probar el Enrutamiento 🧪

El manifiesto `01-gateway.yaml` incluye un recurso `EnvoyProxy` que configura el proxy de datos con un Service de tipo **NodePort** (en lugar del `LoadBalancer` por defecto), lo cual es ideal para entornos de laboratorio.

Obtén el puerto asignado por NodePort al servicio del proxy Envoy:

```bash
export NODE_PORT=$(kubectl get service -n envoy-gateway-system \
  -l gateway.envoyproxy.io/owning-gateway-name=gateway-lab \
  -o jsonpath='{.items[0].spec.ports[0].nodePort}')

echo "NodePort asignado: $NODE_PORT"
```

Realiza la prueba de conectividad:

```bash
curl -v http://localhost:$NODE_PORT/
```

Deberías recibir una respuesta HTTP 200 con la página de bienvenida de Nginx. 🎉

### 7️⃣ Ejercicio: Separación de Roles con RBAC 🔐

Uno de los beneficios clave de la Gateway API es la separación de responsabilidades. Ahora que los recursos están divididos en dos namespaces, observa cómo funciona en la práctica:

- Los **equipos de plataforma** gestionan los `GatewayClass` y `Gateway` en `envoy-gateway-system`.
- Los **equipos de aplicación** solo pueden gestionar `HTTPRoute` en su propio namespace `demo-app`.

Revisa quién puede hacer qué sobre los recursos de red:

```bash
# ¿Puede un SA de la app crear un Gateway en el namespace de infraestructura? (debería ser NO)
kubectl auth can-i create gateways \
  --namespace envoy-gateway-system \
  --as system:serviceaccount:demo-app:default

# ¿Puede crear un HTTPRoute en su propio namespace? (debería ser SÍ con permisos adecuados)
kubectl auth can-i create httproutes \
  --namespace demo-app \
  --as system:serviceaccount:demo-app:default
```

> **🔍 Reflexión:** En el modelo `Ingress` clásico, no había forma nativa de separar quién podía modificar los puntos de entrada del clúster de quién definía las rutas. Con la Gateway API, puedes otorgar permisos de `HTTPRoute` a los equipos de app sin darles acceso al `Gateway` de infraestructura. Este laboratorio demuestra exactamente esa separación con dos namespaces independientes.

---

## 🧹 Limpieza del Laboratorio

Elimina los recursos del laboratorio en orden:

```bash
# Eliminar los manifiestos del laboratorio
kubectl delete -f manifests/03-httproute.yaml --ignore-not-found
kubectl delete -f manifests/02-demo-app.yaml --ignore-not-found
kubectl delete -f manifests/01-gateway.yaml --ignore-not-found

# Eliminar el namespace de la aplicación
kubectl delete namespace demo-app --ignore-not-found

# (Opcional) Desinstalar Envoy Gateway (controlador + CRDs) y limpiar el namespace
helm uninstall eg -n envoy-gateway-system
kubectl delete namespace envoy-gateway-system --ignore-not-found
```

---

## 📚 Referencias y Recursos Adicionales

- 📖 [Documentación oficial de Kubernetes Gateway API](https://gateway-api.sigs.k8s.io/)
- 📖 [Documentación de Envoy Gateway](https://gateway.envoyproxy.io/)
- 📄 [Releases de Gateway API en GitHub](https://github.com/kubernetes-sigs/gateway-api/releases)
- 🎓 [Guía de migración de Ingress a Gateway API](https://gateway-api.sigs.k8s.io/guides/migrating-from-ingress/)
