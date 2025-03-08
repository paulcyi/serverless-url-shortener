## Day 3: API Gateway Setup
- Added `/shorten` (POST) and `/redirect/{code}` (GET) endpoints.
- API URL: https://v3gdhqqp49.execute-api.us-east-1.amazonaws.com/prod/shorten
- Deployed with Terraform, fixed stage conflict manually.
- Tested: `/shorten` works (e.g., shortened linkedin.com to oyzhe8), /redirect 403 issue persists.
- Next: Resolve 403 for /redirect.