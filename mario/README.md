# Super Mario Engine

### EL2003 -- Computer Organization and Assembly Language \| Semester Project

A 16-bit x86 platform game developed in NASM Assembly Language for the
COAL Lab Project (BSCS 3F, Fall 2026).

The project recreates a classic side-scrolling platform game using
low-level programming concepts. It runs as a DOS `.COM` executable
inside DOSBox, with graphics, player movement, game logic, keyboard
input, and timing implemented in Assembly Language.

------------------------------------------------------------------------

## 1. Project Overview

Super Mario Engine is a single-player platform game in which the player
controls Mario through a side-scrolling level.

The objective is to navigate the level, avoid or defeat enemies, collect
coins and power-ups, and reach the flag pole before the timer expires or
all lives are lost.

Unlike conventional games, this project does not use a graphics library
or an external game engine. Core functionality is implemented directly
using 16-bit x86 Assembly instructions.

## 2. Team Members

  Name            Roll Number   Modules Developed
  --------------- ------------- --------------------------
  Ibrahim Vohra   25F-0738      1, 2, 3, 5, 6, 7, 8, 13
  Anss Tahir      25F-0539      4, 9, 10, 11, 12, 14, 15

## 3. Technologies Used

-   **Assembly Language:** NASM (Netwide Assembler)
-   **Architecture:** 16-bit x86, Real Mode
-   **Development Environment:** NASM and DOSBox

## 4. Gameplay Features

-   Side-scrolling platform level.
-   Mario movement with walking, running and jumping.
-   Gravity, momentum and variable jump height.
-   Small Mario and Super Mario forms.
-   Goomba and Koopa Troopa enemies.
-   Koopa shell movement and collision behaviour.
-   Coins, question blocks, bricks and mushroom power-ups.
-   Score, health, lives and countdown timer.
-   Flag pole and level completion sequence.
-   Pause, restart and game-over functionality.

## 5. Project Structure

The main source file is `mario.asm`. It acts as the entry point and
includes the other Assembly files using NASM `%include` directives.


### Source File Responsibilities

  File               Responsibility
  ------------------ ----------------------------------------------
  `mario.asm`        Main entry point and source-file integration
  `build.bat`        Builds the executable and launches DOSBox
  `[map].asm`        Stores the original level map and working copy for gameplay
  `[graphics].asm`   Contains graphics data, tiles, sprites and palettes
  `[input].asm`      Handles keyboard input and key state management
  `[collision].asm`  Detects collisions with tiles, enemies and objects
  `[game_logic].asm` Manages scoring, health, lives, coins and timer
  `[state].asm`      Controls game states and screen transitions
  `[HUD].asm`        Draws the background, tiles, sprites and HUD

Each Assembly file is responsible for a particular part of the game. The
main file integrates these modules into a single executable.

## 6. Controls

  Key           Action
  ------------- ------------------------------------------
  Left Arrow    Move left
  Right Arrow   Move right
  Left Shift    Run
  Space         Jump (hold for a higher jump)
  Up / Down     Navigate the menu
  Enter         Select menu option / continue
  P             Pause / Resume
  Esc           Return to title / Exit from title screen


## 7. Bonus Features

The following additional features have been implemented:

-   **Walking Animation:** Animated Mario movement frames and mirrored
    Goomba sprites.
-   **Coin Pop-up Animation:** A small visual pop-up appears when a
    question block releases a coin.



**Course:** EL2003 -- Computer Organization and Assembly Language\
**Project:** Super Mario Engine\
**Section:** BSCS 3F\
**Semester:** Fall 2026
