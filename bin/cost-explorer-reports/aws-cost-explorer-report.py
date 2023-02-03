#!/usr/bin/env python3

import boto3
import click

from calendar import monthrange
from datetime import datetime, timedelta

from fpdf import FPDF
from prettytable import PrettyTable
import csv

# define table layout
pt = PrettyTable()

pt.field_names = [
    'TimePeriodStart',
    'LinkedAccount',
    'Service',
    'Amount',
    'Unit'
]

pt.align = "l"
pt.align["Amount"] = "r"


def get_cost_and_usage(bclient: object, start: str, end: str) -> list:
    cu = []

    while True:
        data = bclient.get_cost_and_usage(
            TimePeriod={
                'Start': start,
                'End': end,
            },
            Granularity='MONTHLY',
            Metrics=[
                'UnblendedCost',
            ],
            GroupBy=[
                {
                    'Type': 'DIMENSION',
                    'Key': 'LINKED_ACCOUNT',
                },
                {
                    'Type': 'DIMENSION',
                    'Key': 'SERVICE',
                }
            ],
        )

        cu += data['ResultsByTime']
        token = data.get('NextPageToken')

        if not token:
            break

    return cu


def fill_table_content(results: list, start: str, end: str) -> float:
    total = 0
    pt.clear_rows()
    for result_by_time in results:
        for group in result_by_time['Groups']:
            amount = float(group['Metrics']['UnblendedCost']['Amount'])
            unit = group['Metrics']['UnblendedCost']['Unit']
            total += amount
            # Skip, if total amount less then 0.00001 USD
            if amount < 0.00001:
                continue

            pt.add_row([
                result_by_time['TimePeriod']['Start'],
                group['Keys'][0],
                group['Keys'][1],
                format(amount, '0.5f'),
                unit,
            ])
    print("Total: {:5f}".format(total))
    return total


def convert_to_csv(pt: PrettyTable, file_name: str, total: float):
    with open(file_name, 'w', newline='') as f:
        writer = csv.writer(f)
        writer.writerow(pt.field_names)
        for row in pt.rows:
            writer.writerow(row)
        writer.writerow(["", "", "Total:", "{:5f}".format(total), ""])


def convert_to_pdf(pt: PrettyTable, file_name: str, total: float):
    # Convert the prettytable to a list of lists
    table_list = pt.rows

    # Save the prettytable to a PDF file
    pdf = FPDF(orientation="landscape", format="A3")
    pdf.add_page()
    pdf.set_font("helvetica", size=10)

    # Write header
    for col_title in pt.field_names:
        pdf.cell(80, 10, txt=col_title, border=1)
    pdf.ln()

    # Write rows
    for row in table_list:
        for item in row:
            pdf.cell(80, 10, txt=item, border=1)
        pdf.ln()

    # Write total
    for item in ["", "", "Total:", "{:5f}".format(total), ""]:
        pdf.cell(80, 10, txt=item, border=0)
    pdf.ln()

    pdf.output(file_name)


def first_day_next_month(date_str: str) -> str:
    date = datetime.strptime(date_str, "%Y-%m-%d")
    if date.month == 12:
        next_month = date.replace(year=date.year+1, month=1, day=1)
    else:
        next_month = date.replace(month=date.month+1, day=1)
    return next_month.strftime("%Y-%m-%d")


@click.command()
@click.option('-P', '--profile', help='profile name')
@click.option('-S', '--start', help='start date (default: 1st date of current month)')
@click.option('-E', '--end', help='end date (default: last date of current month)')
@click.option('-F', '--file', help='input file path')
def report(profile: str, start: str, end: str, file: str) -> None:
    SERVICE_NAME = 'ce'

    if file:
        with open(file, "r") as file:
            reader = csv.reader(file)
            header = next(reader)
            data = []
            for row in reader:
                row_data = {header[i]: row[i] for i in range(len(header))}
                data.append(row_data)
        for item in data:
            start_date = item['TimePeriodStart']
            end_date = item['TimePeriodEnd']
            # aws_access_key_id = item['AWS_ACCESS_KEY_ID']
            # aws_secret_access_key = item['AWS_SECRET_ACCESS_KEY']
            boto3_client = boto3.client(SERVICE_NAME)
            # Convert the start and end dates to datetime objects
            start_date = datetime.strptime(start_date, "%Y-%m-%d")
            end_date = datetime.strptime(end_date, "%Y-%m-%d")

            # Initialize a list to store the monthly dates
            monthly_dates = []

            # Get the next date by adding one month to the start date
            current_date = start_date
            while current_date <= end_date:
                monthly_dates.append(current_date.strftime("%Y-%m-%d"))
                current_date += timedelta(days=monthrange(current_date.year, current_date.month)[1])
            for start in monthly_dates:
                end = first_day_next_month(start)

                results = get_cost_and_usage(boto3_client, start, end)
                total = fill_table_content(results, start, end)

                print(pt)

                convert_to_csv(pt, f'output/csv/report_{start}_{end}.csv', total)
                convert_to_pdf(pt, f'output/pdf/report_{start}_{end}.pdf', total)
    else:
        # set start/end to current month if not specify
        if not start or not end:
            # get last day of month by `monthrange()`
            # ref: https://stackoverflow.com/a/43663
            ldom = monthrange(datetime.today().year, datetime.today().month)[1]

            start = datetime.today().replace(day=1).strftime('%Y-%m-%d')
            end = datetime.today().replace(day=ldom).strftime('%Y-%m-%d')

        # cost explorer
        boto3_client = boto3.Session(profile_name=profile).client(SERVICE_NAME)

        results = get_cost_and_usage(boto3_client, start, end)
        total = fill_table_content(results, start, end)

        print(pt)

        convert_to_csv(pt, f'output/csv/{profile}_{start}_{end}.csv', total)
        convert_to_pdf(pt, f'output/pdf/{profile}_{start}_{end}.pdf', total)


if __name__ == '__main__':
    report()