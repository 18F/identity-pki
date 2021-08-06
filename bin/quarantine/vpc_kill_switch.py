#!/usr/bin/env python

import boto3
import argparse


DEFAULT_REGION = "us-west-2"

def parse_commandline_arguments():

    global VPC_ID
    global VPC_NAME
    global REGION
    
    parser = argparse.ArgumentParser(formatter_class=argparse.ArgumentDefaultsHelpFormatter,
                                     description='Enable S3 Server Logging if Not enabled.')

    parser.add_argument("-v", "--vpcid", dest="vpcid", type=str, help="Specify the vpc id")
    parser.add_argument("-vn", "--vpcname", dest="vpcname", type=str, help="Specify the vpc name")

    parser.add_argument("-r", "--region", dest="region", type=str,
                        default=DEFAULT_REGION, help="Specify the region of the AWS Account")
    
    args = parser.parse_args()
    VPC_ID = args.vpcid
    VPC_NAME = args.vpcname
    REGION = args.region


if __name__ == '__main__':
    parse_commandline_arguments()
    
    if (VPC_ID or VPC_NAME):

        ec2 = boto3.resource('ec2', region_name=REGION)
        client = boto3.client('ec2', REGION)

        if (not VPC_ID):
            filters = [{'Name': 'tag:Name', 'Values': [VPC_NAME]}]
            vpcs = list(ec2.vpcs.filter(Filters=filters))
            if (vpcs[0]):
                VPC_ID=vpcs[0].id

        if VPC_ID:
            resp_rt_table = client.describe_route_tables(Filters = [{'Name': 'vpc-id', 'Values': [VPC_ID]}]) ['RouteTables']
            #print(resp_rt_table)

            for rt in resp_rt_table:
                #print(rt['RouteTableId'])
                #print(rt['Routes'])

                for route in rt['Routes']:
                    #print(route)
                    if 'DestinationCidrBlock' in route:
                        if (route['DestinationCidrBlock'] == '0.0.0.0/0'):
                            print(route)
                            ans="N"
                            ans = input("Are you sure (Y/N)?")
                            if ans.upper()=="Y":
                                try:
                                    client.delete_route(
                                        DestinationCidrBlock=route['DestinationCidrBlock'], RouteTableId=rt['RouteTableId'])
                                    print("Route Deleted for "+str(route['DestinationCidrBlock']))
                                except:
                                    pass
                    
                    elif 'DestinationIpv6CidrBlock' in route:
                        if (route['DestinationIpv6CidrBlock'] == "::/0"):
                            print(route)
                            ans = "N"
                            ans = input("Are you sure (Y/N)?")
                            if ans.upper() == "Y":
                                try:
                                    client.delete_route(
                                        DestinationIpv6CidrBlock=route['DestinationIpv6CidrBlock'], RouteTableId=rt['RouteTableId'])
                                    print("Route Deleted for " +
                                          str(route['DestinationIpv6CidrBlock']))
                                except:
                                    pass

    else:
        print("Specify the VPC name or VPC id")