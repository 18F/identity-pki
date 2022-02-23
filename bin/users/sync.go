// Sync syncs users, groups, projects, group membership and shared projects.

package main

import (
	"flag"
	"fmt"
	"io/ioutil"
	"log"
	"os"

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

// What we care about w.r.t. GitLab authorization. These objects will be synced.
type GitlabCache struct {
	Users        map[string]*gitlab.User
	Groups       map[string]*gitlab.Group
	GroupMembers map[Membership]*gitlab.GroupMember
	Projects     map[string]*gitlab.Project
}

type Membership struct {
	Collection string
	Member     string
}

// Format of projects in YAML
type AuthorizedProject struct {
	Groups map[string]struct {
		Access *gitlab.AccessLevelValue
	}
}

func (p *AuthorizedProject) UnmarshalYAML(unmarshal func(interface{}) error) error {
	type alias struct {
		Groups map[string]struct {
			Access string
		}
	}
	var tmp alias
	if err := unmarshal(&tmp); err != nil {
		return err
	}

	*p = AuthorizedProject{
		Groups: make(map[string]struct{Access *gitlab.AccessLevelValue}),
	}
	
	for gName, g := range tmp.Groups {
		switch level := g.Access; level {
		case "developer":
			p.Groups[gName] = struct {
				Access *gitlab.AccessLevelValue
			}{
				Access: gitlab.AccessLevel(gitlab.DeveloperPermissions),
			}
		case "maintainer":
			p.Groups[gName] = struct {
				Access *gitlab.AccessLevelValue
			}{
				Access: gitlab.AccessLevel(gitlab.MaintainerPermissions),
			}
		default:
			return fmt.Errorf("Access level %v not defined", level)
		}
	}
	return nil
}

	
// Format of users in YAML
type AuthUser struct {
	Aws_groups    []string
	Gitlab_groups []string
	Git_username string
	Name string
	Email string
}

// Format of groups in YAML
type AuthGroup struct {
	Description string
}

// Format of the YAML input
type AuthorizedUsers struct {
	Users    map[string]*AuthUser
	Groups   map[string]*AuthGroup
	Projects map[string]*AuthorizedProject
}

// A mapping of user and group names to IDs, because our configs work with
// usernames, but GitLab often wants the ID. Populate as we find more mappings.
var cache = &GitlabCache{
	Users:        map[string]*gitlab.User{},
	Groups:       map[string]*gitlab.Group{},
	GroupMembers: map[Membership]*gitlab.GroupMember{},
	Projects:     map[string]*gitlab.Project{},
}

func init() {
	flag.StringVar(&fqdn, "fqdn", "", "Required. Fully qualified domain name for the GitLab instance.")
	flag.StringVar(&userYaml, "file", "../../terraform/master/global/users.yaml", "Input YAML.")
	flag.BoolVar(&check, "check", false, "Only check whether a change would be made, and error if so.")
	flag.BoolVar(&dryrun, "dryrun", false, "Synonym for -check.")
	flag.Usage = func() {
		fmt.Fprintf(flag.CommandLine.Output(), "sync.go: Syncs GitLab users with a YAML source of truth. Requires GITLAB_API_TOKEN to be set in the environment. Usage:\n")
		flag.PrintDefaults()
		os.Exit(1)
	}
}

func main() {
	// Check if we have flags and env vars set
	flag.Parse()
	dryrun = check || dryrun
	if fqdn == "" {
		flag.Usage()
	}
	apiToken = os.Getenv(gitlabTokenEnvVar)
	if apiToken == "" {
		flag.Usage()
	}

	// Set up GitLab connection
	rawClient, err := gitlab.NewClient(
		apiToken,
		gitlab.WithBaseURL(fmt.Sprintf("https://%s", fqdn)),
	)
	if err != nil {
		log.Fatalf("Failed to create client: %v", err)
	}
	gitc := &GitlabClient{
		client: rawClient,
	}

	// Fill cache
	err = populateGitLabCache(gitc)
	if err != nil {
		log.Fatalf("Failed to query GitLab: %v", err)
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

	if err := resolveUsers(gitc, existingUsers, authorizedUsers); err != nil {
		log.Fatalf("Error resolving users: %v", err)
	}

	//
	// Sync Groups
	//

	// Get existing groups
	gitlabGroups, err := getExistingGroups(gitc)
	if err != nil {
		log.Fatalf("Could not get GitLab groups: %v", err)
	}

	groupsToCreate, groupsToDelete := resolveGroups(gitlabGroups, authorizedUsers)
	err = createGroups(gitc, groupsToCreate)
	if err != nil {
		log.Fatalf("Unable to create groups: %v", err)
	}
	err = deleteGroups(gitc, groupsToDelete)
	if err != nil {
		log.Fatalf("Unable to delete groups: %v", err)
	}

	//
	// Sync Group Members
	//

	groupsWithMembers, err := getExistingMembers(gitc)
	if err != nil {
		log.Fatalf("Failed to list memberships: %v", err)
	}
	authGroups := getAuthorizedGroups(authorizedUsers)
	membersToCreate, membersToDelete := resolveMembers(groupsWithMembers, authGroups)
	err = createMemberships(gitc, membersToCreate)
	if err != nil {
		log.Fatalf("Failed to create members: %v", err)
	}
	err = deleteMemberships(gitc, membersToDelete)
	if err != nil {
		log.Fatalf("Failed to delete members: %v", err)
	}

	//
	// Sync Project Membership
	//

	projects, err := getExistingProjects(gitc)
	if err != nil {
		log.Fatalf("Failed to get project memberships: %v", err)
	}

	err = resolveProjects(gitc, projects, authorizedUsers)
	if err != nil {
		log.Fatalf("Failed to resolve projects: %v", err)
	}
}

func resolveProjects(gitc GitlabClientIface, existingProjects map[string]*gitlab.Project, authUsers *AuthorizedUsers) error {
	for pathWithNamespace, authProject := range authUsers.Projects {

		// Does the project exist
		existingProject, ok := existingProjects[pathWithNamespace]
		if !ok {
			return fmt.Errorf("Project %v doesn't exist.", pathWithNamespace)
		}

		// Create or update shares
		for gName, group := range authProject.Groups {

			// Is the group shared with the project?
			foundShare := false
			for _, share := range existingProject.SharedWithGroups {
				if share.GroupName == gName {
					// Ensure accessLevel is correct
					if gitlab.AccessLevelValue(share.GroupAccessLevel) == *group.Access {
						foundShare = true
					} else {
						fatalIfDryRun("%v shouldn't be shared with %v at level %v (should be %v)", pathWithNamespace, share.GroupName, share.GroupAccessLevel, group.Access)
						_, err := gitc.DeleteSharedProjectFromGroup(existingProject.ID, share.GroupID)
						if err != nil {
							return err
						}
					}
					break
				}
			}
			// Create share if we didn't find it
			if !foundShare {
				fatalIfDryRun("%v should be shared with %v", pathWithNamespace, gName)
				_, err := gitc.ShareProjectWithGroup(
					existingProject.ID,
					&gitlab.ShareWithGroupOptions{
						GroupAccess: group.Access,
						GroupID:     &cache.Groups[gName].ID,
					},
				)
				if err != nil {
					return err
				}
			}
		}

		// Delete unauthorized shares
		for _, share := range existingProject.SharedWithGroups {
			if _, ok := authProject.Groups[share.GroupName]; !ok {
				// This share shouldn't exist
				fatalIfDryRun("%v shouldn't be shared with %v", pathWithNamespace, share.GroupName)
				_, err := gitc.DeleteSharedProjectFromGroup(existingProject.ID, share.GroupID)
				if err != nil {
					return err
				}
			}
		}
	}
	return nil
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

func getExistingGroups(gitc GitlabClientIface) (map[string]*gitlab.Group, error) {
	groups, _, err := gitc.ListGroups(
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
		cache.Groups[g.Name] = g
	}

	return groupMap, nil
}

func getExistingMembers(gitc GitlabClientIface) (map[string]map[string]bool, error) {
	memberships := map[string]map[string]bool{}

	gitlabGroups, err := getExistingGroups(gitc)
	if err != nil {
		return nil, err
	}

	for gname, g := range gitlabGroups {
		members, err := getGroupMembers(gitc, g)
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

func getExistingProjects(gitc GitlabClientIface) (map[string]*gitlab.Project, error) {
	projectMap := map[string]*gitlab.Project{}
	projects, _, err := gitc.ListProjects(
		&gitlab.ListProjectsOptions{
			ListOptions: gitlab.ListOptions{
				PerPage: 100,
			},
		},
	)
	if err != nil {
		return nil, err
	}

	for _, project := range projects {
		projectMap[project.PathWithNamespace] = project
	}
	return projectMap, nil
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

func getExistingUsers(gitc GitlabClientIface) (map[string]*gitlab.User, error) {
	gitUsers, _, err := gitc.ListUsers(
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
		cache.Users[u.Username] = u
	}

	return existingUsers, nil
}

// Given sets of existing and authorized users, returns sets of users to block, unblock and create
func resolveUsers(
	gitc GitlabClientIface,
	existingUsers map[string]*gitlab.User,
	authorizedUsers *AuthorizedUsers,
) error {

	// Just a little bookkeeping so we can quickly decided whether to block a user later
	keptUsers := map[string]bool{}
	
	// Unblock or create needed users (members of groups)
	for username, userAttrs := range authorizedUsers.Users {

		// Override the username if a preferred one exists
		if userAttrs.Git_username != "" {
			username = userAttrs.Git_username
		}
		
		if len(userAttrs.Gitlab_groups) > 0 {
			
			// Record this for use when we block users
			keptUsers[username] = true

			// Create or unblock&update
			if u, ok := existingUsers[username]; ok {

				// Unblock user by user ID
				err := unblockUser(gitc, u)
				if err != nil {
					return err
				}

				// Now that we know the user exists, sync the attrs
				if err := updateUser(gitc, u, userAttrs); err != nil {
					return err
				}
			} else {
				if err := createUser(gitc, username, userAttrs); err != nil {
					return err
				}
			}
		}
	}

	for username, user := range existingUsers {

		// Did we create/unblock this user?
		if _, ok := keptUsers[username]; !ok {
			if err := blockUser(gitc, user); err != nil {
				return err
			}
		}
	}
	return nil
}

// Returns sets of groups to create and delete
func resolveGroups(
	gitlabGroups map[string]*gitlab.Group,
	authorizedUsers *AuthorizedUsers,
) (map[string]bool, map[string]*gitlab.Group) {

	authGroups := getAuthorizedGroups(authorizedUsers)

	groupsToCreate := map[string]bool{}
	groupsToDelete := map[string]*gitlab.Group{}

	// Copy input so we don't confuse callers
	for k, v := range gitlabGroups {
		groupsToDelete[k] = v
	}

	// authGroups is every group with a member
	for ag := range authGroups {
		if _, ok := gitlabGroups[ag]; ok {
			delete(groupsToDelete, ag)
			continue
		}
		groupsToCreate[ag] = true
	}

	// Don't delete defined groups without members
	for ag := range authorizedUsers.Groups {
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

func blockUser(gitc GitlabClientIface, u *gitlab.User) error {
	if u.State == "blocked" {
		return nil
	}

	fatalIfDryRun("User %v should be blocked, but isn't.", u.Username)

	if err := gitc.BlockUser(u.ID); err != nil {
		return err
	}
	return nil
}

func unblockUser(gitc GitlabClientIface, u *gitlab.User) error {
	if u.State == "active" {
		return nil
	}

	fatalIfDryRun("User %v should be unblocked, but isn't.", u.Username)

	if err := gitc.UnblockUser(u.ID); err != nil {
		return err
	}
	return nil
}

func updateUser(gitc GitlabClientIface, gitlabUser *gitlab.User, userAttrs *AuthUser) error {
	options := &gitlab.ModifyUserOptions{
		SkipReconfirmation:  gitlab.Bool(true),
	}
	needUpdate := false

	if userAttrs.Name != "" && gitlabUser.Name != userAttrs.Name {
		options.Name = gitlab.String(userAttrs.Name)
		needUpdate = true
	}

	if userAttrs.Email != "" && gitlabUser.Email != userAttrs.Email {
		options.Email = gitlab.String(userAttrs.Email)
		needUpdate = true
	}
	
	if needUpdate {
		fatalIfDryRun("User %v needs updating (%v -> %v, %v -> %v).", gitlabUser.Username, gitlabUser.Name, userAttrs.Name, gitlabUser.Email, userAttrs.Email)
		if _, _, err := gitc.ModifyUser(gitlabUser.ID, options); err != nil {
			return err
		}
	}
	
	return nil
}

func createUser(gitc GitlabClientIface, username string, userAttrs *AuthUser) error {
	fatalIfDryRun("User %v should exist, but doesn't.", username)

	email := fmt.Sprintf("%v@gsa.gov", username)
	if userAttrs.Email != "" {
		email = userAttrs.Email
	}

	name := username
	if userAttrs.Name != "" {
		name = userAttrs.Name
	}
	
	options := &gitlab.CreateUserOptions{
		Email:               gitlab.String(email),
		ForceRandomPassword: gitlab.Bool(true),
		Username:            gitlab.String(username),
		Name:                gitlab.String(name),
		SkipConfirmation:    gitlab.Bool(true),
		CanCreateGroup:      gitlab.Bool(false),
	}

	newUser, _, err := gitc.CreateUser(options)
	if err != nil {
		return err
	}
	cache.Users[newUser.Username] = newUser
	return nil
}

func createGroups(gitc GitlabClientIface, groupsToCreate map[string]bool) error {
	for gname := range groupsToCreate {
		fatalIfDryRun("Group %v should exist, but doesn't.", gname)
		options := &gitlab.CreateGroupOptions{
			Name: gitlab.String(gname),
			Path: gitlab.String(gname),
		}
		_, _, err := gitc.CreateGroup(options)
		if err != nil {
			return err
		}
	}
	return nil
}

func deleteGroups(gitc GitlabClientIface, groupsToDelete map[string]*gitlab.Group) error {
	for gname, group := range groupsToDelete {
		fatalIfDryRun("Group %v shouldn't exist, but does.", gname)

		_, err := gitc.DeleteGroup(group.ID)
		if err != nil {
			return err
		}
	}
	return nil
}

func createMemberships(gitc GitlabClientIface, membersToCreate map[string]map[string]bool) error {
	for groupName, members := range membersToCreate {
		for memberName := range members {
			fatalIfDryRun("Member %v should exist in %v, but doesn't.", memberName, groupName)

			groupID := cache.Groups[groupName].ID
			memberOpts := &gitlab.AddGroupMemberOptions{
				UserID:      gitlab.Int(cache.Users[memberName].ID),
				AccessLevel: gitlab.AccessLevel(gitlab.DeveloperPermissions),
			}
			_, _, err := gitc.AddGroupMember(groupID, memberOpts)
			if err != nil {
				return err
			}
		}
	}
	return nil
}

func deleteMemberships(gitc GitlabClientIface, membersToDelete map[string]map[string]bool) error {
	for groupName, members := range membersToDelete {
		for memberName := range members {
			fatalIfDryRun("Member %v shouldn't exist in %v, but does.", memberName, groupName)

			groupID := cache.Groups[groupName].ID
			userID := cache.Users[memberName].ID
			_, err := gitc.RemoveGroupMember(groupID, userID)
			if err != nil {
				return err
			}
		}
	}
	return nil
}

func populateGitLabCache(gitc GitlabClientIface) error {
	gitLabUsers, err := getExistingUsers(gitc)
	if err != nil {
		return err
	}
	cache.Users = gitLabUsers

	gitLabGroups, err := getExistingGroups(gitc)
	if err != nil {
		return err
	}
	cache.Groups = gitLabGroups

	for _, group := range gitLabGroups {
		groupMembers, err := getGroupMembers(gitc, group)
		if err != nil {
			return err
		}
		for _, member := range groupMembers {
			membership := Membership{
				Collection: group.Name,
				Member:     member.Username,
			}
			cache.GroupMembers[membership] = member
		}
	}

	projects, err := getExistingProjects(gitc)
	if err != nil {
		return err
	}
	cache.Projects = projects

	return nil
}

func getGroupMembers(gitc GitlabClientIface, group *gitlab.Group) ([]*gitlab.GroupMember, error) {
	members, _, err := gitc.ListGroupMembers(
		group.ID,
		&gitlab.ListGroupMembersOptions{
			ListOptions: gitlab.ListOptions{
				PerPage: 100,
			},
		},
	)
	if err != nil {
		return nil, err
	}
	
	return members, nil
}

// If running with --check or --dryrun, exit and error immediately
func fatalIfDryRun(format string, v ...interface{}) {
	if dryrun {
		log.Fatalf(format, v...)
	} else {
		log.Printf(format, v...)
	}
}
