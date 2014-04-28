assert  = require "assert"
path    = require "path"
yajp    = require path.resolve("lib", "yajp")
fs      = require "fs"

describe "YAJP", ->
  describe "#Token", ->
    it "作れる", ->
      assert(yajp.TOKEN_TYPE_STRING)
      tok = yajp.Token("string", yajp.TOKEN_TYPE_STRING)
      assert.equal tok.val, "string"
      assert.equal tok.type, yajp.TOKEN_TYPE_STRING
  describe "#isSpace", ->
    it "空白を検知", ->
      assert yajp.isSpace " "
      assert yajp.isSpace "\t"
      assert yajp.isSpace "\n"
      assert yajp.isSpace "\r"
  describe "#isNumber", ->
    it "数字", ->
      assert yajp.isNumber i+"" for i in [0..9]
      assert.equal yajp.isNumber("f"), false
  describe "#isSymbol", ->
    it "シンボル", ->
      assert yajp.isSymbol s for s in yajp.symbols
      assert.equal yajp.isSymbol("~"), false
  describe "#isQuote", ->
    it "クォート", ->
      assert yajp.isQuote "'"
      assert yajp.isQuote '"'
      assert.equal yajp.isQuote("%"), false
  describe "#isNumberComponent", ->
    it "数値", ->
      assert yajp.isNumberComponent "-"
      assert yajp.isNumberComponent "2"
      assert yajp.isNumberComponent "."
      assert.equal yajp.isNumberComponent("+"), false
  describe "#parse", ->
    describe "数字のパース", ->
      it "できる", ->
        assert.equal yajp.parse("1"), 1
        assert.equal yajp.parse("1.5"), 1.5
        assert.equal yajp.parse("-100"), -100
    describe "文字のパース", ->
      it "できる", ->
        assert.equal yajp.parse('\"double quoted string\"'), "double quoted string"
        assert.equal yajp.parse("\'single quoted string\'"), "single quoted string"
    describe "真偽値のパース", ->
      it "できる", ->
        assert.equal yajp.parse("true"), true
        assert.equal yajp.parse("false"), false
    describe "nullのパース", ->
      it "できる", ->
        assert.equal yajp.parse("null"), null
    describe "配列のパース", ->
      it "できる", ->
        assert.deepEqual yajp.parse("[1,2,3]"), [1,2,3]
        assert.deepEqual yajp.parse('["hoge", true, 1, -10.0]'), ["hoge", true, 1, -10.0]
    describe "ネストされた配列", ->
      it "できる", ->
        assert.deepEqual yajp.parse("[1,[1,2,[1,2,3]]]"), [1,[1,2,[1,2,3]]]
    describe "オブジェクトのパース", ->
      it "できる", ->
        assert.deepEqual yajp.parse("{'key':'value','hoge':-1.0}"), {'key':'value','hoge':-1.0}
describe "test.json", ->
  it "パースできる", ->
    fs.readFile "test/test.json", (e, d) ->
      assert.equal e, undefined
      assert.ok d
      assert.deepEqual yajp.parse(d.toString()), JSON.parse(d.toString())