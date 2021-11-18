package test

import (
	// "crypto/sha256"
	// "encoding/hex"
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
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

var env_name = os.Getenv("ENV_NAME")
var region = os.Getenv("REGION")
var domain = os.Getenv("DOMAIN")

// Generate with https://docs.gitlab.com/ee/user/profile/personal_access_tokens.html#create-a-personal-access-token-programmatically ?
var gitlabtoken = os.Getenv("GITLAB_API_TOKEN")
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

// This does a basic smoke test
// to make sure that it was able to come up and get registered.
func TestRunnerRunning(t *testing.T) {
	asgName := env_name + "-gitlab_runner"

	// make sure first runner is registered
	instances := aws.GetInstanceIdsForAsg(t, asgName, region)
	firstinstance := instances[0:1]
	cmd := "gitlab-runner status"
	result := RunCommandOnInstances(t, firstinstance, cmd)
	assert.Equal(t, "gitlab-runner: Service is running\n", *result.StandardOutputContent)
}

// This checks that s3 buckets are there and being used by gitlab.
func TestGitlabS3buckets(t *testing.T) {
	bucketlist := [...]string{
		"gitlab-" + env_name + "-artifacts",
		"gitlab-" + env_name + "-backups",
		"gitlab-" + env_name + "-external-diffs",
		"gitlab-" + env_name + "-lfs-objects",
		"gitlab-" + env_name + "-uploads",
		"gitlab-" + env_name + "-packages",
		"gitlab-" + env_name + "-dependency-proxy",
		"gitlab-" + env_name + "-terraform-state",
		"gitlab-" + env_name + "-pages",
	}

	// Check the buckets exist and have versioning enabled
	for _, bucket := range bucketlist {
		err := aws.AssertS3BucketExistsE(t, region, bucket)
		require.NoError(t, err, bucket+" bucket does not exist")
		versioning := aws.GetS3BucketVersioning(t, region, bucket)
		require.Equal(t, "Enabled", versioning, "versioning is not enabled on "+bucket)
	}
}

func TestGitlabS3artifacts(t *testing.T) {
	// Check that when we create a repo with a job that the job runs and creates
	// something in S3, indicating that gitlab is actually using S3
	asgName := env_name + "-gitlab"
	instances := aws.GetInstanceIdsForAsg(t, asgName, region)
	firstinstance := instances[0:1]

	// create project
	projectname := fmt.Sprintf("gitlabs3test-%d", os.Getpid())
	cmd := "curl -s -X POST --header 'PRIVATE-TOKEN: " + gitlabtoken +
		"' 'http://localhost:8080/api/v4/projects?name=" + projectname +
		"&initialize_with_readme=true&default_branch=main&auto_devops_enabled=true'"
	result := RunCommandOnInstances(t, firstinstance, cmd)
	require.Equal(t, int64(0), *result.ResponseCode, "could not create repo")

	// parse out project ID from result
	var jsonresult map[string]interface{}
	json.Unmarshal([]byte(*result.StandardOutputContent), &jsonresult)
	projectid := fmt.Sprintf("%.0f", jsonresult["id"])

	// delete project after we are done
	deletecmd := "curl -s -X DELETE --header 'PRIVATE-TOKEN: " + gitlabtoken + "' 'http://localhost:8080/api/v4/projects/" + projectid + "'"
	t.Cleanup(func() {
		result = RunCommandOnInstances(t, firstinstance, deletecmd)
		require.Equal(t, int64(0), *result.ResponseCode, "could not delete repo")
		require.Contains(t, *result.StandardOutputContent, "202 Accepted", "could not delete repo")
	})

	// create a tag/release in project (starts a job)
	// POST /projects/:id/releases
	cmd = "curl -s --header 'Content-Type: application/json' --header 'PRIVATE-TOKEN: " + gitlabtoken +
		"' --data '{ \"name\": \"New release\", \"tag_name\": \"v0.3\", \"description\": \"Super nice release\", \"ref\": \"main\" }'" +
		" --request POST http://localhost:8080/api/v4/projects/" + projectid + "/releases"
	result = RunCommandOnInstances(t, firstinstance, cmd)
	require.Equal(t, int64(0), *result.ResponseCode, "could not create a release with "+cmd)
	require.NotContains(t, *result.StandardOutputContent, "Bad Request", "could not create a release with "+cmd)

	// watch /projects/:id/jobs with project ID to see when job completes
	jobid := "1"
	cmd = "curl -s --header 'PRIVATE-TOKEN: " + gitlabtoken +
		"' 'http://localhost:8080/api/v4/projects/" + projectid +
		"/jobs'"
	for {
		result = RunCommandOnInstances(t, firstinstance, cmd)
		require.Equal(t, int64(0), *result.ResponseCode, "could not get list of jobs with "+cmd)

		var jobresult []map[string]interface{}
		json.Unmarshal([]byte(*result.StandardOutputContent), &jobresult)

		i := 0
		for z, job := range jobresult {
			if job["status"] == "failed" {
				jobid = fmt.Sprintf("%.0f", job["id"])
				i = z
				break
			}
		}
		if jobresult[i]["status"] == "failed" {
			// There is a job, it is done, we can look for the logs now
			break
		}

		fmt.Printf("no jobs are done, waiting until there is one\n")
		time.Sleep(10)
	}

	// Download artifact
	// GET /projects/:id/jobs/:job_id/artifacts/job.log
	cmd = "curl -s --header 'PRIVATE-TOKEN: " + gitlabtoken +
		"' 'http://localhost:8080/api/v4/projects/" + projectid +
		"/jobs/" + jobid + "/trace'"
	result = RunCommandOnInstances(t, firstinstance, cmd)
	require.Equal(t, int64(0), *result.ResponseCode, "could not download job.log with "+cmd)
	require.NotContains(t, *result.StandardOutputContent, "Bad Request", "could not download job.log with "+cmd)
	require.NotContains(t, *result.StandardOutputContent, "404 Not Found", "could not download job.log with "+cmd)

	// If we can figure out how they generate their path, revive the code below.
	// I thought I'd figured it out, but apparently not.

	// // calculate sha256 of job.log
	// data := []byte(*result.StandardOutputContent)
	// sha256data := sha256.Sum256(data)
	// joblogsha256 := hex.EncodeToString(sha256data[:])

	// // find job.log artifact in s3 and make sure they are the same
	// time := time.Now()
	// datestring := time.Format("2006_01_02")
	// s3joblogpath := "/" + joblogsha256[0:2] + "/" +
	// 	joblogsha256[2:4] + "/" +
	// 	joblogsha256 + "/" +
	// 	datestring + "/" +
	// 	projectid + "/" +
	// 	jobid +
	// 	"/job.log"
	// s3joblog, err := aws.GetS3ObjectContentsE(t, region, "gitlab-"+env_name+"-artifacts", s3joblogpath)
	// require.NoError(t, err, "could not get "+s3joblogpath)
	// data = []byte(s3joblog)
	// sha256data = sha256.Sum256(data)
	// s3joblogsha256 := hex.EncodeToString(sha256data[:])
	// require.Equal(t, joblogsha256, s3joblogsha256)
}

// This does a basic smoke test
// to make sure that docker is working.
func TestDockerWorking(t *testing.T) {
	asgName := env_name + "-gitlab_runner"

	// make sure we can pull an image
	instances := aws.GetInstanceIdsForAsg(t, asgName, region)
	firstinstance := instances[0:1]
	cmd := "docker pull alpine:latest"
	result := RunCommandOnInstances(t, firstinstance, cmd)
	require.Equal(t, int64(0), *result.ResponseCode, cmd+" failed: "+*result.StandardOutputContent)
}

// This makes sure that the proper ssh key is installed
func TestSshKey(t *testing.T) {
	asgName := env_name + "-gitlab"

	// make sure the keys are the same
	instances := aws.GetInstanceIdsForAsg(t, asgName, region)
	firstinstance := instances[0:1]
	cmd := "tar xOzf /etc/gitlab/etc_ssh.tar.gz ssh/ssh_host_ecdsa_key.pub"
	tarfileresult := RunCommandOnInstances(t, firstinstance, cmd)
	require.Equal(t, int64(0), *tarfileresult.ResponseCode, cmd+" failed: "+*tarfileresult.StandardOutputContent)
	cmd = "cat /etc/ssh/ssh_host_ecdsa_key.pub"
	fileresult := RunCommandOnInstances(t, firstinstance, cmd)
	require.Equal(t, int64(0), *fileresult.ResponseCode, cmd+" failed: "+*fileresult.StandardOutputContent)
	require.Equal(t, *tarfileresult.StandardOutputContent, *fileresult.StandardOutputContent, "ssh key is not the same as the archived ssh key")

	// check against live sshd
	cmd = "ssh-keyscan localhost | grep ecdsa | awk '{print $3}'"
	result := RunCommandOnInstances(t, firstinstance, cmd)
	require.Contains(t, *tarfileresult.StandardOutputContent, strings.TrimSpace(*result.StandardOutputContent), "archived ssh key was not the same as the running sshd key")
}
