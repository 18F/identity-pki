package test

import (
	"regexp"
	"strings"
	"testing"

	"github.com/gruntwork-io/terratest/modules/aws"
	"github.com/stretchr/testify/assert"
)

func RunOnRunners(t *testing.T, cmd string) []string {
	t.Parallel()
	asgName := env_name + "-gitlab_runner"
	instances := aws.GetInstanceIdsForAsg(t, asgName, region)
	result := RunCommandOnInstances(t, instances, cmd)
	t.Log(*result.StandardOutputContent)
	return strings.Split(*result.StandardErrorContent, "\n")
}

func _TestMemory(t *testing.T) {
	cmd := "docker ps --quiet --all | xargs docker inspect --format '{{.Name}}: {{ .HostConfig.Memory }}'"
	for _, s := range RunOnRunners(t, cmd) {
		// TODO: Remove conditional once https://gitlab.com/gitlab-org/gitlab-runner/-/merge_requests/1834 is merged
		if !regexp.MustCompile("-postgres-|-redis-").MatchString(s) {
			assert.NotRegexp(t, ": 0$", s)
		}
	}
}

func _TestCPUShares(t *testing.T) {
	cmd := "docker ps --quiet --all | xargs docker inspect --format '{{ .Name }}: {{ .HostConfig.CpuShares }}'"
	for _, s := range RunOnRunners(t, cmd) {
		// TODO: Remove conditional once https://gitlab.com/gitlab-org/gitlab-runner/-/merge_requests/1834 is merged
		if !regexp.MustCompile("-postgres-|-redis-").MatchString(s) {
			assert.NotRegexp(t, ": 0$", s)
		}
	}
}

func _TestBoundHostInterface(t *testing.T) {
	cmd := "docker ps --quiet | xargs docker inspect --format '{{ .Name }}: {{ .NetworkSettings.Ports }}'"
	for _, s := range RunOnRunners(t, cmd) {
		assert.NotRegexp(t, "0\\.0\\.0\\.0|::", s)
	}
}

func _TestContainerRestartPolicy(t *testing.T) {
	cmd := "docker ps --quiet --all | xargs docker inspect --format '{{ .Name }}: RestartPolicyName={{ .HostConfig.RestartPolicy.Name }} MaximumRetryCount={{ .HostConfig.RestartPolicy.MaximumRetryCount }}'"
	for _, s := range RunOnRunners(t, cmd) {
		assert.NotRegexp(t, "RestartPolicyName=always", s)
		if regexp.MustCompile("RestartPolicyName=on-failure").MatchString(s) {
			assert.Regexp(t, "MaximumRetryCount=[0-5]$", s)
		}
	}
}

func _TestSharedProcessNamespace(t *testing.T) {
	cmd := "docker ps --quiet --all | xargs docker inspect --format '{{ .Name }}: PidMode={{ .HostConfig.PidMode }}'"
	for _, s := range RunOnRunners(t, cmd) {
		assert.NotRegexp(t, "PidMode=host", s)
	}
}

func TestJobContainers(t *testing.T) {
	// TODO: setup: start long-running job

	t.Run("Require memory arg", _TestMemory)
	t.Run("Require cpu_shares arg", _TestCPUShares)
	t.Run("Require bound interfaces", _TestBoundHostInterface)
	t.Run("Ensure on-failure restart policy <= 5", _TestContainerRestartPolicy)
	t.Run("Ensure host process namespace is not shared", _TestSharedProcessNamespace)

	// TODO: teardown: cancel long-running job
}
