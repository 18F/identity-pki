package test

import (
	"os"
	"testing"

	aws_sdk "github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/service/codepipeline"
	"github.com/gruntwork-io/terratest/modules/aws"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

var aws_session, err = aws.NewAuthenticatedSession(os.Getenv("AWS_REGION"))

func TestToolingtoolingPipelineExists(t *testing.T) {
	svc := codepipeline.New(aws_session)

	input := &codepipeline.GetPipelineInput{
		Name: aws_sdk.String("auto_terraform_tooling_tooling_pipeline"),
	}
	_, err := svc.GetPipeline(input)
	require.NoError(t, err)
}

func TestToolingtoolingPipelineCanGetSource(t *testing.T) {
	svc := codepipeline.New(aws_session)

	input := &codepipeline.GetPipelineStateInput{
		Name: aws_sdk.String("auto_terraform_tooling_tooling_pipeline"),
	}
	pstate, err := svc.GetPipelineState(input)
	require.NoError(t, err)

	sourceStageStatus := []string{}
	for _, i := range pstate.StageStates {
		if *i.StageName == "Source" {
			sourceStageStatus = append(sourceStageStatus, *i.LatestExecution.Status)
		}
	}
	assert.Equal(t, len(sourceStageStatus), 1)
	assert.Equal(t, sourceStageStatus[0], "Succeeded")
}
