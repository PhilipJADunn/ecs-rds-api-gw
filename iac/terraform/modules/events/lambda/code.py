import json
import psycopg2
import os
import boto3

RDS_HOST = os.getenv('RDS_HOST')
RDS_USER = os.getenv('RDS_USER')
RDS_PASSWORD = os.getenv('RDS_PASSWORD')
RDS_DB_NAME = os.getenv('RDS_DB_NAME')
RDS_PORT = 5432
SQS_QUEUE_URL = os.getenv('SQS_QUEUE_URL')

sqs = boto3.client('sqs')

def insert_into_rds(message):
    try:
        connection = psycopg2.connect(
            host=RDS_HOST,
            user=RDS_USER,
            password=RDS_PASSWORD,
            database=RDS_DB_NAME,
            port=RDS_PORT
        )
        
        cursor = connection.cursor()

        name = message['name']
        occupation = message['occupation']
        
        query = "INSERT INTO users (name, occupation) VALUES (%s, %s)"
        cursor.execute(query, (name, occupation))
        connection.commit()
        cursor.close()
        connection.close()

    except Exception as e:
        print(f"Error inserting into RDS: {e}")

def lambda_handler(event, context):
    for record in event['Records']:
        sqs_message = json.loads(record['body'])
        insert_into_rds(sqs_message)

    return {
        'statusCode': 200,
        'body': json.dumps('Successfully processed messages')
    }
