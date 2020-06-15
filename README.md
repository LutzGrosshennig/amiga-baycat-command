# amiga-baycat-command
An Amiga top down endless scrolling game project started in 1989. 

Some friends of me (back then) where really talented with graphics and we started a couple of really promising game projects including this one.

![Screenshot](https://github.com/LutzGrosshennig/amiga-baycat-command/blob/master/screenshots/Baycat-Command-Titel.jpg)

The story is kind of lame: You and your speed boot against time and bandits! Of course with 50 FPS smooth as silk vertical scrolling.

![Screenshot](https://github.com/LutzGrosshennig/amiga-baycat-command/blob/master/screenshots/Baycat-Command-Sample.jpg)

One of the tile sets:

![Screenshot](https://github.com/LutzGrosshennig/amiga-baycat-command/blob/master/screenshots/Baycat-Command-Tiles.jpg)

I cant recall exactly why we abandoned the project but we gradually diverged. Other projects from this area are "Dungeons" (a serial link co-op dungeon game) and "Ballerspiel" a horizontal scrolling game.
which will come to github as well.

Unfortunatly we never had any good sounds and the time to finish Baycat Command. So what is still missing?

* Enemies!
* Sounds!
* Levels!

Due to the crappy IRQ initialization it currently requires Kickstart 1.2/1.3!

# Update
I am currently trying to get everything into an state that is compilable. The disk had some bad sectors and I am trying to pull the corrupted files from other copies. Hang on a little while longer its comming... While I was scanning through the code, I noticed that it does indeed needs a lot of refactoring. Today I would do almost everything differently... But if I would not, it would mean I did not learn anything in the past 30 years :D

Have fun with it!
Lutz

# Planned improvements
* Porting to another assembler. While I liked the Profimat IDE back then, it is not very common.
* Getting rid of the self modifying code of the IRQ handling (that is nasty!).
* ~~Bring Copper handling inline with KS 2.0 and above.~~ (fixed)
* A level editor would be nice!
* Refactor to proper chip/fastram usage (by now everything has to be in chipram, a no go).
* Switch to interleaved bitplanes
* Do things right! :D
