#!/usr/bin/env python

import boto3
import argparse


DEFAULT_REGION = "us-west-2"

def parse_commandline_arguments():

    global VPC_ID
    global REGION
    
    parser = argparse.ArgumentParser(formatter_class=argparse.ArgumentDefaultsHelpFormatter,
                                     description='Enable S3 Server Logging if Not enabled.')

    parser.add_argument("-v", "--vpcid", dest="vpcid", type=str, help="Specify the vpc id")
    parser.add_argument("-r", "--region", dest="region", type=str,
                        default=DEFAULT_REGION, help="Specify the region of the AWS Account")
    
    args = parser.parse_args()
    VPC_ID = args.vpcid
    REGION = args.region


if __name__ == '__main__':
    parse_commandline_arguments()

   

    client = boto3.client('ec2', REGION)
    resp_rt_table = client.describe_route_tables(Filters = [{'Name': 'vpc-id', 'Values': [VPC_ID]}]) ['RouteTables']
    #print(resp_rt_table)

    for rt in resp_rt_table:
        #print(rt['RouteTableId'])
        #print(rt['Routes'])

        for route in rt['Routes']:
            if 'DestinationCidrBlock' in route:
                if (route['DestinationCidrBlock'] == '0.0.0.0/0'):
                    #print(route)
                    try:
                        client.delete_route(
                            DestinationCidrBlock=route['DestinationCidrBlock'], RouteTableId=rt['RouteTableId'])
                        print("Route Deleted for "+str(route['DestinationCidrBlock']))
                    except:
                        pass