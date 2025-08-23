#!/bin/bash

# Default values
SECRET_NAME=""
CERT_PATH=""
REGION="us-east-2"

# Parse parameters
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -sn|--secret-name) SECRET_NAME="$2"; shift ;;
        -ph|--path) CERT_PATH="$2"; shift ;;
        -r|--region) REGION="$2"; shift ;;
        -h|--help)
            echo "Usage: $0 -sn <SECRET_NAME> -ph <CERT_PATH> [-r <AWS_REGION>]"
            echo "  -sn, --secret-name   AWS Secrets Manager secret name"
            echo "  -ph, --path          Path where certificates are located (e.g. /etc/letsencrypt/live/domain)"
            echo "  -r,  --region        AWS region (default: us-east-2)"
            exit 0
            ;;
        *) echo "❌ Unknown parameter: $1"; exit 1 ;;
    esac
    shift
done

# Validate required parameters
if [[ -z "$SECRET_NAME" || -z "$CERT_PATH" ]]; then
    echo "❌ Error: You must provide -sn and -ph"
    echo "Example: $0 -sn prod/tls/example.com -ph /etc/letsencrypt/live/example.com -r us-east-2"
    exit 1
fi

# Certificate files
PRIVKEY="$CERT_PATH/privkey.pem"
FULLCHAIN="$CERT_PATH/fullchain.pem"
CERT="$CERT_PATH/fullchain.pem"

# Validate files
for FILE in "$PRIVKEY" "$FULLCHAIN" "$CERT"; do
  if [[ ! -f "$FILE" ]]; then
    echo "❌ Error: File not found $FILE"
    exit 1
  fi
done

# Convert to JSON-friendly format (\n escaped)
PRIVKEY_ESCAPED=$(awk 'BEGIN{ORS="\\n"} {print}' "$PRIVKEY")
FULLCHAIN_ESCAPED=$(awk 'BEGIN{ORS="\\n"} {print}' "$FULLCHAIN")
CERT_ESCAPED=$(awk 'BEGIN{ORS="\\n"} {print}' "$CERT")

# Push to AWS Secrets Manager
aws secretsmanager put-secret-value \
  --region "$REGION" \
  --secret-id "$SECRET_NAME" \
  --secret-string "$(jq -n --arg privkey "$PRIVKEY_ESCAPED" \
                           --arg fullchain "$FULLCHAIN_ESCAPED" \
                           --arg cert "$CERT_ESCAPED" \
                           '{privkey:$privkey, fullchain:$fullchain}')"
