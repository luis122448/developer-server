# Debugging cert-manager Certificate Issuance

This guide provides a step-by-step process to debug why a `cert-manager` Certificate is not becoming `Ready`. The process involves inspecting a chain of custom resources: `Certificate` -> `CertificateRequest` -> `Order` -> `Challenge`.

## Step 1: Check the Certificate

Start by checking the status of the main `Certificate` resource.

1.  **Get the certificate status:**
    
```sh
kubectl get certificate <certificate-name> -n <namespace>
```
    
If the `READY` column is `False`, proceed to the next step.

2.  **Describe the certificate:**
    
```sh
kubectl describe certificate <certificate-name> -n <namespace>
```
    
Look at the `Events` section at the bottom. This will often tell you that a `CertificateRequest` has been created. Note its name.

## Step 2: Inspect the CertificateRequest

The `CertificateRequest` is the resource that handles the approval and submission of the request to the ACME issuer.

1.  **Describe the CertificateRequest:** Use the name you found in the previous step.

```sh
kubectl describe certificaterequest <cert-request-name> -n <namespace>
```

Check the `Events` and `Status`. Often, this will point to an `Order` resource being created. Note the name of the `Order`.

## Step 3: Inspect the Order

The `Order` resource represents the order placed with the ACME server (e.g., Let's Encrypt) and manages the challenges required to prove ownership of the domain.

1.  **Describe the Order:** Use the name you found in the `CertificateRequest` events.

```sh
kubectl describe order <order-name> -n <namespace>
```
    
The events here will show that one or more `Challenge` resources have been created, one for each domain in the certificate. Note the names of the challenges.

## Step 4: Inspect the Challenge

The `Challenge` resource is where the actual validation happens. The events in this resource contain the root cause of the failure.

1.  **Describe the Challenge:** Use one of the names you found in the `Order` events.

```sh
kubectl describe challenge <challenge-name> -n <namespace>
```
    
Look closely at the `Events` and the `Status.Reason` field. This will contain the specific error message from `cert-manager` or the ACME server.

## Step 6: Applying the Fix and Retrying

If you find that the `Challenge` has failed due to a misconfiguration (e.g., DNS issues, incorrect annotations, etc.), you will need to fix the issue based on the error message.

1.  **Apply the corrected ClusterIssuer/Issuer:**
    
```sh
kubectl apply -f your-cluster-issuer.yaml
```

2.  **Force a retry by deleting the stuck CertificateRequest:** `cert-manager` will automatically create a new one.
    
```sh
# View all resources related to cert-manager:
kubectl get certificate,certificaterequest,order,challenge -A

# Delete all stuck resources to FAILED state:
kubectl delete certificaterequest -A --all
kubectl delete order -A --all
kubectl delete challenge -A --all

# Optionally, delete the certificate to force a new issuance:
kubectl delete secret -n nginx-test <nombre-del-secret-tls>
```

3.  **Monitor the new CertificateRequest** and the certificate status.
    
```sh
kubectl get certificaterequest -n <namespace>
kubectl get certificate -n <namespace>
```
