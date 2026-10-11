local wow = require("spec.helpers.wow")

describe("helpers", function()
    local Str, Array, Dict

    before_each(function()
        local env = wow.load("Forever").env
        Str, Array, Dict = env.Str, env.Array, env.Dict
    end)

    describe("Str", function()
        it("treats nil and the empty string as empty", function()
            assert.is_true(Str.nullOrEmpty(nil))
            assert.is_true(Str.nullOrEmpty(""))
            assert.is_false(Str.nullOrEmpty(" "))
        end)

        it("lowercases nil as the empty string", function()
            assert.are.equal("", Str.toLower(nil))
            assert.are.equal("save", Str.toLower("SaVe"))
        end)

        it("splits into at most the given number of pieces", function()
            assert.are.same({ "save", "my set" }, { Str.split("save my set", " ", 2) })
        end)
    end)

    describe("Array", function()
        it("inserts into a copy, leaving the original alone", function()
            local original = { 2, 3 }

            assert.are.same({ 1, 2, 3 }, Array.insert(original, 1, 1))
            assert.are.same({ 2, 3 }, original)
        end)

        it("checks whether a value is present", function()
            assert.is_true(Array.contains({ 1, 2 }, 2))
            assert.is_false(Array.contains({ 1, 2 }, 3))
        end)
    end)

    describe("Dict", function()
        it("lists keys", function()
            local keys = Dict.keysAsArray({ b = 1, a = 2 })
            table.sort(keys)

            assert.are.same({ "a", "b" }, keys)
        end)

        it("checks for emptiness", function()
            assert.is_true(Dict.isEmpty({}))
            assert.is_false(Dict.isEmpty({ a = 1 }))
        end)
    end)
end)
