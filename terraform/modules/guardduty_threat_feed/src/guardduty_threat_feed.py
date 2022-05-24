import boto3
import logging
import json
import hashlib
import hmac
import http.client
import urllib.request, urllib.parse, urllib.error
import time
import traceback
import email
from botocore.vendored import requests
from datetime import datetime
from os import environ
import cfnresponse

def lambda_handler(event, context):
    responseStatus = 'SUCCESS'
    reason = None
    responseData = {}
    result = {
        'statusCode': '200',
        'body':  {'message': 'success'}
    }

    try:
        #------------------------------------------------------------------
        # Set Log Level
        #------------------------------------------------------------------
        global log_level
        log_level = str(environ['LOG_LEVEL'].upper())
        if log_level not in ['DEBUG', 'INFO','WARNING', 'ERROR','CRITICAL']:
            log_level = 'ERROR'
        logging.getLogger().setLevel(log_level)

        #------------------------------------------------------------------
        # Read inputs parameters
        #------------------------------------------------------------------
        logging.getLogger().info(event)
        request_type = event['RequestType'].upper()  if ('RequestType' in event) else ""
        logging.getLogger().info(request_type)

        #----------------------------------------------------------
        # Extra check for DELETE events
        #----------------------------------------------------------
        if 'DELETE' in request_type:
            if 'ResponseURL' in event:
                cfnresponse.send(event, context, responseStatus, responseData)
            return json.dumps(result)

        #------------------------------------------------------------------
        # Set query parameters
        #------------------------------------------------------------------
        queryType = '/view/iocs?'
        query = {
            'startDate' : int(time.time()) - (int(environ['DAYS_REQUESTED'])*86400),
            'endDate' : int(time.time())
        }

        #------------------------------------------------------------------
        # Query 3rd Party service
        #------------------------------------------------------------------
        #Get Public and Private access key
        public_key = None
        private_key = None
        ssm = boto3.client('ssm')
        response = ssm.get_parameters(Names=[environ['PUBLIC_KEY'], environ['PRIVATE_KEY']], WithDecryption = True)
        for p in response['Parameters']:
            if p['Name'] == environ['PUBLIC_KEY']:
                public_key = str(p['Value'])
            elif p['Name'] == environ['PRIVATE_KEY']:
                private_key = str(p['Value'])

        #Create Query
        enc_q = queryType + urllib.parse.urlencode(query) + '&format=csv'

        #Generate proper accept_header for requested indicator type
        accept_header = 'text/csv'

        #Generate Hash for Auth
        timeStamp = email.utils.formatdate(localtime=True)
        data = enc_q + '2.6' + accept_header + str(timeStamp)
        private_key_bytes = bytes(private_key, 'utf-8')
        data_bytes = bytes(data, 'utf-8')
        hashed = hmac.new(private_key_bytes, data_bytes, hashlib.sha256).hexdigest()
        logging.getLogger().info(hashed)

        headers = {
            'Accept': accept_header,
            'Accept-Version': '2.6',
            'X-Auth': public_key,
            'X-Auth-Hash': hashed,
            'X-App-Name': 'mysight-api',
            'Date': timeStamp
        }

        #Get dataset
        conn = http.client.HTTPSConnection('api.isightpartners.com')
        conn.request('GET', enc_q, '', headers)
        response = conn.getresponse()
        result = {
            'statusCode': str(response.status),
            'body':  {'message': str(response.reason)}
        }
        logging.getLogger().debug(str(result))

        #------------------------------------------------------------------
        # Read Content
        #------------------------------------------------------------------
        timeStamp = datetime.now()
        fileName = "/tmp/iSIGHT_%s_%s_days.csv"%(timeStamp.strftime("%Y%m%d-%H%M%S"), environ['DAYS_REQUESTED'])
        with open(fileName, 'wb') as f:
            f.write(response.read())
            f.close()

        #------------------------------------------------------------------
        # Upload to S3
        #------------------------------------------------------------------
        s3 = boto3.client('s3')
        outputFileName = "iSIGHT/%s_%s_days.csv"%(timeStamp.strftime("%Y%m%d-%H%M%S"), environ['DAYS_REQUESTED'])
        s3.upload_file(fileName, environ['OUTPUT_BUCKET'], outputFileName, ExtraArgs={'ContentType': "application/CSV"})

        #------------------------------------------------------------------
        # Guard Duty
        #------------------------------------------------------------------
        location = "https://s3.amazonaws.com/%s/%s"%(environ['OUTPUT_BUCKET'], outputFileName)
        name = "TF-%s"%timeStamp.strftime("%Y%m%d")
        guardduty = boto3.client('guardduty')
        response = guardduty.list_detectors()

        if len(response['DetectorIds']) == 0:
            raise Exception('Failed to read GuardDuty info. Please check if the service is activated')

        detectorId = response['DetectorIds'][0]

        try:
            response = guardduty.create_threat_intel_set(
                Activate=True,
                DetectorId=detectorId,
                Format='FIRE_EYE',
                Location=location,
                Name=name
            )

        except Exception as error:
            logging.getLogger().error(str(error))
            reason = str(error)

            if "name already exists" in reason:
                found = False
                response = guardduty.list_threat_intel_sets(DetectorId=detectorId)
                for setId in response['ThreatIntelSetIds']:
                    response = guardduty.get_threat_intel_set(DetectorId=detectorId, ThreatIntelSetId=setId)
                    if (name == response['Name']):
                        found = True
                        response = guardduty.update_threat_intel_set(
                            Activate=True,
                            DetectorId=detectorId,
                            Location=location,
                            Name=name,
                            ThreatIntelSetId=setId
                        )
                        logging.getLogger().info("Response - Updated Threat Intel Set: {}".format(response))
                        break

                if not found:
                    raise

            elif "AWS account limits" in reason:
                #--------------------------------------------------------------
                # Limit reached. Try to rotate the oldest one
                #--------------------------------------------------------------
                oldestDate = None
                oldestID = None
                response = guardduty.list_threat_intel_sets(DetectorId=detectorId)
                for setId in response['ThreatIntelSetIds']:
                    response = guardduty.get_threat_intel_set(DetectorId=detectorId, ThreatIntelSetId=setId)
                    tmpName = response['Name']

                    if tmpName.startswith('TF-'):
                        setDate = datetime.strptime(tmpName.split('-')[-1], "%Y%m%d")
                        if oldestDate == None or setDate < oldestDate:
                            oldestDate = setDate
                            oldestID = setId

                if oldestID != None:
                    response = guardduty.update_threat_intel_set(
                        Activate=True,
                        DetectorId=detectorId,
                        Location=location,
                        Name=name,
                        ThreatIntelSetId=oldestID
                    )
                else:
                    raise

            else:
                raise


        #------------------------------------------------------------------
        # Update result data
        #------------------------------------------------------------------
        result = {
            'statusCode': '200',
            'body':  {'message': "You requested: %s day(s) of /view/iocs indicators in CSV"%environ['DAYS_REQUESTED']}
        }

    except Exception as error:
        logging.getLogger().error(str(error))
        responseStatus = 'FAILED'
        reason = str(error)
        result = {
            'statusCode': '500',
            'body':  { 'message': reason }
        }

    finally:
        #------------------------------------------------------------------
        # Send Result
        #------------------------------------------------------------------
        if 'ResponseURL' in event:
            print(str(event))
            cfnresponse.send(event, context, responseStatus, responseData)
        return json.dumps(result)
