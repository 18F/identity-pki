package main

import (
	"github.com/xanzy/go-gitlab"
)

type GitlabClientIface interface {
	ShareProjectWithGroup(pid interface{}, opt *gitlab.ShareWithGroupOptions, options ...gitlab.RequestOptionFunc) (*gitlab.Response, error)
	DeleteSharedProjectFromGroup(pid interface{}, groupID int, options ...gitlab.RequestOptionFunc) (*gitlab.Response, error)
	ListGroups(opt *gitlab.ListGroupsOptions, options ...gitlab.RequestOptionFunc) ([]*gitlab.Group, *gitlab.Response, error)
	ListGroupMembers(gid interface{}, opt *gitlab.ListGroupMembersOptions, options ...gitlab.RequestOptionFunc) ([]*gitlab.GroupMember, *gitlab.Response, error)
	ListProjects(opt *gitlab.ListProjectsOptions, options ...gitlab.RequestOptionFunc) ([]*gitlab.Project, *gitlab.Response, error)
	ListUsers(opt *gitlab.ListUsersOptions, options ...gitlab.RequestOptionFunc) ([]*gitlab.User, *gitlab.Response, error)
	BlockUser(user int, options ...gitlab.RequestOptionFunc) error
	UnblockUser(user int, options ...gitlab.RequestOptionFunc) error
	CreateUser(opt *gitlab.CreateUserOptions, options ...gitlab.RequestOptionFunc) (*gitlab.User, *gitlab.Response, error)
	CreateGroup(opt *gitlab.CreateGroupOptions, options ...gitlab.RequestOptionFunc) (*gitlab.Group, *gitlab.Response, error)
	DeleteGroup(gid interface{}, options ...gitlab.RequestOptionFunc) (*gitlab.Response, error)
	AddGroupMember(gid interface{}, opt *gitlab.AddGroupMemberOptions, options ...gitlab.RequestOptionFunc) (*gitlab.GroupMember, *gitlab.Response, error)
	RemoveGroupMember(gid interface{}, user int, options ...gitlab.RequestOptionFunc) (*gitlab.Response, error)
}

type GitlabClient struct {
	client *gitlab.Client
}

func (gc *GitlabClient) ShareProjectWithGroup(pid interface{}, opt *gitlab.ShareWithGroupOptions, options ...gitlab.RequestOptionFunc) (*gitlab.Response, error) {
	return gc.client.Projects.ShareProjectWithGroup(pid, opt, options...)
}
func (gc *GitlabClient) DeleteSharedProjectFromGroup(pid interface{}, groupID int, options ...gitlab.RequestOptionFunc) (*gitlab.Response, error) {
	return gc.client.Projects.DeleteSharedProjectFromGroup(pid, groupID, options...)
}
func (gc *GitlabClient) ListGroups(opt *gitlab.ListGroupsOptions, options ...gitlab.RequestOptionFunc) ([]*gitlab.Group, *gitlab.Response, error) {
	return gc.client.Groups.ListGroups(opt, options...)
}
func (gc *GitlabClient) ListGroupMembers(gid interface{}, opt *gitlab.ListGroupMembersOptions, options ...gitlab.RequestOptionFunc) ([]*gitlab.GroupMember, *gitlab.Response, error) {
	return gc.client.Groups.ListGroupMembers(gid, opt, options...)
}
func (gc *GitlabClient) ListProjects(opt *gitlab.ListProjectsOptions, options ...gitlab.RequestOptionFunc) ([]*gitlab.Project, *gitlab.Response, error) {
	return gc.client.Projects.ListProjects(opt, options...)
}
func (gc *GitlabClient) ListUsers(opt *gitlab.ListUsersOptions, options ...gitlab.RequestOptionFunc) ([]*gitlab.User, *gitlab.Response, error) {
	return gc.client.Users.ListUsers(opt, options...)
}
func (gc *GitlabClient) BlockUser(user int, options ...gitlab.RequestOptionFunc) error {
	return gc.client.Users.BlockUser(user, options...)
}
func (gc *GitlabClient) UnblockUser(user int, options ...gitlab.RequestOptionFunc) error {
	return gc.client.Users.UnblockUser(user, options...)
}
func (gc *GitlabClient) CreateUser(opt *gitlab.CreateUserOptions, options ...gitlab.RequestOptionFunc) (*gitlab.User, *gitlab.Response, error) {
	return gc.client.Users.CreateUser(opt, options...)
}
func (gc *GitlabClient) CreateGroup(opt *gitlab.CreateGroupOptions, options ...gitlab.RequestOptionFunc) (*gitlab.Group, *gitlab.Response, error) {
	return gc.client.Groups.CreateGroup(opt, options...)
}
func (gc *GitlabClient) DeleteGroup(gid interface{}, options ...gitlab.RequestOptionFunc) (*gitlab.Response, error) {
	return gc.client.Groups.DeleteGroup(gid, options...)
}
func (gc *GitlabClient) AddGroupMember(gid interface{}, opt *gitlab.AddGroupMemberOptions, options ...gitlab.RequestOptionFunc) (*gitlab.GroupMember, *gitlab.Response, error) {
	return gc.client.GroupMembers.AddGroupMember(gid, opt, options...)
}
func (gc *GitlabClient) RemoveGroupMember(gid interface{}, user int, options ...gitlab.RequestOptionFunc) (*gitlab.Response, error) {
	return gc.client.GroupMembers.RemoveGroupMember(gid, user, options...)
}
