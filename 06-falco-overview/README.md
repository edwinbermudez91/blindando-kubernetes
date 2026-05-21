# 🦅 Lab 06: Detección de Amenazas en Tiempo de Ejecución con Falco (Simulación de Crypto-Mining)

¡Llegamos a la fase de monitoreo de seguridad en tiempo real! 🚨 En este laboratorio utilizaremos **Falco**, considerado la "Cámara de Seguridad" de Kubernetes. Falco analiza las llamadas al sistema (syscalls) a nivel del kernel de Linux en tiempo real para detectar comportamientos anómalos o maliciosos en tus contenedores.

Para hacer este laboratorio más realista y de nivel profesional, **diseñaremos y cargaremos una regla personalizada** en Falco capaz de detectar un contenedor malicioso que simula realizar actividades de minería de criptomonedas (Cryptomining) y conexión a un pool de minería usando el protocolo **Stratum**.

---

## 🎯 Objetivos de Aprendizaje

- Entender el concepto de Seguridad en Tiempo de Ejecución (*Runtime Security*).
- Crear y cargar **reglas de seguridad personalizadas** en Falco utilizando archivos de valores de Helm (`values.yaml`).
- Desplegar un Pod simulando una intrusión maliciosa (Crypto-Miner seguro).
- Identificar y auditar alertas críticas de severidad `CRITICAL` en los logs en tiempo real.

---

## ⚙️ Prerrequisitos

- [Helm 3](https://helm.sh/docs/intro/install/) instalado localmente.
- Un clúster de Kubernetes con permisos de administrador (ya que Falco se ejecuta como un DaemonSet con privilegios en cada nodo para leer las llamadas al sistema a nivel de kernel).

---

## 🛠️ Instrucciones Paso a Paso

### 1️⃣ Análisis de la Regla Personalizada (`falco-values.yaml`)

Hemos preparado el archivo `falco-values.yaml` para indicarle a Helm que configure una regla personalizada dentro del motor de Falco. Abre [falco-values.yaml](file:///Users/ehbc/Labs/repos/Blindando-Kubernetes/06-falco-overview/falco-values.yaml) para revisarla:

```yaml
customRules:
  custom-miner-rules.yaml: |-
    # Define una lista reutilizable de nombres conocidos de software minero
    - list: crypto_miner_names
      items: [xmrig, minerd, cpuminer, xmr-stak, cgminer, sgminer]
      
    # Regla personalizada para interceptar cryptominers y mineria fileless
    - rule: Miner de Criptomonedas Detectado
      desc: Detecta la ejecucion de procesos con nombres conocidos de software de mineria de cryptos.
      condition: >
        spawned_process and
        container and
        (proc.name in (crypto_miner_names) or proc.cmdline contains "stratum+tcp")
      output: >
        ALERTA CRITICA: Se ha detectado un proceso de mineria de criptomonedas o conexion a pool Stratum
        (usuario=%user.name pod=%k8s.pod.name namespaces=%k8s.ns.name proc=%proc.name comando=%proc.cmdline contenedor=%container.id)
      priority: CRITICAL
      tags: [process, malware, k8s, mitre_execution]
```

> **🔍 ¿Cómo funciona la regla?**
> * `list: crypto_miner_names`: Almacenamos un conjunto de procesos maliciosos en una lista de Falco (una macro) para mantener la regla limpia y mantenible.
> * `spawned_process`: Asegura que el disparador sea la llamada de sistema `execve` (cuando se inicia un proceso nuevo en el SO).
> * `container`: Garantiza que la alerta ocurra estrictamente dentro de un contenedor, evitando falsos positivos si un proceso legitimo del host coincidiera.
> * `proc.name in (crypto_miner_names)` o `proc.cmdline contains "stratum+tcp"`: Inspecciona si el binario que se ejecuta se llama como un minero, O si los comandos inyectados hacen un intento de conectarse a un pool *Stratum* (permitiendo cazar ataques 'fileless' en intérpretes de shell).

---

### 2️⃣ Instalación de Falco con Reglas Personalizadas (vía Helm)

Instalaremos Falco en su propio namespace e inyectaremos nuestro archivo de valores personalizados para que Falco cargue la regla automáticamente.

```bash
# 1. Añadimos el repositorio de Falco
helm repo add falcosecurity https://falcosecurity.github.io/charts
helm repo update

# 2. Instalamos Falco junto con el dashboard visual (Falcosidekick-UI) y nuestra regla personalizada
helm install falco falcosecurity/falco \
  --namespace falco \
  --create-namespace \
  -f falco-values.yaml \
  --set falcosidekick.enabled=true \
  --set falcosidekick.webui.enabled=true \
  --set falcosidekick.webui.redis.storageEnabled=false
```

---

### 3️⃣ Verificación del Despliegue

Espera a que los pods de Falco se encuentren en estado `Running`. Dado que Falco descarga o compila dinámicamente un driver del kernel (eBPF o módulo del kernel) para interceptar llamadas al sistema, puede tardar hasta un par de minutos.

```bash
kubectl get pods -n falco -o wide -w
```
*(Presiona `Ctrl+C` para salir del modo "watch" cuando estén listos y saludables)*

---

### 4️⃣ Despliegue del Atacante (Simulación de Crypto-Miner via Deployment)

Ahora crearemos un Namespace de seguridad y desplegaremos el controlador que simulará ser el atacante. 

Revisa el archivo [miner-pod.yaml](file:///Users/ehbc/Labs/repos/Blindando-Kubernetes/06-falco-overview/miner-pod.yaml). Para simular el ataque de forma 100% segura y controlada (sin descargar software malicioso ni minar criptomonedas reales), el `Deployment` clona internamente el binario inofensivo de `bash`, lo renombra como `xmrig` y lo mantiene activo en memoria indefinidamente (`sleep infinity`) inyectándole parámetros falsos de minería *Stratum*. 
Esto asegura que Falco tenga tiempo de sobra para enganchar la llamada al sistema y recolectar toda la metadata de K8s:

```bash
# Crear el namespace si no existe
kubectl create namespace security-lab || true

# Desplegar el simulador de minería
kubectl apply -f miner-deploy.yaml -n security-lab
```

---

### 5️⃣ Análisis de Alertas en Tiempo Real 🚨

Dado que nuestro pod simulador de minería ejecutará de inmediato el binario renombrado y llamará a un pool Stratum ficticio, Falco deberá capturar las llamadas al sistema e imprimir alertas de alta prioridad. Tienes dos formas excelentes de visualizar estos ataques:

#### Opción A: A través de Consola (Logs Planos)
Auditemos los logs de los pods de Falco buscando específicamente el término de nuestra regla personalizada (`CRITICA`):

```bash
# Filtrar y observar alertas en tiempo real desde tu terminal
kubectl logs -n falco -l app.kubernetes.io/name=falco --tail=100 -f | grep -i "ALERTA CRITICA"
```

```bash
# Observar las alertas en tiempo real desde tu terminal
kubectl logs -n falco -l app.kubernetes.io/name=falco --tail=100 -f
```

#### Opción B: A través de Dashboard Gráfico (Falcosidekick-UI)
Durante la instalación habilitamos la UI de Falcosidekick. Para acceder al panel visual y ver métricas avanzadas y gráficos de las alertas:

```bash
# 1. Abre un tunel seguro hacia el servicio de la UI
kubectl port-forward svc/falco-falcosidekick-ui -n falco --address 0.0.0.0 2802:2802
```

**2. Accede desde tu navegador web:**
* **URL:** [http://localhost:2802](http://localhost:2802)
* **Usuario:** `admin`
* **Contraseña:** `admin`

*(Allí verás gráficos de torta por nivel de severidad y el flujo de alertas de malware organizado de forma elegante).*

#### Opción C: A través del Gateway API (Ruta /falco)
Si desplegaste el entorno base con el Gateway API, puedes exponer la interfaz web utilizando el archivo preconfigurado `falco-httproute.yaml`. Este manifiesto enruta el tráfico que entra por `/falco` (y sus recursos estáticos) directamente hacia el pod de Falcosidekick.

```bash
# Aplica la regla de enrutamiento HTTPRoute
kubectl apply -f falco-httproute.yaml
```

**Accede desde tu navegador web:**
* **URL:** `http://<IP-O-URL-DEL-GATEWAY>/falco` *(Si usas un laboratorio web como iximiuz, simplemente añade `/falco` a la URL base de tu entorno en el puerto por defecto 80/443).*
* **Usuario:** `admin`
* **Contraseña:** `admin`

> **🎯 ¡Victoria de Seguridad!**
> Deberías ver una salida como esta en los logs de Falco:
> ```text
> 18:44:20.123456789: Critical ALERTA CRITICA: Se ha detectado un proceso de mineria de criptomonedas o conexion a pool Stratum (usuario=root pod=crypto-miner namespaces=security-lab proc=xmrig comando=xmrig -c sleep 3600 --url stratum+tcp://pool.supportxmr.com:3333 --user 44AFFq... --pass x contenedor=d12a3b4c5e6f)
> ```
> ¡El motor de seguridad de Falco detectó la ejecución del binario simulado y los parámetros de conexión maliciosos exactamente como configuramos en la regla personalizada!

---

## 🧹 Limpieza del Laboratorio

Para revertir todos los cambios realizados y desinstalar las herramientas:

```bash
# Eliminar el pod malicioso
kubectl delete -f miner-pod.yaml -n security-lab --ignore-not-found

# Desinstalar Falco del clúster
helm uninstall falco -n falco || true
kubectl delete namespace falco --ignore-not-found
```
