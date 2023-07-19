// Sync syncs users, groups, projects, group membership and shared projects.

package main

import (
	"flag"
	"fmt"
	"log"
	"os"

	"github.com/hashicorp/go-multierror"
	"github.com/xanzy/go-gitlab"
	"golang.org/x/exp/slog"
	"gopkg.in/yaml.v2"
)
const gitlabTokenEnvVar = "GITLAB_API_TOKEN"
const ghost = "ghost"

// Flags
var fqdn string
var dryrun bool
var userYaml string
var apiToken string // env var
var check bool
var validateOnly bool

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

var logger = slog.New(slog.NewJSONHandler(os.Stdout, nil))

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
		Groups: make(map[string]struct{ Access *gitlab.AccessLevelValue }),
	}

	accessLevelAlias := map[string]gitlab.AccessLevelValue{
		"none":       gitlab.NoPermissions,
		"minimal":    gitlab.MinimalAccessPermissions,
		"guest":      gitlab.GuestPermissions,
		"reporter":   gitlab.ReporterPermissions,
		"developer":  gitlab.DeveloperPermissions,
		"maintainer": gitlab.MaintainerPermissions,
		"owner":      gitlab.OwnerPermissions,
	}

	for gName, g := range tmp.Groups {
		alias := g.Access
		if val, ok := accessLevelAlias[alias]; ok {
			p.Groups[gName] = struct {
				Access *gitlab.AccessLevelValue
			}{
				Access: gitlab.AccessLevel(val),
			}
		} else {
			return fmt.Errorf("access level %v not defined", alias)
		}
	}
	return nil
}

// Format of users from parsing YAML. For backwards compatibility, all fields
// must be lists of strings in YAML, but we unmarshal some into scalar strings.
type AuthUser struct {
	Aws_groups         []string
	Ec2_username       []string
	Gitlab_groups      []string
	Git_username       string
	Name               string
	Email              string
	Can_create_group   bool
	Gitlab_project_bot bool
}

func (au *AuthUser) UnmarshalYAML(unmarshal func(interface{}) error) error {
	type alias struct {
		Aws_groups         []string
		Ec2_username       []string
		Gitlab_groups      []string
		Git_username       []string
		Name               []string
		Email              []string
		Can_create_group   []string
		Gitlab_project_bot []string
	}
	var tmp alias
	if err := unmarshal(&tmp); err != nil {
		return err
	}

	*au = AuthUser{
		Aws_groups:    tmp.Aws_groups,
		Gitlab_groups: tmp.Gitlab_groups,
	}
	if len(tmp.Git_username) > 0 {
		au.Git_username = tmp.Git_username[0]
	}
	if len(tmp.Name) > 0 {
		au.Name = tmp.Name[0]
	}
	if len(tmp.Email) > 0 {
		au.Email = tmp.Email[0]
	}
	au.Can_create_group = len(tmp.Can_create_group) > 0 && tmp.Can_create_group[0] == "true"
	au.Gitlab_project_bot = len(tmp.Gitlab_project_bot) > 0 && tmp.Gitlab_project_bot[0] == "true"
	return nil
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
	flag.BoolVar(&validateOnly, "validate", false, "Only validate users.yaml - do not call the Gitlab API.")
}

func main() {

	var result error

	// Check if we have flags and env vars set
	flag.Parse()

	// Parse YAML
	authorizedUsers, err := getAuthorizedUsers(userYaml)
	if err != nil {
		log.Fatalf("Error reading user YAML: %s", err)
	}

	// Run internal validations before we attempt any external changes
	if err := authorizedUsers.Validate(); err != nil {
		log.Fatalf("users yaml failed validation: %v", err)
	}
	if validateOnly {
		os.Exit(0)
	}

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

	// This may fail if Gitlab returns errors. Don't bail, because there's still useful work to do.
	if err := resolveUsers(gitc, existingUsers, authorizedUsers); err != nil {
		result = multierror.Append(result, fmt.Errorf("error resolving users: %v", err))
	}

	//
	// Sync Groups
	//

	// Get existing groups
	gitlabGroups, err := getExistingGroups(gitc)
	if err != nil {
		log.Fatalf("Could not get GitLab groups: %v", err)
	}

	groupsToCreate := resolveGroups(gitlabGroups, authorizedUsers)

	// Even if these fail, try to continue. There's still work to do.
	err = createGroups(gitc, groupsToCreate)
	if err != nil {
		result = multierror.Append(result, fmt.Errorf("unable to create groups: %v", err))
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
	// Even if these fail, try to continue. There's still work to do.
	err = createMemberships(gitc, membersToCreate)
	if err != nil {
		result = multierror.Append(result, fmt.Errorf("failed to create members: %v", err))
	}
	err = deleteMemberships(gitc, membersToDelete)
	if err != nil {
		result = multierror.Append(result, fmt.Errorf("failed to delete members: %v", err))
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
		result = multierror.Append(result, fmt.Errorf("failed to resolve projects: %v", err))
	}

	if result != nil {
		log.Fatal(result)
	}
}

func resolveProjects(gitc GitlabClientIface, existingProjects map[string]*gitlab.Project, authUsers *AuthorizedUsers) error {
	for pathWithNamespace, authProject := range authUsers.Projects {

		// Does the project exist
		existingProject, ok := existingProjects[pathWithNamespace]
		if !ok {
			log.Printf("Warning: Project %v doesn't exist.", pathWithNamespace)
			continue
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

		// Use the overridden git username if available
		if au.Git_username != "" {
			username = au.Git_username
		}

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
	userFile, err := os.ReadFile(f)
	if err != nil {
		return nil, err
	}
	err = yaml.Unmarshal(userFile, &authorizedUsers)
	if err != nil {
		return nil, err
	}
	// Postprocess the YAML to fill in blank fields
	for gsaUsername, userAttrs := range authorizedUsers.Users {
		if userAttrs.Email == "" {
			userAttrs.Email = fmt.Sprintf("%v@gsa.gov", gsaUsername)
		}
		if userAttrs.Name == "" {
			userAttrs.Name = gsaUsername
		}
	}
	return &authorizedUsers, nil
}

func getExistingUsers(gitc GitlabClientIface) (map[string]*gitlab.User, error) {
	existingUsers := make(map[string]*gitlab.User)
	opt := 		&gitlab.ListUsersOptions{
		ListOptions: gitlab.ListOptions{
			PerPage: 100,
		},
		ExcludeInternal: func() *bool { b := true; return &b }(),
	}

	for {
		gitUsers, resp, err := gitc.ListUsers(opt)
		if err != nil {
			return nil, err
		}

		for _, u := range gitUsers {
			existingUsers[u.Username] = u
			cache.Users[u.Username] = u
		}
		if resp.NextPage == 0 {
			break
		}
		opt.Page = resp.NextPage
	}

	return existingUsers, nil
}

// Given sets of existing and authorized users, returns sets of users to block, unblock and create
func resolveUsers(
	gitc GitlabClientIface,
	existingUsers map[string]*gitlab.User,
	authorizedUsers *AuthorizedUsers,
) error {

	var result error

	// Just a little bookkeeping so we can quickly decided whether to block a user later
	keptUsers := map[string]bool{}

	// Unblock or create needed users (bots or members of groups)
	for username, userAttrs := range authorizedUsers.Users {

		// Override the username if a preferred one exists
		if userAttrs.Git_username != "" {
			username = userAttrs.Git_username
		}

		if userAttrs.Gitlab_project_bot || len(userAttrs.Gitlab_groups) > 0 {

			// Record this for use when we block users
			keptUsers[username] = true

			// Create or unblock&update
			if u, ok := existingUsers[username]; ok {

				// Unblock user by user ID
				err := unblockUser(gitc, u)
				if err != nil {
					result = multierror.Append(result, err)
				}

				// Now that we know the user exists, sync the attrs
				if err := updateUser(gitc, u, userAttrs); err != nil {
					result = multierror.Append(result, err)
				}
			} else {
				if err := createUser(gitc, username, userAttrs); err != nil {
					result = multierror.Append(result, err)
				}
			}
		}
	}

	for username, user := range existingUsers {

		// Ignore the special "ghost" user...
		if username == ghost {
			continue
		}

		// Did we create/unblock this user?
		if _, ok := keptUsers[username]; !ok {
			if err := blockUser(gitc, user); err != nil {
				result = multierror.Append(result, err)
			}
		}
	}
	return result
}

// Returns sets of groups to create.
// We don't delete groups that may have been manually created, and instead verify that the
// projects and group memberships in users.yaml are synced.
// TODO: directly create groups. Use mocks to test.
func resolveGroups(
	gitlabGroups map[string]*gitlab.Group,
	authorizedUsers *AuthorizedUsers,
) map[string]bool {

	authorizedGroups := getAuthorizedGroups(authorizedUsers)
	groupsToCreate := map[string]bool{}

	// authGroups is every group with a member
	for ag := range authorizedGroups {
		if _, ok := gitlabGroups[ag]; !ok {
			groupsToCreate[ag] = true
		}
	}

	for g := range gitlabGroups {
		if _, ok := authorizedGroups[g]; !ok {
			logger.Info(
				fmt.Sprintf("%v not found in authorized groups; doing nothing.", g),
				"event", "skip_unauthorized_group",
				"group", g,
			)
		}
	}

	return groupsToCreate
}

// Returns memberships to create and delete.
// TODO: create and delete in-place, test with mocks, and recursively create subgroups.
func resolveMembers(
	liveGroupMemberships map[string]map[string]bool,
	authorizedGroups map[string]map[string]bool,
) (map[string]map[string]bool, map[string]map[string]bool) {

	membersToCreate := map[string]map[string]bool{}
	membersToDelete := map[string]map[string]bool{}

	// Go through each live group and members
	for gname, liveMembers := range liveGroupMemberships {
		
		// If existing membership is for a group not in config, don't do anything.
		if _, ok := authorizedGroups[gname]; !ok {
			continue
		}

		// Create the structure where we can store new and invalid memberships
		membersToCreate[gname] = make(map[string]bool)
		membersToDelete[gname] = make(map[string]bool)
		
		for username := range authorizedGroups[gname] {
			if _, ok := liveMembers[username]; !ok {
				// Create new memberships if required
				membersToCreate[gname][username] = true
			}
		}

		for username := range liveMembers {
			if _, ok := authorizedGroups[gname][username]; !ok {
				// This user shouldn't be in this group. Delete.
				membersToDelete[gname][username] = true
			}
		}
	}
	return membersToCreate, membersToDelete
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
	if u.State == "active" || u.State == "deactivated" {
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
		SkipReconfirmation: gitlab.Bool(true),
	}
	needUpdate := false

	if userAttrs.Name != "" && gitlabUser.Name != userAttrs.Name {
		fatalIfDryRun("User %v needs updating: Name %v -> %v", gitlabUser.Username, gitlabUser.Name, userAttrs.Name)
		options.Name = gitlab.String(userAttrs.Name)
		needUpdate = true
	}

	if userAttrs.Email != "" && gitlabUser.Email != userAttrs.Email {
		fatalIfDryRun("User %v needs updating: Email %v -> %v", gitlabUser.Username, gitlabUser.Email, userAttrs.Email)
		options.Email = gitlab.String(userAttrs.Email)
		needUpdate = true
	}

	if userAttrs.Can_create_group != gitlabUser.CanCreateGroup {
		fatalIfDryRun("User %v needs updating: Create Group %v -> %v", gitlabUser.Username, gitlabUser.CanCreateGroup, userAttrs.Can_create_group)
		options.CanCreateGroup = gitlab.Bool(userAttrs.Can_create_group)
		needUpdate = true
	}

	if needUpdate {
		if _, _, err := gitc.ModifyUser(gitlabUser.ID, options); err != nil {
			return err
		}
	}

	return nil
}

func createUser(gitc GitlabClientIface, username string, userAttrs *AuthUser) error {
	fatalIfDryRun("User %v should exist, but doesn't.", username)

	options := &gitlab.CreateUserOptions{
		Email:               gitlab.String(userAttrs.Email),
		ForceRandomPassword: gitlab.Bool(true),
		Username:            gitlab.String(username),
		Name:                gitlab.String(userAttrs.Name),
		SkipConfirmation:    gitlab.Bool(true),
		CanCreateGroup:      gitlab.Bool(userAttrs.Can_create_group),
	}

	newUser, _, err := gitc.CreateUser(options)
	if err != nil {
		return err
	}

	// DEactivate the newly-created user. User will be REactivated on first login.
	err = gitc.DeactivateUser(newUser.ID)
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

			group, ok := cache.Groups[groupName]
			if !ok {
				return fmt.Errorf("%v not found in group cache", groupName)
			}
			user, ok := cache.Users[memberName]
			if !ok {
				return fmt.Errorf("%v not found in user cache", memberName)
			}
			groupID := group.ID
			memberOpts := &gitlab.AddGroupMemberOptions{
				UserID:      gitlab.Int(user.ID),
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
			_, err := gitc.RemoveGroupMember(groupID, userID, &gitlab.RemoveGroupMemberOptions{})
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
	members := []*gitlab.GroupMember{}
	opt := &gitlab.ListGroupMembersOptions{
		ListOptions: gitlab.ListOptions{
			PerPage: 100,
		},
	}
	for {
		ms, resp, err := gitc.ListGroupMembers(group.ID, opt)
		if err != nil {
			return nil, err
		}
		for _, m := range ms {
			members = append(members, m)
		}
		if resp.NextPage == 0 {
			break
		}
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
