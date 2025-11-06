import os
import json
from datetime import datetime
import boto3

dynamodb = boto3.resource('dynamodb')

CONNECTIONS_TABLE = os.environ.get('CONNECTIONS_TABLE', 'social-battery-connections')
DEVICES_TABLE = os.environ.get('DEVICES_TABLE', CONNECTIONS_TABLE)


def respond(status=200, body=None):
    return {
        'statusCode': status,
        'headers': { 'Content-Type': 'application/json' },
        'body': json.dumps(body or {})
    }


def handler(event, context):
    # support both proxy and http api events
    method = None
    path = None
    try:
        method = event.get('requestContext', {}).get('http', {}).get('method') or event.get('httpMethod')
    except Exception:
        method = event.get('httpMethod')
    path = event.get('rawPath') or event.get('path') or '/'

    table = dynamodb.Table(CONNECTIONS_TABLE)

    try:
        if method == 'POST' and path.endswith('/connections'):
            body = json.loads(event.get('body') or '{}')
            item = {
                'pk': body.get('receiverEmail'),
                'sk': body.get('id') or body.get('sk') or body.get('id') or str(body.get('id') or os.urandom(16).hex()),
            }
            # copy fields
            for k, v in body.items():
                item[k] = v
            if 'sentAt' not in item:
                item['sentAt'] = datetime.utcnow().isoformat()
            table.put_item(Item=item)
            return respond(200, { 'ok': True, 'id': item.get('sk') })

        if method == 'GET' and path.endswith('/connections'):
            qs = event.get('queryStringParameters') or {}
            receiver = qs.get('receiverEmail')
            if not receiver:
                return respond(400, { 'error': 'receiverEmail required' })
            res = table.query(KeyConditionExpression=boto3.dynamodb.conditions.Key('pk').eq(receiver))
            items = res.get('Items', [])
            return respond(200, items)

        if method == 'POST' and path.endswith('/connections/battery'):
            body = json.loads(event.get('body') or '{}')
            email = body.get('email')
            battery = body.get('battery')
            if not email or battery is None:
                return respond(400, { 'error': 'email and battery required' })
            item = { 'pk': f'battery#{email}', 'sk': 'meta', 'email': email, 'battery': int(battery), 'updatedAt': datetime.utcnow().isoformat() }
            table.put_item(Item=item)
            return respond(200, { 'ok': True })

        if method == 'POST' and path.endswith('/devices'):
            body = json.loads(event.get('body') or '{}')
            token = body.get('token')
            email = body.get('email')
            if not token:
                return respond(400, { 'error': 'token required' })
            devices_table = dynamodb.Table(DEVICES_TABLE)
            item = { 'pk': f'device#{token}', 'sk': 'meta', 'token': token, 'email': email, 'createdAt': datetime.utcnow().isoformat() }
            devices_table.put_item(Item=item)
            return respond(200, { 'ok': True })

        return respond(405, { 'error': 'method not allowed' })

    except Exception as e:
        print('error', e)
        return respond(500, { 'error': str(e) })
