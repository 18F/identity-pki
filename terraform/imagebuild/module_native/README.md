### Building New Pipelines

 - Add the main_native module 

### Importing Existing Pipelines

 - Destroy or disable Cloudformation Stacks and retain existing resources -> https://aws.amazon.com/premiumsupport/knowledge-center/delete-cf-stack-retain-resources/
 - Replace the main module with a main_native module at the top level 
 - Override terraform resource names with existing resource names using the input variables such as var.base_pipeline_name
 - Import existing imagebuild resources
 - Obtain an unassociated EIP from the available pool
 - Import that EIP into module.main_native.aws_eip.main
 - Set the IP address of the EIP in the top-level variables.tf as var.image_build_nat_eip
 - Do a full Terraform run
