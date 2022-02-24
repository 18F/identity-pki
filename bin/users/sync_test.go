package main

import (
	"testing"

	"github.com/18F/identity-devops/bin/users/mocks"
	"github.com/golang/mock/gomock"
	"github.com/xanzy/go-gitlab"

	"github.com/google/go-cmp/cmp"
)

func assertEqual(t *testing.T, testName string, got interface{}, want interface{}) {
	if !cmp.Equal(got, want) {
		t.Errorf("%v failed: %s", testName, cmp.Diff(got, want))
	}
}

func TestResolveUsers(t *testing.T) {
	mockCtrl := gomock.NewController(t)
	defer mockCtrl.Finish()
	mockClient := mocks.NewMockGitlabClientIface(mockCtrl)

	testResolveUsersData := []struct {
		Name            string
		ExistingUsers   map[string]*gitlab.User
		AuthorizedUsers *AuthorizedUsers
	}{
		{
			Name: "Add/Block/Unblock Users",
			ExistingUsers: map[string]*gitlab.User{
				"just.testing": {
					Email:    "just.testing@gsa.gov",
					ID:       1,
					Username: "just.testing",
				},
				"john.doe": {
					Email:    "john.doe@gsa.gov",
					ID:       2,
					Username: "john.doe",
				},
				"alexandra.thegreat": {
					Email:    "alexandra.thegreat@gsa.gov",
					ID:       3,
					Username: "alexandra.thegreat",
				},
				"ghost": {
					Username: "ghost",
				},
			},
			AuthorizedUsers: &AuthorizedUsers{
				Users: map[string]*AuthUser{
					"john.doe": {
						Gitlab_groups: []string{},
					},
					"alexandra.thegreat": {
						Gitlab_groups: []string{"devops"},
						Email:         "alex.dagreat@gsa.gov",
					},
					"new.engineer": {
						Gitlab_groups: []string{"appdev"},
					},
				},
			},
		},
	}

	mockClient.
		EXPECT().
		UnblockUser(3) // Alexandra
	mockClient.
		EXPECT().
		CreateUser(gomock.Any()).
		Return(&gitlab.User{
			Username: "new.engineer",
		}, nil, nil)
	mockClient.
		EXPECT().
		BlockUser(1) // Just Testing
	mockClient.
		EXPECT().
		BlockUser(2) // John Doe
	mockClient.
		EXPECT().
		ModifyUser(3, gomock.Any()) // alex.dagreat

	cache.Users = make(map[string]*gitlab.User)
	for _, td := range testResolveUsersData {
		err := resolveUsers(mockClient, td.ExistingUsers, td.AuthorizedUsers)
		if err != nil {
			t.Error(err)
		}
	}
}

var testResolveGroupsData = []struct {
	Name            string
	GitlabGroups    map[string]*gitlab.Group
	AuthorizedUsers *AuthorizedUsers
	AuthGroups      map[string]map[string]bool
	WantToCreate    map[string]bool
	WantToDelete    map[string]*gitlab.Group
}{
	{
		Name: "Create/Delete Groups",
		GitlabGroups: map[string]*gitlab.Group{
			"lg":        {},
			"vestigial": {},
		},
		AuthorizedUsers: &AuthorizedUsers{
			Users: map[string]*AuthUser{
				"user1": {
					Gitlab_groups: []string{"lg"},
				},
				"user2": {
					Gitlab_groups: []string{"new_admin_group"},
				},
			},
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
		toCreate, toDelete := resolveGroups(td.GitlabGroups, td.AuthorizedUsers)

		assertEqual(t, td.Name, toCreate, td.WantToCreate)
		assertEqual(t, td.Name, toDelete, td.WantToDelete)
	}
}

func TestResolveMembers(t *testing.T) {
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

	for _, td := range testResolveMembersData {
		toCreate, toDelete := resolveMembers(td.Memberships, td.AuthGroups)

		assertEqual(t, td.Name, toCreate, td.WantToCreate)
		assertEqual(t, td.Name, toDelete, td.WantToDelete)
	}
}

func TestGetAuthorizedGroups(t *testing.T) {
	want := map[string]map[string]bool{
		"appdev": {"mach.zargolis": true},
		"devops": {"kritty": true},
		"lg":     {"gitlab.and.group.please": true},
	}
	authUsers, err := getAuthorizedUsers("test_users.yaml")
	if err != nil {
		t.Errorf("Failed: %v", err)
	}
	authGroups := getAuthorizedGroups(authUsers)
	assertEqual(t, "Parse groups", authGroups, want)
}

func TestGitlabCache(t *testing.T) {
	mockCtrl := gomock.NewController(t)
	defer mockCtrl.Finish()

	mockClient := mocks.NewMockGitlabClientIface(mockCtrl)
	mockClient.EXPECT().ListUsers(
		&gitlab.ListUsersOptions{
			ListOptions: gitlab.ListOptions{
				PerPage: 100,
			},
		},
	)
	mockClient.
		EXPECT().
		ListGroups(
			&gitlab.ListGroupsOptions{
				ListOptions: gitlab.ListOptions{
					PerPage: 100,
				},
			}).
		Return(
			[]*gitlab.Group{
				{
					ID:   1,
					Name: "Foo",
				},
			}, nil, nil)
	mockClient.EXPECT().ListProjects(
		&gitlab.ListProjectsOptions{
			ListOptions: gitlab.ListOptions{
				PerPage: 100,
			},
		},
	)
	mockClient.EXPECT().
		ListGroupMembers(
			1,
			&gitlab.ListGroupMembersOptions{
				ListOptions: gitlab.ListOptions{
					PerPage: 100,
				},
			},
		)
	populateGitLabCache(mockClient)
}

func TestResolveProjects(t *testing.T) {
	mockCtrl := gomock.NewController(t)
	defer mockCtrl.Finish()

	mockClient := mocks.NewMockGitlabClientIface(mockCtrl)

	authorizedUsers := &AuthorizedUsers{
		Users: map[string]*AuthUser{
			"john.doe": {
				Gitlab_groups: []string{},
			},
			"alexandra.thegreat": {
				Gitlab_groups: []string{"devops"},
			},
			"new.engineer": {
				Gitlab_groups: []string{"appdev"},
			},
		},
		Groups: map[string]*AuthGroup{},
		Projects: map[string]*AuthorizedProject{
			"idp": {
				Groups: map[string]struct{ Access *gitlab.AccessLevelValue }{
					"appdev": {
						Access: gitlab.AccessLevel(40),
					},
				},
			},
		},
	}
	existingProjects := map[string]*gitlab.Project{
		"idp": {
			ID:                1,
			PathWithNamespace: "lg/idp",
			SharedWithGroups: []struct {
				GroupID          int    "json:\"group_id\""
				GroupName        string "json:\"group_name\""
				GroupAccessLevel int    "json:\"group_access_level\""
			}{
				{
					GroupID:          2,
					GroupName:        "devops",
					GroupAccessLevel: 30,
				},
				{
					GroupID:          3,
					GroupName:        "appdev",
					GroupAccessLevel: 30,
				},
			},
		},
	}
	cache = &GitlabCache{
		Groups: map[string]*gitlab.Group{
			"appdev": {
				ID: 3,
			},
		},
	}

	mockClient.
		EXPECT().
		ShareProjectWithGroup(1, &gitlab.ShareWithGroupOptions{
			GroupAccess: gitlab.AccessLevel(gitlab.AccessLevelValue(40)),
			GroupID:     &cache.Groups["appdev"].ID,
		})
	mockClient.
		EXPECT().
		DeleteSharedProjectFromGroup(1, 2)
	mockClient.
		EXPECT().
		DeleteSharedProjectFromGroup(1, 3)
	resolveProjects(mockClient, existingProjects, authorizedUsers)
}
