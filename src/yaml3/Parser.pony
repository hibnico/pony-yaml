
actor Parser
  let _reader: _Reader

  new create(tokenEmitter: TokenEmitter) =>
    _reader = _Reader.create(_ScannerActor.create(tokenEmitter))

  be read(data: Array[U8] val) =>
    _reader.read(data)
