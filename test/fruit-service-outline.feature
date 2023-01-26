Feature: Camel K Fruit Store

  Background:
    Given URL: http://localhost:8080

  Scenario: Create infrastructure
    # Start AWS S3 container
    Given Enable service S3
    Given start LocalStack container

    # Create S3 client
    Given New global Camel context
    Given load to Camel registry amazonS3Client.groovy

    # Create Camel K integration
    Given Camel K integration property file aws-s3-credentials.properties
    When load Camel K integration fruit-service.groovy
    Then Camel K integration fruit-service should print Started route1 (platform-http:///fruits)

  Scenario Outline: Verify fruit service (<name>)
    # Invoke Camel K service
    Given HTTP request body
    """
    {
      "id": <id>,
      "name": "<name>",
      "category":{
        "id": "citrus:randomNumber(1)",
        "name":"<category>"
      },
      "nutrition":{
        "calories": <calories>,
        "sugar": <sugar>
      },
      "status": "<status>",
      "price": <price>,
      "tags": []
    }
    """
    And HTTP request header Content-Type="application/json"
    When send POST /fruits
    Then receive HTTP 200 OK

    # Verify uploaded S3 file
    Given Camel exchange message header CamelAwsS3Key="fruit.json"
    Given receive Camel exchange from("aws2-s3://<bucket>?amazonS3Client=#amazonS3Client&deleteAfterRead=true") with body
    """
    {
      "id": <id>,
      "name": "<name>",
      "category":{
        "id": "@isNumber()@",
        "name":"<category>"
      },
      "nutrition":{
        "calories": <calories>,
        "sugar": <sugar>
      },
      "status": "<status>",
      "price": <price>,
      "tags": []
    }
    """

  Examples:
    | id   | name       | category | price | calories | sugar | status    | bucket       |
    | 1000 | Apple      | pome     | 1.59  | 52       | 11    | AVAILABLE | high-sugar   |
    | 1001 | Pineapple  | tropical | 1.99  | 50       | 9     | PENDING   | medium-sugar |
    | 1002 | Strawberry | berry    | 2.55  | 29       | 5     | SOLD      | low-sugar    |

  Scenario: Remove infrastructure
    # Remove Camel K resources
    Given delete Camel K integration fruit-service
    # Stop AWS S3 container
    Given stop LocalStack container