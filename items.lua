--Config type 0: click and type integer (type, value/default, indicator, label, min, max) --Type used by quantity
--Config type 1: click on 5-point liner selector (type, selected/default 1-5, indicator, label, 5 options)
--Config type 2: toggle switch (type, boolean/default, label)
--Config type 3: click buttons to increment integer (type, value/default, label, step)

--If quantity is editable {0, "10", "#:", "Quantity", 1, 1000} must be first config
--6 configs max per item
--config type 0 does not support negative values currently

--(label, unit price, is quantity editable, config arrays)--
--Quantity editable example {"Acacia Boat", 10, true, {0, "10", "#:", "Quantity", 1, 1000}, {1, 1, "%:", "ConfigA:", 0, 25, 50, 75, 100}, {3, 0, "Config-C", 1, -10, 10}} --Quantity is the first config slot
--Quantity not editable example {"Acacia Boat", 10, false, {0, "-25", "&:", "ConfigD", -50, 50}, {1, 1, "%:", "ConfigA:", 0, 25, 50, 75, 100}, {3, 0, "Config-C", 1, -10, 10}}  --Quantity is locked at 1 and configD is first config slot
itemList = {
    {"Acacia Boat", 10, false},
    {"Acacia Boat with Chest", 10, false, {1, 1, "%:", "ConfigA:", 0, 25, 50, 75, 100}},
    {"Amethyst Shard", 10, false, {2, false, "Config B"}},
    {"Angler Pottery Sherd", 10, false, {3, 0, "Config-C", 1, -10, 10}},
    {"Apple", 10, false, {0, "25", "&:", "ConfigD", 0, 50}},
    {"Archer Pottery Sherd", 10, false, {1, 1, "%:", "ConfigA:", 0, 25, 50, 75, 100}, {1, 1, "%:", "ConfigA:", 0, 25, 50, 75, 100}, {1, 1, "%:", "ConfigA:", 0, 25, 50, 75, 100}, {1, 1, "%:", "ConfigA:", 0, 25, 50, 75, 100}, {1, 1, "%:", "ConfigA:", 0, 25, 50, 75, 100}, {1, 1, "%:", "ConfigA:", 0, 25, 50, 75, 100}},
    {"Armor Stand", 10, false, {2, false, "Config B"}, {2, false, "Config B"}, {2, false, "Config B"}, {2, false, "Config B"}, {2, false, "Config B"}, {2, false, "Config B"}},
    {"Arms Up Pottery Sherd", 10, false, {3, 0, "Config-C", 1, -10, 10}, {3, 0, "Config-C", 1, -10, 10}, {3, 0, "Config-C", 1, -10, 10}, {3, 0, "Config-C", 1, -10, 10}, {3, 0, "Config-C", 1, -10, 10}, {3, 0, "Config-C", 1, -10, 10}},
    {"Arrow", 10, false, {0, "25", "&:", "ConfigD", 0, 50}, {0, "25", "&:", "ConfigD", 0, 50}, {0, "25", "&:", "ConfigD", 0, 50}, {0, "25", "&:", "ConfigD", 0, 50}, {0, "25", "&:", "ConfigD", 0, 50}, {0, "25", "&:", "ConfigD", 0, 50}},
    
    {"Baked Potato", 10, true, {0, "10", "#:", "Quantity", 1, 1000}},
    {"Bamboo Raft", 10, true, {0, "10", "#:", "Quantity", 1, 1000}, {1, 1, "%:", "ConfigA:", 0, 25, 50, 75, 100}},
    {"Bamboo Raft with Chest", 10, true, {0, "10", "#:", "Quantity", 1, 1000}, {2, false, "Config B"}},
    {"Banner Pattern (Creeper Charge)", 10, true, {0, "10", "#:", "Quantity", 1, 1000}, {3, 0, "Config-C", 1, -10, 10}},
    {"Banner Pattern (Flower Charge)", 10, true, {0, "10", "#:", "Quantity", 1, 1000}, {0, "25", "&:", "ConfigD", 0, 50}},
    {"Banner Pattern (Globe)", 10, true, {0, "10", "#:", "Quantity", 1, 1000}, {1, 1, "%:", "ConfigA:", 0, 25, 50, 75, 100}, {1, 1, "%:", "ConfigA:", 0, 25, 50, 75, 100}, {1, 1, "%:", "ConfigA:", 0, 25, 50, 75, 100}, {1, 1, "%:", "ConfigA:", 0, 25, 50, 75, 100}, {1, 1, "%:", "ConfigA:", 0, 25, 50, 75, 100}},
    {"Banner Pattern (Skull Charge)", 10, true, {0, "10", "#:", "Quantity", 1, 1000}, {2, false, "Config B"}, {2, false, "Config B"}, {2, false, "Config B"}, {2, false, "Config B"}, {2, false, "Config B"}},
    {"Banner Pattern (Snout)", 10, true, {0, "10", "#:", "Quantity", 1, 1000}, {3, 0, "Config-C", 1, -10, 10}, {3, 0, "Config-C", 1, -10, 10}, {3, 0, "Config-C", 1, -10, 10}, {3, 0, "Config-C", 1, -10, 10}, {3, 0, "Config-C", 1, -10, 10}},
    {"Banner Pattern (Thing)", 10, true, {0, "10", "#:", "Quantity", 1, 1000}, {1, 1, "%:", "ConfigA:", 0, 25, 50, 75, 100}, {2, false, "Config B"}, {3, 0, "Config-C", 1, -10, 10}, {0, "25", "&:", "ConfigD", 0, 50}, {0, "25", "&:", "ConfigD", -50, 50}},

    {"Beetroot", 10, false}, --Extra to test search scroll
    {"Beetroot Seeds", 10, false},
    {"Beetroot Soup", 10, false},
    {"Birch Boat", 10, false},
    {"Birch Boat with Chest", 10, false},
    {"Black Dye", 10, false},
    {"Blade Pottery Sherd", 10, false},
    {"Blaze Powder", 10, false},
    {"Blaze Rod", 10, false},
    {"Blue Dye", 10, false},
    {"Bone", 10, false},
    {"Bone Meal", 10, false},
    {"Book", 10, false},
    {"Book and Quill", 10, false},
    {"Bottle o Enchanting", 10, false},
    {"Bow", 10, false},
    {"Bowl", 10, false},
    {"Bread", 10, false},
    {"Brewer Pottery Sherd", 10, false},
    {"Brick", 10, false},
    {"Brown Dye", 10, false},
    {"Brush", 10, false},
    {"Bucket", 10, false},
    {"Bucket of Axolotl", 10, false},
    {"Bucket of Cod", 10, false},
    {"Bucket of Pufferfish", 10, false},
    {"Bucket of Salmon", 10, false},
    {"Bucket of Tadpole", 10, false},
    {"Bucket of Tropical Fish", 10, false},
    {"Bundle", 10, false},
    {"Burn Pottery Sherd", 10, false}
}
