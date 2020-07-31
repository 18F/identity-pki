{
 "AWSTemplateFormatVersion": "2010-09-09",
  "Resources": {
    "SNSTopic": {
      "Type": "AWS::SNS::Topic",
      "Properties": {
        "TopicName": "${sns_topic_name}",
        "DisplayName": "${sns_display_name}",
        "Subscription": [
          ${sns_subscription_list}
        ]
      }
    }
  },
  "Outputs": {
    "SlackSNSTopic": {
      "Description": "ARN of the SNS topic",
      "Value": {
        "Ref": "SNSTopic"
      },
      "Export": {
        "Name": "SlackSNSTopic"
      }
    }
  }
}
