// Script assets have changed for v2.3.0 see
// https://help.yoyogames.com/hc/en-us/articles/360005277377 for more information
/// @desc Handle WORK command - earn gold by doing day labor
/// @param {Real} days Number of days to work (default 1)

function scr_cmd_work(days) {
    // TODO: ADVANCED WORK SYSTEM
    // Future enhancements to make earning gold more interesting:
    // - Contracts/Quests: Special jobs that pay better but have requirements
    // - Skill-based work: Better pay for merchants vs laborers
    // - Reputation bonus: High reputation = better wages
    // - Random events: Chance to find valuable items, make connections, etc.
    
    // TODO: MARKET STALL MINI-GAME
    // Allow player to run a market stall on market days:
    // - Buy goods at reduced prices from other vendors
    // - Sell to NPCs with bargaining mini-game
    // - Risk: Could lose money if you bargain poorly
    // - Reward: Could earn more than simple day labor
    // - Requires initial capital to buy stock
    
    // TODO: EMERGENCY EQUIPMENT SELLING
    // When desperate, allow selling caravan equipment:
    // - Sell pack animals (lose saddlebag capacity)
    // - Sell water barrels (risk dehydration)
    // - Sell wagon upgrades/improvements
    // - Creates tough decisions and potential downward spiral
    
    // Get current location
    var current_loc = undefined;
    for (var i = 0; i < array_length(obj_heartbeat.world.locations); i++) {
        if (obj_heartbeat.world.locations[i].id == obj_player.current_location) {
            current_loc = obj_heartbeat.world.locations[i];
            break;
        }
    }
    
    if (current_loc == undefined) {
        console_print("ERROR: Current location not found.");
        return;
    }
    
    // Validate days
    if (days < 1) {
        console_print("You must work at least 1 day.");
        return;
    }
    
    if (days > 30) {
        console_print("You can't work more than 30 days at once.");
        return;
    }
    
    // Calculate daily costs
    var daily = scr_calculate_daily_consumption();
    var total_provisions = daily.provisions * days;
    var total_water = daily.water * days;
    
    // Check if player has enough resources to work
    if (obj_player.provisions < total_provisions) {
        console_print("INSUFFICIENT PROVISIONS!");
        console_print("You need " + string(total_provisions) + " provisions to work for " + string(days) + " days.");
        console_print("You only have " + string(obj_player.provisions) + " provisions.");
        console_print("");
        console_print("Try working fewer days, or buy provisions first.");
        return;
    }
    
    var available_water = scr_get_total_water();
    if (available_water < total_water) {
        console_print("INSUFFICIENT WATER!");
        console_print("You need " + string(total_water) + " water to work for " + string(days) + " days.");
        console_print("You only have " + string(available_water) + " water.");
        return;
    }
    
    // Determine wage based on location type
    var daily_wage = 8; // Base wage
    
    switch(current_loc.type) {
        case "CITY":
            daily_wage = irandom_range(10, 15); // Cities pay best
            break;
        case "TOWN":
            daily_wage = irandom_range(7, 10); // Towns pay average
            break;
        case "VILLAGE":
            daily_wage = irandom_range(5, 8); // Villages pay least
            break;
    }
    
    var total_earnings = daily_wage * days;
    
    // === EXECUTE WORK ===
    
    // Consume resources
    obj_player.provisions -= total_provisions;
    scr_consume_water(total_water);
    
    // Earn gold
    obj_player.gold += total_earnings;
    
    // Advance time
    obj_heartbeat.day += days;
    
    // Generate flavor text
    var work_descriptions = [
        "You spend your days loading wagons at the docks.",
        "You work in the marketplace, hauling goods for merchants.",
        "You take odd jobs around town, doing whatever work you can find.",
        "You help local farmers bring their harvest to market.",
        "You work at the stables, tending to horses and mules.",
        "You assist craftsmen in their workshops.",
        "You take work as a courier, delivering messages around town."
    ];
    
    var flavor = work_descriptions[irandom(array_length(work_descriptions) - 1)];
    
    // === REPORT ===
    console_print("");
    console_print("=== WORK COMPLETE ===");
    console_print(flavor);
    console_print("");
    console_print("Days worked: " + string(days));
    console_print("Daily wage: " + string(daily_wage) + " gold/day");
    console_print("Total earned: " + string(total_earnings) + " gold");
    console_print("");
    console_print("Resources consumed:");
    console_print("  Provisions: " + string(total_provisions));
    console_print("  Water: " + string(total_water));
    console_print("");
    console_print("Current resources:");
    console_print("  Gold: " + string(obj_player.gold));
    console_print("  Provisions: " + string(obj_player.provisions));
    console_print("  Water: " + string(scr_get_total_water()) + "/" + string(scr_get_max_water_capacity()));
    console_print("");
    
    // Warnings
    if (obj_player.provisions < 10) {
        console_print("WARNING: Provisions are running low!");
    }
    if (scr_get_total_water() < 10) {
        console_print("WARNING: Water is running low!");
    }
    
    // Refill water (since time passed in same location)
    var refill_info = scr_refill_water();
    if (refill_info.water > 0) {
        console_print("Water refilled: +" + string(refill_info.water));
    }
    
    console_print("");
}