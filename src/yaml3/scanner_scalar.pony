
class _BlockScalarScanner
  let _literal: Bool
  var _startMark: YamlMark val
  var _endMark: YamlMark val
  let _nextScanner: _Scanner
  var _string: String
  var _leadingBreak: String
  var _trailingBreaks: String
  var _chompLeading: Bool = false
  var _chompTrailing: Bool = true
  var _increment: I32 = 0
  var _indent: USize = 0
  var _leadingBlank: Bool = false
  var _trailingBlank : Bool = false
  var _blockScalarBreaksScanner: (None | _BlockScalarBreaksScanner) = None

  new create(literal: Bool, nextScanner: _Scanner) =>
    _literal = literal
    _nextScanner = nextScanner

  fun ref scan(state: _ScannerState): _ScanResult ? =>
    /* Eat the indicator '|' or '>'. */
    _startMark = state.mark.clone()
    state.skip()
    let skipWhitespace = _LineTrailScanner.create(_startMark, "while scanning a block scalar", this~_scanBlockScalarBreaks())
    // Note: The following lines of code are about chaining scanners
    // TODO: may not be the best way to handle it, since it creates scanners which will never be used
    // First, try to scan a method
    this~_scanChompingMethod(
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
          skipWhitespace
        ),
        // nothing found: go skip the whitespaces
        skipWhitespace
      )
    )

  fun ref _scanChompingMethod(nextScannerIfPresent: _Scanner, nextScannerIfAbsent: _Scanner, state: _ScannerState): _ScanResult ? =>
    if not cache.available() then
      return ScanPaused
    end
    /* Set the chomping method and eat the indicator. */
    if state.check('+') then
      /* Set the chomping method and eat the indicator. */
      _chompTrailing = false
      state.skip()
      nextScannerIfPresent
    elseif state.check('-') then
      /* Set the chomping method and eat the indicator. */
      _chompLeading = true
      _chompTrailing = false
      state.skip()
      nextScannerIfPresent
    else
      nextScannerIfAbsent
    end

  /* Check for an indentation indicator. */
  fun ref _scanIndentIndicator(nextScannerIfPresent: _Scanner, nextScannerIfAbsent: _Scanner, state: _ScannerState): _ScanResult ? =>
    if not cache.available() then
      return ScanPaused
    end
    if state.isDigit() then
      if state.check('0') then
        return ScanError("while scanning a block scalar", _startMark, "found an intendation indicator equal to 0")
      end
      _increment = state.asDigit()
      state.skip()
      nextScannerIfPresent
    else
      nextScannerIfAbsent
    end

  fun ref _scanBlockScalarBreaks(state: _ScannerState): _ScanResult ? =>
    _endMark = state.mark.clone()
    /* Set the intendation level if it was specified. */
    if _increment != 0 then
      _indent = if state.indent >= 0 then state.indent + _increment else _increment end
    end
    /* Scan the leading line breaks and determine the indentation level if needed. */
    let s = _BlockScalarBreaksScanner.create(_indent, _trailingBreaks, _startMark, _endMark, this~_endBlockScalarBreaks())
    _blockScalarBreaksScanner = s
    s

  fun ref _endBlockScalarBreaks(state: _ScannerState): _ScanResult ? =>
    let blockScalarBreaksScanner = _blockScalarBreaksScanner as _BlockScalarBreaksScanner
    _indent = _blockScalarBreaksScanner.indent
    this~_scanContent()

  /* Scan the block scalar content. */
  fun ref _scanContent(state: _ScannerState): _ScanResult ? =>
    if not state.available() then
      return ScanPaused
    end
    if (state.mark.column == _indent) and not state.isZ() then
      /*
       * We are at the beginning of a non-empty line.
       */
      /* Is it a trailing whitespace? */
      _trailingBlank = state.isBlank()
      /* Check if we need to fold the leading line break. */
      if not _literal and (_leadingBreak.size() > 0) and not _leadingBlank and not _trailingBlank then
        /* Do we need to join the lines by space? */
        if _trailingBlank.size() == 0 then
          _string.push(' ')
        end
        _leadingBreak.clear()
      else
        _string.append(_leadingBreak)
        _leadingBreak.clear()
      end
      /* Append the remaining line breaks. */
      _string.append(_trailingBreaks)
      _trailingBreaks.clear()
      /* Is it a leading whitespace? */
      _leadingBlank = state.isBlank()
      return this~_scanCurrentLine()
    end
    /* Chomp the tail. */
    if not _chompLeading then
      _string.append(_leadingBreak)
    end
    if not _chompTrailing then
      _string.append(_trailingBreaks)
    end
    /* Create a token. */
    state.emitToken(_YamlScalarToken(_startMark, _endMark,
      _YamlScalarTokenData(_string, if _literal then YAML_LITERAL_SCALAR_STYLE else YAML_FOLDED_SCALAR_STYLE end)))
    _nextScanner


  /* Consume the current line. */
  fun ref _scanCurrentLine(state: _ScannerState): _ScanResult ? =>
    while not state.isBreakZ() do
      state.read(_string)
      if not state.available() then
        return ScanPaused
      end
    end
    this~_readLine()


  fun ref _readLine(state: _ScannerState): _ScanResult ? =>
    /* Consume the line break. */
    if not state.available(2) then
      return ScanPaused
    end
    state.readLine(_leadingBreak)
    /* Eat the following intendation spaces and line breaks. */
    let s = _BlockScalarBreaksScanner.create(_indent, _trailingBreaks, _startMark, _endMark, this~_endBlockScalarBreaks())
    _blockScalarBreaksScanner = s
    s


/*
 * Scan intendation spaces and line breaks for a block scalar.  Determine the
 * intendation level if needed.
 */
class _BlockScalarBreaksScanner
  let _startMark: YamlMark val
  let endMark: YamlMark val
  let _nextScanner: _Scanner
  let _breaks: String
  var indent : USize
  var _maxIndent: USize = 0

  new create(indent': USize, breaks: String, startMark: YamlMark val, endMark': YamlMark val, nextScanner: _Scanner) =>
    indent = indent'
    _startMark = startMark
    _endMark = endMark
    _breaks = breaks
    _nextScanner = nextScanner
    endMark = endMark'

  fun scan(state: _ScannerState): _ScanResult ? =>
    /* Eat the intendation spaces and line breaks. */
    if not buffer.cache() then
      return ScanPaused
    end
    while ((indent == 0) or (state.mark.column < indent)) and state.isSpace() do
      state.skip()
      if not buffer.cache() then
        return ScanPaused
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
      this~_scanEnd()
    else
      /* Consume the line break. */
      this~_scanLineBreak()
    end

  fun ref _scanLineBreak(state: _ScannerState): _ScanResult ? =>
    if not state.available(2) then
      return ScanPaused
    end
    state.read(breaks)
    this~scan()

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
    _nextScanner


class _ScalarBlanks
  var leadingBreak: String
  var trailingBreaks: String
  var whitespaces: String
  var leadingBlanks: Bool = false



/*
 * Scan a quoted scalar.
 */
class _FlowScalarScanner
  let _single: Bool
  let _nextScanner: _Scanner
  var _startMark: YamlMark val
  var _string: String
  var _scalarBlanks: _ScalarBlanks = _ScalarBlanks.create()

  new create(single: Bool, nextScanner: _Scanner) =>
    _single = single
    _nextScanner = nextScanner

  fun ref scan(state: _ScannerState): _ScanResult ? =>
    /* Eat the left quote. */
    _startMark = state.mark.clone()
    state.skip()
    this~_scanContent()

  /* Consume the content of the quoted scalar. */
  fun ref _scanContent(state: _ScannerState): _ScanResult ? =>
    /* Check that there are no document indicators at the beginning of the line. */
    if not state.available(4) then
      return ScanPaused
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
      return ScanError("while scanning a quoted scalar", start_mark, "found unexpected end of stream")
    end
    _scalarBlanks.leadingBlanks = 0
    this~_scanNonBlank()

  fun ref _scanNonBlank(state: _ScannerState): _ScanResult ? =>
    /* Consume non-blank characters. */
    if not state.available(2) then
      return ScanPaused
    end
    while not state.isBlankZ() do
      /* Check for an escaped single quote. */
      if (single and state.check('\'') and state.check('\'', 1)) then
        _string.push('\'')
        state.skip(2)
      /* Check for the right quote. */
      elseif (buffer.check(if single then '\'' else '"' end)) then
        return this~_checkEndScalar()
      /* Check for an escaped line break. */
      elseif (not single and state.check('\\') and state.isBreak(1)) then
        if not state.available(3) then
          return ScanPaused
        end
        state.skip()
        state.skipLine()
        _scalarBlanks.leadingBlanks = true
        return this~_checkEndScalar()
      /* Check for an escape sequence. */
      elseif (not single and buffer.check('\\')) then
        var codeLength : USize = 0
        /* Check the escape character. */
        match state.at(1)
        | '0' => string.push('\0')
        | 'a' => string.push('\x07')
        | 'b' => string.push('\x08')
        | 't' => string.push('\x09')
        | '\t' => string.push('\x09')
        | 'n' => string.push('\x0A')
        | 'v' => string.push('\x0B')
        | 'f' => string.push('\x0C')
        | 'r' => string.push('\x0D')
        | 'e' => string.push('\x1B')
        | ' ' => string.push('\x20')
        | '"' => string.push('"')
        | '\'' => string.push('\'')
        | '\\' => string.push('\\')
        | 'N' => string.push('\xC2'); string.push('\x85')   /* NEL (#x85) */
        | '_' => string.push('\xC2'); string.push('\xA0')   /* #xA0 */
        | 'L' => string.push('\xE2'); string.push('\x80'); string.push('\xA8')   /* LS (#x2028) */
        | 'P' => string.push('\xE2'); string.push('\x80'); string.push('\xA9')   /* PS (#x2029) */
        | 'x' => codeLength = 2
        | 'u' => codeLength = 4
        | 'U' => codeLength = 8
        else
          return ScanError("while parsing a quoted scalar", _startMark, "found unknown escape character")
        end
        state.skip(2)
        /* Consume an arbitrary escape code. */
        if codeLength > 0 then
          this~_scanEscapeCode()
        end
      else
        /* It is a non-escaped non-blank character. */
        state.read(string)
      end
      if not state.available(2) then
        return ScanPaused
      end
    end
    /* Check if we are at the end of the scalar. */
    if state.check(if single then '\'' else '"' end) then
      this~_scanContentEnd()
    else
      this~_scanBlank()
    end

  fun ref _scanEscapeCode(state: _ScannerState): _ScanResult ? =>
    /* Scan the character value. */
    if state.available(codeLength) then
      return ScanPaused
    end
    var value: U32 = 0
    for k in Range(0, codeLength) do
      if not state.isHexAt(k) then
        return ScanError("while parsing a quoted scalar", _startMark, "did not find expected hexdecimal number")
      end
      value = (value << 4) + state.asHex(k)
    end

    /* Check the value and write the character. */
    if (((value >= 0xD800) and (value <= 0xDFFF)) or (value > 0x10FFFF)) then
      return ScanError("while parsing a quoted scalar", _startMark, "found invalid Unicode character escape code")
    end

    if (value <= 0x7F) then
      string.push(value)
    elseif (value <= 0x7FF) then
      string.push(0xC0 + (value >> 6))
      string.push(0x80 + (value and 0x3F))
    elseif (value <= 0xFFFF) then
      string.push(0xE0 + (value >> 12))
      string.push(0x80 + ((value >> 6) and 0x3F))
      string.push(0x80 + (value and 0x3F))
    else
      string.push(0xF0 + (value >> 18))
      string.push(0x80 + ((value >> 12) and 0x3F))
      string.push(0x80 + ((value >> 6) and 0x3F))
      string.push(0x80 + (value and 0x3F))
    end

    /* Advance the pointer. */
    for k in Range(0, codeLength) do
      state.skip()
    end
    this~_scanNonBlank()

  fun ref _scanBlank(state: _ScannerState): _ScanResult ? =>
    /* Consume blank characters. */
    if not state.available(1) then
      return ScanPaused
    end

    while (state.isBlank() or state.isBreak()) do
      if state.isBlank() then
        /* Consume a space or a tab character. */
        if not _scalarBlanks.leadingBlanks then
          state.read(_scalarBlanks.whitespaces)
        else
          state.skip()
        end
      else
        return _FirstLineBreakScanner~scan(_scalarBlanks, this~_scanBlank())
      end
      if not buffer.available() then
        return ScanPaused
      end
    end
    /* Join the whitespaces or fold line breaks. */
    if _scalarBlanks.leadingBlanks then
      /* Do we need to fold line breaks? */
      if _scalarBlanks.leadingBreak(0) == '\n' then
        if _scalarBlanks.trailingBreaks.size() == 0 then
          string.push(' ')
        else
          string.append(_scalarBlanks.trailingBreaks)
          _scalarBlanks.trailingBreaks.clear()
        end
        _scalarBlanks.leadingBreak.clear()
      else
        string.append(_scalarBlanks.leadingBreak)
        string.append(_scalarBlanks.trailingBreaks)
        _scalarBlanks.leadingBreak.clear()
        _scalarBlanks.trailingBreaks.clear()
      end
    else
      string.append(_scalarBlanks.whitespaces)
      _scalarBlanks.whitespaces.clear()
    end


  fun ref _scanContentEnd(state: _ScannerState): _ScanResult ? =>
    /* Eat the right quote. */
    state.skip()
    let endMark = state.mark.clone()
    /* Create a token. */
    state.emitToken(_YamlScalarToken(_startMark, endMark,
      _YamlScalarTokenData(string, if single then YAML_SINGLE_QUOTED_SCALAR_STYLE else YAML_DOUBLE_QUOTED_SCALAR_STYLE end)))
    _nextScanner


class _FirstLineBreakScanner
  fun ref scan(scalarBlanks: _ScalarBlanks, nextScanner: _Scanner, state: _ScannerState): _ScanResult ? =>
    if not state.available(2) then
      return ScanPaused
    end
    /* Check if it is a first line break. */
    if not scalarBlanks.leadingBlanks then
      scalarBlanks.whitespaces.clear()
      state.readLine(scalarBlanks.leadingBreak)
      scalarBlanks.leadingBlanks = true
    else
      state.readLine(scalarBlanks.trailingBreaks)
    end
    nextScanner

/*
 * Scan a plain scalar.
 */
class _PlainScalarScanner
  let _nextScanner: _Scanner
  var _startMark: YamlMark val
  var _endMark: YamlMark val
  var _string: String
  var _scalarBlanks: _ScalarBlanks

  new create(nextScanner: _Scanner) =>
    _nextScanner = nextScanner

  fun ref scan(state: _ScannerState): _ScanResult ? =>
    _startMark = state.mark.clone()
    _endMark = _startMark
    this~_scanContent()

  /* Consume the content of the plain scalar. */
  fun ref _scanContent(state: _ScannerState): _ScanResult ? =>
    /* Check for a document indicator. */
    if not state.available(4) then
      return ScanPaused
    end
    if ((state.mark.column == 0) and
        ((state.check('-', 0) and
          state.check('-', 1) and
          state.check('-', 2)) or
         (state.check('.', 0) and
          state.check('.', 1) and
          state.check('.', 2))) and
        state.isBlankZ(3)) then
      return this~_scanEnd()
    end
    /* Check for a comment. */
    if buffer.check('#') then
      return this~_scanEnd()
    end
    this~_scanNonBlank()


  fun ref _scanNonBlank(state: _ScannerState): _ScanResult ? =>
    if not state.available(2) then
      return ScanPaused
    end
    /* Consume non-blank characters. */
    while not state.isBlankZ() do
      /* Check for 'x:x' in the flow context. TODO: Fix the test "spec-08-13". */
      if (state.flowLevel > 0) and state.check(':') and not state.isBlankZAt(1) then
        return ScanError("while scanning a plain scalar", _startMark, "found unexpected ':'")
      end

      /* Check for indicators that may end a plain scalar. */
      if ((state.check(':') and state.isBlankZAt(1))
              or ((state.flowLevel > 0) and
                  (state.check(',') or state.check(':')
                   or state.check('?') or state.check('[')
                   or state.check(']') or state.check('{')
                   or state.check('}')))) then
        return this._scanNonBlankEnd()
      end

      /* Check if we need to join whitespaces and breaks. */
      if _scalarBlanks.leadingBlanks or (_scalarBlanks.whitespaces.size() > 0) then
        if _scalarBlanks.leadingBlanks then
          /* Do we need to fold line breaks? */
          if _scalarBlanks.leadingBreak(0) == '\n' then
            if _scalarBlanks.trailingBreaks.size() == 0 then
              string.push(' ')
            else
              string.append(_scalarBlanks.trailingBreaks)
              _trailingBreaks.clear()
            end
            _leadingBreak.clear()
          else
            string.append(_scalarBlanks.leadingBreak)
            string.append(_scalarBlanks.trailingBreaks)
            _scalarBlanks.leadingBreak.clear()
            _scalarBlanks.trailingBreaks.clear()
          end
          _scalarBlanks.leadingBlanks = false
        else
          string.append(_scalarBlanks.whitespaces)
          _scalarBlanks.whitespaces.clear()
        end
      end
      /* Copy the character. */
      state.read(string)
      _endMark = state.mark.clone()
      if not state.available(2) then
        return ScanPaused
      end
    end
    /* Is it the end? */
    if not (state.isBlank() or state.isBreak()) then
      return this~endloop()
    end
    this~_scanBlank()


  fun ref _scanBlank(state: _ScannerState): _ScanResult ? =>
    /* Consume blank characters. */
    if not state.available() then
      return ScanPaused
    end
    while state.isBlank() or state.isBreak() do
      if state.isBlank() then
        /* Check for tab character that abuse intendation. */
        if _scalarBlanks.leadingBlanks and (state.mark.column < _indent) and state.isTab() then
          return ScanError("while scanning a plain scalar", _startMark, "found a tab character that violate intendation")
        end
        /* Consume a space or a tab character. */
        if not _scalarBlanks.leadingBlanks then
          state.read(_whitespaces)
        else
          state.skip()
        end
      else
        if not buffer.cache(2) then
          return ScanPaused
        end
        /* Check if it is a first line break. */
        if not _scalarBlanks.leadingBlanks then
          _scalarBlanks.whitespaces.clear()
          state.readLine(leadingBreak)
          _scalarBlanks.leadingBlanks = true
        else
          state.readLine(_scalarBlanks.trailingBreaks)
        end
      end
      if not state.available() then
        return ScanPaused
      end
    end
    /* Check intendation level. */
    if (state.flowLevel == 0) and (state.mark.column < _indent) then
      return this~_scanEnd()
    end
    this~_scanContent()

  fun ref _scanEnd(state: _ScannerState): _ScanResult ? =>
    state.emitToken(_YamlScalarTokenData(_startMark, _endMark, _YamlScalarTokenData(string, YAML_PLAIN_SCALAR_STYLE)))
    /* Note that we change the 'simple_key_allowed' flag. */
    if _scalarBlanks.leadingBlanks then
      state.simpleKeyAllowed = true
    end
    _nextScanner
