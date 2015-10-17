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
 * This AWS Lambda Function searches for an Amazon EBS Snapshot by the name tag.
 *  It is meant to be called as an AWS CloudFormation Custom Resource. (Check tool-find-snapshot.json for such a template)
 *
 * Parameters accepted are: (documentation available at: http://docs.aws.amazon.com/AWSEC2/latest/APIReference/API_DescribeSnapshots.html)
 *  - SnapshotName: used to filter the 'Name' tag in the call to EC2 DescribeSnapshots
 *
 * Returns two properties:
 *  - SnapshotId: the identifier of the snapshot
 *  - Reason: the reason for the success or error
 *
 * The AWS CloudFormation Custom Resource is marked as CREATE_FAILED when the snapshot is not found.
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
      { Name: 'tag:Name', Values: [ properties.SnapshotName ] }
    ],
    RestorableByUserIds: [ 'self' ]
  };
  if((event.RequestType == 'Create') || (event.RequestType == 'Update')) {
    ec2.describeSnapshots(params, function(err, data) {
      if (err) {
        send_response(event, context, FAILED, { SnapshotId: '', Reason: 'An error occured while calling EC2:' + err });
      } else {
        var snapshots = data.hasOwnProperty('Snapshots') ? data.Snapshots : [];
        if (snapshots.length > 0) {
          snapshots.sort(function (a, b) { return ((a.Name > b.Name) ? -1 : ((a.Name > b.Name) ? 0 : 1)) });
          send_response(event, context, SUCCESS, { SnapshotId: snapshots[0].SnapshotId, Reason: 'Snapshot found' });
        } else {
          send_response(event, context, FAILED, { SnapshotId: '', Reason: 'No such snapshot found' });
        }
      }
    });
  } else {
    send_response(event, context, SUCCESS, { SnapshotId: '', Reason: 'Resource deleted' });
  }
};
