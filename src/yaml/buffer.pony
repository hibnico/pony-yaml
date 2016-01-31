
class Buffer
  let buffer: Array[U8]

  fun cache(length: U8): Bool =>
    true // TODO

  /*
   * Check the octet at the specified position.
   */
  fun checkAt(octet: U8, offset: USize): Bool =>
    buffer(offset) == octet

  /*
   * Check the current octet in the buffer.
   */
  fun check(octet: U8): Bool =>
    checkAt(octet, 0)

  /*
   * Check if the character at the specified position is an alphabetical
   * character, a digit, '_', or '-'.
   */
  fun isAlphaAt(offset: USize): Bool =>
    (buffer(offset) >= '0' and buffer(offset) <= '9')
      or (buffer(offset) >= 'A' and buffer(offset) <= 'Z')
      or (buffer(offset) >= 'a' and buffer(offset) <= 'z')
      or buffer(offset) == '_'
      or buffer(offset) == '-'

  fun isAlpha(): Bool =>
    isAlphaAt(0)

  /*
   * Check if the character at the specified position is a digit.
   */
  fun isDigitAt(offset: USize): Bool =>
    buffer(offset) >= '0' and buffer(offset) <= '9'

  fun isDigit(): Bool =>
    isDigitAt(0)

  /*
   * Get the value of a digit.
   */
  fun asDigitAt(offset: USize): Bool =>
    buffer(offset) - '0'

  fun asDigit(): Bool =>
    asDigitAt(0)

  /*
   * Check if the character at the specified position is a hex-digit.
   */
  fun isHexAt(offset: USize): Bool =>
    (buffer(offset) >= '0' and buffer(offset) <= '9')
      or (buffer(offset) >= 'A' and buffer(offset) <= 'F')
      or (buffer(offset) >= 'a' and buffer(offset) <= 'f')

  fun isHex(): Bool =>
    isHexAt(0)

  /*
   * Get the value of a hex-digit.
   */
  fun asHexAt(offset: USize): U8 =>
    match buffer(offset)
    | let c: U8 if c >= 'A' and c <= 'F' => c - 'A' + 10
    | let c: U8 if c >= 'a' and c <= 'f' => c - 'a' + 10
    else
      buffer(offset) - '0'
    end

  fun asHex(): U8 =>
    asHexAt(0)

  /*
   * Check if the character is ASCII.
   */
  fun isAsciiAt(offset: USize): Bool =>
    buffer(offset) <= '\x7F'

  fun isAscii(): Bool =>
    isAsciiAt(0)

  /*
   * Check if the character can be printed unescaped.
   */
  fun isPrintableAt(offset: USize): Bool =>
    ((buffer(offset) == 0x0A)         /* . == #x0A */
     or (buffer(offset) >= 0x20       /* #x20 <= . <= #x7E */
         and buffer(offset) <= 0x7E)
     or (buffer(offset) == 0xC2       /* #0xA0 <= . <= #xD7FF */
         and (string).pointer[offset+1] >= 0xA0)
     or (buffer(offset) > 0xC2
         and buffer(offset) < 0xED)
     or (buffer(offset) == 0xED
         and (string).pointer[offset+1] < 0xA0)
     or (buffer(offset) == 0xEE)
     or (buffer(offset) == 0xEF      /* #xE000 <= . <= #xFFFD */
         and not ((string).pointer[offset+1] == 0xBB        /* and . != #xFEFF */
             and (string).pointer[offset+2] == 0xBF)
         and not ((string).pointer[offset+1] == 0xBF
             and ((string).pointer[offset+2] == 0xBE
                 or (string).pointer[offset+2] == 0xBF))))

  fun isPrintable(): Bool =>
    isPrintableAt(0)

  /*
   * Check if the character at the specified position is NUL.
   */
  fun isZAt(offset: USize): Bool =>
    checkAt('\0', offset)

  fun isZ(): Bool =>
    isZAt(0)

  /*
   * Check if the character at the specified position is BOM.
   */
  fun isBomAt(offset: USize): Bool =>
    (checkAt('\xEF', offset)
      and checkAt('\xBB', offset + 1)
      and checkAt('\xBF', offset + 2))  /* BOM (#xFEFF) */

  fun isBom(): Bool =>
    isBomAt(0)

  /*
   * Check if the character at the specified position is space.
   */
  fun isSpaceAt(offset: USize): Bool =>
    checkAt(' ', offset)

  fun isSpace(): Bool =>
    isSpace(0)

  /*
   * Check if the character at the specified position is tab.
   */
  fun isTabAt(offset: USize): Bool =>
    checkAt('\t', offset)

  fun isTab(): Bool =>
    isTabAt(0)

  /*
   * Check if the character at the specified position is blank (space or tab).
   */
  fun isBlankAt(offset: USize): Bool =>
    isSpaceAt(offset) or isTabAt(offset)

  fun isBlank(): Bool =>
    isBlankAt(0)

  /*
   * Check if the character at the specified position is a line break.
   */
  fun isBreakAt(offset: USize): Bool =>
    (checkAt('\r', offset)               /* CR (#xD)*/
      or checkAt('\n', offset)            /* LF (#xA) */
      or (checkAt('\xC2', offset)
        and checkAt('\x85', offset + 1))   /* NEL (#x85) */
      or (checkAt('\xE2', offset)
        and checkAt('\x80', offset + 1)
        and checkAt('\xA8', offset + 2))   /* LS (#x2028) */
      or (checkAt('\xE2', offset)
        and checkAt('\x80', offset + 1)
        and checkAt('\xA9', offset + 2)))  /* PS (#x2029) */

  fun isBreak(): Bool =>
    isBreakAt(0)

  fun isCrlfAt(offset: USize): Bool =>
    checkAt('\r', offset) and checkAt('\n', offset + 1)

  fun isCrlf(): Bool =>
    isCrlfAt(0)

  /*
   * Check if the character is a line break or NUL.
   */
  fun isBreakZAt(offset: USize): Bool =>
    isBreakAt(offset) or isZAt(offset)

  fun isBreakZ(): Bool =>
    isBreakZAt(0)

  /*
   * Check if the character is a line break, space, or NUL.
   */
  fun isSpaceZAt(offset: USize): Bool =>
    isSpaceAt(offset) or isBreakZAt(offset)

  fun isSpaceZ(): Bool =>
    isSpaceZAt(0)

  /*
   * Check if the character is a line break, space, tab, or NUL.
   */
  fun isBlankZAt(offset: USize): Bool =>
    isBlankAt(offset) or isBreakZAt(offset)

  fun isBlankZ(): Bool =>
    isBlankZAt(0)

  /*
   * Determine the width of the character.
   */
  fun widthAt(offset: USize): U8 =>
     ((buffer(offset) & 0x80) == 0x00 ? 1 :
      (buffer(offset) & 0xE0) == 0xC0 ? 2 :
      (buffer(offset) & 0xF0) == 0xE0 ? 3 :
      (buffer(offset) & 0xF8) == 0xF0 ? 4 : 0)

  fun width(): U8 =>
    widthAt(0)

  /*
   * Move the string pointer to the next character.
   */
  fun move() =>
    buffer = buffer + width()

//   /*
//    * Copy a character and move the pointers of both strings.
//    */
// #define COPY(string_a,string_b)
//     ((*(string_b).pointer & 0x80) == 0x00 ?
//      (*((string_a).pointer++) = *((string_b).pointer++)) :
//      (*(string_b).pointer & 0xE0) == 0xC0 ?
//      (*((string_a).pointer++) = *((string_b).pointer++),
//       *((string_a).pointer++) = *((string_b).pointer++)) :
//      (*(string_b).pointer & 0xF0) == 0xE0 ?
//      (*((string_a).pointer++) = *((string_b).pointer++),
//       *((string_a).pointer++) = *((string_b).pointer++),
//       *((string_a).pointer++) = *((string_b).pointer++)) :
//      (*(string_b).pointer & 0xF8) == 0xF0 ?
//      (*((string_a).pointer++) = *((string_b).pointer++),
//       *((string_a).pointer++) = *((string_b).pointer++),
//       *((string_a).pointer++) = *((string_b).pointer++),
//       *((string_a).pointer++) = *((string_b).pointer++)) : 0)
