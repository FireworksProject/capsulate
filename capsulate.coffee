INVPARAM = 'INVPARAM'
INVPROPDEF = 'INVPROPDEF'

_ = require 'underscore'

# Extend Underscore.
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

# Model is the prototype for all Object models.
exports.Model = Model = Object.create(null)

Model.create = ->
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

Model.clean = (aObject) ->
    defs = @definitions
    rv = Object.keys(defs).reduce((rv, key) ->
        rv[key] = aObject[key]
        return rv
    , Object.create(null))
    return rv

Model.coerce = (aObject) ->
    defs = @definitions
    rv = Object.keys(aObject).reduce((rv, key) ->
        value = aObject[key]
        coerce = defs[key].coerce
        if coerce then rv[key] = coerce(value)
        else rv[key] = value
        return rv
    , Object.create(null))
    return rv

Model.validate = (aObject) ->
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

# Public: Create a new Model Object by extending this object.
#
# aDefs - The dictionary Object of property definitions whose own enumerable
# properties are the descriptors for the properties managed by this Model.
#
# See the docs for ::create(aDefs) for more usage information.
#
# Returns a new Model Object which has been 'frozen' to prevent accidental
# tampering.
Model.extend = (aDefs) ->
    if not _.isObject(aDefs) or Array.isArray(aDefs)
        msg = "Definitions passed to .extend(aDefs) must be an Object."
        throwInvparam(new Error(msg))

    return createModel(@, aDefs)


# Public: Create a new Model Object.
#
# aDefs - The dictionary Object of property definitions whose own enumerable
# properties are the descriptors for the properties managed by this Model. Each
# property definition should take the following form:
#
# .name         - A friendly String name for the property mostly used in
#                 validation error messages.
# .defaultValue - The default value to use for this property when creating a
#                 new instance of the modeled Object.
# .validators   - An Array of validation functions that will each be called
#                 during the validation process.
# .coerce       - A type casting function that can modify the value of a
#                 property on the modeled object.
#
# The signature for the validation functions is:
#
# `function validator(value, key, name) { ... }`
#
# The 'value' is the value of the property, the key is the property key, and
# the name is the name given to the property in the property definition.
#
# The signature for the coerce function is:
#
# `function typecast(value) { return anotherValue; }`
#
# Returns a new Model Object which has been 'frozen' to prevent accidental
# tampering.
exports.create = (aDefs) ->
    if not _.isObject(aDefs) or Array.isArray(aDefs)
        msg = "Definitions passed to create(aDefs) must be an Object."
        throwInvparam(new Error(msg))

    return createModel(Model, aDefs)


# Private:
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
        parentDefs = if _.isObject(aParent.definitions) then aParent.definitions
        else Object.create(null)
        definitions = extendDefinitions(parentDefs, aChild)
        Object.defineProperty(model, 'definitions', {
            value: Object.freeze(definitions)
        })

        # Freeze it to prevent accidental tampering.
        return Object.freeze(model)

    return create


# Private:
extendDefinitions = do ->

    define = (definitions, key, val) ->
        try
            def = normalizeDefinition(val)
        catch message
            msg = "Definition error for property '#{key}': #{message}"
            throwInvpropdef(Error(msg))

        Object.defineProperty(definitions, key, {
            enumerable: yes
            value: def
        })
        return definitions

    extend = (aParent, aChild) ->
        container = Object.create(null)

        for own key, def of aParent
            container[key] = def

        for own key, def of aChild
            container[key] = def

        defs = Object.keys(container).reduce((defs, key) ->
            return define(defs, key, container[key])
        , Object.create(null))

        return defs

    return extend


# Private:
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
            throw "'validators' Array must only contain Functions."

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


# Private:
throwInvparam = (aError) ->
    aError.code = INVPARAM
    throw aError


# Private:
throwInvpropdef = (aError) ->
    aError.code = INVPROPDEF
    throw aError
