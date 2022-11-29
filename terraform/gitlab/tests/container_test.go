package test

import (
	"regexp"
	"strconv"
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

// s5.3
func _TestDropCapabilities(t *testing.T) {
	cmd := "docker ps --quiet --all | xargs docker inspect --format '{{ .Name }}: CapAdd={{ .HostConfig.CapAdd }} CapDrop={{ .HostConfig.CapDrop }}'"
	for _, s := range RunOnRunners(t, cmd) {
		// Ignore redis and postgres
		if regexp.MustCompile("-postgres-|-redis-").MatchString(s) {
			continue
		}
		if regexp.MustCompile("CapDrop").MatchString(s) {
			assert.Regexp(t, "CapDrop=\\[net_raw\\]", s)
		}
	}
}

// s5.4
func _TestPrivilegedContainers(t *testing.T) {
	cmd := "docker ps --quiet --all | xargs docker inspect --format '{{ .Id }}: Privileged={{ .HostConfig.Privileged }}'"
	for _, s := range RunOnRunners(t, cmd) {
		if regexp.MustCompile("Privileged=").MatchString(s) {
			assert.Regexp(t, "Privileged=false", s)
		}
	}
}

// s5.5
func _TestSensitiveMounts(t *testing.T) {
	cmd := "docker ps --quiet --all | xargs docker inspect --format '{{ .Id }}: Volumes={{ range .Mounts }}{{ .Source }}{{ end }}'"
	for _, s := range RunOnRunners(t, cmd) {
		// Sensitive directories per CIS Docker Benchmark
		badMounts := []string{
			"/",
			"/boot",
			"/dev",
			"/etc",
			"/lib",
			"/proc",
			"/sys",
			"/usr",
		}
		for _, mount := range badMounts {
			assert.NotRegexp(t, "Volumes="+mount+"$", s)
		}
	}
}

// s5.6
func _TestSSHD(t *testing.T) {
	cmd := "docker ps --quiet | xargs -n 1 -i docker exec '{}' pgrep -l sshd"
	for _, s := range RunOnRunners(t, cmd) {
			assert.NotRegexp(t, "sshd", s)
	}
}

// s5.7
func _TestLowPorts(t *testing.T) {
	cmd := "docker ps --quiet --all | xargs docker inspect --format '{{ range $k, $v := .NetworkSettings.Ports }}{{ $k }}\n{{ end }}'"
	for _, s := range RunOnRunners(t, cmd) {
		if ms := regexp.MustCompile("([0-9]+)/tcp").FindStringSubmatch(s); len(ms) > 0 {
			port, _ := strconv.Atoi(ms[1])
			assert.GreaterOrEqual(t, port, 1024)
		}
	}
}

// s5.9
func _TestNetworkMode(t *testing.T) {
	cmd := "docker ps --quiet --all | xargs docker inspect --format '{{ .Id }}: NetworkMode={{ .HostConfig.NetworkMode }}'"
	for _, s := range RunOnRunners(t, cmd) {
			assert.NotRegexp(t, "NetworkMode=host", s)
	}
}

// s5.10
func _TestMemory(t *testing.T) {
	cmd := "docker ps --quiet --all | xargs docker inspect --format '{{.Name}}: {{ .HostConfig.Memory }}'"
	for _, s := range RunOnRunners(t, cmd) {
		// TODO: Remove conditional once https://gitlab.com/gitlab-org/gitlab-runner/-/merge_requests/1834 is merged
		if !regexp.MustCompile("-postgres-|-redis-").MatchString(s) {
			assert.NotRegexp(t, ": 0$", s)
		}
	}
}

// s5.11
func _TestCPUShares(t *testing.T) {
	cmd := "docker ps --quiet --all | xargs docker inspect --format '{{ .Name }}: {{ .HostConfig.CpuShares }}'"
	for _, s := range RunOnRunners(t, cmd) {
		// TODO: Remove conditional once https://gitlab.com/gitlab-org/gitlab-runner/-/merge_requests/1834 is merged
		if !regexp.MustCompile("-postgres-|-redis-").MatchString(s) {
			assert.NotRegexp(t, ": 0$", s)
		}
	}
}

// s5.13
func _TestBoundHostInterface(t *testing.T) {
	cmd := "docker ps --quiet | xargs docker inspect --format '{{ .Name }}: {{ .NetworkSettings.Ports }}'"
	for _, s := range RunOnRunners(t, cmd) {
		assert.NotRegexp(t, "0\\.0\\.0\\.0|::", s)
	}
}

// s5.14
func _TestContainerRestartPolicy(t *testing.T) {
	cmd := "docker ps --quiet --all | xargs docker inspect --format '{{ .Name }}: RestartPolicyName={{ .HostConfig.RestartPolicy.Name }} MaximumRetryCount={{ .HostConfig.RestartPolicy.MaximumRetryCount }}'"
	for _, s := range RunOnRunners(t, cmd) {
		assert.NotRegexp(t, "RestartPolicyName=always", s)
		if regexp.MustCompile(".*RestartPolicyName=on-failure.*").MatchString(s) {
			assert.Regexp(t, "MaximumRetryCount=[0-5]$", s)
		}
	}
}

// s5.15
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

// s5.16
func _TestIPCNamespace(t *testing.T) {
	cmd := "docker ps --quiet --all | xargs docker inspect --format '{{ .Id }}: IpcMode={{ .HostConfig.IpcMode }}'"
	for _, s := range RunOnRunners(t, cmd) {
		assert.NotRegexp(t, "IpcMode=host", s)
	}
}

// s5.17
func _TestSharedDevices(t *testing.T) {
	cmd := "docker ps --quiet --all | xargs docker inspect --format '{{ .Id }}: Devices={{ .HostConfig.Devices }}'"
	for _, s := range RunOnRunners(t, cmd) {
		if regexp.MustCompile(".*Devices=.*").MatchString(s) {
			assert.Regexp(t, "Devices=<no value>", s)
		}
	}
}

// s5.18
func _TestUlimits(t *testing.T) {
	cmd := "docker ps --quiet --all | xargs docker inspect --format '{{ .Id }}: Ulimits={{ .HostConfig.Ulimits }}'"
	for _, s := range RunOnRunners(t, cmd) {
		if regexp.MustCompile("Ulimits").MatchString(s) {
			assert.Regexp(t, ": Ulimits=.*nproc.*$", s)
		}
	}
}

// s5.19
func _TestPropagationMode(t *testing.T) {
	cmd := "docker ps --quiet --all | xargs docker inspect --format '{{ .Id }}: Propagation={{range $mnt := .Mounts}} {{json $mnt.Propagation}} {{end}}'"
	for _, s := range RunOnRunners(t, cmd) {
		if regexp.MustCompile("Propagation").MatchString(s) {
			assert.NotRegexp(t, "shared", s)
		}
	}
}

// s5.20
func _TestUTSNamespace(t *testing.T) {
	cmd := "docker ps --quiet --all | xargs docker inspect --format '{{ .Id }}: UTSMode={{ .HostConfig.UTSMode }}'"
	for _, s := range RunOnRunners(t, cmd) {
		if regexp.MustCompile("UTSMode").MatchString(s) {
			assert.NotRegexp(t, "UTSMode=host", s)
		}
	}
}

// s5.21
func _TestSeccomp(t *testing.T) {
	cmd := "docker ps --quiet --all | xargs docker inspect --format '{{ .Id }}: SecurityOpt={{ .HostConfig.SecurityOpt }}'"
	for _, s := range RunOnRunners(t, cmd) {
		if regexp.MustCompile("SecurityOpt").MatchString(s) {
			assert.NotRegexp(t, "unconfined", s)
		}
	}
}

// s5.22
func _TestPrivilegedExec(t *testing.T) {
	cmd := "ausearch -k docker | grep exec | grep privileged && echo FAILURE"
	for _, s := range RunOnRunners(t, cmd) {
		assert.NotRegexp(t, "FAILURE", s)
	}
}

// s5.23
func _TestRootExec(t *testing.T) {
	cmd := "ausearch -k docker | grep exec | grep user"
	for _, s := range RunOnRunners(t, cmd) {
		assert.NotRegexp(t, "root", s)
	}
}

// s5.24
func _TestCgroupUsage(t *testing.T) {
	cmd := "docker ps --quiet --all | xargs docker inspect --format '{{ .Id }}: CgroupParent={{ .HostConfig.CgroupParent }}'"
	for _, s := range RunOnRunners(t, cmd) {
		assert.NotRegexp(t, "CgroupParent=.", s)
	}
}

// s5.25
func _TestNoNewPrivileges(t *testing.T) {
	cmd := "docker ps --quiet --all | xargs docker inspect --format '{{ .Name }}: SecurityOpt={{ .HostConfig.SecurityOpt }}'"

	for _, s := range RunOnRunners(t, cmd) {
		// Ignore redis and postgres
		if regexp.MustCompile("-postgres-|-redis-").MatchString(s) {
			continue
		}

		if regexp.MustCompile("SecurityOpt").MatchString(s) {
			assert.Regexp(t, "no-new-privileges", s)
		}
	}
}

// s5.29
func _TestDockerNetworking(t *testing.T) {
	cmd := "docker network inspect bridge --format '{{ .Containers }}'"
	for _, s := range RunOnRunners(t, cmd) {
		if regexp.MustCompile("map").MatchString(s) {
			assert.Regexp(t, "map\\[\\]", s)
		}
	}
}

// s5.30
func _TestHostUserNamespace(t *testing.T) {
	cmd := "docker ps --quiet --all | xargs docker inspect --format '{{ .Id }}: UsernsMode={{ .HostConfig.UsernsMode }}'"
	for _, s := range RunOnRunners(t, cmd) {
		assert.NotRegexp(t, "UsernsMode=.", s)
	}
}

// s5.31
func _TestDockerSocket(t *testing.T) {
	cmd := "docker ps --quiet --all | xargs docker inspect --format '{{ .Id }}: Volumes={{ .Mounts }}'"
	for _, s := range RunOnRunners(t, cmd) {
		assert.NotRegexp(t, "docker\\.sock", s)
	}
}

func TestJobContainers(t *testing.T) {
	t.Run("s5.3 Ensure that Linux kernel capabilities are restricted within containers", _TestDropCapabilities)
	t.Run("s5.4 Ensure that privileged containers are not used", _TestPrivilegedContainers)
	t.Run("s5.5 Ensure sensitive host system directories are not mounted on containers", _TestSensitiveMounts)
	t.Run("s5.6 Ensure sshd is not run within containers", _TestSSHD)
	t.Run("s5.7 Ensure privileged ports are not mapped within containers", _TestLowPorts)
	t.Run("s5.9 Ensure that the host's network namespace is not shared", _TestNetworkMode)
	t.Run("s5.10 Require memory arg", _TestMemory)
	t.Run("s5.11 Require cpu_shares arg", _TestCPUShares)
	t.Run("s5.13 Require bound interfaces", _TestBoundHostInterface)
	t.Run("s5.14 Ensure on-failure restart policy <= 5", _TestContainerRestartPolicy)
	t.Run("s5.15 Ensure host process namespace is not shared", _TestSharedProcessNamespace)
	t.Run("Ensure Docker service file ownership is correct", _TestFileOwnershipDockerService)
	t.Run("Ensure Docker service file permissions are correct", _TestFilePermissionsDockerService)
	t.Run("s5.16 Ensure IPC namespace is not shared", _TestIPCNamespace)
	t.Run("s5.17 Ensure devices are not shared", _TestSharedDevices)
	t.Run("s5.18, s5.28 Ensure that the default ulimit IS overwritten at runtime", _TestUlimits)
	t.Run("s5.19 Ensure mount propagation mode is not set to shared", _TestPropagationMode)
	t.Run("s5.20 Ensure that the host's UTS namespace is not shared", _TestUTSNamespace)
	t.Run("s5.21 Ensure the default seccomp profile is not disabled", _TestSeccomp)
	t.Run("s5.22 Ensure that docker exec commands are not privileged", _TestPrivilegedExec)
	t.Run("s5.23 Ensure that docker exec commands are not used with the user=root option", _TestRootExec)
	t.Run("s5.24 Ensure that cgroup usage is confirmed", _TestCgroupUsage)
	t.Run("s5.25 Ensure that the container is restricted from acquiring additional privileges", _TestNoNewPrivileges)
	t.Run("s5.29 Ensure that containers are not on the default network", _TestDockerNetworking)
	t.Run("s5.30 Ensure that the host's user namespaces are not shared", _TestHostUserNamespace)
	t.Run("s5.31 Ensure that the Docker socket is not mounted inside any containers", _TestDockerSocket)
}