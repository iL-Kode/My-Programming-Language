
require_relative 'modules'



$scope_stack = [{}]
$func_stack = [{}]


class ReturnSignal < StandardError
  attr_reader :value
  def initialize(value)
    @value = value
  end
end

#####
#TOP#
#####

class ProgramNode
  def initialize(stmts)
    @stmts = stmts
  end
  
  def evl
    @stmts.each(&:evl)
  end
end


####
#IO#
####

class DisplayNode
  def initialize(exprs)
    @exprs = exprs
  end
  def evl
    output = @exprs.map(&:evl).map(&:to_s).join(" ")
    puts output
    output
  end
end


###########
#VARIABLES#
###########

class AssignNode
  include ScopeManager

  def initialize(name, expr)
    @name = name
    @expr = expr
  end

  def evl
    set_var(@name, @expr.evl)
  end
end

class AddToNode
  include ScopeManager

  def initialize(name, expr)
    @name = name
    @expr = expr
  end

  def evl
    set_var(@name, get_var(@name) + @expr.evl)
  end
end

class SubFromNode
  include ScopeManager
  def initialize(name, expr)
    @name = name
    @expr = expr
  end
  def evl
    set_var(@name, get_var(@name) - @expr.evl)
  end
end


######
#LOOP#
######

class WhileNode
  include ScopeManager

  def initialize(cond, stmts)
    @cond = cond
    @stmts = stmts
  end

  def evl
    push_scope
    while @cond.evl
      @stmts.each(&:evl)
    end
    pop_scope
  end
end



####
#IF#
####

class IfNode
  include ScopeManager
  def initialize(cond, then_s, elif, else_s)
    @cond = cond
    @then_s = then_s
    @elif = elif
    @else_s = else_s
  end

  def evl
    push_scope
    begin
      if @cond.evl
        run_block(@then_s)
      else
        matched = @elif.find {|cond, _| cond.evl}
        if matched
          run_block(matched[1])
        elsif @else_s
          run_block(@else_s)
        end
      end
    ensure
      pop_scope
    end
  end


  private
  def run_block(stmts)
    stmts.each(&:evl)
  end
end



######
#FUNC#
######

class FuncDefNode
  include ScopeManager

  def initialize(name, params, stmts)
    @name = name
    @params = params
    @stmts = stmts
  end

  #register in the current scope
  def evl
    set_func(@name, self)
  end

  #functinon call
  def call(args)
    unless args.size == @params.size
      raise "EXPECTED PARAMETERS: #{@params.size}"
    end

    push_scope
    @params.each_with_index {|p, i| $scope_stack.last[p] = args[i]}
    result = nil

    begin
      @stmts.each(&:evl)
    rescue ReturnSignal => r
      result = r.value
    ensure
      pop_scope
    end

    result
  end
end

class FuncCallNode
  include ScopeManager
  def initialize(name, args)
    @name = name
    @args = args
  end

  def evl
    func = get_func(@name)
    raise "NOT DEFINED FUNCTION" unless func
    func.call(@args.map(&:evl))
  end
end

class ReturnNode
  def initialize(expr)
    @expr = expr
  end

  def evl
    raise ReturnSignal.new(@expr.evl)
  end
end



#############
#EXPRESSIONS#
#############


class BinaryOpNode
  def initialize(left, op, right)
    @left = left
    @op = op
    @right = right
  end

  def evl
    l = @left.evl
    r = @right.evl

    case @op
    when :plus then l + r
    when :minus then l - r
    when :multiply then l * r
    when :divide
      raise "DIVISION BY ZERO" if r == 0
      result = l.to_f / r
    when :less_than then l < r
    when :greater_than then l > r
    when :equal then l == r
    when :not_equal then l != r
    when :and then l && r
    when :or then l || r
    end
  end
end


class NotNode
  def initialize(expr)
    @expr = expr
  end
  def evl
    !@expr.evl
  end
end


class NumberNode
  def initialize(val)
    @val = val
  end
  def evl
    @val
  end
end

class StringNode 
  def initialize(val)
    @val = val
  end
  def evl
    @val
  end
end

class BoolNode 
  def initialize(val)
    @val = val
  end
  def evl
    @val
  end
end

class ListNode 
  def initialize(exprs)
    @exprs = exprs 
  end
  def evl
    @exprs.map(&:evl)
  end
end


class IndexNode
  def initialize(list, index)
    @list = list
    @index = index
  end

  def evl
    arr = @list.evl
    i = @index.evl
    raise "INDEX ERROR" if i < 1 || i > arr.size
    arr[i-1]
  end
end




#variable or function without arguments
class NameNode
  include ScopeManager
  attr_reader :name
  
  def initialize(name)
    @name = name
  end

  def evl
    $scope_stack.reverse_each do |scope|
      return scope[@name] if scope.key?(@name)
    end
    
    func = get_func(@name)
    return func.call([]) if func
    raise "UNDEFINED #{@name.inspect}"
  end
end
