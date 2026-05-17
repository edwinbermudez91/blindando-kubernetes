# 🛡️ Blindando Kubernetes: Seguridad, Auditoría y Control Total

![Kubernetes](https://img.shields.io/badge/Kubernetes-Security-blue?logo=kubernetes&style=for-the-badge)
![Labs](https://img.shields.io/badge/Status-Laboratorios_Activos-success?style=for-the-badge)

¡Bienvenido al repositorio oficial de laboratorios prácticos de la charla **"Blindando Kubernetes: Seguridad, Auditoría y Control Total del Clúster"**! 🚀

Este repositorio está diseñado como una guía interactiva y paso a paso para que puedas experimentar de primera mano con las mejores herramientas y prácticas de seguridad en ecosistemas de orquestación de contenedores. No basta con conocer la teoría; aquí pondremos las manos en la obra para asegurar tu infraestructura de principio a fin.

---

## 🎯 Objetivos de los Laboratorios

A lo largo de estos módulos, adquirirás experiencia práctica y conocimientos técnicos en:

- 🛡️ **Auditoría de cumplimiento:** Evaluar los componentes de tu clúster contra los estrictos estándares de seguridad CIS (Center for Internet Security) utilizando `kube-bench`.
- 🔍 **Escaneo de vulnerabilidades:** Detectar configuraciones inseguras y vulnerabilidades conocidas en tus cargas de trabajo utilizando `Trivy`.
- 🔐 **Control de Accesos (RBAC):** Diseñar e implementar políticas de control de acceso sólidas basadas estrictamente en el principio de mínimo privilegio.
- 🚧 **Aislamiento de red:** Restringir la comunicación entre Pods y prevenir el temido movimiento lateral de los atacantes mediante `NetworkPolicies`.
- 🚨 **Detección en tiempo de ejecución (Run-time Security):** Una introducción práctica a la monitorización y detección de comportamientos anómalos usando `Falco`.
- 🔑 **Gestión Segura de Secretos (GitOps):** Aprender a proteger credenciales y datos sensibles en repositorios de código utilizando `Sealed Secrets`.
- 🔒 **Cifrado en Reposo (Encryption at Rest):** Configurar el cifrado de datos directamente en el etcd para proteger los recursos de la API contra accesos no autorizados al almacenamiento.
---

## 📁 Estructura del Repositorio

El aprendizaje está dividido en 6 módulos temáticos. Aunque son independientes entre sí, te recomendamos seguirlos en orden para construir el conocimiento de forma progresiva:

```text
blindando-kubernetes/
├── 📂 01-kube-bench/             # Auditoría de nodos y componentes del control plane
├── 📂 02-trivy-k8s/              # Escaneo de seguridad de workloads y configuraciones
├── 📂 03-rbac-minimum-privilege/ # Diseño seguro de Roles y asignaciones (RoleBindings)
├── 📂 04-network-policies/       # Segmentación y reglas de tráfico entre Pods
├── 📂 05-falco-overview/         # Monitoreo de seguridad y alertas en tiempo real
├── 📂 06-secrets-sealed/         # Gestión segura de secretos para entornos GitOps
└── 📂 07-encryption-at-rest/     # Cifrado de datos en reposo a nivel de la API y etcd
```

> 💡 **Tip de Aprendizaje:** Cada directorio contiene su propio archivo `README.md` detallado. En ellos encontrarás explicaciones claras, los comandos que debes ejecutar y todos los manifiestos YAML necesarios para resolver los escenarios planteados.

---

## ⚙️ Requisitos Previos

Para aprovechar al máximo estos laboratorios y no tener bloqueos técnicos, asegúrate de contar con lo siguiente:

1. **Entorno Kubernetes Funcional:**
   - Puede ser un entorno de laboratorio efímero (por ejemplo, **labs.iximuiz** o **Killercoda**).
   - O bien, un clúster local propio de desarrollo (`minikube`, `kind`, `k3d`, `Rancher Desktop`).
2. **Herramientas Cliente:**
   - La utilidad de línea de comandos `kubectl` instalada y correctamente autenticada contra tu clúster.
3. **Privilegios:**
   - Se recomienda contar con privilegios elevados (equivalente a `cluster-admin`) para poder crear y destruir Namespaces, ServiceAccounts, configuraciones RBAC, Jobs y políticas de red sin fricciones.

---

## 🚀 Cómo Empezar

1. **Clona el repositorio** en tu máquina local o entorno de laboratorio:
   ```bash
   git clone https://github.com/tu-usuario/blindando-kubernetes.git
   cd blindando-kubernetes
   ```
   *(Nota: Si descargaste el .zip, simplemente descomprímelo y entra en la carpeta raíz).*

2. **Verifica la conexión a tu clúster** para asegurar que todo está en orden:
   ```bash
   kubectl cluster-info
   kubectl get nodes
   ```

3. **¡Inicia el primer laboratorio!** Dirígete a la carpeta `01-kube-bench/` y comienza a securizar tu infraestructura.

---
*Material diseñado para ayudar a ingenieros, desarrolladores y arquitectos cloud a proteger sus cargas de trabajo en Kubernetes de manera efectiva. ¡Es hora de blindar clústeres!* 🛡️☁️
