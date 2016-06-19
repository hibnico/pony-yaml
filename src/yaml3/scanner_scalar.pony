
class _ScalarBlanks
  var leadingBreak: (None | String trn) = recover String.create() end
  var trailingBreaks: (None | String trn) = recover String.create() end
  var whitespaces: (None | String trn) = recover String.create() end
  var leadingBlank: Bool = false
  var trailingBlank: Bool = false


class _BlockScalarScanner is _Scanner
  let _literal: Bool
  let _startMark: YamlMark val
  let _endMark: Option[YamlMark val] = Option[YamlMark val].none()
  let _nextScanner: _Scanner
  var _string: (None | String trn) = recover String.create() end
  let _scalarBlanks: _ScalarBlanks = _ScalarBlanks.create()
  var _chompLeading: Bool = false
  var _chompTrailing: Bool = true
  var _increment: U8 = 0
  var _indent: USize = 0
  var _blockScalarBreaksScanner: (None | _BlockScalarBreaksScanner) = None

  new create(literal: Bool, startMark: YamlMark val, nextScanner: _Scanner) =>
    _literal = literal
    _startMark = startMark
    _nextScanner = nextScanner

  fun ref apply(state: _ScannerState): _ScanResult ? =>
    /* Eat the indicator '|' or '>'. */
    state.skip()
    let s: _LineTrailScanner = _LineTrailScanner.create()
    let skipWhitespace = s~scan(_startMark, "while scanning a block scalar", this~_scanBlockScalarBreaks())
    // Note: The following lines of code are about chaining scanners
    // TODO: may not be the best way to handle it, since it creates scanners which will never be used
    // First, try to scan a method
    this._scanChompingMethod(
      // if successful, then try to scan an indent
      this~_scanIndentIndicator(
        // and then, either present or absent, o skip the whitespaces
        skipWhitespace, skipWhitespace
      ),
      // otherwise try to scan an indent
      this~_scanIndentIndicator(
        // if indent found, then check for a method
        this~_scanChompingMethod(
          // and finally go to skip the whitespaces
          skipWhitespace, skipWhitespace
        ),
        // nothing found: go skip the whitespaces
        skipWhitespace
      ),
      state
    )

  fun ref _scanChompingMethod(nextScannerIfPresent: _Scanner, nextScannerIfAbsent: _Scanner, state: _ScannerState): _ScanResult ? =>
    if not state.available() then
      return ScanPaused(this~_scanChompingMethod(nextScannerIfPresent, nextScannerIfAbsent))
    end
    /* Set the chomping method and eat the indicator. */
    if state.check('+') then
      /* Set the chomping method and eat the indicator. */
      _chompTrailing = false
      state.skip()
      nextScannerIfPresent.apply(state)
    elseif state.check('-') then
      /* Set the chomping method and eat the indicator. */
      _chompLeading = true
      _chompTrailing = false
      state.skip()
      nextScannerIfPresent.apply(state)
    else
      nextScannerIfAbsent.apply(state)
    end

  /* Check for an indentation indicator. */
  fun ref _scanIndentIndicator(nextScannerIfPresent: _Scanner, nextScannerIfAbsent: _Scanner, state: _ScannerState): _ScanResult ? =>
    if not state.available() then
      return ScanPaused(this~_scanIndentIndicator(nextScannerIfPresent, nextScannerIfAbsent))
    end
    if state.isDigit() then
      if state.check('0') then
        return ScanError("while scanning a block scalar", _startMark, "found an intendation indicator equal to 0")
      end
      _increment = state.asDigit()
      state.skip()
      nextScannerIfPresent.apply(state)
    else
      nextScannerIfAbsent.apply(state)
    end

  fun ref _scanBlockScalarBreaks(state: _ScannerState): _ScanResult ? =>
    _endMark.set(state.mark.clone())
    /* Set the intendation level if it was specified. */
    if _increment != 0 then
      _indent = if state.indent >= 0 then state.indent + _increment.usize() else _increment.usize() end
    end
    /* Scan the leading line breaks and determine the indentation level if needed. */
    let s = _BlockScalarBreaksScanner.create(_indent, (_scalarBlanks.trailingBreaks = None) as String trn^, _startMark,
              _endMark.value(), this~_endBlockScalarBreaks())
    _blockScalarBreaksScanner = s
    s.apply(state)

  fun ref _endBlockScalarBreaks(state: _ScannerState): _ScanResult ? =>
    let blockScalarBreaksScanner = _blockScalarBreaksScanner as _BlockScalarBreaksScanner
    _indent = blockScalarBreaksScanner.indent
    _scalarBlanks.trailingBreaks = blockScalarBreaksScanner.breaks = None
    this._scanContent(state)

  /* Scan the block scalar content. */
  fun ref _scanContent(state: _ScannerState): _ScanResult ? =>
    if not state.available() then
      return ScanPaused(this~_scanContent())
    end
    if (state.mark.column == _indent) and not state.isZ() then
      /*
       * We are at the beginning of a non-empty line.
       */
      /* Is it a trailing whitespace? */
      _scalarBlanks.trailingBlank = state.isBlank()
      /* Check if we need to fold the leading line break. */
      if not _literal and ((_scalarBlanks.leadingBreak as String trn).size() > 0)
          and not _scalarBlanks.leadingBlank and not _scalarBlanks.trailingBlank then
        /* Do we need to join the lines by space? */
        if (_scalarBlanks.trailingBreaks as String trn).size() == 0 then
          (_string as String trn).push(' ')
        end
        (_scalarBlanks.leadingBreak as String trn).clear()
      else
        (_string as String trn).append((_scalarBlanks.leadingBreak as String trn).clone())
        (_scalarBlanks.leadingBreak as String trn).clear()
      end
      /* Append the remaining line breaks. */
      (_string as String trn).append((_scalarBlanks.trailingBreaks as String trn).clone())
      (_scalarBlanks.trailingBreaks as String trn).clear()
      /* Is it a leading whitespace? */
      _scalarBlanks.leadingBlank = state.isBlank()
      return this._scanCurrentLine(state)
    end
    /* Chomp the tail. */
    if not _chompLeading then
      (_string as String trn).append((_scalarBlanks.leadingBreak as String trn).clone())
    end
    if not _chompTrailing then
      (_string as String trn).append((_scalarBlanks.trailingBreaks as String trn).clone())
    end
    /* Create a token. */
    state.emitToken(_YamlScalarToken(_startMark, _endMark.value(), (_string = None) as String trn^,
      if _literal then _YamlLiteralScalarStyle else _YamlFoldedScalarStyle end))
    _nextScanner.apply(state)


  /* Consume the current line. */
  fun ref _scanCurrentLine(state: _ScannerState): _ScanResult ? =>
    while not state.isBreakZ() do
      match state.read((_string = None) as String trn^)
      | let e: ScanError => return e
      | let s: String trn => _string = consume s
      else
        error
      end
      if not state.available() then
        return ScanPaused(this~_scanCurrentLine())
      end
    end
    this._readLine(state)


  fun ref _readLine(state: _ScannerState): _ScanResult ? =>
    /* Consume the line break. */
    if not state.available(2) then
      return ScanPaused(this~_readLine())
    end
    match state.readLine((_scalarBlanks.leadingBreak = None) as String trn^)
    | let e: ScanError => return e
    | let s: String trn => _scalarBlanks.leadingBreak = consume s
    else
      error
    end
    /* Eat the following intendation spaces and line breaks. */
    let s = _BlockScalarBreaksScanner.create(_indent, (_scalarBlanks.trailingBreaks = None) as String trn^, _startMark,
              _endMark.value(), this~_endBlockScalarBreaks())
    _blockScalarBreaksScanner = s
    s.apply(state)


/*
 * Scan intendation spaces and line breaks for a block scalar.  Determine the
 * intendation level if needed.
 */
class _BlockScalarBreaksScanner is _Scanner
  let _startMark: YamlMark val
  let _endMark: YamlMark val
  let _nextScanner: _Scanner
  var breaks: (None | String trn)
  var indent : USize
  var _maxIndent: USize = 0

  new create(indent': USize, breaks': String trn, startMark: YamlMark val, endMark: YamlMark val, nextScanner: _Scanner) =>
    indent = indent'
    _startMark = startMark
    _endMark = endMark
    breaks = consume breaks'
    _nextScanner = nextScanner

  fun ref apply(state: _ScannerState): _ScanResult ? =>
    /* Eat the intendation spaces and line breaks. */
    if not state.available() then
      return ScanPaused(this)
    end
    while ((indent == 0) or (state.mark.column < indent)) and state.isSpace() do
      state.skip()
      if not state.available() then
        return ScanPaused(this)
      end
    end
    if state.mark.column > _maxIndent then
      _maxIndent = state.mark.column
    end
    /* Check for a tab character messing the intendation. */
    if ((indent == 0) or (state.mark.column < indent)) and state.isTab() then
      return ScanError("while scanning a block scalar", _startMark, "found a tab character where an intendation space is expected")
    end
    /* Have we found a non-empty line? */
    if not state.isBreak() then
      this._scanEnd(state)
    else
      /* Consume the line break. */
      this._scanLineBreak(state)
    end

  fun ref _scanLineBreak(state: _ScannerState): _ScanResult ? =>
    if not state.available(2) then
      return ScanPaused(this~_scanLineBreak())
    end
    match state.read((breaks = None) as String trn^)
    | let b: String trn => breaks = consume b
    | let e: ScanError => return e
    else
      error
    end
    this.apply(state)

  fun ref _scanEnd(state: _ScannerState): _ScanResult ? =>
    /* Determine the indentation level if needed. */
    if indent == 0 then
      indent = _maxIndent
      if indent < (state.indent + 1) then
        indent = state.indent + 1
      end
      if indent < 1 then
        indent = 1
      end
    end
    _nextScanner.apply(state)


/*
 * Scan a quoted scalar.
 */
class _FlowScalarScanner is _Scanner
  let _single: Bool
  let _nextScanner: _Scanner
  let _startMark: YamlMark val
  var _string: (None | String trn) = recover String.create() end
  var _scalarBlanks: _ScalarBlanks trn = recover _ScalarBlanks.create() end

  new create(single: Bool, startMark: YamlMark val, nextScanner: _Scanner) =>
    _single = single
    _startMark = startMark
    _nextScanner = nextScanner

  fun ref apply(state: _ScannerState): _ScanResult ? =>
    /* Eat the left quote. */
    state.skip()
    this._scanContent(state)

  /* Consume the content of the quoted scalar. */
  fun ref _scanContent(state: _ScannerState): _ScanResult ? =>
    /* Check that there are no document indicators at the beginning of the line. */
    if not state.available(4) then
      return ScanPaused(this~_scanContent())
    end
    if ((state.mark.column == 0) and
        ((state.check('-', 0) and
          state.check('-', 1) and
          state.check('-', 2)) or
         (state.check('.', 0) and
          state.check('.', 1) and
          state.check('.', 2))) and
        state.isBlankZ(3)) then
      return ScanError("while scanning a quoted scalar", _startMark, "found unexpected document indicator")
    end

    /* Check for EOF. */
    if state.isZ() then
      return ScanError("while scanning a quoted scalar", _startMark, "found unexpected end of stream")
    end
    _scalarBlanks.leadingBlank = false
    this._scanNonBlank(state)

  fun ref _scanNonBlank(state: _ScannerState): _ScanResult ? =>
    /* Consume non-blank characters. */
    if not state.available(2) then
      return ScanPaused(this~_scanNonBlank())
    end
    while not state.isBlankZ() do
      /* Check for an escaped single quote. */
      if (_single and state.check('\'') and state.check('\'', 1)) then
        (_string as String trn).push('\'')
        state.skip(2)
      /* Check for the right quote. */
      elseif (state.check(if _single then '\'' else '"' end)) then
        break
      /* Check for an escaped line break. */
      elseif (not _single and state.check('\\') and state.isBreak(1)) then
        return this._scanEscapedEndLine(state)
      /* Check for an escape sequence. */
      elseif (not _single and state.check('\\')) then
        var codeLength : USize = 0
        /* Check the escape character. */
        match _checkEscapeChar(state.at(1), (_string = None) as String trn^)
        | let e: ScanError => return e
        | (let l: USize, let s: String trn) => codeLength = l; _string = consume s
        else
          error
        end
        state.skip(2)
        /* Consume an arbitrary escape code. */
        if codeLength > 0 then
          return this._scanEscapeCode(codeLength, state)
        end
      else
        /* It is a non-escaped non-blank character. */
        match state.read((_string = None) as String trn^)
        | let e: ScanError => return e
        | let s: String trn => _string = consume s
        else
          error
        end
      end
      if not state.available(2) then
        return ScanPaused(this~_scanNonBlank())
      end
    end
    this._scanEndNonBlank(state)

  fun ref _scanEscapedEndLine(state: _ScannerState): _ScanResult ? =>
    if not state.available(3) then
      return ScanPaused(this~_scanEscapedEndLine())
    end
    state.skip()
    state.skipLine()
    _scalarBlanks.leadingBlank = true
    this._scanEndNonBlank(state)

  fun ref _scanEndNonBlank(state: _ScannerState): _ScanResult ? =>
    /* Check if we are at the end of the scalar. */
    if state.check(if _single then '\'' else '"' end) then
      this._scanContentEnd(state)
    else
      this._scanBlank(state)
    end

  fun ref _scanEscapeCode(codeLength: USize, state: _ScannerState): _ScanResult ? =>
    /* Scan the character value. */
    if state.available(codeLength) then
      return ScanPaused(this~_scanEscapeCode(codeLength))
    end
    var value: U32 = 0
    var i: USize = 0
    while i < codeLength do
      if not state.isHex(i) then
        return ScanError("while parsing a quoted scalar", _startMark, "did not find expected hexdecimal number")
      end
      value = (value << 4) + state.asHex(i = i + 1).u32()
    end

    /* Check the value and write the character. */
    if (((value >= 0xD800) and (value <= 0xDFFF)) or (value > 0x10FFFF)) then
      return ScanError("while parsing a quoted scalar", _startMark, "found invalid Unicode character escape code")
    end

    _string = _pushEscapedValue((_string = None) as String trn^, value)

    /* Advance the pointer. */
    state.skip(codeLength)
    this._scanNonBlank(state)

  fun _checkEscapeChar(char: U8, s: String trn): (ScanError | (USize, String trn^)) =>
    var codeLength : USize = 0
    match char
    | '0' => s.push('\0')
    | 'a' => s.push('\x07')
    | 'b' => s.push('\x08')
    | 't' => s.push('\x09')
    | '\t' => s.push('\x09')
    | 'n' => s.push('\x0A')
    | 'v' => s.push('\x0B')
    | 'f' => s.push('\x0C')
    | 'r' => s.push('\x0D')
    | 'e' => s.push('\x1B')
    | ' ' => s.push('\x20')
    | '"' => s.push('"')
    | '\'' => s.push('\'')
    | '\\' => s.push('\\')
    | 'N' => s.push('\xC2'); s.push('\x85')   /* NEL (#x85) */
    | '_' => s.push('\xC2'); s.push('\xA0')   /* #xA0 */
    | 'L' => s.push('\xE2'); s.push('\x80'); s.push('\xA8')   /* LS (#x2028) */
    | 'P' => s.push('\xE2'); s.push('\x80'); s.push('\xA9')   /* PS (#x2029) */
    | 'x' => codeLength = 2
    | 'u' => codeLength = 4
    | 'U' => codeLength = 8
    else
      ScanError("while parsing a quoted scalar", _startMark, "found unknown escape character")
    end
    (codeLength, consume s)

  fun _pushEscapedValue(s: String trn, value: U32): String trn^ =>
    if (value <= 0x7F) then
      s.push(value.u8())
    elseif (value <= 0x7FF) then
      s.push(0xC0 + (value >> 6).u8())
      s.push(0x80 + (value and 0x3F).u8())
    elseif (value <= 0xFFFF) then
      s.push(0xE0 + (value >> 12).u8())
      s.push(0x80 + ((value >> 6) and 0x3F).u8())
      s.push(0x80 + (value and 0x3F).u8())
    else
      s.push(0xF0 + (value >> 18).u8())
      s.push(0x80 + ((value >> 12) and 0x3F).u8())
      s.push(0x80 + ((value >> 6) and 0x3F).u8())
      s.push(0x80 + (value and 0x3F).u8())
    end
    consume s

  fun ref _scanBlank(state: _ScannerState): _ScanResult ? =>
    /* Consume blank characters. */
    if not state.available() then
      return ScanPaused(this~_scanBlank())
    end

    while state.isBlank() or state.isBreak() do
      if state.isBlank() then
        /* Consume a space or a tab character. */
        if not _scalarBlanks.leadingBlank then
          match state.read((_scalarBlanks.whitespaces = None) as String trn^)
          | let e: ScanError => return e
          | let s: String trn => _scalarBlanks.whitespaces = consume s
          else
            error
          end
        else
          state.skip()
        end
      else
        let s: _FirstLineBreakScanner = _FirstLineBreakScanner.create(_scalarBlanks, this~_scanBlank())
        return s.apply(state)
      end
      if not state.available() then
        return ScanPaused(this~_scanBlank())
      end
    end
    /* Join the whitespaces or fold line breaks. */
    if _scalarBlanks.leadingBlank then
      /* Do we need to fold line breaks? */
      if ((_scalarBlanks.leadingBreak as String trn).size() > 0) and ((_scalarBlanks.leadingBreak as String trn)(0) == '\n') then
        if (_scalarBlanks.trailingBreaks as String trn).size() == 0 then
          (_string as String trn).push(' ')
        else
          (_string as String trn).append((_scalarBlanks.trailingBreaks as String trn).clone())
          (_scalarBlanks.trailingBreaks as String trn).clear()
        end
        (_scalarBlanks.leadingBreak as String trn).clear()
      else
        (_string as String trn).append((_scalarBlanks.leadingBreak as String trn).clone())
        (_string as String trn).append((_scalarBlanks.trailingBreaks as String trn).clone())
        (_scalarBlanks.leadingBreak as String trn).clear()
        (_scalarBlanks.trailingBreaks as String trn).clear()
      end
    else
      (_string as String trn).append((_scalarBlanks.whitespaces as String trn).clone())
      (_scalarBlanks.whitespaces as String trn).clear()
    end

  fun ref _endFirstLineBreak(state: _ScannerState): _ScanResult ? =>
    let s: _FirstLineBreakScanner = _firstLineBreakScanner as _FirstLineBreakScanner
    _scalarBlanks = (s._scalarBlanks = None) as _scalarBlanks

  fun ref _scanContentEnd(state: _ScannerState): _ScanResult ? =>
    /* Eat the right quote. */
    state.skip()
    let endMark = state.mark.clone()
    /* Create a token. */
    state.emitToken(_YamlScalarToken(_startMark, endMark, (_string = None) as String trn^,
        if _single then _YamlSingleQuotedScalarStyle else _YamlDoubleQuotedScalarStyle end))
    _nextScanner.apply(state)


class _FirstLineBreakScanner

  var _scalarBlanks: (None | _ScalarBlanks trn)
  var _nextScanner: _Scanner

  new create(scalarBlanks: _ScalarBlanks trn, nextScanner: _Scanner) =>
    _scalarBlanks = scalarBlanks
    _nextScanner = nextScanner

  fun ref apply(state: _ScannerState): _ScanResult ? =>
    if not state.available(2) then
      return ScanPaused(this)
    end
    /* Check if it is a first line break. */
    if not (_scalarBlanks as _ScalarBlanks trn).leadingBlank then
      ((_scalarBlanks as _ScalarBlanks trn).whitespaces as String trn).clear()
      match state.readLine(((_scalarBlanks as _ScalarBlanks trn).leadingBreak = None) as String trn^)
      | let e: ScanError => return e
      | let s: String trn => (_scalarBlanks as _ScalarBlanks trn).leadingBreak = consume s
      else
        error
      end
      (_scalarBlanks as _ScalarBlanks trn).leadingBlank = true
    else
      match state.readLine(((_scalarBlanks as _ScalarBlanks trn).trailingBreaks = None) as String trn^)
      | let e: ScanError => return e
      | let s: String trn => (_scalarBlanks as _ScalarBlanks trn).trailingBreaks = consume s
      else
        error
      end
    end
    nextScanner.apply(state)

/*
 * Scan a plain scalar.
 */
class _PlainScalarScanner is _Scanner
  let _nextScanner: _Scanner
  let _startMark: YamlMark val
  var _endMark: YamlMark val
  var _string: (None | String trn) = None
  var _scalarBlanks: _ScalarBlanks trn = recover _ScalarBlanks.create() end
  var _indent: USize = 0

  new create(startMark: YamlMark val, nextScanner: _Scanner) =>
    _nextScanner = nextScanner
    _startMark = startMark
    _endMark = _startMark

  fun ref apply(state: _ScannerState): _ScanResult ? =>
    _indent = state.indent + 1
    this._scanContent(state)

  /* Consume the content of the plain scalar. */
  fun ref _scanContent(state: _ScannerState): _ScanResult ? =>
    /* Check for a document indicator. */
    if not state.available(4) then
      return ScanPaused(this~_scanContent())
    end
    if ((state.mark.column == 0) and
        ((state.check('-', 0) and
          state.check('-', 1) and
          state.check('-', 2)) or
         (state.check('.', 0) and
          state.check('.', 1) and
          state.check('.', 2))) and
        state.isBlankZ(3)) then
      return this._scanEnd(state)
    end
    /* Check for a comment. */
    if state.check('#') then
      return this._scanEnd(state)
    end
    this._scanNonBlank(state)


  fun ref _scanNonBlank(state: _ScannerState): _ScanResult ? =>
    if not state.available(2) then
      return ScanPaused(this~_scanNonBlank())
    end
    /* Consume non-blank characters. */
    while not state.isBlankZ() do
      /* Check for 'x:x' in the flow context. TODO: Fix the test "spec-08-13". */
      if (state.flowLevel > 0) and state.check(':') and not state.isBlankZ(1) then
        return ScanError("while scanning a plain scalar", _startMark, "found unexpected ':'")
      end

      /* Check for indicators that may end a plain scalar. */
      if ((state.check(':') and state.isBlankZ(1))
              or ((state.flowLevel > 0) and
                  (state.check(',') or state.check(':')
                   or state.check('?') or state.check('[')
                   or state.check(']') or state.check('{')
                   or state.check('}')))) then
        return this._scanNonBlankEnd(state)
      end

      /* Check if we need to join whitespaces and breaks. */
      if _scalarBlanks.leadingBlank or ((_scalarBlanks.whitespaces as String trn).size() > 0) then
        if _scalarBlanks.leadingBlank then
          /* Do we need to fold line breaks? */
          if ((_scalarBlanks.leadingBreak as String trn).size() > 0) and ((_scalarBlanks.leadingBreak as String trn)(0) == '\n') then
            if (_scalarBlanks.trailingBreaks as String trn).size() == 0 then
              (_string as String trn).push(' ')
            else
              (_string as String trn).append((_scalarBlanks.trailingBreaks as String trn).clone())
              (_scalarBlanks.trailingBreaks as String trn).clear()
            end
            (_scalarBlanks.leadingBreak as String trn).clear()
          else
            (_string as String trn).append((_scalarBlanks.leadingBreak as String trn).clone())
            (_string as String trn).append((_scalarBlanks.trailingBreaks as String trn).clone())
            (_scalarBlanks.leadingBreak as String trn).clear()
            (_scalarBlanks.trailingBreaks as String trn).clear()
          end
          _scalarBlanks.leadingBlank = false
        else
          (_string as String trn).append((_scalarBlanks.whitespaces as String trn).clone())
          (_scalarBlanks.whitespaces as String trn).clear()
        end
      end
      /* Copy the character. */
      match state.read((_string = None) as String trn^)
      | let e: ScanError => return e
      | let s: String trn => _string = consume s
      else
        error
      end
      _endMark = state.mark.clone()
      if not state.available(2) then
        return ScanPaused(this~_scanNonBlank())
      end
    end
    /* Is it the end? */
    if not (state.isBlank() or state.isBreak()) then
      return this.endloop(state)
    end
    this._scanBlank(state)


  fun ref _scanBlank(state: _ScannerState): _ScanResult ? =>
    /* Consume blank characters. */
    if not state.available() then
      return ScanPaused(this~_scanBlank())
    end
    while state.isBlank() or state.isBreak() do
      if state.isBlank() then
        /* Check for tab character that abuse intendation. */
        if _scalarBlanks.leadingBlank and (state.mark.column < _indent) and state.isTab() then
          return ScanError("while scanning a plain scalar", _startMark, "found a tab character that violate intendation")
        end
        /* Consume a space or a tab character. */
        if not _scalarBlanks.leadingBlank then
          match state.read((_scalarBlanks.whitespaces = None) as String trn^)
          | let e: ScanError => return e
          | let s: String trn => _scalarBlanks.whitespaces = consume s
          else
            error
          end
        else
          state.skip()
        end
      else
        if not state.available(2) then
          return ScanPaused(this~_scanBlank())
        end
        /* Check if it is a first line break. */
        if not _scalarBlanks.leadingBlank then
          (_scalarBlanks.whitespaces as String trn).clear()
          match state.readLine((_scalarBlanks.leadingBreak = None) as String trn^)
          | let e: ScanError => return e
          | let s: String trn => _scalarBlanks.leadingBreak = consume s
          else
            error
          end
          _scalarBlanks.leadingBlank = true
        else
          match state.readLine((_scalarBlanks.trailingBreaks = None) as String trn^)
          | let e: ScanError => return e
          | let s: String trn => _scalarBlanks.trailingBreaks = consume s
          else
            error
          end
        end
      end
      if not state.available() then
        return ScanPaused(this~_scanBlank())
      end
    end
    /* Check intendation level. */
    if (state.flowLevel == 0) and (state.mark.column < _indent) then
      return this._scanEnd(state)
    end
    this._scanContent(state)

  fun ref _scanEnd(state: _ScannerState): _ScanResult ? =>
    state.emitToken(_YamlScalarToken(_startMark, _endMark, _YamlScalarTokenData((_string = None) as String trn^, YAML_PLAIN_SCALAR_STYLE)))
    /* Note that we change the 'simple_key_allowed' flag. */
    if _scalarBlanks.leadingBlank then
      state.simpleKeyAllowed = true
    end
    _nextScanner.apply(state)
