from __future__ import print_function
import boto3
from botocore.exceptions import ClientError
import os
import json
import csv
from time import sleep
import datetime
from dateutil import parser
import sys
from datetime import timedelta
from datetime import date


def lambda_handler(event, context, iam=None):
    iam = iam or boto3.client("iam")
    ses = boto3.client("ses")

    # print(event)
    credential_report = get_credential_report(iam)
    # print(credential_report)

    account_id = boto3.client("sts").get_caller_identity()["Account"]
    rotation_period = int(os.environ["RotationPeriod"])
    old_password_inactivation_period = int(os.environ["InactivePeriod"])
    old_password_deletion_period = int(os.environ["DeletionPeriod"])

    for value in credential_report.items():
        test1 = value[1]
        check = test1["password_enabled"]
        print(check)
        if check == "true":
            user_name = test1["user"]
            if test1["password_last_used"] == "no_information":
                print(
                    "User "
                    + user_name
                    + " has never logged into the AWS Console. This should be an user who has not onboarded yet"
                )
                continue
            else:
                password_last_used_date = test1["password_last_used"]
                password_last_changed_date = test1["password_last_changed"]

                used_date = parser.parse(password_last_used_date)
                last_used_date = used_date.date()
                print(user_name, "last used their password at", last_used_date)

                changed_date = parser.parse(password_last_changed_date)
                last_changed_date = changed_date.date()
                print(user_name, "last changed their password at", last_changed_date)

                # action to take by comparing date
                action = compare_time(
                    user_name=user_name,
                    lastchanged=last_changed_date,
                    lastlogin=last_used_date,
                    account_id=account_id,
                    rotation_period=rotation_period,
                    old_password_inactivation_period=old_password_inactivation_period,
                    old_password_deletion_period=old_password_deletion_period,
                    iam=iam,
                    ses=ses,
                )
                # print("Returned value from function compare_time()", action)


def load_user_email(user_name, iam):
    iam_tags = iam.list_user_tags(UserName=user_name)
    try:
        email_tag = next(
            filter(lambda config: config["Key"] == "email", iam_tags["Tags"])
        )
        return email_tag["Value"]
    except StopIteration:
        return user_name + "@gsa.gov"


# https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_getting-report.html
# Check the age of password and number of days from last login


def compare_time(
    user_name,
    lastchanged,
    lastlogin,
    account_id,
    rotation_period,
    old_password_inactivation_period,
    old_password_deletion_period,
    iam,
    ses,
):
    password_age = ((datetime.datetime.now()).date() - lastchanged).days
    recent_password_used_age = ((datetime.datetime.now()).date() - lastlogin).days

    print(
        user_name,
        "user's password age is",
        password_age,
        "days old & was used for the most recent login ",
        recent_password_used_age,
        "days ago",
    )

    ### SES email template settings ###
    CHARSET = "UTF-8"
    BODY_HTML = """<html>
    </html>
                """

    sender_email = "noreply@humans.login.gov"
    realemail = load_user_email(user_name, iam=iam)
    print("real recipient_email", realemail)

    recipient_email = user_name + "@gsa.gov"

    if recent_password_used_age < old_password_deletion_period:
        if rotation_period <= password_age <= old_password_inactivation_period:
            expire_in = old_password_inactivation_period - password_age
            expiration_date = (datetime.datetime.now()).date() + timedelta(
                days=expire_in
            )
            print("Expire_in days", expire_in, "days")
            check = expiration_date.strftime("%m/%d/%Y")
            print(
                "Password age between "
                + str(rotation_period)
                + "-"
                + str(old_password_inactivation_period)
                + " days so sending warning notification for user",
                user_name,
            )
            SUBJECT = (
                " Your expiring AWS console password is going to be deactivated in "
                + str(expire_in)
                + "day(s)"
            )
            BODY_HTML = """<html>
                <head>Dear {user_name},</head>
                <body>

                    <p>
                        Your AWS Console login access is going to be disabled at {check}. Console access is disabled
                        if there is missing login activity for more than {old_password_deletion_period} days or if password is
                        not rotated in every {old_password_inactivation_period} days with active login activity.
                    </p>
                    <p>
                        Please see <a href='https://github.com/18F/identity-devops/wiki/Setting-Up-your-Login.gov-Infrastructure-Configuration#settingupdating-your-console-password'>Updating Your Console Password</a>
                        for directions on rotating the password.
                    </p>
                    <p>
                        If you allow your password to expire, you will lose access to the AWS accounts via console.
                        However, this rule does not check or modify your ability to access AWS Accounts using AWS Access Keys.
                    </p>
                    <p>Thank you!</p>
                    <p>Support: Ask @login-platform-help for help in the #login-platform-support Slack channel<br></p>
                </body>
            </html>
            """.format(
                user_name=user_name,
                check=check,
                old_password_deletion_period=old_password_deletion_period,
                old_password_inactivation_period=old_password_inactivation_period,
            )
            send_notification(
                recipient_email, sender_email, SUBJECT, BODY_HTML, CHARSET, ses=ses
            )

        elif password_age > old_password_inactivation_period:
            print(
                "Password age older than "
                + str(old_password_inactivation_period)
                + " days so disabling it for user ",
                user_name,
            )
            action1 = invoke_console_access(user_name)
            if action1 == "Success":
                SUBJECT = " Your expired AWS console password has been deactivated."
                BODY_HTML = """<html>
                    <head>Dear {user_name},</head>
                    <body>

                        <p>Your AWS Console password is disabled.</p>
                        <p>
                            We recommend updating your AWS Console password every {old_password_inactivation_period}
                            days in order to be able to continue to log into the AWS console.
                            AWS Console access is disabled if there is missing login activity for more than {old_password_deletion_period}
                            days or if password is not rotated in every {old_password_inactivation_period} days with active login activity.
                        </p>
                        <p>
                            Please see
                            <a href='https://github.com/18F/identity-devops/wiki/Setting-Up-your-Login.gov-Infrastructure-Configuration#settingupdating-your-console-password'>Updating Your Console Password</a>
                            for directions on rotating the password.
                        </p>
                        <p>Thank you!</p>
                        <p>Support: Ask @login-platform-help for help in the #login-platform-support Slack channel<br></p>
                    </body>
                </html>
                """.format(
                    user_name=user_name,
                    old_password_inactivation_period=old_password_inactivation_period,
                    old_password_deletion_period=old_password_deletion_period,
                )
                send_notification(
                    recipient_email, sender_email, SUBJECT, BODY_HTML, CHARSET, ses=ses
                )
            else:
                print("Failed to update user's login profile")
    else:
        action = invoke_console_access(user_name)
        if action == "Success":
            SUBJECT = " Your expired AWS console password has been deactivated."
            BODY_HTML = """<html>
                <head> Dear {user_name}, </head>
                <body>

                <p>Your AWS Console Password is beyond the required rotation period. </p>

                <p><p>**If you do not need access to the AWS Console, feel free to ignore this email.**</p>

                <p> We recommend rotating (updating) AWS Console password in every {old_password_inactivation_period} days in order to be able to continue to log into the AWS console. Console access is disabled, if there is missing login activity for more than {old_password_deletion_period} days or if password is not rotated in every {old_password_inactivation_period} days with active login activity. Please refer <a href='https://github.com/18F/identity-devops/wiki/Setting-Up-your-Login.gov-Infrastructure-Configuration#settingupdating-your-console-password'>
                 Runbook</a> for directions on rotating the password or reach out to @login-platform-help oncall in Slack for any additional information. </p>

                <p>Thank you for your understanding!</p><br>

                <p> Helpful links: <br>
                <a href='https://github.com/18F/identity-devops/wiki/Setting-Up-your-Login.gov-Infrastructure-Configuration#settingupdating-your-console-password'>
                 Runbook</a><br>
                 Slack : #login-platform-support channel and @login-platform-help<br></p>
                </body>
                </html>
                        """.format(
                user_name=user_name,
                old_password_deletion_period=old_password_deletion_period,
                old_password_inactivation_period=old_password_inactivation_period,
            )
            send_notification(
                recipient_email, sender_email, SUBJECT, BODY_HTML, CHARSET, ses=ses
            )
        else:
            print("Failed to update user's login profile")


# Request the credential report, download and parse the CSV.
def get_credential_report(iam):
    generate_report = iam.generate_credential_report()
    if generate_report["State"] == "COMPLETE":
        try:
            iam_report = iam.get_credential_report()
            convert = iam_report["Content"].decode("utf-8")
            convert_lines = convert.split("\n")
            response_reader = csv.DictReader(convert_lines, delimiter=",")
            response_dict = dict(enumerate(list(response_reader)))
            return response_dict
        except ClientError as e:
            print("Unknown error getting Report: ")
    else:
        sleep(2)
        return get_credential_report(iam)


### SES function to send notification ###


def send_notification(recipient_email, sender_email, SUBJECT, BODY_HTML, CHARSET, ses):
    try:
        response = ses.send_email(
            Destination={
                "ToAddresses": [
                    recipient_email,
                ],
            },
            Message={
                "Body": {"Html": {"Charset": CHARSET, "Data": BODY_HTML}},
                "Subject": {"Charset": CHARSET, "Data": SUBJECT},
            },
            Source=sender_email,
        )

    except ClientError as e:
        print(e.response["Error"]["Message"])
    else:
        print(response["MessageId"])


### Generate temporary role credentials ###
def invoke_console_access(user_name):
    temp_credentials = generate_temp_credentials(user_name)
    # print("Here are the credentials", temp_credentials)
    action = disable_console_access(temp_credentials, user_name)
    print("Console Access for " + user_name + " disabled")
    return action


### Assumed role will have permissions that overlap with the policy below and associated with temp_role_arn
def generate_temp_credentials(user_name):
    sts = boto3.client("sts")
    temp_role_arn = os.environ["temp_role_arn"]

    policy = {
        "Version": "2012-10-17",
        "Statement": [
            {
                "Effect": "Allow",
                "Action": ["iam:DeleteLoginProfile", "iam:GetLoginProfile"],
                "Resource": ["arn:aws:iam::*:user/" + user_name],
            }
        ],
    }

    policy_document = json.dumps(policy)
    print("policy_document", policy_document)

    role_session_name = "additionalpolicyfor" + user_name
    print("role_session_name", role_session_name)

    session_duration = 3600

    try:
        assumed_role_creds = sts.assume_role(
            RoleArn=temp_role_arn,
            Policy=policy_document,
            RoleSessionName=role_session_name,
            DurationSeconds=session_duration,
        )
        return assumed_role_creds
    except ClientError as err:
        print(err.response["Error"]["Message"])
        return err
    except Exception as err:
        print(err)
        return err


def disable_console_access(temp_credentials, user_name):
    try:
        # Format resulting temporary credentials into JSON
        ACCESS_KEY = temp_credentials["Credentials"]["AccessKeyId"]
        SECRET_KEY = temp_credentials["Credentials"]["SecretAccessKey"]
        SESSION_TOKEN = temp_credentials["Credentials"]["SessionToken"]

        iam = boto3.client(
            "iam",
            aws_access_key_id=ACCESS_KEY,
            aws_secret_access_key=SECRET_KEY,
            aws_session_token=SESSION_TOKEN,
        )

        profile = iam.get_login_profile(UserName=user_name)

        print("Here is the user's login profile", profile)

        response = iam.delete_login_profile(UserName=user_name)

        print("Console access disabled for the user", user_name)

        return "Success"

    except ClientError as err:
        print(err.response["Error"]["Message"])
        return err
    except Exception as err:
        print(err)
        return err
