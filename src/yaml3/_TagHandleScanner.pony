
/*
 * Scan a tag handle.
 */
class _TagHandleScanner is _Scanner
  let _directive: Bool
  let _startMark: YamlMark val
  let _nextScanner: _Scanner
  var handle: (None | String trn) = recover String.create() end

  new create(directive: Bool, mark: YamlMark val, nextScanner: _Scanner) =>
    _directive = directive
    _startMark = mark
    _nextScanner = nextScanner

  fun ref apply(state: _ScannerState): _ScanResult ? =>
    /* Check the initial '!' character. */
    if not state.available() then
      return ScanPaused(this)
    end
    if not state.check('!') then
      return ScanError(if _directive then "while scanning a tag directive" else "while scanning a tag" end,
                _startMark, "did not find expected '!'")
    end
    /* Copy the '!' character. */
    (handle as String trn).push('!')
    state.skip()
    this._scanAlpha(state)

  fun ref _scanAlpha(state: _ScannerState): _ScanResult ? =>
    /* Copy all subsequent alphabetical and numerical characters. */
    if not state.available() then
      return ScanPaused(this~_scanAlpha())
    end
    while state.isAlpha() do
      match state.read((handle = None) as String trn^)
      | let h: String trn => handle = consume h
      | let e: ScanError => return e
      else
        error
      end
      if not state.available() then
        return ScanPaused(this~_scanAlpha())
      end
    end

    /* Check if the trailing character is '!' and copy it. */
    if state.check('!') then
      (handle as String trn).push('!')
      state.skip()
    else
      /*
       * It's either the '!' tag or not really a tag handle.  If it's a %TAG
       * directive, it's an error.  If it's a tag token, it must be a part of
       * URI.
       */

      if (_directive and not (((handle as String trn)(0) == '!') and ((handle as String trn).size() == 1))) then
        return ScanError("while parsing a tag directive", _startMark, "did not find expected '!'")
      end
    end
    _nextScanner.apply(state)
