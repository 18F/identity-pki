package terraform

import (
	"github.com/gruntwork-io/terratest/modules/testing"
	"github.com/stretchr/testify/require"
)

// Show calls terraform show in json mode with the given options and returns stdout from the command. If
// PlanFilePath is set on the options, this will show the plan file. Otherwise, this will show the current state of the
// terraform module at options.TerraformDir. This will fail the test if there is an error in the command.
func Show(t testing.TestingT, options *Options) string {
	out, err := ShowE(t, options)
	require.NoError(t, err)
	return out
}

// ShowE calls terraform show in json mode with the given options and returns stdout from the command. If
// PlanFilePath is set on the options, this will show the plan file. Otherwise, this will show the current state of the
// terraform module at options.TerraformDir.
func ShowE(t testing.TestingT, options *Options) (string, error) {
	// We manually construct the args here instead of using `FormatArgs`, because show only accepts a limited set of
	// args.
	args := []string{"show", "-no-color", "-json"}

	// Attach plan file path if specified.
	if options.PlanFilePath != "" {
		args = append(args, options.PlanFilePath)
	}
	return RunTerraformCommandAndGetStdoutE(t, options, args...)
}
