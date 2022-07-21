package test

import (
	"encoding/json"
	"fmt"
	"os"
	"strconv"
	"testing"
	"time"

	http_helper "github.com/gruntwork-io/terratest/modules/http-helper"
	"github.com/stretchr/testify/require"
)

var gitlab_hostname = os.Getenv("CI_SERVER_HOST")
var ci_token = os.Getenv("CI_JOB_TOKEN")
var api_token = os.Getenv("API_TOKEN")
var pipeline_id = os.Getenv("CI_PIPELINE_ID")
var project_id = os.Getenv("CI_PROJECT_ID")

// See if we can run a docker container that we aren't supposed to on the
// env_runner.
func CheckEnvRunnerLockdown(t *testing.T) {
	// get the project
	headers := map[string]string{"PRIVATE-TOKEN": api_token}

	// get the job
	url := fmt.Sprintf("https://%s/api/v4/projects/%s/pipelines/%s/jobs", gitlab_hostname, project_id, pipeline_id)
	httpstatus, body := http_helper.HTTPDo(t, "GET", url, nil, headers, nil)
	require.Equal(t, 200, httpstatus, "Could not do the jobs API call for some reason")

	// decode json body and find lg/identity-devops to get ID
	var jsonList []map[string]interface{}
	json.Unmarshal([]byte(body), &jsonList)
	var jobid = ""
	var runjobstring string
	jobname := fmt.Sprintf("badtest_%s", env_name)

	for _, element := range jsonList {
		if element["name"] == jobname {
			jobid = strconv.FormatFloat(element["id"].(float64), 'f', -1, 64)

			// This is because according to gitlab support, "The API call to play a job is only for manual jobs that have yet to run, not failed jobs"
			// Thus, this lets us re-run the test if we need to.
			if element["status"] == "manual" {
				runjobstring = "play"
			} else {
				runjobstring = "retry"
			}

			break
		}
	}
	require.NotEqual(t, jobid, "", "Could not find the job: "+jobname)

	// Make an HTTP request to the URL to kick off the job
	url = fmt.Sprintf("https://%s/api/v4/projects/%s/jobs/%s/%s", gitlab_hostname, project_id, jobid, runjobstring)
	httpstatus, body = http_helper.HTTPDo(t, "POST", url, nil, headers, nil)
	require.Equal(t, 201, httpstatus, "Could not run job for some reason")

	// find the new job ID
	var jsonData map[string]interface{}
	json.Unmarshal([]byte(body), &jsonData)
	newjobid := strconv.FormatFloat(jsonData["id"].(float64), 'f', -1, 64)

	// loop on job status until it is done, verify that it failed
	var status interface{}
	var i int
	var timeout = 60
	for i = 0; i < timeout; i++ {
		url = fmt.Sprintf("https://%s/api/v4/projects/%s/jobs/%s", gitlab_hostname, project_id, newjobid)
		httpstatus, body = http_helper.HTTPDo(t, "GET", url, nil, headers, nil)
		require.Equal(t, 200, httpstatus, "Could not get the new job for some reason")
		json.Unmarshal([]byte(body), &jsonData)

		if jsonData["finished_at"] != nil {
			status = jsonData["status"]
			break
		}
		time.Sleep(1 * time.Second)
	}
	require.NotEqual(t, timeout, i, "timed out waiting for job to run")
	require.Equal(t, "failed", status, "The badtest job should have failed, thus the env_runner is not limiting what images it can run")
}

func TestEnvRunnerLockdown(t *testing.T) {
	// Argh. This is supposed to run in the test pipeline, but CI_JOB_TOKEN apparently
	// can't look at jobs.  So this can only be run by hand if you set these variables:
	// 	API_TOKEN=<user token with api scope>
	// 	CI_PROJECT_ID=<project ID (21 for identity-devops in prod)>
	//	CI_PIPELINE_ID=<pipeline ID where the badtest job is ready to be run>
	//	CI_SERVER_HOST=gitlab.login.gov
	//	ENV_NAME=<idp env that the env_runner is in that you want to test>
	//
	if api_token != "" {
		CheckEnvRunnerLockdown(t)
	} else {
		api_token = ci_token
		// Once the CI_JOB_TOKEN can be enhanced so that it can kick off and read jobs
		// (hopefully, as a result of https://gitlab.com/groups/gitlab-org/-/epics/3559 or
		// https://gitlab.com/groups/gitlab-org/-/epics/6310), take this next line out.
		t.Skip("API_TOKEN is not set, thus we will not test whether the env_runner is locked down")
		CheckEnvRunnerLockdown(t)
	}
}
