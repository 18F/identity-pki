package test

import (
  "fmt"
  "testing"
  "net/http"
  "strings"	
  "github.com/stretchr/testify/assert"
  "github.com/gruntwork-io/terratest/modules/terraform"
)

// Grab response from idp server to check headers
func ReturnResponse(url string) *http.Response {
  resp, err := http.Get(url)
  if err != nil {
    panic(err)
  }
  defer resp.Body.Close()

  return resp
}

// Given a map of slices, we iterate over each header and check to make sure that the response both contains the header and the appropriate values
func CheckHeaders(t *testing.T, resp *http.Response, idp_fqdn string, headers map[string][]string) {
  // Loop over each key in headers
  for i := range headers {
    // Check if the header exists in the the idp response
    assert.Contains(t, resp.Header, i)
    fmt.Printf("%s: found in response headers\n", i)
    // Check to make sure that the values for the idp response header contain the subset defined for each header
    assert.Subset(t, strings.Split(resp.Header[i][0], "; "), headers[i])
    fmt.Printf("%s: has appropriate values set\n", i)
  }
}

// Check headers and header values
func TestIdpHeaders(t *testing.T) {
  t.Parallel()
  terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
    // The path to where our Terraform code is located
    TerraformDir: "../terraform/app/",
  })
  // Load value from terraform outputs.tf inside terraform/app
  idp_fqdn :=  terraform.Output(t, terraformOptions, "idp_dns_name")
  url := fmt.Sprintf("https://%s", idp_fqdn)
  response := ReturnResponse(url)
  // Map of headers to check for in the response headers
  headers := map[string][]string {
    "Content-Security-Policy": {"frame-ancestors 'self'", "default-src 'self'", "child-src 'self'", "form-action 'self'", "block-all-mixed-content", "connect-src 'self' *.nr-data.net *.google-analytics.com us.acas.acuant.net", fmt.Sprintf("font-src 'self' data: https://%s", idp_fqdn), fmt.Sprintf("img-src 'self' data: login.gov https://%s idscangoweb.acuant.com https://s3.us-west-2.amazonaws.com", idp_fqdn), "media-src 'self'", "object-src 'none'", fmt.Sprintf("style-src 'self' https://%s 'unsafe-inline'", idp_fqdn), "base-uri 'self'"},
    "Strict-Transport-Security": {"max-age=31556952", "includeSubDomains", "preload"},
    "X-Content-Type-Options": {"nosniff"},
    "X-Frame-Options": {"DENY"},
    "X-Xss-Protection": {"1", "mode=block"},
    "Referrer-Policy": {"strict-origin-when-cross-origin"},
    "X-Permitted-Cross-Domain-Policies": {"none"},
  }
  CheckHeaders(t, response, idp_fqdn, headers)
}

// Check origin redirect without added cloudfront header
func TestBlockedOrigin(t *testing.T) {
  t.Parallel()
  terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
    // The path to where our Terraform code is located
    TerraformDir: "../terraform/app/",
  })
  // Load value from terraform outputs.tf inside terraform/app
  idp_origin_fqdn :=  terraform.Output(t, terraformOptions, "idp_origin_dns_name")
  idp_fqdn :=  terraform.Output(t, terraformOptions, "idp_dns_name")
  url := fmt.Sprintf("https://%s", idp_origin_fqdn)
  // Get response and check to make sure it redirected from origin dns name to cloudfront dns name
  response := ReturnResponse(url)
  fmt.Printf("Checking direct access to: %s\n", url)
  assert.Equal(t, 200, response.StatusCode)
  assert.Equal(t, fmt.Sprintf("%s:443", idp_fqdn), response.Request.URL.Host)
  fmt.Printf("Successfully redirected to: https://%s\n", response.Request.URL.Host)
}

/* 
Checks to make sure custom pages exist and and able to be served from cloudfront.
Didn't want to remove the instances from the ASG to test the cloudfront error
page response otherwise the test would take around 10 minutes. Same idea with the
maintenance page, as long as it exists and is reachable Cloudfront will be able
to serve it.
*/
func TestCustomErrorPages(t *testing.T) {
  t.Parallel()
  terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
    // The path to where our Terraform code is located
    TerraformDir: "../terraform/app/",
  })
  idp_custom_pages := terraform.OutputList(t, terraformOptions, "idp_custom_pages")
  for value := range idp_custom_pages {
    response := ReturnResponse(idp_custom_pages[value])
    // Page exists and is reachable in the browser, no permission issues
    assert.Equal(t, 200, response.StatusCode)
    fmt.Printf("%s returned a value of ", idp_custom_pages[value])
    fmt.Println(response.StatusCode)
    // Page is being served from S3 so it isn't dependent on the application
    assert.Contains(t, response.Header["Server"], "AmazonS3")
    fmt.Printf("%s is being served from: AmazonS3\n", idp_custom_pages[value])
    // Page is not being cached by Cloudfront
    assert.Contains(t, response.Header["X-Cache"], "Miss from cloudfront")
    fmt.Printf("%s is not being cached\n", idp_custom_pages[value])
  }
}
