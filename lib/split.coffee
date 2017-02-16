fs = require 'fs'
path = require 'path'

binarySplit = require 'binary-split'
map = require 'through2'
mkdirp = require 'mkdirp'
pump = require 'pump'
{ArgumentParser} = require 'argparse'

packageInfo = require '../package'

argparser = new ArgumentParser(
  addHelp: true
  description: 'Read JSON from STDIN, split by key and output to directory'
  version: packageInfo.version
)
argparser.addArgument(['key'],
  help: 'Key that determines where to output JSON'
  metavar: 'KEY'
  type: 'string'
)
argparser.addArgument(['directory'],
  defaultValue: './'
  help: 'Location to output JSON files, defaults to ./'
  metavar: 'DIRECTORY'
  nargs: '?'
  type: 'string'
)
argparser.addArgument(
  ['--omit-key']
  action: 'storeTrue'
  defaultValue: false
  dest: 'omitKey'
  help: 'Remove the KEY field from records before writing.'
)
argv = argparser.parseArgs()

splitStream = (key, directory, omitKey) ->
  map(objectMode: true, (obj, enc, cb) ->
    obj = JSON.parse obj.toString()
    if typeof obj[key] isnt 'string'
      console.error("Record missing KEY ('#{key}'): #{JSON.stringify(obj)}")
      cb()
    destination = path.join(directory, obj[key] + '.json')
    if omitKey then delete obj[key]
    mkdirp(path.dirname(destination), (err) ->
      if err
        cb(err)
      else
        fs.appendFile(destination, JSON.stringify(obj) + '\n', cb)
    )
  )

pump(
  process.stdin
  binarySplit()
  splitStream(argv.key, argv.directory, argv.omitKey)
  (err) -> if err? then console.error(err)
)
