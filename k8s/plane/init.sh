helm install plane-app makeplane/plane-ce \
    --create-namespace \
    --namespace plane-ce \
    -f values.yaml \
    --timeout 10m \
    --wait \
    --wait-for-jobs


    gracias, para cerrar crea un readme.md breve k8s/plane, explicando que se debe bajar la planmtilla                                │
│    helm  show values plane/plane-enterprise > values.yaml                                                                            │
│    vi values.yaml                                                                                                                    │
│                                                                                                                                      │
│    editar los valores por defecto tals como el storage clase, host tanto de la app , como de minio y rambbit, configurar en true la  │
│    generacuon de certificados ssl, y adicionar esta anotacion cert-manager.io/cluster-issuer: "letsencrypt-prod", finalmente guardar │
│     los cambios,                                                                                                                     │
│                                                                                                                                      │
│    y finalmente ejecutar este comando                                                                                                │
│                                                                                                                                      │
│                                                                                                                                      │
│                                                                                                                                      │
│                                                                                                                                      │
│                                                                                                                                      │
│                                                                                                                                      │
│    helm install plane-app makeplane/plane-ce     --create-namespace     --namespace plane-ce     -f values.yaml     --timeout 10m    │
│      --wait     --wait-for-jobs                                                                                                      │
│                                                                                                                                      │
│    luego puede consultar en la web la app   