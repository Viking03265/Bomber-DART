part of dartvirusbomberman;

class VirusBombermanView {
  List<List<HtmlElement>> tiles;

  final topbar = querySelector('#topbar');
  final tilecontainer = querySelector('#tilecontainer');
  final viruscontainer = querySelector('#viruscontainer');
  final bombcontainer = querySelector('#bombcontainer');
  final upgradecontainer = querySelector('#upgradecontainer');
  final timer = querySelector('#timer');

  // Field
  List<HtmlElement> virus;
  Map<int, HtmlElement> bombs;
  Map<int, HtmlElement> upgrades;

  // TopBar
  List<HtmlElement> players;
  List<HtmlElement> points;
  List<HtmlElement> strengths;
  List<HtmlElement> maxbmb;
  List<HtmlElement> actbmb;

  static bool initialised = false;

  VirusBombermanView();

  void updateClock(VirusBombermanGame model) {
    var min = model.timer > 0 ? (model.timer ~/ 60) : (-model.timer ~/ 60);
    var sec = model.timer > 0 ? (model.timer % 60) : (-model.timer % 60);
    timer.innerHtml =
        "${model.timer < 0 ? "-" : ""}$min:${sec < 10 ? 0 : ""}$sec";
  }

  void update(VirusBombermanGame model) {
    // Update the virus
    for (var i = 0; i < 4; i++) {
      virus[i].style.left = '${model.virus[i].posX ~/ 1}px';
      virus[i].style.top = '${model.virus[i].posY ~/ 1}px';
      if (model.virus[i].inactiveTime >= 3000) {
        virus[i].classes.add('inactive');
      } else {
        virus[i].classes.remove('inactive');
      }
    }

    // TopBar Updates
    for (var i = 0; i < model.virus.length; i++) {
      points[i].text = '${model.virus[i].points}';
      strengths[i].text = '${model.virus[i].strength}';
      maxbmb[i].text = '${model.virus[i].maxBombs}';
      actbmb[i].text = '${model.virus[i].currentBombs}';
    }

    // Update the bombs, create new ones if nessesary, and delete exploded ones.
    var existingBombs = <int, bool>{};
    for (var v in model.virus) {
      for (var b in v.bombs) {
        if (!bombs.containsKey(b.id)) {
          // Create the div
          var div = DivElement();
          div.id = 'bomb${b.id}';
          div.className = 'bomb';
          div.style.left = '${b.posX ~/ 1}px';
          div.style.top = '${b.posY ~/ 1}px';
          // Add to the DOM
          bombcontainer.children.add(div);
          // Add to the map
          bombs[b.id] = div;
        }
        if (!b.detonated) {
          bombs[b.id].style.left = '${b.posX ~/ 1}px';
          bombs[b.id].style.top = '${b.posY ~/ 1}px';
          existingBombs[b.id] = true;
        }
      }
    }
    for (var id = 0; id < model.nextEntityId; id++) {
      if (bombs.containsKey(id) &&
          !(existingBombs.containsKey(id) && existingBombs[id])) {
        bombcontainer.children.remove(bombs[id]);
        bombs.remove(id);
      }
    }
    existingBombs.clear();

    // Update the Upgrades
    var existingUpgrades = <int, bool>{};
    for (var u in model.upgrades) {
      if (!upgrades.containsKey(u.id)) {
        // Create the div
        var div = DivElement();
        div.id = 'upgrade${u.id}';
        div.className = 'upgrade${u.type}';
        div.style.left = '${u.posX ~/ 1}px';
        div.style.top = '${u.posY ~/ 1}px';
        // Add to the DOM
        upgradecontainer.children.add(div);
        // Add to the map
        upgrades[u.id] = div;
      }
      if (!u.taken) {
        existingUpgrades[u.id] = true;
      }
    }
    for (var id = 0; id < model.nextEntityId; id++) {
      if (upgrades.containsKey(id) &&
          !(existingUpgrades.containsKey(id) && existingUpgrades[id])) {
        upgradecontainer.children.remove(upgrades[id]);
        upgrades.remove(id);
      }
    }
    existingUpgrades.clear();

    // Updates the tiles
    final tile = model.tile;
    for (var tY = 0; tY < tile.length; tY++) {
      for (var tX = 0; tX < tile[tY].length; tX++) {
        final td = tiles[tY][tX];
        if (td != null) {
          td.classes.clear();
          if (tile[tY][tX] == #wall) {
            td.classes.add('wall');
          } else if (tile[tY][tX] == #human) {
            td.classes.add('human');
          } else if (tile[tY][tX] == #explosion) {
            td.classes.add('explosion');
          } else {
            td.classes.add('empty');
          }
        }
      }
    }
  }

  void generateTiles(VirusBombermanGame model) {
    // Create and fill a list for the HtmlElements of the players in the topBar.
    players = [];

    for (var i = 0; i < 4; i++) {
      players.add(querySelector('#player$i'));
      players[i].style.visibility = 'hidden';
    }
    
    for (var v in model.virus) {
      players[v.id].style.visibility = 'visible';
    }

    // TopBar Initialization

    points = [];
    strengths = [];
    maxbmb = [];
    actbmb = [];

    for (var i = 0; i < model.virus.length; i++) {
      // Create the divs
      var divpoints = DivElement();
      divpoints.className = 'points';
      divpoints.text = '0';

      // strength div
      var divstrengths = DivElement();
      divstrengths.className = 'strength';
      divstrengths.text = '0';

      // max bombs div
      var divmaxbmb = DivElement();
      divmaxbmb.className = 'maxbombs';
      divmaxbmb.text = '0';

      // active bombs div
      var divactb = DivElement();
      divactb.className = 'actbombs';
      divactb.text = '0';

      // Add to the DOM and the lists
      players[i].children.add(divpoints);
      points.add(divpoints);

      players[i].children.add(divstrengths);
      strengths.add(divstrengths);

      players[i].children.add(divactb);
      maxbmb.add(divmaxbmb);

      players[i].children.add(divmaxbmb);
      actbmb.add(divactb);
    }

    // Create and fill the list for the player sprites.
    virus = [];
    viruscontainer.children.clear();
    for (var v in model.virus) {
      // Create the div
      var div = DivElement();
      div.id = 'virus${v.id}';
      div.style.left = '${v.posX ~/ 1}px';
      div.style.top = '${v.posY ~/ 1}px';
      // Add to the DOM
      viruscontainer.children.add(div);
      // Add to the list
      virus.add(div);
    }

    // Create a map for the bombs.
    bombs = {};

    // Create a map for the upgrades.
    upgrades = {};

    updateClock(model);
    final tile = model.tile;
    tilecontainer.children.clear();

    // Set the grid size
    tilecontainer.style.gridTemplateColumns =
        'repeat(${model.numTilesX}, ${model.tileSize}px)';
    tilecontainer.style.gridTemplateRows =
        'repeat(${model.numTilesY}, ${model.tileSize}px)';

    tiles = List<List<HtmlElement>>(tile.length);
    for (var tY = 0; tY < tile.length; tY++) {
      tiles[tY] = [];
      for (var tX = 0; tX < tile[tY].length; tX++) {
        // Create the div
        var div = DivElement();
        div.id = 'field_${tY}_$tX';
        div.className = '${tile[tY][tX]}';
        // Add to the DOM
        tilecontainer.children.add(div);
        // Add to the 2D List
        tiles[tY].add(div);
      }
    }
  }
}
