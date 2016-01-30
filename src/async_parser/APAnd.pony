
class APAnd is GrammarElement
  let elements: Array[GrammarElement] val

  new val create(elements': Array[GrammarElement] val) =>
    elements = elements'

  fun createParser(state: ParserState, onResult: OnParseResult): TokenParser ? =>
    elements(0).createParser(state, _AndOnParseResult(elements, onResult))

class _AndOnParseResult is OnParseResult
  let parentOnResult: OnParseResult
  let elements: Array[GrammarElement] val
  var currentElement: USize = 0

  new create(elements': Array[GrammarElement] val, parentOnResult': OnParseResult) =>
    elements = elements'
    parentOnResult = parentOnResult'

  fun ref onResult(res: ParseResult): ParseResult ? =>
    if res.status is ParseFailed then
      return parentOnResult.onResult(res)
    end
    currentElement = currentElement + 1
    if currentElement < elements.size() then
      let parser = elements(currentElement).createParser(res.state, this)
      return ParseResult.cont(res.state, parser)
    end
    parentOnResult.onResult(ParseResult.success(res.state))
