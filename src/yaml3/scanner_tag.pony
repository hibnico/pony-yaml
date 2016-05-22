
class _TagScanner
  let _startMark: YamlMark val
  let _nextScanner: _Scanner
  var _tagURIScanner: (None | _TagURIScanner) = None
  var _tagHandleScanner: (None | _TagHandleScanner) = None
  let _handle: String ref = String
  let _suffix: String ref = String

  new create(startMark: YamlMark val, nextScanner: _Scanner) =>
    _startMark = startMark
    _nextScanner = nextScanner

  fun ref scan(state: _ScannerState): _ScanResult ? =>
    if not state.available(2) then
      return ScanPaused
    end
    if state.check('<', 1) then
      /* Set the handle to '' */
      _handle.clear()
      state.skip(2)
      let s = _TagURIScanner.create(false, None, _startMark, _InlineScanner(this~_scanEndUri()))
      _tagURIScanner = s
      s
    else
      /* The tag has either the '!suffix' or the '!handle!suffix' form. */
      /* First, try to scan a handle. */
      let s = _TagHandleScanner.create(false, _startMark, this~_scanEndHandle())
      _tagHandleScanner = s
      s
    end

  fun ref _scanEndUri(state: _ScannerState): _ScanResult ? =>
    if not state.check('>') then
      return ScanError("while scanning a tag", _startMark, "did not find the expected '>'")
    end
    let tagURIScanner = _tagURIScanner as _TagURIScanner
    _suffix = tagURIScanner.uri
    state.skip()
    this~_scanEnd()

  fun ref _scanEndHandle(state: _ScannerState): _ScanResult ? =>
    let tagHandleScanner = _tagHandleScanner as _TagHandleScanner
    _handle = tagHandleScanner.handle
    /* Check if it is, indeed, handle. */
    if (_handle(0) == '!') and (_handle.size() > 1) and (_handle(_handle.size() - 1) == '!') then
      /* Scan the suffix now. */
      let s = _TagURIScanner.create(false, None, _startMark, this~_scanEndUriWithHandle())
      _tagUriScanner = s
      s
    else
      /* It wasn't a handle after all.  Scan the rest of the tag. */
      let s = _TagURIScanner.create(false, _handle, _startMark, this~_scanEndUriWithBadHandle())
      _tagUriScanner = s
      s
    end

  fun ref _scanEndUriWithHandle(state: _ScannerState): _ScanResult ? =>
    let tagURIScanner = _tagURIScanner as _TagURIScanner
    _suffix = tagURIScanner.uri
    this~_scanEnd()

  fun ref _scanEndUriWithBadHandle(state: _ScannerState): _ScanResult ? =>
    /* Set the handle to '!'. */
    _handle = "!"
    let tagURIScanner = _tagURIScanner as _TagURIScanner
    _suffix = tagURIScanner.uri
    /*
     * A special case: the '!' tag.  Set the handle to '' and the
     * suffix to '!'.
     */
    if _suffix.size() == 0 then
      _suffix = _handle = _suffix
    end
    this~_scanEnd()

  fun ref _scanEnd(state: _ScannerState): _ScanResult ? =>
    if not state.available() then
      return ScanPaused
    end
    if not state.isBlankZ() then
      return ScanError("while scanning a tag", _startMark, "did not find expected whitespace or line break")
    end
    let endMark = state.mark.clone()
    state.emitToken(_YamlTagToken(_startMark, endMark, _YamlTagTokenData(_handle, _suffix)))
    _nextScanner


/*
 * Scan a tag handle.
 */
class _TagHandleScanner
  let _directive: Bool
  let _startMark: YamlMark val
  let _nextScanner: _Scanner
  var handle: String = String.create()

  new create(directive: Bool, mark: YamlMark val, nextScanner: _Scanner) =>
    _directive = directive
    _startMark = mark
    _nextScanner = nextScanner

  fun scan(state: _ScannerState): _ScanResult ? =>
    /* Check the initial '!' character. */
    if not state.available() then
      return ScanPaused
    end
    if not state.check('!') then
      return ScanError(if _directive then "while scanning a tag directive" else "while scanning a tag" end,
                _startMark, "did not find expected '!'")
    end
    /* Copy the '!' character. */
    handle.push('!')
    state.skip()
    this~_scanAlpha()

  fun _scanAlpha(state: _ScannerState): _ScanResult ? =>
    /* Copy all subsequent alphabetical and numerical characters. */
    if not state.available() then
      return ScanPaused
    end
    while state.isAlpha() do
      state.read(handle)
      if not state.available() then
        return ScanPaused
      end
    end

    /* Check if the trailing character is '!' and copy it. */
    if state.check('!') then
      handle.push('!')
      state.skip()
    else
      /*
       * It's either the '!' tag or not really a tag handle.  If it's a %TAG
       * directive, it's an error.  If it's a tag token, it must be a part of
       * URI.
       */

      if (_directive and not ((handle(0) == '!') and (handle.size() == 1))) then
        return ScanError("while parsing a tag directive", _startMark, "did not find expected '!'")
      end
    end
    _nextScanner


/*
 * The set of characters that may appear in URI is as follows:
 *
 *      '0'-'9', 'A'-'Z', 'a'-'z', '_', '-', ';', '/', '?', ':', '@', '&',
 *      '=', '+', '$', ',', '.', '!', '~', '*', '\'', '(', ')', '[', ']',
 *      '%'.
 */
class _TagURIScanner
  let _directive: Bool
  let _startMark: YamlMark val
  let _nextScanner: _Scanner
  var _uriEscapesScanner: (None | _URIEscapesScanner) = None
  let uri: String

  new create(directive: Bool, head: (String | None), mark: YamlMark val, nextScanner: _Scanner) =>
    _directive = directive
    _startMark = mark
    _nextScanner = nextScanner
    uri = match head
          | let s: String => s.clone()
          else String()
          end

  fun scan(state: _ScannerState): _ScanResult ? =>
    if not state.available() then
      return ScanPaused
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
        let s = _URIEscapesScanner.create(_directive, _startMark, this~_scanEscape())
        _uriEscapesScanner = s
        return s
      else
        state.read(uri)
      end

      if not state.available() then
        return ScanPaused
      end
    end

    /* Check if the tag is non-empty. */
    if uri.size() == 0 then
      return ScanError(if _directive then "while parsing a %TAG directive" else "while parsing a tag" end,
                _startMark, "did not find expected tag URI")
    end
    _nextScanner

  fun _scanEscape(state: _ScannerState): _ScanResult ? =>
    let uriEscapesScanner = _uriEscapesScanner as _URIEscapesScanner
    uri.append(uriEscapesScanner.string)
    this~scan()


/* Decode the required number of characters. */
class _URIEscapesScanner
  let _directive: Bool
  let _startMark: YamlMark val
  let _nextScanner: _Scanner
  var width: USize = 0
  let string: String = String()

  new create(directive: Bool, mark: YamlMark val, nextScanner: _Scanner) =>
    _directive = directive
    _startMark = mark
    _nextScanner = nextScanner

  fun scan(state: _ScannerState): _ScanResult ? =>
    repeat
      /* Check for a URI-escaped octet. */
      if not state.available(3) then
        return ScanPaused
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
      string.push(octet)
      state.skip(3)
      width = width - 1
    until width == 0 end

    _nextScanner
