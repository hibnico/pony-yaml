primitive UTF32BE
  fun string(): String val => "UTF32BE"

primitive UTF32LE
  fun string(): String val => "UTF32LE"

primitive UTF16BE
  fun string(): String val => "UTF16BE"

primitive UTF16LE
  fun string(): String val => "UTF16LE"

primitive UTF8
  fun string(): String val => "UTF8"

type Encoding is (UTF32BE | UTF32LE | UTF16BE | UTF16LE | UTF8)

class EncodingError
  let message: String
  let pos: USize
  new create(message': String, pos': USize) =>
    message = message'
    pos = pos'

primitive _IncompleteEncoding

actor _Reader
  var _pos: USize = 0
  var _encodingDetermined: Bool = false
  var _data: Array[U8] = Array[U8].create(1024)
  var _encoding: Encoding = UTF8
  let _codepointBufferSize: USize
  let _codePointsReader: CodePointsReader

  new create(codePointsReader: CodePointsReader, codepointBufferSize: USize = 2014) =>
    _codepointBufferSize = codepointBufferSize
    _codePointsReader = codePointsReader

  be read(data: Array[U8] val) =>
    try
      _append(data)
      if (not _encodingDetermined) and (_data.size() >= 4) then
        _encoding = _determineEncoding()
        _encodingDetermined = true
        _codePointsReader.setEncoding(_encoding)
      end
      _readAndSend()
    end

  fun ref _append(data: Array[U8] val) =>
    // use the opportunity to reclaim some ununsed space
    if _pos != 0 then
      let len = _data.size() - _pos
      _data.copy_to(_data, _pos, 0, len)
      _data.truncate(len)
      _pos = 0
    end
    if data.size() == 0 then
      _data.push(0)
    else
      _data.append(data)
    end

  // see http://www.yaml.org/spec/1.2/spec.html#id2771184
  fun ref _determineEncoding(): Encoding ? =>
    if _data(0) == 0x00 then
      if _data(1) == 0x00 then
        if (_data(2) == 0xFE) and (_data(3) == 0xFF) then
          // BOM
          _pos = _pos + 4
          UTF32BE
        elseif _data(2) == 0x00 then
          UTF32BE
        else
          UTF8
        end
      else
        UTF16BE
      end
    elseif _data(0) == 0xFF then
      if (_data(1) == 0xFE) then
        if (_data(2) == 0x00) and (_data(3) == 0x00) then
          // BOM
          _pos = _pos + 4
          UTF32LE
        else
          // BOM
          _pos = _pos + 2
          UTF16LE
        end
      else
        UTF8
      end
    elseif (_data(0) == 0xFE) and (_data(1) == 0xFF) then
      // BOM
      _pos = _pos + 2
      UTF16BE
    elseif (_data(0) == 0xFE) and (_data(1) == 0xBB) and (_data(2) == 0xBF) then
      // BOM
      _pos = _pos + 3
      UTF8
    elseif _data(1) == 0x00 then
      if (_data(2) == 0x00) and (_data(3) == 0x00) then
        UTF32LE
      else
        UTF16LE
      end
    else
      UTF8
    end

  fun ref _readAndSend(): (None | EncodingError) ? =>
    let s: USize = _codepointBufferSize
    let codePoints: Array[U32] iso = recover Array[U32].create(s) end
    while (_pos < _data.size()) and (codePoints.size() < _codepointBufferSize) do
      if _data(_pos) == 0 then
        codePoints.push(0)
        _pos = _pos + 1
        break
      end
      let value: U32 = match _decode()
                      | _IncompleteEncoding => break
                      | let e: EncodingError => return e
                      | let v: U32 => v
                      else
                        error
                      end
      codePoints.push(value)
    end
    _codePointsReader.read(consume codePoints)
    None

  fun ref _decode(): (U32 | EncodingError | _IncompleteEncoding) ? =>
    match match _encoding
          | UTF8 => _decodeUTF8()
          | UTF16LE => _decodeUTF16(0, 1)
          | UTF16BE => _decodeUTF16(1, 0)
          | UTF32LE => _decodeUTF32(0, 1, 2, 3)
          | UTF32BE => _decodeUTF32(3, 2, 1, 0)
          else
            error
          end
    | _IncompleteEncoding => _IncompleteEncoding
    | let e: EncodingError => e
    | let value: U32 =>
      /*
       * Check if the character is in the allowed range:
       *      #x9 | #xA | #xD | [#x20-#x7E]               (8 bit)
       *      | #x85 | [#xA0-#xD7FF] | [#xE000-#xFFFD]    (16 bit)
       *      | [#x10000-#x10FFFF]                        (32 bit)
       */
      if not (   (value == 0x09)
              or (value == 0x0A)
              or (value == 0x0D)
              or ((value >= 0x20) and (value <= 0x7E))
              or (value == 0x85)
              or ((value >= 0xA0) and (value <= 0xD7FF))
              or ((value >= 0xE000) and (value <= 0xFFFD))
              or ((value >= 0x10000) and (value <= 0x10FFFF))
              ) then
        return EncodingError("control characters are not allowed", _pos)
      end
      value
    else
      error
    end


  /*
   * Decode a UTF-8 character.  Check RFC 3629
   * (http://www.ietf.org/rfc/rfc3629.txt) for more details.
   *
   * The following table (taken from the RFC) is used for
   * decoding.
   *
   *    Char. number range |        UTF-8 octet sequence
   *      (hexadecimal)    |              (binary)
   *   --------------------+------------------------------------
   *   0000 0000-0000 007F | 0xxxxxxx
   *   0000 0080-0000 07FF | 110xxxxx 10xxxxxx
   *   0000 0800-0000 FFFF | 1110xxxx 10xxxxxx 10xxxxxx
   *   0001 0000-0010 FFFF | 11110xxx 10xxxxxx 10xxxxxx 10xxxxxx
   *
   * Additionally, the characters in the range 0xD800-0xDFFF
   * are prohibited as they are reserved for use with UTF-16
   * surrogate pairs.
   */
  fun ref _decodeUTF8(): (U32 | EncodingError | _IncompleteEncoding) ? =>
    /* Determine the length of the UTF-8 sequence. */
    var octet: U8 = _data(_pos)
    let width: USize =
      if (octet and 0x80) == 0x00 then 1
      elseif (octet and 0xE0) == 0xC0 then 2
      elseif (octet and 0xF0) == 0xE0 then 3
      elseif (octet and 0xF8) == 0xF0 then 4
      else 0
      end
    /* Check if the leading octet is valid. */
    if width == 0 then
      return EncodingError.create("invalid leading UTF-8 octet", _pos)
    end
    /* Check if the raw buffer contains an incomplete character. */
    if width > (_data.size() - _pos) then
      if _data(_data.size() - 1) == 0 then
        return EncodingError.create("incomplete UTF-8 octet sequence", _pos)
      end
      return _IncompleteEncoding
    end
    /* Decode the leading octet. */
    var value: U32 =
      if (octet and 0x80) == 0x00 then (octet and 0x7F).u32()
      elseif (octet and 0xE0) == 0xC0 then (octet and 0x1F).u32()
      elseif (octet and 0xF0) == 0xE0 then (octet and 0x0F).u32()
      elseif (octet and 0xF8) == 0xF0 then (octet and 0x07).u32()
      else 0
      end
    /* Check and decode the trailing octets. */
    var k: USize = 1
    while k < width do
      octet = _data(_pos + k)
      /* Check if the octet is valid. */
      if (octet and 0xC0) != 0x80 then
        return EncodingError.create("invalid trailing UTF-8 octet", _pos)
      end
      /* Decode the octet. */
      value = (value << 6) + (octet and 0x3F).u32()
      k = k + 1
    end
    /* Check the length of the sequence against the value. */
    if not(   (width == 1)
           or ((width == 2) and (value >= 0x80))
           or ((width == 3) and (value >= 0x800))
           or ((width == 4) and (value >= 0x10000))
          ) then
      return EncodingError.create("invalid length of a UTF-8 sequence", _pos)
    end
    /* Check the range of the value. */
    if ((value >= 0xD800) and (value <= 0xDFFF)) or (value > 0x10FFFF) then
      return EncodingError.create("invalid Unicode character", _pos)
    end
    _pos = _pos + width
    value

  /*
   * The UTF-16 encoding is not as simple as one might
   * naively think.  Check RFC 2781
   * (http://www.ietf.org/rfc/rfc2781.txt).
   *
   * Normally, two subsequent bytes describe a Unicode
   * character.  However a special technique (called a
   * surrogate pair) is used for specifying character
   * values larger than 0xFFFF.
   *
   * A surrogate pair consists of two pseudo-characters:
   *      high surrogate area (0xD800-0xDBFF)
   *      low surrogate area (0xDC00-0xDFFF)
   *
   * The following formulas are used for decoding
   * and encoding characters using surrogate pairs:
   *
   *  U  = U' + 0x10000   (0x01 00 00 <= U <= 0x10 FF FF)
   *  U' = yyyyyyyyyyxxxxxxxxxx   (0 <= U' <= 0x0F FF FF)
   *  W1 = 110110yyyyyyyyyy
   *  W2 = 110111xxxxxxxxxx
   *
   * where U is the character value, W1 is the high surrogate
   * area, W2 is the low surrogate area.
   */
  fun ref _decodeUTF16(low: USize, high: USize): (U32 | EncodingError | _IncompleteEncoding) ? =>
    /* Check for incomplete UTF-16 character. */
    if (_data.size() - _pos) < 2 then
      if _data(_data.size() - 1) == 0 then
        return EncodingError.create("incomplete UTF-16 character", _pos)
      end
      return _IncompleteEncoding
    end
    /* Get the character. */
    var value: U32 = _data(_pos + low).u32() + (_data(_pos + high).u32() << 8)
    /* Check for unexpected low surrogate area. */
    if (value and 0xFC00) == 0xDC00 then
      return EncodingError.create("unexpected low surrogate area", _pos)
    end
    /* Check for a high surrogate area. */
    if (value and 0xFC00) == 0xD800 then
      /* Check for incomplete surrogate pair. */
      if (_data.size() - _pos) < 4 then
        if _data(_data.size() - 1) == 0 then
          return EncodingError.create("incomplete UTF-16 surrogate pair", _pos)
        end
        return _IncompleteEncoding
      end
      /* Get the next character. */
      let value2: U32 = _data(_pos + low + 2).u32() + (_data(_pos + high + 2).u32() << 8)
      /* Check for a low surrogate area. */
      if (value2 and 0xFC00) != 0xDC00 then
        return EncodingError.create("expected low surrogate area", _pos)
      end
      /* Generate the value of the surrogate pair. */
      value = 0x10000 + ((value and 0x3FF) << 10) + (value2 and 0x3FF)
      _pos = _pos + 4
    else
      _pos = _pos + 2
    end
    value

  fun ref _decodeUTF32(low: USize, low2: USize, high: USize, high2: USize): (U32 | EncodingError | _IncompleteEncoding) ? =>
    /* Check for incomplete UTF-32 character. */
    if (_data.size() - _pos) < 4 then
      if _data(_data.size() - 1) == 0 then
        return EncodingError.create("incomplete UTF-32 character", _pos)
      end
      return _IncompleteEncoding
    end
    let value: U32 = _data(_pos + low).u32() + (_data(_pos + low2).u32() << 8) + (_data(_pos + high).u32() << 16) + (_data(_pos + high2).u32() << 24)
    _pos = _pos + 4
    value
