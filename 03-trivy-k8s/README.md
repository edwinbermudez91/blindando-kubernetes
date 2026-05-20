# 🛡️ Lab 03: Escaneo de Clúster y Workloads con Trivy

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
- **[Trivy CLI](https://aquasecurity.github.io/trivy/)** instalado en la misma máquina desde la que ejecutas `kubectl`. Puedes instalar la versión v0.70.0 rápidamente con este comando:
  ```bash
  curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sudo sh -s -- -b /usr/local/bin v0.70.0
  ```
- Un clúster de Kubernetes activo.
- Haber creado el namespace de laboratorio (`security-lab`):
  ```bash
  kubectl create namespace security-lab
  ```
- **(Opcional pero recomendado) [Helm](https://helm.sh/docs/intro/install/)** instalado para desplegar Trivy Operator.

### Instalación de Trivy Operator
Trivy Operator se ejecuta de forma continua en tu clúster para encontrar vulnerabilidades y malas configuraciones de forma automática, generando Custom Resources (CRDs) con los resultados. Puedes revisar su [documentación oficial aquí](https://github.com/aquasecurity/trivy-operator).

Para instalarlo usando Helm:
```bash
# Agregar el repositorio de Helm de Aqua Security
helm repo add aqua https://aquasecurity.github.io/helm-charts/
helm repo update

# Instalar Trivy Operator en el namespace trivy-system
helm install trivy-operator aqua/trivy-operator \
  --namespace trivy-system \
  --create-namespace
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
2. **Restricción de Registros de Confianza (Trusted Registries):**
   * El manifiesto seguro utiliza un nombre de imagen completamente calificado (FQIN) que especifica explícitamente el dominio de confianza: `docker.io/nginxinc/nginx-unprivileged:1.21-alpine` en lugar del valor implícito `nginxinc/...`.
   * En entornos de producción, es una buena práctica forzar que las imágenes provengan únicamente de dominios autorizados (por ejemplo, registros privados o repositorios de confianza) para prevenir ataques de suplantación de identidad (spoofing) o descargas accidentales de software malicioso.
   * Se incluye un archivo `image-policy.yaml` con una política de **Kyverno** que audita o bloquea cualquier pod que intente utilizar imágenes fuera de los registros autorizados (`docker.io`, `ghcr.io`, `gcr.io`):
     ```bash
     kubectl apply -f image-policy.yaml
     ```
   * Además, se incluye el archivo `trivy-trusted-registries-policy.yaml`, que configura el **Trivy Operator** para que reconozca los registros de confianza mediante una política Rego personalizada y deje de reportar la desconfiguración _"Container uses an image from an untrusted registry"_:
     ```bash
     kubectl apply -f trivy-trusted-registries-policy.yaml -n trivy-system
     ```
3. Aplica la versión segura del Deployment:

```bash
kubectl apply -f secure-deployment.yaml -n security-lab
```

### 6️⃣ Verificación Final (Opcional)
Vuelve a ejecutar el escaneo del paso 3. Deberías notar una reducción drástica (idealmente a cero) de las alertas de configuración y vulnerabilidades críticas.

### 7️⃣ Uso de Trivy Operator (Escaneo Continuo) 🔄
Si instalaste Trivy Operator en los prerrequisitos, este automáticamente escaneará los recursos desplegados y generará Custom Resource Definitions (CRDs) con los reportes, sin necesidad de ejecutar comandos manuales de escaneo.

1. **Asegúrate de tener la aplicación vulnerable desplegada:**
   Si la borraste en el paso anterior, vuelve a crearla:
   ```bash
   kubectl apply -f insecure-deployment.yaml -n security-lab
   ```
   *Nota: El operador puede tardar unos segundos en detectar el nuevo pod y generar el reporte.*

2. **Validar los reportes de vulnerabilidades generados:**
   El operador crea un `VulnerabilityReport` por cada ReplicaSet/Pod. Lista los reportes y observa el resumen de severidades en las columnas:
   ```bash
   kubectl get vulnerabilityreports -n security-lab -o wide
   ```

3. **Ejercicio: Extraer las vulnerabilidades CRÍTICAS**
   Vamos a analizar el reporte generado para el pod vulnerable. Primero, guarda el nombre del reporte en una variable de entorno:
   ```bash
   # Sustituye <NOMBRE_DEL_REPORTE> con el nombre que obtuviste en el comando anterior
   export REP_NAME=<NOMBRE_DEL_REPORTE>
   ```
   
   Ahora, usa `jsonpath` para extraer e imprimir únicamente los IDs de las vulnerabilidades catalogadas como críticas:
   ```bash
   kubectl get vulnerabilityreport $REP_NAME -n security-lab \
     -o jsonpath='{range .report.vulnerabilities[?(@.severity=="CRITICAL")]}{.vulnerabilityID}{"\n"}{end}'
   ```

4. **Validar los reportes de configuraciones (misconfigurations):**
   De forma similar a las vulnerabilidades de imagen, el operador evalúa los manifiestos de Kubernetes en busca de malas prácticas.
   ```bash
   kubectl get configauditreports -n security-lab -o wide
   ```

5. **Ver los detalles completos de un reporte:**
   Puedes visualizar cualquiera de los reportes en formato YAML para leer las recomendaciones exactas de remediación que ofrece Trivy.
   ```bash
   kubectl get configauditreport <NOMBRE_DEL_REPORTE_CONFIG> -n security-lab -o yaml
   ```

6. **Visualización Gráfica con Trivy Operator Dashboard (Opcional):**
   Si prefieres una interfaz gráfica interactiva en lugar de consultar la terminal, puedes instalar **Trivy Operator Dashboard**, una herramienta de la comunidad que te permite visualizar cómodamente todos los reportes de vulnerabilidades, auditorías de configuración, secretos expuestos y evaluaciones de RBAC del clúster.

   Instala el dashboard en tu clúster usando Helm:
   ```bash
   helm install trivy-operator-dashboard oci://ghcr.io/raoulx24/charts/trivy-operator-dashboard \
     --version 1.8.0 \
     --namespace trivy-system
   ```

   Existen dos opciones para acceder al dashboard:

   #### Opción A: Acceso temporal vía Port-Forward
   Como el servicio se crea por defecto de tipo `ClusterIP` en el puerto `8900`, realiza un reenvío de puertos (port-forward) para poder acceder localmente:
   ```bash
   kubectl port-forward service/trivy-operator-dashboard 8900:8900 -n trivy-system --address 0.0.0.0
   ```

   Abre tu navegador e ingresa a:
   👉 **[http://localhost:8900](http://localhost:8900)**

   #### Opción B: Exposición formal vía Gateway API 🌐 (Recomendado)
   Si ya has completado el **Lab 01: Gateway API**, puedes exponer el dashboard de forma elegante a través del Gateway del clúster usando la ruta `/trivy`:

   1. Aplica el manifiesto `trivy-dashboard-route.yaml` que asocia el Service del dashboard con el Gateway en `envoy-gateway-system`:
      ```bash
      kubectl apply -f trivy-dashboard-route.yaml
      ```
   
   2. Obtén el puerto NodePort asignado al proxy de Envoy:
      ```bash
      export NODE_PORT=$(kubectl get service -n envoy-gateway-system \
        -l gateway.envoyproxy.io/owning-gateway-name=gateway-lab \
        -o jsonpath='{.items[0].spec.ports[0].nodePort}')
      
      echo "Accede al Dashboard en: http://localhost:$NODE_PORT/trivy"
      ```
      
   3. Abre tu navegador e ingresa a la dirección web que se muestra en tu terminal (ej. `http://localhost:<NODE_PORT>/trivy`).

   ¡Listo! Explora la interfaz gráfica para auditar visualmente el estado de seguridad de tu namespace `security-lab` y el resto de recursos del clúster.


---

## 🧹 Limpieza del Laboratorio

Para mantener tu clúster ordenado y liberar recursos, elimina los despliegues de prueba y los componentes instalados durante este ejercicio:

```bash
# Eliminar despliegues, políticas y rutas del laboratorio
kubectl delete -f secure-deployment.yaml -n security-lab --ignore-not-found
kubectl delete -f insecure-deployment.yaml -n security-lab --ignore-not-found
kubectl delete -f image-policy.yaml --ignore-not-found
kubectl delete -f trivy-trusted-registries-policy.yaml -n trivy-system --ignore-not-found
kubectl delete -f trivy-dashboard-route.yaml --ignore-not-found

# (Opcional) Desinstalar Trivy Operator Dashboard y el operador
helm uninstall trivy-operator-dashboard -n trivy-system
helm uninstall trivy-operator -n trivy-system
kubectl delete namespace trivy-system --ignore-not-found
```
