# Creating and Configuring the Plane Secrets

This document provides a detailed guide on how to create and configure the secrets required for the Plane application.

## Secret Configuration

The `secret.yml` file contains the database credentials and the application's secret key. The values must be Base64 encoded.

### Generating a Random Token for SECRET_KEY

For the `SECRET_KEY`, it is recommended to use a random token. You can generate one using the following command:

```bash
openssl rand -base64 32
```

### Base64 Encoding

To encode your `POSTGRES_USER`, `POSTGRES_PASSWORD`, `POSTGRES_DB`, and the generated `SECRET_KEY` in Base64, you can use the following command:

```bash
echo -n 'your-value' | base64
```

Replace `'your-value'` with the actual value you want to encode.

### Updating the `secret.yml` file

Replace the placeholder values in `secret.yml` with your own Base64 encoded values.

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: plane-secrets
  namespace: plane
type: Opaque
data:
  SECRET_KEY: <base64>
  POSTGRES_USER: <base64>
  POSTGRES_PASSWORD: <base64>
  POSTGRES_DB: <base64>
```

Once you have updated the `secret.yml` file with the encoded values, you can apply it to the cluster using the command in the main deployment guide.
