## Serverless URL Shortener
- **Tech**: AWS Lambda, DynamoDB, Terraform.
- **Challenge**: Encountered a persistent 403 `MissingAuthenticationTokenException` with API Gateway-Lambda integration despite correct permissions and rebuilds. Pivoted to a Lambda Function URL after exhaustive debugging, resolving a subsequent 404 by aligning DynamoDB key mismatches.
- **Demo**: `curl -I "https://hni2syqzq55krzamvqfpm5c3vi0pyygx.lambda-url.us-east-1.on.aws/?code=oyzhe8"` → `HTTP/1.1 302 Found` with `location: https://linkedin.com`
- **Future Work**: File an AWS Support ticket to investigate the API Gateway 403 issue (suspected sync or regional bug).
- **Lessons Learned**: Gained deep insights into serverless architecture, Terraform state management, and debugging AWS service interactions under pressure.
