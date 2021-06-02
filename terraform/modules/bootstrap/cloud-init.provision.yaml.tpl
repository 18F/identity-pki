# cloud-config

# This file is a terraform template.

# This is boilerplate cloud init config to run provision.sh with the specified
# arguments.  provision.sh handles cloning a git repository and running
# chef-client on it locally.
runcmd:
- /var/lib/cloud/instance/scripts/provision.sh ${kitchen_subdir} ${berksfile_toplevel} --asg-name "${asg_name}" --lifecycle-hook-name "${lifecycle_hook_name}" --git-ref "${git_ref}" "${s3_ssh_key_url}" "${git_clone_url}"
- touch "/run/${provision_phase_name}"
- "${run_remove_advantage}"
- "${run_aide}"

# merge multipart cloud-init files in a sane way
merge_type: 'list(append)+dict(recurse_array)+str()'
