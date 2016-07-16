/** Token types. */

trait val _YAMLToken is (Equatable[_YAMLToken] & Stringable)

/** An empty token. */
class val _YamlNoToken is _YAMLToken
  /** The beginning of the token. */
  let startMark: YamlMark val
  /** The end of the token. */
  let endMark: YamlMark val

  new val create(startMark': YamlMark val, endMark': YamlMark val) =>
    startMark = startMark'
    endMark = endMark'

  fun string(fmt: FormatSettings = FormatSettingsDefault): String iso^ =>
    let startIndex = startMark.index
    let endIndex = endMark.index
    recover
      let s: String ref = String.create()
      s.append("NoToken[")
      s.append(startIndex.string())
      s.append("..")
      s.append(endIndex.string())
      s.append("]")
      s
    end

  fun eq(that: _YAMLToken): Bool =>
    match that
    | let s : _YamlNoToken => (s.startMark == this.startMark) and (s.endMark == this.endMark)
    else
      false
    end


/** A STREAM-START token. */
class val _YamlStreamStartToken is _YAMLToken
  /** The beginning of the token. */
  let startMark: YamlMark val
  /** The end of the token. */
  let endMark: YamlMark val
  /** The stream encoding. */
  let encoding: String

  new val create(startMark': YamlMark val, endMark': YamlMark val, encoding': String) =>
    startMark = startMark'
    endMark = endMark'
    encoding = encoding'

  fun string(fmt: FormatSettings = FormatSettingsDefault): String iso^ =>
    let startIndex = startMark.index
    let endIndex = endMark.index
    let e = encoding
    recover
      let s: String ref = String.create()
      s.append("StreamStart[")
      s.append(startIndex.string())
      s.append("..")
      s.append(endIndex.string())
      s.append("] enc=")
      s.append(e)
      s
    end

  fun eq(that: _YAMLToken): Bool =>
    match that
    | let s : _YamlStreamStartToken => (s.startMark == this.startMark) and (s.endMark == this.endMark)
                                          and (s.encoding == this.encoding)
    else
      false
    end

/** A STREAM-END token. */
class val _YamlStreamEndToken is _YAMLToken
  /** The beginning of the token. */
  let startMark: YamlMark val
  /** The end of the token. */
  let endMark: YamlMark val

  new val create(startMark': YamlMark val, endMark': YamlMark val) =>
    startMark = startMark'
    endMark = endMark'

  fun string(fmt: FormatSettings = FormatSettingsDefault): String iso^ =>
    let startIndex = startMark.index
    let endIndex = endMark.index
    recover
      let s: String ref = String.create()
      s.append("StreamEnd[")
      s.append(startIndex.string())
      s.append("..")
      s.append(endIndex.string())
      s.append("]")
      s
    end

  fun eq(that: _YAMLToken): Bool =>
    match that
    | let s : _YamlStreamEndToken => (s.startMark == this.startMark) and (s.endMark == this.endMark)
    else
      false
    end


/** A VERSION-DIRECTIVE token. */
class val _YamlVersionDirectiveToken is _YAMLToken
  /** The beginning of the token. */
  let startMark: YamlMark val
  /** The end of the token. */
  let endMark: YamlMark val
  /** The major version number. */
  let major: U16
  /** The minor version number. */
  let minor: U16

  new val create(startMark': YamlMark val, endMark': YamlMark val, major': U16, minor': U16) =>
    startMark = startMark'
    endMark = endMark'
    major = major'
    minor = minor'

  fun string(fmt: FormatSettings = FormatSettingsDefault): String iso^ =>
    let startIndex = startMark.index
    let endIndex = endMark.index
    let maj = major
    let min = minor
    recover
      let s: String ref = String.create()
      s.append("VersionDirective[")
      s.append(startIndex.string())
      s.append("..")
      s.append(endIndex.string())
      s.append("] v=")
      s.append(maj.string())
      s.append(".")
      s.append(min.string())
      s
    end

  fun eq(that: _YAMLToken): Bool =>
    match that
    | let s : _YamlVersionDirectiveToken => (s.startMark == this.startMark) and (s.endMark == this.endMark)
                                              and (s.major == this.major) and (s.minor == this.minor)
    else
      false
    end


/** A TAG-DIRECTIVE token. */
class val _YamlTagDirectiveToken is _YAMLToken
  /** The beginning of the token. */
  let startMark: YamlMark val
  /** The end of the token. */
  let endMark: YamlMark val
  /** The tag handle. */
  let handle: String
  /** The tag prefix. */
  let prefix: String

  new val create(startMark': YamlMark val, endMark': YamlMark val, handle': String, prefix': String) =>
    startMark = startMark'
    endMark = endMark'
    handle = handle'
    prefix = prefix'

  fun string(fmt: FormatSettings = FormatSettingsDefault): String iso^ =>
    let startIndex = startMark.index
    let endIndex = endMark.index
    let h = handle
    let p = prefix
    recover
      let s: String ref = String.create()
      s.append("TagDirective[")
      s.append(startIndex.string())
      s.append("..")
      s.append(endIndex.string())
      s.append("] p=")
      s.append(p.string())
      s.append(" h=")
      s.append(h.string())
      s
    end

  fun eq(that: _YAMLToken): Bool =>
    match that
    | let s : _YamlTagDirectiveToken => (s.startMark == this.startMark) and (s.endMark == this.endMark)
                                          and (s.prefix == this.prefix) and (s.handle == this.handle)
    else
      false
    end


/** A DOCUMENT-START token. */
class val _YamlDocumentStartToken is _YAMLToken
  /** The beginning of the token. */
  let startMark: YamlMark val
  /** The end of the token. */
  let endMark: YamlMark val

  new val create(startMark': YamlMark val, endMark': YamlMark val) =>
    startMark = startMark'
    endMark = endMark'

  fun string(fmt: FormatSettings = FormatSettingsDefault): String iso^ =>
    let startIndex = startMark.index
    let endIndex = endMark.index
    recover
      let s: String ref = String.create()
      s.append("DocumentStart[")
      s.append(startIndex.string())
      s.append("..")
      s.append(endIndex.string())
      s.append("]")
      s
    end

  fun eq(that: _YAMLToken): Bool =>
    match that
    | let s : _YamlDocumentStartToken => (s.startMark == this.startMark) and (s.endMark == this.endMark)
    else
      false
    end


/** A DOCUMENT-END token. */
class val _YamlDocumentEndToken is _YAMLToken
  /** The beginning of the token. */
  let startMark: YamlMark val
  /** The end of the token. */
  let endMark: YamlMark val

  new val create(startMark': YamlMark val, endMark': YamlMark val) =>
    startMark = startMark'
    endMark = endMark'

  fun string(fmt: FormatSettings = FormatSettingsDefault): String iso^ =>
    let startIndex = startMark.index
    let endIndex = endMark.index
    recover
      let s: String ref = String.create()
      s.append("DocumentEnd[")
      s.append(startIndex.string())
      s.append("..")
      s.append(endIndex.string())
      s.append("]")
      s
    end

  fun eq(that: _YAMLToken): Bool =>
    match that
    | let s : _YamlDocumentEndToken => (s.startMark == this.startMark) and (s.endMark == this.endMark)
    else
      false
    end


/** A BLOCK-SEQUENCE-START token. */
class val _YamlBlockSequenceStartToken is _YAMLToken
  /** The beginning of the token. */
  let startMark: YamlMark val
  /** The end of the token. */
  let endMark: YamlMark val

  new val create(startMark': YamlMark val, endMark': YamlMark val) =>
    startMark = startMark'
    endMark = endMark'

  fun string(fmt: FormatSettings = FormatSettingsDefault): String iso^ =>
    let startIndex = startMark.index
    let endIndex = endMark.index
    recover
      let s: String ref = String.create()
      s.append("BlockSequenceStart[")
      s.append(startIndex.string())
      s.append("..")
      s.append(endIndex.string())
      s.append("]")
      s
    end

  fun eq(that: _YAMLToken): Bool =>
    match that
    | let s : _YamlBlockSequenceStartToken => (s.startMark == this.startMark) and (s.endMark == this.endMark)
    else
      false
    end


/** A BLOCK-SEQUENCE-END token. */
class val _YamlBlockMappingStartToken is _YAMLToken
  /** The beginning of the token. */
  let startMark: YamlMark val
  /** The end of the token. */
  let endMark: YamlMark val

  new val create(startMark': YamlMark val, endMark': YamlMark val) =>
    startMark = startMark'
    endMark = endMark'

  fun string(fmt: FormatSettings = FormatSettingsDefault): String iso^ =>
    let startIndex = startMark.index
    let endIndex = endMark.index
    recover
      let s: String ref = String.create()
      s.append("BlockMappingStart[")
      s.append(startIndex.string())
      s.append("..")
      s.append(endIndex.string())
      s.append("]")
      s
    end

  fun eq(that: _YAMLToken): Bool =>
    match that
    | let s : _YamlBlockMappingStartToken => (s.startMark == this.startMark) and (s.endMark == this.endMark)
    else
      false
    end


/** A BLOCK-END token. */
class val _YamlBlockEndToken is _YAMLToken
  /** The beginning of the token. */
  let startMark: YamlMark val
  /** The end of the token. */
  let endMark: YamlMark val

  new val create(startMark': YamlMark val, endMark': YamlMark val) =>
    startMark = startMark'
    endMark = endMark'

  fun string(fmt: FormatSettings = FormatSettingsDefault): String iso^ =>
    let startIndex = startMark.index
    let endIndex = endMark.index
    recover
      let s: String ref = String.create()
      s.append("BlockEnd[")
      s.append(startIndex.string())
      s.append("..")
      s.append(endIndex.string())
      s.append("]")
      s
    end

  fun eq(that: _YAMLToken): Bool =>
    match that
    | let s : _YamlBlockEndToken => (s.startMark == this.startMark) and (s.endMark == this.endMark)
    else
      false
    end


/** A FLOW-SEQUENCE-START token. */
class val _YamlFlowSequenceStartToken is _YAMLToken
  /** The beginning of the token. */
  let startMark: YamlMark val
  /** The end of the token. */
  let endMark: YamlMark val

  new val create(startMark': YamlMark val, endMark': YamlMark val) =>
    startMark = startMark'
    endMark = endMark'

  fun string(fmt: FormatSettings = FormatSettingsDefault): String iso^ =>
    let startIndex = startMark.index
    let endIndex = endMark.index
    recover
      let s: String ref = String.create()
      s.append("FlowSequenceStart[")
      s.append(startIndex.string())
      s.append("..")
      s.append(endIndex.string())
      s.append("]")
      s
    end

  fun eq(that: _YAMLToken): Bool =>
    match that
    | let s : _YamlFlowSequenceStartToken => (s.startMark == this.startMark) and (s.endMark == this.endMark)
    else
      false
    end


/** A FLOW-SEQUENCE-END token. */
class val _YamlFlowSequenceEndToken is _YAMLToken
  /** The beginning of the token. */
  let startMark: YamlMark val
  /** The end of the token. */
  let endMark: YamlMark val

  new val create(startMark': YamlMark val, endMark': YamlMark val) =>
    startMark = startMark'
    endMark = endMark'

  fun string(fmt: FormatSettings = FormatSettingsDefault): String iso^ =>
    let startIndex = startMark.index
    let endIndex = endMark.index
    recover
      let s: String ref = String.create()
      s.append("FlowSequenceEnd[")
      s.append(startIndex.string())
      s.append("..")
      s.append(endIndex.string())
      s.append("]")
      s
    end

  fun eq(that: _YAMLToken): Bool =>
    match that
    | let s : _YamlFlowSequenceEndToken => (s.startMark == this.startMark) and (s.endMark == this.endMark)
    else
      false
    end


/** A FLOW-MAPPING-START token. */
class val _YamlFlowMappingStartToken is _YAMLToken
  /** The beginning of the token. */
  let startMark: YamlMark val
  /** The end of the token. */
  let endMark: YamlMark val

  new val create(startMark': YamlMark val, endMark': YamlMark val) =>
    startMark = startMark'
    endMark = endMark'

  fun string(fmt: FormatSettings = FormatSettingsDefault): String iso^ =>
    let startIndex = startMark.index
    let endIndex = endMark.index
    recover
      let s: String ref = String.create()
      s.append("FlowMappingStart[")
      s.append(startIndex.string())
      s.append("..")
      s.append(endIndex.string())
      s.append("]")
      s
    end

  fun eq(that: _YAMLToken): Bool =>
    match that
    | let s : _YamlFlowMappingStartToken => (s.startMark == this.startMark) and (s.endMark == this.endMark)
    else
      false
    end


/** A FLOW-MAPPING-END token. */
class val _YamlFlowMappingEndToken is _YAMLToken
  /** The beginning of the token. */
  let startMark: YamlMark val
  /** The end of the token. */
  let endMark: YamlMark val

  new val create(startMark': YamlMark val, endMark': YamlMark val) =>
    startMark = startMark'
    endMark = endMark'

  fun string(fmt: FormatSettings = FormatSettingsDefault): String iso^ =>
    let startIndex = startMark.index
    let endIndex = endMark.index
    recover
      let s: String ref = String.create()
      s.append("FlowMappingEnd[")
      s.append(startIndex.string())
      s.append("..")
      s.append(endIndex.string())
      s.append("]")
      s
    end

  fun eq(that: _YAMLToken): Bool =>
    match that
    | let s : _YamlFlowMappingEndToken => (s.startMark == this.startMark) and (s.endMark == this.endMark)
    else
      false
    end


/** A BLOCK-ENTRY token. */
class val _YamlBlockEntryToken is _YAMLToken
  /** The beginning of the token. */
  let startMark: YamlMark val
  /** The end of the token. */
  let endMark: YamlMark val

  new val create(startMark': YamlMark val, endMark': YamlMark val) =>
    startMark = startMark'
    endMark = endMark'

  fun string(fmt: FormatSettings = FormatSettingsDefault): String iso^ =>
    let startIndex = startMark.index
    let endIndex = endMark.index
    recover
      let s: String ref = String.create()
      s.append("BlockEntry[")
      s.append(startIndex.string())
      s.append("..")
      s.append(endIndex.string())
      s.append("]")
      s
    end

  fun eq(that: _YAMLToken): Bool =>
    match that
    | let s : _YamlBlockEntryToken => (s.startMark == this.startMark) and (s.endMark == this.endMark)
    else
      false
    end


/** A FLOW-ENTRY token. */
class val _YamlFlowEntryToken is _YAMLToken
  /** The beginning of the token. */
  let startMark: YamlMark val
  /** The end of the token. */
  let endMark: YamlMark val

  new val create(startMark': YamlMark val, endMark': YamlMark val) =>
    startMark = startMark'
    endMark = endMark'

  fun string(fmt: FormatSettings = FormatSettingsDefault): String iso^ =>
    let startIndex = startMark.index
    let endIndex = endMark.index
    recover
      let s: String ref = String.create()
      s.append("FlowEntry[")
      s.append(startIndex.string())
      s.append("..")
      s.append(endIndex.string())
      s.append("]")
      s
    end

  fun eq(that: _YAMLToken): Bool =>
    match that
    | let s : _YamlFlowEntryToken => (s.startMark == this.startMark) and (s.endMark == this.endMark)
    else
      false
    end


/** A KEY token. */
class val _YamlKeyToken is _YAMLToken
  /** The beginning of the token. */
  let startMark: YamlMark val
  /** The end of the token. */
  let endMark: YamlMark val

  new val create(startMark': YamlMark val, endMark': YamlMark val) =>
    startMark = startMark'
    endMark = endMark'

  fun string(fmt: FormatSettings = FormatSettingsDefault): String iso^ =>
    let startIndex = startMark.index
    let endIndex = endMark.index
    recover
      let s: String ref = String.create()
      s.append("Key[")
      s.append(startIndex.string())
      s.append("..")
      s.append(endIndex.string())
      s.append("]")
      s
    end

  fun eq(that: _YAMLToken): Bool =>
    match that
    | let s : _YamlKeyToken => (s.startMark == this.startMark) and (s.endMark == this.endMark)
    else
      false
    end


/** A VALUE token. */
class val _YamlValueToken is _YAMLToken
  /** The beginning of the token. */
  let startMark: YamlMark val
  /** The end of the token. */
  let endMark: YamlMark val

  new val create(startMark': YamlMark val, endMark': YamlMark val) =>
    startMark = startMark'
    endMark = endMark'

  fun string(fmt: FormatSettings = FormatSettingsDefault): String iso^ =>
    let startIndex = startMark.index
    let endIndex = endMark.index
    recover
      let s: String ref = String.create()
      s.append("Value[")
      s.append(startIndex.string())
      s.append("..")
      s.append(endIndex.string())
      s.append("]")
      s
    end

  fun eq(that: _YAMLToken): Bool =>
    match that
    | let s : _YamlValueToken => (s.startMark == this.startMark) and (s.endMark == this.endMark)
    else
      false
    end


/** An ALIAS token. */
class val _YamlAliasToken is _YAMLToken
  /** The beginning of the token. */
  let startMark: YamlMark val
  /** The end of the token. */
  let endMark: YamlMark val
  /** The alias value. */
  let value: String

  new val create(startMark': YamlMark val, endMark': YamlMark val, value': String) =>
    startMark = startMark'
    endMark = endMark'
    value = value'

  fun string(fmt: FormatSettings = FormatSettingsDefault): String iso^ =>
    let startIndex = startMark.index
    let endIndex = endMark.index
    let v = value
    recover
      let s: String ref = String.create()
      s.append("Alias[")
      s.append(startIndex.string())
      s.append("..")
      s.append(endIndex.string())
      s.append("] v=")
      s.append(v)
      s
    end

  fun eq(that: _YAMLToken): Bool =>
    match that
    | let s : _YamlAliasToken => (s.startMark == this.startMark) and (s.endMark == this.endMark)
                                    and (s.value == this.value)
    else
      false
    end


/** An ANCHOR token. */
class val _YamlAnchorToken is _YAMLToken
  /** The beginning of the token. */
  let startMark: YamlMark val
  /** The end of the token. */
  let endMark: YamlMark val
  /** The anchor value. */
  let value: String

  new val create(startMark': YamlMark val, endMark': YamlMark val, value': String) =>
    startMark = startMark'
    endMark = endMark'
    value = value'

  fun string(fmt: FormatSettings = FormatSettingsDefault): String iso^ =>
    let startIndex = startMark.index
    let endIndex = endMark.index
    let v = value
    recover
      let s: String ref = String.create()
      s.append("Anchor[")
      s.append(startIndex.string())
      s.append("..")
      s.append(endIndex.string())
      s.append("] v=")
      s.append(v)
      s
    end

  fun eq(that: _YAMLToken): Bool =>
    match that
    | let s : _YamlAnchorToken => (s.startMark == this.startMark) and (s.endMark == this.endMark)
                                    and (s.value == this.value)
    else
      false
    end

/** A TAG token. */
class val _YamlTagToken is _YAMLToken
  /** The beginning of the token. */
  let startMark: YamlMark val
  /** The end of the token. */
  let endMark: YamlMark val
  /** The tag handle. */
  let handle: String
  /** The tag suffix. */
  let suffix: String

  new val create(startMark': YamlMark val, endMark': YamlMark val, handle': String, suffix': String) =>
    startMark = startMark'
    endMark = endMark'
    handle = handle'
    suffix = suffix'

  fun string(fmt: FormatSettings = FormatSettingsDefault): String iso^ =>
    let startIndex = startMark.index
    let endIndex = endMark.index
    let h = handle
    let suf = suffix
    recover
      let s: String ref = String.create()
      s.append("Tag[")
      s.append(startIndex.string())
      s.append("..")
      s.append(endIndex.string())
      s.append("] s=")
      s.append(suf)
      s.append(" h=")
      s.append(h)

      s
    end

  fun eq(that: _YAMLToken): Bool =>
    match that
    | let s : _YamlTagToken => (s.startMark == this.startMark) and (s.endMark == this.endMark)
                                          and (s.suffix == this.suffix) and (s.handle == this.handle)
    else
      false
    end


/** A SCALAR token. */
primitive _YamlFoldedScalarStyle
primitive _YamlLiteralScalarStyle
primitive _YamlDoubleQuotedScalarStyle
primitive _YamlSingleQuotedScalarStyle
primitive _YamlPlainScalarStyle
type _YamlScalarStyle is (_YamlFoldedScalarStyle | _YamlLiteralScalarStyle | _YamlDoubleQuotedScalarStyle | _YamlSingleQuotedScalarStyle | _YamlPlainScalarStyle)
class val _YamlScalarToken is _YAMLToken
  /** The beginning of the token. */
  let startMark: YamlMark val
  /** The end of the token. */
  let endMark: YamlMark val
  /** The scalar value. */
  let value: String
  /** The scalar style. */
  let style: _YamlScalarStyle

  new val create(startMark': YamlMark val, endMark': YamlMark val, value': String, style': _YamlScalarStyle) =>
    startMark = startMark'
    endMark = endMark'
    value = value'
    style = style'

  fun string(fmt: FormatSettings = FormatSettingsDefault): String iso^ =>
    let startIndex = startMark.index
    let endIndex = endMark.index
    recover
      let s: String ref = String.create()
      s.append("Scalar[")
      s.append(startIndex.string())
      s.append("..")
      s.append(endIndex.string())
      s.append("]")
      s
    end

  fun eq(that: _YAMLToken): Bool =>
    match that
    | let s : _YamlScalarToken => (s.startMark == this.startMark) and (s.endMark == this.endMark)
                                    and (s.style is this.style) and (s.value == this.value)
    else
      false
    end
