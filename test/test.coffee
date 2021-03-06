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

        @equal(typeof model.merge, 'function', 'model.merge')
        @assert(('merge' in keys), 'merge() is own, enumerable property')

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


    it 'should throw an Error if a merge definition is made but is not a Function', T (done) ->
        @expectCount(2)
        try
            CAP.create({
                foo:
                    merge: 'string'
            })
        catch err
            @equal(err.code, 'INVPROPDEF', 'Error.code')
            @equal(err.message, "Definition error for property 'foo': 'merge' definition must be a Function.", 'Error.message')

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

        @equal(typeof Person.merge, 'function', 'Person.merge')
        @assert(('merge' in keys), 'merge() is own, enumerable property')

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


    it 'should throw an Error if a merge definition is made but is not a Function', T (done) ->
        @expectCount(2)
        try
            BaseModel.extend({
                foo:
                    merge: 'string'
            })
        catch err
            @equal(err.code, 'INVPROPDEF', 'Error.code')
            @equal(err.message, "Definition error for property 'foo': 'merge' definition must be a Function.", 'Error.message')

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


describe 'Model.create()', ->

    it 'should create a new, pristine Object.', T (done) ->
        TwitterHandle = -> return 'twitter'

        M = CAP.create({
            firstName: {}
            lastName: {}
            address:
                coerce: (val) ->
                    if val and typeof val is 'object'
                        city = val.city or null
                        state = val.state or null
                        return {city: city, state: state}
                    return {city: null, state: null}

                defaultValue: (src) ->
                    return @coerce(src)
            tags:
                defaultValue: ['tennis', 'reading']
            twitterHandle:
                defaultValue: TwitterHandle
            age:
                defaultValue: 0
        })

        m = M.create()

        @equal(m.firstName, null, '.firstName')
        @equal(m.lastName, null, '.lastName')
        @equal(m.address.city, null, '.address.city')
        @equal(m.address.state, null, '.address.state')
        @equal(m.tags[0], 'tennis', 'address.tags[0]')
        @equal(m.tags[1], 'reading', 'address.tags[1]')
        @equal(m.twitterHandle, 'twitter', '.twitterHandle')
        @equal(m.age, 0, '.age')

        keys = Object.keys(m)
        @equal(keys.length, 6, 'Object.keys().length')
        @assert('firstName' in keys, 'firstName in keys')
        @assert('lastName' in keys, 'lastName in keys')
        @assert('address' in keys, 'address in keys')
        @assert('tags' in keys, 'tags in keys')
        @assert('twitterHandle' in keys, 'twitterHandle in keys')
        @assert('age' in keys, 'age in keys')
        return done()


    it 'should stand up to mutation', T (done) ->
        socialMedia =
            twitter: {id: '123', username: 'metoo'}
            facebook: {id: '456', username: 'metoo'}

        date =
            year: 2012
            month: 11

        def =
            fullName:
                defaultValue: ''
            address:
                defaultValue: {city: null, state: null}
            tags:
                defaultValue: ['tennis', 'reading']
            social:
                defaultValue: socialMedia
            dob:
                defaultValue: -> return date

        M = CAP.create(def)

        def.fullName.defaultValue = 'NA'
        m = M.create()
        @equal(m.fullName, '', '.fullName')

        def.address.defaultValue = {city: 'Boston', state: 'MA'}
        m = M.create()
        @equal(m.address.city, null, 'm.address.city')

        m.address.city = 'Cambridge'
        x = M.create()
        @equal(x.address.city, null, 'x.address.city')

        def.tags.defaultValue.push('skydiving')
        m = M.create()
        @equal(m.tags[2], undefined, 'm.tags[2]')

        m.tags[0] = 'skiing'
        x = M.create()
        @equal(x.tags[0], 'tennis', 'x.tags[0]')

        socialMedia.twitter.username = 'foo'
        m = M.create()
        @equal(m.social.twitter.username, 'metoo', 'm.social.twitter.username')

        m.social.facebook.username = 'bar'
        x = M.create()
        @equal(x.social.facebook.username, 'metoo', 'x.social.twitter.username')

        date.year = 1970
        m = M.create()
        # The only way to protect closures from mutation is for the user to
        # realize the danger.
        @equal(m.dob.year, 1970, 'm.dob.year')

        m.dob.month = 9
        x = M.create()
        # Another closure mutation problem.
        @equal(x.dob.month, 9, 'x.dob.month')

        return done()


    it 'should extend an object passed as the first parameter', T (done) ->

        M = CAP.create({
            fullName:
                defaultValue: ''
            address:
                defaultValue: (source) ->
                    rv = Object.create(null)

                    rv.city = if source.city and typeof source.city is 'string'
                        source.city
                    else null

                    rv.state = if source.state and typeof source.state is 'string'
                        source.state
                    else null

                    return rv
            tags:
                defaultValue: ['tennis', 'reading']
        })

        source =
            fullName: 0
            address: {state: 'NY'}
            age: 36

        m = M.create(source)

        @notStrictEqual(m, source, 'a new object is created')

        @strictEqual(m.fullName, 0, '.fullName')
        @equal(m.address.city, null, '.address.city')
        @equal(m.address.state, 'NY', '.address.state')
        @equal(m.tags[0], 'tennis', '.tags[0]')
        @equal(m.age, 36, '.age')

        return done()


    return


describe 'Model.clean()', ->

    it 'should create a new object with only the defined properties.', T (done) ->

        M = CAP.create({
            firstName:
                name: 'First Name'
            lastName:
                name: 'Last Name'
            address:
                name: 'Address'
                defaultValue: {city: null, state: null}
            tags:
                defaultValue: ['tennis', 'reading']
            age:
                defaultValue: 0
        })

        source =
            firstName: 'Foo'
            tags: ['blacksmithing']
            gender: 'male'

        m = M.clean(source)

        @notStrictEqual(m, source, 'a new object is created')

        @strictEqual(m.firstName, 'Foo', '.firstName')
        @equal(Object::hasOwnProperty.call(m, 'lastName'), false, '.lastName')
        @equal(Object::hasOwnProperty.call(m, 'address'), false, '.address')
        @strictEqual(m.tags.length, 1, 'm.tags.length')
        @strictEqual(m.tags[0], 'blacksmithing', 'm.tags[0]')
        @equal(Object::hasOwnProperty.call(m, 'age'), false, '.age')
        @equal(Object::hasOwnProperty.call(m, 'gender'), false, '.gender')
        return done()


    it 'expects an object or function to be passed as the single parameter', T (done) ->
        @expectCount(4)
        errMessage = "Model::clean(aObject) expects an Object as the single parameter."

        M = CAP.create({})

        # Functions are OK
        f = ->
        M.clean(f)

        # Arrays are OK
        M.clean([])
        
        try
            M.clean()
        catch e1
            @equal(e1.code, 'INVPARAM', 'Error.code')
            @equal(e1.message, errMessage, 'Error.message')
        
        try
            M.clean(null)
        catch e2
            @equal(e2.code, 'INVPARAM', 'Error.code')
            @equal(e2.message, errMessage, 'Error.message')
        return done()

    return


describe 'Model.coerce()', ->

    it 'should create a new object with coerceable values coerced.', T (done) ->

        M = CAP.create({
            firstName:
                name: 'First Name'
            lastName:
                name: 'Last Name'
            address:
                name: 'Address'
                defaultValue: {city: null, state: null}
                coerce: (val) ->
                    rv = @defaultValue()
                    if val and typeof val is 'object'
                        rv.city = val.city or null
                        rv.state = val.state or null
                    return rv
        })

        source =
            firstName: 'Foo'
            age: 32
            address: {city: 'Cambridge'}

        m = M.coerce(source)

        @notStrictEqual(m, source, 'a new object is created')
        @strictEqual(m.firstName, 'Foo', '.firstName')
        @equal(Object::hasOwnProperty.call(m, 'lastName'), false, '.lastName')
        @strictEqual(m.age, 32, '.age')
        @strictEqual(m.address.city, 'Cambridge', '.address.city')
        @strictEqual(m.address.state, null, '.address.state')
        return done()


    it 'expects an object or function to be passed as the single parameter', T (done) ->
        @expectCount(4)
        errMessage = "Model::coerce(aObject) expects an Object as the single parameter."

        M = CAP.create({})

        # Functions are OK
        f = ->
        M.coerce(f)

        # Arrays are OK
        M.coerce([])
        
        try
            M.coerce()
        catch e1
            @equal(e1.code, 'INVPARAM', 'Error.code')
            @equal(e1.message, errMessage, 'Error.message')
        
        try
            M.coerce(null)
        catch e2
            @equal(e2.code, 'INVPARAM', 'Error.code')
            @equal(e2.message, errMessage, 'Error.message')
        return done()

    return


describe 'Model.merge()', ->

    it 'should return a new object by merging the passed objects', T (done) ->

        M = CAP.create({
            firstName:
                name: 'First Name'
            lastName:
                name: 'Last Name'
            address:
                name: 'Address'

                coerce: (val) ->
                    if val and typeof val is 'object'
                        city = val.city or null
                        state = val.state or null
                        return {city: city, state: state}
                    return {city: null, state: null}

                merge: (existing, source) ->
                    if Object(existing) isnt existing
                        existing = Object.create(null)
                    source = @coerce(source)
                    existing.city = source.city or existing.city or null
                    existing.state = source.state or existing.state or null
                    return existing
        })

        existing =
            firstName: 'Foo'
            address: {street: '10 Main', city: 'Cambridge'}

        source =
            firstName: 'John'
            lastName: 'Doe'
            address: {city: 'Somerville', state: 'MA'}

        m = M.merge(existing, source)

        @strictEqual(Object.keys(m).length, 3, 'Object.keys()')
        @equal(m.firstName, 'John', '.firstName')
        @equal(m.lastName, 'Doe', '.lastName')
        @equal(m.address.street, '10 Main', '.address.street')
        @equal(m.address.city, 'Somerville', '.address.city')
        @equal(m.address.state, 'MA', '.address.state')
        return done()

    return


describe 'Model.validate()', ->

    it 'should return an errors object if there are any validation errors', T (done) ->
        validateExists = (val, key, name) ->
            if typeof val is 'undefined' or val is null
                return "The '#{name}' property is required."
            return

        validateString = (val, key, name) ->
            if not val or typeof val isnt 'string'
                return "The '#{name}' property must be a String."
            return

        validateObject = (val, key, name) ->
            if Object(val) isnt val
                return "The '#{name}' property must be an Object."
            return

        M = CAP.create({
            firstName:
                name: 'First Name'
                validators: [validateExists, validateString]
            lastName:
                name: 'Last Name'
                validators: [validateExists, validateString]
            address:
                name: 'Address'
                validators: [validateExists, validateObject]
        })

        source =
            firstName: 32
            age: 32
            address: 'Cambridge'

        errors = M.validate(source)

        @equal(errors.firstName[0], "The 'First Name' property must be a String.", '.firstName[0]')

        @equal(errors.lastName[0], "The 'Last Name' property is required.", '.lastName[0]')
        @equal(errors.lastName[1], "The 'Last Name' property must be a String.", '.lastName[1]')

        @equal(errors.address[0], "The 'Address' property must be an Object.", '.address[0]')

        return done()

    return
