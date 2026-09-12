#!/usr/bin/env bash

# Exit immediately if a command exits with a non-zero status
set -e

# ==========================================
# CONFIGURATION VARIABLES
# ==========================================
AWS_REGION="us-east-1"
S3_BUCKET_NAME="webforx-tf-state-sandbox-us-east-1"
DYNAMODB_TABLE_NAME="webforx-tf-locks"

echo "=========================================="
echo " Starting Terraform Backend Bootstrapping "
echo "=========================================="

# 1. CREATE S3 BUCKET
echo "[1/4] Checking/Creating S3 Bucket: ${S3_BUCKET_NAME}..."

if aws s3api head-bucket --bucket "${S3_BUCKET_NAME}" 2>/dev/null; then
    echo "  -> S3 Bucket '${S3_BUCKET_NAME}' already exists."
else
    # us-east-1 does not require LocationConstraint
    if [ "${AWS_REGION}" = "us-east-1" ]; then
        aws s3api create-bucket \
            --bucket "${S3_BUCKET_NAME}" \
            --region "${AWS_REGION}"
    else
        aws s3api create-bucket \
            --bucket "${S3_BUCKET_NAME}" \
            --region "${AWS_REGION}" \
            --create-bucket-configuration LocationConstraint="${AWS_REGION}"
    fi
    echo "  -> S3 Bucket created successfully."
fi

# 2. ENABLE S3 BUCKET VERSIONING (Recommended for State Files)
echo "[2/4] Enabling versioning on S3 Bucket..."
aws s3api put-bucket-versioning \
    --bucket "${S3_BUCKET_NAME}" \
    --versioning-configuration Status=Enabled

# 3. ENABLE S3 DEFAULT ENCRYPTION (SSE-S3)
echo "[3/4] Enabling default AES256 server-side encryption..."
aws s3api put-bucket-encryption \
    --bucket "${S3_BUCKET_NAME}" \
    --server-side-encryption-configuration '{
        "Rules": [
            {
                "ApplyServerSideEncryptionByDefault": {
                    "SSEAlgorithm": "AES256"
                }
            }
        ]
    }'

# 4. CREATE DYNAMODB LOCK TABLE
echo "[4/4] Checking/Creating DynamoDB Table: ${DYNAMODB_TABLE_NAME}..."

if aws dynamodb describe-table --table-name "${DYNAMODB_TABLE_NAME}" --region "${AWS_REGION}" >/dev/null 2>&1; then
    echo "  -> DynamoDB Table '${DYNAMODB_TABLE_NAME}' already exists."
else
    aws dynamodb create-table \
        --table-name "${DYNAMODB_TABLE_NAME}" \
        --attribute-definitions AttributeName=LockID,AttributeType=S \
        --key-schema AttributeName=LockID,KeyType=HASH \
        --billing-mode PAY_PER_REQUEST \
        --region "${AWS_REGION}"

    echo "  -> Waiting for DynamoDB table creation to complete..."
    aws dynamodb wait table-exists \
        --table-name "${DYNAMODB_TABLE_NAME}" \
        --region "${AWS_REGION}"
        
    echo "  -> DynamoDB table created successfully."
fi

echo "=========================================="
echo " Bootstrapping Complete! Ready for 'terraform init' "
echo "=========================================="
