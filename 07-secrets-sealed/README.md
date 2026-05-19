# 🔒 Lab 07: Gestión Segura de Secretos con Bitnami Sealed Secrets

¡Bienvenidos al laboratorio de GitOps y Seguridad! 🚀 En esta sesión aprenderemos cómo manejar secretos en Kubernetes de forma profesional. 

El problema: Los **Secrets** estándar de Kubernetes solo están codificados en Base64, lo cual no es cifrado. Si los subes a un repositorio de Git, cualquiera con acceso al repo puede leerlos. **Sealed Secrets** soluciona esto permitiéndote cifrar tus secretos de tal forma que solo el controlador dentro de tu clúster pueda descifrarlos.

---

## 🎯 Objetivos de Aprendizaje

- Entender por qué los Secrets estándar no son aptos para GitOps.
- Instalar el controlador de **Sealed Secrets** en el clúster.
- Utilizar la CLI `kubeseal` para transformar secretos vulnerables en recursos seguros.
- Verificar la creación automática de secretos "unsealed" por el controlador.
- Explorar los diferentes alcances (**Scopes**) de seguridad.

---

## ⚙️ Prerrequisitos

- Un clúster de Kubernetes funcional.
- [Helm 3](https://helm.sh/docs/intro/install/) instalado.
- CLI `kubeseal` instalada en tu máquina local:
  - **macOS**: `brew install kubeseal`
  - **Linux**: Descarga el binario desde el [repo oficial](https://github.com/bitnami-labs/sealed-secrets/releases).

---

## 🛠️ Instrucciones Paso a Paso

### 1️⃣ Instalación del Controlador
El controlador es el cerebro que gestiona las llaves criptográficas y realiza el "unsealing". Lo instalaremos en el namespace `kube-system`.

```bash
# 1. Añadimos el repositorio oficial
helm repo add sealed-secrets https://bitnami-labs.github.io/sealed-secrets

# 2. Instalamos el controlador
helm install sealed-secrets-controller sealed-secrets/sealed-secrets -n kube-system
```

### 2️⃣ Crear un Secreto local (Sin encriptar) ⚠️
Primero generamos un secreto común. **Nota crítica:** Este archivo (`secret-raw.yaml`) contiene datos sensibles y nunca debe ser subido a Git.

```bash
kubectl create secret generic my-db-creds \
    --from-literal=username=admin \
    --from-literal=password=Passw0rd! \
    --dry-run=client -o yaml > secret-raw.yaml
```

### 3️⃣ Encriptar el Secreto (Sealing) 🔐
Utilizamos `kubeseal` para crear un recurso de tipo `SealedSecret`. Este archivo sí es seguro para ser trackeado en Git.

```bash
kubeseal --format=yaml < secret-raw.yaml > sealed-secret.yaml
```
> **💡 Tip Pro:** El comando anterior se comunica con el clúster para obtener la llave pública. Si no tienes acceso al clúster en este momento, puedes usar un certificado guardado localmente: `kubeseal --cert pub-cert.pem < secret-raw.yaml > sealed-secret.yaml`.

### 4️⃣ Aplicar y Verificar
Ahora aplicamos el recurso encriptado. El controlador detectará el `SealedSecret` y generará automáticamente un `Secret` convencional en el mismo namespace.

```bash
# Aplicamos el secreto sellado
kubectl apply -f sealed-secret.yaml

# Verificamos que ambos recursos existan
kubectl get sealedsecret my-db-creds
kubectl get secret my-db-creds
```

**Validar el contenido desencriptado:**
```bash
# Ver el password original para confirmar que el controlador hizo su trabajo
kubectl get secret my-db-creds -o jsonpath='{.data.password}' | base64 -d
```

### 5️⃣ Limpieza de Seguridad (MUY IMPORTANTE) 🧹
Una vez que el secreto ha sido "sellado" y aplicado al clúster, el archivo original en texto plano debe ser eliminado inmediatamente de tu máquina local para evitar fugas de información.

```bash
# Eliminar el archivo con las credenciales en texto plano
rm secret-raw.yaml
```

---

## 🛡️ Conceptos de Seguridad Avanzados

### 🧪 Laboratorio Interactivo: Alcances (Scopes)
Los alcances definen qué tan ligado está el secreto a su nombre y namespace original. Esto evita que alguien copie un `SealedSecret` de un namespace a otro sin permiso.

Primero, preparemos el entorno creando los namespaces necesarios:
```bash
kubectl apply -f manifests/setup-namespaces.yaml
```

#### 1. Strict (Predeterminado)
El secreto está vinculado tanto al **nombre** como al **namespace**. Si cambias cualquiera de los dos, el controlador no podrá descifrarlo.

**Laboratorio:**
```bash
# 1. Sellar el secreto para el namespace 'default'
kubeseal --scope strict < manifests/strict/secret-raw.yaml > manifests/strict/sealed-strict.yaml

# 2. ✅ Escenario de Éxito: Aplicar en 'default' y desplegar Pod
kubectl apply -f manifests/strict/sealed-strict.yaml -n default
kubectl apply -f manifests/strict/pod-success.yaml
kubectl get pod strict-success-pod # Debería estar 'Running'

# 3. ❌ Escenario de Fallo: Intentar aplicar el mismo secreto en 'dev'
# Un atacante copia el archivo y cambia el namespace a 'dev' en el YAML para engañar a Kubernetes
sed 's/"namespace": "default"/"namespace": "dev"/g' manifests/strict/sealed-strict.yaml > manifests/strict/sealed-strict-hacked.yaml

# El atacante aplica su archivo hackeado
kubectl apply -f manifests/strict/sealed-strict-hacked.yaml

# El Pod intenta montar el secreto
kubectl apply -f manifests/strict/pod-fail.yaml

# Verificamos que falla. El controlador detectó la manipulación del namespace y NO descifró el secreto.
kubectl get pod strict-fail-pod -n dev # Se quedará en 'ContainerCreating' (Error: SecretNotFound)
```

#### 2. Namespace-wide
El secreto está vinculado al **namespace**, pero puedes cambiarle el **nombre**. Útil si quieres usar el mismo secreto para diferentes microservicios en el mismo namespace.

**Laboratorio:**
```bash
# 1. Sellar el secreto para el namespace 'backend'
kubeseal --scope namespace-wide < manifests/namespace-wide/secret-raw.yaml > manifests/namespace-wide/sealed-namespace.yaml

# 2. ✅ Escenario de Éxito: Renombrar y aplicar en 'backend'
# Al aplicar, le cambiamos el nombre al vuelo de 'ns-creds' a 'db-creds-api' pero mantenemos el namespace
sed 's/name: ns-creds/name: db-creds-api/g' manifests/namespace-wide/sealed-namespace.yaml | kubectl apply -n backend -f -
kubectl apply -f manifests/namespace-wide/pod-success.yaml
kubectl get pod ns-success-pod -n backend # Debería estar 'Running'

# 3. ❌ Escenario de Fallo: Intentar aplicarlo en 'frontend'
# Un atacante copia el archivo e intenta cambiar el nombre y el namespace para aplicarlo en su entorno 'frontend'
sed -e 's/"name": "ns-creds"/"name": "db-creds-api"/g' -e 's/"namespace": "backend"/"namespace": "frontend"/g' manifests/namespace-wide/sealed-namespace.yaml > manifests/namespace-wide/sealed-namespace-hacked.yaml

# El atacante aplica su archivo hackeado
kubectl apply -f manifests/namespace-wide/sealed-namespace-hacked.yaml

# El Pod intenta montar el secreto
kubectl apply -f manifests/namespace-wide/pod-fail.yaml

# Verificamos que falla. Aunque el scope permite cambiar el nombre, NO permite cambiar el namespace.
kubectl get pod ns-fail-pod -n frontend # Se quedará en 'ContainerCreating' porque el controlador no descifró el secreto.
```

#### 3. Cluster-wide
El secreto puede ser descifrado en **cualquier namespace** y con **cualquier nombre**. Es el menos restrictivo y debe usarse con precaución.

**Laboratorio:**
```bash
# 1. Sellar el secreto (Cluster-wide no se ata a namespace/name)
kubeseal --scope cluster-wide < manifests/cluster-wide/secret-raw.yaml > manifests/cluster-wide/sealed-cluster.yaml

# 2. ✅ Escenario de Éxito: Aplicar en múltiples namespaces
kubectl apply -f manifests/cluster-wide/sealed-cluster.yaml -n dev
kubectl apply -f manifests/cluster-wide/pod-dev.yaml

kubectl apply -f manifests/cluster-wide/sealed-cluster.yaml -n frontend
kubectl apply -f manifests/cluster-wide/pod-frontend.yaml

# Ambos Pods funcionarán perfectamente
kubectl get pod cluster-dev-pod -n dev
kubectl get pod cluster-frontend-pod -n frontend
```
> **⚠️ Riesgo de Seguridad**: Si sellas las credenciales de Producción como `cluster-wide`, cualquier desarrollador podría aplicarlas en `dev`, montar el secreto y obtener acceso a datos reales. Usa este scope solo para configuraciones genéricas compartidas.

### Rotación de Llaves
Por defecto, el controlador genera una nueva llave cada 30 días. Los secretos viejos seguirán funcionando porque el controlador mantiene las llaves antiguas en su historial para poder descifrarlos.

---

## 🧹 Limpieza del Laboratorio

Para dejar el clúster como estaba, eliminamos los recursos y el controlador:

```bash
# Borrar los secretos creados
kubectl delete sealedsecret my-db-creds
kubectl delete secret my-db-creds

# Desinstalar el controlador
helm uninstall sealed-secrets-controller -n kube-system
```