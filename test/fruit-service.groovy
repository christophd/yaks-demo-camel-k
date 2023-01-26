/*
 * Licensed to the Apache Software Foundation (ASF) under one or more
 * contributor license agreements.  See the NOTICE file distributed with
 * this work for additional information regarding copyright ownership.
 * The ASF licenses this file to You under the Apache License, Version 2.0
 * (the "License"); you may not use this file except in compliance with
 * the License.  You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

// camel-k: language=groovy
// camel-k: trait=service.enabled=true
// camel-k: trait=knative-service.enabled=false

def parameters = 'overrideEndpoint={{camel.component.aws2-s3.overrideEndpoint}}&' +
                    'uriEndpointOverride={{camel.component.aws2-s3.uriEndpointOverride}}&' +
                    'accessKey={{camel.component.aws2-s3.accessKey}}&' +
                    'secretKey={{camel.component.aws2-s3.secretKey}}&'+
                    'region={{camel.component.aws2-s3.region}}'

from('platform-http:/fruits')
  .log('received fruit ${body}')
  .unmarshal().json()
  .removeHeaders("*")
  .setHeader("CamelAwsS3Key", constant("fruit.json"))
  .choice()
    .when().simple('${body[nutrition][sugar]} <= 5')
        .setHeader("CamelAwsS3BucketName", constant("low-sugar"))
    .when().simple('${body[nutrition][sugar]} > 5 && ${body[nutrition][sugar]} <= 10')
        .setHeader("CamelAwsS3BucketName", constant("medium-sugar"))
    .otherwise()
        .setHeader("CamelAwsS3BucketName", constant("high-sugar"))
  .end()
  .marshal().json()
  .log('sending ${body}')
  .to("aws2-s3://noop?$parameters")
