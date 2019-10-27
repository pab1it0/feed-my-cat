'use strict';

const AWS = require('aws-sdk');
const ssm = new AWS.SSM();
const sns = new AWS.SNS();

const lastFeedingTimeVar = process.env.LAST_FEEDING_TIME_VAR;
const isAlertEmailSentVar = process.env.IS_ALERT_EMAIL_SENT_VAR;
const isBackToNormalEmailSentVar = process.env.IS_BACK_TO_NORMAL_EMAIL_SENT_VAR;
const topicArn = process.env.TOPIC_ARN;

const hungryTreshold = 900000; // 15 min in milliseconds

exports.handler = async (event) => {
    const currentTimeStr = Date.now().toString();
    const lastFedStr = await getParameter(lastFeedingTimeVar);
    const lastFedDate = new Date(parseInt(lastFedStr)).toTimeString();
    console.log(`Current time: ${currentTimeStr}`);
    console.log(`Last fed: ${lastFedStr}`);

    if (isMitsiHungry(currentTimeStr, lastFedStr)) return handleAlert(lastFedDate);
    return handleBackToNormal(lastFedDate);
};

function isMitsiHungry(currentTimeStr, lastFedDate) {
    const hungryTime = parseInt(currentTimeStr) - parseInt(lastFedDate)
    if (hungryTime > hungryTreshold) {
        console.log(`Cat wasn't fed for the past ${Math.ceil(hungryTime/60000)} minutes`);
        return true;
    }
    return false;
};

async function handleBackToNormal(lastFedDate) {
    const isBackToNormalEmailSent = await getParameter(isBackToNormalEmailSentVar);
    if (isBackToNormalEmailSent == '1') {
        console.log(`Cat's femished and everybody already knows that :)`)
        return true;
    }

    const message = `Cat was fed at ${lastFedDate}. Calm down you guys ...`
    console.log(message);
    return dispatchSNS(message).then(response => {
        console.log(response);
        return putParameter(isBackToNormalEmailSentVar, '1').then(response => {
            console.log(`isBackToNormalEmailSentVar was set to TRUE`);
            return putParameter(isAlertEmailSentVar, '0').then(response => {
                console.log(`isAlertEmailSentVar was set to FALSE`);
                return true;
            });
    }).catch(error => {
        console.log(error);
        return error;
        });
    });
};

async function handleAlert(lastFedDate) {
    const isAlertEmailSent = await getParameter(isAlertEmailSentVar);
    if (isAlertEmailSent == '1') {
        console.log(`Cat's hungry and everybody already knows that :)`)
        return true;
    }
    const message = `Cat wasn't fed for more than 15 min, last time she was fed was ${lastFedDate}. FEED IT!!!`
    console.log(message);
    return dispatchSNS(message).then(response => {
        console.log(response);
        return putParameter(isAlertEmailSentVar, '1').then(response => {
            console.log(`isAlertEmailSentVar was set to TRUE`);
            return putParameter(isBackToNormalEmailSentVar, '0').then(response => {
                console.log(`isBackToNormalEmailSentVar was set to FALSE`);
                return true;
            });
    }).catch(error => {
        console.log(error);
        return error;
        });
    });
};

function dispatchSNS(message) {
    var params = {
        Message: message, 
        Subject: "Cat's hunger status",
        TopicArn: topicArn
    };

    return sns.publish(params).promise().then(data => {
        return data;
    });
};

function putParameter(paramName, value) {
    var params = {
        Name: paramName,
        Type: 'String', 
        Value: value,
        Overwrite: true
    };
    
    return ssm.putParameter(params).promise().then(data => {
        return true;
    });
}

function getParameter(param) {
    var params = {
        Name: param, 
        WithDecryption: true
    };

    return ssm.getParameter(params).promise().then(data => {
        return data.Parameter.Value;
    });
};
