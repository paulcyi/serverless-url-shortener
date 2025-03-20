## Serverless URL Shortener
- **Tech**: AWS Lambda, DynamoDB, Terraform, GitHub Actions, Trivy, SonarQube.
- **Challenge**: Hit a 403 MissingAuthenticationTokenException with API Gateway-Lambda despite correct perms—pivoted to Lambda Function URL, fixed a 404 via DynamoDB key alignment. Added Trivy/SonarQube to CI/CD, resolved SonarCloud auto-analysis conflict.
- **Demo**: `curl -I "https://hni2syqzq55krzamvqfpm5c3vi0pyygx.lambda-url.us-east-1.on.aws/?code=oyzhe8"` → `HTTP/1.1 302 Found` with `location: https://linkedin.com`
- **CI/CD**: GitHub Actions deploys in ~5 mins, Trivy scans infra, SonarQube zeroed criticals on Lambda code.
- **Future Work**: AWS Support ticket for API Gateway 403 (sync/regional bug?), S3 frontend, SNS alerts.
- **Lessons Learned**: Mastered serverless architecture, Terraform state, AWS debugging, and CI/CD hardening under pressure.
