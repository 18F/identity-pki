package test

import (
	"regexp"
	"strings"
	"testing"

	"github.com/gruntwork-io/terratest/modules/aws"
	"github.com/stretchr/testify/assert"
)

func _TestMemory(t *testing.T) {
	asgName := env_name + "-gitlab_runner"
	instances := aws.GetInstanceIdsForAsg(t, asgName, region)
	cmd := "docker ps --quiet --all | xargs docker inspect --format '{{.Name}}: {{ .HostConfig.Memory }}'"
	result := RunCommandOnInstances(t, instances, cmd)
	t.Log(*result.StandardOutputContent)
	for _, s := range strings.Split(*result.StandardOutputContent, "\n") {
		// TODO: Remove conditional once https://gitlab.com/gitlab-org/gitlab-runner/-/merge_requests/1834 is merged
		if !regexp.MustCompile("-postgres-|-redis-").MatchString(s) {
			assert.NotRegexp(t, ": 0$", s)
		}
	}
}

func TestJobContainers(t *testing.T) {
	// TODO: setup: start long-running job

	t.Run("Require memory arg", _TestMemory)

	// TODO: teardown: cancel long-running job
}
