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


# Public: Create a new Object using the default property values defined by the
# Model.
#
# aSource - The source Object to get properties from
#           (default: Object.create(null)).
#
# Properties will be defined on the new Object according to the defaultValue
# given in the Model definition for each property if the property is not an own
# property of aSource.
#
# Returns a new Object with own, enumerable properties defined from aSource and
# the default property values of the Model.
Model.create = (aSource) ->
    source = if aSource and _.isObject(aSource)
        Object.keys(aSource).reduce((source, key) ->
            return defineProp(source, key, aSource[key])
        , Object.create(null))
    else Object.create(null)

    defs = @definitions
    rv = Object.keys(defs).reduce((rv, key) ->
        if not _.hasProperty(rv, key)
            defineProp(rv, key, defs[key].defaultValue(source[key]))
        return rv
    , source)
    return rv


# Public: Create an Object which only contains the properties which are defined
# by this Model.
#
# aObject - The source Object.
#
# Returns a new Object with own, enumerable properties defined from aSource.
# The only Properties which will be defined on the new Object are those that
# are defined by this Model *and* exist on the source object (aObject).
Model.clean = (aObject) ->
    if Object(aObject) isnt aObject
        msg = "Model::clean(aObject) expects an Object as the single parameter."
        throwInvparam(new Error(msg))

    defs = @definitions
    rv = Object.keys(defs).reduce((rv, key) ->
        if _.hasProperty(aObject, key)
            defineProp(rv, key, aObject[key])
        return rv
    , Object.create(null))
    return rv


# Public: Coerce the properties of an Object using the coerce functions defined
# by this Model.
#
# aObject - The source Object.
#
# Returns a new Object with own, enumerable properties defined from aSource
# after each property of aSource has been passed through the corresponding
# coerce function defined by this Model. If no coerce function is defined on
# this Model for the property, then it is simply defined as is.
Model.coerce = (aObject) ->
    if Object(aObject) isnt aObject
        msg = "Model::coerce(aObject) expects an Object as the single parameter."
        throwInvparam(new Error(msg))

    defs = @definitions
    rv = Object.keys(aObject).reduce((rv, key) ->
        value = aObject[key]
        if Object::hasOwnProperty.call(defs, key) and coerce = defs[key].coerce
            defineProp(rv, key, coerce(value))
        else defineProp(rv, key, value)
        return rv
    , Object.create(null))
    return rv


# Public: Validate an Object by running the validation functions defined for
# each property on this Model.
#
# aObject - The Object to validate.
#
# Returns an Object whoes own properties are the keys of the properties on the
# given aObject which did not pass validation. If all the properties on aObject
# pass validation then returns null.
Model.validate = (aObject) ->
    errors = Object.create(null)
    defs = @definitions

    pushError = (key, err) ->
        if not errors[key] then errors[key] = []
        errors[key].push(err)
        return

    Object.keys(defs).forEach (key) ->
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


# Public: Merge two objects together using the merge rules defined on this
# Model.
#
# aTarget - The Object that receive properties from the aSource.
# aSource - The Object that will provide properties to aTarget.
#
# Returns a new object made up of all the properties of aTarget and aSource.
# Any properties of aTarget which also exist on aSource will be overwritten by
# those of aSource.  If this Model definition includes merge functions for any
# properties of aSource, they will be executed and the resulting values will be
# used to define those properties on aTarget.
Model.merge = (aTarget, aSource) ->
    defs = @definitions

    # First, copy over all properties to a new object.
    rv = Object.keys(aTarget).reduce((rv, key) ->
        return defineProp(rv, key, aTarget[key])
    , Object.create(null))

    # Then merge in the properties from aSource
    rv = Object.keys(aSource).reduce((rv, key) ->
        val = aSource[key]
        if Object::hasOwnProperty.call(defs, key) and merge = defs[key].merge
            defineProp(rv, key, merge(rv[key], val))
        else
            defineProp(rv, key, val)

        return rv
    , rv)
    return rv


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
# .validators   - An Array of validation Functions that will each be called
#                 during the validation process.
# .coerce       - A type casting Function that can modify the value of a
#                 property on the modeled object.
# .merge        - A Function to provide special merge logic used when this
#                 property is merged with another.
#
# The signature for the validation Functions is:
#
# `function validator(value, key, name) { ... }`
#
# The 'value' is the value of the property, the key is the property key, and
# the name is the name given to the property in the property definition.
#
# The signature for the coerce Function is:
#
# `function typecast(value) { return anotherValue; }`
#
# The signature for the merge Function is:
#
# `function merge(existing, source) { return mergedValue; }`
#
# The 'existing' is the value of the property on the target Object, while
# 'source' is the value on the source Object.
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

    merge = aDef.merge
    if merge and not _.isFunction(merge)
        throw "'merge' definition must be a Function."

    # .defaultValue must be coerced into a Function.
    if _.hasProperty(aDef, 'defaultValue')
        df = aDef.defaultValue

        # Already a function.
        if _.isFunction(df)
            defaultValue = df

        # Return deep copies of mutable Objects and Arrays to prevent
        # accidental tampering.
        else if _.isObject(aDef.defaultValue)
            df = JSON.parse(JSON.stringify(df))
            defaultValue = -> return JSON.parse(JSON.stringify(df))

        # Simply return primitives, detached from the object to prevent
        # accidental mutation.
        else
            defaultValue = -> return df

    # Default is to return null
    else
        defaultValue = -> return null

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
            value: (val) -> coerce.call(def, val)
        })

    if merge
        Object.defineProperty(def, 'merge', {
            enumerable: yes
            value: (target, source) -> merge.call(def, target, source)
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


defineProp = (obj, key, val) ->
    # Use Object.defineProperty() for more control.
    Object.defineProperty(obj, key, {
        enumerable: yes
        writable: yes
        value: val
    })
    return obj

# Private:
throwInvparam = (aError) ->
    aError.code = INVPARAM
    throw aError


# Private:
throwInvpropdef = (aError) ->
    aError.code = INVPROPDEF
    throw aError
