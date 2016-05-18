
/* Decode the required number of characters. */
class _URIEscapesScanner is _Scanner
  let _directive: Boolean
  let _startMark: YamlMark val
  var width: USize = 0
  let string = String()

  new create(directive: Bool, mark: YamlMark val) =>
    _directive = directive
    _startMark = mark

  fun scan(state: _ScannerState): ScanResult =>
    do
      /* Check for a URI-escaped octet. */
      if not state.buffer.available(3) then
        return ScanContinue
      end

      if not (state.buffer.check('%') and state.buffer.isHex(1) and state.buffer.isHex(2)) then
        return ScanError(if _directive then "while parsing a %TAG directive" else "while parsing a tag" end,
                  _startMark, "did not find URI escaped octet")
      end

      /* Get the octet. */
      let octet: U8 = (state.buffer.asHex(1) << 4) + state.buffer.asHex(2)

      /* If it is the leading octet, determine the length of the UTF-8 sequence. */
      if width == 0 then
        width = (octet & 0x80) == 0x00 ? 1 :
                (octet & 0xE0) == 0xC0 ? 2 :
                (octet & 0xF0) == 0xE0 ? 3 :
                (octet & 0xF8) == 0xF0 ? 4 : 0;
        if width == 0 then
          return ScanError(if _directive then "while parsing a %TAG directive" else "while parsing a tag" end,
                  _startMark, "found an incorrect leading UTF-8 octet")
        end
      else
        /* Check if the trailing octet is correct. */
        if ((octet & 0xC0) != 0x80) then
          return ScanError(if _directive then "while parsing a %TAG directive" else "while parsing a tag" end,
                  _startMark, "found an incorrect trailing UTF-8 octet")
        end
      end

      /* Copy the octet and move the pointers. */
      string.push(octet)
      state.skip(3)
      width = width - 1
    } while (width > 0)

    state.scannerStack.pop()
    ScanDone
