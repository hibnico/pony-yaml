
class _ScannerState
  var _scanner: _Scanner = _RootScanner
  let mark: YamlMark = YamlMark.create()
  let _data: Array[U8] = Array[U8].create(1024)
  var _pos: USize = 0
  var simpleKeyAllowed: Bool = true
  var flowLevel: USize = 0
  var indent: USize = 0
  let indents: Array[USize] = Array[USize].create(5)

  fun ref run(): (ScanDone | ScanPaused | ScanError) ? =>
    match _scanner.apply(this)
    | let p: ScanPaused => _scanner = p.nextScanner; p
    | let e: ScanError => e
    | ScanDone => ScanDone
    else
      error
    end

  fun emitToken(token: _YAMLToken[Any]) =>
    None

  fun available(nb: USize = 1): Bool =>
    (_data.size() - _pos) >= nb

  /*
   * Determine the width of the character.
   */
  fun width(): USize ? =>
    let char = _data(_pos)
    if (char and 0x80) == 0x00 then 1
    elseif (char and 0xE0) == 0xC0 then 2
    elseif (char and 0xF0) == 0xE0 then 3
    elseif (char and 0xF8) == 0xF0 then 4
    else 0
    end

  fun at(i: USize = 0): U8 ? =>
    _data(_pos + i)

  fun ref skip(nb: USize = 1) ? =>
    mark.index = mark.index + nb
    mark.column = mark.column + nb
    var n = nb
    while n > 0 do
      _pos = _pos + width()
      n = n - 1
    end

  fun ref skipLine() ? =>
    if isCrlf() then
      mark.index = mark.index + 2
      mark.column = 0
      mark.line = mark.line + 1
      _pos = _pos + 2
    elseif isBreak() then
      mark.index = mark.index + 1
      mark.column = 0
      mark.line = mark.line + 1
      _pos = _pos + width()
    end

  fun ref read(s: String trn): (ScanError | String trn^) ? =>
    let char = _data(_pos)
    if (char and 0x80) == 0x00 then
      s.push(char)
      _pos = _pos + 1
    elseif (char and 0xE0) == 0xC0 then
      s.push(char)
      s.push(_data(_pos + 1))
      _pos = _pos + 2
    elseif (char and 0xF0) == 0xE0 then
      s.push(char)
      s.push(_data(_pos + 1))
      s.push(_data(_pos + 2))
      _pos = _pos + 2
    elseif (char and 0xF8) == 0xF0 then
      s.push(char)
      s.push(_data(_pos + 1))
      s.push(_data(_pos + 2))
      s.push(_data(_pos + 3))
      _pos = _pos + 3
    else
      return ScanError("Invalid caracter", mark.clone(), "")
    end
    mark.index = mark.index + 1
    mark.column = mark.column + 1
    consume s

  fun ref readLine(s: String trn): (ScanError | String trn^) ? =>
    if check('\r') and check('\n', 1) then        /* CR LF -> LF */
      s.push('\n')
      _pos = _pos + 2
      mark.index = mark.index + 2
      mark.column = 0
      mark.line = mark.line + 1
    elseif check('\r') or check('\n') then         /* CR|LF -> LF */
      s.push('\n')
      _pos = _pos + 1
      mark.index = mark.index + 1
      mark.column = 0
      mark.line = mark.line + 1
    elseif check('\xC2') and check('\x85', 1) then       /* NEL -> LF */
      s.push('\n')
      _pos = _pos + 2
      mark.index = mark.index + 1
      mark.column = 0
      mark.line = mark.line + 1
    elseif check('\xE2') and check('\x80', 1) and (check('\xA8', 2) or check('\xA9', 2)) then  /* LS|PS -> LS|PS */
      s.push(_data(_pos = _pos + 1))
      s.push(_data(_pos = _pos + 1))
      s.push(_data(_pos = _pos + 1))
      mark.index = mark.index + 1
      mark.column = 0
      mark.line = mark.line + 1
    else
      error
    end
    consume s


  /*
   * Check the current octet in the buffer.
   */
  fun check(char: U8, offset: USize = 0): Bool ? =>
    _data(_pos + offset) == char

  /*
   * Check if the character at the specified position is an alphabetical
   * character, a digit, '_', or '-'.
   */
  fun isAlpha(offset: USize = 0): Bool ? =>
    let char = _data(_pos + offset)
    ((char >= '0') and (char <= '9'))
       or ((char >= 'A') and (char <= 'Z'))
       or ((char >= 'a') and (char <= 'z'))
       or (char == '_')
       or (char == '-')


  /*
   * Check if the character at the specified position is a digit.
   */
  fun isDigit(offset: USize = 0): Bool ? =>
    let char = _data(_pos + offset)
    (char >= '0') and (char <= '9')

  /*
   * Get the value of a digit.
   */
  fun asDigit(offset: USize = 0): U8 ? =>
    _data(_pos + offset) - '0'

  /*
   * Check if the character at the specified position is a hex-digit.
   */
  fun isHex(offset: USize = 0): Bool ? =>
    let char = _data(_pos + offset)
    ((char >= '0') and (char <= '9'))
      or ((char >= 'A') and (char <= 'F'))
      or ((char >= 'a') and (char <= 'f'))

  /*
   * Get the value of a hex-digit.
   */
  fun asHex(offset: USize = 0): U8 ? =>
    let char = _data(_pos + offset)
    match char
    | let c: U8 if (c >= 'A') and (c <= 'F') => (c - 'A') + 10
    | let c: U8 if (c >= 'a') and (c <= 'f') => (c - 'a') + 10
    else
      char - '0'
    end

  /*
   * Check if the character is ASCII.
   */
  fun isAscii(offset: USize = 0): Bool ? =>
    let char = _data(_pos + offset)
    char <= '\x7F'

  /*
   * Check if the character can be printed unescaped.
   */
  fun isPrintable(offset: USize = 0): Bool ? =>
    let char = _data(_pos + offset)
    ((char == 0x0A)         /* . == #x0A */
     or ((char >= 0x20)       /* #x20 <= . <= #x7E */
         and (char <= 0x7E))
     or ((char == 0xC2)       /* #0xA0 <= . <= #xD7FF */
         and (_data(_pos + offset + 1) >= 0xA0))
     or ((char > 0xC2)
         and (char < 0xED))
     or ((char == 0xED)
         and (_data(_pos + offset + 1) < 0xA0))
     or (char == 0xEE)
     or ((char == 0xEF)      /* #xE000 <= . <= #xFFFD */
         and not ((_data(_pos + offset + 1) == 0xBB)        /* and . != #xFEFF */
                  and (_data(_pos + offset + 2) == 0xBF))
         and not ((_data(_pos + offset + 1) == 0xBF)
                  and ((_data(_pos + offset + 2) == 0xBE)
                       or (_data(_pos + offset + 2) == 0xBF)))))

  /*
   * Check if the character at the specified position is NUL.
   */
  fun isZ(offset: USize = 0): Bool ? =>
    _data(_pos + offset) == '\0'

  /*
   * Check if the character at the specified position is BOM.
   */
  fun isBom(offset: USize = 0): Bool ? =>
    (_data(_pos + offset) == '\xEF')
      and (_data(_pos + offset + 1) == '\xBB')
      and (_data(_pos + offset + 2) == '\xBF')  /* BOM (#xFEFF) */

  /*
   * Check if the character at the specified position is space.
   */
  fun isSpace(offset: USize = 0): Bool ? =>
    _data(_pos + offset) == ' '

  /*
   * Check if the character at the specified position is tab.
   */
  fun isTab(offset: USize = 0): Bool ? =>
    _data(_pos + offset) == '\t'

  /*
   * Check if the character at the specified position is blank (space or tab).
   */
  fun isBlank(offset: USize = 0): Bool ? =>
    isSpace(offset) or isTab(offset)

  /*
   * Check if the character at the specified position is a line break.
   */
  fun isBreak(offset: USize = 0): Bool ? =>
    (_data(_pos + offset) == '\r')                  /* CR (#xD)*/
      or (_data(_pos + offset) == '\n')             /* LF (#xA) */
      or ((_data(_pos + offset) == '\xC2')
        and (_data(_pos + offset + 1) == '\x85'))   /* NEL (#x85) */
      or ((_data(_pos + offset) == '\xE2')
        and (_data(_pos + offset + 1) == '\x80')
        and (_data(_pos + offset + 2) == '\xA8'))   /* LS (#x2028) */
      or ((_data(_pos + offset) == '\xE2')
        and (_data(_pos + offset + 1) == '\x80')
        and (_data(_pos + offset + 2) == '\xA9'))   /* PS (#x2029) */

  fun isCrlf(offset: USize = 0): Bool ? =>
    (_data(_pos + offset) == '\r') and (_data(_pos + offset + 1) == '\n')

  /*
   * Check if the character is a line break or NUL.
   */
  fun isBreakZ(offset: USize = 0): Bool ? =>
    isBreak(offset) or isZ(offset)

  /*
   * Check if the character is a line break, space, or NUL.
   */
  fun isSpaceZ(offset: USize = 0): Bool ? =>
    isSpace(offset) or isBreakZ(offset)

  /*
   * Check if the character is a line break, space, tab, or NUL.
   */
  fun isBlankZ(offset: USize = 0): Bool ? =>
    isBlank(offset) or isBreakZ(offset)
