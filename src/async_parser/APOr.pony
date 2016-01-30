
class APOr is GrammarElement
  let elements: Array[GrammarElement] val

  new val create(elements': Array[GrammarElement] val) =>
    elements = elements'

  fun createParser(state: ParserState, onResult: OnParseResult): TokenParser ? =>
    elements(0).createParser(state, _OrOnParseResult(state, elements, onResult))

class _OrOnParseResult is OnParseResult
  let parentOnResult: OnParseResult
  let elements: Array[GrammarElement] val
  var currentElement: USize = 0
  let initialState: ParserState

  new create(initialState': ParserState, elements': Array[GrammarElement] val, parentOnResult': OnParseResult) =>
    initialState = initialState'
    elements = elements'
    parentOnResult = parentOnResult'

  fun ref onResult(res: ParseResult): ParseResult ? =>
    if res.status is ParseSuccess then
      return parentOnResult.onResult(res)
    end
    currentElement = currentElement + 1
    if currentElement < elements.size() then
      let parser = elements(currentElement).createParser(initialState, this)
      return parser.acceptToken(res.state)
    end
    parentOnResult.onResult(res)
