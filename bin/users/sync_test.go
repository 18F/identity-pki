package main

import (
	"testing"

	"github.com/google/go-cmp/cmp"
)

var testData = []struct {
	Name              string
	ExistingUsers     map[string]*UserState
	AuthorizedUsers   *AuthorizedUsers
	WantExistingUsers map[string]*UserState
	WantNewUsers      map[string]string
}{
	{
		Name: "Block Nonexistent User",
		ExistingUsers: map[string]*UserState{
			"just.testing@gsa.gov": {
				Enable: false,
			},
		},
		AuthorizedUsers: &AuthorizedUsers{},
		WantExistingUsers: map[string]*UserState{
			"just.testing@gsa.gov": {
				Enable: false,
			},
		},
		WantNewUsers: map[string]string{},
	},
	{
		Name: "Block Unauthorized User",
		ExistingUsers: map[string]*UserState{
			"john.doe@gsa.gov": {
				Enable: false,
			},
		},
		AuthorizedUsers: &AuthorizedUsers{
			Users: map[string][]string{
				"john.doe": []string{"notadev", "atall"},
			},
		},
		WantExistingUsers: map[string]*UserState{
			"john.doe@gsa.gov": {
				Enable: false,
			},
		},
		WantNewUsers: map[string]string{},
	},
	{
		Name: "Add User",
		ExistingUsers: map[string]*UserState{
			"just.testing@gsa.gov": {
				Enable: false,
			},
			"john.doe@gsa.gov": {
				Enable: false,
			},
			"alexandra.thegreat@gsa.gov": {
				Enable: false,
			},
		},
		AuthorizedUsers: &AuthorizedUsers{
			Users: map[string][]string{
				"john.doe":           []string{"notadev", "atall"},
				"alexandra.thegreat": []string{"luthier", "devops"},
				"new.engineer":       []string{"appdev"},
			},
		},
		WantExistingUsers: map[string]*UserState{
			"just.testing@gsa.gov": {
				Enable: false,
			},
			"john.doe@gsa.gov": {
				Enable: false,
			},
			"alexandra.thegreat@gsa.gov": {
				Enable: true,
			},
		},
		WantNewUsers: map[string]string{
			"new.engineer@gsa.gov": "new.engineer",
		},
	},
}

func TestMarkUsers(t *testing.T) {
	for _, td := range testData {
		existingUsers := td.ExistingUsers
		authorizedUsers := td.AuthorizedUsers
		newUsers := map[string]string{}
		markUsers(existingUsers, newUsers, authorizedUsers)

		if !cmp.Equal(existingUsers, td.WantExistingUsers) {
			t.Errorf("%v failed: %s", td.Name, cmp.Diff(existingUsers, td.WantExistingUsers))
		}
		if !cmp.Equal(newUsers, td.WantNewUsers) {
			t.Errorf("%v failed: %s", td.Name, cmp.Diff(newUsers, td.WantNewUsers))
		}
	}
}
