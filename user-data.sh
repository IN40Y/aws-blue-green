#!/bin/bash
# Script to install and configure a web server on Ubuntu
apt-get update
apt-get install -y nginx
systemctl start nginx
systemctl enable nginx

# Create a simple HTML page based on the app_version
# The Terraform variable is passed via the Launch Template tags and retrieved by instance metadata
INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
REGION=$(curl -s http://169.254.169.254/latest/meta-data/placement/region)
# Use the AWS CLI to get the 'Version' tag for this instance
APP_VERSION=$(aws ec2 describe-tags --region $REGION --filters "Name=resource-id,Values=$INSTANCE_ID" "Name=key,Values=Version" --query "Tags[0].Value" --output text)

# Write the HTML file
cat > /var/www/html/index.html <<EOF
<!DOCTYPE html>
<html>
<head>
    <title>Blue-Green Demo</title>
    <style>
        body { font-family: Arial, sans-serif; text-align: center; padding: 50px; }
        h1 { color: #333; }
        .blue { background-color: #e6f7ff; }
        .green { background-color: #e6ffe6; }
    </style>
</head>
<body class="${APP_VERSION}">
    <h1>Hello from <span style="color: ${APP_VERSION};">${APP_VERSION}</span> environment!</h1>
    <p>Instance ID: <code>$INSTANCE_ID</code></p>
    <p>Deployed with Terraform!</p>
</body>
</html>
EOF