#!/usr/bin/env bash
set -Eeuo pipefail

NAMESPACE="${KUBERNETES_NAMESPACE:-orderflow-production}"
: "${RELEASE_VERSION:?RELEASE_VERSION must come from a vX.Y.Z Git tag}"
: "${IMAGE_URL:?IMAGE_URL must identify the immutable ACR image}"

if [[ ! "$RELEASE_VERSION" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
	echo "Invalid release tag: $RELEASE_VERSION" >&2
	exit 1
fi

IMAGE_TAG="${IMAGE_URL##*:}"
IMAGE_COMMIT="${IMAGE_TAG#"${RELEASE_VERSION}-"}"
if [[ "$IMAGE_TAG" == "$IMAGE_URL" || "$IMAGE_TAG" == "$IMAGE_COMMIT" || ! "$IMAGE_COMMIT" =~ ^[[:xdigit:]]{40}$ ]]; then
	echo "Image tag must contain $RELEASE_VERSION and the full 40-character source commit SHA" >&2
	exit 1
fi

echo "Deploying OrderFlow $RELEASE_VERSION to namespace $NAMESPACE"
kubectl get namespace "$NAMESPACE" >/dev/null
kubectl apply -f deployment/kubernetes/service.yaml
kubectl apply -f deployment/kubernetes/pod-disruption-budget.yaml
sed \
	-e "s|__ORDERFLOW_IMAGE__|${IMAGE_URL}|g" \
	-e "s|__RELEASE_VERSION__|${RELEASE_VERSION}|g" \
	deployment/kubernetes/deployment.yaml | kubectl apply -f -

kubectl rollout status "deployment/orderflow" \
	--namespace "$NAMESPACE" \
	--timeout=5m

kubectl exec "deployment/orderflow" --namespace "$NAMESPACE" -- node -e '
	fetch("http://127.0.0.1:3000/health")
		.then(async (response) => {
			if (!response.ok) throw new Error(`health endpoint returned ${response.status}`);
			const body = await response.json();
			if (body.status !== "ok") throw new Error("health endpoint did not report ok");
			console.log(`Health check passed for release ${body.version}`);
		})
		.catch((error) => { console.error(error); process.exitCode = 1; });
'
