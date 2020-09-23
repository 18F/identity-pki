class FinitePolicyMappingDepth
  attr_reader :value

  def initialize(value)
    @value = value.to_i
  end

  def negative?
    @value.negative?
  end

  def any?
    false
  end

  def <=>(other)
    if other.any?
      -1
    else
      value <=> other.value
    end
  end

  def -(other)
    FinitePolicyMappingDepth.new(value - other)
  end
end
