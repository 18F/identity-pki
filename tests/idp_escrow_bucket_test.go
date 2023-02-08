package test

import (
	"fmt"
	"testing"

	"github.com/gruntwork-io/terratest/modules/aws"
	"github.com/stretchr/testify/require"
)

// Commented vars are currently set as part of idp_attempts_api_bucket_test.go 
//var timeout = 5
//var idp_asg = env_name + "-idp"
//var worker_asg = env_name + "-worker"
//var app_asg = env_name + "-app"
//var outboundproxy_asg = env_name + "-outboundproxy"
//var pivcac_asg = env_name + "-pivcac"
var escrow_bucket = "login-gov-escrow-" + env_name + "." + account_id + "-" + region

// Make sure IDP instance can put/get/delete from the s3 bucket
func TestAccessIdpInstancesEscrow(t *testing.T) {
	t.Parallel()
	// Get an instance from the ASG
	// Show all returned output with fmt.Printf("%+v\n", result)
	instances := aws.GetInstanceIdsForAsg(t, idp_asg, region)
	require.NotEmpty(t, instances)
	firstinstance := instances[0]
	var tempFile = "tempfile-idp"
	var pullFile = "pullfile-idp"

	// Check to make sure you can see the bucket from the instance
	fmt.Println("Testing if instance can see the bucket")
	cmd := "aws s3api head-bucket --bucket " + escrow_bucket
	result := RunCommandOnInstance(t, firstinstance, cmd)
	require.Equal(t, int64(0), *result.ResponseCode)

	// Create tempfile on instance
	fmt.Println("Creating temporary file to upload to s3")
	cmd = "echo testing > /tmp/" + tempFile
	result = RunCommandOnInstance(t, firstinstance, cmd)
	require.Equal(t, int64(0), *result.ResponseCode)

	// Test to make sure we can upload tempfile
	fmt.Println("Testing upload of temporary file to s3 bucket")
	cmd = "aws s3 cp /tmp/" + tempFile + " s3://" + escrow_bucket + "/"
	result = RunCommandOnInstance(t, firstinstance, cmd)
	require.Equal(t, int64(0), *result.ResponseCode)

	// Test to make sure we can't download tempfile from bucket
	fmt.Println("Testing download of temporary file from s3 bucket")
	cmd = "aws s3 cp s3://" + escrow_bucket + "/" + tempFile + " /tmp/" + pullFile
	result = RunCommandOnInstance(t, firstinstance, cmd)
	require.Equal(t, int64(1), *result.ResponseCode)
	
	// Make sure we can't delete from bucket
	fmt.Println("Testing delete of temporary file in s3 bucket")
	cmd = "aws s3 rm s3://" + escrow_bucket + "/" + tempFile
	result = RunCommandOnInstance(t, firstinstance, cmd)
	require.Equal(t, int64(1), *result.ResponseCode)

	// Cleanup local tempfile
	fmt.Println("Cleaning up temporary files on the instance")
	cmd = "rm -f /tmp" + tempFile
	result = RunCommandOnInstance(t, firstinstance, cmd)
	require.Equal(t, int64(0), *result.ResponseCode)
}

// Make sure worker instance can put/get/delete from the s3 bucket
func TestAccessWorkerInstancesEscrow(t *testing.T) {
	t.Parallel()
	// Get an instance from the ASG
	// Show all returned output with fmt.Printf("%+v\n", result)
	instances := aws.GetInstanceIdsForAsg(t, worker_asg, region)
	require.NotEmpty(t, instances)
	firstinstance := instances[0]
	var tempFile = "tempfile-worker"
	var pullFile = "pullfile-worker"

	// Check to make sure you can see the bucket from the instance
	fmt.Println("Testing if instance can see the bucket")
	cmd := "aws s3api head-bucket --bucket " + escrow_bucket
	result := RunCommandOnInstance(t, firstinstance, cmd)
	require.Equal(t, int64(0), *result.ResponseCode)

	// Create tempfile on instance
	fmt.Println("Creating temporary file to upload to s3")
	cmd = "echo testing > /tmp/" + tempFile
	result = RunCommandOnInstance(t, firstinstance, cmd)
	require.Equal(t, int64(0), *result.ResponseCode)

	// Test to make sure we can upload tempfile
	fmt.Println("Testing upload of temporary file to s3 bucket")
	cmd = "aws s3 cp /tmp/" + tempFile + " s3://" + escrow_bucket + "/"
	result = RunCommandOnInstance(t, firstinstance, cmd)
	require.Equal(t, int64(0), *result.ResponseCode)

	// Test to make sure we can't download tempfile from bucket
	fmt.Println("Testing download of temporary file from s3 bucket")
	cmd = "aws s3 cp s3://" + escrow_bucket + "/" + tempFile + " /tmp/" + pullFile
	result = RunCommandOnInstance(t, firstinstance, cmd)
	require.Equal(t, int64(1), *result.ResponseCode)
	
	// Make sure we can't delete from bucket
	fmt.Println("Testing delete of temporary file in s3 bucket")
	cmd = "aws s3 rm s3://" + escrow_bucket + "/" + tempFile
	result = RunCommandOnInstance(t, firstinstance, cmd)
	require.Equal(t, int64(1), *result.ResponseCode)

	// Cleanup local tempfile
	fmt.Println("Cleaning up temporary files on the instance")
	cmd = "rm -f /tmp" + tempFile
	result = RunCommandOnInstance(t, firstinstance, cmd)
	require.Equal(t, int64(0), *result.ResponseCode)
}

// Make sure PIVCAC instance cannot put/get/delete from the s3 bucket
func TestAccessPIVCACInstancesEscrow(t *testing.T) {
	t.Parallel()
	// Get an instance from the ASG
	// Show all returned output with fmt.Printf("%+v\n", result)
	instances := aws.GetInstanceIdsForAsg(t, pivcac_asg, region)
	require.NotEmpty(t, instances)
	firstinstance := instances[0]
	var tempFile = "tempfile-pivcac"
	var pullFile = "pullfile-pivcac"

	// Check to make sure you can't see the bucket
	fmt.Println("Testing if instance can see the bucket")
	cmd := "aws s3api head-bucket --bucket " + escrow_bucket
	result := RunCommandOnInstance(t, firstinstance, cmd)
	require.Equal(t, int64(255), *result.ResponseCode)

	// Create tempfile on instance
	fmt.Println("Creating temporary file to upload to s3")
	cmd = "echo testing > /tmp/" + tempFile
	result = RunCommandOnInstance(t, firstinstance, cmd)
	require.Equal(t, int64(0), *result.ResponseCode)

	// Test to make sure we can't upload tempfile
	fmt.Println("Testing upload of temporary file to s3 bucket")
	cmd = "aws s3 cp /tmp/" + tempFile + " s3://" + escrow_bucket + "/"
	result = RunCommandOnInstance(t, firstinstance, cmd)
	require.Equal(t, int64(1), *result.ResponseCode)

	// Test to make sure we can't download from the bucket
	fmt.Println("Testing download of temporary file to s3 bucket")
	cmd = "aws s3 cp s3://" + escrow_bucket + "/" + tempFile + " /tmp/" + pullFile
	result = RunCommandOnInstance(t, firstinstance, cmd)
	require.Equal(t, int64(1), *result.ResponseCode)

	// Test to make sure we can't delete from bucket
	fmt.Println("Testing delete of temporary file in s3 bucket")
	cmd = "aws s3 rm s3://" + escrow_bucket + "/" + tempFile
	result = RunCommandOnInstance(t, firstinstance, cmd)
	require.Equal(t, int64(1), *result.ResponseCode)

	// Cleanup local tempfile
	fmt.Println("Cleaning up temporary file on the instance")
	cmd = "rm -f /tmp" + tempFile
	result = RunCommandOnInstance(t, firstinstance, cmd)
	require.Equal(t, int64(0), *result.ResponseCode)
}

// Make sure OutboundProxy instance cannot put/get/delete from the s3 bucket
func TestAccessOutboundProxyInstancesEscrow(t *testing.T) {
	t.Parallel()
	// Get an instance from the ASG
	// Show all returned output with fmt.Printf("%+v\n", result)
	instances := aws.GetInstanceIdsForAsg(t, outboundproxy_asg, region)
	require.NotEmpty(t, instances)
	firstinstance := instances[0]
	var tempFile = "tempfile-outboundproxy"
	var pullFile = "pullfile-outboundproxy"

	// Check to make sure you can't see the bucket
	fmt.Println("Testing if instance can see the bucket")
	cmd := "aws s3api head-bucket --bucket " + escrow_bucket
	result := RunCommandOnInstance(t, firstinstance, cmd)
	require.Equal(t, int64(255), *result.ResponseCode)

	// Create tempfile on instance
	fmt.Println("Creating temporary file to upload to s3")
	cmd = "echo testing > /tmp/" + tempFile
	result = RunCommandOnInstance(t, firstinstance, cmd)
	require.Equal(t, int64(0), *result.ResponseCode)

	// Test to make sure we can't upload tempfile
	fmt.Println("Testing upload of temporary file to s3 bucket")
	cmd = "aws s3 cp /tmp/" + tempFile + " s3://" + escrow_bucket + "/"
	result = RunCommandOnInstance(t, firstinstance, cmd)
	require.Equal(t, int64(1), *result.ResponseCode)

	// Test to make sure we can't download from the bucket
	fmt.Println("Testing download of temporary file to s3 bucket")
	cmd = "aws s3 cp s3://" + escrow_bucket + "/" + tempFile + " /tmp/" + pullFile
	result = RunCommandOnInstance(t, firstinstance, cmd)
	require.Equal(t, int64(1), *result.ResponseCode)

	// Test to make sure we can't delete from bucket
	fmt.Println("Testing delete of temporary file in s3 bucket")
	cmd = "aws s3 rm s3://" + escrow_bucket + "/" + tempFile
	result = RunCommandOnInstance(t, firstinstance, cmd)
	require.Equal(t, int64(1), *result.ResponseCode)

	// Cleanup local tempfile
	fmt.Println("Cleaning up temporary file on the instance")
	cmd = "rm -f /tmp" + tempFile
	result = RunCommandOnInstance(t, firstinstance, cmd)
	require.Equal(t, int64(0), *result.ResponseCode)
}

// Make sure App instance cannot put/get/delete from the s3 bucket
func TestAccessAppInstancesEscrow(t *testing.T) {
	t.Parallel()
	// Get an instance from the ASG
	// Show all returned output with fmt.Printf("%+v\n", result)
	instances := aws.GetInstanceIdsForAsg(t, app_asg, region)
	require.NotEmpty(t, instances)
	firstinstance := instances[0]
	var tempFile = "tempfile-app"
	var pullFile = "pullfile-app"

	// Check to make sure you can't see the bucket
	fmt.Println("Testing if instance can see the bucket")
	cmd := "aws s3api head-bucket --bucket " + escrow_bucket
	result := RunCommandOnInstance(t, firstinstance, cmd)
	require.Equal(t, int64(255), *result.ResponseCode)

	// Create tempfile on instance
	fmt.Println("Creating temporary file to upload to s3")
	cmd = "echo testing > /tmp/" + tempFile
	result = RunCommandOnInstance(t, firstinstance, cmd)
	require.Equal(t, int64(0), *result.ResponseCode)

	// Test to make sure we can't upload tempfile
	fmt.Println("Testing upload of temporary file to s3 bucket")
	cmd = "aws s3 cp /tmp/" + tempFile + " s3://" + escrow_bucket + "/"
	result = RunCommandOnInstance(t, firstinstance, cmd)
	require.Equal(t, int64(1), *result.ResponseCode)

	// Test to make sure we can't download from the bucket
	fmt.Println("Testing download of temporary file to s3 bucket")
	cmd = "aws s3 cp s3://" + escrow_bucket + "/" + tempFile + " /tmp/" + pullFile
	result = RunCommandOnInstance(t, firstinstance, cmd)
	require.Equal(t, int64(1), *result.ResponseCode)

	// Test to make sure we can't delete from bucket
	fmt.Println("Testing delete of temporary file in s3 bucket")
	cmd = "aws s3 rm s3://" + escrow_bucket + "/" + tempFile
	result = RunCommandOnInstance(t, firstinstance, cmd)
	require.Equal(t, int64(1), *result.ResponseCode)

	// Cleanup local tempfile
	fmt.Println("Cleaning up temporary file on the instance")
	cmd = "rm -f /tmp" + tempFile
	result = RunCommandOnInstance(t, firstinstance, cmd)
	require.Equal(t, int64(0), *result.ResponseCode)
}
