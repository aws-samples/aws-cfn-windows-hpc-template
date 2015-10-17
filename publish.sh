#!/bin/bash

# AWS CloudFormation Windows HPC Template
#
# Copyright 2015 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License").
# You may not use this file except in compliance with the License.
# A copy of the License is located at
#
#  http://aws.amazon.com/apache2.0
#
# or in the "license" file accompanying this file. This file is distributed
# on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
# express or implied. See the License for the specific language governing
# permissions and limitations under the License.

#
# This script publishes the local AWS CloudFormation templates to an Amazon S3 bucket
#

ARGC=$#

function help {
  echo "Usage: $( basename $BASH_SOURCE ) <bucket> <prefix>"
  echo " - <bucket>: the Amazon S3 bucket that will store the AWS CloudFormation templates"
  echo " - <prefix>: the prefix in this bucket that will be used to store the data"
  echo ""
}

if [ "${ARGC}" -eq 0 ]; then
  help
  return -1
fi

BUCKET="$1"

if [ -z "${BUCKET}" ]; then
  echo "You must specify a valid destination bucket"
  echo ""
  help
  return -1
fi

if [ "${ARGC}" -eq 1 ]; then
  echo "No prefix specified, will use the bucket root as a destination"
  PREFIX=""
else
  PREFIX="$2"
  PREFIX="${PREFIX#/}"
  PREFIX="${PREFIX%/}"
fi

if [ -z "${PREFIX}" ]; then
  FILESPREFIX=""
  DESTINATION="${BUCKET}"
  HTTP_DESTINATION="https://${BUCKET}.s3.amazonaws.com"
else
  FILESPREFIX="${PREFIX}/"
  DESTINATION="${BUCKET}/${PREFIX}"
  HTTP_DESTINATION="https://${BUCKET}.s3.amazonaws.com/${PREFIX}"
fi

echo "#####"
echo "Publishing files to 's3://${DESTINATION}'"

cd lambda
echo ""
echo "Publishing AWS Lambda function sources"

for i in *.js; do
  zip $i.tmp $i
  aws s3 cp $i.tmp "s3://${DESTINATION}/lambda/$( basename $i .js ).zip"
  rm $i.tmp
done
cd ..

cd cfn-init
echo ""
echo "Publishing PowerShell Scripts"
for i in *.ps1; do
  aws s3 cp $i "s3://${DESTINATION}/cfn-init/$i"
done

echo ""
echo "Publishing Configuration Files"
for i in *.conf; do
  aws s3 cp $i "s3://${DESTINATION}/cfn-init/$i"
done
cd ..

echo ""
echo "Publishing AWS CloudFormation templates"
for i in *.json; do
  sed -e "s#<SUBSTACKSOURCE>#${HTTP_DESTINATION}/#g" -e "s#<BUCKETNAME>#${BUCKET}#g" -e "s#<PREFIX>#${FILESPREFIX}#g" -e "s#<DESTINATION>#${DESTINATION}#g" < $i > $i.tmp
  aws s3 cp $i.tmp "s3://${DESTINATION}/$i"
  rm $i.tmp
done

cd cfn
echo ""
echo "Publishing AWS CloudFormation sub stacks"
for i in *.json; do
  sed -e "s#<SUBSTACKSOURCE>#${HTTP_DESTINATION}/#g" -e "s#<BUCKETNAME>#${BUCKET}#g" -e "s#<PREFIX>#${FILESPREFIX}#g" -e "s#<DESTINATION>#${DESTINATION}#g" < $i > $i.tmp
  aws s3 cp $i.tmp "s3://${DESTINATION}/cfn/$i"
  rm $i.tmp
done
cd ..
echo "Start the cluster by using the '${HTTP_DESTINATION}/0-all.json' AWS CloudFormation Stack"
