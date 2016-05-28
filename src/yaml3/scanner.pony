

class _RootScanner is _Scanner
  fun ref apply(state: _ScannerState): _ScanResult ? =>
    if not state.available() then
      return ScanPaused(this)
    end
    _streamStart()
    this._scanToNextToken(state)

  fun ref _streamStart() =>
    let simpleKey = _YamlSimpleKey.create()
    /* Set the initial indentation. */
    state.indent = -1
    /* Initialize the simple key stack. */
    state.simpleKeys.push(simpleKey)
    /* A simple key is allowed at the beginning of the stream. */
    state.simpleKeyAllowed = true
    /* Create the STREAM-START token and append it to the queue. */
    let mark = state.mark.clone()
    state.emitToken(_YamlStreamStartToken(mark, mark, _YamlStreamStartTokenData(encoding)))

  /*
   * Eat whitespaces and comments until the next token is found.
   */
  fun ref _scanToNextToken(state: _ScannerState): _ScanResult ? =>
    /* Allow the BOM mark to start a line. */
    if not state.available() then
      return ScanPaused(this~_scanToNextToken())
    end
    if (state.mark.column == 0) and (state.isBom()) then
      state.skip()
    end
    this._scanToNextToken_skipWhitespaces(state)

  /*
   * Eat whitespaces.
   *
   * Tabs are allowed:
   *
   *  - in the flow context;
   *  - in the block context, but not at the beginning of the line or
   *  after '-', '?', or ':' (complex value).
   */
  fun ref _scanToNextToken_skipWhitespaces(state: _ScannerState): _ScanResult ? =>
    while (state.check(' ') or
            (((state.flowLevel > 0) or (not state.simpleKeyAllowed)) and
             state.check('\t'))) do
      state.skip()
      if not state.available() then
        return ScanPaused(this~_scanToNextToken_skipWhitespaces())
      end
    end

    if state.check('#') then
      this._scanToNextToken_skipComment(state)
    else
      this._scanToNextToken_checkLineBreak(state)
    end

  fun ref _scanToNextToken_skipComment(state: _ScannerState): _ScanResult ? =>
    while not state.isBreakZ() do
      state.skip()
      if not state.available() then
        return ScanPaused(this~_scanToNextToken_skipComment())
      end
    end
    this._scanToNextToken_checkLineBreak(state)

  fun ref _scanToNextToken_checkLineBreak(state: _ScannerState): _ScanResult ? =>
    /* If it is a line break, eat it. */
    if state.isBreak() then
      this._scanToNextToken_skipLineBreak(state)
    else
      this._scanStaleSimpleKeys(state)
    end

  fun ref _scanToNextToken_skipLineBreak(state: _ScannerState): _ScanResult ? =>
    if not state.available(2) then
      return ScanPaused(this~_scanToNextToken_skipLineBreak())
    end
    state.skipLine()
    /* In the block context, a new line may start a simple key. */
    if state.flowLevel == 0 then
      state.simpleKeyAllowed = true
    end
    this._scanToNextToken(state)

  /*
   * Check the list of potential simple keys and remove the positions that
   * cannot contain simple keys anymore.
   */
  fun ref _scanStaleSimpleKeys(state: _ScannerState): _ScanResult ? =>
    /* Check for a potential simple key for each flow level. */
    for simpleKey in state.simpleKeys do
      /*
       * The specification requires that a simple key
       *
       *  - is limited to a single line,
       *  - is shorter than 1024 characters.
       */
      if simpleKey.possible
              and ((simpleKey.mark.line < state.mark.line)
                  or ((simpleKey.mark.index + 1024) < state.mark.index)) then
          /* Check if the potential simple key to be removed is required. */
          if simpleKey.required then
              return ScanError("while scanning a simple key", simpleKey.mark, "could not find expected ':'")
          end
          simpleKey.possible = false
      end
    end
    /* Check the indentation level against the current column. */
    _unrollIndent(state, state.mark.column)
    this._scanToken(state)

  fun ref _scanToken(state: _ScannerState): _ScanResult ? =>
    /*
     * Ensure that the buffer contains at least 4 characters.  4 is the length
     * of the longest indicators ('--- ' and '... ').
    */
    if not state.available(4) then
      return ScanPaused(this~_scanToken())
    end

    /* Is it the end of the stream? */
    if state.isZ() then
      return this._scanStreamEnd(state)
    end

    /* Is it a directive? */
    if (state.mark.column == 0) and state.check('%') then
      return this._scanDirective(state)
    end

    /* Is it the document start indicator? */
    if (state.mark.column == 0)
            and state.check('-', 0)
            and state.check('-', 1)
            and state.check('-', 2)
            and state.isBlankZ(3) then
      return this._scanDocumentIndicator(YAML_DOCUMENT_START_TOKEN, state)
    end

    /* Is it the document end indicator? */
    if (state.mark.column == 0)
            and state.check('.', 0)
            and state.check('.', 1)
            and state.check('.', 2)
            and state.isBlankZ(3) then
      return this._scanDocumentIndicator(YAML_DOCUMENT_END_TOKEN, state)
    end

    /* Is it the flow sequence start indicator? */
    if state.check('[') then
      return this._scanFlowCollectionStart(YAML_FLOW_SEQUENCE_START_TOKEN, state)
    end

    /* Is it the flow mapping start indicator? */
    if state.check('{') then
      return this._scanFlowCollectionStart(YAML_FLOW_MAPPING_START_TOKEN, state)
    end

    /* Is it the flow sequence end indicator? */
    if state.check(']') then
      return this._scanFlowCollectionEnd(YAML_FLOW_SEQUENCE_END_TOKEN, state)
    end

    /* Is it the flow mapping end indicator? */
    if state.check('}') then
      return this._scanFlowCollectionEnd(YAML_FLOW_MAPPING_END_TOKEN, state)
    end

    /* Is it the flow entry indicator? */
    if state.check(',') then
      return this._scanFlowEntry(state)
    end

    /* Is it the block entry indicator? */
    if state.check('-') and state.isBlankZ(1) then
      return this._scanBlockEntry(state)
    end

    /* Is it the key indicator? */
    if state.check('?') and ((state.flowLevel > 0) or state.isBlankZ(1)) then
      return this._scanKey(state)
    end

    /* Is it the value indicator? */
    if state.check(':') and ((state.flowLevel > 0) or state.isBlankZ(1)) then
      return this._scanValue(state)
    end

    /* Is it an alias? */
    if state.check('*') then
      return this._scanAnchor(_YamlAliasToken~create(), "alias", state)
    end

    /* Is it an anchor? */
    if state.check('&') then
      return this._scanAnchor(_YamlAnchorToken~create(), "anchor", state)
    end

    /* Is it a tag? */
    if state.check('!') then
      return this._scanTag(state)
    end

    /* Is it a literal scalar? */
    if state.check('|') and not (state.flowLevel > 0) then
      return this._scanBlockScalar(true, state)
    end

    /* Is it a folded scalar? */
    if state.check('>') and not (state.flowLevel > 0) then
      return this._scanBlockScalar(false, state)
    end

    /* Is it a single-quoted scalar? */
    if state.check('\'') then
      return this._scanFlowScalar(true, state)
    end

    /* Is it a double-quoted scalar? */
    if state.check('"') then
      return this._scanFlowScalar(false, state)
    end

    /*
     * Is it a plain scalar?
     *
     * A plain scalar may start with any non-blank characters except
     *
     *      '-', '?', ':', ',', '[', ']', '{', '}',
     *      '#', '&', '*', '!', '|', '>', '\'', '\"',
     *      '%', '@', '`'.
     *
     * In the block context (and, for the '-' indicator, in the flow context
     * too), it may also start with the characters
     *
     *      '-', '?', ':'
     *
     * if it is followed by a non-space character.
     *
     * The last rule is more restrictive than the specification requires.
     */
    if not (state.isBlankZ() or state.check('-')
                or state.check('?') or state.check(':')
                or state.check(',') or state.check('[')
                or state.check(']') or state.check('{')
                or state.check('}') or state.check('#')
                or state.check('&') or state.check('*')
                or state.check('!') or state.check('|')
                or state.check('>') or state.check('\'')
                or state.check('"') or state.check('%')
                or state.check('@') or state.check('`')) or
            (state.check('-') and not state.isBlank(1)) or
            (not (state.flowLevel > 0) and
             (state.check('?') or state.check(':'))
             and not state.isBlankZ(1)) then
      return this._scanPlainScalar(state)
    end

    /*
     * If we don't determine the token type so far, it is an error.
     */
    _YamlError("while scanning for the next token", mark,
            "found character that cannot start any token")

  /*
   * Produce the STREAM-END token and shut down the scanner.
   */
  fun _scanStreamEnd(state: _ScannerState): _ScanResult ? =>
    /* Force new line. */
    if state.mark.column != 0 then
      state.mark.column = 0
      state.mark.line = state.mark.line + 1
    end
    /* Reset the indentation level. */
    _unrollIndent(state, state.mark.column)
    /* Reset simple keys. */
    match _removeSimpleKey(state)
    | let e: ScanError => return e
    end
    state.simpleKeyAllowed = false
    /* Create the STREAM-END token and append it to the queue. */
    let mark = state.mark.clone()
    state.emitToken(_YamlStreamEndToken(mark, mark))
    ScanDone

  /*
   * Produce a VERSION-DIRECTIVE or TAG-DIRECTIVE token.
   */
  fun _scanDirective(state: _ScannerState): _ScanResult ? =>
    /* Reset the indentation level. */
    _unrollIndent(state, state.mark.column)
    /* Reset simple keys. */
    match _removeSimpleKey()
    | let e: ScanError => return e
    end
    state.simpleKeyAllowed = false
    let s = _DirectiveScanner.create(state.mark.clone(), this~_scanToNextToken())
    s.apply(state)


  /*
   * Produce the DOCUMENT-START or DOCUMENT-END token.
   */
  fun _scanDocumentIndicator(tokenConstructor: {(YamlMark, YamlMark) : _YAMLToken[Any]}, state: _ScannerState): _ScanResult ? =>
    /* Reset the indentation level. */
    _unrollIndent(state, state.mark.colum)
    /* Reset simple keys. */
    match _removeSimpleKey(state)
    | let e: ScanError => return e
    end
    state.simpleKeyAllowed = false
    /* Consume the token. */
    let startmark = state.mark.clone()
    state.skip(3)
    let endMark = state.mark.clone()
    /* Create the DOCUMENT-START or DOCUMENT-END token. */
    state.emitToken(tokenConstructor(startMark, endMark))
    this._scanToNextToken(state)

  /*
   * Produce the FLOW-SEQUENCE-START or FLOW-MAPPING-START token.
   */
  fun _scanFlowCollectionStart(tokenConstructor: {(YamlMark, YamlMark) : _YAMLToken[Any]}, state: _ScannerState): _ScanResult ? =>
    /* The indicators '[' and '{' may start a simple key. */
    match _saveSimpleKey(state)
    | let e: ScanError => return e
    end
    /* Increase the flow level. */
    _increaseFlowLevel(state)
    /* A simple key may follow the indicators '[' and '{'. */
    state.simpleKeyAllowed = true
    /* Consume the token. */
    let startMark = state.mark.clone()
    buffer.skip()
    let endMark = state.mark.clone()
    /* Create the FLOW-SEQUENCE-START of FLOW-MAPPING-START token. */
    state.emitToken(tokenConstructor(startMark, endMark))
    this._scanToNextToken(state)

  /*
   * Produce the FLOW-SEQUENCE-END or FLOW-MAPPING-END token.
   */
  fun _scanFlowCollectionEnd(tokenConstructor: {(YamlMark, YamlMark) : _YAMLToken[Any]}, state: _ScannerState): _ScanResult ? =>
    /* Reset any potential simple key on the current flow level. */
    match _removeSimpleKey(state)
    | let e: ScanError => return e
    end
    /* Decrease the flow level. */
    _decreaseFlowLevel(state)
    /* No simple keys after the indicators ']' and '}'. */
    state.simpleKeyAllowed = false
    /* Consume the token. */
    let startMark = state.mark.clone()
    state.skip()
    let endMark = state.mark.clone()
    /* Create the FLOW-SEQUENCE-END of FLOW-MAPPING-END token. */
    state.emitToken(tokenConstructor(startMark, endmark))
    this._scanToNextToken(state)

  /*
   * Produce the FLOW-ENTRY token.
   */
  fun _scanFlowEntry(state: _ScannerState): _ScanResult ? =>
    /* Reset any potential simple keys on the current flow level. */
    match _removeSimpleKey(state)
    | let e: ScanError => return e
    end
    /* Simple keys are allowed after ','. */
    state.simpleKeyAllowed = true
    /* Consume the token. */
    let startMark = state.mark.clone()
    state.skip()
    let endMark = state.mark.clone()
    /* Create the FLOW-ENTRY token and append it to the queue. */
    state.emitToken(_YamlFlowEntryToken(startMark, endMark))
    this._scanToNextToken(state)

  /*
   * Produce the BLOCK-ENTRY token.
   */
  fun _scanBlockEntry(state: _ScannerState): _ScanResult ? =>
    /* Check if the scanner is in the block context. */
    if state.flowLevel == 0 then
      /* Check if we are allowed to start a new entry. */
      if not state.simpleKeyAllowed then
        return ScanError(None, state.mark.clone(), "block sequence entries are not allowed in this context")
      end
      /* Add the BLOCK-SEQUENCE-START token if needed. */
      _rollIndent(state, state.mark.column, YAML_BLOCK_SEQUENCE_START_TOKEN, state.mark.clone())
    else
      /*
       * It is an error for the '-' indicator to occur in the flow context,
       * but we let the Parser detect and report about it because the Parser
       * is able to point to the context.
       */
      None
    end
    /* Reset any potential simple keys on the current flow level. */
    match _removeSimpleKey(state)
    | let e: ScanError => return e
    end
    /* Simple keys are allowed after '-'. */
    state.simpleKeyAllowed = true
    /* Consume the token. */
    let startMark = state.mark.clone()
    state.skip()
    let endMark = state.mark.clone()
    /* Create the BLOCK-ENTRY token and append it to the queue. */
    state.emitToken(_YamlBlockEntryToken(startMark, endMark))
    this._scanToNextToken(state)

  /*
   * Produce the KEY token.
   */
  fun _scanKey(state: _ScannerState): _ScanResult ? =>
    /* In the block context, additional checks are required. */
    if state.flowLevel == 0 then
      /* Check if we are allowed to start a new key (not nessesary simple). */
      if not state.simpleKeyAllowed then
        return ScanError(None, state.mark.clone(), "mapping keys are not allowed in this context")
      end
      /* Add the BLOCK-MAPPING-START token if needed. */
      _rollIndent(state, state.mark.column, YAML_BLOCK_MAPPING_START_TOKEN, state.mark.clone())
    end
    /* Reset any potential simple keys on the current flow level. */
    match _removeSimpleKey(state)
    | let e: ScanError => return e
    end
    /* Simple keys are allowed after '?' in the block context. */
    state.simpleKeyAllowed = state.flowLevel == 0
    /* Consume the token. */
    let startMark = state.mark.clone()
    state.skip()
    let endMark = state.mark.clone()
    /* Create the KEY token and append it to the queue. */
    state.emitToken(_YAMLToken(YAML_KEY_TOKEN, startMark, endMark))
    this._scanToNextToken(state)

  /*
   * Produce the VALUE token.
   */
  fun _scanValue(state: _ScannerState): _ScanResult ? =>
    let simpleKey = state.simpleKeys.top-1
    /* Have we found a simple key? */
    if simpleKey.possible then
      /* Create the KEY token and insert it into the queue. */
      state.emitToken(_YAMLToken(YAML_KEY_TOKEN, simpleKey.mark, simpleKey.mark))
      /* In the block context, we may need to add the BLOCK-MAPPING-START token. */
      _rollIndent(state, simpleKey.mark.column, YAML_BLOCK_MAPPING_START_TOKEN, simpleKey.mark, simpleKey.tokenNumber)
      /* Remove the simple key. */
      simpleKey.possible = false
      /* A simple key cannot follow another simple key. */
      simpleKey = false
    else
      /* The ':' indicator follows a complex key. */
      /* In the block context, extra checks are required. */
      if state.flowLevel == 0 then
        /* Check if we are allowed to start a complex value. */
        if not simpleKey then
          return ScanError(None, mark, "mapping values are not allowed in this context")
        end
        /* Add the BLOCK-MAPPING-START token if needed. */
        _rollIndent(state, state.mark.column, YAML_BLOCK_MAPPING_START_TOKEN, state.mark.clone())
      end
      /* Simple keys after ':' are allowed in the block context. */
      state.simpleKeyAllowed = state.flowLevel == 0
    end
    /* Consume the token. */
    let startMark = state.mark.clone()
    state.skip()
    let endMark = state.mark.clone()
    /* Create the VALUE token and append it to the queue. */
    state.emitToken(_YAMLToken(YAML_VALUE_TOKEN, startMark, endMark))
    this._scanToNextToken(state)

  /*
   * Produce the ALIAS or ANCHOR token.
   */
  fun _scanAnchor(tokenConstructor: {(YamlMark, YamlMark, String): _YAMLToken[Any]}, errorName: String,
        state: _ScannerState): _ScanResult ? =>
    /* An anchor or an alias could be a simple key. */
    match _saveSimpleKey(state)
    | let e: ScanError => return e
    end
    /* A simple key cannot follow an anchor or an alias. */
    state.simpleKeyAllowed = false
    /* Create the ALIAS or ANCHOR token and append it to the queue. */
    let s = _AnchorScanner.create(tokenConstructor, errorName, this~_scanToNextToken())
    s.apply(state)

  /*
   * Produce the TAG token.
   */
  fun _scanTag(state: _ScannerState): _ScanResult ? =>
    /* A tag could be a simple key. */
    match _saveSimpleKey(state)
    | let e: ScanError => return e
    end
    /* A simple key cannot follow a tag. */
    state.simpleKeyAllowed = false
    /* Create the TAG token and append it to the queue. */
    let s = _TagScanner.create(this~_scanToNextToken())
    s.apply(state)

  /*
   * Produce the SCALAR(...,literal) or SCALAR(...,folded) tokens.
   */
  fun _scanBlockScalar(literal: Bool, state: _ScannerState): _ScanResult ? =>
    /* Remove any potential simple keys. */
    match _removeSimpleKey(state)
    | let e: ScanError => return e
    end
    /* A simple key may follow a block scalar. */
    state.simpleKeyAllowed = true
    /* Create the SCALAR token and append it to the queue. */
    let s = _BlockScalarScanner.create(literal, this~_scanToNextToken())
    s.apply(state)


  /*
   * Produce the SCALAR(...,single-quoted) or SCALAR(...,double-quoted) tokens.
   */
  fun _scanFlowScalar(single: Bool, state: _ScannerState): _ScanResult ? =>
    /* A plain scalar could be a simple key. */
    match _saveSimpleKey(state)
    | let e: ScanError => return e
    end
    /* A simple key cannot follow a flow scalar. */
    state.simpleKeyAllowed = false
    /* Create the SCALAR token and append it to the queue. */
    let s = _FlowScalarScanner.create(single, this~_scanToNextToken())
    s.apply(state)

  /*
   * Produce the SCALAR(...,plain) token.
   */
  fun _scanPlainScalar(state: _ScannerState): _ScanResult ? =>
    /* A plain scalar could be a simple key. */
    match _saveSimpleKey(state)
    | let e: ScanError => return e
    end
    /* A simple key cannot follow a flow scalar. */
    state.simpleKeyAllowed = false
    /* Create the SCALAR token and append it to the queue. */
    let s = _PlainScalarScanner.create(this~_scanToNextToken())
    s.apply(state)

  /*
   * Increase the flow level and resize the simple key list if needed.
   */
  fun _increaseFlowLevel(state: _ScannerState) =>
    let simpleKey = _YamlSimpleKey.create()
    /* Reset the simple key on the next level. */
    state.simpleKeys.push(simpleKey)
    state.flowLevel = state.flowLevel + 1

  /*
   * Decrease the flow level.
   */
  fun _decreaseFlowLevel(state: _ScannerState) ? =>
    if state.flowLevel > 0 then
      state.flowLevel = state.flowLevel - 1
      state.simpleKeys.pop()
    end

  /*
   * Push the current indentation level to the stack and set the new level
   * the current column is greater than the indentation level.  In this case,
   * append or insert the specified token into the token queue.
   *
   */
  fun _rollIndent(state: _ScannerState, column: U16, tokenConstructor: {(YamlMark, YamlMark) : _YAMLToken[Any]},
                  mark: YamlMark val, number: (U16 | None) = None) ? =>
    /* In the flow context, do nothing. */
    if state.flowLevel > 0 then
      return
    end

    if state.indent < column then
      /*
       * Push the current indentation level to the stack and set the new
       * indentation level.
       */
      state.indents.push(indent)
      state.indent = column
      /* Create a token and insert it into the queue. */
      state.emitToken(tokenConstructor(mark, mark))
      if number is None then
        tokens.enqueue(token)
      else
        tokens.insert((number as U16) - tokens_parsed, token)
      end
    end

  /*
   * Pop indentation levels from the indents stack until the current level
   * becomes less or equal to the column.  For each intendation level, append
   * the BLOCK-END token.
   */
  fun _unrollIndent(state: _ScannerState, column: (U16 | None) = None) ? =>
    /* In the flow context, do nothing. */
    if state.flowLevel > 0 then
      return
    end

    /* Loop through the intendation levels in the stack. */
    while state.indent > column do
      /* Create a token and append it to the queue. */
      state.emitToken(_YAMLToken(YAML_BLOCK_END_TOKEN, mark, mark))
      /* Pop the indentation level. */
      state.indent = indents.pop()
    end

  /*
   * Check if a simple key may start at the current position and add it if
   * needed.
   */
  fun _saveSimpleKey(state: _ScannerState): (ScanError | None) ? =>
    /*
     * A simple key is required at the current position if the scanner is in
     * the block context and the current column coincides with the indentation
     * level.
     */
    var required = (state.flowLevel == 0) and (state.indent == state.mark.column)
    /*
     * If the current position may start a simple key, save it.
     */
    if state.simpleKeyAllowed then
      let simpleKey = _YamlSimpleKey.create()
      simpleKey.possible = true
      simpleKey.required = required
      simpleKey.token_number = tokens_parsed + (tokens.tail - tokens.head)
      simpleKey.mark = mark.clone()
      match _removeSimpleKey(state)
      | let e: ScanError => return e
      end
      state.simpleKeys.update(state.simpleKeys.size() - 1, simpleKey)
    end
    None

  /*
   * Remove a potential simple key at the current flow level.
   */
  fun _removeSimpleKey(state: _ScannerState): (ScanError | None) ? =>
    let simpleKey = state.simpleKeys.top-1
    if simpleKey.possible then
      /* If the key is required, it is an error. */
      if simpleKey.required then
        return ScanError("while scanning a simple key", simpleKey.mark, "could not find expected ':'")
      end
    end
    /* Remove the key from the stack. */
    simpleKey.possible = false
    None


/* Eat the rest of the line including any comments. */
primitive _LineTrailScanner

  fun scan(startMark: YamlMark val, errorContext: String, nextScanner: _Scanner, state: _ScannerState): _ScanResult ? =>
    if not state.buffer.available() then
      return ScanPaused(this)
    end

    while state.buffer.isBlank() do
      state.skip()
      if not state.buffer.available() then
        return ScanPaused(this)
      end
    end
    _CommentScanner.scan(_EOLScanner~scan(startMark, errorContext, nextScanner))


primitive _CommentScanner
  fun scan(nextScanner: _Scanner, state: _ScannerState): _ScanResult ? =>
    if not state.buffer.available() then
      ScanPaused(this)
    end
    if state.buffer.check('#') then
      _SkipLineScanner.scan(nextScanner)
    else
      nextScanner.apply(state)
    end


primitive _EOLScanner
  fun scan(startMark: YamlMark val, errorContext: String, nextScanner: _Scanner, state: _ScannerState): _ScanResult ? =>
    /* Check if we are at the end of the line. */
    if not state.buffer.isBreakZ() then
      return ScanError(errorContext, startMark, "did not find expected comment or line break")
    end

    /* Eat a line break. */
    if state.buffer.isBreak() then
      if not state.buffer.available(2) then
        return ScanPaused(this)
      end
      state.skipLine()
    end
    nextScanner.apply(state)


primitive _SkipLineScanner

  fun scan(nextScanner: _Scanner, state: _ScannerState): _ScanResult ? =>
    if not state.buffer.available() then
      return ScanPaused(this)
    end
    while not state.buffer.isBreakZ() do
      state.skip()
      if not state.buffer.available() then
        return ScanPaused(this)
      end
    end
    nextScanner.apply(state)

class _AnchorScanner is _Scanner
  let _tokenConstructor: {(YamlMark, YamlMark, String): _YAMLToken[Any]}
  let _errorName: String
  let _startMark: YamlMark val
  let _nextScanner: _Scanner
  var anchor: String = String.create()
  var length: USize = 0

  new create(tokenConstructor: {(YamlMark, YamlMark, String): _YAMLToken[Any]}, errorName: String,
             startMark: YamlMark val, nextScanner: _Scanner) =>
    _tokenConstructor = tokenConstructor
    _errorName = errorName
    _startMark = startMark
    _nextScanner = nextScanner

  fun ref apply(state: _ScannerState): _ScanResult ? =>
    /* Eat the indicator character. */
    state.skip()
    this._scanAnchor(state)

  fun _scanAnchor(state: _ScannerState): _ScanResult ? =>
    if not state.available() then
      return ScanPaused(this~_scanAnchor())
    end
    while state.isAlpha() do
      state.read(_anchor)
      length = length + 1
      if not state.available() then
        return ScanPaused(this~_scanAnchor())
      end
    end
    if ((length == 0) or not (state.isBlankZ() or state.check('?')
                or state.check(':') or state.check(',')
                or state.check(']') or state.check('}')
                or state.check('%') or state.check('@')
                or state.check('`'))) then
        return ScanError("while scanning an " + _errorName, _startMark, "did not find expected alphabetic or numeric character")
    end
    let endMark = state.mark.clone()
    /* Create a token. */
    state.emitToken(_tokenConstructor(_startMark, endMark, _anchor))
    _nextScanner.apply(state)
