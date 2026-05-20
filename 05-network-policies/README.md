# 🕸️ Lab 05: Aislamiento de Red con NetworkPolicies

¡Bienvenido a la defensa en profundidad a nivel de red! 🧱 Por defecto, los pods en Kubernetes pueden comunicarse libremente entre sí. En este laboratorio, desplegaremos un escenario compuesto por un `frontend`, un `backend` y un pod malicioso (`attacker`). Utilizaremos **NetworkPolicies** para bloquear el tráfico no deseado y aplicar el principio de *Zero Trust* en nuestra red.

---

## 🎯 Objetivos de Aprendizaje

- Entender el comportamiento por defecto (flat network) de Kubernetes.
- Aislar componentes críticos aplicando políticas *Default Deny* (Denegar todo).
- Permitir tráfico legítimo explícitamente usando selectores de pods (`podSelector`).
- Comprobar la efectividad del aislamiento de red frente a intentos de conexión no autorizados.

---

## ⚙️ Prerrequisitos

> **⚠️ Importante:** Para que las NetworkPolicies surtan efecto, tu clúster de Kubernetes debe tener instalado un plugin de red (CNI) que las soporte, como **Calico**, **Cilium** o **Weave Net**. Si usas minikube o kind con su configuración básica, las reglas podrían no aplicarse.

---

## 🛠️ Instrucciones Paso a Paso

### 1️⃣ Preparación del Entorno
Garantizamos la existencia del namespace de laboratorio.

```bash
kubectl create namespace security-lab || true
```

### 2️⃣ Despliegue del Escenario Inicial
Vamos a simular una aplicación web clásica y a un actor malintencionado en el mismo clúster.

```bash
# Desplegamos la aplicación legítima (Frontend y Backend)
kubectl apply -f frontend-backend.yaml -n security-lab

# Desplegamos el pod atacante
kubectl apply -f attacker-pod.yaml -n security-lab

# Comprobamos que todos estén corriendo (Running)
kubectl get pods -n security-lab -o wide
```

### 3️⃣ Verificación de Conectividad Abierta 🔓
Comprobemos que, sin políticas de red, todos pueden hablar con el backend.

**Desde el Frontend:**
```bash
kubectl exec -n security-lab -it deployments/frontend -- curl -s http://backend-svc
```
> Deberías recibir una respuesta correcta.

**Desde el Atacante:**
```bash
kubectl exec -it attacker -n security-lab -- curl -s http://backend-svc
```
> El atacante también recibe respuesta. ¡Esto es un riesgo de seguridad enorme!

### 4️⃣ Aislamiento del Backend (Deny-All) 🛑
Aplicamos una política restrictiva: prohibimos **todo** el tráfico de entrada al backend.

```bash
kubectl apply -f backend-deny-all.yaml -n security-lab
```
> *Prueba a ejecutar el `curl` desde el frontend ahora; se quedará colgado (timeout) porque está bloqueado.*

### 5️⃣ Apertura Controlada (Allow-Frontend) ✅
Ahora creamos una excepción explícita que permite el tráfico *únicamente* desde pods etiquetados como `frontend`.

```bash
kubectl apply -f backend-allow-frontend.yaml -n security-lab
```

### 6️⃣ Verificación de Aislamiento Efectivo 🛡️
Volvamos a probar la conectividad para confirmar que nuestra política funciona.

**✅ Frontend al Backend (Debe Funcionar):**
```bash
kubectl exec -it deployments/frontend -n security-lab -- curl -s http://backend-svc
```

**❌ Atacante al Backend (Debe Fallar/Timeout):**
```bash
kubectl exec -it attacker -n security-lab -- curl --max-time 3 http://backend-svc
```
> El atacante ya no puede acceder al backend. ¡Hemos protegido la aplicación!

---

## 🧹 Limpieza del Laboratorio

Deja el entorno limpio para el siguiente ejercicio:

```bash
kubectl delete -f backend-allow-frontend.yaml -n security-lab --ignore-not-found
kubectl delete -f backend-deny-all.yaml -n security-lab --ignore-not-found
kubectl delete -f attacker-pod.yaml -n security-lab --ignore-not-found
kubectl delete -f frontend-backend.yaml -n security-lab --ignore-not-found
```
