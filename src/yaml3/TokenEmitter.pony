
interface tag TokenEmitter
  be emit(token: _YAMLToken)

actor TokenCollector is TokenEmitter
  let tokens: Array[_YAMLToken] = Array[_YAMLToken].create()
  be emit(token: _YAMLToken) =>
    tokens.push(token)
