package test

import (
	"os"
	"testing"
	"time"

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

func FindStatusForPipeline(t *testing.T, pipeline string, stage string) string {
	svc := codepipeline.New(aws_session)

	input := &codepipeline.GetPipelineStateInput{
		Name: aws_sdk.String(pipeline),
	}
	sourceStageStatus := []string{}

	// If the pipeline is running that stage, loop until we get a real answer
	for {
		pstate, err := svc.GetPipelineState(input)
		require.NoError(t, err)

		sourceStageStatus = []string{}
		for _, i := range pstate.StageStates {
			if *i.StageName == stage {
				sourceStageStatus = append(sourceStageStatus, *i.LatestExecution.Status)
			}
		}
		assert.Equal(t, len(sourceStageStatus), 1)

		if sourceStageStatus[0] == "InProgress" {
			time.Sleep(2)
		} else {
			break
		}
	}

	return (sourceStageStatus[0])
}

func TestToolingtoolingPipelineCanGetSource(t *testing.T) {
	status := FindStatusForPipeline(t, "auto_terraform_tooling_tooling_pipeline", "Source")
	assert.Equal(t, "Succeeded", status)
}

func TestToolingtoolingPipelineCanPlan(t *testing.T) {
	status := FindStatusForPipeline(t, "auto_terraform_tooling_tooling_pipeline", "Plan")
	assert.Equal(t, "Succeeded", status)
}
