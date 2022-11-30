package test

import (
	"bufio"
	"fmt"
	"os"
	"strings"
	"testing"
	"time"

	aws_sdk "github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/autoscaling"
	"github.com/aws/aws-sdk-go/service/cloudwatchlogs"
	"github.com/aws/aws-sdk-go/service/ssm"
	"github.com/gruntwork-io/terratest/modules/aws"
	http_helper "github.com/gruntwork-io/terratest/modules/http-helper"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

var idp_hostname = os.Getenv("IDP_HOSTNAME")
var account_id = os.Getenv("ACCOUNT_ID")
var region = os.Getenv("REGION")
var env_name = os.Getenv("ENV_NAME")
var recycle = os.Getenv("RECYCLE")

func RunCommandOnInstances(t *testing.T, instancestrings []string, command string) *ssm.GetCommandInvocationOutput {
	var instances []*string
	for _, instance := range instancestrings {
		instances = append(instances, aws_sdk.String(instance))
	}

	// Wait for SSM to get active
	aws.WaitForSsmInstance(t, region, instancestrings[0], 900*time.Second)

	// ssm in and do the command
	myssm := aws.NewSsmClient(t, region)
	input := &ssm.SendCommandInput{
		DocumentName: aws_sdk.String("AWS-RunShellScript"),
		Parameters: map[string][]*string{
			"commands": {
				aws_sdk.String(command),
			},
		},
		InstanceIds: instances,
	}
	output, err := myssm.SendCommand(input)
	require.NoError(t, err)

	// Wait until it's done
	cmdinvocation := &ssm.GetCommandInvocationInput{
		CommandId:  output.Command.CommandId,
		InstanceId: instances[0],
	}
	err = myssm.WaitUntilCommandExecuted(cmdinvocation)
	require.NoError(t, err)

	// return output of command
	cmdoutput, err := myssm.GetCommandInvocation(cmdinvocation)
	require.NoError(t, err)
	return cmdoutput
}

func ASGRecycle(t *testing.T, asgName string) {
	asgClient := aws.NewAsgClient(t, region)
	input := &autoscaling.DescribeAutoScalingGroupsInput{
		AutoScalingGroupNames: []*string{
			aws_sdk.String(asgName),
		},
	}
	result, err := asgClient.DescribeAutoScalingGroups(input)
	require.NoError(t, err)

	// get the current size
	asgSize := *result.AutoScalingGroups[0].DesiredCapacity

	// Make sure we are actually at that size
	asgInstances := aws.GetInstanceIdsForAsg(t, asgName, region)
	assert.Equal(t, int64(len(asgInstances)), asgSize, "ASG size is not proper for "+asgName)

	// set the size to 2x
	updateinput := &autoscaling.UpdateAutoScalingGroupInput{
		AutoScalingGroupName: aws_sdk.String(asgName),
		DesiredCapacity:      aws_sdk.Int64(asgSize * 2),
	}
	_, err = asgClient.UpdateAutoScalingGroup(updateinput)
	require.NoError(t, err)

	// wait until everything is done scaling up
	aws.WaitForCapacity(t, asgName, region, 60, 15*time.Second)

	// XXX This happens too quickly?  Do we need to do some sort of healthcheck here,
	//     or is that taken care of by the lifecycle stuff?

	// scale back down
	updateinput = &autoscaling.UpdateAutoScalingGroupInput{
		AutoScalingGroupName: aws_sdk.String(asgName),
		DesiredCapacity:      aws_sdk.Int64(asgSize),
	}
	_, err = asgClient.UpdateAutoScalingGroup(updateinput)
	require.NoError(t, err)

	// wait until everything is done scaling down
	aws.WaitForCapacity(t, asgName, region, 60, 30*time.Second)
}

// This does an ASG recycle of the IDP (if needed) and then a basic smoke test
// to make sure that everything works with whatever new stuff is out there.
func TestIdpRecycle(t *testing.T) {
	asgName := env_name + "-idp"
	if recycle == "TRUE" {
		ASGRecycle(t, asgName)
	}

	url := fmt.Sprintf("https://%s/api/health/", idp_hostname)

	// Make an HTTP request to the URL and make sure it is healthy
	http_helper.HttpGetWithRetryWithCustomValidation(t, url, nil, 5, 1*time.Second,
		func(statusCode int, body string) bool {
			isOk := statusCode == 200
			isHealthy := strings.Contains(body, "all_checks_healthy\":true")
			return isOk && isHealthy
		},
	)
}

// Test Cloudwatch metric filters
func TestMetricFilters(t *testing.T) {
	mySession := session.Must(session.NewSession())
	svc := cloudwatchlogs.New(mySession, aws_sdk.NewConfig().WithRegion(region))

	// Get the pattern we're checking from the live filter
	filters, err := svc.DescribeMetricFilters(&cloudwatchlogs.DescribeMetricFiltersInput{
		FilterNamePrefix: aws_sdk.String(env_name + "-idp-interesting-uris-success"),
		LogGroupName:     aws_sdk.String(env_name + "_/var/log/nginx/access.log"),
	})
	require.NoError(t, err)
	require.Len(t, filters.MetricFilters, 1)
	pattern := filters.MetricFilters[0].FilterPattern

	// This log has a couple interesting events, and a few that should get filtered out
	readFile, err := os.Open("testdata/access.log.test")
	require.NoError(t, err)
	fileScanner := bufio.NewScanner(readFile)
	fileScanner.Split(bufio.ScanLines)
	var logLines []*string
	for fileScanner.Scan() {
		logLines = append(logLines, aws_sdk.String(fileScanner.Text()))
	}

	filterOutput, err := svc.TestMetricFilter(&cloudwatchlogs.TestMetricFilterInput{
		FilterPattern:    pattern,
		LogEventMessages: logLines,
	})
	require.NoError(t, err)
	// Exactly 2 events should pass the filter
	require.Len(t, filterOutput.Matches, 2)
}

// // XXX would be great to actually do a new account and so on.
// func TestIdpAccountcreation(t *testing.T) {
// 	t.Parallel()
// 	XXX
// }

// // XXX Not sure how to test pivcac?
// func TestPivCac(t *testing.T) {
// 	t.Parallel()

// 	url := fmt.Sprintf("https://test.pivcac.%s/api/health/", idp_hostname)

// 	// Make an HTTP request to the URL and make sure it is healthy
// 	http_helper.HttpGetWithRetryWithCustomValidation(t, url, nil, 5, 1*time.Second,
// 		func(statusCode int, body string) bool {
// 			isOk := statusCode == 200
// 			isHealthy := strings.Contains(body, "all_checks_healthy\":true")
// 			return isOk && isHealthy
// 		},
// 	)
// }
