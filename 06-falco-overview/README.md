# 🦅 Lab 06: Detección de Amenazas en Tiempo de Ejecución con Falco

¡Llegamos a la fase de monitoreo y respuesta! 🚨 En esta demostración veremos **Falco** en acción. Falco es considerado el "Cámara de Seguridad" de Kubernetes: analiza las llamadas al sistema (syscalls) en tiempo real para detectar comportamientos anómalos o maliciosos en tus contenedores.

> **ℹ️ Nota:** Este laboratorio está diseñado como una demostración rápida y visual (ideal para una sesión de 60 minutos) más que como un taller profundo de escritura de reglas.

---

## 🎯 Objetivos de Aprendizaje

- Entender el concepto de Seguridad en Tiempo de Ejecución (*Runtime Security*).
- Desplegar Falco rápidamente utilizando su chart oficial de Helm.
- Provocar deliberadamente un comportamiento sospechoso (abrir una shell interactiva en un contenedor).
- Identificar y analizar las alertas generadas por Falco en los logs.

---

## ⚙️ Prerrequisitos

- [Helm 3](https://helm.sh/docs/intro/install/) instalado localmente.
- Un clúster de Kubernetes en el que tengas permisos de administrador (requiere privilegios para desplegar a nivel de nodo mediante un DaemonSet).

---

## 🛠️ Instrucciones Paso a Paso

### 1️⃣ Instalación de Falco (vía Helm)
Vamos a instalar Falco en su propio namespace utilizando el repositorio oficial de Helm.

```bash
# 1. Añadimos el repositorio de Falco
helm repo add falcosecurity https://falcosecurity.github.io/charts
helm repo update

# 2. Instalamos Falco
helm install falco falcosecurity/falco \
  --namespace falco \
  --create-namespace
```

### 2️⃣ Verificación del Despliegue
Asegúrate de que los pods de Falco (desplegados como DaemonSet en cada nodo) estén en estado `Running`. Puede tardar un par de minutos mientras compila o descarga los drivers del kernel.

```bash
kubectl get pods -n falco -o wide -w
```
*(Usa `Ctrl+C` para salir del modo "watch" cuando estén listos)*

### 3️⃣ Simulación de un Ataque 🏴‍☠️
Vamos a crear un pod legítimo y luego intentar hacer algo que, en producción, sería muy sospechoso: abrir una consola interactiva (`bash`) dentro de él.

**Paso A: Crear el pod víctima**
```bash
# Desplegamos un contenedor de Ubuntu que simplemente duerme
kubectl run demo-shell --image=ubuntu -n security-lab -- sleep 3600
```

**Paso B: Realizar la intrusión**
```bash
# Entramos al contenedor con una shell interactiva
kubectl exec -it demo-shell -n security-lab -- bash
```
*(Una vez dentro del pod, puedes ejecutar comandos como `ls -la /etc`, `cat /etc/shadow` o simplemente `exit` para salir).*

### 4️⃣ Detección y Análisis de Logs 🚨
Las reglas por defecto de Falco consideran sospechoso abrir una shell en un contenedor. Vamos a revisar sus logs para encontrar la alerta.

Abre una nueva terminal (o sal del pod) y busca la alerta en los logs de Falco:
```bash
# Buscamos eventos de Falco (puedes filtrar usando grep si hay mucho ruido)
kubectl logs -n falco -l app.kubernetes.io/name=falco | grep "Notice"
```

> **🔍 ¿Qué debes buscar?**
> Deberías ver un mensaje similar a:
> `Notice A shell was spawned in a container with an attached terminal (user=root pod=demo-shell ...)`
> ¡Falco te ha pillado in fraganti!

---

## 🧹 Limpieza del Laboratorio

Eliminemos los rastros de nuestra intrusión y desinstalemos Falco:

```bash
# Borrar el pod de prueba
kubectl delete pod demo-shell -n security-lab --ignore-not-found

# Desinstalar Falco
helm uninstall falco -n falco || true
kubectl delete namespace falco --ignore-not-found
```
