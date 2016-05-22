/** Token types. */

trait val _YamlTokenData

class _YAMLToken[TD: _YamlTokenData val]
  /** The beginning of the token. */
  let startMark: YamlMark val
  /** The end of the token. */
  let endMark: YamlMark val
  /** The token data. */
  let data: TD

  new val create(startMark': YamlMark val, endMark': YamlMark val, data': TD) =>
    startMark = startMark'
    endMark = endMark'
    data = data'

primitive _NoYamlTokenData is _YamlTokenData


/** An empty token. */
type _YamlNoToken is _YAMLToken[_NoYamlTokenData]


/** A STREAM-START token. */
class val _YamlStreamStartTokenData is _YamlTokenData
  /** The stream encoding. */
  let encoding: String
  new val create(encoding': String) =>
    encoding = encoding'
type _YamlStreamStartToken is _YAMLToken[_YamlStreamStartTokenData]


/** A STREAM-END token. */
type _YamlStreamEndToken is _YAMLToken[_NoYamlTokenData]


/** A VERSION-DIRECTIVE token. */
class val _YamlVersionDirectiveTokenData is _YamlTokenData
  /** The major version number. */
  let major: U16
  /** The minor version number. */
  let minor: U16
  new val create(major': U16, minor': U16) =>
    major = major'
    minor = minor'
type _YamlVersionDirectiveToken is _YAMLToken[_YamlVersionDirectiveTokenData]


/** A TAG-DIRECTIVE token. */
class val _YamlTagDirectiveTokenData is _YamlTokenData
  /** The tag handle. */
  let handle: String
  /** The tag prefix. */
  let prefix: String
  new val create(handle': String, prefix': String) =>
    handle = handle'
    prefix = prefix'
type _YamlTagDirectiveToken is _YAMLToken[_YamlTagDirectiveTokenData]


/** A DOCUMENT-START token. */
type _YamlDocumentStartToken is _YAMLToken[_NoYamlTokenData]


/** A DOCUMENT-END token. */
type _YamlDocumentEndToken is _YAMLToken[_NoYamlTokenData]


/** A BLOCK-SEQUENCE-START token. */
type _YamlBlockSequenceStartToken is _YAMLToken[_NoYamlTokenData]


/** A BLOCK-SEQUENCE-END token. */
type _YamlBlockMappingStartToken is _YAMLToken[_NoYamlTokenData]


/** A BLOCK-END token. */
type _YamlBlockEndToken is _YAMLToken[_NoYamlTokenData]


/** A FLOW-SEQUENCE-START token. */
type _YamlFlowSequenceStartToken is _YAMLToken[_NoYamlTokenData]


/** A FLOW-SEQUENCE-END token. */
type _YamlFlowSequenceEndToken is _YAMLToken[_NoYamlTokenData]


/** A FLOW-MAPPING-START token. */
type _YamlFlowMappingStartToken is _YAMLToken[_NoYamlTokenData]


/** A FLOW-MAPPING-END token. */
type _YamlFlowMappingEndToken is _YAMLToken[_NoYamlTokenData]


/** A BLOCK-ENTRY token. */
type _YamlBlockEntryToken is _YAMLToken[_NoYamlTokenData]


/** A FLOW-ENTRY token. */
type _YamlFlowEntryToken is _YAMLToken[_NoYamlTokenData]


/** A KEY token. */
type _YamlKeyToken is _YAMLToken[_NoYamlTokenData]


/** A VALUE token. */
type _YamlValueToken is _YAMLToken[_NoYamlTokenData]


/** An ALIAS token. */
class val _YamlAliasTokenData is _YamlTokenData
  /** The alias value. */
  let value: String
  new val create(value': String) =>
    value = value'
type _YamlAliasToken is _YAMLToken[_YamlAliasTokenData]


/** An ANCHOR token. */
class val _YamlAnchorTokenData is _YamlTokenData
  /** The anchor value. */
  let value: String
  new val create(value': String) =>
    value = value'
type _YamlAnchorToken is _YAMLToken[_YamlAnchorTokenData]


/** A TAG token. */
class val _YamlTagTokenData is _YamlTokenData
  /** The tag handle. */
  let handle: String
  /** The tag suffix. */
  let suffix: String
  new val create(handle': String, suffix': String) =>
    handle = handle'
    suffix = suffix'
type _YamlTagToken is _YAMLToken[_YamlTagTokenData]


/** A SCALAR token. */
primitive _YamlStyle1
type _YamlScalarStyle is (_YamlStyle1)
class val _YamlScalarTokenData is _YamlTokenData
  /** The scalar value. */
  let value: String
  /** The length of the scalar value. */
  let length: USize
  /** The scalar style. */
  let style: _YamlScalarStyle
  new val create(value': String, length': USize, style': _YamlScalarStyle) =>
    value = value'
    length = length'
    style = style'
type _YamlScalarToken is _YAMLToken[_YamlScalarTokenData]
