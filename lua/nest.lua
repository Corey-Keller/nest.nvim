local module = {}

--- Defaults being applied to `applyKeymaps`
-- Can be modified to change defaults applied.
module.defaults = {
    mode = "n",
    prefix = "",
    buffer = false,
    options = {
        noremap = true,
        silent = true,
    },
}

-- Create empty table to hold mapping info for later reference
NestMapsTable = {}

--- Registry for keymapped lua functions, do not modify!
module.functions = {}

local function registerFunction(func)
    table.insert(module.functions, func)

    return #module.functions
end

local function copy(table)
    local ret = {}

    for key, value in pairs(table) do
        ret[key] = value
    end

    return ret
end

local function mergeTables(left, right)
    local ret = copy(left)

    for key, value in pairs(right) do
        ret[key] = value
    end

    return ret
end

local function mergeOptions(left, right)
    local ret = copy(left)

    if right == nil then
        return ret
    end

    if right.mode ~= nil then
        ret.mode = right.mode
    end

    if right.buffer ~= nil then
        ret.buffer = right.buffer
    end

    if right.prefix ~= nil then
        ret.prefix = ret.prefix .. right.prefix
    end

    if right.options ~= nil then
        ret.options = mergeTables(ret.options, right.options)
    end

    return ret
end

--- Applies the given `keymapConfig`, creating nvim keymaps
module.applyKeymaps = function (config, presets)
    local mergedPresets = mergeOptions(
        presets or module.defaults,
        config
    )

    local first = config[1]

    if type(first) == "table" then
        for _, it in ipairs(config) do
            module.applyKeymaps(it, mergedPresets)
        end

        return
    end

    local second = config[2]

    mergedPresets.prefix = mergedPresets.prefix .. first

    if type(second) == "table" then
        module.applyKeymaps(second, mergedPresets)

        return
    end

    local rhs = type(second) == "function"
        and '<Cmd>lua require("nest").functions[' .. registerFunction(second) .. ']()<CR>'
        or second

    local cfg = {}
    if mergedPresets.mode ~= nil then
        cfg.mode = mergedPresets.mode
    end

    if mergedPresets.buffer ~= nil then
        cfg.buffer = mergedPresets.buffer
    end

    if mergedPresets.options ~= nil then
        cfg.options = copy(mergedPresets.options)
    end

    cfg.lhs = mergedPresets.prefix
    cfg.rhs = rhs

    if type(config[3]) == "string" then
        cfg.description = config[3]
    end

    table.insert(NestMapsTable,cfg)

    for mode in string.gmatch(mergedPresets.mode, '.') do
        if mergedPresets.buffer then
            local buffer = (mergedPresets.buffer == true)
                and 0
                or mergedPresets.buffer

            vim.api.nvim_buf_set_keymap(
                buffer,
                mode,
                mergedPresets.prefix,
                rhs,
                mergedPresets.options
            )
        else
            vim.api.nvim_set_keymap(
                mode,
                mergedPresets.prefix,
                rhs,
                mergedPresets.options
            )
        end
    end

end

return module
