package main

import (
	"fmt"
)

// Ensure users.yaml is internally consistent by ensuring referenced groups are
// also defined. Ensure root has the necessary properties and permissions.
func (au *AuthorizedUsers) Validate() error {
	// Every referenced gitlab group must be defined
	for userName, user := range au.Users {
		for _, group := range user.Gitlab_groups {
			if _, ok := au.Groups[group.Name]; !ok {
				return fmt.Errorf("%v is not defined, but %v is a member of it", group.Name, userName)
			}
		}
	}
	for projectName, project := range au.Projects {
		for groupName := range project.Groups {
			if _, ok := au.Groups[groupName]; !ok {
				return fmt.Errorf("%v is not defined, but has access to %v", groupName, projectName)
			}
		}
	}

	// There must be a root user
	rootUser, ok := au.Users["root"]
	if !ok {
		return fmt.Errorf("root user must be defined")
	}

	// Root must be a member of every group
	rootGroups := map[string]bool{}
	for _, group := range rootUser.Gitlab_groups {
		rootGroups[group.Name] = true
	}
	for groupName := range au.Groups {
		if _, ok := rootGroups[groupName]; !ok {
			return fmt.Errorf("root should be a member of all groups, but isn't a member of %v", groupName)
		}
	}

	// Root must be able to create groups
	if !rootUser.Can_create_group {
		return fmt.Errorf("root must be able to create groups")
	}

	// Gitlab Project Bots may not be members of groups
	for userName, user := range au.Users {
		if user.Gitlab_project_bot && len(user.Gitlab_groups) > 0 {
			return fmt.Errorf("project Bot %v may not be a member any groups", userName)
		}
	}
	return nil
}
