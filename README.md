<div align="center">

# 🛡️ Blindando Kubernetes: Seguridad, Auditoría y Control Total

[![Kubernetes Security](https://img.shields.io/badge/Kubernetes-Security_&_Hardening-326CE5?style=for-the-badge&logo=kubernetes&logoColor=white)](./02-kube-bench/README.md)
[![Envoy Gateway](https://img.shields.io/badge/Gateway_API-Envoy_Gateway-F8C517?style=for-the-badge&logo=envoyproxy&logoColor=black)](./01-gateway-api/README.md)
[![Trivy & Falco](https://img.shields.io/badge/SecOps-Trivy_•_Falco_•_Sealed_Secrets-D32F2F?style=for-the-badge&logo=aquasecurity&logoColor=white)](./03-trivy-k8s/README.md)
[![Observabilidad](https://img.shields.io/badge/Observabilidad-Prometheus_&_Grafana-F46800?style=for-the-badge&logo=grafana&logoColor=white)](./09-monitoring-prometheus-grafana/README.md)
[![Instructor](https://img.shields.io/badge/Autor-Edwin_Bermúdez-0A66C2?style=for-the-badge&logo=linkedin&logoColor=white)](https://www.linkedin.com/in/edwin-bermudez-cuervo)
[![License: MIT](https://img.shields.io/badge/License-MIT-16A34A?style=for-the-badge)](./LICENSE)

¡Bienvenido al repositorio oficial de laboratorios prácticos de **"Blindando Kubernetes: Seguridad, Auditoría y Control Total del Clúster"**! 🚀

Este repositorio está diseñado como una guía interactiva y paso a paso de **Defensa en Profundidad (Defense-in-Depth)** para que experimentes de primera mano con las herramientas estándar de la CNCF y las mejores prácticas de seguridad (*CKS / Hardening*) en entornos de producción.

</div>

---

## 🏗️ Arquitectura de Defensa en Profundidad (Los 9 Módulos)

```mermaid
flowchart TD
    subgraph Edge["🌐 1. Perímetro y Tráfico de Entrada"]
        M1["Lab 01: Gateway API<br/>(Envoy Gateway + Separación de Roles)"]
    end

    subgraph ControlPlane["🏛️ 2. Plano de Control y Datos en Reposo"]
        M2["Lab 02: Auditoría CIS<br/>(kube-bench)"]
        M8["Lab 08: Cifrado en etcd<br/>(Encryption at Rest)"]
    end

    subgraph Workloads["📦 3. Workloads, Secretos y Supply Chain"]
        M3["Lab 03: Escaneo de Vulnerabilidades<br/>(Trivy CLI + Trivy Operator)"]
        M7["Lab 07: Secretos para GitOps<br/>(Bitnami Sealed Secrets)"]
    end

    subgraph ZeroTrust["🔐 4. Identidad (RBAC) y Red Zero-Trust"]
        M4["Lab 04: Mínimo Privilegio<br/>(RBAC + ServiceAccount Hardening)"]
        M5["Lab 05: Microsegmentación<br/>(NetworkPolicies)"]
    end

    subgraph Runtime["🚨 5. Detección Runtime y Observabilidad"]
        M6["Lab 06: Seguridad en Ejecución<br/>(Falco eBPF + Reglas Custom)"]
        M9["Lab 09: Monitoreo y Postura<br/>(Prometheus + Grafana + Trivy)"]
    end

    Edge --> ControlPlane --> Workloads --> ZeroTrust --> Runtime

    style Edge fill:#eff6ff,stroke:#2563eb,color:#1e3a8a
    style ControlPlane fill:#f5f3ff,stroke:#7c3aed,color:#4c1d95
    style Workloads fill:#fffbeb,stroke:#d97706,color:#78350f
    style ZeroTrust fill:#f0fdf4,stroke:#16a34a,color:#14532d
    style Runtime fill:#fef2f2,stroke:#dc2626,color:#7f1d1d
```

---

## 📚 Ruta de Aprendizaje y Laboratorios (9 Módulos)

El aprendizaje está dividido en **9 módulos prácticos**. Aunque cada uno puede ejecutarse de forma independiente, seguirlos en orden te permite construir un clúster blindado de extremo a extremo:

| # | Laboratorio | Capa de Seguridad | Nivel | Duración | Herramientas Clave | Guía Paso a Paso |
| :---: | :--- | :--- | :---: | :---: | :---: | :---: |
| **01** | **Kubernetes Gateway API** | Tráfico de Entrada y Separación de Roles | `Intermedio` | `~20 min` | `Envoy Gateway` `HTTPRoute` | [🌐 Ir al Lab 01](./01-gateway-api/README.md) |
| **02** | **Auditoría CIS Benchmark** | Cumplimiento del Plano de Control y Nodos | `Básico` | `~15 min` | `kube-bench` `CIS` | [🛡️ Ir al Lab 02](./02-kube-bench/README.md) |
| **03** | **Escaneo de Vulnerabilidades** | Imágenes, `securityContext` y Registros | `Intermedio` | `~25 min` | `Trivy CLI` `Operator` | [🔍 Ir al Lab 03](./03-trivy-k8s/README.md) |
| **04** | **RBAC y Mínimo Privilegio** | Autorización, Impersonación y Tokens | `Intermedio` | `~20 min` | `Role` `ClusterRole` `SA` | [🔐 Ir al Lab 04](./04-rbac-minimum-privilege/README.md) |
| **05** | **Aislamiento con NetworkPolicies** | Microsegmentación y Red *Zero-Trust* | `Intermedio` | `~15 min` | `NetworkPolicy` `CNI` | [🕸️ Ir al Lab 05](./05-network-policies/README.md) |
| **06** | **Detección en Runtime** | Inspección de *Syscalls* y Crypto-Miners | `Avanzado` | `~25 min` | `Falco` `Falcosidekick` | [🦅 Ir al Lab 06](./06-falco-overview/README.md) |
| **07** | **Gestión Segura de Secretos** | Cifrado Asimétrico GitOps y Scopes | `Intermedio` | `~25 min` | `Sealed Secrets` `kubeseal` | [🔑 Ir al Lab 07](./07-secrets-sealed/README.md) |
| **08** | **Cifrado de Datos en Reposo** | Protección Criptográfica en `etcd` | `Avanzado` | `~20 min` | `EncryptionConfig` `etcdctl` | [🔒 Ir al Lab 08](./08-encryption-at-rest/README.md) |
| **09** | **Monitoreo y Postura de Seguridad** | Observabilidad y Dashboards de CVEs | `Intermedio` | `~25 min` | `Prometheus` `Grafana` | [📊 Ir al Lab 09](./09-monitoring-prometheus-grafana/README.md) |

<details>
<summary>✅ <strong>Checklist de Progreso del Estudiante (CKS / Hardening)</strong></summary>

- [ ] **Lab 01:** Exponer servicios con `GatewayClass`, `Gateway` y `HTTPRoute` separando roles entre namespaces.
- [ ] **Lab 02:** Auditar nodos y Control Plane con `kube-bench` e interpretar hallazgos `[FAIL]` / `[WARN]`.
- [ ] **Lab 03:** Detectar CVEs y aplicar `securityContext` endurecido + políticas de registros confiables con Trivy/Kyverno.
- [ ] **Lab 04:** Diseñar roles de mínimo privilegio y desactivar el montaje automático de tokens (`automountServiceAccountToken: false`).
- [ ] **Lab 05:** Aplicar política `default-deny-all` y habilitar tráfico selectivo por `podSelector`.
- [ ] **Lab 06:** Escribir reglas personalizadas en Falco para detectar binarios maliciosos y conexiones Stratum.
- [ ] **Lab 07:** Sellar secretos para GitOps y comprobar los límites de `strict`, `namespace-wide` y `cluster-wide`.
- [ ] **Lab 08:** Configurar cifrado `aescbc` en `kube-apiserver` y verificar secretos cifrados en `etcd`.
- [ ] **Lab 09:** Integrar métricas de Trivy Operator en Prometheus y visualizarlas en Grafana.

</details>

---

## 📁 Estructura del Repositorio

```text
blindando-kubernetes/
├── 📂 01-gateway-api/                   # Gestión moderna de tráfico de entrada con Envoy Gateway
├── 📂 02-kube-bench/                    # Auditoría CIS de nodos y componentes del Control Plane
├── 📂 03-trivy-k8s/                     # Escaneo de vulnerabilidades, políticas y hardening de workloads
├── 📂 04-rbac-minimum-privilege/        # Diseño de Roles, simulación de robo de token y remediación
├── 📂 05-network-policies/              # Políticas Default-Deny y apertura controlada entre Pods
├── 📂 06-falco-overview/                # Reglas personalizadas en Falco para detectar Crypto-Miners
├── 📂 07-secrets-sealed/                # Cifrado de secretos para GitOps y laboratorio de Scopes
├── 📂 08-encryption-at-rest/            # Cifrado de secretos en reposo en etcd (aescbc / KMS)
├── 📂 09-monitoring-prometheus-grafana/ # Observabilidad del clúster e integración con Trivy Operator
└── 📂 scripts/                          # Script de verificación rápida de prerrequisitos (check-env.sh)
```

> 💡 **Tip de Aprendizaje:** Cada directorio contiene su propio archivo `README.md` detallado con explicaciones, comandos listos para copiar y todos los manifiestos YAML necesarios.

---

## ⚙️ Requisitos Previos

Para aprovechar al máximo estos laboratorios sin bloqueos técnicos, asegúrate de contar con:

1. **Entorno Kubernetes Funcional:**
   - Un entorno de laboratorio en la nube como [**iximiuz Labs**](https://labs.iximiuz.com/) o **Killercoda**.
   - O un clúster local (`minikube`, `kind`, `k3d`, `Rancher Desktop`) con un CNI que soporte `NetworkPolicies` (como **Cilium** o **Calico**).
2. **Herramientas Cliente:**
   - `kubectl` y `helm` (v3+) instalados y autenticados contra tu clúster.
   - Opcional según el módulo: `trivy` (Lab 03), `kubeseal` (Lab 07) y `etcdctl` en el nodo de control plane (Lab 08).
3. **Privilegios:**
   - Permisos de `cluster-admin` para instalar operadores, CRDs, configuraciones RBAC y políticas de red.

---

## 🚀 Cómo Empezar

1. **Clona el repositorio** en tu máquina o entorno de laboratorio:
   ```bash
   git clone https://github.com/edwinbermudez91/blindando-kubernetes.git
   cd blindando-kubernetes
   ```

2. **Verifica los prerrequisitos y la conexión a tu clúster:**
   ```bash
   ./scripts/check-env.sh
   ```

3. **¡Inicia el primer laboratorio!** Entra a [`01-gateway-api/README.md`](./01-gateway-api/README.md) y avanza módulo por módulo.

---

## 👨‍🏫 Autor y Comunidad

Material diseñado y mantenido por **Edwin Bermúdez** — *Senior DevOps & SRE | Cloud Native Instructor*.

- 🔗 **LinkedIn:** [linkedin.com/in/edwin-bermudez-cuervo](https://www.linkedin.com/in/edwin-bermudez-cuervo)
- 🐙 **GitHub:** [@edwinbermudez91](https://github.com/edwinbermudez91)
- 🚢 **Curso Fundamentos de Kubernetes:** [edwinbermudez91/Fundamentos-Kubernetes](https://github.com/edwinbermudez91/Fundamentos-Kubernetes)

---

## 📄 Licencia

Este proyecto está distribuido bajo la **Licencia MIT**. Consulta el archivo [LICENSE](./LICENSE) para más detalles.

*¡Es hora de blindar clústeres de principio a fin!* 🛡️☸️
