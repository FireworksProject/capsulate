TOOLS = require 'test-tools'
T = TOOLS.test

CAP = require '../dist/capsulate'


describe 'start', ->

    it 'should not be smoking', T (done) ->
        @assert(true, 'smoking')
        return done()

    return

