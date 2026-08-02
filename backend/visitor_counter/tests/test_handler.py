import json
import os

os.environ["TABLE_NAME"] = "resume-visitor-count"

import boto3
import pytest
from moto import mock_aws

from backend.visitor_counter.handler import handler


@pytest.fixture
def dynamodb_table():
    with mock_aws():
        client = boto3.client("dynamodb", region_name="eu-central-1")
        client.create_table(
            TableName=os.environ["TABLE_NAME"],
            KeySchema=[{"AttributeName": "id", "KeyType": "HASH"}],
            AttributeDefinitions=[{"AttributeName": "id", "AttributeType": "S"}],
            BillingMode="PAY_PER_REQUEST",
        )
        yield


def test_handler_starts_count_at_one(dynamodb_table):
    response = handler({}, None)

    assert response["statusCode"] == 200
    assert json.loads(response["body"]) == {"count": 1}


def test_handler_increments_on_repeated_calls(dynamodb_table):
    handler({}, None)
    handler({}, None)
    response = handler({}, None)

    assert json.loads(response["body"]) == {"count": 3}


def test_handler_sets_cors_header(dynamodb_table):
    response = handler({}, None)

    assert response["headers"]["Access-Control-Allow-Origin"] == "*"
