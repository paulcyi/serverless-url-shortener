import json
import boto3
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table('urls')

def lambda_handler(event, context):
    logger.info("Event received: %s", event)
    try:
        short_code = event.get('queryStringParameters', {}).get('code', '')
        if not short_code:
            raise KeyError('Missing code parameter')
    except KeyError:
        return {
            'statusCode': 400,
            'body': json.dumps({'error': 'Missing code parameter'}),
            'headers': {'Content-Type': 'application/json'}
        }

    response = table.get_item(Key={'short_code': short_code})
    original_url = response.get('Item', {}).get('original_url')

    if not original_url:
        return {
            'statusCode': 404,
            'body': json.dumps({'error': 'Short code not found'}),
            'headers': {'Content-Type': 'application/json'}
        }

    return {
        'statusCode': 302,
        'headers': {
            'Location': original_url
        },
        'body': ''
    }
