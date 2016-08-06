/** Token types. */

trait val YamlToken is (Equatable[YamlToken] & Stringable)

/** An empty token. */
class val YamlNoToken is YamlToken
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

  fun eq(that: YamlToken): Bool =>
    match that
    | let s : YamlNoToken => (s.startMark == this.startMark) and (s.endMark == this.endMark)
    else
      false
    end


/** A STREAM-START token. */
class val YamlStreamStartToken is YamlToken
  /** The beginning of the token. */
  let startMark: YamlMark val
  /** The end of the token. */
  let endMark: YamlMark val
  /** The stream encoding. */
  let encoding: Encoding

  new val create(startMark': YamlMark val, endMark': YamlMark val, encoding': Encoding) =>
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
      s.append(e.string())
      s
    end

  fun eq(that: YamlToken): Bool =>
    match that
    | let s : YamlStreamStartToken => (s.startMark == this.startMark) and (s.endMark == this.endMark)
                                          and (s.encoding is this.encoding)
    else
      false
    end

/** A STREAM-END token. */
class val YamlStreamEndToken is YamlToken
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

  fun eq(that: YamlToken): Bool =>
    match that
    | let s : YamlStreamEndToken => (s.startMark == this.startMark) and (s.endMark == this.endMark)
    else
      false
    end


/** A VERSION-DIRECTIVE token. */
class val YamlVersionDirectiveToken is YamlToken
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

  fun eq(that: YamlToken): Bool =>
    match that
    | let s : YamlVersionDirectiveToken => (s.startMark == this.startMark) and (s.endMark == this.endMark)
                                              and (s.major == this.major) and (s.minor == this.minor)
    else
      false
    end


/** A TAG-DIRECTIVE token. */
class val YamlTagDirectiveToken is YamlToken
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

  fun eq(that: YamlToken): Bool =>
    match that
    | let s : YamlTagDirectiveToken => (s.startMark == this.startMark) and (s.endMark == this.endMark)
                                          and (s.prefix == this.prefix) and (s.handle == this.handle)
    else
      false
    end


/** A DOCUMENT-START token. */
class val YamlDocumentStartToken is YamlToken
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

  fun eq(that: YamlToken): Bool =>
    match that
    | let s : YamlDocumentStartToken => (s.startMark == this.startMark) and (s.endMark == this.endMark)
    else
      false
    end


/** A DOCUMENT-END token. */
class val YamlDocumentEndToken is YamlToken
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

  fun eq(that: YamlToken): Bool =>
    match that
    | let s : YamlDocumentEndToken => (s.startMark == this.startMark) and (s.endMark == this.endMark)
    else
      false
    end


/** A BLOCK-SEQUENCE-START token. */
class val YamlBlockSequenceStartToken is YamlToken
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

  fun eq(that: YamlToken): Bool =>
    match that
    | let s : YamlBlockSequenceStartToken => (s.startMark == this.startMark) and (s.endMark == this.endMark)
    else
      false
    end


/** A BLOCK-SEQUENCE-END token. */
class val YamlBlockMappingStartToken is YamlToken
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

  fun eq(that: YamlToken): Bool =>
    match that
    | let s : YamlBlockMappingStartToken => (s.startMark == this.startMark) and (s.endMark == this.endMark)
    else
      false
    end


/** A BLOCK-END token. */
class val YamlBlockEndToken is YamlToken
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

  fun eq(that: YamlToken): Bool =>
    match that
    | let s : YamlBlockEndToken => (s.startMark == this.startMark) and (s.endMark == this.endMark)
    else
      false
    end


/** A FLOW-SEQUENCE-START token. */
class val YamlFlowSequenceStartToken is YamlToken
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

  fun eq(that: YamlToken): Bool =>
    match that
    | let s : YamlFlowSequenceStartToken => (s.startMark == this.startMark) and (s.endMark == this.endMark)
    else
      false
    end


/** A FLOW-SEQUENCE-END token. */
class val YamlFlowSequenceEndToken is YamlToken
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

  fun eq(that: YamlToken): Bool =>
    match that
    | let s : YamlFlowSequenceEndToken => (s.startMark == this.startMark) and (s.endMark == this.endMark)
    else
      false
    end


/** A FLOW-MAPPING-START token. */
class val YamlFlowMappingStartToken is YamlToken
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

  fun eq(that: YamlToken): Bool =>
    match that
    | let s : YamlFlowMappingStartToken => (s.startMark == this.startMark) and (s.endMark == this.endMark)
    else
      false
    end


/** A FLOW-MAPPING-END token. */
class val YamlFlowMappingEndToken is YamlToken
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

  fun eq(that: YamlToken): Bool =>
    match that
    | let s : YamlFlowMappingEndToken => (s.startMark == this.startMark) and (s.endMark == this.endMark)
    else
      false
    end


/** A BLOCK-ENTRY token. */
class val YamlBlockEntryToken is YamlToken
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

  fun eq(that: YamlToken): Bool =>
    match that
    | let s : YamlBlockEntryToken => (s.startMark == this.startMark) and (s.endMark == this.endMark)
    else
      false
    end


/** A FLOW-ENTRY token. */
class val YamlFlowEntryToken is YamlToken
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

  fun eq(that: YamlToken): Bool =>
    match that
    | let s : YamlFlowEntryToken => (s.startMark == this.startMark) and (s.endMark == this.endMark)
    else
      false
    end


/** A KEY token. */
class val YamlKeyToken is YamlToken
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

  fun eq(that: YamlToken): Bool =>
    match that
    | let s : YamlKeyToken => (s.startMark == this.startMark) and (s.endMark == this.endMark)
    else
      false
    end


/** A VALUE token. */
class val YamlValueToken is YamlToken
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

  fun eq(that: YamlToken): Bool =>
    match that
    | let s : YamlValueToken => (s.startMark == this.startMark) and (s.endMark == this.endMark)
    else
      false
    end


/** An ALIAS token. */
class val YamlAliasToken is YamlToken
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

  fun eq(that: YamlToken): Bool =>
    match that
    | let s : YamlAliasToken => (s.startMark == this.startMark) and (s.endMark == this.endMark)
                                    and (s.value == this.value)
    else
      false
    end


/** An ANCHOR token. */
class val YamlAnchorToken is YamlToken
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

  fun eq(that: YamlToken): Bool =>
    match that
    | let s : YamlAnchorToken => (s.startMark == this.startMark) and (s.endMark == this.endMark)
                                    and (s.value == this.value)
    else
      false
    end

/** A TAG token. */
class val YamlTagToken is YamlToken
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

  fun eq(that: YamlToken): Bool =>
    match that
    | let s : YamlTagToken => (s.startMark == this.startMark) and (s.endMark == this.endMark)
                                          and (s.suffix == this.suffix) and (s.handle == this.handle)
    else
      false
    end


/** A SCALAR token. */
primitive YamlFoldedScalarStyle
primitive YamlLiteralScalarStyle
primitive YamlDoubleQuotedScalarStyle
primitive YamlSingleQuotedScalarStyle
primitive YamlPlainScalarStyle
type YamlScalarStyle is (YamlFoldedScalarStyle | YamlLiteralScalarStyle | YamlDoubleQuotedScalarStyle | YamlSingleQuotedScalarStyle | YamlPlainScalarStyle)
class val YamlScalarToken is YamlToken
  /** The beginning of the token. */
  let startMark: YamlMark val
  /** The end of the token. */
  let endMark: YamlMark val
  /** The scalar value. */
  let value: String
  /** The scalar style. */
  let style: YamlScalarStyle

  new val create(startMark': YamlMark val, endMark': YamlMark val, value': String, style': YamlScalarStyle) =>
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

  fun eq(that: YamlToken): Bool =>
    match that
    | let s : YamlScalarToken => (s.startMark == this.startMark) and (s.endMark == this.endMark)
                                    and (s.style is this.style) and (s.value == this.value)
    else
      false
    end
