#!/usr/bin/env bash

# when a command fails, bash exits instead of continuing with the rest of the script
set -o errexit
# make the script fail, when accessing an unset variable
set -o nounset
# pipeline command is treated as failed, even if one command in the pipeline fails
set -o pipefail
# enable debug mode, by running your script as TRACE=1
if [[ "${TRACE-0}" == "1" ]]; then set -o xtrace; fi

DEFAULT_PROJECT=$(gcloud config get-value project)
PROJECT_ID=${PROJECT_ID:-"$DEFAULT_PROJECT"}

assert_user_is_authenticated() {
  # Check if the user is authenticated for gcloud
  if gcloud auth list --format='value(account)' | grep '@'; then
      echo "User is authenticated for gcloud"
  else
      echo "User is not authenticated for gcloud. Please authenticate using 'gcloud auth login'"
      exit 1
  fi
}

check_service_status() {
    local PROJECT_ID="$1"
    local SERVICE_NAME="$2"
    local ENABLED_SERVICES
    ENABLED_SERVICES=$(gcloud services list --enabled --format="value(config.name)" --project "$PROJECT_ID")

    if echo "$ENABLED_SERVICES" | grep -q "$SERVICE_NAME"; then
      return 0
    fi

    return 1
}

seperator() {
  printf "\n------------------------------------------\n"
}

list_resources() {
  local project_id="$1"
  local api_endpoint="$2"
  local resource="$3"

  if check_service_status "$project_id" "$api_endpoint"; then
    echo "$3:"
    eval "gcloud $resource list --project \"$project_id\" --format=\"value(name)\""
    seperator
  fi
}

list_enabled_services() {
  local project_id="$1"
  echo "Enabled services:"
  gcloud services list --project "$project_id"
  seperator
}

list_compute_resources() {
  local project_id="$1"
  RESOURCES=(
    "backend-services"
    "backend-buckets"
    "health-checks"
    "http-health-checks"
    "https-health-checks"
    "instance-groups"
    "instance-templates"
    "instances"
    "networks"
    "routers"
    "target-http-proxies"
    "target-https-proxies"
    "target-pools"
    "url-maps"
  )

  for resource in "${RESOURCES[@]}"; do
      list_resources "$project_id" "compute.googleapis.com" "compute $resource"
  done
}

echo "Generating resource report for project $PROJECT_ID"
seperator

list_enabled_services "$PROJECT_ID"
list_compute_resources "$PROJECT_ID"

# list_resources "$PROJECT_ID" "artifactregistry.googleapis.com" ""
# list_resources "$PROJECT_ID" "bigquery.googleapis.com" ""
# list_resources "$PROJECT_ID" "bigquerymigration.googleapis.com" "" ""
# list_resources "$PROJECT_ID" "bigquerystorage.googleapis.com" "" ""
list_resources "$PROJECT_ID" "bigtableadmin.googleapis.com" "Cloud Bigtable Instances" "bigtable instances"
# list_resources "$PROJECT_ID" "billingbudgets.googleapis.com" "" ""
# list_resources "$PROJECT_ID" "cloudaicompanion.googleapis.com" "" ""
# list_resources "$PROJECT_ID" "cloudapis.googleapis.com" "" ""
# list_resources "$PROJECT_ID" "cloudasset.googleapis.com" "" ""
# list_resources "$PROJECT_ID" "cloudbilling.googleapis.com" "" ""
# list_resources "$PROJECT_ID" "cloudresourcemanager.googleapis.com" "" ""
# list_resources "$PROJECT_ID" "cloudtrace.googleapis.com" "" ""
# list_resources "$PROJECT_ID" "containerregistry.googleapis.com" ""
# list_resources "$PROJECT_ID" "datastore.googleapis.com" ""
# list_resources "$PROJECT_ID" "iam.googleapis.com" ""
# list_resources "$PROJECT_ID" "iamcredentials.googleapis.com" ""
list_resources "$PROJECT_ID" "kubernetes.googleapis.com" "container clusters"
# list_resources "$PROJECT_ID" "logging.googleapis.com" ""
# list_resources "$PROJECT_ID" "monitoring.googleapis.com" ""
# list_resources "$PROJECT_ID" "networkmanagement.googleapis.com" ""
# list_resources "$PROJECT_ID" "oslogin.googleapis.com" ""
list_resources "$PROJECT_ID" "pubsub.googleapis.com" "pubsub topics"
# list_resources "$PROJECT_ID" "run.googleapis.com" ""
# list_resources "$PROJECT_ID" "servicemanagement.googleapis.com" ""
# list_resources "$PROJECT_ID" "serviceusage.googleapis.com" ""
# list_resources "$PROJECT_ID" "spanner.googleapis.com" "Cloud Spanner Instances" "spanner instances"
# list_resources "$PROJECT_ID" "sql-component.googleapis.com" ""
# list_resources "$PROJECT_ID" "sqladmin.googleapis.com" "Cloud SQL Instances" "sql instances"
list_resources "$PROJECT_ID" "storage-api.googleapis.com" "storage buckets"
# list_resources "$PROJECT_ID" "storage-component.googleapis.com" ""
# list_resources "$PROJECT_ID" "storage.googleapis.com" ""

