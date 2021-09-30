# Tests!

This directory holds the infrastructure tests that you can run on your gitlab
cluster.  It uses [Terratest](https://terratest.gruntwork.io/) to poke and prod
at things.

Terratest is great because it has
[lots of modules](https://pkg.go.dev/github.com/gruntwork-io/terratest/modules)
that you can use to test out kubernetes things, AWS things, ssh things, etc.

## Setting Up

To get set up, you will need to make sure you have golang installed:
```
brew install golang

```

That should be it!  Though it's been a while since I've set up golang, so
there might be more things.  Like I have these set, but I don't know if
you will need to set them too:
```
GOROOT=/usr/local/opt/go/libexec
GOPATH=/Users/<username>/.go
```

Another nice thing is to set your editor up to automatically use `go fmt`.
This is editor specific, so is left as an exercise for the reader.

## Running Tests

Just cd into the `tests` directory, make sure you have done a `tsh login`
for your cluster, and run
```
./test.sh <gitlabclustername> <domain>
```
where `<domain>` is the same as what you set in the `domain` variable in
`terraform/gitlab/module/variables.tf`.

This will run a series of tests on the gitlab instance that you have specified.
If things are good, it should say that everything is ok and return a zero
exitcode.  If it failed for some reason, there should be some outputs that
tell you what the test was expecting and what it got.

## Updating

As you are adding dependencies and so on in the tests, you may need/want to
update dependencies.  There is a makefile that should work for most of the
things that we will want to do:
```
tests$ make
go mod tidy
go mod vendor
tests$ 
```

There is [further information on how to manage modules](https://blog.golang.org/using-go-modules)
in the golang blog.
