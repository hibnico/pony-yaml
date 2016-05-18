
primitive _ScanURIChars
primitive _ScanEscape
type _State is (_ScanURIChars | _ScanEscape)

/*
 * The set of characters that may appear in URI is as follows:
 *
 *      '0'-'9', 'A'-'Z', 'a'-'z', '_', '-', ';', '/', '?', ':', '@', '&',
 *      '=', '+', '$', ',', '.', '!', '~', '*', '\'', '(', ')', '[', ']',
 *      '%'.
 */
class _TagURIScanner is _Scanner
  let _directive: Boolean
  let _startMark: YamlMark val
  var _state: _State = _ScanURIChars
  var _uriEscapesScanner: (None | _URIEscapesScanner) = None
  let uri: String

  new create(directive: Bool, head: (String | None), mark: YamlMark val) =>
    _directive = directive
    _startMark = mark
    uri = match head
          | let s: String => s.clone()
          else String()
          end

  fun scan(state: _ScannerState): ScanResult =>
    match _state
    | _ScanURIChars => _scanURIChars(state)
    | _ScanEscape => _scanEscape(state)

  fun _scanURIChars(state: _ScannerState): ScanResult =>
    if not state.buffer.available() then
      return ScanContinue
    end
    while state.buffer.isAlpha() or state.buffer.check(';') do
            or state.buffer.check('/') or state.buffer.check('?')
            or state.buffer.check(':') or state.buffer.check('@')
            or state.buffer.check('&') or state.buffer.check('=')
            or state.buffer.check('+') or state.buffer.check('$')
            or state.buffer.check(',') or state.buffer.check('.')
            or state.buffer.check('!') or state.buffer.check('~')
            or state.buffer.check('*') or state.buffer.check('\'')
            or state.buffer.check('(') or state.buffer.check(')')
            or state.buffer.check('[') or state.buffer.check(']')
            or state.buffer.check('%') do
      /* Check if it is a URI-escape sequence. */
      if state.buffer.check('%') then
        let s = _URIEscapesScanner.create(_directive, _startMark)
        state.scannerStack.push(s)
        _uriEscapesScanner = s
        _state = _ScanEscape
        return ScanContinue
      else
        state.read(uri)
      end

      if not state.buffer.available() then
        return ScanContinue
      end
    end

    /* Check if the tag is non-empty. */
    if uri.size() == 0 then
      return ScanError(if _directive then "while parsing a %TAG directive" else "while parsing a tag" end,
                _startMark, "did not find expected tag URI")
    end
    state.scannerStack.pop()
    ScanDone

  fun _scanEscape(state: _ScannerState): ScanResult =>
    let uriEscapesScanner = try _uriEscapesScanner as _URIEscapesScanner end
    uri.append(uriEscapesScanner.string)
    _state = _ScanURIChars
    ScanContinue
