import json
import os
import http.client
import logging
from datetime import datetime, timedelta

logging.basicConfig(level=logging.INFO)

def lambda_handler(event, context):
    webhook_url = os.environ.get('SLACK_WEBHOOK_URL')
    
    if not webhook_url:
        logging.error('SLACK_WEBHOOK_URL not set!')
        return {
            'statusCode': 500,
            'body': json.dumps('SLACK_WEBHOOK_URL not set!')
        }
    
    # Extract host and path from the webhook URL
    parsed_url = webhook_url.split('/')
    host = parsed_url[2]
    path = '/' + '/'.join(parsed_url[3:])
    
    # Extract relevant information from the event
    sns_message = json.loads(event['Records'][0]['Sns']['Message'])
    alarm_name = sns_message.get('AlarmName', 'Unknown Alarm')
    instance_id = sns_message.get('Trigger', {}).get('Dimensions', [{}])[0].get('value', 'Unknown Instance')
    
    # Get current time in UTC and convert to Korean Standard Time (KST)
    utc_now = datetime.utcnow()
    kst_now = utc_now + timedelta(hours=9)
    time_str = kst_now.strftime('%Y-%m-%d %H:%M:%S KST')
    
    # Construct message
    message = {
        "text": (
            f"*Alarm Triggered!*\n"
            f"• Instance ID: {instance_id}\n"
            f"• Time: {time_str}\n"
            f"• Alarm Name: {alarm_name}\n"
        )
    }
    
    conn = http.client.HTTPSConnection(host)
    
    headers = {
        'Content-Type': 'application/json'
    }
    
    try:
        logging.info(f"Sending message to Slack: {message}")
        conn.request('POST', path, body=json.dumps(message), headers=headers)
        response = conn.getresponse()
        response_data = response.read().decode()
        
        logging.info(f"Slack response status: {response.status}")
        logging.info(f"Slack response body: {response_data}")
        
        return {
            'statusCode': response.status,
            'body': response_data
        }
    except Exception as e:
        logging.error(f'Error sending notification: {str(e)}')
        return {
            'statusCode': 500,
            'body': json.dumps(f'Error sending notification: {str(e)}')
        }
    finally:
        conn.close()
