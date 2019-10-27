'use strict';

const AWS = require('aws-sdk');
const rekognition = new AWS.Rekognition();
const ssm = new AWS.SSM();

const lastFeedingTime = process.env.LAST_FEEDING_TIME_VAR;

exports.handler = async (event) => {

  const s3Record = event.Records[0].s3;
  const bucket = s3Record.bucket.name;
  const key = s3Record.object.key;

  console.log(`A file named ${key} was put in a bucket ${bucket}`);

  return detectLabels(bucket, key).then(labels => {
    console.log(labels);
    const isFood = checkIsFood(labels);

    if (isFood) return feedCat();

  }).catch(error => {
    return error;
  })

};

function detectLabels(bucket, key) {
  const params = {
    Image: {
     S3Object: {
      Bucket: bucket, 
      Name: key
     }
    }, 
    MaxLabels: 5, 
    MinConfidence: 90
   };

   return rekognition.detectLabels(params).promise().then(data => {
      return data.Labels;
   }).catch(error => {
        console.log(error);
        return error;
   });  
}

function checkIsFood(labels) {
  return labels
  .map(label => {
    return ['Fish', 'Milk', 'Bread'].indexOf(label.Name) >= 0 ? true : false
  }).some( val => {
    return val === true;
  });
}

function feedCat() {
    const date = Date.now().toString();
    return putParameter(lastFeedingTime, date).then(response => {
        console.log(`Cat was fed at ${date}`);
        return true
    })
}

function putParameter(paramName, value) {
    var params = {
        Name: paramName,
        Type: 'String', 
        Value: value,
        Overwrite: true
    };
   
    return ssm.putParameter(params).promise().then(data => {
        return true;
    })
}
