
/* Decode the required number of characters. */
class _URIEscapesScanner is _Scanner
  let _directive: Bool
  let _startMark: YamlMark val
  let _nextScanner: _Scanner
  var width: USize = 0
  var escaped: (None | String iso)

  new create(directive: Bool, escaped': String iso, mark: YamlMark val, nextScanner: _Scanner) =>
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
      (escaped as String iso).push(octet)
      state.skip(3)
      width = width - 1
    until width == 0 end

    _nextScanner.apply(state)
