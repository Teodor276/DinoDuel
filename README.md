# capstone-team-4

## Dino Duel
This application implements the Battle Sheep board game in the Godot game engine. 
Users can choose to play against friends on their local machine or over a network, or against several levels of AI.

## Developers
- Garret Gill: networking lead
- Cristian Padilla: co-AI lead
- Noah Thompson: co-UI lead, co-game core lead
- Bethany Stevens: team lead, co-UI lead
- Teodor Zlatar: co-game core lead, co-AI lead

## Documentation

### UI

- **Dino sprites:** [Dino Family by Demching](https://demching.itch.io/dino-family)
- **AI pixel art generator used for concepts:** [AI Pixel Art Generator](https://aipixelartgenerator.com/)
- **Pixel smoke particles:** [Particle Smoke by Pedro Ricciotti](https://pedroricciotti.itch.io/particle-smoke)
- **Stone UI elements:** [Complete UI Essential Pack by Crusenho](https://crusenho.itch.io/complete-ui-essential-pack)
- **Background assets:** [Megabundle by PixelJad](https://pixeljad.itch.io/megabundle)
- Suggested `"../"` for `get_node()`: [Reddit thread](https://www.reddit.com/r/godot/comments/fjp984/get_node_returning_null/?rdt=55697)
- Information on `gui_input()` used for screen dimmer: [Godot Documentation](https://docs.godotengine.org/en/stable/tutorials/inputs/inputevent.html)
- How to play videos that are already loaded: [Reddit thread](https://www.reddit.com/r/godot/comments/pv3irp/loading_videos_into_the_video_player_by_code/?rdt=64730)
- Using `get_node()` for accessing child nodes: Google's AI overview for "how to access children node's visibility properties godot"
- Using `str()`: [Godot Forums discussion](https://godotforums.org/d/32997-int-to-string-conversion)
- **Design created with:** [Canva Design](https://www.canva.com/design/DAGj9bw9zJo/xQANiX6sO9j23dtY35MGXw/edit)
- **Tool used:** [Theora Converter](https://sourceforge.net/projects/theoraconverter/)
- **Tool used:** [OBS Studio](https://obsproject.com/)
- ChatGPT 4.0 used to generate art for the gameplay section of the game

### Game Core

- **Godot Syntax and Engine Basics:** [Godot 4.3 Documentation](https://docs.godotengine.org/en/4.3/)
- **Hexagonal Coordinates and Transfers:** [Red Blob Games - Hexagonal Grids](https://www.redblobgames.com/grids/hexagons/)

### Networking

- **Calculating broadcast addresses:** [WikiHow Guide](https://www.wikihow.com/Calculate-Network-and-Broadcast-Address)
- **UDP communication between instances:** [Godot UDPServer Documentation](https://docs.godotengine.org/en/stable/classes/class_udpserver.html)
- **HTTP Requests (SoftServe):** [Godot HTTPRequest Class Documentation](https://docs.godotengine.org/en/stable/tutorials/networking/http_request_class.html)
- **Godot Regex Class Documentation:** [Godot Engine Docs - Regex](https://docs.godotengine.org/en/stable/classes/class_regex.html)
- **Complete Guide to Regular Expressions:** [CoderPad - Regex Guide](https://coderpad.io/blog/development/the-complete-guide-to-regular-expressions-regex/)
- ChatGPT 4.0 used for debugging and help with the syntax

### AI

- **Godot Syntax and Engine Basics:** [Godot 4.3 Documentation](https://docs.godotengine.org/en/4.3/)
- **Restricting stack placement to perimeter (Flood Fill):** [Wikipedia - Flood Fill](https://en.wikipedia.org/wiki/Flood_fill)
- **Implementing Monte Carlo Tree Search (MCTS):** [BuiltIn - Monte Carlo Tree Search](https://builtin.com/machine-learning/monte-carlo-tree-search)
- **Parallelization:** [Godot Multithreading Tutorial](https://docs.godotengine.org/en/stable/tutorials/performance/using_multiple_threads.html)
- **Board traversals in AI:** [HackerEarth BFS Tutorial](https://www.hackerearth.com/practice/algorithms/graphs/breadth-first-search/tutorial/)
- ChatGPT 4.0 used for debugging and help with the syntax

### Music
- **Music pulled from:** [Zophar's Domain - Gameboy Music](https://www.zophar.net/music/gameboy-gbs)
  - **BGM #4:** Jurassic Park (GBA)
  - **BGM #5:** Jurassic Park (GBA)
  - **Kremlantis:** Donkey Kong Country (GBA)
  - **Bonus Win:** Kirby’s Dream Land 2
  - **Game Over:** Kirby’s Dream Land
  - **Game Over:** Kirby’s Block Ball

### Exporting

- **Changing icons and creating a release build:** [Exporting Projects in Godot](https://docs.godotengine.org/en/latest/tutorials/export/exporting_projects.html)

### Installer

- **Inno Setup Documentation:** [Inno Setup Help](https://jrsoftware.org/ishelp/index.php?topic=languagessection)
- **Installer Tutorial:** [YouTube Video](https://www.youtube.com/watch?v=4s4rP9GYH0o)
