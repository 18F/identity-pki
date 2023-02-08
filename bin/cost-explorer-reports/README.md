# AWS Cost Explorer Pretty Report written in Python

### Method adapted from @guessi via https://github.com/guessi/aws-cost-explorer-report 

Script has been modified to add monthly reports by taking dates from input.csv file for Start and End dates. 
The ouput is stored locally in your machine in csv and pdf format in the output directory under output/csv and output/pdf.

These directories need to be created beforehand in your local machine.

To execute the script you need to use 'aws-vault exec $profile' so that you get the AWS Profile to execute the AWS API
and generate reports.

Also note, the following AWS restriction in relation to data availability
 - Max months for data available is 12 months for Cost Explorer Reports. 

## Prerequisites

- Python 3.10 (or later)


## Setup Requirements

```bash
$ pipenv install
```

or

```bash
$ pip3 install -r requirements.txt
```

## Usage

```bash
$ ./aws-cost-explorer-report.py --help

Usage: aws-cost-explorer-report.py [OPTIONS]

Options:
  
  -S, --start TEXT    start date (default: 1st date of current month)
  -E, --end TEXT      end date (default: last date of current month)
  -F, --file TEXT     input file path
  --help              Show this message and exit.
```

## Examples

check cost explorer report of date range [2022-01-01,2022-01-31]

```bash
$ ./aws-cost-explorer-report.py  -S 2022-01-01 -E 2022-01-31

+-----------------+---------------+----------------------------------------+------------+
| TimePeriodStart | LinkedAccount | Service                                |     Amount |
+-----------------+---------------+----------------------------------------+------------+
| 2022-01-01      | 123456789012  | AWS Key Management Service             |    1.39938 |
| 2022-01-01      | 123456789012  | AWS Lambda                             |    3.00102 |
| 2022-01-01      | 123456789012  | EC2 - Other                            |   11.48211 |
| 2022-01-01      | 123456789012  | Amazon Elastic Compute Cloud - Compute |  102.41709 |
| 2022-01-01      | 123456789012  | Amazon Elastic Load Balancing          |   17.73890 |
| 2022-01-01      | 123456789012  | Amazon Route 53                        |    1.32980 |
| 2022-01-01      | 123456789012  | Amazon Simple Notification Service     |    2.32891 |
| 2022-01-01      | 123456789012  | Amazon Simple Storage Service          |    3.34789 |
| 2022-01-01      | 123456789012  | AmazonCloudWatch                       |   10.32789 |
| 2022-01-01      | 123456789012  | AWS Key Management Service             |    3.97408 |
| 2022-01-01      | 123456789012  | AWS Lambda                             |   23.44120 |
| 2022-01-01      | 123456789012  | EC2 - Other                            |   12.30661 |
| 2022-01-01      | 123456789012  | Amazon Elastic Compute Cloud - Compute |  127.45739 |
| 2022-01-01      | 123456789012  | Amazon Elastic Load Balancing          |   18.15638 |
| 2022-01-01      | 123456789012  | Amazon Route 53                        |    1.32456 |
| 2022-01-01      | 123456789012  | Amazon Simple Notification Service     |    2.00011 |
| 2022-01-01      | 123456789012  | Amazon Simple Storage Service          |    3.63218 |
| 2022-01-01      | 123456789012  | AmazonCloudWatch                       |   10.06860 |
+-----------------+---------------+----------------------------------------+------------+
```

Generate reports monthly. The reports will be saved to `output` folder. 
```bash
$ ./aws-cost-explorer-report.py -F sample_input.csv
```

## Equivalent command with `awscli`

check cost explorer report of date range [2022-01-01,2022-01-31]

```bash
$ aws --profile my-profile \
    ce get-cost-and-usage \
      --time-period "Start=2022-01-01,End=2022-01-31" \
      --granularity "MONTHLY" \
      --metrics "UnblendedCost" \
      --group-by "Type=DIMENSION,Key=LINKED_ACCOUNT" \
      --group-by "Type=DIMENSION,Key=SERVICE" \
      --output json
```

# License

[MIT LICENSE](LICENSE)

