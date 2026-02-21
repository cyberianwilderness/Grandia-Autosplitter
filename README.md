# Grandia I (Steam / HD Remaster) LiveSplit Autosplitter

**Status:** Work in Progress

This autosplitter provides automatic splits for Grandia I using memory values from the Steam HD Remaster.


# Location-Based Split (Working)
- As development progresses, the aim is to split when significant areas of the game are first reached. At present only Marna Road is used for testing purposes

---

# Boss Fight Splits
Every Boss fight that provides a reward when the battle rewards screen appears, is used to split.
The autosplitter checks:
- EXP gained
- Gold gained

If both match the expected values, the split occurs.
If a boss only awards EXP **or** Gold, the splitter will match the non-zero value.

---

# Duplicate Split Protection (WIP)

## Reward Latch
Prevents multiple splits while sitting on the reward screen.

#### Location Latch
Prevents repeated splits when staying in the same location state.

#### 3-Second Cooldown
A refresh-rate aware cooldown prevents double splits when:

- identical rewards occur (e.g., Saki / Nana / Mio)
- rewards linger on screen (players may stay on the reward section for a long time - unlikely, but could occur)

---

## ASLVarViewer Support
The autosplitter exposes useful values for analysis and verification:

**Location / State**
- `loc2` → LocationVar2  
- `ms` → mapState  
- `sv` → startVar  

**Battle Rewards**
- `expR` → EXP gained from battle  
- `goldR` → Gold gained from battle  

Should anyone be testing the autosplitter, please show the above variables in your splits if possible.
This helps
- verify split triggers  
- discover additional split points  

---

## Current Split Order

1. Marna Road
2. Rock Bird
3. Orc King
4. Squid King
5. Chang
6. Ganymede
7. Saki
8. Nana
9. Mio
10. Serpent
11. Madragon
12. Massacre Machine 1
13. Massacre Machine 2
14. Gadwin
15. Grinwhale
16. Arm
17. Milda
18. Gaia Battler 1
19. Gaia Battler 2
20. Ruin Guard
21. Trinity
22. Baal
23. Hydra
24. Great Susano-o
25. Ax
26. Iron Ball
27. Phantom Dragon
28. Gaia Battler 3
29. Mage King
30. Gaia Battler 4
31. Mullen
32. Gaia Trent
33. Gaia Armor

_I appreciate this is not ideal as some of these fights have significant time between them. The aim is to add location splits based on feedback from speedrnners as more testing is done and to ofcourse find the variable for the final split when the party enter the Spirit Sanctuary_
---

## Important Notes

- Splits occur when the **battle rewards screen appears**, not when the boss dies.
- The autosplitter does **NOT auto-reset**. Should the game crash, players should not have their splits reset.
- LocationVar1 is currently unused. But plans are th use it in the future
- Additional location splits will be added as they are verified.

---

## Planned Improvements

- Additional location splits
- Optional split conditions
- Improved detection for bosses with identical rewards
- Community verification & accuracy testing

---

## Contributing

If you discover reliable memory values or additional split points:

1. Verify using ASLVarViewer
2. Note the exact values observed
3. I can be found in the Grandia Speedrunning discord or raise a pull request on here.

---

## Compatibility

- Grandia HD Remaster (Steam)  
- LiveSplit with ASL support  

