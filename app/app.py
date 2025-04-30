from flask import Flask, request, jsonify
import boto3
import os

app = Flask(__name__)

sns_client = boto3.client('sns', region_name=os.environ.get('AWS_REGION', 'eu-west-1'))
sns_topic_arn = os.environ.get('SNS_TOPIC_HERE')

@app.route('/notify', methods=['POST'])
def notify_sns():
    data = request.get_json()
    message = data.get('message')
    
    if not message:
        return jsonify({'error': 'No message provided'}), 400

    try:
        sns_client.publish(
            TopicArn=sns_topic_arn,
            Message=message,
            Subject='Notification from ECS Backend Gateway'
        )
        return jsonify({'status': 'Message sent to SNS'}), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
