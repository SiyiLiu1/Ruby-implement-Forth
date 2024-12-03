# Siyi Liu V00951684

class ForthInterpreter
  def initialize
    @stack = []
    @error_exist = false    # flag of wether should print ok or not

    @do_loop = false  # signal for if it's in for (DO...LOOP) loop
    @i_ind = -1 # index for for (DO...LOOP) loop

    @heap_var_address = 1000  # inital value for heap memory
    @heap_dict = {}   # {memory1:value1...memoryN:valueN}

    @dictionary = {
      "+" => -> { basic_opration("+") },      # @stack: bottom[a,b]top: + => bottom[a+b]top
      "-" => -> { basic_opration("-")},       # @stack: bottom[a,b]top: - => bottom[a-b]top
      "*" => -> { basic_opration("*")},       # @stack: bottom[a,b]top: * => bottom[a*b]top
      "/" => -> { basic_opration("/") },      # @stack: bottom[a,b]top: / => bottom[a/b]top,   if b == 0, print a error message
      "MOD" => -> { basic_opration("%") },    # @stack: bottom[a,b]top: "mod" => bottom[a%b]top, if b == 0, print a error message
      "DUP" => -> { one_ele_ops("DUP") },     # @stack: bottom[a,b]top: "DUP" => bottom[a,b,b]top
      "SWAP" => -> { two_ele_ops("SWAP") },   # @stack: bottom[a,b]top: "SWAP" => bottom[b,a]top
      "DROP" => -> { one_ele_ops("DROP")},    # @stack: bottom[a,b]top: "DROP" => bottom[a]top
      "DUMP" => -> { puts @stack.inspect },   # print the @stack without modifying @stack
      "OVER" => -> { two_ele_ops("OVER") },   # @stack: bottom[a,b]top: "OVER" => bottom[a,b,a]top
      "ROT" => -> {if enough_arg(3); a, b, c = @stack.pop(3); @stack.push(b, c, a);end},  # @stack: bottom[a,b,c]top: "ROT" => bottom[b,c,a]top
      "." => -> { one_ele_ops(".")},          # @stack: bottom[a,b]top: "." => bottom[a]top and print b as a int
      "EMIT" => -> { one_ele_ops("EMIT")},    # pops the TOS and prints the value as an ASCII character
      "CR" => -> { puts },                    # prints a newline
      "=" => -> { two_ele_ops("=") },         # @stack: bottom[a,b]top: pop a and b, @stack[-1] if a == b, otherwise @stack[0]
      "<" => -> { two_ele_ops("<") },         # @stack: bottom[a,b]top: pop a and b, @stack[-1] if a < b, otherwise @stack[0]
      ">" => -> { two_ele_ops(">") },         # @stack: bottom[a,b]top: pop a and b, @stack[-1] if a > b, otherwise @stack[0]
      "AND" => -> { basic_opration("&") },    #  pop two elements from the TOS and push back bitwise and
      "OR" => -> { basic_opration("|")},      #  pop two elements from the TOS and push back bitwise or
      "XOR" => -> {basic_opration("^")},      #  pop two elements from the TOS and push back bitwise xor
      "INVERT" => -> { one_ele_ops("INVERT") }, #  pops a value from the TOS and pushes its bitwise negation (inversion) back
    }
  end

  def run
    loop do
      begin
        multi_line = false
        definde_new = false
        loop_dict = {}
        print "> "
        line = gets.chomp # gets.encode("UTF-8", "GBK")

        if line.start_with?(":") && !line.include?(";") # multiple line define new key and process
          definde_new = true
          input = line.clone + " "
          loop do
            line = gets.chomp
            input += line + " "
            break if line.include?(";")
          end
          execute_line(input)
        elsif line.start_with?(":")                   # single line case for define new key and process
          definde_new = true
          execute_line(line)
        end

        if !definde_new
          if line.include?(".\"") && (line.rindex("\"") <= line.rindex(".\"")+1)   # multiple line string
            loop_dict[:string_index] = line.index(/\s.\"\s/i)
            multi_line = true
          end
          if line =~ /\sif\s/i &&                                             # multiple line IF...ELSE...THEN,
            line.scan(/\b#{"if"}\b/i).length > line.scan(/\b#{"then"}\b/i).length  # number of "if" > number of "then"
            loop_dict[:if_index] = line.index(/\sif\s/i)
            multi_line = true
          end
          if line =~ /\sbegin\s/i &&                                             # mutiple line BEGIN...UNTIL
            line.scan(/\b#{"begin"}\b/i).length > line.scan(/\b#{"until"}\b/i).length # number of "begin" > number of "until"
            loop_dict[:begin_index] = line.index(/\sbegin\s/i)
            multi_line = true
          end
          if line =~ /\sdo\s/i &&                                              # mutiple line DO...LOOP
            line.scan(/\b#{"do"}\b/i).length > line.scan(/\b#{"loop"}\b/i).length   # number of "do" > number of "loop"
            loop_dict[:do_index] = line.index(/\sdo\s/i)
            multi_line = true
          end
        end

        if !definde_new && multi_line          # multi-line string, if.., begin..., do...
          first_appear = loop_dict.values.min
          first_key = loop_dict.select { |k, v| v == first_appear }.keys.first
          first_key = first_key.to_s
          if first_key == "string_index"
            gets_string(line)
          elsif first_key == "if_index"
            gets_if(line)
          elsif first_key == "begin_index"
            gets_begin(line)
          else
            gets_do(line)
          end

        elsif !definde_new && !multi_line         # All other single line case
          break if line.nil?
          break if line.strip.downcase == "exit" || line.strip.downcase == "quit"
          execute_line(line)
        end

        if !@error_exist                         # no error, print "ok"
          puts "ok"
        else                                     # have error, then change error status for next input
          @error_exist = false
        end
      rescue => error
        # Handle error but don't exit the loop
        puts "error: #{error.message}"
      end
    end
  end



  private

  def gets_string(line)
    input = line.clone
    loop do
      line = gets.chomp
      input += "\n" + line
      break if (line.include?("\"") && !line.include?(".\"")) ||
      (line.include?(".\"") && (line.rindex("\"") > (line.rindex(".\"")+1)))
    end
    execute_line(input)
  end

  def gets_if(line)
    input = line.clone + " "
    loop do
      line = gets.chomp
      input += line + " "
      break if input.scan(/\b#{"if"}\b/i).length <= input.scan(/\b#{"then"}\b/i).length
    end
    execute_line(input)
  end

  def gets_begin(line)
    input = line.clone + " "
    loop do
      line = gets.chomp
      input += line + " "
      break if input.scan(/\b#{"begin"}\b/i).length <= line.scan(/\b#{"until"}\b/i).length
    end
    execute_line(input)
  end

  def gets_do(line)
    input = line.clone + " "
    loop do
      line = gets.chomp
      input += line + " "
      break if input.scan(/\b#{"do"}\b/i).length <= line.scan(/\b#{"loop"}\b/i).length
    end
    execute_line(input)
  end



  def execute_line(line)
    in_sentence = false # flag to indicate if we're defining a new word

    sentence = ''    # build a new string when encounter ."
    new_line = false # output a new line when in the end of the sentence

    comment = false # ignore all comment inside ()

    # All Loops: IF ...ELSE...THEN, DO I...LOOP,
    ignore_symble = false
    all_stop = -1 # some word need to be ignored
    exc_content = '' # pick excute if or else statement

    @while_var = 0 # @while_var = 0  # inital value for control while (BEGIN...UNTIL) loop

    #  Variables and constants
    new_var = false # switch to control weither definde a new variable
    new_constant = false # switch to control weither definde a new constant

    words = line.strip.split(' ')
    words.each_with_index do |word, index|
      upper = word.upcase
        if (upper == "IF") ||  (upper == "ELSE") || (upper == "THEN")||
          (upper == "DO") ||  (upper == "I") ||  (upper == "LOOP")||
          (upper == "BEGIN") ||  (upper == "UNTIL") ||
          (upper == "VARIABLE") || (upper == "CONSTANT") || (upper == "CELLS") || (upper == "ALLOT")

          words[index] = upper # ALL keyword need to be upper case
        end
      end
    words.each_with_index do |word, index|
      if @error_exist
        break
      end
      if !in_sentence # inside string words do nothing
        if !comment
          upper = word.upcase
          if index == all_stop
            ignore_symble = false
          elsif ignore_symble
            next
          elsif @do_loop && word == "I"
            @stack.push(@i_ind)
          elsif new_var
            cur_address = @heap_var_address
            @dictionary[upper] = -> {@stack.push(cur_address)}
            @heap_dict[cur_address] = 0
            @heap_var_address += 1
            new_var = false

          elsif new_constant
            if enough_arg(1)
              @dictionary[upper] = -> {@stack.push(@stack.pop)}
            end
            new_constant = false

          elsif word == "VARIABLE"
            new_var = true

          elsif word == "!"
            if enough_arg(2)
              heap_add = @stack.pop
              if heap_add < 1000
                @error_exist = true
                puts "error: not exist address: " + heap_add.to_s
              else
                @heap_dict[heap_add] = @stack.pop
              end
            end
          elsif word == "?"
            if enough_arg(1)
              heap_add = @stack.pop
              if heap_add < 1000
                @error_exist = true
                puts "error: not exist address: " + heap_add.to_s
              else
                heap_var = @heap_dict[heap_add]
                print heap_var.to_s + " "
              end
            end

          elsif word == "@"
            if enough_arg(1)
              heap_add = @stack.pop
              if heap_add < 1000
                @error_exist = true
                puts "error: not exist address: " + heap_add.to_s
              else
                heap_var = @heap_dict[heap_add]
                @stack.push(heap_var)
              end
            end

          elsif word == "CELLS"
            next

          elsif word == "ALLOT"
            if enough_arg(1)
              @heap_var_address += @stack.pop
            end
          elsif word == "CONSTANT"
            new_constant = true

          elsif word == '."' # start of string sentence
            in_sentence = true

          elsif word == '('
            comment = true

          elsif @dictionary[upper]
            @dictionary[upper].call()

          elsif word.=~(/^-?\d+(\.\d+)?$/) # integer or decimal sentence
            @stack.push(word.to_i)

          elsif word == ':'
            define_word(words)
            ignore_symble = true

          elsif word == 'IF'
            if enough_arg(1)
              condition = @stack.pop
              all_stop = words.rindex("THEN")

              if words.index("ELSE") != nil
                if condition != 0
                  exc_content =words[words.index(word) + 1..words.index("ELSE") - 1].join(" ")
                  execute_line(exc_content)
                else
                  exc_content = exc_string(words, "ELSE", "THEN")
                  execute_line(exc_content)
                end
              else
                if condition != 0
                  exc_content = exc_string(words, "IF", "THEN")
                  execute_line(exc_content)
                else
                  all_stop = words.rindex("THEN")
                  ignore_symble = true
                end
              end

              ignore_symble = true
            end

          elsif word == 'DO'
            if enough_arg(2)
              end_val,begin_val = @stack.pop(2)
              all_stop = words.rindex("LOOP")
              exc_content = exc_string(words, word, "LOOP")
              for @i_ind in begin_val..end_val-1 do
                @do_loop = true
                execute_line(exc_content)
              end
              ignore_symble = true
              @do_loop = false
            end

          elsif word == 'I'
            @error_exist = true
            puts "error 'I' outside the DO...LOOP construct"

          elsif word == 'BEGIN'
            all_stop = words.rindex("UNTIL")
            exc_content = exc_string(words, word, "UNTIL")
            while @while_var!=-1 do
              execute_line(exc_content)
              if enough_arg(1)
                @while_var = @stack.pop
              end
            end
            ignore_symble = true
          else
            puts "error: unknown input keyword '#{word}'"
            @error_exist = true

          end

        else
          if word == ")"
            comment = false
          end
        end
      else
        sentence << " #{word}"
        if word.end_with?('"')
          new_line = true
          print sentence[1..-2] # remove surrounding quotes
          sentence = ''
          in_sentence = false
        end
      end
    end
    if new_line
      puts
    end
    return true
  end

  def exc_string(arr, begin_word,end_word)
    # pull out all key info from arr array and makes it string
    arr[(arr.index(begin_word)+1)..(arr.rindex(end_word)-1)].join(' ')
  end


  def define_word(words)
    # define a new keyword with excuteble content
    words.shift
    name = words.shift.upcase
    body = []
    comment = false
    while words.first != ';'
      each = words.shift
      if !comment
        if each != "("
          body.push(each)
        else
          comment = true
        end
      else
        if each == ")"
          comment = false
        end
      end
    end
    @dictionary[name] = lambda do
      execute_line(body.join(' '))
    end
  end

  def enough_arg(need)
    # check if pop's argument is enough for an process
    if @stack.length >= need
      true
    elsif @stack.empty?
      puts "error: empty stack"
      @error_exist = true
      false
    else
      puts "error: not enough elements in the stack"
      @error_exist = true
      false
    end
  end

  def basic_opration(sign)
    if enough_arg(2)
      a, b = @stack.pop(2)
      sign = sign.to_sym
      @stack.push(a.send(sign, b))
    end
  end

  def one_ele_ops(ops)
    if enough_arg(1)
      if ops == "."
        print @stack.pop.to_i.to_s + ' '
      elsif ops == "DUP"
        @stack.push(@stack.last)
      elsif ops == "DROP"
        @stack.pop
      elsif ops == "EMIT"
        print @stack.pop.to_i.chr
      elsif ops == "INVERT"
        @stack.push(~@stack.pop.to_s.to_i)
      end
    end
  end

  def two_ele_ops(ops)
    if enough_arg(2)
      a, b = @stack.pop(2)
      if ops == "SWAP"
        @stack.push(b, a)
      elsif ops == "OVER"
        @stack.push(a, b, a)
      elsif ops == "="
        @stack.push(a == b ? -1 : 0)
      elsif ops == "<"
        @stack.push(a < b ? -1 : 0)
      elsif ops == ">"
        @stack.push(a > b ? -1 : 0)
      end
    end
  end

end


forth = ForthInterpreter.new
forth.run
