#!/usr/bin/env bash
set -Eeuo pipefail

NAMESPACE="${KUBERNETES_NAMESPACE:-orderflow-production}"
DEPLOYMENT="${KUBERNETES_DEPLOYMENT:-orderflow}"

echo "Rolling back $DEPLOYMENT in namespace $NAMESPACE to the previous healthy revision"
kubectl rollout history "deployment/$DEPLOYMENT" --namespace "$NAMESPACE"
kubectl rollout undo "deployment/$DEPLOYMENT" --namespace "$NAMESPACE"
kubectl rollout status "deployment/$DEPLOYMENT" \
	--namespace "$NAMESPACE" \
	--timeout=5m
kubectl get deployment "$DEPLOYMENT" --namespace "$NAMESPACE" \
	--output='jsonpath=Deployed image: {.spec.template.spec.containers[?(@.name=="orderflow")].image}{"\n"}'
echo "Rollback completed; verify /health, order flows, and production SLOs before closing the incident."
