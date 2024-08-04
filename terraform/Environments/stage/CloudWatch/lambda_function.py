import json
import os
import http.client
import logging
from datetime import datetime, timedelta

logging.basicConfig(level=logging.INFO)

def lambda_handler(event, context):
    webhook_url = os.environ.get('SLACK_WEBHOOK_URL')
    
    if not webhook_url:
        logging.error('SLACK_WEBHOOK_URL이 설정되어 있지 않습니다!')
        return {
            'statusCode': 500,
            'body': json.dumps('SLACK_WEBHOOK_URL이 설정되어 있지 않습니다!')
        }
    
    # Extract host and path from the webhook URL
    try:
        parsed_url = webhook_url.split('/')
        host = parsed_url[2]
        path = '/' + '/'.join(parsed_url[3:])
    except IndexError:
        logging.error('SLACK_WEBHOOK_URL이 올바른 형식이 아닙니다!')
        return {
            'statusCode': 500,
            'body': json.dumps('SLACK_WEBHOOK_URL이 올바른 형식이 아닙니다!')
        }
    
    # Extract relevant information from the event
    try:
        if 'Records' not in event or len(event['Records']) == 0:
            raise KeyError('Event does not contain "Records" key or it is empty')

        sns_message = json.loads(event['Records'][0]['Sns']['Message'])
        alarm_name = sns_message.get('AlarmName', '알람 이름 없음')
        instance_id = sns_message.get('Trigger', {}).get('Dimensions', [{}])[0].get('value', '알 수 없는 인스턴스')
    except (KeyError, IndexError, json.JSONDecodeError) as e:
        logging.error(f'이벤트 처리 오류: {str(e)}')
        return {
            'statusCode': 400,
            'body': json.dumps(f'이벤트 처리 오류: {str(e)}')
        }
    
    # Get current time in UTC and convert to Korean Standard Time (KST)
    utc_now = datetime.utcnow()
    kst_now = utc_now + timedelta(hours=9)
    time_str = kst_now.strftime('%Y-%m-%d %H:%M:%S KST')
    
    # Construct message
    message = {
        "text": (
            f"*알람 발생!*\n"
            f"• 인스턴스 ID: {instance_id}\n"
            f"• 시간: {time_str}\n"
            f"• 알람 이름: {alarm_name}\n"
            f"• CPU 사용률이 임계값(80%)을 초과했습니다.\n"
        )
    }
    
    conn = http.client.HTTPSConnection(host)
    
    headers = {
        'Content-Type': 'application/json'
    }
    
    try:
        logging.info(f"Slack으로 메시지 전송: {message}")
        conn.request('POST', path, body=json.dumps(message), headers=headers)
        response = conn.getresponse()
        response_data = response.read().decode()
        
        logging.info(f"Slack 응답 상태: {response.status}")
        logging.info(f"Slack 응답 본문: {response_data}")
        
        return {
            'statusCode': response.status,
            'body': response_data
        }
    except Exception as e:
        logging.error(f'알림 전송 오류: {str(e)}')
        return {
            'statusCode': 500,
            'body': json.dumps(f'알림 전송 오류: {str(e)}')
        }
    finally:
        conn.close()
