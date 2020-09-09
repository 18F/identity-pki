package test

import (
	"fmt"
	"os"
	"strings"
	"testing"
	"time"

	aws_sdk "github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/service/autoscaling"
	"github.com/gruntwork-io/terratest/modules/aws"
	http_helper "github.com/gruntwork-io/terratest/modules/http-helper"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

var idp_hostname = os.Getenv("IDP_HOSTNAME")
var region = os.Getenv("REGION")
var env_name = os.Getenv("ENV_NAME")
var elkAsgName = env_name + "-elk"

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
// func TestIdpAccount(t *testing.T) {
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
	instances := aws.GetInstanceIdsForAsg(t, elkAsgName, region)

	// we should only have one elk instance
	assert.Equal(t, int(len(instances)), 1)

	fmt.Println(instances)

	// Wait for SSM to get active
	// aws.WaitForSsmInstance(t, region, instanceid, 60, 15*time.Second)

	// ssm in and make sure that the chef run is done?
}

// // XXX AWS ES is what is running in my environment, so cannot test this now.
// func TestESRecycle(t *testing.T) {
// 	ASGRecycle(t, env_name + "-elasticsearch")
// }

func TestFilebeat(t *testing.T) {
	t.Parallel()

	instances := aws.GetInstanceIdsForAsg(t, elkAsgName, region)
	assert.Greater(t, int(len(instances)), 0)
	// instanceid := instances[0].instanceIdXXX

	// Wait for SSM to get active
	// aws.WaitForSsmInstance(t, region, instanceid, 60, 15*time.Second)

	// ssm in and turn on http.enabled and query curl -XGET 'localhost:5066/stats?pretty'
	// and parse out errors and other things
}

func TestLogstash(t *testing.T) {
	t.Parallel()

}

func TestElastalert(t *testing.T) {
	t.Parallel()

}

func TestElasticsearch(t *testing.T) {
	t.Parallel()

}
