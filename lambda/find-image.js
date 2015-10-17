/*
 * AWS CloudFormation Windows HPC Template
 *
 * Copyright 2015 Amazon.com, Inc. or its affiliates. All Rights Reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License").
 * You may not use this file except in compliance with the License.
 * A copy of the License is located at
 *
 *  http://aws.amazon.com/apache2.0
 *
 * or in the "license" file accompanying this file. This file is distributed
 * on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
 * express or implied. See the License for the specific language governing
 * permissions and limitations under the License.
 */
 
/**
 * This AWS Lambda Function searches for an Amazon Machine Image by name.
 *  It is meant to be called as an AWS CloudFormation Custom Resource. (Check tool-find-image.json for such a template)
 *
 * Parameters accepted are: (documentation available at: http://docs.aws.amazon.com/AWSEC2/latest/APIReference/API_DescribeImages.html)
 *  - Architecture: used as the 'architecture' filter in the call to EC2 DescribeImages
 *  - VirtualizationType: used as the 'virtualization-type' filter in the call to EC2 DescribeImages
 *  - RootDeviceType: used as the 'root-device-type' filter in the call to EC2 DescribeImages
 *  - ImageName: used as the 'name' filter in the call to EC2 DescribeImages
 *  - Owner: used as the 'Owner' property in the call to EC2 DescribeImages
 *
 * Returns two properties:
 *  - ImageId: the identifier of the image
 *  - Reason: the reason for the success or error
 *
 * The AWS CloudFormation Custom Resource is marked as CREATE_FAILED when the image is not found.
 *
 * The resource supports update.
 */
var AWS = require('aws-sdk');
var ec2 = new AWS.EC2({region: process.env.AWS_REGION});

/// This part taken from http://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-properties-lambda-function-code.html 
SUCCESS = "SUCCESS";
FAILED = "FAILED";

function send_response(event, context, responseStatus, responseData, physicalResourceId) {
    var responseBody = JSON.stringify({
        Status: responseStatus,
        Reason: "See the details in CloudWatch Log Stream: " + context.logStreamName,
        PhysicalResourceId: physicalResourceId || context.logStreamName,
        StackId: event.StackId,
        RequestId: event.RequestId,
        LogicalResourceId: event.LogicalResourceId,
        Data: responseData
    });
 
    console.log("Response body:\n", responseBody);
 
    var https = require("https");
    var url = require("url");
 
    var parsedUrl = url.parse(event.ResponseURL);
    var options = {
        hostname: parsedUrl.hostname,
        port: 443,
        path: parsedUrl.path,
        method: "PUT",
        headers: {
            "content-type": "",
            "content-length": responseBody.length
        }
    };
 
    var request = https.request(options, function(response) {
        console.log("Status code: " + response.statusCode);
        console.log("Status message: " + response.statusMessage);
        context.done();
    });
 
    request.on("error", function(error) {
        console.log("send(..) failed executing https.request(..): " + error);
        context.done();
    });
 
    request.write(responseBody);
    request.end();
}
/// End copy

exports.handler = function(event, context) {
  var properties = event.ResourceProperties;
  var params = {
    Filters: [ 
      { Name: 'architecture', Values: [ properties.Architecture || 'x86_64' ] },
      { Name: 'virtualization-type', Values: [ properties.VirtualizationType || 'hvm' ] },
      { Name: 'root-device-type', Values: [ properties.RootDeviceType || 'ebs' ] },
      { Name: 'name', Values: [ properties.ImageName + '*' ] }
    ],
    Owners: [ properties.Owner || 'amazon' ]
  };
  if((event.RequestType == 'Create') || (event.RequestType == 'Update')) {
    ec2.describeImages(params, function(err, data) {
      if (err) {
        send_response(event, context, FAILED, { ImageId: '', Reason: 'An error occured while calling EC2:' + err });
      } else {
        var images = data.hasOwnProperty('Images') ? data.Images : [];
        if (images.length > 0) {
          images.sort(function (a, b) { return ((a.Name > b.Name) ? -1 : ((a.Name > b.Name) ? 0 : 1)) });
          send_response(event, context, SUCCESS, { ImageId: images[0].ImageId, Reason: 'Image found' });
        } else {
          send_response(event, context, FAILED, { ImageId: '', Reason: 'No such image found' });
        }
      }
    });
  } else {
    send_response(event, context, SUCCESS, { ImageId: '', Reason: 'Resource deleted' });
  }
};
