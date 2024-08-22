--// Types
local Types = require(script.Types)
type InputType = Types.inputType

--// Services
local UserInputService = game:GetService('UserInputService')

--// Variables
local InputHandler = {
    binds = {}
}

--// Constants
local inputStates = script.InputStates:GetChildren()

--// Public Functions
function InputHandler.processInput(inputObject: InputObject)
    local detectedInput = inputObject.KeyCode.Name ~= 'Unknown' and inputObject.KeyCode or inputObject.UserInputType

    local bindObjects = InputHandler.binds[detectedInput.Name]
    if not bindObjects then return end

    for _, bindObject in bindObjects do
        local stateCheck = false
        for _, stateType in bindObject.state do
            if stateType == inputObject.UserInputState then
                stateCheck = true
                break
            end
        end

        if stateCheck then
            pcall(function()
                bindObject.callback(inputObject)
            end)
        end
    end
end

function InputHandler.addBind(inputData: InputType)
    for _, bind in inputData.binds do
        if not InputHandler.binds[bind.Name] then
            InputHandler.binds[bind.Name] = {}
        end
        table.insert(InputHandler.binds[bind.Name], inputData)
    end
end

function InputHandler.removeInput(inputData: InputType)
    for _, bind in inputData.binds do
        if InputHandler.binds[bind.Name] then
            for i, bindObject in InputHandler.binds[bind.Name] do
                if bindObject == inputData then
                    table.remove(InputHandler.binds[bind.Name], i)
                    break
                end
            end
            if #InputHandler.binds[bind.Name] == 0 then
                InputHandler.binds[bind.Name] = nil
            end
        end
    end
end

--// Connections
function InputHandler.preLoad()
    for _, inputModule in inputStates do
        local input: InputType = require(inputModule)
        for _, bind in input.binds do
            if not InputHandler.binds[bind.Name] then
                InputHandler.binds[bind.Name] = {}
            end
            table.insert(InputHandler.binds[bind.Name], input)
        end
    end

    UserInputService.InputBegan:Connect(function(inputObject: InputObject, isTyping: boolean)
        if isTyping then return end
        InputHandler.processInput(inputObject)
    end)

    UserInputService.InputEnded:Connect(function(inputObject: InputObject, isTyping: boolean)
        if isTyping then return end
        InputHandler.processInput(inputObject)
    end)
end

return InputHandler
