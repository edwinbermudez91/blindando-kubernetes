#!/usr/bin/env bash
set -euo pipefail

echo "🔍 Verificando prerrequisitos para Blindando Kubernetes..."
echo ""

check_cmd() {
  local cmd="$1"
  local required="$2"
  if command -v "$cmd" >/dev/null 2>&1; then
    echo "  ✅ $cmd: instalado"
  elif [ "$required" = "required" ]; then
    echo "  ❌ $cmd: NO encontrado (requerido)"
  else
    echo "  ⚠️  $cmd: no encontrado (opcional según el laboratorio)"
  fi
}

echo "1) Herramientas cliente:"
check_cmd kubectl required
check_cmd helm required
check_cmd trivy optional
check_cmd kubeseal optional

echo ""
echo "2) Conexión al clúster:"
if kubectl cluster-info >/dev/null 2>&1; then
  echo "  ✅ Clúster accesible:"
  kubectl get nodes -o wide
else
  echo "  ❌ No se pudo conectar al clúster Kubernetes (verifica tu kubeconfig)."
  exit 1
fi
