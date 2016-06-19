/** Token types. */

trait val _YAMLToken

class _SimpleYAMLToken is _YAMLToken
  /** The beginning of the token. */
  let startMark: YamlMark val
  /** The end of the token. */
  let endMark: YamlMark val

  new val create(startMark': YamlMark val, endMark': YamlMark val) =>
    startMark = startMark'
    endMark = endMark'


/** An empty token. */
type _YamlNoToken is _SimpleYAMLToken


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


/** A STREAM-END token. */
type _YamlStreamEndToken is _SimpleYAMLToken


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


/** A DOCUMENT-START token. */
type _YamlDocumentStartToken is _SimpleYAMLToken


/** A DOCUMENT-END token. */
type _YamlDocumentEndToken is _SimpleYAMLToken


/** A BLOCK-SEQUENCE-START token. */
type _YamlBlockSequenceStartToken is _SimpleYAMLToken


/** A BLOCK-SEQUENCE-END token. */
type _YamlBlockMappingStartToken is _SimpleYAMLToken


/** A BLOCK-END token. */
type _YamlBlockEndToken is _SimpleYAMLToken


/** A FLOW-SEQUENCE-START token. */
type _YamlFlowSequenceStartToken is _SimpleYAMLToken


/** A FLOW-SEQUENCE-END token. */
type _YamlFlowSequenceEndToken is _SimpleYAMLToken


/** A FLOW-MAPPING-START token. */
type _YamlFlowMappingStartToken is _SimpleYAMLToken


/** A FLOW-MAPPING-END token. */
type _YamlFlowMappingEndToken is _SimpleYAMLToken


/** A BLOCK-ENTRY token. */
type _YamlBlockEntryToken is _SimpleYAMLToken


/** A FLOW-ENTRY token. */
type _YamlFlowEntryToken is _SimpleYAMLToken


/** A KEY token. */
type _YamlKeyToken is _SimpleYAMLToken


/** A VALUE token. */
type _YamlValueToken is _SimpleYAMLToken


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
