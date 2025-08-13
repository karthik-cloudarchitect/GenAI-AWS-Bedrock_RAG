# CloudOpsPilot GenAI Project - AWS Bedrock RAG System

> 🔄 **Recent Updates**: Enhanced documentation, improved error handling, and optimized performance configurations for better user experience.

A comprehensive Retrieval-Augmented Generation (RAG) system built on AWS Bedrock, featuring document processing, vector search, and an intelligent chat interface.

## 🚀 Features

- **Document Processing**: Upload and process various document formats (PDF, TXT, DOC, DOCX, MD)
- **Vector Search**: Advanced semantic search using OpenSearch
- **AI Chat Interface**: Interactive chat with AWS Bedrock AI models
- **Scalable Architecture**: Built on AWS serverless services
- **Modern UI**: Responsive React-based frontend with Tailwind CSS
- **Real-time Processing**: Event-driven document processing pipeline

## 🏗️ Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Frontend      │    │   API Gateway   │    │   Lambda        │
│   (CloudFront)  │◄──►│   (REST API)    │◄──►│   Functions     │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                │                       │
                                ▼                       ▼
                       ┌─────────────────┐    ┌─────────────────┐
                       │   OpenSearch    │    │   DynamoDB      │
                       │   (Vector DB)   │    │   (Metadata)    │
                       └─────────────────┘    └─────────────────┘
                                ▲                       ▲
                                │                       │
                       ┌─────────────────┐    ┌─────────────────┐
                       │   S3 Bucket     │    │   AWS Bedrock   │
                       │   (Documents)   │    │   (AI Models)   │
                       └─────────────────┘    └─────────────────┘
```

## 📋 Prerequisites

- AWS CLI configured with appropriate permissions
- Terraform (version >= 1.0)
- Python 3.8+ (for Lambda dependencies)
- pip (Python package manager)

## 🛠️ Installation & Deployment

### 🚀 Quick Start (Recommended for Novice Users)

**New to AWS or Terraform?** Start with our comprehensive step-by-step guide:

📖 **[QUICKSTART.md](QUICKSTART.md)** - Complete novice-friendly guide with:
- Detailed prerequisite installation instructions
- Step-by-step deployment process
- Troubleshooting common issues
- Manual deployment fallback options

### 🚀 Automated Deployment (For Experienced Users)

For the fastest deployment experience, use our automated script:

```bash
# Clone the repository
git clone <repository-url>
cd GenAI-AWS-Bedrock_RAG

# Deploy everything with one command
./scripts/deploy.sh
```

This script will handle all prerequisites, deployment, and configuration automatically.

### 🔧 Manual Deployment

If you prefer manual deployment, follow these steps:

#### 1. Clone the Repository

```bash
git clone <repository-url>
cd GenAI-AWS-Bedrock_RAG
```

#### 2. Configure AWS Credentials

Ensure your AWS CLI is configured with appropriate permissions:

```bash
aws configure
```

Required permissions:
- S3 (Full access)
- Lambda (Full access)
- API Gateway (Full access)
- OpenSearch (Full access)
- DynamoDB (Full access)
- CloudFront (Full access)
- IAM (Limited to creating roles and policies)
- EKS (Full access)

#### 3. Prepare Lambda Dependencies

The Lambda functions require specific Python packages. A deployment package is already included, but you can recreate it if needed:

```bash
# Create temporary directory for Lambda package
mkdir -p temp_lambda_package
cp app/lambda/*.py temp_lambda_package/

# Install dependencies
cd temp_lambda_package
pip install -r requirements.txt -t .
zip -r ../terraform/modules/compute/lambda_functions.zip .
cd ..
```

#### 4. Deploy Infrastructure

Navigate to the terraform directory and deploy:

```bash
cd terraform

# Initialize Terraform
terraform init

# Review the deployment plan
terraform plan

# Deploy the infrastructure
terraform apply
```

#### 5. Deploy Frontend

After the infrastructure is deployed, upload the frontend files:

```bash
# Get the frontend bucket name from Terraform output
FRONTEND_BUCKET=$(terraform output -raw frontend_bucket_name)

# Upload frontend files
aws s3 sync ../frontend/ s3://$FRONTEND_BUCKET --region ap-southeast-2
```

#### 6. Access the Application

Once deployment is complete, you can access:

- **Frontend**: `https://<cloudfront-domain>` (from Terraform output)
- **API Endpoint**: `https://<api-gateway-url>/prod/query` (from Terraform output)
- **OpenSearch Dashboard**: `https://<opensearch-domain>/_dashboards/` (from Terraform output)

## 🔧 Configuration

### Environment Variables

The Lambda functions use the following environment variables (automatically configured by Terraform):

- `OPENSEARCH_ENDPOINT`: OpenSearch domain endpoint
- `DYNAMODB_TABLE`: DynamoDB table name
- `S3_BUCKET`: S3 bucket for document storage
- `BEDROCK_MODEL_ID`: AWS Bedrock model ID (default: anthropic.claude-3-sonnet-20240229-v1:0)

### Customization

You can customize the deployment by modifying the Terraform variables in `terraform/main.tf`:

```hcl
variable "aws_region" {
  description = "AWS region for deployment"
  default     = "ap-southeast-2"
}

variable "project_name" {
  description = "Project name for resource naming"
  default     = "rag"
}
```

## 📁 Project Structure

```
GenAI-AWS-Bedrock_RAG/
├── app/
│   └── lambda/                 # Lambda function source code
│       ├── document_processor.py
│       ├── query_processor.py
│       └── utils.py
├── docs/
│   ├── RAG_Architecture.md     # Detailed architecture documentation
│   └── sample_knowledge_base/  # Sample documents for testing
├── frontend/                   # Frontend application
│   ├── index.html
│   └── app.js
├── scripts/                    # Deployment and utility scripts
├── terraform/                  # Infrastructure as Code
│   ├── main.tf                 # Main Terraform configuration
│   └── modules/                # Terraform modules
│       ├── api/                # API Gateway module
│       ├── compute/            # Lambda functions module
│       ├── eks/                # EKS cluster module
│       ├── frontend/           # Frontend hosting module
│       ├── iam/                # IAM roles and policies module
│       └── storage/            # Storage resources module
├── .gitignore
└── README.md
```

## 🧪 Testing

### 1. Test the API

```bash
# Test the query endpoint
curl -X POST "https://<api-gateway-url>/prod/query" \
  -H "Content-Type: application/json" \
  -d '{"query": "Hello, can you help me?"}'
```

### 2. Test Document Upload

Upload a document to the S3 bucket:

```bash
aws s3 cp docs/sample_knowledge_base/company_handbook.md s3://<document-bucket>/
```

### 3. Test the Frontend

Open the CloudFront URL in your browser and test the chat interface.

## 🔍 Troubleshooting

### Common Issues

1. **Lambda Function Errors**
   - Check CloudWatch logs for detailed error messages
   - Verify IAM permissions are correctly assigned
   - Ensure environment variables are set

2. **API Gateway Timeouts**
   - Check Lambda function execution time
   - Verify API Gateway integration settings
   - Check CORS configuration if needed

3. **Frontend Not Loading**
   - Verify S3 bucket policy allows CloudFront access
   - Check CloudFront distribution settings
   - Ensure index.html is uploaded to S3

4. **OpenSearch Connection Issues**
   - Verify security group settings
   - Check IAM roles for OpenSearch access
   - Ensure VPC configuration is correct

### Logs and Monitoring

- **Lambda Logs**: CloudWatch Log Groups `/aws/lambda/rag-*`
- **API Gateway Logs**: CloudWatch Log Groups `/aws/apigateway/`
- **OpenSearch Logs**: CloudWatch Log Groups `/aws/opensearch/`

## 🧹 Cleanup

To remove all deployed resources, use our automated cleanup script:

```bash
./scripts/cleanup.sh
```

Or manually:

```bash
cd terraform
terraform destroy
```

**⚠️ Warning**: This will permanently delete all resources and data.

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## 📞 Support

For issues and questions:
- Create an issue in the repository
- Check the troubleshooting section
- Review the architecture documentation in `docs/`

## 🔄 Updates and Maintenance

- Regularly update AWS SDK versions in Lambda functions
- Monitor CloudWatch metrics for performance optimization
- Keep Terraform modules updated with latest AWS provider versions
- Review and update security configurations periodically