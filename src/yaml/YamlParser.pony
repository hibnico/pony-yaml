
actor YamlParser
  let _reader: _Reader

  new create(tokenEmitter: YamlTokenEmitter) =>
    _reader = _Reader.create(_ScannerActor.create(tokenEmitter))

  be read(data: Array[U8] val) =>
    _reader.read(data)
