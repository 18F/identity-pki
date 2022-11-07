package test

import (
	"sync"
	"fmt"
	"testing"
	"time"

	aws_sdk "github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/service/ssm"
	"github.com/gruntwork-io/terratest/modules/aws"
	"github.com/stretchr/testify/require"
)

var timeout = 5
var idp_asg = env_name + "-idp"
var worker_asg = env_name + "-worker"
var app_asg = env_name + "-app"
var outboundproxy_asg = env_name + "-outboundproxy"
var pivcac_asg = env_name + "-pivcac"

func RunCommandOnInstance(t *testing.T, instance_string string, command string) *ssm.GetCommandInvocationOutput {
	outputs := RunOnInstances(t, []string{instance_string}, command)
	return outputs[0]
}

func RunOnInstances(t *testing.T, instancestrings []string, command string) []*ssm.GetCommandInvocationOutput {
	var instances []*string
	for _, instance := range instancestrings {
		instances = append(instances, aws_sdk.String(instance))
	}

	// Wait for SSM to get active
	var wg sync.WaitGroup
	for _, instancestring := range instancestrings {
		wg.Add(1)
		go func(i string) {
			defer wg.Done()
			aws.WaitForSsmInstance(t, region, i, 900*time.Second)
		}(instancestring)
	}
	wg.Wait()

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
	results := make(chan *ssm.GetCommandInvocationOutput, len(instances))
	for _, instance := range instances {
		go func(i *string) {
			cmdinvocation := &ssm.GetCommandInvocationInput{
				CommandId:  output.Command.CommandId,
				InstanceId: i,
			}
			myssm.WaitUntilCommandExecuted(cmdinvocation)
			cmdoutput, _ := myssm.GetCommandInvocation(cmdinvocation)

			results <- cmdoutput
		}(instance)
	}

	outputs := []*ssm.GetCommandInvocationOutput{}
	for range instances {
		cmdOut := <-results
		outputs = append(outputs, cmdOut)
	}

	// return outputs of commands
	return outputs
}

// Make sure IDP instance can put/get/delete from the s3 bucket
func TestAccessIdpInstances(t *testing.T) {
	// Can't t.Parallel() this since it will write to the bucket
	// Get an instance from the ASG
	// Show all returned output with fmt.Printf("%+v\n", result)
	instances := aws.GetInstanceIdsForAsg(t, idp_asg, region)
	require.NotEmpty(t, instances)
	firstinstance := instances[0]
	var tempFile = "tempfile"
	var pullFile = "pullfile"

	// Check to make sure you can see the bucket from the instance
	fmt.Println("Testing if instance can see the bucket")
	cmd := "aws s3api head-bucket --bucket " + env_name + "-idp-attempts-api"
	result := RunCommandOnInstance(t, firstinstance, cmd)
	require.Equal(t, int64(0), *result.ResponseCode)

	// Create tempfile on instance
  fmt.Println("Creating temporary file to upload to s3")
	cmd = "echo testing > /tmp/" + tempFile
	result = RunCommandOnInstance(t, firstinstance, cmd)
	require.Equal(t, int64(0), *result.ResponseCode)

	// Test to make sure we can upload tempfile
	fmt.Println("Testing upload of temporary file to s3 bucket")
	cmd = "aws s3 cp /tmp/" + tempFile + " s3://" + env_name + "-idp-attempts-api/"
	result = RunCommandOnInstance(t, firstinstance, cmd)
	require.Equal(t, int64(0), *result.ResponseCode)

	// Test to make sure we can pull from the bucket
	fmt.Println("Testing download of temporary file to s3 bucket")
	cmd = "aws s3 cp s3://" + env_name + "-idp-attempts-api/" + tempFile + " /tmp/" + pullFile
	result = RunCommandOnInstance(t, firstinstance, cmd)
	require.Equal(t, int64(0), *result.ResponseCode)
 
	// Test delete and cleanup tempfile
	fmt.Println("Testing delete of temporary file in s3 bucket")
	cmd = "aws s3 rm s3://" + env_name + "-idp-attempts-api/" + tempFile
	result = RunCommandOnInstance(t, firstinstance, cmd)
	require.Equal(t, int64(0), *result.ResponseCode)

	// Cleanup local tempfile and pullfile
	fmt.Println("Cleaning up temporary files on the instance")
	cmd = "rm -f /tmp" + tempFile + " /tmp/" + pullFile
	result = RunCommandOnInstance(t, firstinstance, cmd)
	require.Equal(t, int64(0), *result.ResponseCode)
}

// Make sure Worker instance can put/get/delete from the s3 bucket
func TestAccessWorkerInstances(t *testing.T) {
	// Can't t.Parallel() this since it will write to the bucket
	// Get an instance from the ASG
	// Show all returned output with fmt.Printf("%+v\n", result)
	instances := aws.GetInstanceIdsForAsg(t, worker_asg, region)
	require.NotEmpty(t, instances)
	firstinstance := instances[0]
	var tempFile = "tempfile"
	var pullFile = "pullfile"

	// Check to make sure you can see the bucket from the instance
	fmt.Println("Testing if instance can see the bucket")
	cmd := "aws s3api head-bucket --bucket " + env_name + "-idp-attempts-api"
	result := RunCommandOnInstance(t, firstinstance, cmd)
	require.Equal(t, int64(0), *result.ResponseCode)

	// Create tempfile on instance
  fmt.Println("Creating temporary file to upload to s3")
	cmd = "echo testing > /tmp/" + tempFile
	result = RunCommandOnInstance(t, firstinstance, cmd)
	require.Equal(t, int64(0), *result.ResponseCode)

	// Test to make sure we can upload tempfile
	fmt.Println("Testing upload of temporary file to s3 bucket")
	cmd = "aws s3 cp /tmp/" + tempFile + " s3://" + env_name + "-idp-attempts-api/"
	result = RunCommandOnInstance(t, firstinstance, cmd)
	require.Equal(t, int64(0), *result.ResponseCode)

	// Test to make sure we can pull from the bucket
	fmt.Println("Testing download of temporary file to s3 bucket")
	cmd = "aws s3 cp s3://" + env_name + "-idp-attempts-api/" + tempFile + " /tmp/" + pullFile
	result = RunCommandOnInstance(t, firstinstance, cmd)
	require.Equal(t, int64(0), *result.ResponseCode)
 
	// Test delete and cleanup tempfile
	fmt.Println("Testing delete of temporary file in s3 bucket")
	cmd = "aws s3 rm s3://" + env_name + "-idp-attempts-api/" + tempFile
	result = RunCommandOnInstance(t, firstinstance, cmd)
	require.Equal(t, int64(0), *result.ResponseCode)

	// Cleanup local tempfile and pullfile
	fmt.Println("Cleaning up temporary files on the instance")
	cmd = "rm -f /tmp" + tempFile + " /tmp/" + pullFile
	result = RunCommandOnInstance(t, firstinstance, cmd)
	require.Equal(t, int64(0), *result.ResponseCode)
}

// Make sure PIVCAC instance cannot put/get/delete from the s3 bucket
func TestAccessPIVCACInstances(t *testing.T) {
	// Can t.Parallel() this since it won't write to the bucket
  t.Parallel()
	// Get an instance from the ASG
	// Show all returned output with fmt.Printf("%+v\n", result)
	instances := aws.GetInstanceIdsForAsg(t, pivcac_asg, region)
	require.NotEmpty(t, instances)
	firstinstance := instances[0]
	var tempFile = "tempfile"
	var pullFile = "pullfile"

	// Check to make sure you can see the bucket from the instance
	fmt.Println("Testing if instance can see the bucket")
	cmd := "aws s3api head-bucket --bucket " + env_name + "-idp-attempts-api"
	result := RunCommandOnInstance(t, firstinstance, cmd)
	require.Equal(t, int64(255), *result.ResponseCode)

	// Create tempfile on instance
  fmt.Println("Creating temporary file to upload to s3")
	cmd = "echo testing > /tmp/" + tempFile
	result = RunCommandOnInstance(t, firstinstance, cmd)
	require.Equal(t, int64(0), *result.ResponseCode)

	// Test to make sure we can upload tempfile
	fmt.Println("Testing upload of temporary file to s3 bucket")
	cmd = "aws s3 cp /tmp/" + tempFile + " s3://" + env_name + "-idp-attempts-api/"
	result = RunCommandOnInstance(t, firstinstance, cmd)
	require.Equal(t, int64(1), *result.ResponseCode)

	// Test to make sure we can pull from the bucket
	fmt.Println("Testing download of temporary file to s3 bucket")
	cmd = "aws s3 cp s3://" + env_name + "-idp-attempts-api/" + tempFile + " /tmp/" + pullFile
	result = RunCommandOnInstance(t, firstinstance, cmd)
	require.Equal(t, int64(1), *result.ResponseCode)
 
	// Test delete and cleanup tempfile
	// This will always fail because it can't upload to begin with
	// if there is a better way of testing delete permissions
	// that doesn't require an object let me know
	fmt.Println("Testing delete of temporary file in s3 bucket")
	cmd = "aws s3 rm s3://" + env_name + "-idp-attempts-api/" + tempFile
	result = RunCommandOnInstance(t, firstinstance, cmd)
	require.Equal(t, int64(1), *result.ResponseCode)

	// Cleanup local tempfile and pullfile
	fmt.Println("Cleaning up temporary file on the instance")
	cmd = "rm -f /tmp" + tempFile
	result = RunCommandOnInstance(t, firstinstance, cmd)
	require.Equal(t, int64(0), *result.ResponseCode)
}

// Make sure Outboundproxy instances cannot put/get/delete from the s3 bucket
func TestAccessOutboundproxyInstances(t *testing.T) {
	// Can t.Parallel() this since it won't write to the bucket
  t.Parallel()
	// Get an instance from the ASG
	// Show all returned output with fmt.Printf("%+v\n", result)
	instances := aws.GetInstanceIdsForAsg(t, outboundproxy_asg, region)
	require.NotEmpty(t, instances)
	firstinstance := instances[0]
	var tempFile = "tempfile"
	var pullFile = "pullfile"

	// Check to make sure you can see the bucket from the instance
	fmt.Println("Testing if instance can see the bucket")
	cmd := "aws s3api head-bucket --bucket " + env_name + "-idp-attempts-api"
	result := RunCommandOnInstance(t, firstinstance, cmd)
	require.Equal(t, int64(255), *result.ResponseCode)

	// Create tempfile on instance
  fmt.Println("Creating temporary file to upload to s3")
	cmd = "echo testing > /tmp/" + tempFile
	result = RunCommandOnInstance(t, firstinstance, cmd)
	require.Equal(t, int64(0), *result.ResponseCode)

	// Test to make sure we can upload tempfile
	fmt.Println("Testing upload of temporary file to s3 bucket")
	cmd = "aws s3 cp /tmp/" + tempFile + " s3://" + env_name + "-idp-attempts-api/"
	result = RunCommandOnInstance(t, firstinstance, cmd)
	require.Equal(t, int64(1), *result.ResponseCode)

	// Test to make sure we can pull from the bucket
	fmt.Println("Testing download of temporary file to s3 bucket")
	cmd = "aws s3 cp s3://" + env_name + "-idp-attempts-api/" + tempFile + " /tmp/" + pullFile
	result = RunCommandOnInstance(t, firstinstance, cmd)
	require.Equal(t, int64(1), *result.ResponseCode)
 
	// Test delete and cleanup tempfile
	// This will always fail because it can't upload to begin with
	// if there is a better way of testing delete permissions
	// that doesn't require an object let me know
	fmt.Println("Testing delete of temporary file in s3 bucket")
	cmd = "aws s3 rm s3://" + env_name + "-idp-attempts-api/" + tempFile
	result = RunCommandOnInstance(t, firstinstance, cmd)
	require.Equal(t, int64(1), *result.ResponseCode)

	// Cleanup local tempfile and pullfile
	fmt.Println("Cleaning up temporary file on the instance")
	cmd = "rm -f /tmp" + tempFile
	result = RunCommandOnInstance(t, firstinstance, cmd)
	require.Equal(t, int64(0), *result.ResponseCode)
}

// Make sure App instance cannot put/get/delete from the s3 bucket
func TestAccessAppInstances(t *testing.T) {
	// Can t.Parallel() this since it won't write to the bucket
  t.Parallel()
	// Get an instance from the ASG
	// Show all returned output with fmt.Printf("%+v\n", result)
	instances := aws.GetInstanceIdsForAsg(t, app_asg, region)
	require.NotEmpty(t, instances)
	firstinstance := instances[0]
	var tempFile = "tempfile"
	var pullFile = "pullfile"

	// Check to make sure you can see the bucket from the instance
	fmt.Println("Testing if instance can see the bucket")
	cmd := "aws s3api head-bucket --bucket " + env_name + "-idp-attempts-api"
	result := RunCommandOnInstance(t, firstinstance, cmd)
	require.Equal(t, int64(255), *result.ResponseCode)

	// Create tempfile on instance
  fmt.Println("Creating temporary file to upload to s3")
	cmd = "echo testing > /tmp/" + tempFile
	result = RunCommandOnInstance(t, firstinstance, cmd)
	require.Equal(t, int64(0), *result.ResponseCode)

	// Test to make sure we can upload tempfile
	fmt.Println("Testing upload of temporary file to s3 bucket")
	cmd = "aws s3 cp /tmp/" + tempFile + " s3://" + env_name + "-idp-attempts-api/"
	result = RunCommandOnInstance(t, firstinstance, cmd)
	require.Equal(t, int64(1), *result.ResponseCode)

	// Test to make sure we can pull from the bucket
	fmt.Println("Testing download of temporary file to s3 bucket")
	cmd = "aws s3 cp s3://" + env_name + "-idp-attempts-api/" + tempFile + " /tmp/" + pullFile
	result = RunCommandOnInstance(t, firstinstance, cmd)
	require.Equal(t, int64(1), *result.ResponseCode)
 
	// Test delete and cleanup tempfile
	// This will always fail because it can't upload to begin with
	// if there is a better way of testing delete permissions
	// that doesn't require an object let me know
	fmt.Println("Testing delete of temporary file in s3 bucket")
	cmd = "aws s3 rm s3://" + env_name + "-idp-attempts-api/" + tempFile
	result = RunCommandOnInstance(t, firstinstance, cmd)
	require.Equal(t, int64(1), *result.ResponseCode)

	// Cleanup local tempfile and pullfile
	fmt.Println("Cleaning up temporary file on the instance")
	cmd = "rm -f /tmp" + tempFile
	result = RunCommandOnInstance(t, firstinstance, cmd)
	require.Equal(t, int64(0), *result.ResponseCode)
}


