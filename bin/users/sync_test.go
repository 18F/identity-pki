package main

import (
	"testing"

	"github.com/18F/identity-devops/bin/users/mocks"
	"github.com/xanzy/go-gitlab"
	"go.uber.org/mock/gomock"

	"github.com/google/go-cmp/cmp"
)

func assertEqual(t *testing.T, testName string, got interface{}, want interface{}) {
	if !cmp.Equal(got, want) {
		t.Errorf("%v failed: %s", testName, cmp.Diff(got, want))
	}
}

// Ensure we build missing emails from the GSA username, not the Gitlab username
func TestGuessEmail(t *testing.T) {
	authUsers, err := getAuthorizedUsers("test_users.yaml")
	if err != nil {
		t.Errorf("Failed: %v", err)
	}
	for _, testData := range []struct {
		Got  string
		Want string
	}{
		{
			Got:  authUsers.Users["krit.alexikos"].Email,
			Want: "krit.alexikos@gsa.gov",
		},
		{
			Got:  authUsers.Users["krit.alexikos"].Git_username,
			Want: "kritty",
		},
	} {
		assertEqual(t, "Process user YAML", testData.Got, testData.Want)
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
					State:    "blocked",
				},
				"alexander.theok": {
					Email:    "alexander.theok@gsa.gov",
					ID:       4,
					Username: "alexander.theok",
					State:    "deactivated",
				},
				"ghost": {
					Username: "ghost",
				},
				// project_xxx_bot users are autocreated by
				// project access tokens and should be ignored
				// by the user sync script
				"project_210_bot_03ed703ab828f27259bc2b5cbcb1b465": {
					Username: "project_210_bot_03ed703ab828f27259bc2b5cbcb1b465",
				},
			},
			AuthorizedUsers: &AuthorizedUsers{
				Users: map[string]*AuthUser{
					"john.doe": {
						Gitlab_groups: []GitlabGroup{},
					},
					"alexandra.thegreat": {
						Gitlab_groups: []GitlabGroup{
							{
								Name: "devops",
							},
							{
								Name: "appdev|owner",
							},
						},
						Email: "alex.dagreat@gsa.gov",
					},
					"alexander.theok": {
						Gitlab_groups: []GitlabGroup{
							{
								Name: "devops",
							},
						},
						Email: "alexander.theok@gsa.gov",
					},
					"new.engineer": {
						Gitlab_groups: []GitlabGroup{
							{
								Name: "appdev",
							},
						},
					},
					// Not a member of any groups
					"robbie.robot": {
						Gitlab_project_bot: true,
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
			ID:       5,
		}, nil, nil)
	mockClient.
		EXPECT().
		DeactivateUser(5) // deactivate new.engineer
	mockClient.
		EXPECT().
		CreateUser(gomock.Any()).
		Return(&gitlab.User{
			Username: "robbie.robot",
			ID:       6,
		}, nil, nil)
	mockClient.
		EXPECT().
		DeactivateUser(6) // deactivate robbie.robot

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
	AuthGroups      map[string]map[string]*gitlab.AccessLevelValue
	WantToCreate    map[string]bool
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
					Gitlab_groups: []GitlabGroup{
						{
							Name: "lg",
						},
					},
				},
				"user2": {
					Gitlab_groups: []GitlabGroup{
						{
							Name: "new_admin_group",
						},
					},
				},
			},
		},

		AuthGroups: map[string]map[string]*gitlab.AccessLevelValue{
			"lg": {
				"user1": gitlab.AccessLevel(gitlab.DeveloperPermissions),
			},
			"new_admin_group": {
				"user2": gitlab.AccessLevel(gitlab.DeveloperPermissions),
			},
		},
		WantToCreate: map[string]bool{
			"new_admin_group": true,
		},
	},
}

func TestResolveGroups(t *testing.T) {
	for _, td := range testResolveGroupsData {
		toCreate := resolveGroups(td.GitlabGroups, td.AuthorizedUsers)

		assertEqual(t, td.Name, toCreate, td.WantToCreate)
	}
}

func TestResolveMembers(t *testing.T) {
	var testResolveMembersData = []struct {
		Name         string
		Memberships  map[string]map[string]*gitlab.AccessLevelValue
		AuthGroups   map[string]map[string]*gitlab.AccessLevelValue
		WantToCreate map[string]map[string]*gitlab.AccessLevelValue
		WantToDelete map[string]map[string]bool
		WantToChange map[string]map[string]*gitlab.AccessLevelValue
	}{
		{
			Name: "Create/Delete Members",
			Memberships: map[string]map[string]*gitlab.AccessLevelValue{
				"lg": {
					"lg_dev": gitlab.AccessLevel(gitlab.DeveloperPermissions),
					"ex_dev": gitlab.AccessLevel(gitlab.DeveloperPermissions),
				},
			},
			AuthGroups: map[string]map[string]*gitlab.AccessLevelValue{
				"lg": {
					"lg_dev":  gitlab.AccessLevel(gitlab.DeveloperPermissions),
					"new_dev": gitlab.AccessLevel(gitlab.DeveloperPermissions),
				},
			},
			WantToCreate: map[string]map[string]*gitlab.AccessLevelValue{
				"lg": {
					"new_dev": gitlab.AccessLevel(gitlab.DeveloperPermissions),
				},
			},
			WantToDelete: map[string]map[string]bool{
				"lg": {
					"ex_dev": true,
				},
			},
			WantToChange: map[string]map[string]*gitlab.AccessLevelValue{
				// XXX should manufacture some stuff that needs changing here
				"lg": {},
			},
		},
	}

	for _, td := range testResolveMembersData {
		toCreate, toDelete, toChange := resolveMembers(td.Memberships, td.AuthGroups)

		assertEqual(t, td.Name, toCreate, td.WantToCreate)
		assertEqual(t, td.Name, toDelete, td.WantToDelete)
		assertEqual(t, td.Name, toChange, td.WantToChange)
	}
}

func TestGetAuthorizedGroups(t *testing.T) {
	want := map[string]map[string]*gitlab.AccessLevelValue{
		"appdev": {
			"mach.zargolis": defaultAccessLevel,
			"root":          defaultAccessLevel,
			"kritty":        gitlab.AccessLevel(gitlab.MaintainerPermissions),
		},
		"bots": {"root": defaultAccessLevel},
		"devops": {
			"kritty": defaultAccessLevel,
			"root":   defaultAccessLevel,
		},
		"lg": {
			"gitlab.and.group.please": defaultAccessLevel,
			"root":                    defaultAccessLevel,
		},
		"pm": {
			"root": defaultAccessLevel,
		},
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
	// Test pagination. It's OK if a page has 0 entries.
	mockClient.EXPECT().ListUsers(
		&gitlab.ListUsersOptions{
			ListOptions: gitlab.ListOptions{
				PerPage: 100,
			},
			ExcludeInternal: gitlab.Bool(true),
		}).
		Return(
			[]*gitlab.User{},
			&gitlab.Response{
				NextPage: 2,
			},
			nil,
		)
	mockClient.EXPECT().ListUsers(
		&gitlab.ListUsersOptions{
			ListOptions: gitlab.ListOptions{
				PerPage: 100,
				Page:    2,
			},
			ExcludeInternal: gitlab.Bool(true),
		}).
		Return(
			[]*gitlab.User{},
			&gitlab.Response{
				NextPage: 0,
			},
			nil,
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
	).
	Return(
		[]*gitlab.Project{},
		&gitlab.Response{
			NextPage: 0,
		},
		nil,
	)
	// Test pagination. Empty pages are OK.
	mockClient.EXPECT().
		ListGroupMembers(
			1,
			&gitlab.ListGroupMembersOptions{
				ListOptions: gitlab.ListOptions{
					PerPage: 100,
				},
			},
		).
		Return(
			[]*gitlab.GroupMember{},
			&gitlab.Response{
				NextPage: 0,
			},
			nil,
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
				Gitlab_groups: []GitlabGroup{},
			},
			"alexandra.thegreat": {
				Gitlab_groups: []GitlabGroup{
					{
						Name: "devops",
					},
				},
			},
			"new.engineer": {
				Gitlab_groups: []GitlabGroup{
					{
						Name: "appdev",
					},
				},
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
				GroupFullPath    string "json:\"group_full_path\""
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

func TestValidate(t *testing.T) {
	tests := map[string]struct {
		input    string
		want_err bool
	}{
		"valid":                   {input: "test_users.yaml", want_err: false},
		"bad project member":      {input: "test_users_bad_project_membership.yaml", want_err: true},
		"missing group":           {input: "test_users_missing_group.yaml", want_err: true},
		"can't create group":      {input: "test_users_no_root_group_permission.yaml", want_err: true},
		"missing root membership": {input: "test_users_no_root_membership.yaml", want_err: true},
		"no root member":          {input: "test_users_no_root.yaml", want_err: true},
		"bot group member":        {input: "test_users_bot_member.yaml", want_err: true},
		"bad AccessLevel":         {input: "test_users_bad_accesslevel.yaml", want_err: true},
		"missing AccessLevel":     {input: "test_users_no_accesslevel.yaml", want_err: true},
	}

	for name, td := range tests {
		t.Run(name, func(t *testing.T) {
			au, err := getAuthorizedUsers(td.input)
			if err != nil && !td.want_err {
				t.Errorf("error loading %v: %v", td.input, err)
			}
			if err == nil {
				err = au.Validate()
				if err != nil && !td.want_err {
					t.Errorf("error validating %s: %s", td.input, err)
				}
				if err == nil && td.want_err {
					t.Errorf("expected an error when validating %s", td.input)
				}
			}
		})
	}
}
