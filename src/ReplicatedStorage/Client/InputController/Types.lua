--!strict

export type inputType = {
    name: string, --// Name of the input
    binds: {Enum.KeyCode|Enum.UserInputType}, --// Binds to connect to
    state: {Enum.UserInputState}, --// State of the input to detect (Begin/End)
    callback: (InputObject) -> (), --// Function to call when the input is detected
    actionAuthority: ({ action: string, caster: Instance, customData: unknown?, initialCastTime: number, serverAction: "Cancel" | "Start" }) -> ()?, --// Function to call when the server authoritates an action over all clients
}

return nil