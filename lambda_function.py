import json
import boto3

def lambda_handler(event, context):
    client = boto3.client('dynamodb')
    response = client.update_item(
        TableName='CloudResume',
        Key={'Name': {'S': 'VisitorCount'}},
        UpdateExpression='ADD #V :v',
        ExpressionAttributeNames={"#V":"Value"},
        ExpressionAttributeValues={":v": {"N":"1"}},
        ReturnValues='UPDATED_NEW')
    return {
        'statusCode': 200,
        'body': response['Attributes']
    }
