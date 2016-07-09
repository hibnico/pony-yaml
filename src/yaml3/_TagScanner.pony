
class _TagScanner is _Scanner
  let _startMark: YamlMark val
  let _nextScanner: _Scanner
  var _tagURIScanner: (None | _TagURIScanner) = None
  var _tagHandleScanner: (None | _TagHandleScanner) = None
  var _handle: String = ""
  var _suffix: String = ""

  new create(startMark: YamlMark val, nextScanner: _Scanner) =>
    _startMark = startMark
    _nextScanner = nextScanner

  fun ref apply(state: _ScannerState): _ScanResult ? =>
    if not state.available(2) then
      return ScanPaused(this)
    end
    if state.check('<', 1) then
      // keep _handle as ""
      state.skip(2)
      let s = _TagURIScanner.create(false, None, _startMark, this~_scanEndUri())
      _tagURIScanner = s
      s.apply(state)
    else
      /* The tag has either the '!suffix' or the '!handle!suffix' form. */
      /* First, try to scan a handle. */
      let s = _TagHandleScanner.create(false, _startMark, this~_scanEndHandle())
      _tagHandleScanner = s
      s.apply(state)
    end

  fun ref _scanEndUri(state: _ScannerState): _ScanResult ? =>
    if not state.check('>') then
      return ScanError("while scanning a tag", _startMark, "did not find the expected '>'")
    end
    let tagURIScanner = _tagURIScanner as _TagURIScanner
    _suffix = (tagURIScanner.uri = None) as String iso^
    state.skip()
    this._scanEnd(state)

  fun ref _scanEndHandle(state: _ScannerState): _ScanResult ? =>
    let tagHandleScanner = _tagHandleScanner as _TagHandleScanner
    let h: String iso = (tagHandleScanner.handle = None) as String iso^
    /* Check if it is, indeed, handle. */
    if (h(0) == '!') and (h.size() > 1) and (h(h.size() - 1) == '!') then
      _handle = consume h
      /* Scan the suffix now. */
      let s = _TagURIScanner.create(false, None, _startMark, this~_scanEndUriWithHandle())
      _tagURIScanner = s
      s.apply(state)
    else
      /* It wasn't a handle after all.  Scan the rest of the tag. */
      let s = _TagURIScanner.create(false, consume h, _startMark, this~_scanEndUriWithBadHandle())
      _tagURIScanner = s
      s.apply(state)
    end

  fun ref _scanEndUriWithHandle(state: _ScannerState): _ScanResult ? =>
    let tagURIScanner = _tagURIScanner as _TagURIScanner
    _suffix = (tagURIScanner.uri = None) as String iso^
    this._scanEnd(state)

  fun ref _scanEndUriWithBadHandle(state: _ScannerState): _ScanResult ? =>
    /* Set the handle to '!'. */
    _handle = "!"
    let tagURIScanner = _tagURIScanner as _TagURIScanner
    _suffix = (tagURIScanner.uri = None) as String iso^
    /*
     * A special case: the '!' tag.  Set the handle to '' and the
     * suffix to '!'.
     */
    if _suffix.size() == 0 then
      _suffix = _handle = _suffix
    end
    this._scanEnd(state)

  fun ref _scanEnd(state: _ScannerState): _ScanResult ? =>
    if not state.available() then
      return ScanPaused(this~_scanEnd())
    end
    if not state.isBlankZ() then
      return ScanError("while scanning a tag", _startMark, "did not find expected whitespace or line break")
    end
    let endMark = state.mark.clone()
    match state.emitToken(_YamlTagToken(_startMark, endMark, _handle, _suffix))
    | let e: ScanError => return e
    end
    _nextScanner.apply(state)
