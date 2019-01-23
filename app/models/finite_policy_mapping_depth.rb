class FinitePolicyMappingDepth
  attr_reader :value

  # :reek:FeatureEnvy
  def initialize(value)
    @value = value.to_i
  end

  def negative?
    @value.negative?
  end

  def any?
    false
  end

  # :reek:FeatureEnvy
  def <=>(other)
    value <=> other.value
  end

  def -(other)
    FinitePolicyMappingDepth.new(value - other)
  end
end
