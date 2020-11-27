minetest.register_node("core:ns_node", {
    drawtype = "glasslike",
    visual_scale = 1.0,
    tiles = {"core_ns.png", "core_ns.png", "core_ns.png", "core_ns.png", "core_ns.png", "core_ns.png"},
    inventory_image = "core_ns.png",
    use_texture_alpha = true,
    stack_max = 1,
    sunlight_propagates = false,
    walkable = true,
    pointable = true,
    diggable = true,
})