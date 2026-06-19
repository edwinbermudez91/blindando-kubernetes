# 📊 Lab 09: Monitoreo Integral del Clúster y Postura de Seguridad (Trivy + Grafana)

¡Bienvenido al laboratorio final de observabilidad! En este módulo aprenderás a instalar el estándar de la industria para monitoreo en Kubernetes: **kube-prometheus-stack**. Este conjunto de herramientas extrae y grafica automáticamente las métricas de todos tus nodos y pods. Además, integraremos los resultados de seguridad del **Lab 03 (Trivy)** para tener un único dashboard que combine rendimiento y seguridad.

---

## 🎯 Objetivos de Aprendizaje

- Instalar y configurar `kube-prometheus-stack` mediante Helm.
- Explorar los dashboards de Grafana que vienen preconfigurados para monitorear el estado global del clúster (CPU, Memoria, Red por Pod y Nodo).
- Exponer Grafana usando el Gateway API del Lab 01.
- Conectar **Trivy Operator** a Prometheus mediante un `ServiceMonitor`.
- Importar y utilizar el Dashboard oficial de Trivy en Grafana para visualizar vulnerabilidades y configuraciones inseguras (kube-bench) en tiempo real.

---

## ⚙️ Prerrequisitos

- Un clúster de Kubernetes activo.
- [Helm](https://helm.sh/docs/intro/install/) instalado.
- Haber completado el **Lab 03 (Trivy Operator)**, de modo que el namespace `trivy-system` ya exista y el operador esté corriendo.
- (Opcional) Haber completado el **Lab 01 (Gateway API)** para exponer Grafana a través de Envoy.

---

## 🛠️ Instrucciones Paso a Paso

### 1️⃣ Instalar kube-prometheus-stack
Primero, descargamos el stack oficial de la comunidad. Este Helm chart instala Prometheus, Grafana, Alertmanager y exportadores clave como `node-exporter` (métricas de servidores físicos/máquinas virtuales) y `kube-state-metrics` (métricas de objetos de Kubernetes).

```bash
# Agregar el repositorio de Prometheus a Helm
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Crear un namespace dedicado para monitoreo
kubectl create namespace monitoring

# Instalar el stack con nuestros valores personalizados
helm install kube-prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  -f values-prometheus.yaml
```

Verifica que todos los componentes se estén iniciando:
```bash
kubectl get pods -n monitoring
```

### 2️⃣ Acceso a Grafana y Monitoreo del Clúster 📈
Existen dos formas de acceder al dashboard de Grafana.

#### Opción A: Port-Forward (Local)
```bash
kubectl port-forward service/kube-prometheus-grafana 3000:80 -n monitoring --address 0.0.0.0
```
Abre tu navegador en `http://localhost:3000/grafana/` o utiliza el botón de "Acceso a puertos" si estás en un entorno de laboratorio en la nube.
*(Usuario: `admin`, Contraseña: `prom-operator`).*

#### Opción B: Gateway API (Recomendado)
Si tienes `envoy-gateway` configurado, expón Grafana a través de un `HTTPRoute`:

1. Aplica el manifiesto de la ruta que expone Grafana bajo el prefijo `/grafana`:
   ```bash
   kubectl apply -f grafana-route.yaml
   ```
2. Obtén el puerto de tu Gateway:
   ```bash
   export NODE_PORT=$(kubectl get service -n envoy-gateway-system -l gateway.envoyproxy.io/owning-gateway-name=gateway-lab -o jsonpath='{.items[0].spec.ports[0].nodePort}')
   echo "Accede a Grafana en: http://localhost:$NODE_PORT/grafana/"
   ```

**🌟 Explora tu Clúster:** 
Una vez en Grafana, ve al menú **Dashboards** > **General**. Abre el dashboard **"Kubernetes / Compute Resources / Cluster"**. ¡Todo tu clúster ya está siendo monitoreado de caja! Puedes ver el uso de CPU y memoria de todos tus Pods y Nodos.

### 3️⃣ Integración de Seguridad: Trivy + Grafana 🛡️
Ahora conectaremos los escaneos de seguridad y cumplimiento (CIS benchmarks/kube-bench) que hace Trivy Operator, para visualizarlos aquí mismo.

1. **Crear el ServiceMonitor para Trivy:**
   Aplicaremos una regla que le dice a Prometheus que comience a raspar las métricas expuestas por el Trivy Operator.
   ```bash
   kubectl apply -f trivy-servicemonitor.yaml
   ```
   *Nota: Prometheus detectará este nuevo ServiceMonitor automáticamente gracias a la configuración en `values-prometheus.yaml`.*

2. **Importar el Dashboard de Trivy en Grafana:**
   - En la interfaz de Grafana, ve al menú lateral izquierdo, haz clic en el ícono del símbolo **"+"** y selecciona **Import**.
   - En la casilla que dice *Import via grafana.com*, escribe el ID **`17813`** (o `17214`) y presiona el botón **Load**.
   - En la siguiente pantalla, selecciona **Prometheus** en el menú desplegable que aparece en la parte inferior y haz clic en **Import**.

**¡Magia! ✨** 
Ahora tienes un panel interactivo que te muestra exactamente cuántas vulnerabilidades Críticas y Altas hay en tu clúster, y un resumen de las malas configuraciones descubiertas por la lógica interna de kube-bench. Todo centralizado.

---

## 🧹 Limpieza del Laboratorio

Para eliminar los recursos creados:

```bash
kubectl delete -f trivy-servicemonitor.yaml --ignore-not-found
kubectl delete -f grafana-route.yaml --ignore-not-found
helm uninstall kube-prometheus -n monitoring
kubectl delete namespace monitoring
```
