#!/usr/bin/env ruby

# Copy a list of issues from one repository to another.
#
# See ../doc/process-issue-tracking.md for more background on the need to copy
# issues between repositories.
# https://github.com/18F/identity-devops/blob/master/copy-issues/doc/process-issue-tracking.md
#

require 'date'
require 'yaml'
require 'pp'

require 'json'
require 'rest-client'
require 'netrc'

def main(args)
  if args.length < 2
    puts <<-EOS
#{File.basename($0)} NETRC_FILE SOURCE_REPO TARGET_REPO MOVED_LABEL ISSUE_IDS

Copy a list of github issues from SOURCE_REPO to TARGET_REPO.

MOVED_LABEL should be a marker like copied-to-target to indicate an issue has
been processed. This label must exist on the source repo.

For example, to copy issues 123 124 and 125 from source-repo to target-repo:

  #{File.basename($0)} secret.netrc myorg/source-repo myorg/target-repo '123 124 125'

    EOS
    exit 1
  end
  netrc = args.fetch(0)
  sourcerepo = args.fetch(1)
  targetrepo = args.fetch(2)
  sentinel_label = args.fetch(3)
  ids_string = args.fetch(4)

  issue_ids = ids_string.split

  r = Runner.new(netrc, sourcerepo, targetrepo, sentinel_label, issue_ids)

  r.dry_run

  puts
  puts "Dry run is complete. Check above to see that all looks good."
  puts "About to destructively update data!"
  if STDIN.tty?
    puts "Press enter to continue..."
    STDIN.gets
  end

  r.run!
end

class Runner
  def initialize(netrc, source_repo, target_repo, moved_label, issue_ids)
    @user, @password = load_creds_from_netrc(netrc)

    @source_repo = source_repo
    @target_repo = target_repo
    @moved_label = moved_label

    @issue_ids = issue_ids

    RestClient.log ||= STDOUT
  end

  def run!
    run(false)
  end

  def dry_run
    run(true)
  end

  def run(dry_run)
    if dry_run
      puts "Starting dry run migration from #{@source_repo} to #{@target_repo}"
    else
      puts "Starting LIVE RUN migration from #{@source_repo} to #{@target_repo}"
    end

    @issue_ids.each do |id|
      migrate_issue(dry_run, id)
    end
  end

  def load_creds_from_netrc(path)
    netrc = Netrc.read(path)
    rec = netrc['api.github.com']
    raise "No rec for api.github.com in netrc" unless rec
    [rec.login, rec.password]
  end

  def migrate_issue(dry_run, issue_id, copy_labels=true)
    puts "migrate_issue #{issue_id} (dry_run: #{dry_run})"

    issue_data = get_issue(@source_repo, issue_id)

    state = issue_data['state']
    if state != 'open'
      warn "skipping issue #{issue_id}, is in state #{state.inspect}, must be 'open' to migrate"
      return
    end

    labels = issue_data.fetch('labels')
    if labels.find {|label| label.fetch('name') == @moved_label}
      warn "skipping issue #{issue_id} already has label #{@moved_label}, will not move"
      return
    end

    source_url = "https://github.com/#{@source_repo}/issues/#{issue_id}"
    body_prefix = "## This issue was migrated from #{source_url}\n\n"

    new_issue_hash = {
      'title' => issue_data.fetch('title') + ' (migrated)',
      'body' => body_prefix + issue_data.fetch('body'),
      'assignees' => issue_data.fetch('assignees').map {|assignee| assignee.fetch('login')}
    }

    if copy_labels
      new_issue_hash['labels'] = issue_data.fetch('labels').map{|label| label.fetch('name')}
    end

    if dry_run
      puts "DRY RUN: would have created issue with data:"
      pp new_issue_hash
    else
      resp = create_issue(@target_repo, new_issue_hash)
      target_url = resp.fetch('url')

      puts "Adding migrated label #{@moved_label} to source issue"
      add_label(@source_repo, issue_id, @moved_label)

      puts "Done migrating #{issue_id} from #{source_url} to #{target_url}"
    end
  end

  def get_issue(repo, issue_id)
    github_get_json("/repos/#{repo}/issues/#{issue_id}")
  end

  def add_label(repo, issue_id, label_name)
    puts "Adding label #{label_name} to #{repo} issue ##{issue_id}"

    res = RestClient::Request.execute(
      method: :post,
      url: "https://api.github.com/repos/#{repo}/issues/#{issue_id}/labels",
      user: @user,
      password: @password,
      payload: [label_name].to_json,
      headers: {content_type: :json})

    data = JSON.parse(res.body)

    #puts "Response:"
    #pp data

    data
  end

  def create_issue(repo, payload_hash)
    res = RestClient::Request.execute(
      method: :post,
      url: "https://api.github.com/repos/#{repo}/issues",
      user: @user,
      password: @password,
      payload: payload_hash.to_json,
      headers: {content_type: :json})

    data = JSON.parse(res.body)

    puts "Created issue: #{data.fetch('url')}"

    data
  end

  def github_get_json(path)
    uri = URI.parse('https://api.github.com')
    uri.path = path
    resp = RestClient::Request.execute(
      method: :get,
      url: uri.to_s,
      user: @user,
      password: @password
    )
    JSON.parse(resp.body)
  end
end

if $0 == __FILE__
  main(ARGV)
end
