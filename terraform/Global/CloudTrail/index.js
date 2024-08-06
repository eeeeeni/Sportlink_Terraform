const https = require('https');
const url = require('url');

exports.handler = async (event) => {
    const slackWebhookUrl = process.env.SLACK_WEBHOOK_URL;
    
    // 이벤트에서 접속 시간과 알람 이유를 추출합니다.
    const utcTimestamp = event.time || new Date().toISOString();
    const alarmReason = event.message || '알 수 없는 이유';

    // UTC 시간을 한국 시간으로 변환합니다.
    const utcDate = new Date(utcTimestamp);
    const kstDate = new Date(utcDate.getTime() + (9 * 60 * 60 * 1000)); // UTC+9시간

    // 한국 시간 문자열 포맷 (YYYY-MM-DD HH:mm:ss)
    const kstTimestamp = kstDate.toISOString().replace('T', ' ').substring(0, 19);

    // 슬랙에 전송할 메시지 구성
    const message = {
        text: `**알람 발생 시간:** ${kstTimestamp}\n**알람 이유:** ${alarmReason}`
    };

    const parsedUrl = url.parse(slackWebhookUrl);
    const options = {
        hostname: parsedUrl.hostname,
        path: parsedUrl.path,
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        }
    };

    return new Promise((resolve, reject) => {
        const req = https.request(options, (res) => {
            res.on('data', (d) => {
                process.stdout.write(d);
            });
            res.on('end', () => {
                resolve({ statusCode: 200, body: '알림이 전송되었습니다.' });
            });
        });

        req.on('error', (e) => {
            reject({ statusCode: 500, body: `오류 발생: ${e.message}` });
        });

        req.write(JSON.stringify(message));
        req.end();
    });
};
