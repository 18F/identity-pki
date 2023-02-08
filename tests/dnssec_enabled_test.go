package test

import (
	"fmt"
	"testing"

	"github.com/gruntwork-io/terratest/modules/aws"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

var dns_test_host = "www.dnssec-failed.org"

// Ensure DNSSec validation is enabled on IDP instances
func TestDNSSecIdpInstances(t *testing.T) {
	t.Parallel()
	// Get an instance from the ASG
	instances := aws.GetInstanceIdsForAsg(t, idp_asg, region)
	require.NotEmpty(t, instances)
	firstinstance := instances[0]

	// Check to make sure dig against the dns_test_host does not return any records
	fmt.Println("Running dig +noall +answer www.dnssec-failed.org")
	cmd := "dig +noall +answer " + dns_test_host
	result := RunCommandOnInstance(t, firstinstance, cmd)

	// Std output of the command run above should return an empty string
	assert.Equal(t, "", *result.StandardOutputContent)

	// Check to make sure dig against the idp_hostname returns records
	fmt.Println("Running dig +noall +answer " + idp_hostname)
	cmd = "dig +noall +answer " + idp_hostname
	result = RunCommandOnInstance(t, firstinstance, cmd)

	// Std output of the command run above should not return an empty string
	assert.NotEqual(t, "", *result.StandardOutputContent)

	// Print returned DNS records
	fmt.Println(*result.StandardOutputContent)
}
