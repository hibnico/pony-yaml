
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
    _suffix = (tagURIScanner.uri = None) as String trn^
    state.skip()
    this._scanEnd(state)

  fun ref _scanEndHandle(state: _ScannerState): _ScanResult ? =>
    let tagHandleScanner = _tagHandleScanner as _TagHandleScanner
    let h: String trn = (tagHandleScanner.handle = None) as String trn^
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
    _suffix = (tagURIScanner.uri = None) as String trn^
    this._scanEnd(state)

  fun ref _scanEndUriWithBadHandle(state: _ScannerState): _ScanResult ? =>
    /* Set the handle to '!'. */
    _handle = "!"
    let tagURIScanner = _tagURIScanner as _TagURIScanner
    _suffix = (tagURIScanner.uri = None) as String trn^
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
    state.emitToken(_YamlTagToken(_startMark, endMark, _handle, _suffix))
    _nextScanner.apply(state)


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


/*
 * The set of characters that may appear in URI is as follows:
 *
 *      '0'-'9', 'A'-'Z', 'a'-'z', '_', '-', ';', '/', '?', ':', '@', '&',
 *      '=', '+', '$', ',', '.', '!', '~', '*', '\'', '(', ')', '[', ']',
 *      '%'.
 */
class _TagURIScanner is _Scanner
  let _directive: Bool
  let _startMark: YamlMark val
  let _nextScanner: _Scanner
  var _uriEscapesScanner: (None | _URIEscapesScanner) = None
  var uri: (None | String trn)

  new create(directive: Bool, head: (String trn | None), mark: YamlMark val, nextScanner: _Scanner) =>
    _directive = directive
    _startMark = mark
    _nextScanner = nextScanner
    uri = match consume head
          | let s: String trn => consume s
          else recover String.create() end
          end

  fun ref apply(state: _ScannerState): _ScanResult ? =>
    if not state.available() then
      return ScanPaused(this)
    end
    while state.isAlpha() or state.check(';')
            or state.check('/') or state.check('?')
            or state.check(':') or state.check('@')
            or state.check('&') or state.check('=')
            or state.check('+') or state.check('$')
            or state.check(',') or state.check('.')
            or state.check('!') or state.check('~')
            or state.check('*') or state.check('\'')
            or state.check('(') or state.check(')')
            or state.check('[') or state.check(']')
            or state.check('%') do
      /* Check if it is a URI-escape sequence. */
      if state.check('%') then
        let s = _URIEscapesScanner.create(_directive, (uri = None) as String trn^, _startMark, this~_scanEscape())
        _uriEscapesScanner = s
        return s.apply(state)
      else
        match state.read((uri = None) as String trn^)
        | let u: String trn => uri = consume u
        | let e: ScanError => return e
        else
          error
        end
      end

      if not state.available() then
        return ScanPaused(this)
      end
    end

    /* Check if the tag is non-empty. */
    if (uri as String trn).size() == 0 then
      return ScanError(if _directive then "while parsing a %TAG directive" else "while parsing a tag" end,
                _startMark, "did not find expected tag URI")
    end
    _nextScanner.apply(state)

  fun ref _scanEscape(state: _ScannerState): _ScanResult ? =>
    let uriEscapesScanner = _uriEscapesScanner as _URIEscapesScanner
    uri = uriEscapesScanner.escaped = None
    this.apply(state)


/* Decode the required number of characters. */
class _URIEscapesScanner is _Scanner
  let _directive: Bool
  let _startMark: YamlMark val
  let _nextScanner: _Scanner
  var width: USize = 0
  var escaped: (None | String trn)

  new create(directive: Bool, escaped': String trn, mark: YamlMark val, nextScanner: _Scanner) =>
    _directive = directive
    _startMark = mark
    _nextScanner = nextScanner
    escaped = consume escaped'

  fun ref apply(state: _ScannerState): _ScanResult ? =>
    repeat
      /* Check for a URI-escaped octet. */
      if not state.available(3) then
        return ScanPaused(this)
      end

      if not (state.check('%') and state.isHex(1) and state.isHex(2)) then
        return ScanError(if _directive then "while parsing a %TAG directive" else "while parsing a tag" end,
                  _startMark, "did not find URI escaped octet")
      end

      /* Get the octet. */
      let octet: U8 = (state.asHex(1) << 4) + state.asHex(2)

      /* If it is the leading octet, determine the length of the UTF-8 sequence. */
      if width == 0 then
        width = if (octet and 0x80) == 0x00 then 1
                elseif (octet and 0xE0) == 0xC0 then 2
                elseif (octet and 0xF0) == 0xE0 then 3
                elseif (octet and 0xF8) == 0xF0 then 4
                else 0
                end
        if width == 0 then
          return ScanError(if _directive then "while parsing a %TAG directive" else "while parsing a tag" end,
                  _startMark, "found an incorrect leading UTF-8 octet")
        end
      else
        /* Check if the trailing octet is correct. */
        if ((octet and 0xC0) != 0x80) then
          return ScanError(if _directive then "while parsing a %TAG directive" else "while parsing a tag" end,
                  _startMark, "found an incorrect trailing UTF-8 octet")
        end
      end

      /* Copy the octet and move the pointers. */
      (escaped as String trn).push(octet)
      state.skip(3)
      width = width - 1
    until width == 0 end

    _nextScanner.apply(state)
