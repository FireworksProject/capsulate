_ = require 'underscore'

_.mixin({
    isFullString: (a) -> return a and typeof a is 'string'

    hasProperty: (a, key) ->
        val = a[key]
        if val then return yes
        if typeof val isnt 'undefined' then return yes
        if Object::hasOwnProperty.call(a, key) then return yes
        if key in a then return yes
        return no
})

exports.proto = gProto = Object.create(null)

gProto.create = ->
    defs = @definitions
    rv = Object.keys(defs).reduce((rv, key) ->
        rv[key] = if _.hasProperty(defs[key], 'defaultValue')
            dval = defs[key].defaultValue
            if _.isFunction(dval) then dval()
            else dval
        else null
        return rv
    , Object.create(null))
    return rv

gProto.clean = (aObject) ->
    defs = @definitions
    rv = Object.keys(defs).reduce((rv, key) ->
        rv[key] = aObject[key]
        return rv
    , Object.create(null))
    return rv

gProto.coerce = (aObject) ->
    defs = @definitions
    rv = Object.keys(aObject).reduce((rv, key) ->
        value = aObject[key]
        coerce = defs[key].coerce
        if coerce then rv[key] = coerce(value)
        else rv[key] = value
        return rv
    , Object.create(null))
    return rv

gProto.validate = (aObject) ->
    errors = Object.create(null)
    defs = @definitions

    pushError = (key, err) ->
        if not errors[key] then errors[key] = []
        errors[key].push(err)
        return

    Object.keys(aObject).forEach (key) ->
        validators = defs[key].validators
        if not validators.length then return
        stringName = defs[key].name or key
        value = aObject[key]
        for validate in validators
            err = validate(value, key, stringName)
            if err then pushError(key, err)
        return

    if Object.keys(errors).length then return errors
    return null

gProto.extend = (aDefinitions) ->
    if not _.isObject(aDefinitions) or Array.isArray(aDefinitions)
        msg = "Definitions passed to .extend(aDefinitions) must be an Object."
        throw new Error(msg)

    return createModel(@, aDefinitions)


exports.create = (aDefinitions) ->
    if not _.isObject(aDefinitions) or Array.isArray(aDefinitions)
        msg = "Definitions passed to create(aDefinitions) must be an Object."
        throw new Error(msg)

    return createModel(gProto, aDefinitions)


createModel = do ->

    # Extend an object using Object.defineProperty().
    extend = (target, source) ->
        for own key, val of source
            if key isnt 'definitions'
                Object.defineProperty(target, key, {
                    enumerable: yes
                    value: val
                })
        return target

    create = (aParent, aChild) ->
        model = Object.create(null)
        # Only extend the methods of the parent object. The child object is
        # just a definition dictionary.
        model = extend(model, aParent)

        # Create and extend the definitions with the .definitions property of
        # the parent, the the child Object, which is the new definition
        # dictionary.
        definitions = extendDefinitions(aParent.definitions, aChild)
        Object.defineProperty(model, 'definitions', {
            value: Object.freeze(definitions)
        })

        # Freeze it to prevent accidental tampering.
        return Object.freeze(model)

    return create


extendDefinitions = do ->

    define = (definitions, key, val) ->
        try
            def = normalizeDefinition(val)
        catch message
            throw new Error("Definition error '#{key}': #{message}")

        Object.defineProperty(definitions, key, {
            enumerable: yes
            value: def
        })
        return definitions

    extend = (aParent, aChild) ->
        defs = Object.create(null)

        defs = Object.keys(aParent).reduce((defs, key) ->
            return define(defs, key, aParent[key])
        , Object.create(null))

        defs = Object.keys(aChild).reduce((defs, key) ->
            return define(defs, key, aChild[key])
        , defs)

        return defs

    return extend


normalizeDefinition = (aDef) ->
    aDef or= {}
    def = Object.create(null)

    name = aDef.name
    if name and not _.isString(name)
        throw "'name' definition must be a String."

    coerce = aDef.coerce
    if coerce and not _.isFunction(coerce)
        throw "'coerce' definition must be a Function."

    if _.hasProperty(aDef, 'defaultValue')
        if _.isFunction(aDef.defaultValue)
            defaultValue = aDef.defaultValue
        else
            defaultValue = -> return aDef.defaultValue
    else
        defaultValue = -> return null

    if _.isObject(defaultValue) then Object.freeze(defaultValue)

    validators = aDef.validators or []
    if validators and not Array.isArray(validators)
        throw "'validators' definition must be an Array."

    for fn in validators
        if not _.isFunction(fn)
            throw "'validators' Array must only contain functions."

    if name
        Object.defineProperty(def, 'name', {
            enumerable: yes
            value: name
        })

    if coerce
        Object.defineProperty(def, 'coerce', {
            enumerable: yes
            value: coerce
        })

    Object.defineProperty(def, 'defaultValue', {
        enumerable: yes
        value: defaultValue
    })

    Object.defineProperty(def, 'validators', {
        enumerable: yes
        value: Object.freeze(validators.slice())
    })

    return Object.freeze(def)
