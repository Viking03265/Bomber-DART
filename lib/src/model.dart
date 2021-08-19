part of dartvirusbomberman;

class VirusBombermanGame {
  /// Size of the tiles in px.
  final double tileSize = 40;

  /// Size of the player in px.
  final double playerHitbox = 30;

  /// Size of the bomb in px.
  final double bombHitbox = 20;

  /// Size of the upgrade in px.
  final double upgradeHitbox = 20;

  /// Time the bomb takes to explode in ms.
  final double bombTimer = 3000;

  /// Time the explosion lingers around in ms.
  final double explosionTimer = 150;

  /// The id the next generated bomb needs to get, to sync with the view.
  int nextEntityId = 0;

  /// Width of the board in tiles.
  int numTilesX = 29;

  /// Height of the board in tiles.
  int numTilesY = 19;

  /// The timer shown in the top of the board.
  int timer;

  /// The random generator used by the game.
  Random random;

  /// The chance that a destroyed wall drops a strengthUp upgrade.
  double chanceStrengthUp = 0.1;

  /// The chance that a destroyed wall drops a bombUp upgrade.
  double chanceBombUp = 0.05;

  /// Blockstates contain the state of each tile they are representing.
  /// negative values mean, it is currently in an explosion,
  /// zero is walkable,
  /// positive values mean, there is an obstacle
  List<List<double>> blockstates;

  /// A list containing all current players on the field.
  List<Virus> virus;

  /// A map containing all current upgrades on the field.
  List<Upgrade> upgrades;

  VirusBombermanGame();

  /// Loads the map and creates the players,
  /// "with the data of a given JSON File."
  void loadLevel() {
    random = Random();

    // Reset the entityIdCounter
    nextEntityId = 0;

    // Generate the 2D Array for the tiles.
    blockstates = Iterable.generate(numTilesX, (tX) {
      return Iterable.generate(numTilesY, (tY) => 0.0).toList();
    }).toList();

    // Load the Level JSON here in the future.
    // Currently it's just a standart level.
    for (var x = 0; x < numTilesX; x++) {
      for (var y = 0; y < numTilesY; y++) {
        if (x % 2 == 1 && y % 2 == 1) {
          blockstates[x][y] = 10000;
        } else {
          blockstates[x][y] = random.nextInt(2).toDouble();
        }
      }
    }

    blockstates[0][0] = 0;
    blockstates[1][0] = 0;
    blockstates[0][1] = 0;

    blockstates[numTilesX - 1][0] = 0;
    blockstates[numTilesX - 2][0] = 0;
    blockstates[numTilesX - 1][1] = 0;

    blockstates[0][numTilesY - 1] = 0;
    blockstates[1][numTilesY - 1] = 0;
    blockstates[0][numTilesY - 2] = 0;

    blockstates[numTilesX - 1][numTilesY - 1] = 0;
    blockstates[numTilesX - 2][numTilesY - 1] = 0;
    blockstates[numTilesX - 1][numTilesY - 2] = 0;

    // Reset the timer.
    timer = 180;

    // Reset the list for the upgrades.
    upgrades = <Upgrade>[];

    // Reset the list for the players.
    virus = <Virus>[];

    // Create the players, depending on the level it can be less than four.
    virus.add(Virus(this, 0, 0, 0));
    virus[0].player = true;
    virus.add(Virus(this, numTilesX - 1, 0, 0));
    virus.add(Virus(this, 0, numTilesY - 1, 0));
    virus.add(Virus(this, numTilesX - 1, numTilesY - 1, 0));
  }

  /// Reduces the value of the timer by [deltaS] seconds,
  /// and returns true if the time has run out and false if there is still time left.
  bool tickClock(int deltaS) {
    timer -= deltaS;
    return timer < 0;
  }

  /// Updates the model, depending on how much time, [deltaMS] in ms, has passed.
  void update(int deltaMS) {
    for (var v in virus) {
      v.update(this, deltaMS);
    }

    for (var u in upgrades) {
      if (u.taken) {
        upgrades.remove(u);
      } else {
        u.update(this, deltaMS);
      }
    }

    for (var x = 0; x < numTilesX; x++) {
      for (var y = 0; y < numTilesY; y++) {
        if (blockstates[x][y] < 0) {
          blockstates[x][y] = min(0, blockstates[x][y] + deltaMS);
        }
      }
    }
  }

  /// Calculates the tile the position is on, cropped to the mapsize.
  List<int> getTileFromCoord(VirusBombermanGame game, double posX, double posY) {
    var tile = <int>[];
    tile.add(max(0, min(posX ~/ game.tileSize, game.numTilesX - 1)));
    tile.add(max(0, min(posY ~/ game.tileSize, game.numTilesY - 1)));
    return tile;
  }

  /// Calculates the coordinates int the middle of the tile.
  List<double> getCoordFromTile(VirusBombermanGame game, int tileX, int tileY) {
    var pos = <double>[];
    pos.add((tileX + 0.5) * game.tileSize);
    pos.add((tileY + 0.5) * game.tileSize);
    return pos;
  }

  /// Returns a list of the tilestates of the model.
  /// Used by the view.
  List<List<Symbol>> get tile {
    List<List<Symbol>> _tile = Iterable.generate(numTilesY, (tY) {
      return Iterable.generate(numTilesX, (tX) => #empty).toList();
    }).toList();

    for (var tX = 0; tX < numTilesX; tX++) {
      for (var tY = 0; tY < numTilesY; tY++) {
        if (blockstates[tX][tY] >= 100) {
          _tile[tY][tX] = #wall;
        } else if (blockstates[tX][tY] > 0) {
          _tile[tY][tX] = #human;
        } else if (blockstates[tX][tY] < 0) {
          _tile[tY][tX] = #explosion;
        } else {
          _tile[tY][tX] = #empty;
        }
      }
    }

    return _tile;
  }

  void summonUpgrade(int tileX, int tileY, int type) {
    upgrades.add(Upgrade(this, (tileX + 0.5) * tileSize, (tileY + 0.5) * tileSize, type));
  }
}
