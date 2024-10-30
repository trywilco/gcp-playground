#!/bin/bash

# Variables
SERVICE_ACCOUNT_NAME="wilco-checks-service-account"
DESCRIPTION="Verify wilco actions"
DISPLAY_NAME="Wilco checks"
PROJECT_ID=$(gcloud config get-value project)
ROLE="roles/storage.admin"
KEY_FILE_PATH="/tmp/wilco_creds.json"

# Create the service account
gcloud iam service-accounts create $SERVICE_ACCOUNT_NAME \
  --description="$DESCRIPTION" \
  --display-name="$DISPLAY_NAME"

# Assign the role to the service account
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:${SERVICE_ACCOUNT_NAME}@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="$ROLE"

# Generate the key file for the service account
gcloud iam service-accounts keys create $KEY_FILE_PATH \
  --iam-account "${SERVICE_ACCOUNT_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"

# Display the key file content
echo "Service account key file content:"
credentials="`cat $KEY_FILE_PATH`"
stringified_credentials="$(echo "$credentials" | jq -R -s .)"


WILCO_ID="`cat .wilco`"
export ENGINE_EVENT_ENDPOINT="${ENGINE_BASE_URL}/users/${WILCO_ID}/event"

# Update engine with service account credentials

curl -L -X POST "${ENGINE_EVENT_ENDPOINT}" -H "Content-Type: application/json" --data-raw "{ \"event\": \"gcp_service_account_created\", \"metadata\": {\"credentials\": $stringified_credentials }}"
