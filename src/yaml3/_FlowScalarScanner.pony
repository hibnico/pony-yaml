
/*
 * Scan a quoted scalar.
 */
class _FlowScalarScanner is _Scanner
  let _single: Bool
  let _nextScanner: _Scanner
  let _startMark: YamlMark val
  var _string: (None | String iso) = recover String.create() end
  var _scalarBlanks: (None | _ScalarBlanks iso) = recover _ScalarBlanks.create() end
  var _firstLineBreakScanner: (None | _FirstLineBreakScanner) = None

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
        state.isBlankEOF(3)) then
      return ScanError("while scanning a quoted scalar", _startMark, "found unexpected document indicator")
    end

    /* Check for EOF. */
    if state.isEOF() then
      return ScanError("while scanning a quoted scalar", _startMark, "found unexpected end of stream")
    end
    (_scalarBlanks as _ScalarBlanks iso).leadingBlank = false
    this._scanNonBlank(state)

  fun ref _scanNonBlank(state: _ScannerState): _ScanResult ? =>
    /* Consume non-blank characters. */
    if not state.available(2) then
      return ScanPaused(this~_scanNonBlank())
    end
    while not state.isBlankEOF() do
      /* Check for an escaped single quote. */
      if (_single and state.check('\'') and state.check('\'', 1)) then
        (_string as String iso).push('\'')
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
        match _checkEscapeChar(state.at(1), (_string = None) as String iso^)
        | let e: ScanError => return e
        | (let l: USize, let s: String iso) => codeLength = l; _string = consume s
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
        match state.read((_string = None) as String iso^)
        | let e: ScanError => return e
        | let s: String iso => _string = consume s
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
    (_scalarBlanks as _ScalarBlanks iso).leadingBlank = true
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

    _string = _pushEscapedValue((_string = None) as String iso^, value)

    /* Advance the pointer. */
    state.skip(codeLength)
    this._scanNonBlank(state)

  fun _checkEscapeChar(char: U8, s: String iso): (ScanError | (USize, String iso^)) =>
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

  fun _pushEscapedValue(s: String iso, value: U32): String iso^ =>
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
        if not (_scalarBlanks as _ScalarBlanks iso).leadingBlank then
          match state.read(((_scalarBlanks as _ScalarBlanks iso).whitespaces = None) as String iso^)
          | let e: ScanError => return e
          | let s: String iso => (_scalarBlanks as _ScalarBlanks iso).whitespaces = consume s
          else
            error
          end
        else
          state.skip()
        end
      else
        let s: _FirstLineBreakScanner = _FirstLineBreakScanner.create((_scalarBlanks = None) as _ScalarBlanks iso^, this~_endFirstLineBreak())
        _firstLineBreakScanner = s
        return s.apply(state)
      end
      if not state.available() then
        return ScanPaused(this~_scanBlank())
      end
    end
    /* Join the whitespaces or fold line breaks. */
    if (_scalarBlanks as _ScalarBlanks iso).leadingBlank then
      /* Do we need to fold line breaks? */
      if (((_scalarBlanks as _ScalarBlanks iso).leadingBreak as String iso).size() > 0)
         and (((_scalarBlanks as _ScalarBlanks iso).leadingBreak as String iso)(0) == '\n') then
        if ((_scalarBlanks as _ScalarBlanks iso).trailingBreaks as String iso).size() == 0 then
          (_string as String iso).push(' ')
        else
          (_string as String iso).append(((_scalarBlanks as _ScalarBlanks iso).trailingBreaks as String iso).clone())
          ((_scalarBlanks as _ScalarBlanks iso).trailingBreaks as String iso).clear()
        end
        ((_scalarBlanks as _ScalarBlanks iso).leadingBreak as String iso).clear()
      else
        (_string as String iso).append(((_scalarBlanks as _ScalarBlanks iso).leadingBreak as String iso).clone())
        (_string as String iso).append(((_scalarBlanks as _ScalarBlanks iso).trailingBreaks as String iso).clone())
        ((_scalarBlanks as _ScalarBlanks iso).leadingBreak as String iso).clear()
        ((_scalarBlanks as _ScalarBlanks iso).trailingBreaks as String iso).clear()
      end
    else
      (_string as String iso).append(((_scalarBlanks as _ScalarBlanks iso).whitespaces as String iso).clone())
      ((_scalarBlanks as _ScalarBlanks iso).whitespaces as String iso).clear()
    end
    this._scanContent(state)

  fun ref _endFirstLineBreak(state: _ScannerState): _ScanResult ? =>
    let s: _FirstLineBreakScanner = _firstLineBreakScanner as _FirstLineBreakScanner
    _scalarBlanks = (s.scalarBlanks = None)
    this._scanBlank(state)

  fun ref _scanContentEnd(state: _ScannerState): _ScanResult ? =>
    /* Eat the right quote. */
    state.skip()
    let endMark = state.mark.clone()
    /* Create a token. */
    match state.emitToken(_YamlScalarToken(_startMark, endMark, (_string = None) as String iso^,
        if _single then _YamlSingleQuotedScalarStyle else _YamlDoubleQuotedScalarStyle end))
    | let e: ScanError => return e
    end
    _nextScanner.apply(state)
