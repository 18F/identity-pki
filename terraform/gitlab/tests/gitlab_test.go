package test

import (
	"os"
	"testing"
	"time"

	aws_sdk "github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/service/autoscaling"
	"github.com/aws/aws-sdk-go/service/ssm"
	"github.com/gruntwork-io/terratest/modules/aws"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

var env_name = os.Getenv("ENV_NAME")
var region = os.Getenv("REGION")
var domain = os.Getenv("DOMAIN")
var timeout = 5

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

// This does an ASG recycle of the runner and then a basic smoke test
// to make sure that it was able to come up and get registered.
func TestRunnerRecycle(t *testing.T) {
	asgName := env_name + "-gitlab_runner"
	ASGRecycle(t, asgName)

	// make sure runner is registered
	instances := aws.GetInstanceIdsForAsg(t, asgName, region)
	firstinstance := instances[0:1]
	cmd := "gitlab-runner status"
	result := RunCommandOnInstances(t, firstinstance, cmd)
	assert.Equal(t, "gitlab-runner: Service is running\n", *result.StandardOutputContent)
}
