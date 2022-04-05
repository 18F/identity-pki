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
	instances := aws.GetInstanceIdsForAsg(t, env_name+"-gitlab-build-pool", region)
	instances = append(instances, aws.GetInstanceIdsForAsg(t, env_name+"-gitlab-test-pool", region)...)

	results := RunCommandOnInstances(t, instances, cmd)
	combinedOut := []string{}
	for _, result := range results {
		slicedOut := strings.Split(*result.StandardOutputContent, "\n")
		slicedErr := strings.Split(*result.StandardErrorContent, "\n")
		combinedOut = append(combinedOut, slicedOut...)
		combinedOut = append(combinedOut, slicedErr...)
	}
	return combinedOut
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

func _TestFileOwnershipDockerService(t *testing.T) {
	cmd := "stat -c '%U %G' $(systemctl show -p FragmentPath docker.service --value)"
	for _, s := range RunOnRunners(t, cmd) {
		// TODO: Remove conditional once https://gitlab.com/gitlab-org/gitlab-runner/-/merge_requests/1834 is merged
		if !regexp.MustCompile("root root").MatchString(s) {
			assert.NotRegexp(t, ": 0$", s)
		}
	}
}

func _TestFilePermissionsDockerService(t *testing.T) {
	cmd := "stat -c '%a' $(systemctl show -p FragmentPath docker.service --value)"
	for _, s := range RunOnRunners(t, cmd) {
		// TODO: Remove conditional once https://gitlab.com/gitlab-org/gitlab-runner/-/merge_requests/1834 is merged
		if !regexp.MustCompile("644").MatchString(s) {
			assert.NotRegexp(t, ": 0$", s)
		}
	}
}

// s5.18
func _TestUlimits(t *testing.T) {
	cmd := "docker ps --quiet --all | xargs docker inspect --format '{{ .Id }}: Ulimits={{ .HostConfig.Ulimits }}'"
	for _, s := range RunOnRunners(t, cmd) {
		if regexp.MustCompile("Ulimits").MatchString(s) {
			assert.Regexp(t, ": Ulimits=<no value>$", s)
		}
	}
}


func TestJobContainers(t *testing.T) {
	t.Run("s5.10 Require memory arg", _TestMemory)
	t.Run("s5.11 Require cpu_shares arg", _TestCPUShares)
	t.Run("Require bound interfaces", _TestBoundHostInterface)
	t.Run("Ensure on-failure restart policy <= 5", _TestContainerRestartPolicy)
	t.Run("Ensure host process namespace is not shared", _TestSharedProcessNamespace)
	t.Run("Ensure Docker service file ownership is correct", _TestFileOwnershipDockerService)
	t.Run("Ensure Docker service file permissions are correct", _TestFilePermissionsDockerService)
	t.Run("Ensure that the default ulimit is not overwritten at runtime", _TestUlimits)
}
