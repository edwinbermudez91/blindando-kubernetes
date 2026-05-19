# 🔒 Lab 08: Cifrado de Datos en Reposo (Encryption at Rest)

Este módulo cubre la configuración del cifrado de datos en reposo para los recursos almacenados en la API de Kubernetes (como los Secrets), basándose en la [documentación oficial de Kubernetes](https://kubernetes.io/docs/tasks/administer-cluster/encrypt-data/).

## Conceptos Clave

*   **¿Qué es?** Por defecto, Kubernetes almacena los recursos (incluyendo los Secrets) en texto plano dentro de la base de datos `etcd`. El cifrado en reposo permite cifrar estos datos en `etcd`, añadiendo una capa de seguridad adicional al cifrado a nivel de disco que ya puedas tener implementado en los nodos.
*   **EncryptionConfiguration:** Es un archivo YAML que le indica al proceso `kube-apiserver` qué recursos cifrar y qué proveedores de cifrado utilizar.
*   **Proveedores de Cifrado:**
    *   `identity`: No aplica ningún cifrado (almacena en texto plano). Se usa como valor por defecto, como respaldo o durante transiciones para leer datos antiguos no cifrados.
    *   `aescbc` / `aesgcm` / `secretbox`: Proveedores locales que usan una llave simétrica proporcionada directamente en el archivo de configuración.
    *   `kms` (Key Management Service): Usa un servicio externo (como AWS KMS, Azure Key Vault, Google Cloud KMS) para administrar las llaves mediante un modelo de "envelope encryption" (cifrado de sobre). Es la opción más recomendada para entornos de producción reales.
*   **Implementación:** Se debe pasar el argumento `--encryption-provider-config` al Static Pod del `kube-apiserver` indicando la ruta del archivo de configuración.

---

## Ejercicio Práctico: Configurar Cifrado Local (aescbc)

En este ejercicio, configuraremos el cifrado de datos en reposo utilizando el proveedor `aescbc` con una llave generada localmente.

> **Nota Importante:** Este ejercicio asume que tienes acceso al nodo de control plane (master) de tu clúster y que el `kube-apiserver` se ejecuta como un Static Pod. Esto es común en clústeres creados con `kubeadm`, `minikube` o `kind`.

### Paso 1: Verificar el estado actual (Texto plano)

1. Crea un Secret de prueba en el namespace por defecto:
   ```bash
   kubectl create secret generic mi-secreto-plano -n default --from-literal=password=supersecreto
   ```

2. Verifica cómo se almacena en `etcd` obteniendo los datos directamente de la base de datos. 

   > **Requisito previo:** Necesitarás la herramienta `etcdctl`. Si no la tienes instalada en tu nodo de control plane, puedes descargarla y configurarla rápidamente con los siguientes comandos:
   > ```bash
   > cd /tmp
   > export RELEASE=$(curl -s https://api.github.com/repos/etcd-io/etcd/releases/latest | grep tag_name | cut -d '"' -f 4)
   > wget https://github.com/etcd-io/etcd/releases/download/${RELEASE}/etcd-${RELEASE}-linux-amd64.tar.gz
   > tar xvf etcd-${RELEASE}-linux-amd64.tar.gz ; cd etcd-${RELEASE}-linux-amd64
   > sudo mv etcd etcdctl /usr/local/bin/
   > ```

   Ahora, ejecuta el siguiente comando para consultar el valor desde etcd *(ajusta las rutas de los certificados si es necesario)*:
   ```bash
   # Comando genérico, ajusta los certificados según tu entorno
   sudo ETCDCTL_API=3 etcdctl \
     --cacert=/etc/kubernetes/pki/etcd/ca.crt \
     --cert=/etc/kubernetes/pki/etcd/server.crt \
     --key=/etc/kubernetes/pki/etcd/server.key \
     get /registry/secrets/default/mi-secreto-plano | hexdump -C
   ```
   **Resultado:** Notarás que el valor `supersecreto` es perfectamente visible en la salida (texto plano).

### Paso 2: Generar una Llave de Cifrado

En el nodo de control plane, genera una llave aleatoria de 32 bytes y codifícala en base64:

```bash
head -c 32 /dev/urandom | base64
```
*Copia el valor generado, lo necesitarás en el siguiente paso para tu archivo de configuración.*

### Paso 3: Crear el Archivo de Configuración de Cifrado

En el nodo de control plane, crea un directorio para guardar la configuración y el archivo en sí.

```bash
sudo mkdir -p /etc/kubernetes/enc
sudo nano /etc/kubernetes/enc/enc.yaml
```

Añade el siguiente contenido, reemplazando `<BASE_64_ENCODED_SECRET>` con el valor que generaste en el Paso 2:

```yaml
---
apiVersion: apiserver.config.k8s.io/v1
kind: EncryptionConfiguration
resources:
  - resources:
      - secrets
    providers:
      - aescbc:
          keys:
            - name: key1
              secret: <BASE_64_ENCODED_SECRET>
      - identity: {} # Importante: Permite leer secretos antiguos que no están cifrados
```

### Paso 4: Modificar el kube-apiserver

Edita el manifiesto del Static Pod del `kube-apiserver`, que usualmente se encuentra en `/etc/kubernetes/manifests/kube-apiserver.yaml`:

1. Añade el argumento al comando de inicio del contenedor:
   ```yaml
   spec:
     containers:
     - command:
       - kube-apiserver
       # ... otros argumentos ...
       - --encryption-provider-config=/etc/kubernetes/enc/enc.yaml
   ```

2. Añade el montaje de volumen para que el contenedor pueda leer el archivo:
   ```yaml
       volumeMounts:
       # ... otros volumeMounts ...
       - name: enc
         mountPath: /etc/kubernetes/enc
         readOnly: true
   ```

3. Añade el volumen (`hostPath`) en la especificación del Pod:
   ```yaml
     volumes:
     # ... otros volumes ...
     - name: enc
       hostPath:
         path: /etc/kubernetes/enc
         type: DirectoryOrCreate
   ```

Guarda el archivo. El proceso `kubelet` detectará inmediatamente el cambio en el manifiesto y reiniciará el `kube-apiserver` automáticamente. Espera unos minutos hasta que la API de Kubernetes vuelva a responder (puedes verificar con `kubectl get pods -n kube-system`).

### Paso 5: Verificar el Cifrado

1. Una vez la API esté arriba, crea un nuevo Secret:
   ```bash
   kubectl create secret generic mi-secreto-cifrado -n default --from-literal=password=nuevosecreto
   ```

2. Verifica cómo se almacena en `etcd` ahora (usando el mismo comando del Paso 1, pero apuntando al nuevo secreto):
   ```bash
   sudo ETCDCTL_API=3 etcdctl \
     --cacert=/etc/kubernetes/pki/etcd/ca.crt \
     --cert=/etc/kubernetes/pki/etcd/server.crt \
     --key=/etc/kubernetes/pki/etcd/server.key \
     get /registry/secrets/default/mi-secreto-cifrado | hexdump -C
   ```
   **Resultado:** Deberías ver un prefijo indicando el proveedor y la versión de la llave (por ejemplo: `k8s:enc:aescbc:v1:key1:`) seguido de datos cifrados que son completamente ilegibles. No encontrarás "nuevosecreto" en texto plano.

3. Verifica que la API de Kubernetes es capaz de descifrarlo correctamente al consultarlo con kubectl:
   ```bash
   kubectl get secret mi-secreto-cifrado -n default -o yaml
   ```
   El valor base64 debe decodificarse correctamente a "nuevosecreto" si lo pasas por `echo <valor-base64> | base64 -d`.

### Paso 6: Cifrar los Secrets Existentes

Los Secrets que fueron creados antes de configurar el cifrado (como el `mi-secreto-plano` del Paso 1) todavía residen en texto plano en la base de datos `etcd`. Para cifrarlos, debes forzar una escritura para reemplazarlos:

```bash
kubectl get secrets --all-namespaces -o json | kubectl replace -f -
```

Luego de ejecutar este comando, puedes volver a verificar con `etcdctl` que `mi-secreto-plano` ahora está cifrado.

Opcionalmente, para asegurar que **todos** los secretos estén estrictamente cifrados y no permitir ninguna lectura de texto plano a nivel de API, puedes editar `/etc/kubernetes/enc/enc.yaml` y remover la línea `- identity: {}`, luego esperar a que se recargue (si tienes activado el reload automático) o reiniciar el apiserver.

---
> ⚠️ **Consideración de Seguridad (Local vs KMS):** Almacenar la llave de cifrado en un archivo en el disco del control plane (como hicimos con `aescbc`) protege contra la lectura pasiva de la base de datos `etcd` o la sustracción de backups de etcd. Sin embargo, si un atacante compromete a fondo el nodo de control plane, podrá leer el archivo `enc.yaml` y extraer la llave. Para máxima seguridad y cumplimiento, se debe utilizar el proveedor **KMS**.
