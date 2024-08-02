import json
import urllib3
import os
from datetime import datetime, timedelta, timezone

def lambda_handler(event, context):
    # Slack 웹훅 URL 가져오기
    slack_webhook_url = os.environ['SLACK_WEBHOOK_URL']
    
    try:
        # 이벤트에서 메시지 추출
        message = event['Records'][0]['Sns']['Message']
        detail = json.loads(message)
        
        # 인스턴스 정보 및 알림 시간 추출
        instance_id = detail.get('detail', {}).get('instance-id', '인스턴스 ID')
        region = detail.get('detail', {}).get('region', '리전 이름')
        time_utc = detail.get('detail', {}).get('time', '시간')
        state = detail.get('detail', {}).get('state', '인스턴스 상태')
        
        # UTC 시간을 KST로 변환
        if time_utc != '정보 없음':
            time_utc_dt = datetime.fromisoformat(time_utc.replace('Z', '+00:00'))
            kst = timezone(timedelta(hours=9))
            time_kst = time_utc_dt.astimezone(kst).strftime('%Y-%m-%d %H:%M:%S %Z')
        else:
            time_kst = '정보 없음'
        
        # Slack 메시지 구성 
        slack_message = {
            "text": (
                f"인스턴스 모니터링 알림:\n"
                f"인스턴스 ID: `{instance_id}`\n"
                f"리전: `{region}`\n"
                f"시간 (KST): `{time_kst}`\n"
                f"상태: `{state}`\n"
                f"과부하 발생: `{state}` 상태 발생\n"
            )
        }
        
        # Slack에 메시지 보내기
        http = urllib3.PoolManager()
        response = http.request(
            'POST',
            slack_webhook_url,
            body=json.dumps(slack_message),
            headers={'Content-Type': 'application/json'}
        )
        
        # 응답 처리
        if response.status != 200:
            raise Exception(f"Slack으로의 요청이 오류를 반환했습니다: {response.status}, 응답 내용:\n{response.data}")
        
        return {
            'statusCode': 200,
            'body': json.dumps('Slack에 알림을 보냈습니다!')
        }

    except Exception as e:
        print(f"SNS 메시지 처리 중 오류 발생: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps('SNS 메시지 처리 중 오류 발생')
        }
