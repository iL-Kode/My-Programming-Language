

#Handle variables, functions, scopes
#Hash, stacked

module ScopeManager

  def push_scope
    $scope_stack.push ({})
    $func_stack.push({})
  end

  def pop_scope
    $scope_stack.pop
    $func_stack.pop
  end

  def set_var(name, value)
    $scope_stack.reverse_each do |scope|
      if scope.key?(name)
        scope[name] = value
        return value
      end
    end
    $scope_stack.last[name] = value
    value
  end

  def get_var(name)
    $scope_stack.reverse_each do |scope|
      return scope[name] if scope.key?(name)
    end
    raise "VARIABLE UNDEFINED"
  end

  def set_func(name, node)
    $func_stack.last[name] = node
  end

  def get_func(name)
    $func_stack.reverse_each do |scope|
      return scope[name] if scope.key?(name)
    end
    nil
  end
end
