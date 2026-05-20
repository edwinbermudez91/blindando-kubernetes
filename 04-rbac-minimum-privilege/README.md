# 🔐 Lab 04: Control de Acceso Basado en Roles (RBAC) y Mínimo Privilegio

¡Adéntrate en el mundo de la autorización en Kubernetes! 🧭 En este laboratorio pondremos en práctica el principio de **Mínimo Privilegio**. Crearás un **Role** con permisos estrictamente de solo lectura (`read-only`) para un namespace específico y lo asignarás a una **ServiceAccount** mediante un **RoleBinding**.

---

## 🎯 Objetivos de Aprendizaje

- Comprender la diferencia entre un `Role` y un `ClusterRole`.
- Crear una `ServiceAccount` dedicada para aplicaciones o usuarios.
- Implementar restricciones de acceso efectivas utilizando RBAC.
- Validar experimentalmente las restricciones de permisos simulando acciones prohibidas.

---

## 🛠️ Instrucciones Paso a Paso

### 1️⃣ Preparación del Entorno
Comencemos asegurando que nuestro espacio de trabajo (`namespace`) esté listo.

```bash
# Crear el namespace si no existe
kubectl create namespace security-lab || true
```

### 2️⃣ Creación de la Identidad (ServiceAccount)
En Kubernetes, los pods y procesos interactúan con la API usando una `ServiceAccount`. Vamos a crear una llamada `viewer`.

```bash
kubectl create serviceaccount viewer -n security-lab
```

### 3️⃣ Aplicar Políticas de Solo Lectura
A continuación, definimos *qué* se puede hacer (Role) y *quién* puede hacerlo (RoleBinding).

```bash
# Aplica el Role con permisos de lectura (get, list, watch)
kubectl apply -f ns-readonly-role.yaml

# Asocia el Role a nuestra ServiceAccount 'viewer'
kubectl apply -f ns-readonly-rolebinding.yaml
```

### 4️⃣ Poblar el Namespace con Datos
Para poder probar los permisos de lectura, necesitamos recursos en el namespace. Puedes desplegar algunos pods y servicios de prueba, por ejemplo usando el Deployment inseguro del Lab 03 o cualquier imagen básica (como Nginx).

```bash
# Ejemplo rápido para crear un Pod de prueba
kubectl run test-pod --image=nginx -n security-lab
```

### 5️⃣ Verificación de Privilegios 🕵️‍♂️
Vamos a suplantar (impersonar) a la ServiceAccount `viewer` para comprobar si las reglas de RBAC funcionan correctamente. Kubernetes permite hacer esto usando el flag `--as`.

**✅ Prueba de Lectura (Debe funcionar):**
```bash
kubectl get pods -n security-lab --as=system:serviceaccount:security-lab:viewer
```
> Deberías ver la lista de pods sin ningún problema.

**❌ Prueba de Escritura/Borrado (Debe fallar):**
```bash
kubectl delete pod test-pod -n security-lab --as=system:serviceaccount:security-lab:viewer
```
> **🎯 Éxito!** Deberías recibir un mensaje de error tipo `Forbidden: User cannot delete resource...`, demostrando que el RBAC bloqueó la acción.

### 6️⃣ Ampliando Permisos con ClusterRole y ClusterRoleBinding
Un `Role` está limitado a un namespace, pero a veces necesitas dar acceso a recursos que no pertenecen a ningún namespace (como los `Nodes`) o a recursos a través de todos los namespaces. Para esto usamos `ClusterRole` y `ClusterRoleBinding`.

Vamos a darle permiso a nuestra `ServiceAccount` para listar los nodos del clúster.

```bash
# Aplica el ClusterRole (permisos sobre nodos)
kubectl apply -f cluster-node-reader-clusterrole.yaml

# Aplica el ClusterRoleBinding (enlaza el ClusterRole a la ServiceAccount viewer)
kubectl apply -f cluster-node-reader-clusterrolebinding.yaml
```

**✅ Prueba de Lectura de Nodos:**
```bash
kubectl get nodes --as=system:serviceaccount:security-lab:viewer
```
> Deberías poder ver los nodos del clúster. Intenta listar un recurso global al que no le diste acceso (como `namespaces`), ¡y verás que sigue denegado!

### 7️⃣ El Peligro del Token por Defecto (Ataque Simulado)

Antes de asegurar nuestros pods deshabilitando el montaje de tokens, veamos qué sucede cuando un contenedor es vulnerado y tiene una `ServiceAccount` con permisos excesivos (en este caso, permisos totales). Por defecto, Kubernetes monta el token de la ServiceAccount en todos los pods.

Vamos a crear un secreto de prueba que el atacante intentará robar, una `ServiceAccount` llamada `hacker`, un `Role` con permisos totales en el namespace (que permite editar roles, secretos, etc.), y un `RoleBinding`.

```bash
# Crear un secreto valioso de prueba
kubectl create secret generic valioso-secreto --from-literal=password=supersecreto123 -n security-lab

# Crear la ServiceAccount 'hacker'
kubectl create serviceaccount hacker -n security-lab

# Crear y aplicar un Role con permisos amplios (puede hacer de todo en el namespace)
kubectl apply -f hacker/hacker-role.yaml

# Vincular el Role a la ServiceAccount
kubectl apply -f hacker/hacker-rolebinding.yaml
```

Luego, desplegaremos un pod malicioso (con una imagen de Ubuntu) que usará esta ServiceAccount, simulando una aplicación vulnerada:

```bash
kubectl apply -f hacker/hacker-pod.yaml
```

Una vez que el pod esté en ejecución, vamos a simular que somos el atacante que ha obtenido ejecución remota de código (RCE) dentro del contenedor. Entraremos al pod e instalaremos `curl` para poder interactuar con la API:

```bash
# Entrar al pod
kubectl exec -it hacker-pod -n security-lab -- bash

# (Dentro del pod) Actualizar repositorios e instalar curl
apt-get update && apt-get install -y curl
```

Dentro del contenedor, extraeremos el token que Kubernetes montó automáticamente y configuraremos algunas variables de entorno para comunicarnos con la API de Kubernetes:

```bash
# Extraer el token y el certificado de la CA
TOKEN=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)
CACERT=/var/run/secrets/kubernetes.io/serviceaccount/ca.crt

# Revelar los secretos del namespace
curl -s --cacert $CACERT -H "Authorization: Bearer $TOKEN" https://kubernetes.default.svc/api/v1/namespaces/security-lab/secrets
```
> **😱 ¡Peligro!** Al ejecutar esto, verás la información de todos los secretos en el namespace (incluyendo `valioso-secreto`) porque la ServiceAccount montada tiene los permisos para hacerlo.

Ahora, demostraremos que también podemos escalar el ataque o modificar el clúster creando un secreto de prueba malicioso usando la API:

```bash
# Crear un secreto usando la API REST de Kubernetes
curl -s -X POST --cacert $CACERT -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" -d '{"apiVersion":"v1","kind":"Secret","metadata":{"name":"pwned-secret"},"type":"Opaque","stringData":{"pwned":"true"}}' https://kubernetes.default.svc/api/v1/namespaces/security-lab/secrets

# Verificar que el secreto se creó exitosamente (debe aparecer 'pwned-secret')
curl -s --cacert $CACERT -H "Authorization: Bearer $TOKEN" https://kubernetes.default.svc/api/v1/namespaces/security-lab/secrets | grep pwned-secret

# Salir del pod atacado
exit
```
> **🎯 Éxito para el atacante:** Se ha demostrado cómo un token montado automáticamente, combinado con exceso de privilegios (como editar roles o gestionar secretos), permite a un atacante tomar control de los recursos del namespace y escalar su ataque.

### 8️⃣ Deshabilitar el Montaje Automático del Token (automountServiceAccountToken)

Por defecto, Kubernetes monta automáticamente el token de la `ServiceAccount` dentro de todos los pods en la ruta `/var/run/secrets/kubernetes.io/serviceaccount`. Si una aplicación es comprometida, un atacante puede usar este token para interactuar con la API de Kubernetes (como acabamos de ver en el ataque simulado).

Como mejor práctica de **Mínimo Privilegio**, si tu aplicación **no** necesita comunicarse con la API de Kubernetes, debes deshabilitar este montaje automático.

El archivo `pod-automount-test.yaml` muestra cómo hacerlo configurando explícitamente `automountServiceAccountToken: false`.

```bash
# Aplica el pod con el montaje de token deshabilitado
kubectl apply -f pod-automount-test.yaml

# Verifica si el token fue montado (Debe fallar porque no existe el directorio)
kubectl exec -it automount-test -n security-lab -- ls /var/run/secrets/kubernetes.io/serviceaccount
```
> **🎯 Éxito!** Recibirás un error indicando `No such file or directory` o similar. Esto garantiza que, incluso si un atacante toma control del contenedor, no tendrá credenciales pre-inyectadas para escalar privilegios en el clúster.

---

## 🧹 Limpieza del Laboratorio

Para revertir los cambios realizados:

```bash
kubectl delete pod test-pod hacker-pod -n security-lab --ignore-not-found
kubectl delete -f pod-automount-test.yaml --ignore-not-found
kubectl delete -f hacker/hacker-rolebinding.yaml --ignore-not-found
kubectl delete -f hacker/hacker-role.yaml --ignore-not-found
kubectl delete secret valioso-secreto pwned-secret -n security-lab --ignore-not-found
kubectl delete -f ns-readonly-rolebinding.yaml --ignore-not-found
kubectl delete -f ns-readonly-role.yaml --ignore-not-found
kubectl delete -f cluster-node-reader-clusterrolebinding.yaml --ignore-not-found
kubectl delete -f cluster-node-reader-clusterrole.yaml --ignore-not-found
kubectl delete serviceaccount viewer hacker -n security-lab --ignore-not-found
```
