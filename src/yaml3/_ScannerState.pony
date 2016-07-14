
class _ScannerState
  var _scanner: _Scanner = _RootScanner.create()
  let mark: YamlMark = YamlMark.create()
  let _data: Array[U8] = Array[U8].create(1024)
  var _pos: USize = 0
  var simpleKeyAllowed: Bool = true
  var flowLevel: USize = 0
  var indent: USize = 0
  let indents: Array[USize] = Array[USize].create(5)
  let simpleKeys: Array[_YamlSimpleKey] ref = Array[_YamlSimpleKey].create(5)
  var tokensParsed: USize = 0
  let _tokenBuffer: Array[_YAMLToken] ref = Array[_YAMLToken].create(5)

  fun ref append(data: Array[U8] val) =>
    _data.append(data)

  fun ref run(): (ScanDone | ScanPaused | ScanError) ? =>
    match _scanner.apply(this)
    | let p: ScanPaused => _scanner = p.nextScanner; p
    | let e: ScanError => e
    | ScanDone => ScanDone
    else
      error
    end

  fun ref emitToken(token: _YAMLToken, offset: USize = 0): (ScanError | None) ? =>
    let hasPossibleSimpleKeys: Bool = match _removeStaleSimpleKeys()
    | let e: ScanError => return e
    | let b: Bool => b
    else
      error
    end
    if hasPossibleSimpleKeys then
      _tokenBuffer.insert(_tokenBuffer.size() - offset, token)
    elseif offset != 0 then
      error
    else
      if _tokenBuffer.size() > 0 then
        for t in _tokenBuffer.values() do
          _doEmitToken(t)
        end
        _tokenBuffer.truncate(0)
      end
      _doEmitToken(token)
    end
    tokensParsed = tokensParsed + 1
    None

  fun _doEmitToken(token: _YAMLToken) =>
    None

  /*
   * Increase the flow level and resize the simple key list if needed.
   */
  fun ref increaseFlowLevel() =>
    /* Reset the simple key on the next level. */
    simpleKeys.push(_YamlSimpleKey.createStub())
    flowLevel = flowLevel + 1

  /*
   * Decrease the flow level.
   */
  fun ref decreaseFlowLevel() ? =>
    if flowLevel > 0 then
      flowLevel = flowLevel - 1
      simpleKeys.pop()
    end

  /*
   * Push the current indentation level to the stack and set the new level
   * the current column is greater than the indentation level.  In this case,
   * append or insert the specified token into the token queue.
   *
   */
  fun ref rollIndent(column: USize, tokenConstructor: {(YamlMark val, YamlMark val) : _YAMLToken} val,
                  m: YamlMark val, number: (USize | None) = None) ? =>
    /* In the flow context, do nothing. */
    if flowLevel > 0 then
      return
    end

    if indent < column then
      /*
       * Push the current indentation level to the stack and set the new
       * indentation level.
       */
      indents.push(indent)
      indent = column
      /* Create a token and insert it into the queue. */
      let token = tokenConstructor(m, m)
      match number
      | None => emitToken(token)
      | let n: USize => emitToken(token, tokensParsed - n)
      else
        error
      end
    end

  /*
   * Pop indentation levels from the indents stack until the current level
   * becomes less or equal to the column.  For each intendation level, append
   * the BLOCK-END token.
   */
  fun ref unrollIndent(column: (USize | None) = None) ? =>
    /* In the flow context, do nothing. */
    if flowLevel > 0 then
      return
    end

    let limit = match column
    | None => -1
    | let c: USize => c
    else
      error
    end

    /* Loop through the intendation levels in the stack. */
    while indent > limit do
      /* Create a token and append it to the queue. */
      let m = mark.clone()
      emitToken(_YamlBlockEndToken(m, m))
      /* Pop the indentation level. */
      indent = indents.pop()
    end

  /*
   * Check if a simple key may start at the current position and add it if
   * needed.
   */
  fun ref saveSimpleKey(): (ScanError | None) ? =>
    /*
     * If the current position may start a simple key, save it.
     */
    if simpleKeyAllowed then
      /* check if a simple key was already set */
      let simpleKey = simpleKeys(simpleKeys.size() - 1)
      if simpleKey.possible then
        /* If the key is required, it is an error. */
        if simpleKey.required then
          return ScanError("while scanning a simple key", simpleKey.mark, "could not find expected ':'")
        end
      end
      /* set the new simple key */
      simpleKey.possible = true
      /*
       * A simple key is required at the current position if the scanner is in
       * the block context and the current column coincides with the indentation
       * level.
       */
      simpleKey.required = (flowLevel == 0) and (indent == mark.column)
      simpleKey.tokenNumber = tokensParsed
      simpleKey.mark = mark.clone()
    end
    None

  /*
   * Remove a potential simple key at the current flow level.
   */
  fun ref resetSimpleKey(): (ScanError | None) ? =>
    let simpleKey = simpleKeys(simpleKeys.size() - 1)
    if simpleKey.possible then
      /* If the key is required, it is an error. */
      if simpleKey.required then
        return ScanError("while scanning a simple key", simpleKey.mark, "could not find expected ':'")
      end
    end
    /* Remove the key from the stack. */
    simpleKey.possible = false
    None

  /*
   * Check the list of potential simple keys and remove the positions that
   * cannot contain simple keys anymore.
   */
  fun ref _removeStaleSimpleKeys(): (ScanError | Bool) ? =>
    var hasPossibleSimpleKeys: Bool = false
    /* Check for a potential simple key for each flow level. */
    for simpleKey in simpleKeys.values() do
      /*
       * The specification requires that a simple key
       *
       *  - is limited to a single line,
       *  - is shorter than 1024 characters.
       */
      if simpleKey.possible then
        if (simpleKey.mark.line < mark.line) or ((simpleKey.mark.index + 1024) < mark.index) then
          /* Check if the potential simple key to be removed is required. */
          if simpleKey.required then
              return ScanError("while scanning a simple key", simpleKey.mark, "could not find expected ':'")
          end
          simpleKey.possible = false
        else
          hasPossibleSimpleKeys = true
        end
      end
    end
    /* Check the indentation level against the current column. */
    unrollIndent(mark.column)
    hasPossibleSimpleKeys

  fun available(nb: USize = 1): Bool =>
    (_data.size() - _pos) >= nb

  /*
   * Determine the width of the character.
   */
  fun width(): USize ? =>
    let char = _data(_pos)
    if (char and 0x80) == 0x00 then 1
    elseif (char and 0xE0) == 0xC0 then 2
    elseif (char and 0xF0) == 0xE0 then 3
    elseif (char and 0xF8) == 0xF0 then 4
    else 0
    end

  fun at(i: USize = 0): U8 ? =>
    _data(_pos + i)

  fun ref skip(nb: USize = 1) ? =>
    mark.index = mark.index + nb
    mark.column = mark.column + nb
    var n = nb
    while n > 0 do
      _pos = _pos + width()
      n = n - 1
    end

  fun ref skipLine() ? =>
    if isCrlf() then
      mark.index = mark.index + 2
      mark.column = 0
      mark.line = mark.line + 1
      _pos = _pos + 2
    elseif isBreak() then
      mark.index = mark.index + 1
      mark.column = 0
      mark.line = mark.line + 1
      _pos = _pos + width()
    end

  fun ref read(s: String iso): (ScanError | String iso^) ? =>
    let char = _data(_pos)
    if (char and 0x80) == 0x00 then
      s.push(char)
      _pos = _pos + 1
    elseif (char and 0xE0) == 0xC0 then
      s.push(char)
      s.push(_data(_pos + 1))
      _pos = _pos + 2
    elseif (char and 0xF0) == 0xE0 then
      s.push(char)
      s.push(_data(_pos + 1))
      s.push(_data(_pos + 2))
      _pos = _pos + 2
    elseif (char and 0xF8) == 0xF0 then
      s.push(char)
      s.push(_data(_pos + 1))
      s.push(_data(_pos + 2))
      s.push(_data(_pos + 3))
      _pos = _pos + 3
    else
      return ScanError("Invalid caracter", mark.clone(), "")
    end
    mark.index = mark.index + 1
    mark.column = mark.column + 1
    consume s

  fun ref readLine(s: String iso): (ScanError | String iso^) ? =>
    if check('\r') and check('\n', 1) then        /* CR LF -> LF */
      s.push('\n')
      _pos = _pos + 2
      mark.index = mark.index + 2
      mark.column = 0
      mark.line = mark.line + 1
    elseif check('\r') or check('\n') then         /* CR|LF -> LF */
      s.push('\n')
      _pos = _pos + 1
      mark.index = mark.index + 1
      mark.column = 0
      mark.line = mark.line + 1
    elseif check('\xC2') and check('\x85', 1) then       /* NEL -> LF */
      s.push('\n')
      _pos = _pos + 2
      mark.index = mark.index + 1
      mark.column = 0
      mark.line = mark.line + 1
    elseif check('\xE2') and check('\x80', 1) and (check('\xA8', 2) or check('\xA9', 2)) then  /* LS|PS -> LS|PS */
      s.push(_data(_pos = _pos + 1))
      s.push(_data(_pos = _pos + 1))
      s.push(_data(_pos = _pos + 1))
      mark.index = mark.index + 1
      mark.column = 0
      mark.line = mark.line + 1
    else
      error
    end
    consume s


  /*
   * Check the current octet in the buffer.
   */
  fun check(char: U8, offset: USize = 0): Bool ? =>
    _data(_pos + offset) == char

  /*
   * Check if the character at the specified position is an alphabetical
   * character, a digit, '_', or '-'.
   */
  fun isAlpha(offset: USize = 0): Bool ? =>
    let char = _data(_pos + offset)
    ((char >= '0') and (char <= '9'))
       or ((char >= 'A') and (char <= 'Z'))
       or ((char >= 'a') and (char <= 'z'))
       or (char == '_')
       or (char == '-')


  /*
   * Check if the character at the specified position is a digit.
   */
  fun isDigit(offset: USize = 0): Bool ? =>
    let char = _data(_pos + offset)
    (char >= '0') and (char <= '9')

  /*
   * Get the value of a digit.
   */
  fun asDigit(offset: USize = 0): U8 ? =>
    _data(_pos + offset) - '0'

  /*
   * Check if the character at the specified position is a hex-digit.
   */
  fun isHex(offset: USize = 0): Bool ? =>
    let char = _data(_pos + offset)
    ((char >= '0') and (char <= '9'))
      or ((char >= 'A') and (char <= 'F'))
      or ((char >= 'a') and (char <= 'f'))

  /*
   * Get the value of a hex-digit.
   */
  fun asHex(offset: USize = 0): U8 ? =>
    let char = _data(_pos + offset)
    match char
    | let c: U8 if (c >= 'A') and (c <= 'F') => (c - 'A') + 10
    | let c: U8 if (c >= 'a') and (c <= 'f') => (c - 'a') + 10
    else
      char - '0'
    end

  /*
   * Check if the character is ASCII.
   */
  fun isAscii(offset: USize = 0): Bool ? =>
    let char = _data(_pos + offset)
    char <= '\x7F'

  /*
   * Check if the character can be printed unescaped.
   */
  fun isPrintable(offset: USize = 0): Bool ? =>
    let char = _data(_pos + offset)
    ((char == 0x0A)         /* . == #x0A */
     or ((char >= 0x20)       /* #x20 <= . <= #x7E */
         and (char <= 0x7E))
     or ((char == 0xC2)       /* #0xA0 <= . <= #xD7FF */
         and (_data(_pos + offset + 1) >= 0xA0))
     or ((char > 0xC2)
         and (char < 0xED))
     or ((char == 0xED)
         and (_data(_pos + offset + 1) < 0xA0))
     or (char == 0xEE)
     or ((char == 0xEF)      /* #xE000 <= . <= #xFFFD */
         and not ((_data(_pos + offset + 1) == 0xBB)        /* and . != #xFEFF */
                  and (_data(_pos + offset + 2) == 0xBF))
         and not ((_data(_pos + offset + 1) == 0xBF)
                  and ((_data(_pos + offset + 2) == 0xBE)
                       or (_data(_pos + offset + 2) == 0xBF)))))

  /*
   * Check if the character at the specified position is NUL.
   */
  fun isZ(offset: USize = 0): Bool ? =>
    _data(_pos + offset) == '\0'

  /*
   * Check if the character at the specified position is BOM.
   */
  fun isBom(offset: USize = 0): Bool ? =>
    (_data(_pos + offset) == '\xEF')
      and (_data(_pos + offset + 1) == '\xBB')
      and (_data(_pos + offset + 2) == '\xBF')  /* BOM (#xFEFF) */

  /*
   * Check if the character at the specified position is space.
   */
  fun isSpace(offset: USize = 0): Bool ? =>
    _data(_pos + offset) == ' '

  /*
   * Check if the character at the specified position is tab.
   */
  fun isTab(offset: USize = 0): Bool ? =>
    _data(_pos + offset) == '\t'

  /*
   * Check if the character at the specified position is blank (space or tab).
   */
  fun isBlank(offset: USize = 0): Bool ? =>
    isSpace(offset) or isTab(offset)

  /*
   * Check if the character at the specified position is a line break.
   */
  fun isBreak(offset: USize = 0): Bool ? =>
    (_data(_pos + offset) == '\r')                  /* CR (#xD)*/
      or (_data(_pos + offset) == '\n')             /* LF (#xA) */
      or ((_data(_pos + offset) == '\xC2')
        and (_data(_pos + offset + 1) == '\x85'))   /* NEL (#x85) */
      or ((_data(_pos + offset) == '\xE2')
        and (_data(_pos + offset + 1) == '\x80')
        and (_data(_pos + offset + 2) == '\xA8'))   /* LS (#x2028) */
      or ((_data(_pos + offset) == '\xE2')
        and (_data(_pos + offset + 1) == '\x80')
        and (_data(_pos + offset + 2) == '\xA9'))   /* PS (#x2029) */

  fun isCrlf(offset: USize = 0): Bool ? =>
    (_data(_pos + offset) == '\r') and (_data(_pos + offset + 1) == '\n')

  /*
   * Check if the character is a line break or NUL.
   */
  fun isBreakZ(offset: USize = 0): Bool ? =>
    isBreak(offset) or isZ(offset)

  /*
   * Check if the character is a line break, space, or NUL.
   */
  fun isSpaceZ(offset: USize = 0): Bool ? =>
    isSpace(offset) or isBreakZ(offset)

  /*
   * Check if the character is a line break, space, tab, or NUL.
   */
  fun isBlankZ(offset: USize = 0): Bool ? =>
    isBlank(offset) or isBreakZ(offset)
