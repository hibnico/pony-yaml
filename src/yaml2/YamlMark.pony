
class YamlMark
  /** The position index. */
  var index: USize
  /** The position line. */
  var line: USize
  /** The position column. */
  var column: USize

  new create(index': USize = 0, line': USize = 0, column': USize = 0) =>
    index = index'
    line = line'
    column = column'

  fun clone(): YamlMark val =>
    recover val YamlMark.create(index, line, column) end
