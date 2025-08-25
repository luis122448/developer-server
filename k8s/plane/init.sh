helm install plane-app makeplane/plane-ce \
    --create-namespace \
    --namespace plane-ce \
    -f values.yaml \
    --timeout 10m \
    --wait \
    --wait-for-jobs