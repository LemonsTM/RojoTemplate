--// STOLEN FROM THE ELDRUNA GUY

local BehaviorTree = {}
BehaviorTree.__index = BehaviorTree

local Node = {}
Node.__index = Node

function Node.new(data)
    local self = setmetatable({}, Node)
    self.type = data.Type
    self.name = data.Name
    self.children = {}
    self.func = data.Func

    return self
end

function Node:addChild(childNode)
    table.insert(self.children, childNode)
end

function Node:run(entity, blackboard)
    if self.type == 'Root' then
        return self.children[1]:run(entity, blackboard)
    end

    if self.type == "Task" and self.func then
        return self.func(entity, blackboard)
    elseif self.type == "Sequence" then
        for _, child in ipairs(self.children) do
            local result = child:run(entity, blackboard)
            if result == "Failure" then
                return "Failure"
            end
        end

        return "Success"
    elseif self.type == "Selector" then
        for _, child in ipairs(self.children) do
            local result = child:run(entity, blackboard)
            if result == "Success" then
                return "Success"
            end
        end

        return "Failure"
    end

    return "Failure"
end

function BehaviorTree.buildTree(treeData)
    local function buildNode(data)
        local node = Node.new(data)
        if data.Children then
            for _, childData in ipairs(data.Children) do
                local childNode = buildNode(childData)
                node:addChild(childNode)
            end
        end

        return node
    end

    return buildNode(treeData[1])
end

return BehaviorTree
