# Lab 02 · Auditoría CIS con kube-bench

## ¿Qué es kube-bench?

[kube-bench](https://github.com/aquasecurity/kube-bench) es una herramienta de código abierto desarrollada por Aqua Security que comprueba si Kubernetes está desplegado de forma segura según las directrices de seguridad documentadas en el **CIS (Center for Internet Security) Kubernetes Benchmark**.

Las pruebas de evaluación están definidas en archivos YAML, lo que facilita la comprensión y actualización a medida que las especificaciones evolucionan.

## Objetivo del Laboratorio

En este laboratorio ejecutarás **kube-bench** como un Job dentro del clúster para obtener un resumen del estado de cumplimiento frente al CIS Kubernetes Benchmark y revisarás algunos hallazgos clave para entender su impacto.

> Nota: adapta los comandos a tu entorno (bare metal, managed, etc.). En servicios manejados (EKS, GKE, AKS), muchas comprobaciones del plano de control no aplican directamente ya que son gestionadas por el proveedor.

## Pasos

1. Crear namespace de laboratorio (opcional):

```bash
kubectl create namespace security-lab
```

2. Aplicar el Job de kube-bench:

```bash
kubectl apply -f kube-bench-job.yaml -n security-lab
kubectl get jobs -n security-lab
```

3. Ver logs del Job y guardar resultados:

```bash
kubectl logs job/kube-bench -n security-lab | tee kube-bench-results.txt
```

4. Visualizar los resultados y localizar hallazgos:

Para facilitar la lectura, puedes imprimir el archivo de resultados aplicando colores (rojo para `FAIL`, amarillo para `WARN`, verde para `PASS` y cian para `INFO`):

```bash
awk '
/\[FAIL\]/ {print "\033[1;31m" $0 "\033[0m"; next}
/\[WARN\]/ {print "\033[1;33m" $0 "\033[0m"; next}
/\[PASS\]/ {print "\033[1;32m" $0 "\033[0m"; next}
/\[INFO\]/ {print "\033[1;36m" $0 "\033[0m"; next}
{print}
' kube-bench-results.txt
```

Si prefieres filtrar directamente para ver solo los problemas y el resumen final:

```bash
grep -E "\[FAIL\]|\[WARN\]|Summary" kube-bench-results.txt
```

5. Elegir 1–2 hallazgos relevantes y discutir:

- ¿A qué componente afectan (API server, kubelet, etcd...)?
- ¿Qué impacto tendría en producción?
- ¿Cómo lo priorizarías en tu backlog de hardening?

## Limpieza

```bash
kubectl delete job kube-bench -n security-lab --ignore-not-found
```
