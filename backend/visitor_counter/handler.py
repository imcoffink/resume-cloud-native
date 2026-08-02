import json
import os

import boto3

COUNTER_ID = "visitor_count"

dynamodb = boto3.resource("dynamodb")


def handler(event, context):
    table = dynamodb.Table(os.environ["TABLE_NAME"])

    response = table.update_item(
        Key={"id": COUNTER_ID},
        UpdateExpression="ADD #count :incr",
        ExpressionAttributeNames={"#count": "count"},
        ExpressionAttributeValues={":incr": 1},
        ReturnValues="UPDATED_NEW",
    )
    count = int(response["Attributes"]["count"])

    return {
        "statusCode": 200,
        "headers": {
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": "*",
        },
        "body": json.dumps({"count": count}),
    }
