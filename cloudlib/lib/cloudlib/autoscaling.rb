# frozen_string_literal: true

require 'pastel'

# :nodoc:
module Cloudlib

  def self.autoscaling
    AutoScaling.new_resource
  end

  # Class wrapping AutoScaling functionality
  class AutoScaling
    attr_reader :autoscaling
    attr_reader :pastel
    attr_reader :prompt

    def self.new_resource
      Aws::AutoScaling::Resource.new
    end

    RecycleScheduledActionName = 'RecycleOnce.asg-recycle'

    def initialize
      @autoscaling = self.class.new_resource
      @pastel = Pastel.new
      @prompt = TTY::Prompt.new(output: STDERR)
    end

    # Print information about the given auto scaling group.
    #
    # @param [String] asg_name
    # @param [String] preamble Text to describe the output
    # @param [Boolean] print_scheduled_actions
    # @param [Boolean] prompt_for_recycle If set, and a scheduled action is
    #   found named with the `RecycleScheduledActionName`, prompt the user
    #   whether they want to continue, since this means there is already a
    #   recycle in progress.
    #
    # @return [Aws::AutoScaling::Types::AutoScalingGroup]
    #
    def print_asg_info(asg_name, preamble: 'Current',
                       print_scheduled_actions: true,
                       prompt_for_recycle: false)
      data = get_autoscaling_group_by_name(asg_name).data

      if print_scheduled_actions
        sched = print_asg_schedule_info(asg_name)
      end

      puts pastel.blue.bold("#{preamble} ASG capacity of #{asg_name.inspect}:")

      {
        'desired:' => :desired_capacity,
        'min:' => :min_size,
        'max:' => :max_size,
      }.each_pair do |label, method|
        value = data.public_send(method)
        puts pastel.blue.bold("  #{label.ljust(8)} #{value}")
      end

      puts pastel.blue.bold(
        "Health check: #{data.health_check_type}, " +
        "#{data.health_check_grace_period}s grace period"
      )

      if prompt_for_recycle
        unless print_scheduled_actions
          raise ArgumentError.new(
            'Must pass print_scheduled_actions in order to prompt_for_recycle'
          )
        end
        if sched.any? { |action| action.name == RecycleScheduledActionName }
          log.warn('It looks like a recycle is already in progress!')
          prompt.ask('Press enter to continue anyway...')
        end
      end

      data
    end

    # Print scheduled action information about the given auto scaling group and
    # return an array of scheduled actions.
    #
    # @param [String] asg_name
    #
    # @return [Array<Aws::AutoScaling::ScheduledAction>]
    #
    def print_asg_schedule_info(asg_name)
      sched = get_autoscaling_scheduled_actions(asg_name)

      unless sched.empty?
        puts pastel.yellow.bold("Scheduled actions for #{asg_name}:")
        puts JSON.pretty_generate(sched.map { |action| action.data.to_h })
      end

      sched
    end

    # @param [String] asg_name
    # @param [:min, :max, :desired] type
    # @param [Integer] count
    def change_asg_count(asg_name, type:, count:, print_counts: true)
      case type
      when :min
        key = :min_size
      when :max
        key = :max_size
      when :desired
        key = :desired_capacity
      else
        raise ArgumentError.new("Unexpected count type: #{type.inspect}")
      end

      print_asg_info(asg_name) if print_counts

      log.info("Setting ASG #{asg_name.inspect} #{type} count to " +
               count.inspect)

      autoscaling.client.update_auto_scaling_group(
        auto_scaling_group_name: asg_name,
        key => count
      )

      if print_counts
        print_asg_info(asg_name, preamble: 'After change, current',
                       print_scheduled_actions: false)
      end
    end

    # Identify which instances to terminate in order to get the ASG down to its
    # desired count. Log the rationale being used.
    #
    # @param [Aws::AutoScaling::AutoScalingGroup] asg
    # @param [Integer] Desired count of instances after scaling in
    #
    def find_instances_to_scale_in(asg, desired_capacity)
      asg_instance_info = {}
      asg.instances.each {|i| asg_instance_info[i.instance_id] = i }

      ec2 = Cloudlib::EC2.new
      instances = ec2.list_instances_by_ids(asg.instances.map(&:instance_id), in_vpc: false)
      instances.sort_by!(&:launch_time).reverse!

      log.info('To keep:')

      instances.each_with_index do |i, index|
        info = asg_instance_info.fetch(i.instance_id)
        uptime_hours = ((Time.now - i.launch_time) / 3600.0).round(1)
        if index == desired_capacity
          log.info('To scale in:')
        end
        log.info([
          i.instance_id, i.image_id, i.launch_time, "(#{uptime_hours} hrs ago)",
          i.state.name, info.health_status, info.lifecycle_state, info.protected_from_scale_in ? 'protected' : '-',
        ].map(&:to_s).join(' '))
      end

      # instances to scale in will be left in instances
      to_keep = instances.shift(desired_capacity)

      to_scale_in = instances.select {|i| asg_instance_info.fetch(i.instance_id).protected_from_scale_in }
      unprotected = instances.reject {|i| asg_instance_info.fetch(i.instance_id).protected_from_scale_in }

      unless unprotected.empty?
        log.info("#{unprotected.count} instances already have no scale-in" +
                 "protection: " + unprotected.map(&:instance_id).join(' '))
      end

      if to_scale_in.empty?
        return to_scale_in
      end

      # assert that all the new instances are up and healthy
      to_keep.each do |i|
        info = asg_instance_info.fetch(i.instance_id)

        unless info.health_status == 'Healthy' && info.lifecycle_state == 'InService'
          log.error("New instance #{i.instance_id} is #{info.health_status} and #{info.lifecycle_state}")
          log.error('This ought to be Healthy and InService, bailing out...')
          raise UnsafeError.new('Unexpected health status on new instance')
        end

        if Time.now - i.launch_time < asg.health_check_grace_period
          log.error("Health check grace period #{asg.health_check_grace_period} has not elapsed yet for #{i.instance_id}")
          log.error("Instance was launched only #{(Time.now - i.launch_time).to_i} seconds ago")
          if ENV['UNSAFE_ALLOW_INSTANCE_IN_GRACE_PERIOD']
            log.warn('Continuing anyway because UNSAFE_ALLOW_INSTANCE_IN_GRACE_PERIOD is set')
          else
            raise UnsafeError.new("Too early to tell if instance is healthy: " +
                                  i.instance_id.inspect)
          end
        end
      end

      log.info('New instances are all healthy according to ASG: ' + to_keep.map(&:instance_id).join(' '))

      asg_name = asg.auto_scaling_group_name
      if asg.health_check_type == 'EC2'
        log.warn("#{asg_name} uses EC2 health checks, which only check hardware")
        log.warn("WARNING: you must check health independently!")
      else
        log.info("#{asg_name} uses ELB health checks, which are informative")
      end

      return to_scale_in
    end

    # Remove scale-in protection from as many instances are needed to get the
    # ASG down to its desired count. Perform some sanity checks to help ensure
    # that all the instances we're keeping are healthy and InService before
    # removinge scale-in protection from any of them.
    #
    # @param [String] asg_name
    # @param [Boolean] prompt_continue Whether to prompt before proceeding
    #
    def scale_in_old_instances(asg_name, prompt_continue: true)
      log.info("Looking up ASG #{asg_name.inspect}")
      asg = get_autoscaling_group_by_name(asg_name)

      log.info("#{asg_name} desired count: #{asg.desired_capacity}")
      log.info("#{asg_name} running count: #{asg.instances.count}")

      to_scale_in = find_instances_to_scale_in(asg, asg.desired_capacity)

      if to_scale_in.empty?
        log.info("No instances require removal of scale-in protection")
        return
      end

      log.warn("Will remove scale-in protection from #{to_scale_in.count} older instances: " + to_scale_in.map(&:instance_id).join(' '))

      if prompt_continue
        unless prompt.yes?('Continue?', default: false)
          log.warn('Aborting')
          return false
        end
      end

      set_instance_protection(asg_name, to_scale_in.map(&:instance_id), false)

      log.info('Finished removing scale-in protection')
    end

    def set_instance_protection(asg_name, instance_ids, is_protected)
      log.info("Setting scale-in protection to #{is_protected.inspect} for " +
               "#{asg_name.inspect} instances: #{instance_ids.inspect}")

      autoscaling.client.set_instance_protection(
        auto_scaling_group_name: asg_name, instance_ids: instance_ids,
        protected_from_scale_in: is_protected
      )
    end

    # Initiate a recycle of the given autoscaling group by doubling its desired
    # count and then creating a scheduled action in the near future to reduce
    # the desired count back to the normal level.
    #
    # @param [String] asg_name
    # @param [Integer] new_size The desired capacity to set immediately
    # @param [Integer] return_to_size The desired capacity to set in the
    #   scheduled action
    # @param [Integer] spindown_delay How long in the future (seconds) to
    #   create the scheduled action to set the return_to_size
    # @param [Boolean] print_summary Whether to print a human readable summary
    #   of actions
    # @param [Boolean] skip_zero Whether to keep going if the target desired
    #   capacity is 0
    # @param [Boolean] interactive
    #
    def start_recycle(asg_name, new_size: nil, return_to_size: nil,
                      skip_zero: false, spindown_delay: nil,
                      print_summary: true, interactive: true)
      log.info "Starting ASG recycle of #{asg_name.inspect}"

      # Load current ASG size data and print it
      data = print_asg_info(asg_name, prompt_for_recycle: true)

      current_size = data.desired_capacity
      max_size = data.max_size
      _min_size = data.min_size
      health_grace_period = data.health_check_grace_period

      # By default, set the spindown delay to either 2x the grace period, or a
      # minimum of 15 minutes if the grace period is too short.
      #
      # We set our default spin-down delay to be 2x the grace period to be
      # extra sure that newly provisioned instances have time to start
      # receiveing health checks before we terminate any existing instances.
      #
      # This functionality is mostly obsolete thanks to ASG Lifecycle Hooks,
      # which allow us to set a health check grace period of 0 and have no
      # grace period whatsoever. Use a default spin-down delay of 15 minutes in
      # this case.
      spindown_delay ||= [health_grace_period * 2, 900].max

      # warn if not using default return-to size
      if return_to_size
        if return_to_size != current_size
          log.warn("Using #{return_to_size} as spin-down size, not default #{current_size}")
        end
      else
        # by default, return to the current size
        return_to_size = current_size
      end

      # warn if not using default immediate size
      # by default, double the number of instances
      default_new_size = return_to_size * 2
      if new_size
        if new_size != default_new_size
          log.warn("Using #{new_size} as immediate, not default #{default_new_size}")
        end
      else
        new_size = default_new_size
      end

      if new_size > max_size
        message = "cannot spin up #{new_size} instances, > max #{max_size}"
        log.error(message)
        raise ArgumentError.new(message)
      end

      # warn if recycling is a noop because that's surprising to user
      if current_size == 0 && new_size == 0
        message = 'current desired size is 0, nothing to recycle'

        # if skip_zero was given and current desired count is 0, just warn
        if skip_zero
          log.info("Skipping #{asg_name.inspect}, " + message)
          return
        end

        # otherwise fail unless we have a new nonzero target
        log.error(message)
        raise Error.new("ASG #{asg_name.inspect} " + message)
      end

      spindown_time = Time.now + spindown_delay

      log.info("ASG recycle of #{asg_name.inspect}: new_size" +
               " #{new_size.inspect}, return_to_size" +
               " #{return_to_size.inspect}, spindown_delay" +
               " #{spindown_delay.inspect}")

      if print_summary
        if new_size > current_size
          direction = 'increase to'
        elsif new_size < current_size
          direction = 'decrease to'
        elsif new_size == current_size
          direction = 'maintain at'
        end
        [
          "Recycling #{asg_name}:",
          "Will #{direction} #{new_size} instances immediately",
          "Will return to   #{return_to_size} instances in " +
            "#{spindown_delay}s (at #{spindown_time.strftime('%F %T')})",
        ].each { |line| puts pastel.bold.blue(line) }
      end

      if new_size != current_size
        set_desired_capacity(asg_name, new_size)
      else
        log.info("Current desired capacity is already #{current_size.inspect}")
      end

      create_scheduled_action(asg_name, RecycleScheduledActionName,
                              start_time: spindown_time,
                              desired_capacity: return_to_size)
    end

    # Call `#start_recycle` once for each autoscaling group in an environment.
    #
    # @param [String] env
    # @param [Hash] recycle_opts Options passed directly to `#start_recycle`
    # @param [Boolean] interactive Whether to prompt for confirmation
    #
    def recycle_all_asgs_in_env(env, recycle_opts: {}, interactive: true)
      prefix = env + '-'
      asgs = list_autoscaling_groups(name_prefix: prefix, skip_stateful: true,
                                     skip_zero: true)
      if asgs.empty?
        log.error("No ASGs found prefixed #{prefix.inspect} -- wrong account?")
        raise NotFound.new("No auto scaling groups found for #{env.inspect}")
      end

      log.info("\nWill recycle all autoscaling groups in #{env.inspect}:\n  " +
               asgs.map(&:name).join("\n  "))

      if interactive
        prompt.ask('Press enter to continue...')
      end

      # it would be nice to pass the data through to recycle to avoid more API
      # calls, but that's future work
      asgs.each do |group|
        puts pastel.bold.green("\nRecycling #{group.name}")
        start_recycle(group.name, **recycle_opts)
      end

      puts pastel.bold.green('All Done')
    end

    def log
      @log ||= Cloudlib.class_log(self.class, STDERR)
    end

    def self.log
      @log ||= Cloudlib.class_log(self, STDERR)
    end

    # Look up an auto scaling group by name.
    #
    # @param asg_name [String]
    #
    # @return [Aws::AutoScaling::AutoScalingGroup]
    #
    def get_autoscaling_group_by_name(asg_name)
      log.debug("describe-auto-scaling-groups named #{asg_name.inspect}")
      found = autoscaling.groups(auto_scaling_group_names: [asg_name]).to_a
      if found.length > 1
        raise ManyFound.new('Found multiple groups: ' + found.inspect)
      end
      if found.empty?
        raise NotFound.new("No groups found for name: #{asg_name.inspect}")
      end

      found.first
    end

    # @param [String, nil] name_prefix
    # @param [Boolean] skip_stateful Whether to skip groups that have the
    #   "stateful" tag set
    # @param [Boolean] skip_zero Whether to skip groups that have desired count
    #   set to 0
    # @return [Array<Aws::AutoScaling::AutoScalingGroup>]
    def list_autoscaling_groups(name_prefix: nil, skip_stateful: false,
                                skip_zero: false)
      msg = 'describe-auto-scaling-groups'
      msg += " with prefix #{name_prefix.inspect}" if name_prefix
      msg += ', skipping stateful groups' if skip_stateful
      msg += ', skipping empty groups' if skip_zero
      log.debug(msg)

      groups = autoscaling.groups.to_a

      if name_prefix
        groups = groups.find_all { |g| g.name.start_with?(name_prefix) }
      end

      if skip_stateful
        groups.reject! do |g|
          if g.tags.any? { |t| t.key == 'stateful' }
            log.warn("Skipped #{g.name.inspect} because stateful tag is set")
            true
          end
        end
      end

      if skip_zero
        groups.reject! do |g|
          if g.desired_capacity == 0
            log.warn("Skipped #{g.name.inspect} due to desired capacity of 0")
            true
          end
        end
      end

      groups
    end

    # @param asg_name [String]
    # @return [Array<Aws::AutoScaling::ScheduledAction>]
    #
    def get_autoscaling_scheduled_actions(asg_name)
      log.debug("describe-scheduled-actions for ASG #{asg_name.inspect}")
      autoscaling.scheduled_actions(auto_scaling_group_name: asg_name).to_a
    end

    # @param [String] asg_name
    # @param [Integer] count
    def set_desired_capacity(asg_name, count)
      unless count.is_a?(Integer)
        raise ArgumentError.new("Invalid count: #{count.inspect}")
      end
      log.debug("Updating ASG #{asg_name.inspect} desired count to #{count}")
      autoscaling.client.update_auto_scaling_group(
        auto_scaling_group_name: asg_name,
        desired_capacity: count
      )
    end

    def create_scheduled_action(asg_name, action_name, start_time:,
                                desired_capacity: nil, min_size: nil,
                                max_size: nil)

      unless desired_capacity || min_size || max_size
        raise ArgumentError.new(
          'Must pass at least one of desired_capacity, min_size, max_size'
        )
      end

      params = {
        auto_scaling_group_name: asg_name,
        scheduled_action_name: action_name,
        start_time: start_time,
      }

      params[:desired_capacity] = desired_capacity if desired_capacity
      params[:min_size] = min_size if min_size
      params[:max_size] = max_size if max_size

      log.debug("Creating scheduled action: #{params.inspect}")

      autoscaling.client.put_scheduled_update_group_action(params)
    end
  end
end
