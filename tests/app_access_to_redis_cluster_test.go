package test

import (
	"fmt"
	"testing"

	aws_sdk "github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/elasticache"
	"github.com/gruntwork-io/terratest/modules/aws"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

var redis_cluster_identifier = env_name + "-idp-001"

func GetCluster(t *testing.T, cluster_name string) *elasticache.DescribeCacheClustersOutput {
	cluster := elasticache.New(session.New())
	input := &elasticache.DescribeCacheClustersInput{
		CacheClusterId:    aws_sdk.String(cluster_name),
		ShowCacheNodeInfo: aws_sdk.Bool(true),
	}

	result, err := cluster.DescribeCacheClusters(input)
	require.NoError(t, err)

	return result
}

// Ensure IDP instance can still access the Redis cluster endpoint
func TestRedisAccessIdpInstances(t *testing.T) {
	// Can t.Parallel() this since it isn't writing to Redis
	t.Parallel()
	// Get an instance from the ASG
	instances := aws.GetInstanceIdsForAsg(t, idp_asg, region)
	require.NotEmpty(t, instances)
	firstinstance := instances[0]

	// Get cluster endpoint
	response := GetCluster(t, redis_cluster_identifier)
	endpoint := (*response.CacheClusters[0].CacheNodes[0].Endpoint.Address)

	// Attempt to establish connection
	fmt.Println("Attempting to connect to Redis endpoint " + endpoint + " from IDP instance")
	cmd := "timeout --preserve-status 5 nc -v -z " + endpoint + " 6379"
	result := RunCommandOnInstance(t, firstinstance, cmd)

	// Command should return success code
	fmt.Println(*result.StandardErrorContent)
	assert.Equal(t, "Success", *result.Status)
}

// Ensure app instance cannot access the Redis cluster endpoint
func TestRedisAccessAppInstances(t *testing.T) {
	// Can t.Parallel() this since it isn't writing to Redis
	t.Parallel()
	// Get an instance from the ASG
	instances := aws.GetInstanceIdsForAsg(t, app_asg, region)
	require.NotEmpty(t, instances)
	firstinstance := instances[0]

	// Get cluster endpoint
	response := GetCluster(t, redis_cluster_identifier)
	endpoint := (*response.CacheClusters[0].CacheNodes[0].Endpoint.Address)

	// Attempt to establish connection. Netcat will hang indefinitely, so a 5s timeout is implemented to kill the nc command if a connection isn't established within that timeframe
	fmt.Println("Attempting to connect to Redis endpoint " + endpoint + " from App instance")
	cmd := "timeout --preserve-status 5 nc -v -z " + endpoint + " 6379"
	result := RunCommandOnInstance(t, firstinstance, cmd)

	// Command should fail and return failure status
	fmt.Println("Unable to establish connection between app instance and Redis endpoint")
	assert.Equal(t, "Failed", *result.Status)
}
