package main

import (
	"flag"
	"fmt"
	"github.com/xanzy/go-gitlab"
	"gopkg.in/yaml.v2"
	"io/ioutil"
	"log"
	"os"
)

const gitlabTokenEnvVar = "GITLAB_API_TOKEN"

// Flags
var fqdn string
var dryrun bool
var userYaml string
var apiToken string // env var

var allowedRoles = map[string]bool{
	"devops": true,
	"appdev": true,
}

var ignoredUsers = []string{
	"support",
	"alert",
}

type AuthorizedUsers struct {
	Users map[string][]string
}

type UserState struct {
	User   *gitlab.User
	Enable bool
}

func init() {
	flag.StringVar(&fqdn, "fqdn", "", "Required. Fully qualified domain name for the GitLab instance.")
	flag.StringVar(&userYaml, "file", "../../terraform/master/global/users.yaml", "Input YAML.")
	flag.BoolVar(&dryrun, "dryrun", false, "Whether to run in dryrun mode. Defaults to false.")
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
	gitlabClient, err := gitlab.NewClient(
		apiToken,
		gitlab.WithBaseURL(fmt.Sprintf("https://%s", fqdn)),
	)
	if err != nil {
		log.Fatalf("Failed to create client: %v", err)
	}

	// Get existing GitLab users
	existingUsers, err := getExistingUsers(gitlabClient)
	if err != nil {
		log.Fatalf("Failed to list users: %v", err)
	}

	authorizedUsers, err := getAuthorizedUsers(userYaml)
	if err != nil {
		log.Fatalf("Error reading user YAML: %s", err)
	}

	newUsers := make(map[string]string)
	markUsers(existingUsers, newUsers, authorizedUsers)

	// For each user in GitLab, create/keep/disable as marked
	ignoreMap := make(map[string]bool)
	for _, v := range ignoredUsers {
		ignoreMap[fmt.Sprintf("%v@%v", v, fqdn)] = true
	}
	
	for _, u := range existingUsers {
		if _, ok := ignoreMap[u.User.Email]; ok {
			continue
		}
		if u.Enable {
			err = unblockUser(gitlabClient, u.User)
			if err != nil {
				log.Fatalf("Could not unblock %v: %v", u.User.Email, err)
			}
		} else if !u.Enable {
			err = blockUser(gitlabClient, u.User)
			if err != nil {
				log.Fatalf("Could not block %v: %v", u.User.Email, err)
			}
		}
	}
	for email, username := range newUsers {
		err = createUserFromEmail(gitlabClient, email, username)
		if err != nil {
			log.Fatalf("Could not create %v: %v", email, err)
		}
	}
}

func createUserFromEmail(gitc *gitlab.Client, email string, username string) error {
	log.Printf("Create %#v", email)
	options := &gitlab.CreateUserOptions{
		Email:               gitlab.String(fmt.Sprintf(email)),
		ForceRandomPassword: gitlab.Bool(true),
		Username:            gitlab.String(username),
		Name:                gitlab.String(username),
		SkipConfirmation:    gitlab.Bool(true),
	}

	if dryrun {
		return nil
	}

	_, _, err := gitc.Users.CreateUser(options)
	if err != nil {
		return err
	}
	return nil
}

func blockUser(gitc *gitlab.Client, user *gitlab.User) error {
	log.Printf("Block %v (ID %v)", user.Email, user.ID)

	if dryrun {
		return nil
	}

	if user.State == "blocked" {
		return nil
	}

	err := gitc.Users.BlockUser(user.ID)
	if err != nil {
		return err
	}
	return nil
}

func unblockUser(gitc *gitlab.Client, user *gitlab.User) error {
	log.Printf("Unblock %v (ID %v)", user.Email, user.ID)

	if dryrun {
		return nil
	}

	if user.State == "active" {
		return nil
	}

	err := gitc.Users.UnblockUser(user.ID)
	if err != nil {
		return err
	}
	return nil
}

func getAuthorizedUsers(f string) (*AuthorizedUsers, error) {
	// Get Users from YAML
	var authorizedUsers AuthorizedUsers
	userFile, err := ioutil.ReadFile(f)
	if err != nil {
		return nil, err
	}
	err = yaml.Unmarshal(userFile, &authorizedUsers)
	if err != nil {
		return nil, err
	}
	return &authorizedUsers, nil
}

func getExistingUsers(gitc *gitlab.Client) (map[string]*UserState, error) {
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

	existingUsers := make(map[string]*UserState)
	for _, u := range gitUsers {
		existingUsers[u.Email] = &UserState{
			User:   u,
			Enable: false,
		}
		log.Printf("Found existing GitLab user: %v (%v)", u.Email, u.State)
	}

	return existingUsers, nil
}

func markUsers(existingUsers map[string]*UserState, newUsers map[string]string, authorizedUsers *AuthorizedUsers) {
	// For each user in YAML,  mark to keep it
	for username, userRoles := range authorizedUsers.Users {
		for _, role := range userRoles {
			if _, ok := allowedRoles[role]; ok {
				email := fmt.Sprintf("%s@gsa.gov", username)
				if _, ok := existingUsers[email]; ok {
					existingUsers[email].Enable = true
				} else {
					newUsers[email] = username
				}
			}
		}
	}
}
