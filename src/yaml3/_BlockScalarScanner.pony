
class _BlockScalarScanner is _Scanner
  let _literal: Bool
  let _startMark: YamlMark val
  let _endMark: Option[YamlMark val] = Option[YamlMark val].none()
  let _nextScanner: _Scanner
  var _string: (None | String iso) = recover String.create() end
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
    let s = _BlockScalarBreaksScanner.create(_indent, (_scalarBlanks.trailingBreaks = None) as String iso^, _startMark,
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
    if (state.mark.column == _indent) and not state.isEOF() then
      /*
       * We are at the beginning of a non-empty line.
       */
      /* Is it a trailing whitespace? */
      _scalarBlanks.trailingBlank = state.isBlank()
      /* Check if we need to fold the leading line break. */
      if not _literal and ((_scalarBlanks.leadingBreak as String iso).size() > 0)
          and not _scalarBlanks.leadingBlank and not _scalarBlanks.trailingBlank then
        /* Do we need to join the lines by space? */
        if (_scalarBlanks.trailingBreaks as String iso).size() == 0 then
          (_string as String iso).push(' ')
        end
        (_scalarBlanks.leadingBreak as String iso).clear()
      else
        (_string as String iso).append((_scalarBlanks.leadingBreak as String iso).clone())
        (_scalarBlanks.leadingBreak as String iso).clear()
      end
      /* Append the remaining line breaks. */
      (_string as String iso).append((_scalarBlanks.trailingBreaks as String iso).clone())
      (_scalarBlanks.trailingBreaks as String iso).clear()
      /* Is it a leading whitespace? */
      _scalarBlanks.leadingBlank = state.isBlank()
      return this._scanCurrentLine(state)
    end
    /* Chomp the tail. */
    if not _chompLeading then
      (_string as String iso).append((_scalarBlanks.leadingBreak as String iso).clone())
    end
    if not _chompTrailing then
      (_string as String iso).append((_scalarBlanks.trailingBreaks as String iso).clone())
    end
    /* Create a token. */
    match state.emitToken(_YamlScalarToken(_startMark, _endMark.value(), (_string = None) as String iso^,
      if _literal then _YamlLiteralScalarStyle else _YamlFoldedScalarStyle end))
    | let e: ScanError => return e
    end
    _nextScanner.apply(state)


  /* Consume the current line. */
  fun ref _scanCurrentLine(state: _ScannerState): _ScanResult ? =>
    while not state.isBreakEOF() do
      match state.read((_string = None) as String iso^)
      | let e: ScanError => return e
      | let s: String iso => _string = consume s
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
    match state.readLine((_scalarBlanks.leadingBreak = None) as String iso^)
    | let e: ScanError => return e
    | let s: String iso => _scalarBlanks.leadingBreak = consume s
    else
      error
    end
    /* Eat the following intendation spaces and line breaks. */
    let s = _BlockScalarBreaksScanner.create(_indent, (_scalarBlanks.trailingBreaks = None) as String iso^, _startMark,
              _endMark.value(), this~_endBlockScalarBreaks())
    _blockScalarBreaksScanner = s
    s.apply(state)
