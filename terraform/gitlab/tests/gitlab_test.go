package test

import (
	// "crypto/sha256"
	// "encoding/hex"
	"encoding/json"
	"fmt"
	"math/rand"
	"net/http"
	"os"
	"strings"
	"sync"
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
var accountid = os.Getenv("ACCOUNTID")
var timeout = 5
var runner_asg = env_name + "-gitlab-env-runner"

func randSeq(n int) string {
	b := make([]rune, n)
	for i := range b {
		b[i] = letters[rand.Intn(len(letters))]
	}
	return string(b)
}

type GitlabToken struct {
	mu    sync.Mutex
	token string
}

var gitlabtoken = GitlabToken{token: ""}
var letters = []rune("abcdef0123456789")

func gitlabToken(t *testing.T) string {
	gitlabtoken.mu.Lock()
	defer gitlabtoken.mu.Unlock()
	if gitlabtoken.token == "" {
		// generate token string
		rand.Seed(time.Now().UnixNano())
		newtoken := randSeq(20)

		// do command on host to create it
		asgName := env_name + "-gitlab"
		instances := aws.GetInstanceIdsForAsg(t, asgName, region)
		require.NotEmpty(t, instances)
		firstinstance := instances[0]
		cmd := fmt.Sprintf("gitlab-rails runner \"token = User.find_by_username('root').personal_access_tokens.create(scopes: [:api], name: 'Automation Token'); token.set_token('%s'); token.save!\"", newtoken)
		result := RunCommandOnInstance(t, firstinstance, cmd)
		require.Equal(t, int64(0), *result.ResponseCode, cmd+" failed to create API token: "+*result.StandardOutputContent)
		gitlabtoken.token = newtoken
	}
	return gitlabtoken.token
}

func deleteGitlabToken(t *testing.T) {
	gitlabtoken.mu.Lock()
	defer gitlabtoken.mu.Unlock()
	if gitlabtoken.token != "" {
		// do command on host to delete it
		asgName := env_name + "-gitlab"
		instances := aws.GetInstanceIdsForAsg(t, asgName, region)
		require.NotEmpty(t, instances)
		firstinstance := instances[0]
		cmd := fmt.Sprintf("gitlab-rails runner \"PersonalAccessToken.find_by_token('%s').revoke!\"", gitlabtoken.token)
		result := RunCommandOnInstance(t, firstinstance, cmd)
		require.Equal(t, int64(0), *result.ResponseCode, cmd+" failed to revoke API token: "+*result.StandardOutputContent)
		gitlabtoken.token = ""
	}
}

func RunCommandOnInstance(t *testing.T, instance_string string, command string) *ssm.GetCommandInvocationOutput {
	outputs := RunCommandOnInstances(t, []string{instance_string}, command)
	return outputs[0]
}

func RunCommandOnInstances(t *testing.T, instancestrings []string, command string) []*ssm.GetCommandInvocationOutput {
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
	// make sure first runner is registered
	instances := aws.GetInstanceIdsForAsg(t, runner_asg, region)
	require.NotEmpty(t, instances)

	firstinstance := instances[0]
	cmd := "gitlab-runner status"
	result := RunCommandOnInstance(t, firstinstance, cmd)
	assert.Equal(t, "gitlab-runner: Service is running\n", *result.StandardOutputContent)
}

// This checks that s3 buckets are there and being used by gitlab.
func TestGitlabS3buckets(t *testing.T) {
	bucketlist := [...]string{
		"login-gov-" + env_name + "-gitlabartifacts-" + accountid + "-" + region,
		"login-gov-" + env_name + "-gitlabediffs-" + accountid + "-" + region,
		"login-gov-" + env_name + "-gitlablfsobjects-" + accountid + "-" + region,
		"login-gov-" + env_name + "-gitlabuploads-" + accountid + "-" + region,
		"login-gov-" + env_name + "-gitlabpackages-" + accountid + "-" + region,
		"login-gov-" + env_name + "-gitlabdproxy-" + accountid + "-" + region,
		"login-gov-" + env_name + "-gitlabtfstate-" + accountid + "-" + region,
		"login-gov-" + env_name + "-gitlabpages-" + accountid + "-" + region,
	}

	// Check the buckets exist and have versioning enabled
	for _, bucket := range bucketlist {
		err := aws.AssertS3BucketExistsE(t, region, bucket)
		require.NoError(t, err, bucket+" bucket does not exist")
		versioning := aws.GetS3BucketVersioning(t, region, bucket)
		require.Equal(t, "Enabled", versioning, "versioning is not enabled on "+bucket)
	}
}

func TestGitlabAPI(t *testing.T) {
	// Create a gitlab token that we can use for the job
	token := gitlabToken(t)
	t.Cleanup(func() {
		deleteGitlabToken(t)
	})

	// Check that when we create a repo with a job that the job runs and creates
	// something in S3, indicating that gitlab is actually using S3
	asgName := env_name + "-gitlab"
	instances := aws.GetInstanceIdsForAsg(t, asgName, region)
	require.NotEmpty(t, instances)
	firstinstance := instances[0]

	// create project
	projectname := fmt.Sprintf("gitlabs3test-%d", os.Getpid())
	cmd := "curl -s -X POST --header 'PRIVATE-TOKEN: " + token +
		"' 'http://localhost:8080/api/v4/projects?name=" + projectname +
		"&initialize_with_readme=true&default_branch=main&auto_devops_enabled=true'"
	result := RunCommandOnInstance(t, firstinstance, cmd)
	require.Equal(t, int64(0), *result.ResponseCode, "could not create repo")

	// parse out project ID from result
	var jsonresult map[string]interface{}
	json.Unmarshal([]byte(*result.StandardOutputContent), &jsonresult)
	projectid := fmt.Sprintf("%.0f", jsonresult["id"])
	require.NotNil(t, jsonresult["id"], "projectid is nil.  Project creation said: "+*result.StandardOutputContent)

	// delete project after we are done
	deletecmd := "curl -s -X DELETE --header 'PRIVATE-TOKEN: " + token + "' 'http://localhost:8080/api/v4/projects/" + projectid + "'"
	t.Cleanup(func() {
		result = RunCommandOnInstance(t, firstinstance, deletecmd)
		require.Equal(t, int64(0), *result.ResponseCode, "could not delete repo")
		require.Contains(t, *result.StandardOutputContent, "202 Accepted", "could not delete repo")
	})

	// create a tag/release in project (starts a job)
	// POST /projects/:id/releases
	cmd = "curl -s --header 'Content-Type: application/json' --header 'PRIVATE-TOKEN: " + token +
		"' --data '{ \"name\": \"New release\", \"tag_name\": \"v0.3\", \"description\": \"Super nice release\", \"ref\": \"main\" }'" +
		" --request POST http://localhost:8080/api/v4/projects/" + projectid + "/releases"

	result = RunCommandOnInstance(t, firstinstance, cmd)
	require.Equal(t, int64(0), *result.ResponseCode, "could not create a release with "+strings.ReplaceAll(cmd, token, "XXX"))
	require.NotContains(t, *result.StandardOutputContent, "Bad Request", "could not create a release with "+cmd)

	// watch /projects/:id/jobs with project ID to see when job completes
	jobid := "1"
	cmd = "curl -s --header 'PRIVATE-TOKEN: " + token +
		"' 'http://localhost:8080/api/v4/projects/" + projectid +
		"/jobs'"
	var jobtimeout int
	for jobtimeout = 18; jobtimeout > 0; jobtimeout-- {
		result = RunCommandOnInstance(t, firstinstance, cmd)
		require.Equal(t, int64(0), *result.ResponseCode, "could not get list of jobs with "+cmd)
		var jobresult []map[string]interface{}
		json.Unmarshal([]byte(*result.StandardOutputContent), &jobresult)

		i := -1
		for z, job := range jobresult {
			if job["status"] == "failed" {
				jobid = fmt.Sprintf("%.0f", job["id"])
				i = z
				break
			}
		}
		if (i != -1) && (jobresult[i]["status"] == "failed") {
			// There is a job, it is done, we can look for the logs now
			break
		}

		fmt.Printf("no jobs in %s are done, waiting until there is one\n", projectname)
		time.Sleep(10)
	}
	require.NotEqual(t, 0, jobtimeout, "timed out:  no job finished")

	// Download artifact
	// GET /projects/:id/jobs/:job_id/artifacts/job.log
	cmd = "curl -s --header 'PRIVATE-TOKEN: " + token +
		"' 'http://localhost:8080/api/v4/projects/" + projectid +
		"/jobs/" + jobid + "/trace'"
	result = RunCommandOnInstance(t, firstinstance, cmd)
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
	// If we're inside Gitlab CI, we implictly know it works.
	if os.Getenv("CI_PROJECT_DIR") != "" {
		return
	}

	// make sure docker is running
	instances := aws.GetInstanceIdsForAsg(t, runner_asg, region)
	require.NotEmpty(t, instances)
	firstinstance := instances[0]
	cmd := "docker info"
	result := RunCommandOnInstance(t, firstinstance, cmd)
	require.Equal(t, int64(0), *result.ResponseCode, cmd+" failed: "+*result.StandardOutputContent)
}

// This makes sure that the proper ssh key is installed
func TestSshKey(t *testing.T) {
	asgName := env_name + "-gitlab"
	// make sure the keys are the same
	instances := aws.GetInstanceIdsForAsg(t, asgName, region)
	require.NotEmpty(t, instances)
	firstinstance := instances[0]
	cmd := "tar xOzf /etc/gitlab/etc_ssh.tar.gz ssh/ssh_host_ecdsa_key.pub"
	tarfileresult := RunCommandOnInstance(t, firstinstance, cmd)
	require.Equal(t, int64(0), *tarfileresult.ResponseCode, cmd+" failed: "+*tarfileresult.StandardOutputContent)
	cmd = "cat /etc/ssh/ssh_host_ecdsa_key.pub"
	fileresult := RunCommandOnInstance(t, firstinstance, cmd)
	require.Equal(t, int64(0), *fileresult.ResponseCode, cmd+" failed: "+*fileresult.StandardOutputContent)
	require.Equal(t, *tarfileresult.StandardOutputContent, *fileresult.StandardOutputContent, "ssh key is not the same as the archived ssh key")

	// check against live sshd
	cmd = "ssh-keyscan localhost | grep ecdsa | awk '{print $3}'"
	result := RunCommandOnInstance(t, firstinstance, cmd)
	require.Contains(t, *tarfileresult.StandardOutputContent, strings.TrimSpace(*result.StandardOutputContent), "archived ssh key was not the same as the running sshd key")
}

// XXX This will be working once the new AMI gets out that has
// XXX https://github.com/18F/identity-base-image/pull/178 in it.
// // This tests whether we are still fulfilling the s1.2.x auditd controls.
// func TestSOneTwo(t *testing.T) {
// 	instances := aws.GetInstanceIdsForAsg(t, runner_asg, region)
//  require.NotEmpty(t, instances)
// 	firstinstance := instances[0]
// 	cmd := "sudo auditctl -l"
// 	result := RunCommandOnInstance(t, firstinstance, cmd)
// 	require.Equal(t, int64(0), *result.ResponseCode, cmd+" failed: "+*result.StandardOutputContent)
// 	require.Contains(t, *result.StandardOutputContent, "docker", "According to compliance control s1.2.x, auditd needs to have docker stuff in it")
// }

// this is to store the dockerd proc info for s2.x so we only have to get it once.
type DockerdProc struct {
	mu          sync.Mutex
	commandline string
}

var dockerdproc = DockerdProc{commandline: ""}

func GetDockerdProc(t *testing.T) string {
	dockerdproc.mu.Lock()
	defer dockerdproc.mu.Unlock()

	if dockerdproc.commandline == "" {
		instances := aws.GetInstanceIdsForAsg(t, runner_asg, region)
		require.NotEmpty(t, instances)
		firstinstance := instances[0]
		cmd := "ps gaxuwww | grep -v grep | grep dockerd"
		result := RunCommandOnInstance(t, firstinstance, cmd)
		require.Equal(t, int64(0), *result.ResponseCode, cmd+" failed: "+*result.StandardOutputContent)
		dockerdproc.commandline = *result.StandardOutputContent
	}
	return dockerdproc.commandline
}

// This tests whether we are still fulfilling the s2.1 control.
func TestSTwoOne(t *testing.T) {
	require.Contains(t, GetDockerdProc(t), "--icc=false", "According to compliance control s2.1, icc should be false")
}

// This tests whether we are still fulfilling the s2.10 control.
func TestSTwoTen(t *testing.T) {
	require.NotContains(t, GetDockerdProc(t), "dm.basesize", "According to compliance control s2.10, dm.basesize should not be set")
}

// This tests whether we are still fulfilling the s2.11 and s3.15 control.
func TestSTwoEleven(t *testing.T) {
	instances := aws.GetInstanceIdsForAsg(t, runner_asg, region)
	require.NotEmpty(t, instances)
	firstinstance := instances[0]
	cmd := "ls -l /var/run/docker.sock"
	result := RunCommandOnInstance(t, firstinstance, cmd)
	require.Equal(t, int64(0), *result.ResponseCode, cmd+" failed: "+*result.StandardOutputContent)
	require.Contains(t, *result.StandardOutputContent, "srw-rw---- 1 root docker", "According to compliance controls s2.11 and s3.15, use of docker should only be authorized for members of the docker group and root")
}

// This tests whether we are still fulfilling the s2.12 and s2.2 controls.
func TestSTwoTwelve(t *testing.T) {
	require.Contains(t, GetDockerdProc(t), "--log-level=debug", "According to compliance control s2.12 and s2.2, Dockerd should be logging at least at info level")
}

// This tests whether we are still fulfilling the s2.13 control.
func TestSTwoThirteen(t *testing.T) {
	require.Contains(t, GetDockerdProc(t), "--live-restore", "According to compliance control s2.13, Dockerd should have live_restore enabled")
}

// This tests whether we are still fulfilling the s2.16 control.
func TestSTwoSixteen(t *testing.T) {
	require.NotContains(t, GetDockerdProc(t), "--experimental", "According to compliance control s2.16, Dockerd should have experimental features disabled")
}

// This tests whether we are still fulfilling the s2.17 control.
func TestSTwoSeventeen(t *testing.T) {
	require.Contains(t, GetDockerdProc(t), "--no-new-privileges", "According to compliance control s2.17, Dockerd should have --no-new-privileges set")
}

// This tests whether we are still fulfilling the s2.3 control.
func TestSTwoThree(t *testing.T) {
	require.NotContains(t, GetDockerdProc(t), "--iptables=false", "According to compliance control s2.3, Dockerd should be able to change iptables")
}

// This tests whether we are still fulfilling the s2.5 control.
func TestSTwoFour(t *testing.T) {
	require.NotContains(t, GetDockerdProc(t), "storage-driver aufs", "According to compliance control s2.5, Dockerd should not use aufs")
}

// This tests whether we are still fulfilling the s2.8 control.
func TestSTwoEight(t *testing.T) {
	require.Contains(t, GetDockerdProc(t), "--userns-remap=default", "According to compliance control s2.8, Dockerd should remap uids/gids")
}

// This tests whether we are still fulfilling the s3.17 control.
func TestSThreeSeventeen(t *testing.T) {
	instances := aws.GetInstanceIdsForAsg(t, runner_asg, region)
	require.NotEmpty(t, instances)
	firstinstance := instances[0]
	cmd := "ls -l /etc/docker/daemon.json"
	result := RunCommandOnInstance(t, firstinstance, cmd)
	require.NotEqual(t, int64(0), *result.ResponseCode, "/etc/docker/daemon.json should not exist, as we are using the docker recipe to configure the commandline to configure it so that we don't have to manage the perms/ownership of this.")
}

// This tests whether we are still fulfilling the s3.19 control.
func TestSThreeNineteen(t *testing.T) {
	instances := aws.GetInstanceIdsForAsg(t, runner_asg, region)
	require.NotEmpty(t, instances)
	firstinstance := instances[0]
	cmd := "ls -l /etc/default/docker"
	result := RunCommandOnInstance(t, firstinstance, cmd)
	require.Equal(t, int64(0), *result.ResponseCode, cmd+" failed: "+*result.StandardOutputContent)
	require.Contains(t, *result.StandardOutputContent, "-rw-r--r-- 1 root root", "According to compliance control s3.19, the docker defaults should only be editable by root")
}

// This tests whether we are still fulfilling the s3.2 control.
func TestSThreeTwo(t *testing.T) {
	instances := aws.GetInstanceIdsForAsg(t, runner_asg, region)
	require.NotEmpty(t, instances)
	firstinstance := instances[0]
	cmd := "ls -l $(systemctl show -p FragmentPath docker.service | awk -F= '{print $2}')"
	result := RunCommandOnInstance(t, firstinstance, cmd)
	require.Equal(t, int64(0), *result.ResponseCode, cmd+" failed: "+*result.StandardOutputContent)
	require.Contains(t, *result.StandardOutputContent, "-rw-r--r-- 1 root root", "According to compliance control s3.2, the docker service file should only be editable by root")
}

// This tests whether we are still fulfilling the s3.20 control.
func TestSThreeTwenty(t *testing.T) {
	instances := aws.GetInstanceIdsForAsg(t, runner_asg, region)
	require.NotEmpty(t, instances)
	firstinstance := instances[0]
	cmd := "ls -l /etc/sysconfig/docker"
	result := RunCommandOnInstance(t, firstinstance, cmd)
	require.NotEqual(t, int64(0), *result.ResponseCode, "/etc/sysconfig/docker should not exist by default so that s3.20 is fulfilled")
}

// This tests whether we are still fulfilling the s3.3 control.
func TestSThreeThree(t *testing.T) {
	instances := aws.GetInstanceIdsForAsg(t, runner_asg, region)
	require.NotEmpty(t, instances)
	firstinstance := instances[0]
	cmd := "ls -l $(systemctl show -p FragmentPath docker.socket | awk -F= '{print $2}')"
	result := RunCommandOnInstance(t, firstinstance, cmd)
	require.Equal(t, int64(0), *result.ResponseCode, cmd+" failed: "+*result.StandardOutputContent)
	require.Contains(t, *result.StandardOutputContent, "-rw-r--r-- 1 root root", "According to compliance control s3.3, the docker socket should have these perms")
}

// This tests whether we are still fulfilling the s3.5 control.
func TestSThreeFive(t *testing.T) {
	instances := aws.GetInstanceIdsForAsg(t, runner_asg, region)
	require.NotEmpty(t, instances)
	firstinstance := instances[0]
	cmd := "ls -ld /etc/docker"
	result := RunCommandOnInstance(t, firstinstance, cmd)
	if *result.ResponseCode != int64(0) {
		// If /etc/docker doesn't exist, that's cool.  Otherwise, unknown error.
		require.Contains(t, *result.StandardOutputContent, "cannot access '/etc/docker': No such file or directory", "There was an unknown error when looking at /etc/docker permissions: "+*result.StandardOutputContent)
	} else {
		// /etc/docker perms are proper.
		require.Contains(t, *result.StandardOutputContent, "drwxr-xr-x 2 root root", "According to compliance control s3.5, the docker dir should have these perms")
	}
}

// This tests whether we are still fulfilling the s3.7 control.
func TestSThreeSeven(t *testing.T) {
	instances := aws.GetInstanceIdsForAsg(t, runner_asg, region)
	require.NotEmpty(t, instances)
	firstinstance := instances[0]
	cmd := "ls -ld /etc/docker/certs.d"
	result := RunCommandOnInstance(t, firstinstance, cmd)
	require.NotEqual(t, int64(0), *result.ResponseCode, "/etc/docker/certs.d should not exist, as we are not using certs.  Otherwise, s3.7 requires us to manage the perms of this.")
}

func TestPlantUml(t *testing.T) {
	// Encoded UML from doc/architecture/waf.md
	// This was chosen because it excercises the `!include` directive.
	testUML := "https://" + domain + "/-/plantuml/png/~1U9oDLDzlsZ0GVkUlkF42I0rfEvxwC0aOHKWjGx2sZvD9Zc3DE9djaB5g__lETe44GhiemiVTTxy_fmN37aIfD8nBLBhnYSj8v37cIi3Qc4pVXQ5YHJVXPfqlSutAWb6QRfHkmZcFc8hJASSCHJZi1JF1f7bwV0WL2cGQmvlWclG_XliCtIpVY4QZ1VsN1Kme5gMCSKKcgvcHyJ_Iia8BjjJs3BYD4QnI5MGsDmK8jpUVkzTXpBKvjBCF7j8vx4qeLAAOuQdqzG0zjT1qi_a8i-2RJF0Ln_WTt1YfToP29iGxg2cQ8bK_kKo6ljklAFWMrUu3Foepomr-W5fWb2jkTfEO8jDflGHdCYevEayo2eGv_ifH6xWNQG4qNnYJcYsXNOGl_VkEGmxINCPCxThRJ5v1Sxpem_Diskp0gpFldoVQdxOOkqXDGATeaj3qSVxQn1vL1sbKCaKsaw_bUJOyIJOIJ1iUFQGi7Z0YH4J3V1lhKOUgBSMImamV1fIYK_ANgK4Gk3AL1ln3Q0rnAbi6rcoBeDy62ebAyqntuP59bY2mA4AjOSiP6AOIDBfrXcrSYfyffCufkbaZH8BJhbeQ9hCktDCEg64OoJXBkJGq9RFc6kYrM3-IW1016L599Wvkq_xtAfWK53NBbu975bMg1cNifb0fS3IydKXjxEnqM-LI-YNDdVJdP8Ody4oblpbQ-BV1pCdlEhGJryXXoMVO0nMOMDBbN_64i7tQPEUrPgW0nDPsmLO48gbvrRa4ckS2BL3HwPiJjj9wV1tF-XdTfyXzLYfSOuvhPrIpjFU_rRk4Skj9FfBR6eQ3rHquG6WlERmNInUhTY6Ke6w5fpwNlIzjjDmE5Kaa6pE31Tkr9RC5aiBEqzdtNmC8uhIGmHUW6-aCzTfzcpM6VJD0scDn3IZzyIOVmNaTNFACJ4SNi74FEMXnTz3hVJupU8hUmUsjCp5hiX-D08W_JaLdIUKeTOHMeZYr5-6abbBrD41V1QkEu1-shL5m"
	resp, err := http.Get(testUML)
	require.NoError(t, err, "HTTP request to plantuml-server failed")
	defer resp.Body.Close()
	errorMessage := resp.Header.Get("X-Plantuml-Diagram-Error")
	require.Equal(t, 200, resp.StatusCode, "plantUML could not be rendered: "+errorMessage)
}
