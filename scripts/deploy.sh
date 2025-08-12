#!/bin/bash

#==============================================================================
# GenAI RAG System Deployment Script
#==============================================================================
# This script deploys the complete RAG (Retrieval-Augmented Generation) system
# including infrastructure, Lambda functions, and frontend components.
#
# Deployment Phases:
# 1. Infrastructure provisioning (Terraform)
# 2. Lambda function packaging and deployment
# 3. Frontend build and S3 upload
# 4. API Gateway configuration
# 5. OpenSearch index setup
# 6. Knowledge base initialization
#
# Prerequisites:
# - AWS CLI configured with admin permissions
# - Terraform installed (version 1.0+)
# - Node.js for frontend build
# - Python 3.9+ for Lambda functions
#
# Environment Variables:
# - AWS_REGION: Target AWS region
# - ENVIRONMENT: Deployment environment (dev/staging/prod)
# - OPENSEARCH_DOMAIN: OpenSearch cluster name
#
# Usage:
#   ./deploy.sh [environment] [region]
#   Example: ./deploy.sh prod us-east-1
#
# Version: 3.0
# Last Updated: $(date +'%Y-%m-%d')
#==============================================================================

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check AWS CLI configuration
check_aws_config() {
    print_status "Checking AWS CLI configuration..."
    
    if ! command_exists aws; then
        print_error "AWS CLI is not installed. Please install it first."
        exit 1
    fi
    
    if ! aws sts get-caller-identity >/dev/null 2>&1; then
        print_error "AWS CLI is not configured. Please run 'aws configure' first."
        exit 1
    fi
    
    print_success "AWS CLI is properly configured"
}

# Function to check Terraform installation
check_terraform() {
    print_status "Checking Terraform installation..."
    
    if ! command_exists terraform; then
        print_error "Terraform is not installed. Please install it first."
        exit 1
    fi
    
    TERRAFORM_VERSION=$(terraform version -json | jq -r '.terraform_version')
    print_success "Terraform version $TERRAFORM_VERSION is installed"
}

# Function to check Python and pip
check_python() {
    print_status "Checking Python installation..."
    
    if ! command_exists python3; then
        print_error "Python 3 is not installed. Please install it first."
        exit 1
    fi
    
    if ! command_exists pip3; then
        print_error "pip3 is not installed. Please install it first."
        exit 1
    fi
    
    PYTHON_VERSION=$(python3 --version | cut -d' ' -f2)
    print_success "Python $PYTHON_VERSION is installed"
}

# Function to prepare Lambda deployment package
prepare_lambda_package() {
    print_status "Preparing Lambda deployment package..."
    
    # Create temporary directory
    mkdir -p temp_lambda_package
    
    # Copy Lambda function code
    cp app/lambda/*.py temp_lambda_package/
    
    # Create requirements.txt if it doesn't exist
    if [ ! -f temp_lambda_package/requirements.txt ]; then
        cat > temp_lambda_package/requirements.txt << EOF
requests==2.31.0
boto3==1.34.0
botocore==1.34.0
EOF
    fi
    
    # Install dependencies
    cd temp_lambda_package
    pip3 install -r requirements.txt -t .
    
    # Create deployment package
    zip -r ../terraform/modules/compute/lambda_functions.zip .
    cd ..
    
    print_success "Lambda deployment package created"
}

# Function to deploy infrastructure
deploy_infrastructure() {
    print_status "Deploying infrastructure with Terraform..."
    
    cd terraform
    
    # Initialize Terraform
    print_status "Initializing Terraform..."
    terraform init
    
    # Plan deployment
    print_status "Planning deployment..."
    terraform plan -out=tfplan
    
    # Ask for confirmation
    echo
    print_warning "Review the plan above. Do you want to proceed with deployment? (y/N)"
    read -r response
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        print_status "Deployment cancelled by user"
        exit 0
    fi
    
    # Apply deployment
    print_status "Applying Terraform configuration..."
    terraform apply tfplan
    
    # Get outputs
    print_status "Getting deployment outputs..."
    API_ENDPOINT=$(terraform output -raw api_endpoint)
    FRONTEND_URL=$(terraform output -raw frontend_url)
    DOCUMENT_BUCKET=$(terraform output -raw document_bucket)
    OPENSEARCH_DASHBOARD=$(terraform output -raw opensearch_dashboard)
    
    cd ..
    
    print_success "Infrastructure deployed successfully"
}

# Function to deploy frontend
deploy_frontend() {
    print_status "Deploying frontend to S3..."
    
    # Get frontend bucket name from Terraform output
    cd terraform
    FRONTEND_BUCKET=$(terraform output -raw frontend_bucket_name)
    cd ..
    
    # Upload frontend files
    aws s3 sync frontend/ s3://$FRONTEND_BUCKET --region ap-southeast-2
    
    print_success "Frontend deployed successfully"
}

# Function to upload sample documents
upload_sample_documents() {
    print_status "Uploading sample documents..."
    
    if [ -d "docs/sample_knowledge_base" ]; then
        cd terraform
        DOCUMENT_BUCKET=$(terraform output -raw document_bucket)
        cd ..
        
        aws s3 cp docs/sample_knowledge_base/ s3://$DOCUMENT_BUCKET/ --recursive --region ap-southeast-2
        
        print_success "Sample documents uploaded"
    else
        print_warning "No sample documents found in docs/sample_knowledge_base/"
    fi
}

# Function to display deployment summary
show_deployment_summary() {
    print_success "Deployment completed successfully!"
    echo
    echo "=== Deployment Summary ==="
    echo "Frontend URL: $FRONTEND_URL"
    echo "API Endpoint: $API_ENDPOINT"
    echo "Document Bucket: $DOCUMENT_BUCKET"
    echo "OpenSearch Dashboard: $OPENSEARCH_DASHBOARD"
    echo
    echo "=== Next Steps ==="
    echo "1. Open the frontend URL in your browser"
    echo "2. Test the chat interface"
    echo "3. Upload additional documents to the S3 bucket if needed"
    echo "4. Monitor CloudWatch logs for any issues"
    echo
    echo "=== Testing Commands ==="
    echo "Test API: curl -X POST '$API_ENDPOINT' -H 'Content-Type: application/json' -d '{\"query\": \"Hello\"}'"
    echo "Upload document: aws s3 cp your-document.pdf s3://$DOCUMENT_BUCKET/"
}

# Function to cleanup temporary files
cleanup() {
    print_status "Cleaning up temporary files..."
    
    if [ -d "temp_lambda_package" ]; then
        rm -rf temp_lambda_package
    fi
    
    if [ -f "terraform/tfplan" ]; then
        rm terraform/tfplan
    fi
    
    print_success "Cleanup completed"
}

# Main deployment function
main() {
    echo "=========================================="
    echo "CloudOpsPilot GenAI Project - Deployment"
    echo "=========================================="
    echo
    
    # Check prerequisites
    check_aws_config
    check_terraform
    check_python
    
    # Prepare Lambda package
    prepare_lambda_package
    
    # Deploy infrastructure
    deploy_infrastructure
    
    # Deploy frontend
    deploy_frontend
    
    # Upload sample documents
    upload_sample_documents
    
    # Show summary
    show_deployment_summary
    
    # Cleanup
    cleanup
    
    print_success "All done! Your RAG system is ready to use."
}

# Handle script arguments
case "${1:-}" in
    --help|-h)
        echo "Usage: $0 [OPTIONS]"
        echo
        echo "Options:"
        echo "  --help, -h     Show this help message"
        echo "  --skip-frontend Skip frontend deployment"
        echo "  --skip-docs    Skip sample document upload"
        echo
        echo "This script deploys the entire CloudOpsPilot GenAI RAG system."
        exit 0
        ;;
    --skip-frontend)
        SKIP_FRONTEND=true
        ;;
    --skip-docs)
        SKIP_DOCS=true
        ;;
    "")
        # No arguments, proceed with full deployment
        ;;
    *)
        print_error "Unknown option: $1"
        echo "Use --help for usage information"
        exit 1
        ;;
esac

# Run main function
main "$@" 