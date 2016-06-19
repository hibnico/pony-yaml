
class Option[T]
  var _value : (None | T)
  new none() => _value = None
  new create(v: T^) => _value = v
  fun ref set(v: T) => _value = consume v
  fun ref giveup(): T ? => (_value = None) as T^
  fun isNone(): Bool => _value is None
  fun value(): T ? => _value as T
  fun ref run(runner: {(T): T^}) => set(runner(giveup()))


class ScanError
  let problem: (None | String)
  let mark: YamlMark val
  let context: String

  new create(problem': (None | String), mark': YamlMark val, context': String) =>
    problem = problem'
    mark = mark'
    context = context'

primitive ScanDone
class ScanPaused
  let nextScanner: _Scanner
  new create(nextScanner': _Scanner) => nextScanner = nextScanner'

type _ScanResult is (ScanDone | ScanPaused | ScanError)

interface _Scanner
  fun ref apply(state: _ScannerState): _ScanResult ?

class _YamlSimpleKey
  /** Is a simple key possible? */
  var possible: Bool = false
  /** Is a simple key required? */
  var required: Bool = false
  /** The number of the token. */
  var token_number: USize = 0
  /** The position mark. */
  var mark: YamlMark = YamlMark.create()


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

  fun box clone(): YamlMark val =>
    recover val YamlMark.create(index, line, column) end
