
require_relative 'rdparse'
require_relative 'nodes'




#Structured Queryless Language
#Superb Quality Language
class SimpleQuerylessLanguage
  def initialize
    @parser = Parser.new("SQL") do


      #multi word tokens before whitespace

      token(/DEFINE\s+FUNCTION/)  {:define_func}
      token(/END\s+WHILE/)        {:end_while}
      token(/END\s+FOR/)          {:end_for}
      token(/END\s+IF/)           {:end_if}
      token(/END\s+FUNCTION/)     {:end_func}
      token(/ELSE\s+IF/)          {:elif}
      token(/FOR\s+EACH/)         {:for_each}
      token(/NOT\s+EQUAL/)        {:not_equal}
      token(/GREATER\s+THAN/)     {:greater_than}
      token(/LESS\s+THAN/)        {:less_than}
      token(/MULTIPLIED\s+BY/)    {:mult_by}
      token(/DIVIDED\s+BY/)       {:div_by}
      token(/\s+/)
      token(/\d+\.\d+/)           {|m| m.to_f}
      token(/\d+/)                {|m| m.to_i}
      token(/"[^"]*"/)            {|m| m}
      token(/\bSET\b/)            {:set}
      token(/\bTO\b/)             {:to}
      token(/\bADD\b/)            {:add}
      token(/\bSUBTRACT\b/)       {:sub}
      token(/\bFROM\b/)           {:from}
      token(/\bPLUS\b/)           {:plus}
      token(/\bMINUS\b/)          {:minus}
      token(/\bDISPLAY\b/)        {:display}
      token(/\bWHILE\b/)          {:while}
      token(/\bIF\b/)             {:if}
      token(/\bELSE\b/)           {:else}
      token(/\bFOR\b/)            {:for}
      token(/\bIN\b/)             {:in}
      token(/\bRETURN\b/)         {:return}
      token(/\bWITH\b/)           {:with}
      token(/\bAND\b/)            {:and}
      token(/\bOR\b/)             {:or}
      token(/\bNOT\b/)            {:not}
      token(/\bEQUAL\b/)          {:equal}
      token(/\bGIVING\b/)         {:giving}
      token(/\bTRUE\b/)           {:true}
      token(/\bFALSE\b/)          {:false}
      token(/\bAT\b/)             {:at}          
      token(/[,\[\]()]/)          {|m| m}
      token(/[a-zA-Z][a-zA-Z0-9_]*/)  {|m| m}

      #########
      #Grammar#
      #########

      start :program do
        match(:stmts) {|s| ProgramNode.new(s)}
      end

      rule :stmts do
        match(:stmt) {|s| [s]}
        match(:stmts, :stmt) {|ss, s| ss << s; ss}
      end

      rule :stmt do
        match(:add_to)
        match(:sub_from)
        match(:assign)
        match(:display_stmt)
        match(:while_loop)
        match(:if_stmt)
        #match(:for_each_loop)
        match(:func_def)
        match(:return_stmt)
        match(:expr)
      end



      ############
      #STATEMENTS#
      ############

      # [ SET __ TO __ ] [ __ GIVING __ ]
      rule :assign do
        match(:set, :ident, :to, :expr) {|_, name, _, e| AssignNode.new(name, e)}
        match(:expr, :giving, :ident)   {|e, _, name| AssignNode.new(name, e)}
      end

      # [ ADD __ TO __ ]
      rule :add_to do
        match(:add, :expr, :to, :ident) {|_, e, _, name| AddToNode.new(name, e)}
      end

      # [ SUBTRACT __ FROM __ ]
      rule :sub_from do
        match(:sub, :expr, :from, :ident) {|_, e, _, name| SubFromNode.new(name, e)}
      end 

      # [ DISPLAY __(, __, ..) ]
      rule :display_stmt do
        match(:display, :expr_list) {|_, exprs| DisplayNode.new(exprs)}
      end

      rule :expr_list do
        match(:expr)                    {|e| [e]}
        match(:expr_list, ',', :expr)   {|list, _, e| list << e; list}
      end

      

      # [ WHILE __  ]
      # [    ...    ]
      # [ END WHILE ]
      rule :while_loop do
        match(:while, :expr, :stmts, :end_while) {|_, cond, stmts, _| WhileNode.new(cond, stmts)}
      end

      # [ IF __       ]
      # [     ...     ]
      # [ ELSE IF  __ ]
      # [     ...     ]
      # [ ELSE        ]
      # [     ...     ]
      # [ END IF      ]
      rule :if_stmt do
        match(:if, :expr, :stmts, :else_ifs, :else, :stmts, :end_if) {|_, cond, stmts, elifs, _, else_stmts, _| IfNode.new(cond, stmts, elifs, else_stmts)}
        match(:if, :expr, :stmts, :else_ifs, :end_if) {|_, cond, stmts, elifs, _| IfNode.new(cond, stmts, elifs, nil)}
        match(:if, :expr, :stmts, :else, :stmts, :end_if) {|_, cond, stmts,  _, else_stmts, _| IfNode.new(cond, stmts, [], else_stmts)}
        match(:if, :expr, :stmts, :end_if) {|_, cond, stmts, _| IfNode.new(cond, stmts, [], nil)}
      end

      rule :else_ifs do
        match(:elif, :expr, :stmts) {|_, cond, stmts| [[cond, stmts]]}
        match(:else_ifs, :elif, :expr, :stmts) {|list, _, cond, stmts| list << [cond, stmts]; list}
      end

      # [ FOR EACH __ IN __ ]
      # [        ...        ]
      # [ END FOR           ]
      # -------------------------------------------------------------------------------------------------------------- #



      # -------------------------------------------------------------------------------------------------------------- #
      
      # [ DEFINE FUNCTION __ (WITH __(, __, ..)) ]
      # [                 ...                    ]
      # [ END FUNCTION                           ]
      rule :func_def do
        match(:define_func, :ident, :with, :param, :stmts, :end_func) {|_, name, _, params, stmts, _| FuncDefNode.new(name, params, stmts)}
        match(:define_func, :ident, :stmts, :end_func) {|_, name, stmts, _| FuncDefNode.new(name, [], stmts)}
      end

      rule :param do
        match(:ident) {|id| [id]}
        match(:param, ',', :ident) {|list, _, id| list << id; list}
      end

      rule :return_stmt do
        match(:return, :expr) {|_, e| ReturnNode.new(e)}
      end





      #############
      #EXPRESSIONS#
      #############
      


      # Binary operations
      rule :expr do
        match(:or_expr)
      end

      rule :or_expr do
        match(:or_expr, :or, :and_expr) {|l, _, r| BinaryOpNode.new(l, :or, r)}
        match(:and_expr)
      end

      rule :and_expr do
        match(:and_expr, :and, :not_expr) {|l, _, r| BinaryOpNode.new(l, :and, r)}
        match(:not_expr)
      end

      rule :not_expr do
        match(:not, :not_expr) {|_, e| NotNode.new(e)}
        match(:comp)
      end

      rule :comp do
        match(:ari_expr, :less_than, :ari_expr) {|l, _, r| BinaryOpNode.new(l, :less_than, r)}
        match(:ari_expr, :greater_than, :ari_expr) {|l, _, r| BinaryOpNode.new(l, :greater_than, r)}
        match(:ari_expr, :equal, :ari_expr) {|l, _, r| BinaryOpNode.new(l, :equal, r)}
        match(:ari_expr, :not_equal, :ari_expr) {|l, _, r| BinaryOpNode.new(l, :not_equal, r)}
        match(:ari_expr)
      end

      rule :ari_expr do
        match(:ari_expr, :plus, :mult_expr) {|l, _, r| BinaryOpNode.new(l, :plus, r)}
        match(:ari_expr, :minus, :mult_expr) {|l, _, r| BinaryOpNode.new(l, :minus, r)}
        match(:mult_expr)
      end

      rule :mult_expr do
        match(:mult_expr, :mult_by, :factor) {|l, _, r| BinaryOpNode.new(l, :multiply, r)}
        match(:mult_expr, :div_by, :factor) {|l, _, r| BinaryOpNode.new(l, :divide, r)}
        match(:factor)
      end

      rule :factor do
        match('(', :expr, ')') {|_, e, _| e}
        match(Float) {|n| NumberNode.new(n)}
        match(Integer) {|n| NumberNode.new(n)}
        match(/"[^"]*"/) {|s| StringNode.new(s[1..-2])}
        match(:true) {BoolNode.new(true)}
        match(:false) {BoolNode.new(false)}
        match(:factor, :at, :expr) {|list, _, ind| IndexNode.new(list, ind)}    #token AT
        match('[', :expr_list, ']') {|_, exprs, _| ListNode.new(exprs)}
        match('[',  ']') {ListNode.new([])}
        match(:func_call) 
        match(:ident) {|name| NameNode.new(name)}
      end


      # Function call
      rule :func_call do
        match(:ident, :with, :arg_list) {|name, _, args| FuncCallNode.new(name, args)}
      end

      rule :arg_list do
        match(:expr) {|e| [e]}
        match(:arg_list, ',', :expr) {|list, _, e| list << e; list}
      end

      rule :ident do
        match(/[a-zA-Z][a-zA-Z0-9_]*/) {|m| m}
      end
    end
  end


  def run(code)
    program = @parser.parse(code)
    program.evl
  rescue ReturnSignal => r
    r.value
  rescue => e
    puts "ERROR: #{e.message}"
  end



  def interactive
    puts "Simple Queryless Language Interactive Mode. Type 'quit' to exit."
    loop do
      print ">> "
      input = gets&.chomp
      break if input.nil? || input.strip == 'quit'
      next if input.strip.empty?
      begin
        @parser.parse(input).evl
      rescue => e
        puts "ERROR #{e.message}"
      end
    end
  end

  def log(on = true)
    @parser.logger.level = on ? Logger::DEBUG : Logger::WARN
  end
end

if $PROGRAM_NAME == __FILE__
  lang = SimpleQuerylessLanguage.new
  
  if ARGV[0]
    lang.run(File.read(ARGV[0]))

  else
  lang.interactive
  end
end





        


        
      




