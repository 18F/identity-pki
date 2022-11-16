# Read SQS and log SES events to CloudWatch Logs after replacing recipient/destination email address

from __future__ import print_function
import json

def lambda_handler(event, context):
    #print("Here is full event", event)
    for record in event['Records']:
        record_body = record["body"]
        message_dict = json.loads(record_body)
        message = message_dict['Message']

        conv = json.loads(message)

        #print("Here is the message in json", conv)
        event_type = conv['eventType']
        print("EventType:", event_type)

        mail_destination = conv['mail']['destination']
        headers_destination = conv['mail']['headers']
        common_headers = conv['mail']['commonHeaders']

        if(event_type == 'Bounce'):
            bounced_destination = conv['bounce']['bouncedRecipients']
            for bounced_recipient in bounced_destination:    
                email                             = bounced_recipient['emailAddress']
                scrubbed_email                    = hide_destination_email(email)
                bounced_recipient['emailAddress'] = scrubbed_email
            mail_section(mail_destination, headers_destination, common_headers, conv)

        elif(event_type == 'Complaint'):
            compliants_list = conv['complaint']['complainedRecipients']
            for complaining_recipient in compliants_list:    
                email                                 = complaining_recipient['emailAddress']
                scrubbed_email                        = hide_destination_email(email)
                complaining_recipient['emailAddress'] = scrubbed_email
                mail_section(mail_destination, headers_destination, common_headers, conv)
        
        elif(event_type == 'Delivery'):
            delivery_list = conv['delivery']['recipients']
            z = []
            for delivered_recipient in delivery_list:    
                scrubbed_email             = hide_destination_email(delivered_recipient)
                z.append(scrubbed_email)
            conv['delivery']['recipients'] = z
            mail_section(mail_destination, headers_destination, common_headers, conv)
        
        elif(event_type == 'Send'):
            #print("Event type Send does not log destination email in the send{} block")
            mail_section(mail_destination, headers_destination, common_headers, conv)
        
        elif(event_type == 'Reject'):
            #print("Event type Reject does not log destination email in the reject{} block")
            reason = conv['reject']['reason']
            print("Email was rejected for the reason:", reason)
            mail_section(mail_destination, headers_destination, common_headers, conv)

        elif(event_type == 'Open'):
            #print("Event type Open does not log destination email in the open{} block")
            ip_address = conv['open']['ipAddress']
            print("Email was opened by the ip address:", ip_address)
            mail_section(mail_destination, headers_destination, common_headers, conv)
        
        elif(event_type == 'Click'):
            #print("Event type Click does not log destination email in the click{} block")
            ip_address = conv['click']['ipAddress']
            print("Email was clicked from the ip address:", ip_address)
            mail_section(mail_destination, headers_destination, common_headers, conv)
        
        elif(event_type == 'Rendering Failure'):
            #print("Event type Rendering Failure does not log destination email in the failure{} block")
            error_message = conv['failure']['errorMessage']
            print("Error message for rendering failure:", error_message)
            mail_section(mail_destination, headers_destination, common_headers, conv)
        
        elif(event_type == 'DeliveryDelay'):
            delayed_lists = conv['deliveryDelay']['delayedRecipients']
            for delayed_recipient in delayed_lists:    
                email                                 = delayed_recipient['emailAddress']
                scrubbed_email                        = hide_destination_email(email)
                delayed_recipient['emailAddress']     = scrubbed_email
            mail_section(mail_destination, headers_destination, common_headers, conv)

        else:
            continue
         
                
#function to hide email desination from mail section

def mail_section(mail_destination, headers_destination, common_headers, conv):
        print("Hidding destination email from mail section")
        zz = []
        for recipient_email in mail_destination:
            #print(recipient_email)
            scrubbed_email=hide_destination_email(recipient_email)
            #print("Returned email", scrubbed_email)
            zz.append(scrubbed_email)

            for header in headers_destination:
                if(header['name'] == 'To'):
                  header['value'] = scrubbed_email
                  
            #print("Here is the common_headers", common_headers)
            #print("type of common_headers", type(common_headers))
            #for common_header in common_headers:
            #print(common_headers['to'])
            
            common_headers.update(to=scrubbed_email)    
                              
        conv['mail']['destination'] = zz

        final_log = json.dumps(conv)
        print("Message from SES events after replacing username from destination email addresses", final_log)
        
#Hiding the destination email address info "@"            
def hide_destination_email(email):
    position = email.index("@")
    updated_email = email[position:]
    return(updated_email)  