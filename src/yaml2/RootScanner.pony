
primitive _ScanBOM
primitive _SkipWhiteSpace
primitive _CheckComment
primitive _SkipComment
primitive _CheckLineBreak
primitive _SkipLineBreak
primitive _ScanStaleSimpleKeys
primitive _ScanToken
type _State is (None | _ScanBOM | _SkipWhiteSpace | _CheckComment | _SkipComment | _CheckLineBreak | _SkipLineBreak | _ScanStaleSimpleKeys | _ScanToken)

class _RootScanner is _Scanner
  var _state: _State = None

  fun scan(state: YamlParser): ScanResult =>
    match _state
    | None => _startScan(state)
    | _ScanBOM => _scanBOM(state)
    | _SkipWhitespace => _skipWhitespace(state)
    | _CheckComment => _checkComment(state)
    | _SkipComment => _skipComment(state)
    | _CheckLineBreak => _checkLineBreak(state)
    | _SkipLineBreak => _skipLineBreak(state)
    | _ScanStaleSimpleKeys => _scanStaleSimpleKeys(state)
    | _ScanToken => _scanToken(state)

  fun _startScan(state: _ScannerState): ScanResult =>
    let simpleKey = _YamlSimpleKey.create()
    /* Set the initial indentation. */
    state.indent = -1
    /* Initialize the simple key stack. */
    state.simpleKeys.push(simpleKey)
    /* A simple key is allowed at the beginning of the stream. */
    state.simpleKeyAllowed = true
    /* Create the STREAM-START token and append it to the queue. */
    let mark = state.mark.clone()
    state.emitToken(_YAMLToken(YAML_STREAM_START_TOKEN, mark, mark, _YamlStreamStartTokenData(encoding)))
    _state = _ScanBOM
    ScanContinue

  fun _scanBOM(state: _ScannerState): ScanResult =>
    if state.mark.column == 0 and state.isBom() then
      state.skip()
    end
    _state = _SkipWhiteSpace
    ScanContinue

  fun _skipWhitespace(state: _ScannerState): ScanResult =>
    /*
     * Eat whitespaces.
     *
     * Tabs are allowed:
     *
     *  - in the flow context;
     *  - in the block context, but not at the beginning of the line or
     *  after '-', '?', or ':' (complex value).
     */
    while (state.check(' ') or
            ((state.flowLevel > 0 or not state.simpleKeyAllowed) and
             state.check('\t'))) do
      state.skip()
      if not state.available() then
        return
      end
    end
    _state = _CheckComment
    ScanContinue

  fun _checkComment(state: _ScannerState): ScanResult =>
    if state.check('#') then
      _state = _SkipComment
    else
      _state = _CheckLineBreak
    end
    ScanContinue

  fun _skipComment(state: _ScannerState): ScanResult =>
    while not state.isBreakZ() do
      state.skip()
      if not state.available() then
        return
      end
    end
    _state = _CheckLineBreak
    ScanContinue

  fun _checkLineBreak(state: _ScannerState): ScanResult =>
    /* If it is a line break, eat it. */
    if state.isBreak() then
      _state = _SkipLineBreak
    else
      _state = _ScanStaleSimpleKeys
    end
    ScanContinue

  fun _skipLineBreak(state: _ScannerState): ScanResult =>
    if not state.available(2) then
      return
    end
    state.skipLine()

    /* In the block context, a new line may start a simple key. */
    if state.flowLevel == 0 then
      state.simpleKeyAllowed = true
    end
    _state = _SkipBomState
    ScanContinue

  /*
   * Check the list of potential simple keys and remove the positions that
   * cannot contain simple keys anymore.
   */
  fun _scanStaleSimpleKeys(state: _ScannerState): ScanResult =>
    /* Check for a potential simple key for each flow level. */
    for simpleKey in state.simpleKeys do
      /*
       * The specification requires that a simple key
       *
       *  - is limited to a single line,
       *  - is shorter than 1024 characters.
       */
      if simpleKey.possible
              and (simpleKey.mark.line < state.mark.line
                  or simpleKey.mark.index + 1024 < state.mark.index) then
          /* Check if the potential simple key to be removed is required. */
          if simpleKey.required then
              return ScanError("while scanning a simple key", simpleKey.mark, "could not find expected ':'")
          end

          simpleKey.possible = false
      end
    end
    /* Check the indentation level against the current column. */
    _unrollIndent(state, state.mark.column)
    _state = _ScanToken
    ScanContinue

  fun _scanToken(state: _ScannerState): ScanResult =>
    /*
     * Ensure that the buffer contains at least 4 characters.  4 is the length
     * of the longest indicators ('--- ' and '... ').
    */
    if not state.available(4) then
      return ScanContinue
    end

    /* Is it the end of the stream? */
    if state.isZ() then
      return _scanStreamEnd(state)
    end

    /* Is it a directive? */
    if state.mark.column == 0 and state.check('%') then
      return _scanDirective(state)
    end

    /* Is it the document start indicator? */
    if state.mark.column == 0
            and state.check('-', 0)
            and state.check('-', 1)
            and state.check('-', 2)
            and state.isBlankZ(3) then
      return _scanDocumentIndicator(state, YAML_DOCUMENT_START_TOKEN)
    end

    /* Is it the document end indicator? */
    if state.mark.column == 0
            and state.check('.', 0)
            and state.check('.', 1)
            and state.check('.', 2)
            and state.isBlankZ(3) then
      return _scanDocumentIndicator(state, YAML_DOCUMENT_END_TOKEN)
    end

    /* Is it the flow sequence start indicator? */
    if state.check('[') then
      return _scanFlowCollectionStart(state, YAML_FLOW_SEQUENCE_START_TOKEN)
    end

    /* Is it the flow mapping start indicator? */
    if state.check('{') then
      return _scanFlowCollectionStart(state, YAML_FLOW_MAPPING_START_TOKEN)
    end

    /* Is it the flow sequence end indicator? */
    if state.check(']') then
      return _scanFlowCollectionEnd(state, YAML_FLOW_SEQUENCE_END_TOKEN)
    end

    /* Is it the flow mapping end indicator? */
    if state.check('}') then
      return _scanFlowCollectionEnd(state, YAML_FLOW_MAPPING_END_TOKEN)
    end

    /* Is it the flow entry indicator? */
    if state.check(',') then
      return _scanFlowEntry(state)
    end

    /* Is it the block entry indicator? */
    if state.check('-') and state.isBlankZ(1) then
      return _scanBlockEntry(state)
    end

    /* Is it the key indicator? */
    if state.check('?') and (state.flowLevel > 0 or state.isBlankZ(1)) then
      return _scanKey(state)
    end

    /* Is it the value indicator? */
    if state.check(':') and (state.flowLevel > 0 or state.isBlankZ(1)) then
      return _scanValue(state)
    end

    /* Is it an alias? */
    if state.check('*') then
      return _scanAnchor(state, YAML_ALIAS_TOKEN)
    end

    /* Is it an anchor? */
    if state.check('&') then
      return _scanAnchor(state, YAML_ANCHOR_TOKEN)
    end

    /* Is it a tag? */
    if state.check('!') then
      return _scanTag(state)
    end

    /* Is it a literal scalar? */
    if state.check('|') and not state.flowLevel > 0 then
      return _scanBlockScalar(state, 1)
    end

    /* Is it a folded scalar? */
    if state.check('>') and not state.flowLevel > 0 then
      return _scanBlockScalar(state, 0)
    end

    /* Is it a single-quoted scalar? */
    if state.check('\'') then
      return _scanFlowScalar(state, 1)
    end

    /* Is it a double-quoted scalar? */
    if state.check('"') then
      return _scanFlowScalar(state, 0)
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
            (not state.flowLevel > 0 and
             (state.check('?') or state.check(':'))
             and not state.isBlankZ(1)) then
      return _scanPlainScalar(state)
    end

    /*
     * If we don't determine the token type so far, it is an error.
     */
    _YamlError("while scanning for the next token", mark,
            "found character that cannot start any token")

  /*
   * Produce the STREAM-END token and shut down the scanner.
   */
  fun _scanStreamEnd(state: _ScannerState): ScanResult =>
    /* Force new line. */
    if state.mark.column != 0 then
      state.mark.column = 0
      state.mark.line = state.mark.line + 1
    end
    /* Reset the indentation level. */
    _unrollIndent(state, state.mark.column)
    /* Reset simple keys. */
    let res = _removeSimpleKey(state)
    if res is ScanError then
      return try res as ScanError end
    end
    state.simpleKeyAllowed = false
    /* Create the STREAM-END token and append it to the queue. */
    let mark = state.mark.clone()
    state.emitToken(_YAMLToken(YAML_STREAM_END_TOKEN, mark, mark))
    _state = _SkipWhiteSpace
    return ScanDone

  /*
   * Produce a VERSION-DIRECTIVE or TAG-DIRECTIVE token.
   */
  fun _scanDirective(state: _ScannerState): ScanResult =>
    /* Reset the indentation level. */
    _unrollIndent(state, state.mark.column)
    /* Reset simple keys. */
    let res = state.removeSimpleKey()
    if res is ScanError then
      return try res as ScanError end
    end
    state.simpleKeyAllowed = false
    state.scannerStack.push(_DirectiveScanner.create(state.mark.clone()))
    _state = _SkipWhiteSpace
    return ScanContinue

  /*
   * Produce the DOCUMENT-START or DOCUMENT-END token.
   */
  fun _scanDocumentIndicator(state: _ScannerState, tokenType: TokenType): ScanResult =>
    /* Reset the indentation level. */
    _unrollIndent(state, state.mark.colum)
    /* Reset simple keys. */
    let res = _removeSimpleKey(state)
    if res is ScanError then
      return try res as ScanError end
    end
    state.simpleKeyAllowed = false
    /* Consume the token. */
    let startmark = state.mark.clone()
    state.skip(3)
    let endMark = state.mark.clone()
    /* Create the DOCUMENT-START or DOCUMENT-END token. */
    state.emitToken(_YAMLToken(tokenType, startMark, endMark))
    _state = _SkipWhiteSpace
    return ScanContinue

  /*
   * Produce the FLOW-SEQUENCE-START or FLOW-MAPPING-START token.
   */
  fun _scanFlowCollectionStart(state: _ScannerState, tokenType: TokenType): ScanResult =>
    /* The indicators '[' and '{' may start a simple key. */
    let res = _saveSimpleKey(state)
    if res is ScanError then
      return try res as ScanError end
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
    state.emitToken(_YAMLToken(tokenType, startMark, endMark))
    _state = _SkipWhiteSpace
    return ScanContinue

  /*
   * Produce the FLOW-SEQUENCE-END or FLOW-MAPPING-END token.
   */
  fun _scanFlowCollectionEnd(state: _ScannerState, tokenType: TokenType): ScanResult =>
    /* Reset any potential simple key on the current flow level. */
    let res = _removeSimpleKey(state)
    if res is ScanError then
      return try res as ScanError end
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
    state.emitToken(_YAMLToken(tokenType, startMark, endmark))
    _state = _SkipWhiteSpace
    return ScanContinue

  /*
   * Produce the FLOW-ENTRY token.
   */
  fun _scanFlowEntry(state: _ScannerState): ScanResult =>
    /* Reset any potential simple keys on the current flow level. */
    let e = _removeSimpleKey(state)
    if e is ScanError then
      return (e as ScanError)
    end
    /* Simple keys are allowed after ','. */
    state.simpleKeyAllowed = true
    /* Consume the token. */
    let startMark = state.mark.clone()
    state.skip()
    let endMark = state.mark.clone()
    /* Create the FLOW-ENTRY token and append it to the queue. */
    state.emitToken(_YAMLToken(YAML_FLOW_ENTRY_TOKEN, startMark, endMark))
    _state = _SkipWhiteSpace
    return ScanContinue

  /*
   * Produce the BLOCK-ENTRY token.
   */
  fun _scanBlockEntry(state: _ScannerState): ScanResult =>
    /* Check if the scanner is in the block context. */
    if state.flowLevel == 0 then
      /* Check if we are allowed to start a new entry. */
      if not state.simpleKeyAllowed then
        return ScanError(None, state.mark.clone(), "block sequence entries are not allowed in this context");
      end
      /* Add the BLOCK-SEQUENCE-START token if needed. */
      _rollIndent(state, state.mark.column, YAML_BLOCK_SEQUENCE_START_TOKEN, state.mark.clone())
    else
        /*
         * It is an error for the '-' indicator to occur in the flow context,
         * but we let the Parser detect and report about it because the Parser
         * is able to point to the context.
         */
    end
    /* Reset any potential simple keys on the current flow level. */
    let e = _removeSimpleKey(state)
    if e is ScanError then
      return (e as ScanError)
    end
    /* Simple keys are allowed after '-'. */
    state.simpleKeyAllowed = true
    /* Consume the token. */
    let startMark = state.mark.clone()
    state.skip()
    let endMark = state.mark.clone()
    /* Create the BLOCK-ENTRY token and append it to the queue. */
    state.emitToken(_YAMLToken(YAML_BLOCK_ENTRY_TOKEN, startMark, endMark))
    _state = _SkipWhiteSpace
    return ScanContinue

  /*
   * Produce the KEY token.
   */
  fun _scanKey(state: _ScannerState): ScanResult =>
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
    let e = _removeSimpleKey(state)
    if e is ScanError then
      return (e as ScanError)
    end
    /* Simple keys are allowed after '?' in the block context. */
    state.simpleKeyAllowed = state.flowLevel == 0
    /* Consume the token. */
    let startMark = state.mark.clone()
    state.skip()
    let endMark = state.mark.clone()
    /* Create the KEY token and append it to the queue. */
    state.emitToken(_YAMLToken(YAML_KEY_TOKEN, startMark, endMark))
    _state = _SkipWhiteSpace
    return ScanContinue

  /*
   * Produce the VALUE token.
   */
  fun _scanValue(state: _ScannerState): ScanResult =>
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
          return ScanError(None, mark, "mapping values are not allowed in this context");
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
    _state = _SkipWhiteSpace
    return ScanContinue

  /*
   * Produce the ALIAS or ANCHOR token.
   */
  fun _scanAnchor(state: _ScannerState, tokenType: TokenType): ScanResult =>
    /* An anchor or an alias could be a simple key. */
    let res = _saveSimpleKey(state)
    if res is ScanError then
      return try res as ScanError end
    end
    /* A simple key cannot follow an anchor or an alias. */
    state.simpleKeyAllowed = false
    /* Create the ALIAS or ANCHOR token and append it to the queue. */
    state.scannerStack.push(_AnchorScanner.create(tokenType))
    _state = _SkipWhiteSpace
    return ScanContinue

  /*
   * Produce the TAG token.
   */
  fun _scanTag(state: _ScannerState, tokenType: TokenType): ScanResult =>
    /* A tag could be a simple key. */
    let res = _saveSimpleKey(state)
    if res is ScanError then
      return try res as ScanError end
    end
    /* A simple key cannot follow a tag. */
    state.simpleKeyAllowed = false
    /* Create the TAG token and append it to the queue. */
    state.scannerStack.push(_TagScanner.create(tokenType))
    _state = _SkipWhiteSpace
    return ScanContinue

  /*
   * Produce the SCALAR(...,literal) or SCALAR(...,folded) tokens.
   */
  fun _scanBlockScalar(state: _ScannerState, literal: Bool): ScanResult =>
    /* Remove any potential simple keys. */
    let res = _removeSimpleKey(state)
    if res is ScanError then
      return try res as ScanError end
    end
    /* A simple key may follow a block scalar. */
    state.simpleKeyAllowed = true
    /* Create the SCALAR token and append it to the queue. */
    state.scannerStack.push(_BlockScalarScanner.create(literal))
    _state = _SkipWhiteSpace
    return ScanContinue

  /*
   * Produce the SCALAR(...,single-quoted) or SCALAR(...,double-quoted) tokens.
   */
  fun _scanFlowScalar(state: _ScannerState, single: Bool): ScanResult =>
    /* A plain scalar could be a simple key. */
    let res = _saveSimpleKey(state)
    if res is ScanError then
      return try res as ScanError end
    end
    /* A simple key cannot follow a flow scalar. */
    state.simpleKeyAllowed = false
    /* Create the SCALAR token and append it to the queue. */
    state.scannerStack.push(_FlowScalarScanner.create(single))
    _state = _SkipWhiteSpace
    return ScanContinue


  /*
   * Produce the SCALAR(...,plain) token.
   */
  fun _scanPlainScalar(state: _ScannerState): ScanResult =>
    /* A plain scalar could be a simple key. */
    let res = _saveSimpleKey(state)
    if res is ScanError then
      return try res as ScanError end
    end
    /* A simple key cannot follow a flow scalar. */
    state.simpleKeyAllowed = false
    /* Create the SCALAR token and append it to the queue. */
    state.scannerStack.push(_PlainScalarScanner.create())
    _state = _SkipWhiteSpace
    return ScanContinue

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
  fun _decreaseFlowLevel(state: _ScannerState) =>
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
  fun _rollIndent(state: _ScannerState, column U16, type: TokenType, mark: YamlMark val, number: (U16 | None) = None) =>
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
      state.emitToken(_YAMLToken(type, mark, mark))
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
  fun _unrollIndent(state: _ScannerState, column: (U16 | None) = None) =>
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
  fun _saveSimpleKey(state: _ScannerState): (ScanError | None) =>
    /*
     * A simple key is required at the current position if the scanner is in
     * the block context and the current column coincides with the indentation
     * level.
     */
    var required = state.flowLevel == 0 and state.indent == state.mark.column
    /*
     * If the current position may start a simple key, save it.
     */
    if state.simpleKeyAllowed then
      let simpleKey = _YamlSimpleKey.create()
      simpleKey.possible = true
      simpleKey.required = required
      simpleKey.token_number = tokens_parsed + (tokens.tail - tokens.head)
      simpleKey.mark = mark.clone()
      let res = _removeSimpleKey(state)
      if res is ScanError then
        return (res as ScanError)
      end
      state.simpleKeys.update(state.simpleKeys.size() - 1, simpleKey)
    end
    None


  /*
   * Remove a potential simple key at the current flow level.
   */
  fun _removeSimpleKey(state: _ScannerState): (ScanError | None)  =>
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
