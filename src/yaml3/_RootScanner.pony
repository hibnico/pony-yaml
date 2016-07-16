

class _RootScanner

  fun ref apply(state: _ScannerState): _ScanResult ? =>
    if not state.available() then
      return ScanPaused(this)
    end
    match _streamStart(state)
    | let e: ScanError => return e
    | None => None
    else
      error
    end
    this._scanToNextToken(state)

  fun ref _streamStart(state: _ScannerState): (ScanError | None) ? =>
    /* Set the initial indentation. */
    state.indent = -1
    /* Initialize the simple key stack. */
    state.simpleKeys.push(_YamlSimpleKey.createStub())
    /* A simple key is allowed at the beginning of the stream. */
    state.simpleKeyAllowed = true
    /* Create the STREAM-START token and append it to the queue. */
    let mark = state.mark.clone()
    let encoding: String = "UTF-8" // TODO
    match state.emitToken(_YamlStreamStartToken(mark, mark, encoding))
    | let e: ScanError => e
    end

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
    while not state.isBreakEOF() do
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
      this._scanToNextToken_staleKeys(state)
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

  fun ref _scanToNextToken_staleKeys(state: _ScannerState): _ScanResult ? =>
    /* Remove obsolete potential simple keys. */
    match state.removeStaleSimpleKeys()
    | let e: ScanError => return e
    end
    /* Check the indentation level against the current column. */
    state.unrollIndent(state.mark.column)
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
    if state.isEOF() then
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
            and state.isBlankEOF(3) then
      let cons = lambda (startMark: YamlMark val, endMark: YamlMark val) : _YAMLToken => _YamlDocumentStartToken.create(startMark, endMark) end
      return this._scanDocumentIndicator(cons, state)
    end

    /* Is it the document end indicator? */
    if (state.mark.column == 0)
            and state.check('.', 0)
            and state.check('.', 1)
            and state.check('.', 2)
            and state.isBlankEOF(3) then
      let cons = lambda (startMark: YamlMark val, endMark: YamlMark val) : _YAMLToken => _YamlDocumentEndToken.create(startMark, endMark) end
      return this._scanDocumentIndicator(cons, state)
    end

    /* Is it the flow sequence start indicator? */
    if state.check('[') then
      let cons = lambda (startMark: YamlMark val, endMark: YamlMark val) : _YAMLToken => _YamlFlowMappingStartToken.create(startMark, endMark) end
      return this._scanFlowCollectionStart(cons, state)
    end

    /* Is it the flow mapping start indicator? */
    if state.check('{') then
      let cons = lambda (startMark: YamlMark val, endMark: YamlMark val) : _YAMLToken => _YamlFlowMappingStartToken.create(startMark, endMark) end
      return this._scanFlowCollectionStart(cons, state)
    end

    /* Is it the flow sequence end indicator? */
    if state.check(']') then
      let cons = lambda (startMark: YamlMark val, endMark: YamlMark val) : _YAMLToken => _YamlFlowSequenceEndToken.create(startMark, endMark) end
      return this._scanFlowCollectionEnd(cons, state)
    end

    /* Is it the flow mapping end indicator? */
    if state.check('}') then
      let cons = lambda (startMark: YamlMark val, endMark: YamlMark val) : _YAMLToken => _YamlFlowMappingEndToken.create(startMark, endMark) end
      return this._scanFlowCollectionEnd(cons, state)
    end

    /* Is it the flow entry indicator? */
    if state.check(',') then
      return this._scanFlowEntry(state)
    end

    /* Is it the block entry indicator? */
    if state.check('-') and state.isBlankEOF(1) then
      return this._scanBlockEntry(state)
    end

    /* Is it the key indicator? */
    if state.check('?') and ((state.flowLevel > 0) or state.isBlankEOF(1)) then
      return this._scanKey(state)
    end

    /* Is it the value indicator? */
    if state.check(':') and ((state.flowLevel > 0) or state.isBlankEOF(1)) then
      return this._scanValue(state)
    end

    /* Is it an alias? */
    if state.check('*') then
      let cons = lambda (startMark: YamlMark val, endMark: YamlMark val, value: String) : _YAMLToken => _YamlAliasToken.create(startMark, endMark, value) end
      return this._scanAnchor(cons, "alias", state)
    end

    /* Is it an anchor? */
    if state.check('&') then
      let cons = lambda (startMark: YamlMark val, endMark: YamlMark val, value: String) : _YAMLToken => _YamlAnchorToken.create(startMark, endMark, value) end
      return this._scanAnchor(cons, "anchor", state)
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
    if not (state.isBlankEOF() or state.check('-')
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
             and not state.isBlankEOF(1)) then
      return this._scanPlainScalar(state)
    end

    /*
     * If we don't determine the token type so far, it is an error.
     */
    ScanError("while scanning for the next token", state.mark.clone(), "found character that cannot start any token")

  /*
   * Produce the STREAM-END token and shut down the scanner.
   */
  fun ref _scanStreamEnd(state: _ScannerState): _ScanResult ? =>
    /* Force new line. */
    if state.mark.column != 0 then
      state.mark.column = 0
      state.mark.line = state.mark.line + 1
    end
    /* Reset the indentation level. */
    state.unrollIndent(state.mark.column)
    /* Reset simple keys. */
    match state.resetSimpleKey()
    | let e: ScanError => return e
    end
    state.simpleKeyAllowed = false
    /* Create the STREAM-END token and append it to the queue. */
    let mark = state.mark.clone()
    match state.emitToken(_YamlStreamEndToken(mark, mark))
    | let e: ScanError => return e
    end
    ScanDone

  /*
   * Produce a VERSION-DIRECTIVE or TAG-DIRECTIVE token.
   */
  fun ref _scanDirective(state: _ScannerState): _ScanResult ? =>
    /* Reset the indentation level. */
    state.unrollIndent(state.mark.column)
    /* Reset simple keys. */
    match state.resetSimpleKey()
    | let e: ScanError => return e
    end
    state.simpleKeyAllowed = false
    let s = _DirectiveScanner.create(state.mark.clone(), this~_scanToNextToken())
    s.apply(state)


  /*
   * Produce the DOCUMENT-START or DOCUMENT-END token.
   */
  fun ref _scanDocumentIndicator(tokenConstructor: {(YamlMark val, YamlMark val) : _YAMLToken} val, state: _ScannerState): _ScanResult ? =>
    /* Reset the indentation level. */
    state.unrollIndent(state.mark.column)
    /* Reset simple keys. */
    match state.resetSimpleKey()
    | let e: ScanError => return e
    end
    state.simpleKeyAllowed = false
    /* Consume the token. */
    let startMark = state.mark.clone()
    state.skip(3)
    let endMark = state.mark.clone()
    /* Create the DOCUMENT-START or DOCUMENT-END token. */
    match state.emitToken(tokenConstructor(startMark, endMark))
    | let e: ScanError => return e
    end
    this._scanToNextToken(state)

  /*
   * Produce the FLOW-SEQUENCE-START or FLOW-MAPPING-START token.
   */
  fun ref _scanFlowCollectionStart(tokenConstructor: {(YamlMark val, YamlMark val) : _YAMLToken} val, state: _ScannerState): _ScanResult ? =>
    /* The indicators '[' and '{' may start a simple key. */
    match state.saveSimpleKey()
    | let e: ScanError => return e
    end
    /* Increase the flow level. */
    state.increaseFlowLevel()
    /* A simple key may follow the indicators '[' and '{'. */
    state.simpleKeyAllowed = true
    /* Consume the token. */
    let startMark = state.mark.clone()
    state.skip()
    let endMark = state.mark.clone()
    /* Create the FLOW-SEQUENCE-START of FLOW-MAPPING-START token. */
    match state.emitToken(tokenConstructor(startMark, endMark))
    | let e: ScanError => return e
    end
    this._scanToNextToken(state)

  /*
   * Produce the FLOW-SEQUENCE-END or FLOW-MAPPING-END token.
   */
  fun ref _scanFlowCollectionEnd(tokenConstructor: {(YamlMark val, YamlMark val) : _YAMLToken} val, state: _ScannerState): _ScanResult ? =>
    /* Reset any potential simple key on the current flow level. */
    match state.resetSimpleKey()
    | let e: ScanError => return e
    end
    /* Decrease the flow level. */
    state.decreaseFlowLevel()
    /* No simple keys after the indicators ']' and '}'. */
    state.simpleKeyAllowed = false
    /* Consume the token. */
    let startMark = state.mark.clone()
    state.skip()
    let endMark = state.mark.clone()
    /* Create the FLOW-SEQUENCE-END of FLOW-MAPPING-END token. */
    match state.emitToken(tokenConstructor(startMark, endMark))
    | let e: ScanError => return e
    end
    this._scanToNextToken(state)

  /*
   * Produce the FLOW-ENTRY token.
   */
  fun ref _scanFlowEntry(state: _ScannerState): _ScanResult ? =>
    /* Reset any potential simple keys on the current flow level. */
    match state.resetSimpleKey()
    | let e: ScanError => return e
    end
    /* Simple keys are allowed after ','. */
    state.simpleKeyAllowed = true
    /* Consume the token. */
    let startMark = state.mark.clone()
    state.skip()
    let endMark = state.mark.clone()
    /* Create the FLOW-ENTRY token and append it to the queue. */
    match state.emitToken(_YamlFlowEntryToken(startMark, endMark))
    | let e: ScanError => return e
    end
    this._scanToNextToken(state)

  /*
   * Produce the BLOCK-ENTRY token.
   */
  fun ref _scanBlockEntry(state: _ScannerState): _ScanResult ? =>
    /* Check if the scanner is in the block context. */
    if state.flowLevel == 0 then
      /* Check if we are allowed to start a new entry. */
      if not state.simpleKeyAllowed then
        return ScanError(None, state.mark.clone(), "block sequence entries are not allowed in this context")
      end
      /* Add the BLOCK-SEQUENCE-START token if needed. */
      let cons = lambda (startMark: YamlMark val, endMark: YamlMark val) : _YAMLToken => _YamlBlockSequenceStartToken.create(startMark, endMark) end
      state.rollIndent(state.mark.column, cons, state.mark.clone())
    else
      /*
       * It is an error for the '-' indicator to occur in the flow context,
       * but we let the Parser detect and report about it because the Parser
       * is able to point to the context.
       */
      None
    end
    /* Reset any potential simple keys on the current flow level. */
    match state.resetSimpleKey()
    | let e: ScanError => return e
    end
    /* Simple keys are allowed after '-'. */
    state.simpleKeyAllowed = true
    /* Consume the token. */
    let startMark = state.mark.clone()
    state.skip()
    let endMark = state.mark.clone()
    /* Create the BLOCK-ENTRY token and append it to the queue. */
    match state.emitToken(_YamlBlockEntryToken(startMark, endMark))
    | let e: ScanError => return e
    end
    this._scanToNextToken(state)

  /*
   * Produce the KEY token.
   */
  fun ref _scanKey(state: _ScannerState): _ScanResult ? =>
    /* In the block context, additional checks are required. */
    if state.flowLevel == 0 then
      /* Check if we are allowed to start a new key (not nessesary simple). */
      if not state.simpleKeyAllowed then
        return ScanError(None, state.mark.clone(), "mapping keys are not allowed in this context")
      end
      /* Add the BLOCK-MAPPING-START token if needed. */
      let cons = lambda (startMark: YamlMark val, endMark: YamlMark val) : _YAMLToken => _YamlBlockMappingStartToken.create(startMark, endMark) end
      state.rollIndent(state.mark.column, cons, state.mark.clone())
    end
    /* Reset any potential simple keys on the current flow level. */
    match state.resetSimpleKey()
    | let e: ScanError => return e
    end
    /* Simple keys are allowed after '?' in the block context. */
    state.simpleKeyAllowed = state.flowLevel == 0
    /* Consume the token. */
    let startMark = state.mark.clone()
    state.skip()
    let endMark = state.mark.clone()
    /* Create the KEY token and append it to the queue. */
    match state.emitToken(_YamlKeyToken(startMark, endMark))
    | let e: ScanError => return e
    end
    this._scanToNextToken(state)

  /*
   * Produce the VALUE token.
   */
  fun ref _scanValue(state: _ScannerState): _ScanResult ? =>
    let simpleKey = state.simpleKeys(state.simpleKeys.size() - 1)
    /* Have we found a simple key? */
    if simpleKey.possible then
      /* Create the KEY token and insert it into the queue. */
      match state.emitToken(_YamlKeyToken(simpleKey.mark, simpleKey.mark), state.tokensParsed - simpleKey.tokenNumber)
      | let e: ScanError => return e
      end
      /* In the block context, we may need to add the BLOCK-MAPPING-START token. */
      let cons = lambda (startMark: YamlMark val, endMark: YamlMark val) : _YAMLToken => _YamlBlockMappingStartToken.create(startMark, endMark) end
      state.rollIndent(simpleKey.mark.column, cons, simpleKey.mark, simpleKey.tokenNumber)
      /* Remove the simple key. */
      simpleKey.possible = false
      /* A simple key cannot follow another simple key. */
      state.simpleKeyAllowed = false
    else
      /* The ':' indicator follows a complex key. */
      /* In the block context, extra checks are required. */
      if state.flowLevel == 0 then
        /* Check if we are allowed to start a complex value. */
        if not state.simpleKeyAllowed then
          return ScanError(None, state.mark.clone(), "mapping values are not allowed in this context")
        end
        /* Add the BLOCK-MAPPING-START token if needed. */
        let cons = lambda (startMark: YamlMark val, endMark: YamlMark val) : _YAMLToken => _YamlBlockMappingStartToken.create(startMark, endMark) end
        state.rollIndent(state.mark.column, cons, state.mark.clone())
      end
      /* Simple keys after ':' are allowed in the block context. */
      state.simpleKeyAllowed = state.flowLevel == 0
    end
    /* Consume the token. */
    let startMark = state.mark.clone()
    state.skip()
    let endMark = state.mark.clone()
    /* Create the VALUE token and append it to the queue. */
    match state.emitToken(_YamlValueToken(startMark, endMark))
    | let e: ScanError => return e
    end
    this._scanToNextToken(state)

  /*
   * Produce the ALIAS or ANCHOR token.
   */
  fun ref _scanAnchor(tokenConstructor: {(YamlMark val, YamlMark val, String val): _YAMLToken} val, errorName: String,
        state: _ScannerState): _ScanResult ? =>
    /* An anchor or an alias could be a simple key. */
    match state.saveSimpleKey()
    | let e: ScanError => return e
    end
    /* A simple key cannot follow an anchor or an alias. */
    state.simpleKeyAllowed = false
    /* Create the ALIAS or ANCHOR token and append it to the queue. */
    let s = _AnchorScanner.create(tokenConstructor, errorName, state.mark.clone(), this~_scanToNextToken())
    s.apply(state)

  /*
   * Produce the TAG token.
   */
  fun ref _scanTag(state: _ScannerState): _ScanResult ? =>
    /* A tag could be a simple key. */
    match state.saveSimpleKey()
    | let e: ScanError => return e
    end
    /* A simple key cannot follow a tag. */
    state.simpleKeyAllowed = false
    /* Create the TAG token and append it to the queue. */
    let s = _TagScanner.create(state.mark.clone(), this~_scanToNextToken())
    s.apply(state)

  /*
   * Produce the SCALAR(...,literal) or SCALAR(...,folded) tokens.
   */
  fun ref _scanBlockScalar(literal: Bool, state: _ScannerState): _ScanResult ? =>
    /* Remove any potential simple keys. */
    match state.resetSimpleKey()
    | let e: ScanError => return e
    end
    /* A simple key may follow a block scalar. */
    state.simpleKeyAllowed = true
    /* Create the SCALAR token and append it to the queue. */
    let s = _BlockScalarScanner.create(literal, state.mark.clone(), this~_scanToNextToken())
    s.apply(state)


  /*
   * Produce the SCALAR(...,single-quoted) or SCALAR(...,double-quoted) tokens.
   */
  fun ref _scanFlowScalar(single: Bool, state: _ScannerState): _ScanResult ? =>
    /* A plain scalar could be a simple key. */
    match state.saveSimpleKey()
    | let e: ScanError => return e
    end
    /* A simple key cannot follow a flow scalar. */
    state.simpleKeyAllowed = false
    /* Create the SCALAR token and append it to the queue. */
    let s = _FlowScalarScanner.create(single, state.mark.clone(), this~_scanToNextToken())
    s.apply(state)

  /*
   * Produce the SCALAR(...,plain) token.
   */
  fun ref _scanPlainScalar(state: _ScannerState): _ScanResult ? =>
    /* A plain scalar could be a simple key. */
    match state.saveSimpleKey()
    | let e: ScanError => return e
    end
    /* A simple key cannot follow a flow scalar. */
    state.simpleKeyAllowed = false
    /* Create the SCALAR token and append it to the queue. */
    let s = _PlainScalarScanner.create(state.mark.clone(), this~_scanToNextToken())
    s.apply(state)
