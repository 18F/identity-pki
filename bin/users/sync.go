package main

import (
	"flag"
	"fmt"
	"io/ioutil"
	"log"
	"os"
	"strings"

	"github.com/xanzy/go-gitlab"
	"gopkg.in/yaml.v2"
)

const gitlabTokenEnvVar = "GITLAB_API_TOKEN"

// Flags
var fqdn string
var dryrun bool
var userYaml string
var apiToken string // env var
var check bool

var allowedRoles = map[string]bool{
	"devops":        true,
	"appdev":        true,
	"devopsnonprod": true,
}

var ignoredUsers = []string{
	"support",
	"alert",
	"root",
	"admin@example.com", // Default email for root
}

type AuthUser struct {
	Aws_groups    []string
	Gitlab_groups []string
}

type AuthorizedUsers struct {
	Users map[string]*AuthUser
}

// A mapping of user and group names to IDs, because our configs work with
// usernames, but GitLab often wants the ID. Populate as we find more mappings.
var idCache = map[string]int{}

func init() {
	flag.StringVar(&fqdn, "fqdn", "", "Required. Fully qualified domain name for the GitLab instance.")
	flag.StringVar(&userYaml, "file", "../../terraform/master/global/users.yaml", "Input YAML.")
	flag.BoolVar(&dryrun, "dryrun", false, "Whether to run in dryrun mode. Defaults to false.")
	flag.BoolVar(&check, "check", false, "Only check whether a change would be made, and error if so.")
	flag.Usage = func() {
		fmt.Fprintf(flag.CommandLine.Output(), "sync.go: Syncs GitLab users with a YAML source of truth. Requires GITLAB_API_TOKEN to be set in the environment. Usage:\n")
		flag.PrintDefaults()
		os.Exit(1)
	}
}

func main() {
	// Check if we have flags and env vars set
	flag.Parse()
	if fqdn == "" {
		flag.Usage()
	}
	apiToken = os.Getenv(gitlabTokenEnvVar)
	if apiToken == "" {
		flag.Usage()
	}

	// Set up GitLab connection
	gitc, err := gitlab.NewClient(
		apiToken,
		gitlab.WithBaseURL(fmt.Sprintf("https://%s", fqdn)),
	)
	if err != nil {
		log.Fatalf("Failed to create client: %v", err)
	}

	//
	// Sync Users
	//

	// Get existing GitLab users
	existingUsers, err := getExistingUsers(gitc)
	if err != nil {
		log.Fatalf("Failed to list users: %v", err)
	}

	authorizedUsers, err := getAuthorizedUsers(userYaml)
	if err != nil {
		log.Fatalf("Error reading user YAML: %s", err)
	}

	usersToBlock, usersToUnblock, usersToCreate := resolveUsers(existingUsers, authorizedUsers)
	err = blockUsers(gitc, usersToBlock)
	if err != nil {
		log.Fatalf("Unable to block users: %v", err)
	}
	err = unblockUsers(gitc, usersToUnblock)
	if err != nil {
		log.Fatalf("Unable to unblock users: %v", err)
	}
	err = createUsers(gitc, usersToCreate)
	if err != nil {
		log.Fatalf("Unable to create users: %v", err)
	}

	//
	// Sync Groups
	//

	// Get existing groups
	gitlabGroups, err := getExistingGroups(gitc)
	if err != nil {
		log.Fatalf("Could not get GitLab groups: %v", err)
	}
	log.Printf("Found groups: %v", gitlabGroups)

	authGroups := getAuthorizedGroups(authorizedUsers)
	log.Printf("Authorized groups: %v", authGroups)

	groupsToCreate, groupsToDelete := resolveGroups(gitlabGroups, authGroups)
	err = createGroups(gitc, groupsToCreate)
	if err != nil {
		log.Fatalf("Unable to create groups: %v", err)
	}
	err = deleteGroups(gitc, groupsToDelete)
	if err != nil {
		log.Fatalf("Unable to delete groups: %v", err)
	}

	//
	// Sync Members
	//

	groupsWithMembers, err := getExistingMembers(gitc)
	if err != nil {
		log.Fatalf("Failed to list memberships: %v", err)
	}
	authGroups = getAuthorizedGroups(authorizedUsers)
	membersToCreate, membersToDelete := resolveMembers(groupsWithMembers, authGroups)
	err = createMemberships(gitc, membersToCreate)
	if err != nil {
		log.Fatalf("Failed to create members: %v", err)
	}
	err = deleteMemberships(gitc, membersToDelete)
	if err != nil {
		log.Fatalf("Failed to delete members: %v", err)
	}
}

func getAuthorizedGroups(authUsers *AuthorizedUsers) map[string]map[string]bool {
	groups := map[string]map[string]bool{}
	for username, au := range authUsers.Users {
		for _, g := range au.Gitlab_groups {
			if _, ok := groups[g]; !ok {
				groups[g] = make(map[string]bool)
			}
			groups[g][username] = true
		}
	}

	return groups
}

func getExistingGroups(gitc *gitlab.Client) (map[string]*gitlab.Group, error) {
	groups, _, err := gitc.Groups.ListGroups(
		&gitlab.ListGroupsOptions{
			ListOptions: gitlab.ListOptions{
				PerPage: 100,
			},
		},
	)
	if err != nil {
		return nil, err
	}

	groupMap := make(map[string]*gitlab.Group)
	for _, g := range groups {
		groupMap[g.Name] = g
		idCache[fmt.Sprintf("group:%v", g.Name)] = g.ID
	}

	return groupMap, nil
}

func getExistingMembers(gitc *gitlab.Client) (map[string]map[string]bool, error) {
	memberships := map[string]map[string]bool{}

	gitlabGroups, err := getExistingGroups(gitc)
	if err != nil {
		return nil, err
	}
	log.Printf("Found groups: %v", gitlabGroups)

	for gname, g := range gitlabGroups {
		members, _, err := gitc.Groups.ListGroupMembers(
			g.ID,
			&gitlab.ListGroupMembersOptions{
				ListOptions: gitlab.ListOptions{
					PerPage: 100,
				},
			},
		)
		if err != nil {
			return nil, err
		}
		memberships[gname] = make(map[string]bool)
		for _, m := range members {
			memberships[gname][m.Username] = true
		}
	}
	return memberships, nil
}

func getAuthorizedUsers(f string) (*AuthorizedUsers, error) {
	// Get Users from YAML
	var authorizedUsers AuthorizedUsers
	userFile, err := ioutil.ReadFile(f)
	if err != nil {
		return nil, err
	}
	err = yaml.UnmarshalStrict(userFile, &authorizedUsers)
	if err != nil {
		return nil, err
	}
	return &authorizedUsers, nil
}

func getExistingUsers(gitc *gitlab.Client) (map[string]*gitlab.User, error) {
	gitUsers, _, err := gitc.Users.ListUsers(
		&gitlab.ListUsersOptions{
			ListOptions: gitlab.ListOptions{
				PerPage: 100,
			},
		},
	)
	if err != nil {
		return nil, err
	}

	existingUsers := make(map[string]*gitlab.User)
	for _, u := range gitUsers {
		existingUsers[u.Username] = u
		log.Printf("Found existing GitLab user: %v (%v)", u.Email, u.State)
		idCache[fmt.Sprintf("user:%v", u.Username)] = u.ID
	}

	return existingUsers, nil
}

// Given sets of existing and authorized users, returns sets of users to block, unblock and create
func resolveUsers(
	existingUsers map[string]*gitlab.User,
	authorizedUsers *AuthorizedUsers,
) (map[string]*gitlab.User, map[string]*gitlab.User, map[string]bool) {

	usersToBlock := map[string]*gitlab.User{}
	usersToUnblock := map[string]*gitlab.User{}
	usersToCreate := map[string]bool{}

	// Copy and clean existingUsers so we don't mangle it unexpectedly
	ignoreMap := make(map[string]bool)
	for _, v := range ignoredUsers {
		if strings.Contains(v, "@") {
			ignoreMap[v] = true
		} else {
			ignoreMap[fmt.Sprintf("%v@%v", v, fqdn)] = true
		}
	}
	for username, user := range existingUsers {
		if _, ok := ignoreMap[user.Email]; !ok {
			usersToBlock[username] = user
		}
	}

	// For each user in YAML,  mark to keep it
	for username, userAttrs := range authorizedUsers.Users {
		for _, role := range userAttrs.Aws_groups {
			if _, ok := allowedRoles[role]; !ok {
				// skip to the next role
				continue
			}
			if u, ok := existingUsers[username]; ok {
				usersToUnblock[username] = u
				delete(usersToBlock, username)
			} else {
				usersToCreate[username] = true
			}
		}
	}

	return usersToBlock, usersToUnblock, usersToCreate
}

// Returns sets of groups to create and delete
func resolveGroups(
	gitlabGroups map[string]*gitlab.Group,
	authGroups map[string]map[string]bool,
) (map[string]bool, map[string]*gitlab.Group) {

	groupsToCreate := map[string]bool{}
	groupsToDelete := map[string]*gitlab.Group{}

	// Copy input so we don't confuse callers
	for k, v := range gitlabGroups {
		groupsToDelete[k] = v
	}

	for ag := range authGroups {
		if _, ok := gitlabGroups[ag]; ok {
			delete(groupsToDelete, ag)
			continue
		}
		groupsToCreate[ag] = true
	}

	return groupsToCreate, groupsToDelete
}

func resolveMembers(
	memberships map[string]map[string]bool,
	authGroups map[string]map[string]bool,
) (map[string]map[string]bool, map[string]map[string]bool) {

	membersToCreate := map[string]map[string]bool{}

	for gname, members := range memberships {
		membersToCreate[gname] = make(map[string]bool)

		// Ignore machine users
		for _, username := range ignoredUsers {
			delete(members, username)
		}
		for username := range authGroups[gname] {
			// Remove authorized members from maybeDelete
			if _, ok := members[username]; ok {
				delete(members, username)
				continue
			}
			// Create new memberships if required
			membersToCreate[gname][username] = true
		}
	}
	return membersToCreate, memberships
}

func blockUsers(gitc *gitlab.Client, usersToBlock map[string]*gitlab.User) error {
	for username, user := range usersToBlock {
		if user.State == "blocked" {
			continue
		}
		if check {
			log.Fatalf("User %v should be blocked, but isn't.", username)
		}

		log.Printf("Blocking %v (ID %v)", user.Email, user.ID)
		if dryrun {
			continue
		}

		err := gitc.Users.BlockUser(user.ID)
		if err != nil {
			return err
		}
	}
	return nil
}

func unblockUsers(gitc *gitlab.Client, usersToUnblock map[string]*gitlab.User) error {
	for username, user := range usersToUnblock {
		if user.State == "active" {
			continue
		}
		if check {
			log.Fatalf("User %v should be unblocked, but isn't.", username)
		}

		log.Printf("Unblocking %v (ID %v)", user.Email, user.ID)
		if dryrun {
			continue
		}

		err := gitc.Users.UnblockUser(user.ID)
		if err != nil {
			return err
		}
	}
	return nil
}

func createUsers(gitc *gitlab.Client, usersToCreate map[string]bool) error {
	for username := range usersToCreate {
		if check {
			log.Fatalf("User %v should exist, but doesn't.", username)
		}

		log.Printf("Creating %v", username)
		if dryrun {
			return nil
		}
		options := &gitlab.CreateUserOptions{
			Email:               gitlab.String(fmt.Sprintf("%v@gsa.gov", username)),
			ForceRandomPassword: gitlab.Bool(true),
			Username:            gitlab.String(username),
			Name:                gitlab.String(username),
			SkipConfirmation:    gitlab.Bool(true),
			CanCreateGroup:      gitlab.Bool(false),
		}

		newUser, _, err := gitc.Users.CreateUser(options)
		if err != nil {
			return err
		}
		idCache[fmt.Sprintf("user:%v", newUser.Username)] = newUser.ID
	}
	return nil
}

func createGroups(gitc *gitlab.Client, groupsToCreate map[string]bool) error {
	for gname := range groupsToCreate {
		if check {
			log.Fatalf("Group %v should exist, but doesn't.", gname)
		}
		log.Printf("Creating %v", gname)
		if dryrun {
			return nil
		}
		options := &gitlab.CreateGroupOptions{
			Name: gitlab.String(gname),
			Path: gitlab.String(gname),
		}
		_, _, err := gitc.Groups.CreateGroup(options)
		if err != nil {
			return err
		}
	}
	return nil
}

func deleteGroups(gitc *gitlab.Client, groupsToDelete map[string]*gitlab.Group) error {
	for gname, group := range groupsToDelete {
		if check {
			log.Fatalf("Group %v shouldn't exist, but does.", gname)
		}
		log.Printf("Deleting group %v", gname)
		if dryrun {
			continue
		}
		_, err := gitc.Groups.DeleteGroup(group.ID)
		if err != nil {
			return err
		}
	}
	return nil
}

func createMemberships(gitc *gitlab.Client, membersToCreate map[string]map[string]bool) error {
	for groupName, members := range membersToCreate {
		for memberName := range members {
			if check {
				log.Fatalf("Member %v should exist in %v, but doesn't.", memberName, groupName)
			}
			log.Printf("Adding %v to %v", memberName, groupName)
			if dryrun {
				continue
			}
			groupID := idCache[fmt.Sprintf("group:%v", groupName)]
			memberOpts := &gitlab.AddGroupMemberOptions{
				UserID:      gitlab.Int(idCache[fmt.Sprintf("user:%v", memberName)]),
				AccessLevel: gitlab.AccessLevel(gitlab.DeveloperPermissions),
			}
			_, _, err := gitc.GroupMembers.AddGroupMember(groupID, memberOpts)
			if err != nil {
				return err
			}
		}
	}
	return nil
}

func deleteMemberships(gitc *gitlab.Client, membersToDelete map[string]map[string]bool) error {
	for groupName, members := range membersToDelete {
		for memberName := range members {
			if check {
				log.Fatalf("Member %v shouldn't exist in %v, but does.", memberName, groupName)
			}
			log.Printf("Removing %v from %v", memberName, groupName)
			if dryrun {
				continue
			}
			groupID := idCache[fmt.Sprintf("group:%v", groupName)]
			userID := idCache[fmt.Sprintf("user:%v", memberName)]
			_, err := gitc.GroupMembers.RemoveGroupMember(groupID, userID)
			if err != nil {
				return err
			}
		}
	}
	return nil
}
