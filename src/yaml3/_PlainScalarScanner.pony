
/*
 * Scan a plain scalar.
 */
class _PlainScalarScanner is _Scanner
  let _nextScanner: _Scanner
  let _startMark: YamlMark val
  var _endMark: YamlMark val
  var _string: (None | String iso) = None
  var _scalarBlanks: _ScalarBlanks iso = recover _ScalarBlanks.create() end
  var _indent: USize = 0

  new create(startMark: YamlMark val, nextScanner: _Scanner) =>
    _nextScanner = nextScanner
    _startMark = startMark
    _endMark = _startMark

  fun ref apply(state: _ScannerState): _ScanResult ? =>
    _indent = state.indent
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
        state.isBlankEOF(3)) then
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
    while not state.isBlankEOF() do
      /* Check for 'x:x' in the flow context. TODO: Fix the test "spec-08-13". */
      if (state.flowLevel > 0) and state.check(':') and not state.isBlankEOF(1) then
        return ScanError("while scanning a plain scalar", _startMark, "found unexpected ':'")
      end

      /* Check for indicators that may end a plain scalar. */
      if ((state.check(':') and state.isBlankEOF(1))
              or ((state.flowLevel > 0) and
                  (state.check(',') or state.check(':')
                   or state.check('?') or state.check('[')
                   or state.check(']') or state.check('{')
                   or state.check('}')))) then
        break
      end

      /* Check if we need to join whitespaces and breaks. */
      if _scalarBlanks.leadingBlank or ((_scalarBlanks.whitespaces as String iso).size() > 0) then
        if _scalarBlanks.leadingBlank then
          /* Do we need to fold line breaks? */
          if ((_scalarBlanks.leadingBreak as String iso).size() > 0) and ((_scalarBlanks.leadingBreak as String iso)(0) == '\n') then
            if (_scalarBlanks.trailingBreaks as String iso).size() == 0 then
              (_string as String iso).push(' ')
            else
              (_string as String iso).append((_scalarBlanks.trailingBreaks as String iso).clone())
              (_scalarBlanks.trailingBreaks as String iso).clear()
            end
            (_scalarBlanks.leadingBreak as String iso).clear()
          else
            (_string as String iso).append((_scalarBlanks.leadingBreak as String iso).clone())
            (_string as String iso).append((_scalarBlanks.trailingBreaks as String iso).clone())
            (_scalarBlanks.leadingBreak as String iso).clear()
            (_scalarBlanks.trailingBreaks as String iso).clear()
          end
          _scalarBlanks.leadingBlank = false
        else
          (_string as String iso).append((_scalarBlanks.whitespaces as String iso).clone())
          (_scalarBlanks.whitespaces as String iso).clear()
        end
      end
      /* Copy the character. */
      _string = state.read((_string = None) as String iso^)
      _endMark = state.mark.clone()
      if not state.available(2) then
        return ScanPaused(this~_scanNonBlank())
      end
    end
    /* Is it the end? */
    if not (state.isBlank() or state.isBreak()) then
      return this._scanEnd(state)
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
          _scalarBlanks.whitespaces = state.read((_scalarBlanks.whitespaces = None) as String iso^)
        else
          state.skip()
        end
      else
        if not state.available(2) then
          return ScanPaused(this~_scanBlank())
        end
        /* Check if it is a first line break. */
        if not _scalarBlanks.leadingBlank then
          (_scalarBlanks.whitespaces as String iso).clear()
          match state.readLine((_scalarBlanks.leadingBreak = None) as String iso^)
          | let e: ScanError => return e
          | let s: String iso => _scalarBlanks.leadingBreak = consume s
          else
            error
          end
          _scalarBlanks.leadingBlank = true
        else
          match state.readLine((_scalarBlanks.trailingBreaks = None) as String iso^)
          | let e: ScanError => return e
          | let s: String iso => _scalarBlanks.trailingBreaks = consume s
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
    match state.emitToken(_YamlScalarToken(_startMark, _endMark, (_string = None) as String iso^, _YamlPlainScalarStyle))
    | let e: ScanError => return e
    end
    /* Note that we change the 'simple_key_allowed' flag. */
    if _scalarBlanks.leadingBlank then
      state.simpleKeyAllowed = true
    end
    _nextScanner.apply(state)
