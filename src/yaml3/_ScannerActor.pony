actor _ScannerActor
  let _state: _ScannerState

  new create(tokenEmitter: TokenEmitter) =>
    _state = _ScannerState.create(tokenEmitter)

  be setEncoding(encoding: Encoding) =>
    _state.setEncoding(encoding)

  be read(codePoints: Array[U32] val) =>
    try
      _state.append(codePoints)
      _state.run()
    end
