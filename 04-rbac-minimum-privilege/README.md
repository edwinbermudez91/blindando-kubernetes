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

---

## 🧹 Limpieza del Laboratorio

Para revertir los cambios realizados:

```bash
kubectl delete pod test-pod -n security-lab --ignore-not-found
kubectl delete -f ns-readonly-rolebinding.yaml --ignore-not-found
kubectl delete -f ns-readonly-role.yaml --ignore-not-found
kubectl delete serviceaccount viewer -n security-lab --ignore-not-found
```
