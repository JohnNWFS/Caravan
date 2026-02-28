// Script assets have changed for v2.3.0 see
// https://help.yoyogames.com/hc/en-us/articles/360005277377 for more information
/// @desc Queue the full Caravan player's guide for typewriter-style output.
///       Call console_clear() before calling this.
///       All lines use console_print_slow() -- they drip in one per typewriter_delay frames.
///       SPACE pauses/resumes the typewriter. Any other key flushes the queue instantly.

function scr_show_game_guide() {

    // ================================================================
    // HEADER
    // ================================================================
    console_print_slow("  CARAVAN  --  THE PLAYER'S GUIDE");
    console_print_slow("  ================================");
    console_print_slow("  [ SPACE = pause/resume  |  any other key = skip all ]");
    console_print_slow("");

    // ================================================================
    // WELCOME
    // ================================================================
    console_print_slow("WELCOME, MERCHANT");
    console_print_slow("-----------------------------------------");
    console_print_slow("You have chosen to risk your life savings on a cart, a donkey,");
    console_print_slow("and the iron-clad belief that somewhere out there, someone needs");
    console_print_slow("salt. They do. You just have to find them before Rosa Marchetti");
    console_print_slow("does. She has a head start. Her donkey is also smarter than yours.");
    console_print_slow("");
    console_print_slow("This is CARAVAN - a medieval trade game about buying things cheap");
    console_print_slow("and selling them expensive, which is, historically speaking, how");
    console_print_slow("every merchant fortune in history was made. (And also lost.)");
    console_print_slow("");

    // ================================================================
    // THE WORLD
    // ================================================================
    console_print_slow("THE WORLD");
    console_print_slow("-----------------------------------------");
    console_print_slow("The world is made of Cities, Towns, and Villages.");
    console_print_slow("");
    console_print_slow("  CITIES   - Big markets. More goods. Safer roads.");
    console_print_slow("             Prices are higher. Competition is fierce.");
    console_print_slow("  TOWNS    - Medium markets. Some danger. Good trade routes.");
    console_print_slow("             Sweet spot for experienced merchants.");
    console_print_slow("  VILLAGES - Tiny stock. Higher danger. Wild price swings.");
    console_print_slow("             Visit them before your rivals do.");
    console_print_slow("");
    console_print_slow("Each location PRODUCES some goods (cheap there, sell elsewhere)");
    console_print_slow("and DEMANDS others (paying a premium - shown as [WANTED]).");
    console_print_slow("Stock depletes when people buy it. It regenerates over time.");
    console_print_slow("The trick: be the first one there after stock rebounds.");
    console_print_slow("");

    // ================================================================
    // YOUR GOAL
    // ================================================================
    console_print_slow("YOUR GOAL");
    console_print_slow("-----------------------------------------");
    console_print_slow("Make as much gold as possible.");
    console_print_slow("That's it. There's no princess. There's no dragon.");
    console_print_slow("There's just you, the road, and an increasingly valuable donkey.");
    console_print_slow("The game scores you on your final gold after 50 journeys.");
    console_print_slow("(Or however many you chose. We're not the boss of you.)");
    console_print_slow("");

    // ================================================================
    // ALL COMMANDS
    // ================================================================
    console_print_slow("ALL COMMANDS");
    console_print_slow("-----------------------------------------");
    console_print_slow("  TRAVEL (T)       Show destinations from your location.");
    console_print_slow("                   Lists cost in days, water, gold, provisions.");
    console_print_slow("  GO <place> (G)   Travel there. e.g. GO Silverpeak  or  GO 3");
    console_print_slow("  MARKET (M)       See buy and sell prices at current location.");
    console_print_slow("  BUY <good> <n>   Buy trade goods. e.g. BUY salt 50");
    console_print_slow("                   Use MAX to buy as much as you can afford.");
    console_print_slow("  SELL <good> <n>  Sell cargo. e.g. SELL silk 20  or  SELL silk MAX");
    console_print_slow("  STATUS (ST)      Your gold, health, wagons, animals, cargo.");
    console_print_slow("  INVENTORY (I)    Detailed cargo list with estimated resale values.");
    console_print_slow("  SHOP VEHICLES    Browse wagons for sale. Bigger = more cargo.");
    console_print_slow("  SHOP ANIMALS     Browse draft animals. Faster or wear-resistant.");
    console_print_slow("  REPAIR (REP)     Repair all damaged wagons. Costs gold. Worth it.");
    console_print_slow("  WORK <days> (W)  Earn 3 gold/day through day labor. Very slow.");
    console_print_slow("                   Use when you have literally 12 gold and a dream.");
    console_print_slow("  MAP              See the whole world map. ESC or click to close.");
    console_print_slow("  HELP (H)         Quick command reference.");
    console_print_slow("  GUIDE            This guide. Hello again.");
    console_print_slow("");

    // ================================================================
    // TRADING STRATEGY
    // ================================================================
    console_print_slow("TRADING STRATEGY");
    console_print_slow("-----------------------------------------");
    console_print_slow("The golden rule: buy where it's cheap, sell where it's expensive.");
    console_print_slow("Groundbreaking advice, we know. You're welcome.");
    console_print_slow("");
    console_print_slow("HOW TO FIND GOOD TRADES:");
    console_print_slow("  1. MARKET here. Note what's cheap (produced locally).");
    console_print_slow("  2. GO somewhere new. MARKET there.");
    console_print_slow("  3. If the price is higher than you paid, that's profit.");
    console_print_slow("  4. If the price says [WANTED] - extra bonus. Sell everything.");
    console_print_slow("  5. Repeat until wealthy or the donkey gives up.");
    console_print_slow("");
    console_print_slow("MARGIN MATH:");
    console_print_slow("  buy@50, sell@120 = 70g profit per unit. Haul 100 units.");
    console_print_slow("  That's 7,000g for one trip. That's a very good trip.");
    console_print_slow("  Always check both sides before committing your cargo budget.");
    console_print_slow("");
    console_print_slow("BULK DISCOUNT:");
    console_print_slow("  Buying more units at once gets a small price discount.");
    console_print_slow("  Selling more units at once gets a small price penalty.");
    console_print_slow("  Split large sell orders across multiple stops if possible.");
    console_print_slow("");
    console_print_slow("RESERVE FUND:");
    console_print_slow("  Always keep 50g in reserve for provisions, tolls, and emergencies.");
    console_print_slow("  Running out of gold mid-journey is undignified.");
    console_print_slow("  Running out of water mid-desert is worse.");
    console_print_slow("");

    // ================================================================
    // BUILDING YOUR CARAVAN
    // ================================================================
    console_print_slow("BUILDING YOUR CARAVAN");
    console_print_slow("-----------------------------------------");
    console_print_slow("Your starting Handcart has 6 cargo slots. This is not a lot.");
    console_print_slow("A Merchant Wagon has 12. A wealthy merchant has more than one wagon.");
    console_print_slow("");
    console_print_slow("VEHICLES (SHOP VEHICLES):");
    console_print_slow("  Handcart    - 4 slots, no animal needed. You push it yourself.");
    console_print_slow("               (It shows. The donkey is embarrassed for you.)");
    console_print_slow("  Cart        - 6 slots, needs a draft animal. Upgrade #1.");
    console_print_slow("  Wagon       - 8 slots + livestock pen. Serious merchant gear.");
    console_print_slow("  Covered     - 10 slots + livestock. Slower but durable.");
    console_print_slow("  Merch.Wagon - 12 slots + 2 livestock. The pinnacle of excess.");
    console_print_slow("");
    console_print_slow("ANIMALS (SHOP ANIMALS):");
    console_print_slow("  Donkey - Reliable. Cheap. Brings 2 saddlebag bonus slots.");
    console_print_slow("  Mule   - Like a donkey but faster and slightly more annoyed.");
    console_print_slow("           Adds 3 saddlebag bonus slots.");
    console_print_slow("  Ox     - Slow but reduces wagon wear by 30%. Long-haul hero.");
    console_print_slow("  Horse  - Fast. Prestigious. Expensive to feed. Worth it.");
    console_print_slow("  Drake  - A fire-breathing lizard. Very fast. Very rare.");
    console_print_slow("           Your competitors will never see you coming.");
    console_print_slow("");
    console_print_slow("REPAIRS:");
    console_print_slow("  Wagons take wear damage on every journey, especially on rough");
    console_print_slow("  terrain (desert, mountains). Below 50% condition, they break");
    console_print_slow("  down more often. REPAIR costs gold but saves cargo - and pride.");
    console_print_slow("");

    // ================================================================
    // THE RIVALS
    // ================================================================
    console_print_slow("YOUR RIVALS");
    console_print_slow("-----------------------------------------");
    console_print_slow("Rosa Marchetti and Ibn Rashid started trading before you arrived.");
    console_print_slow("On MEDIUM worlds, Mei Lin Chen joins them.");
    console_print_slow("On LARGE worlds, Diego Torres and Fatima Al-Rashid are also out");
    console_print_slow("there, making your life significantly more competitive.");
    console_print_slow("");
    console_print_slow("ROSA MARCHETTI (The Explorer)");
    console_print_slow("  Wanders widely. Visits everywhere. Buys whatever looks good.");
    console_print_slow("  High explore drive - she'll visit your best route eventually.");
    console_print_slow("");
    console_print_slow("IBN RASHID (The Speculator)");
    console_print_slow("  Hammers high-margin routes. Clears out Perfume and Fine Dyes.");
    console_print_slow("  If you arrive at Silverpeak and the Perfume is gone... Ibn.");
    console_print_slow("");
    console_print_slow("MEI LIN CHEN (The Arbitrageur)  [MEDIUM/LARGE only]");
    console_print_slow("  Plays the city price spread game. Methodical. Profitable.");
    console_print_slow("");
    console_print_slow("DIEGO TORRES (The Opportunist)  [LARGE only]");
    console_print_slow("  Wanders even more than Rosa. Goes everywhere. Buys odd things.");
    console_print_slow("  Responsible for most of the 'why is this stock at zero?' moments.");
    console_print_slow("");
    console_print_slow("FATIMA AL-RASHID (The Specialist)  [LARGE only]");
    console_print_slow("  Focuses on luxury goods. Very high margin. Rarely loses.");
    console_print_slow("  In AGGRESSIVE mode, she starts with double gold. Good luck.");
    console_print_slow("");

    // ================================================================
    // PRO TIPS
    // ================================================================
    console_print_slow("PRO TIPS");
    console_print_slow("-----------------------------------------");
    console_print_slow("  > Check MAP before TRAVEL - see where everyone is relative");
    console_print_slow("    to where you want to go. Plan multi-stop routes.");
    console_print_slow("  > Desert routes burn extra water. Mountain routes add days.");
    console_print_slow("    Budget for both. Desert + no water barrel = a bad day.");
    console_print_slow("  > If a market is empty, move on. Rivals hit it first.");
    console_print_slow("    Return in a few journeys when stock regenerates.");
    console_print_slow("  > SELL [WANTED] goods first. That 40% bonus is real money.");
    console_print_slow("  > Pigs are more profitable than they look. Haul the pigs.");
    console_print_slow("  > The WORK command pays 3g/day. It's not for getting rich.");
    console_print_slow("    It's for not dying broke. There's a difference.");
    console_print_slow("  > Selling a vehicle nets ~40% of buy price. Upgrade, don't flip.");
    console_print_slow("  > On AGGRESSIVE mode rivals double their starting gold.");
    console_print_slow("    Pick Merchant Prince and go fast, or they'll clear everything.");
    console_print_slow("  > You cannot pet the donkey. This is a known limitation.");
    console_print_slow("    The donkey is aware of this and is coping.");
    console_print_slow("");

    // ================================================================
    // FOOTER
    // ================================================================
    console_print_slow("-----------------------------------------");
    console_print_slow("Type HELP for the quick command reference.");
    console_print_slow("Type START (from setup) or GO <destination> to hit the road!");
    console_print_slow("May your margins be high and your axles unbroken.");
    console_print_slow("");
}
