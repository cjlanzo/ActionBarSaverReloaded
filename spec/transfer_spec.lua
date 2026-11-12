local wow = require("spec.helpers.wow")

-- /abs export and /abs import, copying sets and alias groups between accounts
for _, client in ipairs(wow.clients) do
    describe("/abs export and import on " .. client.name, function()
        local main, alt

        before_each(function()
            main = wow.load(client)
            alt = wow.load(client)
            for _, game in ipairs({ main, alt }) do
                game.spells[100] = "Charge"
                game.items[6948] = "Hearthstone"
                game.macros[1] = "Heal; then: run, 1.2"
                game.equipmentSets[0] = "Tank Gear"
            end
        end)

        local function export(game, args)
            game.window = nil
            game:slash("export " .. args)
            return game.window and game.window.text
        end

        local function import(game, text, args)
            game:slash("import" .. (args and (" " .. args) or ""))
            return game.window.submit(text, false)
        end

        describe("sets", function()
            it("copies a set to another account, where it restores", function()
                main.bar[1] = { type = "spell", id = 100 }
                main.bar[2] = { type = "item", id = 6948 }
                main.bar[3] = { type = "macro", id = 1 }
                main.bar[4] = { type = "equipmentset", id = "Tank Gear" }
                main.bar[client.maxSlots] = { type = "spell", id = 100 }
                main:slash("save leveling")

                local text = export(main, "leveling")
                assert.are.equal("Export set 'leveling'", main.window.title)

                assert.are.same({ "done", "Imported set 'leveling'" }, { import(alt, text) })
                assert.are.same(main.db.class.sets.leveling, alt.db.class.sets.leveling)

                alt:clearOutput()
                alt:slash("restore leveling")
                assert.are.same(main.bar, alt.bar)
                assert.are.same({ "Restored set 'leveling'" }, alt:messages())
            end)

            it("keeps names that contain separators and spaces", function()
                main.bar[3] = { type = "macro", id = 1 }
                main:slash("save my set; v2")

                import(alt, export(main, "my set; v2"))

                assert.are.same({ [3] = { type = "macro", id = "Heal; then: run, 1.2" } }, alt.db.class.sets["my set; v2"])
            end)

            it("keeps macro names that look like numbers as names", function()
                main.macros[1] = "123"
                main.bar[1] = { type = "macro", id = 1 }
                main:slash("save test")

                import(alt, export(main, "test"))

                assert.are.same({ type = "macro", id = "123" }, alt.db.class.sets.test[1])
            end)

            it("ignores spaces and line breaks picked up when pasting", function()
                main.bar[1] = { type = "spell", id = 100 }
                main:slash("save test")
                local text = export(main, "test")

                local result = import(alt, "  " .. text:sub(1, 10) .. "\n" .. text:sub(11) .. "\n")

                assert.are.equal("done", result)
                assert.are.same({ [1] = { type = "spell", id = 100 } }, alt.db.class.sets.test)
            end)

            it("saves under another name when one is given", function()
                main.bar[1] = { type = "spell", id = 100 }
                main:slash("save leveling")

                assert.are.same({ "done", "Imported set 'from main'" }, { import(alt, export(main, "leveling"), "from main") })
                assert.is_nil(alt.db.class.sets.leveling)
                assert.are.same({ [1] = { type = "spell", id = 100 } }, alt.db.class.sets["from main"])
            end)

            it("asks before replacing a set, and replaces it on the second click", function()
                main.bar[1] = { type = "spell", id = 100 }
                main:slash("save leveling")
                alt.bar[1] = { type = "item", id = 6948 }
                alt:slash("save leveling")
                local text = export(main, "leveling")

                assert.are.same({ "conflict", "Set 'leveling' already exists." }, { import(alt, text) })
                assert.are.same({ [1] = { type = "item", id = 6948 } }, alt.db.class.sets.leveling)

                assert.are.same({ "done", "Replaced set 'leveling'" }, { alt.window.submit(text, true) })
                assert.are.same({ [1] = { type = "spell", id = 100 } }, alt.db.class.sets.leveling)
            end)

            it("refuses a set from another class", function()
                main:slash("save leveling")
                alt.class = "MAGE"

                assert.are.same({ "error", "This set is for a WARRIOR; you're on a MAGE" }, { import(alt, export(main, "leveling")) })
                assert.is_nil(alt.db.class.sets.leveling)
            end)

            it("refuses text that isn't an export", function()
                local result, message = import(alt, "hello")

                assert.are.equal("error", result)
                assert.are.equal("This isn't an ActionBarSaver export, or it's from a newer version of the addon", message)
                assert.are.same({}, alt.db.class.sets)
            end)

            it("refuses a set with an unreadable slot", function()
                local result, message = import(alt, "ABS1;set;test;WARRIOR;one=spell:100")

                assert.are.same({ "error", "Couldn't read slot 'one=spell:100'" }, { result, message })
                assert.are.same({}, alt.db.class.sets)
            end)

            it("explains how to export, and which sets exist", function()
                main:slash("export")
                main:slash("export missing")

                assert.is_nil(main.window)
                assert.are.same({
                    "Usage: /abs export <set> or /abs export aliases",
                    "No set with the name 'missing' exists",
                }, main:messages())
            end)
        end)

        describe("alias groups", function()
            it("copies alias groups to another account", function()
                main:slash("alias spell racials 20554 20549")
                main:slash("alias item hearth 6948 2")
                local text = export(main, "aliases")
                assert.are.equal("Export alias groups", main.window.title)

                assert.are.same({ "done", "Imported 2 alias group(s)" }, { import(alt, text) })
                assert.are.same(main.db.global.aliasGroups, alt.db.global.aliasGroups)
            end)

            it("asks before replacing alias groups, then replaces them all", function()
                main:slash("alias spell racials 20554 20549")
                alt:slash("alias mount wolves 1 2")
                local text = export(main, "aliases")

                assert.are.same({ "conflict", "This replaces your 1 alias group(s)." }, { import(alt, text) })
                assert.are.same({ summonmount = { wolves = { 1, 2 } } }, alt.db.global.aliasGroups)

                assert.are.equal("done", alt.window.submit(text, true))
                assert.are.same({ spell = { racials = { 20554, 20549 } } }, alt.db.global.aliasGroups)
            end)

            it("leaves sets alone when importing aliases", function()
                alt:slash("save leveling")
                main:slash("alias spell racials 20554 20549")

                import(alt, export(main, "aliases"))

                assert.is_not_nil(alt.db.class.sets.leveling)
            end)

            it("refuses alias groups that break the alias rules", function()
                assert.are.same(
                    { "error", "spell 20549 is in both 'a' and 'b'" },
                    { import(alt, "ABS1;aliases;spell.a=20549;spell.b=20549") })
                assert.are.same({ "error", "Unknown alias type 'flyout'" }, { import(alt, "ABS1;aliases;flyout.a=1") })
                assert.are.same({ "error", "'x' in group 'a' is not an ID" }, { import(alt, "ABS1;aliases;spell.a=x") })
                assert.are.same({}, alt.db.global.aliasGroups)
            end)

            it("says when there's nothing to export", function()
                main:slash("export aliases")

                assert.is_nil(main.window)
                assert.are.same({ "No alias groups to export" }, main:messages())
            end)
        end)
    end)
end
