package main

import (
	"testing"

	"github.com/xanzy/go-gitlab"

	"github.com/google/go-cmp/cmp"
)

var testResolveUsersData = []struct {
	Name            string
	ExistingUsers   map[string]*gitlab.User
	AuthorizedUsers *AuthorizedUsers
	WantToBlock     map[string]*gitlab.User
	WantToUnblock   map[string]*gitlab.User
	WantToCreate    map[string]bool
}{
	{
		Name: "Add/Block/Unblock Users",
		ExistingUsers: map[string]*gitlab.User{
			"just.testing": {
				Email: "just.testing@gsa.gov",
			},
			"john.doe": {
				Email: "john.doe@gsa.gov",
			},
			"alexandra.thegreat": {
				Email: "alexandra.thegreat@gsa.gov",
			},
			"root": {
				Email: "admin@example.com",
			},
		},
		AuthorizedUsers: &AuthorizedUsers{
			Users: map[string]*AuthUser{
				"john.doe": {
					Aws_groups: []string{"notadev", "atall"},
				},
				"alexandra.thegreat": {
					Aws_groups: []string{"luthier", "devops"},
				},
				"new.engineer": {
					Aws_groups: []string{"appdev"},
				},
			},
		},
		WantToBlock: map[string]*gitlab.User{
			"just.testing": {
				Email: "just.testing@gsa.gov",
			},
			"john.doe": {
				Email: "john.doe@gsa.gov",
			},
		},
		WantToUnblock: map[string]*gitlab.User{
			"alexandra.thegreat": {
				Email: "alexandra.thegreat@gsa.gov",
			},
		},
		WantToCreate: map[string]bool{
			"new.engineer": true,
		},
	},
}

func TestResolveUsers(t *testing.T) {
	for _, td := range testResolveUsersData {
		toBlock, toUnblock, toCreate := resolveUsers(td.ExistingUsers, td.AuthorizedUsers)

		assertEqual(t, td.Name, toBlock, td.WantToBlock)
		assertEqual(t, td.Name, toUnblock, td.WantToUnblock)
		assertEqual(t, td.Name, toCreate, td.WantToCreate)
	}
}

var testResolveGroupsData = []struct {
	Name         string
	GitlabGroups map[string]*gitlab.Group
	AuthGroups   map[string]map[string]bool
	WantToCreate map[string]bool
	WantToDelete map[string]*gitlab.Group
}{
	{
		Name: "Create/Delete Groups",
		GitlabGroups: map[string]*gitlab.Group{
			"lg":        {},
			"vestigial": {},
		},
		AuthGroups: map[string]map[string]bool{
			"lg": {
				"user1": true,
			},
			"new_admin_group": {
				"user2": true,
			},
		},
		WantToCreate: map[string]bool{
			"new_admin_group": true,
		},
		WantToDelete: map[string]*gitlab.Group{
			"vestigial": {},
		},
	},
}

func TestResolveGroups(t *testing.T) {
	for _, td := range testResolveGroupsData {
		toCreate, toDelete := resolveGroups(td.GitlabGroups, td.AuthGroups)

		assertEqual(t, td.Name, toCreate, td.WantToCreate)
		assertEqual(t, td.Name, toDelete, td.WantToDelete)
	}
}

var testResolveMembersData = []struct {
	Name         string
	Memberships  map[string]map[string]bool
	AuthGroups   map[string]map[string]bool
	WantToCreate map[string]map[string]bool
	WantToDelete map[string]map[string]bool
}{
	{
		Name: "Create/Delete Members",
		Memberships: map[string]map[string]bool{
			"lg": {
				"lg_dev": true,
				"ex_dev": true,
				"root":   true,
			},
		},
		AuthGroups: map[string]map[string]bool{
			"lg": {
				"lg_dev":  true,
				"new_dev": true,
			},
		},
		WantToCreate: map[string]map[string]bool{
			"lg": {
				"new_dev": true,
			},
		},
		WantToDelete: map[string]map[string]bool{
			"lg": {
				"ex_dev": true,
			},
		},
	},
}

func TestResolveMembers(t *testing.T) {
	for _, td := range testResolveMembersData {
		toCreate, toDelete := resolveMembers(td.Memberships, td.AuthGroups)

		assertEqual(t, td.Name, toCreate, td.WantToCreate)
		assertEqual(t, td.Name, toDelete, td.WantToDelete)
	}
}

func TestGetAuthorizedGroups(t *testing.T) {
	want := map[string]map[string]bool{
		"lg": {
			"gitlab.and.group.please": true,
		},
	}
	authUsers, err := getAuthorizedUsers("test_users.yaml")
	if err != nil {
		t.Errorf("Failed: %v", err)
	}
	authGroups := getAuthorizedGroups(authUsers)
	assertEqual(t, "Parse groups", authGroups, want)
}

func assertEqual(t *testing.T, testName string, got interface{}, want interface{}) {
	if !cmp.Equal(got, want) {
		t.Errorf("%v failed: %s", testName, cmp.Diff(got, want))
	}
}
