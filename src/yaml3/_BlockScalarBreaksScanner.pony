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
