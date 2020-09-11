package test

import (
	"encoding/json"
	"fmt"
	"os"
	"strings"
	"testing"
	"time"

	aws_sdk "github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/service/autoscaling"
	"github.com/aws/aws-sdk-go/service/ssm"
	"github.com/gruntwork-io/terratest/modules/aws"
	http_helper "github.com/gruntwork-io/terratest/modules/http-helper"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

var idp_hostname = os.Getenv("IDP_HOSTNAME")
var region = os.Getenv("REGION")
var env_name = os.Getenv("ENV_NAME")
var elkAsgName = env_name + "-elk"

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
	assert.Equal(t, int64(len(asgInstances)), asgSize)

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

// This does an ASG recycle of the IDP and then a basic smoke test
// to make sure that everything works with whatever new stuff is out there.
func TestIdpRecycle(t *testing.T) {
	asgName := env_name + "-idp"
	ASGRecycle(t, asgName)

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

// This does an ASG recycle of the ELK node to make sure that everything works with
// whatever new stuff is out there.
func TestElkRecycle(t *testing.T) {
	ASGRecycle(t, elkAsgName)

	// we should only have one elk instance
	instancestrings := aws.GetInstanceIdsForAsg(t, elkAsgName, region)
	assert.Equal(t, int(len(instancestrings)), 1)

	cmdoutput := RunCommandOnInstances(t, instancestrings, "cat /var/lib/cloud/data/status.json")
	assert.Equal(t, *cmdoutput.ResponseCode, int64(0))

	// Make sure that the cloud-init run completed properly
	var cwstatus map[string]map[string]map[string]interface{}
	err := json.Unmarshal([]byte(*cmdoutput.StandardOutputContent), &cwstatus)
	require.NoError(t, err)
	for _, v := range cwstatus["v1"] {
		if errors, ok := v["errors"]; ok {
			assert.Empty(t, errors)
		}
	}
}

// // XXX AWS ES is what is running in my environment, so cannot test this now.
// func TestESRecycle(t *testing.T) {
// 	ASGRecycle(t, env_name + "-elasticsearch")
// }

func TestFilebeat(t *testing.T) {
	t.Parallel()

	// we should only have one elk instance
	instancestrings := aws.GetInstanceIdsForAsg(t, elkAsgName, region)
	assert.Equal(t, int(len(instancestrings)), 1)

	cmdoutput := RunCommandOnInstances(t, instancestrings, "/usr/bin/curl -XGET localhost:5066/stats?pretty")
	assert.Equal(t, *cmdoutput.ResponseCode, int64(0))

	// Make sure that we are are successfully logging to logstash
	var cwstatus map[string]map[string]map[string]map[string]int64
	err := json.Unmarshal([]byte(*cmdoutput.StandardOutputContent), &cwstatus)
	require.NoError(t, err)

	// check for zero errors
	assert.Equal(t, cwstatus["libbeat"]["output"]["write"]["errors"], int64(0))
	// check for greater than zero bytes sent to logstash
	assert.Greater(t, cwstatus["libbeat"]["output"]["write"]["bytes"], int64(0))
}

func TestLogstash(t *testing.T) {
	t.Parallel()

	// we should only have one elk instance
	instancestrings := aws.GetInstanceIdsForAsg(t, elkAsgName, region)
	assert.Equal(t, int(len(instancestrings)), 1)

	cmdoutput := RunCommandOnInstances(t, instancestrings, "/usr/bin/curl -XGET localhost:9600/_node/stats/events")

	assert.Equal(t, *cmdoutput.ResponseCode, int64(0))
	var cwstatus map[string]interface{}
	err := json.Unmarshal([]byte(*cmdoutput.StandardOutputContent), &cwstatus)
	require.NoError(t, err)

	// check for zero errors
	events := cwstatus["events"].(map[string]interface{})
	assert.Greater(t, events["out"].(float64), float64(0))
	// check for green status
	assert.Equal(t, cwstatus["status"], "green")
}

func TestElastalert(t *testing.T) {
	t.Parallel()
	// XXX need to probably query ES for some stats here.
}

func TestElasticsearch(t *testing.T) {
	t.Parallel()
	// XXX do we need more here?  If logstash is working, ES is working, right?
}
