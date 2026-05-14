# 🛡️ Lab 02: Escaneo de Clúster y Workloads con Trivy

¡Bienvenido al laboratorio de escaneo de vulnerabilidades y configuraciones! 🚀 En este laboratorio aprenderás a utilizar **Trivy**, una potente herramienta open-source, para escanear tu clúster de Kubernetes y un Deployment de prueba. El objetivo es identificar vulnerabilidades de software y malas prácticas de configuración (misconfigurations) antes de que un atacante pueda explotarlas.

---

## 🎯 Objetivos de Aprendizaje

- Ejecutar escaneos de vulnerabilidades en imágenes de contenedores desplegadas.
- Detectar configuraciones inseguras en manifiestos de Kubernetes (falta de límites, privilegios excesivos, etc.).
- Filtrar reportes de seguridad para centrarse en riesgos críticos.
- Aplicar correcciones de seguridad (hardening) a un Deployment.

---

## ⚙️ Prerrequisitos

Antes de comenzar, asegúrate de tener lo siguiente:
- [Trivy](https://aquasecurity.github.io/trivy/) instalado en la misma máquina desde la que ejecutas `kubectl`.
- Un clúster de Kubernetes activo.
- Haber creado el namespace de laboratorio (`security-lab`):
  ```bash
  kubectl create namespace security-lab
  ```

---

## 🛠️ Instrucciones Paso a Paso

### 1️⃣ Desplegar una aplicación vulnerable
Primero, vamos a simular un escenario real desplegando un Deployment configurado de forma intencionalmente insegura.

```bash
# Aplicamos el manifiesto vulnerable
kubectl apply -f insecure-deployment.yaml -n security-lab

# Verificamos que el pod esté corriendo
kubectl get pods -n security-lab
```

### 2️⃣ Escaneo general del clúster
Trivy permite obtener una visión panorámica del estado de seguridad de todo el clúster.

```bash
trivy k8s --report summary
```
> **💡 Tip:** Observa la cantidad de vulnerabilidades detectadas en los distintos namespaces y componentes base de Kubernetes.

### 3️⃣ Escaneo detallado por Namespace
Para no saturarnos con información, enfoquémonos únicamente en nuestro laboratorio y en las vulnerabilidades de mayor impacto.

```bash
trivy k8s --namespace security-lab --severity HIGH,CRITICAL --report all
```

### 4️⃣ Análisis de Resultados 🔍
Examina detalladamente la salida del comando anterior. Busca lo siguiente:
- **Vulnerabilidades (CVEs):** Fallos de seguridad conocidos en la imagen base del contenedor.
- **Misconfigurations:** Configuraciones riesgosas en el manifiesto de Kubernetes, como la falta de un `securityContext`, permisos excesivos (`capabilities`), o la ausencia de límites de recursos.

### 5️⃣ Remediación y Hardening 🛡️
Es hora de corregir los problemas encontrados.

1. Abre y revisa el archivo `secure-deployment.yaml`. Nota las diferencias respecto al manifiesto inseguro (uso de `securityContext`, recursos definidos, etc.).
2. Aplica la versión segura del Deployment:

```bash
kubectl apply -f secure-deployment.yaml -n security-lab
```

### 6️⃣ Verificación Final (Opcional)
Vuelve a ejecutar el escaneo del paso 3. Deberías notar una reducción drástica (idealmente a cero) de las alertas de configuración y vulnerabilidades críticas.

---

## 🧹 Limpieza del Laboratorio

Para mantener tu clúster ordenado, elimina los recursos creados durante este ejercicio:

```bash
kubectl delete -f secure-deployment.yaml -n security-lab --ignore-not-found
kubectl delete -f insecure-deployment.yaml -n security-lab --ignore-not-found
```
