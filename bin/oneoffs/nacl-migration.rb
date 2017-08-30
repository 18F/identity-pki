#!/usr/bin/env ruby

require_relative '../../cloudlib/lib/cloudlib'

def log
  Cloudlib.cli_log
end

def get_network_acl(acl_id)
  log.info("Looking up network acl #{acl_id.inspect}")
  ec2 = Cloudlib::EC2.new_resource
  ec2.network_acl(acl_id)
end

def create_allow_all_rules(network_acl)
  log.info("Creating allow all network acl rules on #{network_acl.network_acl_id}")

  log.info("Creating ingress rule")
  maybe_create_allow_all(network_acl, false)

  log.info("Creating egress rule")
  maybe_create_allow_all(network_acl, true)

  log.info("Finished creating allow all rules")
end

# @param network_acl [Aws::EC2::NetworkAcl]
# @param egress [Boolean]
def find_allow_all(network_acl, egress, rule_number: nil)
  network_acl.entries.find_all {|e|
    [
      e.egress == egress,
      e.protocol == '-1', # ANY
      e.rule_action == 'allow',
      rule_number.nil? || e.rule_number == rule_number,
    ].all?
  }
end

def maybe_create_allow_all(network_acl, is_egress)
  found = find_allow_all(network_acl, is_egress)
  if !found.empty?
    found.each do |entry|
      if entry.rule_number == 1
        log.info("Found existing allow all #{gress_label(entry)} rule #1")
        return
      else
        log.info("Ignoring existing rule ##{entry.rule_number} allow all #{gress_label(entry)}")
      end
    end
  end

  log.info("Creating allow all rule, #{is_egress ? 'egress' : 'ingress'}")
  network_acl.create_entry({
    egress: is_egress,
    cidr_block: '0.0.0.0/0',
    dry_run: false,
    protocol: '-1', # ANY
    rule_action: 'allow',
    rule_number: 1,
  })
end

def delete_allow_all_rules(network_acl)
  log.info("Deleting allow all network acl rules on #{network_acl.network_acl_id}")

  # ensure we're looking at latest data
  network_acl.reload

  delete_single_allow_all_rule(network_acl, false)
  delete_single_allow_all_rule(network_acl, true)

  log.info("Finished deleting allow all rules")
end

def delete_single_allow_all_rule(network_acl, is_egress)
  label = is_egress ? 'egress' : 'ingress'
  found = find_allow_all(network_acl, is_egress, rule_number: 1)
  if found.empty?
    log.info("No #{label} allow all rule #1 found")
  else
    log.info("Deleting #{label} rule 1")
    network_acl.delete_entry(egress: is_egress, rule_number: 1)
  end
end

def gress_label(entry)
  if entry.egress
    "egress"
  else
    "ingress"
  end
end

def delete_all_other_rules(network_acl, require_allow_all: true)
  log.warn("Deleting all >#1 network acl rules on #{network_acl.network_acl_id}")

  # ensure we're looking at latest data
  network_acl.reload

  # refuse to operate unless we have allow all rules
  if require_allow_all
    if find_allow_all(network_acl, false, rule_number: 1).empty?
      raise "Refusing to operate on #{network_acl.inspect} because no ingress allow all rule #1 exists"
    end
    if find_allow_all(network_acl, true, rule_number: 1).empty?
      raise "Refusing to operate on #{network_acl.inspect} because no egress allow all rule #1 exists"
    end
  end


  network_acl.entries.each do |entry|
    next if entry.rule_number == 1 # skip our allow all rule
    next if entry.rule_number == 32767 # default rule can't be deleted

    log.warn("Deleting #{gress_label(entry)} rule ##{entry.rule_number}")
    log.warn('  ' + entry.to_hash.inspect)

    network_acl.delete_entry(egress: entry.egress, rule_number:
                             entry.rule_number)
  end

  log.info("Finished deleting all other rules")
end

def usage
  STDERR.puts <<-EOM
usage: #{File.basename($0)} COMMAND NETWORK_ACL_ID

See https://github.com/18F/identity-devops/tree/master/doc/technical/operations/nacl-hacks.md

COMMAND may be one of:

  add-allow-all     Create rule #1 to allow all traffic

  delete-all-rules  Delete all rules except #1

  remove-allow-all  Delete rule #1 allowing all traffic

  EOM
end

def main
  if ARGV.length != 2
    usage
    exit 2
  end

  command = ARGV.fetch(0)
  nacl_id = ARGV.fetch(1)

  nacl = get_network_acl(nacl_id)

  case command
  when 'add-allow-all'
    create_allow_all_rules(nacl)
  when 'delete-all-rules'
    delete_all_other_rules(nacl)
  when 'remove-allow-all'
    delete_allow_all_rules(nacl)
  else
    usage
    exit 2
  end

  log.info("All done!")
end

if $0 == __FILE__
  main
end
