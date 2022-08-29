# Read SQS and log them as well formed JSON in CloudWatch Logs

from __future__ import print_function
import json

def lambda_handler(event, context):
    for record in event['Records']:
        payload = record["body"]
        logs_data = json.loads(payload)
        message = logs_data['Message']

        conv = json.loads(message)
        notification_type = conv['notificationType']

        if(notification_type == 'Bounce'):
            bounce_destination = conv['bounce']['bouncedRecipients']
            for x in bounce_destination:    
                email = x['emailAddress']
                text=hide_destination_email(email)
                x['emailAddress'] = text
        
        elif(notification_type == 'Complaint'):
            compliants_list = conv['complaint']['complainedRecipients']
            for xy in compliants_list:    
                email = xy['emailAddress']
                text=hide_destination_email(email)
                xy['emailAddress'] = text
        
        elif(notification_type == 'Delivery'):
            delivery_list = conv['delivery']['recipients']
            z = []
            for xz in delivery_list:    
                text=hide_destination_email(xz)
                z.append(text)
            conv['delivery']['recipients'] = z
        
        else:
            continue
        
        mail_destination = conv['mail']['destination']

        zz = []
        for y in mail_destination:
            #print(y)
            updated_email_2=hide_destination_email(y)
            #print("Returned email", updated_email_2)
            zz.append(updated_email_2)
        conv['mail']['destination'] = zz

        final_log = json.dumps(conv)
        print(final_log)
        
#Hiding the destination email address info "@"            
def hide_destination_email(email):
    position = email.index("@")
    updated_email = email[position:]
    return(updated_email)  
