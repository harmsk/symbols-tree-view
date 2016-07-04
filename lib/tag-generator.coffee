{BufferedProcess, Point} = require 'atom'
Q = require 'q'
path = require 'path'
Ctags = require 'universal-ctags'

module.exports =
  class TagGenerator
    constructor: (@path, @scopeName) ->

    parseTagLine: (line) ->
      sections = line.split('\t')
      if sections.length > 3
        tag = {
          position: new Point(parseInt(sections[2]) - 1)
          name: sections[0]
          type: sections[3]
          parent: null
        }
        if sections.length > 4 and sections[4].search('signature:') == -1
          tag.parent = sections[4]
        if @getLanguage() == 'Python' and tag.type == 'member'
          tag.type = 'function'
        return tag
      else
        return null

    getLanguage: ->
      return 'Cson' if path.extname(@path) in ['.cson', '.gyp']

      {
        'source.c'              : 'C'
        'source.cpp'            : 'C++'
        'source.clojure'        : 'Lisp'
        'source.coffee'         : 'CoffeeScript'
        'source.css'            : 'Css'
        'source.css.less'       : 'Css'
        'source.css.scss'       : 'Css'
        'source.gfm'            : 'Markdown'
        'source.go'             : 'Go'
        'source.java'           : 'Java'
        'source.js'             : 'JavaScript'
        'source.js.jsx'         : 'JavaScript'
        'source.jsx'            : 'JavaScript'
        'source.json'           : 'Json'
        'source.makefile'       : 'Make'
        'source.objc'           : 'C'
        'source.objcpp'         : 'C++'
        'source.python'         : 'Python'
        'source.ruby'           : 'Ruby'
        'source.sass'           : 'Sass'
        'source.yaml'           : 'Yaml'
        'text.html'             : 'Html'
        'text.html.php'         : 'Php'
        'source.livecodescript' : 'LiveCode'

        # For backward-compatibility with Atom versions < 0.166
        'source.c++'            : 'C++'
        'source.objc++'         : 'C++'
      }[@scopeName]

    generate: ->
      deferred = Q.defer()
      tags = []
      defaultCtagsFile = require.resolve('./.ctags')
      args = ["--options=#{defaultCtagsFile}", '--fields=KsS']

      if atom.config.get('symbols-view.useEditorGrammarAsCtagsLanguage')
        if language = @getLanguage()
          args.push("--language-force=#{language}")

      args.push('-nf', '-', @path)

      result = Ctags.ctags(args)
      stdout = result['outputStream']
      if stdout
        for line in stdout.split('\n')
          if tag = @parseTagLine(line.trim())
            tags.push(tag)
      deferred.resolve(tags)

      deferred.promise
