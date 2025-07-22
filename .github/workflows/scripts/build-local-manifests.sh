#!/bin/bash

# Build local manifests for all ArgoCD applications
# This script generates Kubernetes manifests for all applications defined in argocd-apps-root-app/

set -eo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/../../../" && pwd)"
ARGOCD_APPS_DIR="${ROOT_DIR}/argocd-apps-root-app"
MANIFESTS_DIR="${ROOT_DIR}/manifests"
APPS_DIR="${ROOT_DIR}/apps"

# Options
FAIL_FAST=${FAIL_FAST:-false}  # Set to true to exit on first failure

# Create manifests directory
mkdir -p "${MANIFESTS_DIR}"

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Show usage information
usage() {
    cat << EOF
Usage: $0 [options]

This script generates Kubernetes manifests for all ArgoCD applications.

Options:
    -h, --help      Show this help message
    -f, --fail-fast Exit immediately on first failure

Environment Variables:
    FAIL_FAST       Set to 'true' to enable fail-fast mode (default: false)

Examples:
    $0                    # Run normally, continue on failures
    $0 --fail-fast        # Exit on first failure
    FAIL_FAST=true $0     # Exit on first failure (using env var)
EOF
}

# Function to extract application name from ArgoCD app file
get_app_name() {
    local app_file="$1"
    yq eval '.metadata.name' "$app_file"
}

# Function to extract namespace from ArgoCD app file
get_app_namespace() {
    local app_file="$1"
    yq eval '.spec.destination.namespace' "$app_file"
}

# Function to check if app uses Helm charts
is_helm_app() {
    local app_file="$1"
    local chart_exists=$(yq eval '.spec.sources[]? | select(.chart != null) | .chart' "$app_file" 2>/dev/null || echo "")
    [[ -n "$chart_exists" ]]
}

# Function to check if app uses multiple sources
has_multiple_sources() {
    local app_file="$1"
    local sources_count=$(yq eval '.spec.sources | length' "$app_file" 2>/dev/null || echo "0")
    
    if [[ "$sources_count" != "0" && "$sources_count" != "null" && "$sources_count" -gt 0 ]]; then
        return 0
    else
        return 1
    fi
}

# Function to build Helm-based application
build_helm_app() {
    local app_file="$1"
    local app_name="$2"
    local namespace="$3"
    
    log_info "Building Helm application: $app_name"
    
    # Extract Helm chart information
    local chart_name=$(yq eval '.spec.sources[] | select(.chart != null) | .chart' "$app_file")
    local chart_version=$(yq eval '.spec.sources[] | select(.chart != null) | .targetRevision' "$app_file")
    local chart_repo=$(yq eval '.spec.sources[] | select(.chart != null) | .repoURL' "$app_file")
    
    # Find values file
    local values_file="${APPS_DIR}/${app_name}/values.yaml"
    
    if [[ ! -f "$values_file" ]]; then
        log_warning "Values file not found for $app_name at $values_file"
        values_file=""
    fi
    
    # Create namespace directory
    local output_dir="${MANIFESTS_DIR}/${namespace}"
    mkdir -p "$output_dir"
    
    # Add Helm repo if not already added
    local repo_name=$(echo "$chart_repo" | sed 's|https://||' | sed 's|registry-1.docker.io/||' | sed 's|/|-|g' | sed 's|\.|-|g')
    
    # Handle special case for OCI registries
    if [[ "$chart_repo" == *"registry-1.docker.io"* || "$chart_repo" == *"docker.io"* || "$chart_repo" == *"ghcr.io"* || "$chart_repo" == *"quay.io"* ]]; then
        # For OCI registries, we need to use the full URL format
        if [[ "$chart_repo" != oci://* ]]; then
            chart_repo="oci://${chart_repo}"
        fi
        log_info "Using OCI registry: $chart_repo"
    else
        helm repo add "$repo_name" "$chart_repo" 2>/dev/null || true
        helm repo update > /dev/null 2>&1
    fi
    
    # Build Helm template
    local helm_cmd
    if [[ "$chart_repo" == *"oci://"* ]]; then
        helm_cmd="helm template $app_name $chart_repo/$chart_name --version $chart_version --namespace $namespace --create-namespace"
    else
        helm_cmd="helm template $app_name $repo_name/$chart_name --version $chart_version --namespace $namespace --create-namespace"
    fi
    
    if [[ -n "$values_file" ]]; then
        helm_cmd="$helm_cmd --values $values_file"
    fi
    
    log_info "Running: $helm_cmd"
    
    # Generate manifests
    if $helm_cmd > "${output_dir}/${app_name}-helm.yaml"; then
        log_success "Generated Helm manifests for $app_name"
        
        # Also copy any additional manifests from the app directory
        local manifests_path="${APPS_DIR}/${app_name}/manifests"
        if [[ -d "$manifests_path" ]]; then
            cp -r "$manifests_path"/* "$output_dir/" 2>/dev/null || true
            log_info "Copied additional manifests from $manifests_path"
        fi
    else
        log_error "Failed to generate Helm manifests for $app_name"
        return 1
    fi
}

# Function to build plain Kubernetes manifest application
build_manifest_app() {
    local app_file="$1"
    local app_name="$2"
    local namespace="$3"
    
    log_info "Building manifest application: $app_name"
    
    # Extract source path
    local source_path
    if has_multiple_sources "$app_file"; then
        source_path=$(yq eval '.spec.sources[] | select(.path != null) | .path' "$app_file" | head -1)
    else
        source_path=$(yq eval '.spec.source.path' "$app_file")
    fi
    
    local app_dir="${ROOT_DIR}/${source_path}"
    
    if [[ ! -d "$app_dir" ]]; then
        log_error "Application directory not found: $app_dir"
        return 1
    fi
    
    # Create namespace directory
    local output_dir="${MANIFESTS_DIR}/${namespace}"
    mkdir -p "$output_dir"
    
    # Copy all YAML files
    find "$app_dir" -name "*.yaml" -o -name "*.yml" | while read -r file; do
        local filename=$(basename "$file")
        local dest_file="${output_dir}/${app_name}-${filename}"
        
        # Add namespace to the manifest if not present
        if yq eval '.metadata.namespace' "$file" > /dev/null 2>&1; then
            cp "$file" "$dest_file"
        else
            yq eval ".metadata.namespace = \"$namespace\"" "$file" > "$dest_file"
        fi
        
        log_info "Copied $filename to $dest_file"
    done
    
    log_success "Generated manifests for $app_name"
}

# Function to build ApplicationSet applications
build_applicationset() {
    local app_file="$1"
    local app_name="$2"
    
    log_info "Processing ApplicationSet: $app_name"
    
    # Extract the path pattern
    local path_pattern=$(yq eval '.spec.generators[].git.directories[].path' "$app_file")
    
    # Find all directories matching the pattern
    local base_path=$(echo "$path_pattern" | sed 's/\/\*$//')
    local search_dir="${ROOT_DIR}/${base_path}"
    
    if [[ ! -d "$search_dir" ]]; then
        log_error "ApplicationSet base directory not found: $search_dir"
        return 1
    fi
    
    # Process each subdirectory
    for subdir in "$search_dir"/*; do
        if [[ -d "$subdir" ]]; then
            local subapp_name=$(basename "$subdir")
            local full_app_name="${app_name}-${subapp_name}"
            
            # Extract namespace from template
            local namespace=$(yq eval '.spec.template.spec.destination.namespace' "$app_file")
            
            log_info "Building ApplicationSet member: $full_app_name"
            
            # Create namespace directory
            local output_dir="${MANIFESTS_DIR}/${namespace}"
            mkdir -p "$output_dir"
            
            # Copy all YAML files
            find "$subdir" -name "*.yaml" -o -name "*.yml" | while read -r file; do
                local filename=$(basename "$file")
                local dest_file="${output_dir}/${full_app_name}-${filename}"
                
                # Add namespace to the manifest if not present
                if yq eval '.metadata.namespace' "$file" > /dev/null 2>&1; then
                    cp "$file" "$dest_file"
                else
                    yq eval ".metadata.namespace = \"$namespace\"" "$file" > "$dest_file"
                fi
                
                log_info "Copied $filename to $dest_file"
            done
        fi
    done
    
    log_success "Generated ApplicationSet manifests for $app_name"
}

# Function to process a single ArgoCD application file
process_app() {
    local app_file="$1"
    local filename=$(basename "$app_file")
    
    # Skip if not a YAML file
    if [[ ! "$filename" =~ \.(yaml|yml)$ ]]; then
        return 0
    fi
    
    # Skip the root app
    if [[ "$filename" == "argocd-apps-root-app.yaml" ]]; then
        return 0
    fi
    
    log_info "Processing: $filename"
    
    # Check if it's an ApplicationSet
    local kind=$(yq eval '.kind' "$app_file")
    if [[ "$kind" == "ApplicationSet" ]]; then
        local app_name=$(get_app_name "$app_file")
        build_applicationset "$app_file" "$app_name"
        return 0
    fi
    
    # Process regular Application
    if [[ "$kind" == "Application" ]]; then
        local app_name=$(get_app_name "$app_file")
        local namespace=$(get_app_namespace "$app_file")
        
        if is_helm_app "$app_file"; then
            build_helm_app "$app_file" "$app_name" "$namespace"
        else
            build_manifest_app "$app_file" "$app_name" "$namespace"
        fi
    fi
}

# Main execution
main() {
    log_info "Starting manifest generation..."
    log_info "Root directory: $ROOT_DIR"
    log_info "ArgoCD apps directory: $ARGOCD_APPS_DIR"
    log_info "Output directory: $MANIFESTS_DIR"
    
    # Clean up existing manifests
    if [[ -d "$MANIFESTS_DIR" ]]; then
        log_info "Cleaning existing manifests directory..."
        rm -rf "${MANIFESTS_DIR}"/*
    fi
    
    # Process all ArgoCD application files
    local processed_count=0
    local failed_count=0
    
    for app_file in "$ARGOCD_APPS_DIR"/*.yaml; do
        if [[ -f "$app_file" ]]; then
            if process_app "$app_file"; then
                ((processed_count++)) || true
            else
                ((failed_count++)) || true
                log_error "Failed to process $(basename "$app_file")"
                
                # Exit immediately if fail-fast is enabled
                if [[ "$FAIL_FAST" == "true" ]]; then
                    log_error "Fail-fast mode enabled. Exiting on first failure."
                    exit 1
                fi
            fi
        fi
    done
    
    if [[ $failed_count -gt 0 ]]; then
        log_error "Manifest generation failed!"
        log_error "Processed: $processed_count applications"
        log_error "Failed: $failed_count applications"
        exit 1
    fi
    
    log_success "Manifest generation completed!"
    log_info "Processed: $processed_count applications"
    
    # Show summary
    log_info "Generated manifests in:"
    find "$MANIFESTS_DIR" -type f -name "*.yaml" | sort
}

# Parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                usage
                exit 0
                ;;
            -f|--fail-fast)
                FAIL_FAST=true
                shift
                ;;
            *)
                log_error "Unknown option: $1"
                usage
                exit 1
                ;;
        esac
    done
}

# Parse arguments and run main function
parse_args "$@"
main