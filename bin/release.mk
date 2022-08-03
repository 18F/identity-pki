TF_PATHS := $(shell find terraform -name env-vars.sh -exec dirname {} \; |grep -v 'ecr\|gitlab\|prod')
PLANS := $(TF_PATHS:=.plan)
APPLIES := $(TF_PATHS:=.apply)
PROD_TF_PATHS := $(shell find terraform -name env-vars.sh -exec dirname {} \; |grep -v 'ecr\|gitlab\|sms/prod-east' | grep 'prod')
PROD_PLANS := $(PROD_TF_PATHS:=.plan)
PROD_APPLIES := $(PROD_TF_PATHS:=.apply)
APP_ENVS := $(patsubst %,terraform/app/%,int staging dm prod)

# Provide these as vars so they may be overridden for testing purposes
# e.g. td="echo td" git_push="echo git push" bin/release.sh today
ifdef dry_run
td := echo Would have run td
git_push := echo Would have run git push
asg_recycle := echo Would have run asg-recycle
scale_in := echo Would have run scale-in-old-instances
else
td := bin/td
git_push := git push
asg_recycle := bin/asg-recycle
scale_in := bin/scale-in-old-instances
endif

SHELL = /bin/sh -o pipefail -c
.PHONY: clean clean-plan clean-apply clean-recycle clean-scale-in default help non-app-non-prod
.PHONY: other-prod int staging dm prod
.DEFAULT_GOAL := help

all: int staging dm non-app-non-prod prod non-app-prod

# Deploy, with prompts to verify plans
non-app-non-prod: | $(APPLIES)
non-app-prod: | $(PROD_APPLIES)

# Deploy to named app environment, with prompts for user intervention
int staging dm: %: terraform/app/%.recycle-verify
prod: terraform/app/prod.scale-in

# This might be very silly, but lets you just run 'make today' every day and
# does the right thing.
today: $(shell date +%A)
Sunday: help
Monday: help
Tuesday: int
Wednesday: staging dm non-app-non-prod
Thursday: prod non-app-prod
Friday: help
Saturday: help

# weird environments
terraform/waf/staging.plan terraform/waf/staging.apply : export DEPLOY_WEIRD_BRANCH := 1

# Find the cut release
$(APP_ENVS:=.release_version): terraform/app/%.release_version:
	git checkout main
	git pull
	echo "v$$(expr $$(cat VERSION.txt | sed -E 's/pre\-//' | sed -E 's/\..+//') - 1)" > $@

# Prepping app branches
$(APP_ENVS:=.branch): terraform/app/%.branch: | terraform/app/%.release_version
	git checkout stages/$*
	git pull --ff-only origin `cat $|`
	$(git_push) --set-upstream origin stages/$*
	touch $@

# App-specific td invocation
$(APP_ENVS:=.plan): terraform/app/%.plan: | terraform/app/%.branch ## plan for one app env "%"
	git checkout stages/$*
	$(td) -e $* -c b | tee $@.tmp
	mv $@.tmp $@

# If no plan exists, fail. Don't implicitly run plan.
$(APP_ENVS:=.apply): terraform/app/%.apply: | terraform/app/%.plan-verify ## apply for one app env "%"
	git checkout stages/$*
	$(td) -e $* -a auto-approve | tee $@.tmp
	mv $@.tmp $@

# Override so recycling int is run as `sandbox-admin`
$(patsubst %,terraform/app/%.recycle,int): ACCOUNT = sandbox-admin
$(patsubst %,terraform/app/%.recycle,prod staging dm): ACCOUNT = prod-admin

# Recycling for prod, staging, dm is done as `prod-admin`. `int` gets overridden.
$(APP_ENVS:=.recycle): terraform/app/%.recycle: | terraform/app/%.apply ## recycle one app env "%"
	aws-vault exec $(ACCOUNT) -- $(asg_recycle) $* ALL | tee $@.tmp
	mv $@.tmp $@

terraform/app/%.recycle-verify: | terraform/app/%.recycle
	@echo Please verify the recycle of $* completed and $* is healthy.
	@read -p "Enter 'y' to continue: " s && test "$$s" = "y"
	touch $@

# Prod needs a special command to scale-in
PROD_SCALE_INS=$(patsubst %,terraform/app/prod.%.scale-in,idp pivcac worker outboundproxy)
$(PROD_SCALE_INS): terraform/app/prod.%.scale-in: | terraform/app/prod.recycle-verify
	aws-vault exec prod-admin -- $(scale_in) prod $*
	touch $@

terraform/app/prod.scale-in: | $(PROD_SCALE_INS)

$(PROD_PLANS): GIT_BRANCH = stages/prod
terraform/all/tooling-prod.plan: GIT_BRANCH = main
$(PLANS) $(PROD_PLANS):
	test -n "$(GIT_BRANCH)" && git checkout "$(GIT_BRANCH)" || true
	$(td) -d $(shell basename $(@D)) -e $(shell basename $@ .plan) -c b | tee $@.tmp
	mv $@.tmp $@

if_nonempty_plan = if ! grep -q '^No changes in Terraform plan for ' $|; then

$(addsuffix .plan-verify,$(TF_PATHS) $(PROD_TF_PATHS) $(APP_ENVS)): %.plan-verify: | %.plan
	$(if_nonempty_plan) less $|; fi
	@$(if_nonempty_plan) echo "Please verify the plan output of $* (maybe posting to #identity-devops)."; fi
	@$(if_nonempty_plan) read -p "Enter 'y' to continue: " s && test "$$s" = "y"; fi
	touch $@

# Ensure there's a verified plan before applying
$(PROD_APPLIES): GIT_BRANCH = stages/prod
terraform/all/tooling-prod.apply: GIT_BRANCH = main
$(APPLIES) $(PROD_APPLIES): %.apply: | %.plan %.plan-verify
	test -n "$(GIT_BRANCH)" && git checkout "$(GIT_BRANCH)" || true
	rm -f $@.tmp
	$(if_nonempty_plan) $(td) -d $(shell basename $(@D)) -e $(shell basename $@ .apply) -a auto-approve | tee $@.tmp; fi
	$(if_nonempty_plan) mv $@.tmp $@; fi
	touch $@

## Removes all intermediate files (e.g. .plan, .apply)
clean: clean-plan clean-apply clean-recycle clean-scale-in
	rm -f terraform/*/*.branch
	rm -f terraform/*/*.release_version

clean-plan: ## Just removes .plan logs
	rm -f terraform/*/*.plan
	rm -f terraform/*/*.plan.tmp
	rm -f terraform/*/*.plan-verify

clean-apply: ## Just removes .apply logs
	rm -f terraform/*/*.apply
	rm -f terraform/*/*.apply.tmp

clean-recycle: ## Just removes .recycle logs
	rm -f terraform/*/*.recycle
	rm -f terraform/*/*.recycle.tmp
	rm -f terraform/*/*.recycle-verify

clean-scale-in: ## Just remove .scale-in logs
	rm -f terraform/*/*.scale-in

# help: export TEST_VAR=bar
help: ## Prints usage text
	@echo Usage: $(WRAPPER) [TARGET]
	@echo
	@echo Targets:
	@grep -E '^[a-zA-Z_/%.-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "%-25s %s\n", $$1, $$2}'
	@echo
	@echo Prod envs:
	@echo $(PROD_TF_PATHS) | xargs -n 1 echo | column
	@echo
	@echo Non-prod envs:
	@echo $(TF_PATHS) | xargs -n 1 echo | column
	@echo
	@echo App envs:
	@echo $(APP_ENVS) | xargs -n 1 echo | column
