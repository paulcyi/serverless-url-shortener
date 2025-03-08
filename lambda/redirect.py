import json
def lambda_handler(event, context):
    short_code = event['pathParameters']['code']
    store = {"abc123": "google.com"}  # Dummy for now
    long_url = store.get(short_code, "404")
    if long_url == "404":
        return {"statusCode": 404, "body": json.dumps("Not found")}
    return {
        "statusCode": 301,
        "headers": {"Location": long_url},
        "body": ""
    }