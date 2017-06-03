# Gold Tools and Bonus Yields [goldtools]
by Kevin "mrunderhill89" Cameron

SUMMARY:
This mod adds a gold pickaxe, shovel, axe, and sword to the game. 

Now I know what you're going to say: "Oh, great, another mod that makes gold unrealistically overpowered," right? Not so! In this mod, gold tools are actually as bad if not worse than wooden tools. They can dig any kind of node, but they take forever to do so and break very quickly.

So why would you use them? Well, in this mod gold has the curious property of doubling or tripling the yields you get from most nodes, allowing you to harvest far more of a rare material than by using standard tools. This way you can keep a steel or diamond pick for quarrying common stone, and a gold pick for when you find something you want.

This mod wraps the native Minetest dig function with new code that detects whether the current tool has the property "bonusyield" or "randombonusyield." If so, the mod detects what items the newly-dug node would have dropped and adds additional items to your inventory based on that value. Note that you probably won't get something for nothing this way: the mod will detect (with reasonable accuracy) if a node yields itself and no bonus yields are given if that's the case. Because most trees fall under this category, axes have some special logic that automatically splits the wood when cut. This also applies to rubber trees with the Technic mod (you'll get more latex this way), as well as my Maple Tree mod and the special wood types added by Duane's [Big Trees](https://forum.minetest.net/viewtopic.php?f=9&t=16503) mod.
