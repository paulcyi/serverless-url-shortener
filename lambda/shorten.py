import json, random, string
def lambda_handler(event, context):
    body = json.loads(event['body'])
    long_url = body['url']
    short_code = ''.join(random.choices(string.ascii_lowercase + string.digits, k=6))
    store = {"abc123": "google.com"}  # Dummy for now
    store[short_code] = long_url
    return {
        "statusCode": 200,
        "body": json.dumps({"short_url": f"https://yourdomain.com/{short_code}"})
    }