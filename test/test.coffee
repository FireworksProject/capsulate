TOOLS = require 'test-tools'
T = TOOLS.test

CAP = require '../dist/capsulate'


describe '::create()', ->

    it 'should return a special Model instance', T (done) ->
        model = CAP.create({
            firstName:
                defaultValue: null
                coerce: String
            lastName:
                defaultValue: null
                coerce: String
        })

        @equal(model.prototype, null, 'prototype is null')
        @assert(Object.isFrozen(model), 'is frozen')

        # keys are own, enumerable properties
        keys = Object.keys(model)

        @equal(typeof model.create, 'function', 'model.create()')
        @assert(('create' in keys), 'create() is own, enumerable property')

        @equal(typeof model.clean, 'function', 'model.clean')
        @assert(('clean' in keys), 'clean() is own, enumerable property')

        @equal(typeof model.coerce, 'function', 'model.coerce')
        @assert(('coerce' in keys), 'coerce() is own, enumerable property')

        @equal(typeof model.validate, 'function', 'model.validate')
        @assert(('validate' in keys), 'validate() is own, enumerable property')

        @equal(typeof model.extend, 'function', 'model.extend')
        @assert(('extend' in keys), 'extend() is own, enumerable property')

        @equal(typeof model.definitions, 'object', 'model.definitions')
        @strictEqual(('definitions' in keys), false, 'definitions isnt own, enumerable property')
        @assert(Object.isFrozen(model.definitions), 'definitions are frozen')

        @assert(Object.isFrozen(model.definitions.firstName), 'model.definitions.firstName')
        @assert(Object.isFrozen(model.definitions.lastName), 'model.definitions.lastName')
        return done()


    it 'should throw an Error if aDefs is not an object', T (done) ->
        @expectCount(2)
        try
            CAP.create()
        catch err
            @equal(err.code, 'INVPARAM', 'Error.code')
            @equal(err.message, 'Definitions passed to create(aDefs) must be an Object.', 'Error.message')

        return done()


    it 'should throw an Error if a name defintion is made but is not a String', T (done) ->
        @expectCount(2)
        try
            CAP.create({
                foo:
                    name: true
            })
        catch err
            @equal(err.code, 'INVPROPDEF', 'Error.code')
            @equal(err.message, "Definition error for property 'foo': 'name' definition must be a String.", 'Error.message')

        return done()


    it 'should throw an Error if a coerce definition is made but is not a Function', T (done) ->
        @expectCount(2)
        try
            CAP.create({
                foo:
                    coerce: 'string'
            })
        catch err
            @equal(err.code, 'INVPROPDEF', 'Error.code')
            @equal(err.message, "Definition error for property 'foo': 'coerce' definition must be a Function.", 'Error.message')

        return done()


    it 'should throw an Error if a validators definition is made but is not an Array of Functions', T (done) ->
        @expectCount(4)

        try
            CAP.create({
                foo:
                    validators: -> return null
            })
        catch err
            @equal(err.code, 'INVPROPDEF', 'Error.code')
            @equal(err.message, "Definition error for property 'foo': 'validators' definition must be an Array.", 'Error.message')

        try
            CAP.create({
                foo:
                    validators: ['required']
            })
        catch err
            @equal(err.code, 'INVPROPDEF', 'Error.code')
            @equal(err.message, "Definition error for property 'foo': 'validators' Array must only contain Functions.", 'Error.message')

        return done()


    return


describe 'Model.extend()', ->

    BaseModel = CAP.create({
        $model:
            defaultValue: 'BaseModel'
            coerce: -> return @defaultValue
        $created:
            defaultValue: -> return new Date().getTime()
    })

    it 'should return a special Model instance with inherited property definitions', T (done) ->
        Person = BaseModel.extend({
            $model:
                defaultValue: 'Person'
                coerce: -> return @defaultValue
            firstName:
                defaultValue: null
                coerce: String
            lastName:
                defaultValue: null
                coerce: String
        })

        @equal(Person.prototype, null, 'prototype is null')
        @assert(Object.isFrozen(Person), 'is frozen')

        # keys are own, enumerable properties
        keys = Object.keys(Person)

        @equal(typeof Person.create, 'function', 'Person.create()')
        @assert(('create' in keys), 'create() is own, enumerable property')

        @equal(typeof Person.clean, 'function', 'Person.clean')
        @assert(('clean' in keys), 'clean() is own, enumerable property')

        @equal(typeof Person.coerce, 'function', 'Person.coerce')
        @assert(('coerce' in keys), 'coerce() is own, enumerable property')

        @equal(typeof Person.validate, 'function', 'Person.validate')
        @assert(('validate' in keys), 'validate() is own, enumerable property')

        @equal(typeof Person.extend, 'function', 'Person.extend')
        @assert(('extend' in keys), 'extend() is own, enumerable property')

        @equal(typeof Person.definitions, 'object', 'Person.definitions')
        @strictEqual(('definitions' in keys), false, 'definitions isnt own, enumerable property')
        @assert(Object.isFrozen(Person.definitions), 'definitions are frozen')

        # Definitions are inherited.
        @assert(Object.isFrozen(Person.definitions.$model), 'model.definitions.$model')
        @assert(Object.isFrozen(Person.definitions.$created), 'model.definitions.$created')
        @assert(Object.isFrozen(Person.definitions.firstName), 'model.definitions.firstName')
        @assert(Object.isFrozen(Person.definitions.lastName), 'model.definitions.lastName')

        # Check overridden .$model property
        defaultValue = Person.definitions.$model.defaultValue()
        @equal(defaultValue, 'Person', '$model.defaultValue')
        return done()


    it 'should throw an Error if aDefs is not an object', T (done) ->
        @expectCount(2)
        try
            BaseModel.extend()
        catch err
            @equal(err.code, 'INVPARAM', 'Error.code')
            @equal(err.message, 'Definitions passed to .extend(aDefs) must be an Object.', 'Error.message')

        return done()


    it 'should throw an Error if a name defintion is made but is not a String', T (done) ->
        @expectCount(2)
        try
            BaseModel.extend({
                foo:
                    name: true
            })
        catch err
            @equal(err.code, 'INVPROPDEF', 'Error.code')
            @equal(err.message, "Definition error for property 'foo': 'name' definition must be a String.", 'Error.message')

        return done()


    it 'should throw an Error if a coerce definition is made but is not a Function', T (done) ->
        @expectCount(2)
        try
            BaseModel.extend({
                foo:
                    coerce: 'string'
            })
        catch err
            @equal(err.code, 'INVPROPDEF', 'Error.code')
            @equal(err.message, "Definition error for property 'foo': 'coerce' definition must be a Function.", 'Error.message')

        return done()


    it 'should throw an Error if a validators definition is made but is not an Array of Functions', T (done) ->
        @expectCount(4)

        try
            BaseModel.extend({
                foo:
                    validators: -> return null
            })
        catch err
            @equal(err.code, 'INVPROPDEF', 'Error.code')
            @equal(err.message, "Definition error for property 'foo': 'validators' definition must be an Array.", 'Error.message')

        try
            BaseModel.extend({
                foo:
                    validators: ['required']
            })
        catch err
            @equal(err.code, 'INVPROPDEF', 'Error.code')
            @equal(err.message, "Definition error for property 'foo': 'validators' Array must only contain Functions.", 'Error.message')

        return done()


    return
