#!/usr/bin/env python

# Removes default routes for all subnets for a given VPC

import argparse
import botocore
import boto3
import pprint
import sys


DEFAULT_REGION = "us-west-2"


def parse_commandline_arguments():
    parser = argparse.ArgumentParser(
        # formatter_class=argparse.ArgumentDefaultsHelpFormatter,
        description="Cut off Internet access for a VPC by deleting default routes",
    )

    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument(
        "-e",
        "--environment",
        dest="environment",
        type=str,
        help="Specify application environment VPC",
    )
    group.add_argument(
        "-v", "--vpcid", dest="vpcid", type=str, help="Specify the VPC by ID"
    )
    group.add_argument(
        "-n", "--vpcname", dest="vpcname", type=str, help="Specify the VPC by name"
    )

    parser.add_argument(
        "-r",
        "--region",
        dest="region",
        type=str,
        default=DEFAULT_REGION,
        help="Specify the region of the AWS Account",
    )

    parser.add_argument(
        "--test",
        dest="test",
        action="store_true",
        help="Run in test/dry run mode",
    )
    return parser.parse_args()


def get_vpc_id(vpc_name, region=DEFAULT_REGION):
    ec2 = boto3.resource("ec2", region_name=region)
    filters = [{"Name": "tag:Name", "Values": [vpc_name]}]
    vpcs = list(ec2.vpcs.filter(Filters=filters))

    if len(vpcs) == 0:
        raise RuntimeError(f'No VPC ID found for VPC name "{vpc_name}"')
    elif len(vpcs) > 1:
        raise RuntimeError(f'Multiple VPCs found matching the name "{vpc_name}"')

    return vpcs[0].id


def get_vpc_name(vpc_id, region=DEFAULT_REGION):
    ec2 = boto3.resource("ec2", region_name=region)
    filters = [{"Name": "vpc-id", "Values": [vpc_id]}]
    vpcs = list(ec2.vpcs.filter(Filters=filters))

    if len(vpcs) == 0:
        raise RuntimeError(f'No VPC ID found for VPC ID "{vpc_id}"')

    for tag in vpcs[0].tags:
        if tag["Key"] == "Name":
            return tag["Value"]

    return ""


def enumerate_default_routes(vpc_id, region=DEFAULT_REGION):
    default_routes = {}
    client = boto3.client("ec2", region)
    resp_rt_table = client.describe_route_tables(
        Filters=[{"Name": "vpc-id", "Values": [vpc_id]}]
    )["RouteTables"]

    for rt in resp_rt_table:
        rt_routes = []

        for route in rt["Routes"]:
            if (
                "DestinationCidrBlock" in route
                and route["DestinationCidrBlock"] == "0.0.0.0/0"
            ):
                rt_routes.append(route)
            elif (
                "DestinationIpv6CidrBlock" in route
                and route["DestinationIpv6CidrBlock"] == "::/0"
            ):
                rt_routes.append(route)

        if len(rt_routes) > 0:
            default_routes[rt["RouteTableId"]] = rt_routes

    return default_routes


def delete_routetable_routes(routetable_routes, dry_run=False, region=DEFAULT_REGION):
    client = boto3.client("ec2", region)

    for (routetable, routes) in routetable_routes.items():
        for route in routes:
            delete_params = {
                k: v
                for (k, v) in route.items()
                if k in ["DestinationCidrBlock", "DestinationIpv6CidrBlock"]
            }
            delete_params["RouteTableId"] = routetable
            print(f"Processing {delete_params}")
            delete_params["DryRun"] = dry_run

            try:
                client.delete_route(**delete_params)
            except botocore.exceptions.ClientError as err:
                # Attempt to proceed on client failures
                code = err.response["Error"]["Code"]
                msg = err.response["Error"]["Message"]
                if code == "DryRunOperation":
                    sys.stderr.write(f"DRYRUN on {delete_params}: {msg}\n")
                else:
                    sys.stderr.write(f"ERROR on {delete_params}: {msg}\n")


def main():
    args = parse_commandline_arguments()

    if args.environment:
        vpc_name = f"login-vpc-{args.environment}"
        vpc_id = get_vpc_id(vpc_name, region=args.region)
    elif args.vpc_name:
        vpc_name = args.vpcname
        vpc_id = get_vpc_id(vpc_name, region=args.region)
    else:
        vpc_id = args.vpcid
        vpc_name = get_vpc_name(vpc_id)

    default_routes = enumerate_default_routes(vpc_id, region=args.region)

    if len(default_routes) == 0:
        print(f"No matching routes found for VPC {vpc_id} ({vpc_name})")
        sys.exit(0)

    print(f"Preparing to delete the following routes from VPC {vpc_id} ({vpc_name})\n")
    for (rt, routes) in default_routes.items():
        print(
            f"RouteTableId: {rt}\n",
            "\n".join([pprint.pformat(r) for r in routes]),
            "\n",
        )

    ans = input("ARE YOU SURE YOU WANT TO DELETE THESE ROUTES (y/n)? ")

    if ans.lower() not in ["y", "yes"]:
        print("\nCANCELLED")
        sys.exit(0)

    delete_routetable_routes(default_routes, dry_run=args.test, region=args.region)

    print("\nWARNING: Halt automated Terraform activity to prevent restoring access!")
    sys.exit(0)


if __name__ == "__main__":
    main()
