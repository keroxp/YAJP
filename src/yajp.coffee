YAJP =
  OPEN_BRACKET  : '['
  CLOSE_BRACKET : ']'
  OPEN_PAREN    : '{'
  CLOSE_PAREN   : '}'
  DOUBLE_QUOTE  : '"'
  SINGLE_QUOTE  : "'"
  COLON_TOKEN   : ':'
  COMMA_TOKEN   : ','
  PERIOD_TOKEN  : '.'
  MINUS_TOKEN   : '-'
  NULL_CHARACTER: '\0'
  symbols: ['[',']','{','}','"',"'",':',',',".","-"]
  spaces: [' ','\n','\r','\t']
  separators: ['}',']',',',':','\0']
  TRUE_IDENTIFIER   : 'true'
  FALSE_IDENTIFIER  : 'false'
  NULL_IDENTIFIER   : 'null'
  TOKEN_TYPE_SYMBOL : 'SYMBOL'
  TOKEN_TYPE_STRING : 'STRING'
  TOKEN_TYPE_NUMBER : 'NUMBER'
  TOKEN_TYPE_BOOL   : 'BOOL'
  TOKEN_TYPE_NULL   : 'NULL'
  Token: (val,type) -> {"val": val, "type": type}
  isSpace           : (c)   -> c in @spaces                 # is skippable?
  isSeparator       : (c)   -> c in @separators             # is separator? '}', ']' , ',', ':'
  isIdentifier      : (c)   -> !!c.match(/[a-z]/)           # is identifier?
  isNumber          : (c)   -> !!c.match(/[0-9]/)           # 0 ~ 9
  isSymbol          : (c)   -> c in @symbols                # symbol
  isQuote           : (c)   -> c in [@DOUBLE_QUOTE,@SINGLE_QUOTE] # ' or "
  isNumberComponent : (c)   -> c in [@MINUS_TOKEN,@PERIOD_TOKEN] or @isNumber(c) # -, ., 0~9
  isValueToken      : (tok) -> tok.type in [@TOKEN_TYPE_STRING,@TOKEN_TYPE_BOOL,@TOKEN_TYPE_NUMBER,@TOKEN_TYPE_NULL] # string, number, bool, null
  isSymbolToken     : (tok) -> tok.type is @TOKEN_TYPE_SYMBOL # is symbol token?
  nextChar: ->  # get next character
    if @location < @jsonstr.length - 1
      @jsonstr.charAt(++@location)
    else if @location is @jsonstr.length - 1
      @NULL_CHARACTER
    else
      throw new Error "out of range"
  nextValidChar: ->
    loop return c unless @isSpace((c = @nextChar()))  # skip spaces
  backStep: -> --@location
  nextIdentifier: ->
    id = ""
    loop
      c = @nextValidChar()
      if @isSeparator(c)
        @backStep()
        return id
      else if !@isIdentifier(c)
        throw new Error "expected identifier but #{c}"
      else
        id += c
  nextString: ->
    str = ""
    loop
      if @isQuote((c = @nextChar()))
        d = @nextValidChar()
        @backStep()
        return str if @isSeparator(d)
      else
        str += c
  nextNumber: ->
    num = ""
    loop
      c = @nextValidChar()
      if @isSeparator(c)
        @backStep()
        return num
      else if !@isNumberComponent(c)
        throw new Error "expected number but #{c}"
      else
        num += c
  # next token, symbol, number, string, identifier
  nextToken: ->
    c = @nextValidChar()
    # console.log c
    if @isNumberComponent(c)
      @Token(Number(c+@nextNumber()), @TOKEN_TYPE_NUMBER)     # number
    else if @isQuote(c)
      @Token(@nextString(), @TOKEN_TYPE_STRING)               # string
    else if @isSymbol(c)
      @Token(c, @TOKEN_TYPE_SYMBOL)                           # symbol
    else
      throw new Error "expected identifier" if @isNumber(c)
      switch (id = c + @nextIdentifier())                     # identifier
        when @FALSE_IDENTIFIER
          @Token(false, @TOKEN_TYPE_BOOL)
        when @TRUE_IDENTIFIER
          @Token(true, @TOKEN_TYPE_BOOL)
        when @NULL_IDENTIFIER
          @Token(null, @TOKEN_TYPE_NULL)
        else
          throw new Error "unexpected identifier '#{id}'"
  # extract value from Token
  extractValue: (tok) ->
    if @isValueToken(tok)
      tok.val
    else if @isSymbolToken(tok)
      switch tok.val
        when @OPEN_BRACKET
          @nextArray()
        when @OPEN_PAREN
          @nextObject()
        else
          throw new Error "expected { or [ but #{tok.val}"
    else
      throw new Error "unexpected token #{tok.val}"
  # next object
  nextObject: ->
    obj = {}
    loop
      if (tok = @nextToken()).val is @CLOSE_PAREN
        return obj
      else
        throw new Error "expected string but #{tok.val}" unless tok.type is @TOKEN_TYPE_STRING
        key = tok.val
        tok = @nextToken()
        throw new Error "expected : but #{tok.val}" unless tok.val is @COLON_TOKEN
        obj[key] = @extractValue(@nextToken())
        tok = @nextToken()
        return obj if tok.val is @CLOSE_PAREN
        throw new Error "expected , but #{tok.val}" unless tok.val is @COMMA_TOKEN
  # next array
  nextArray: ->
    arr = []
    loop
      if (tok = @nextToken()).val is @CLOSE_BRACKET
        return arr
      else
        arr.push(@extractValue(tok))
        tok = @nextToken()
        return arr if tok.val is @CLOSE_BRACKET
        throw new Error "expected , but #{tok.val}" unless tok.val is @COMMA_TOKEN
  # parse
  parse: (str) ->
    @jsonstr = str
    @location = -1
    @extractValue(@nextToken())
# export
module.exports = YAJP