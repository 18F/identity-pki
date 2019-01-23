class InfinitePolicyMappingDepth
  def value
    :any
  end

  def negative?
    false
  end

  def any?
    true
  end

  # :reek:UtilityFunction
  def <=>(other)
    if other.any?
      0
    else
      1
    end
  end

  def -(_other)
    self
  end
end
