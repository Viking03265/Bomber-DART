part of dartvirusbomberman;

class Behaviour extends BehaviourInterface {
  // Easy AI for the start.
  // The AI should place bombs directly infront of walls,
  // and try to avoid all bombs by going to positions that are not in a explosion zone.
  // For now only place one bomb at a time.
  bool searchForAction = false;
  bool placeBombThere = false;
  List<List<double>> bombMap;
  List<List<double>> entityMap;
  List<List<double>> goalMap;
  List<List<double>> distMap;
  List<List<bool>> placeBombMap;
  List<int> walkToTile;
  List<int> goalTile;
  List<List<int>> path;

  Behaviour(VirusBombermanGame game, Virus virus) {
    walkToTile = game.getTileFromCoord(game, virus.posX, virus.posY);
    initMaps(game);
  }

  void initMaps(VirusBombermanGame game) {
    bombMap = List.generate(game.numTilesX,
        (i) => List.filled(game.numTilesY, 0.0, growable: false),
        growable: false);
    entityMap = List.generate(game.numTilesX,
        (i) => List.filled(game.numTilesY, 0.0, growable: false),
        growable: false);
    goalMap = List.generate(game.numTilesX,
        (i) => List.filled(game.numTilesY, 0.0, growable: false),
        growable: false);
    placeBombMap = List.generate(game.numTilesX,
        (i) => List.filled(game.numTilesY, false, growable: false),
        growable: false);
    distMap = List.generate(game.numTilesX,
        (i) => List.filled(game.numTilesY, 10000, growable: false),
        growable: false);
  }

  @override
  void update(VirusBombermanGame game, Virus virus) {
    // If it is running smooth enough with pathfinding running in every update the if can go,
    // otherwise the searchForAction should only be set to true once the virus gets to its previous goal.
    // Running smooth here, but might not on lower end CPUs.
    searchForAction = true;
    if (searchForAction) {
      // Generate the 2D Arrays, here called maps.
      initMaps(game);
      fillBombMap(game);

      // Fill the entity map, for the distance calculation for each tile.
      for (var v in game.virus) {
        if (v.id != virus.id) {
          var tile = game.getTileFromCoord(game, v.posX, v.posY);
          entityMap[tile[0]][tile[1]] = 10.0;
        }
      }

      fillDistAndGoalMap(game, virus);

      // Search for the maximum goal / dist
      var maxGoalByDist = 0.0;
      goalTile = game.getTileFromCoord(game, virus.posX, virus.posY);
      for (var x = 0; x < game.numTilesX; x++) {
        for (var y = 0; y < game.numTilesY; y++) {
          goalMap[x][y] /= max(1, distMap[x][y]);
          if (maxGoalByDist < goalMap[x][y]) {
            maxGoalByDist = goalMap[x][y];
            goalTile = [x, y];
          }
        }
      }

      // Calculate the next tile that brings you closer to your tartet.
      path = <List<int>>[];
      var currentTile = <int>[];
      var nextTilesToCheck = <List<int>>[];

      nextTilesToCheck.add(goalTile);
      while (nextTilesToCheck.isNotEmpty &&
          (currentTile = nextTilesToCheck.removeAt(0)) != null) {
        path.insert(0, currentTile);

        var nextMinValue = distMap[currentTile[0]][currentTile[1]];
        var foundAtLeastSomething = false;
        var neighbours =
            getNeighbouringTiles(game, currentTile[0], currentTile[1]);

        var nextMinTile;
        for (var neighbour in neighbours) {
          if (distMap[neighbour[0]][neighbour[1]] < nextMinValue) {
            nextMinValue = distMap[neighbour[0]][neighbour[1]];
            nextMinTile = [neighbour[0], neighbour[1]];
            foundAtLeastSomething = true;
          }
        }
        if (!foundAtLeastSomething) {
          // Could not find a lower value than the last.
          // So it must be at the virus position.
          break;
        } else {
          nextTilesToCheck.add(nextMinTile);
        }
      }

      if (path.isNotEmpty) {
        if (path.length == 1) {
          // The best option is to stay at the tile.
          walkToTile = path[0];
        } else {
          // Move to the next tile.
          walkToTile = [path[1][0], path[1][1]];
        }
        placeBombThere = placeBombMap[walkToTile[0]][walkToTile[1]];
      }
      searchForAction = false;
    }

    var walkTo = game.getCoordFromTile(game, walkToTile[0], walkToTile[1]);
    // Is not at the target.
    // Walk there, ignore if stuck for now.
    var stuck = false, stuck2 = false;
    if (walkTo[0] < virus.posX - 1) {
      stuck = virus.moveLeft(game);
    } else if (walkTo[0] > virus.posX + 1) {
      stuck = virus.moveRight(game);
    } else {
      stuck = true;
    }
    if (walkTo[1] < virus.posY - 1) {
      if (virus.moveUp(game) && stuck) {
        stuck2 = true;
      }
    } else if (walkTo[1] > virus.posY + 1) {
      if (virus.moveDown(game) && stuck) {
        stuck2 = true;
      }
    } else if (stuck) {
      stuck2 = true;
    }
    if (stuck2) {
      searchForAction = true;
      if (placeBombThere) {
        virus.plantBomb(game);
        placeBombThere = false;
      }
    }
  }

  /// Fills the distMap, as well as the goalMap for every tile the [virus] can reach.
  /// It also fills the tiles that are needed to move out of an explosion with high goal values.
  void fillDistAndGoalMap(VirusBombermanGame game, Virus virus) {
    var nextTilesToCheck = <List<int>>[];
    var currentTile = <int>[];

    var playerTile = game.getTileFromCoord(game, virus.posX, virus.posY);
    var isPlayerInsideExplosion = bombMap[playerTile[0]][playerTile[1]] < 0;
    distMap[playerTile[0]][playerTile[1]] = 0.0;
    nextTilesToCheck.add(playerTile);
    placeBombMap[playerTile[0]][playerTile[1]] = true;

    // Calculate the walking distance of each tile to the player.
    while (nextTilesToCheck.isNotEmpty &&
        (currentTile = nextTilesToCheck.removeAt(0)) != null) {
      // Calculate the amount of points a bomb could get when placed on this tile.
      for (var explosionTile in getExplosionTiles(
          game, currentTile[0], currentTile[1], virus.strength)) {
        goalMap[currentTile[0]][currentTile[1]] +=
            (game.blockstates[explosionTile[0]][explosionTile[1]] == 1
                    ? 1
                    : 0) +
                entityMap[explosionTile[0]][explosionTile[1]];
        placeBombMap[currentTile[0]][currentTile[1]] = true;
      }

      // Fill the field in the maps.
      for (var neighborTile
          in getNeighbouringTiles(game, currentTile[0], currentTile[1])) {
        if (bombMap[neighborTile[0]][neighborTile[1]] < 0 &&
            !isPlayerInsideExplosion) {
          // Avoid going into explosions.
        } else if (game.blockstates[neighborTile[0]][neighborTile[1]] == 0) {
          var newDist = distMap[currentTile[0]][currentTile[1]] + 1.0;

          if (newDist < distMap[neighborTile[0]][neighborTile[1]]) {
            distMap[neighborTile[0]][neighborTile[1]] = newDist;
            nextTilesToCheck.add([neighborTile[0], neighborTile[1]]);
          }
        }
      }
    }
    if (isPlayerInsideExplosion) {
      for (var x = 0; x < game.numTilesX; x++) {
        for (var y = 0; y < game.numTilesY; y++) {
          if (bombMap[x][y] > 0) {
            goalMap[x][y] += bombMap[x][y] / distMap[x][y];
            placeBombMap[x][y] = false;
          }
        }
      }
    }
    for (var u in game.upgrades) {
      var tile = game.getTileFromCoord(game, u.posX, u.posY);
      goalMap[tile[0]][tile[1]] = 10.0;
      placeBombMap[tile[0]][tile[1]] = false;
    }
  }

  /// Sets negativ values for every tile an explosion will accour on,
  /// so it can be avoided.
  /// Sets positiv values for every walkable tile that is next to a future explosion,
  /// so the AI can walk there to avoid the explosion.
  void fillBombMap(VirusBombermanGame game) {
    for (var x = 0; x < game.numTilesX; x++) {
      for (var y = 0; y < game.numTilesY; y++) {
        if (game.blockstates[x][y] < 0) bombMap[x][y] = game.blockstates[x][y];
      }
    }
    var bombs = <Bomb>[];
    for (var v in game.virus) {
      for (var b in v.bombs) {
        bombs.add(b);
      }
    }
    bombs.sort((a, b) => a.remainingTime.compareTo(b.remainingTime));
    for (var b in bombs) {
      var bombTileX = b.posX ~/ game.tileSize;
      var bombTileY = b.posY ~/ game.tileSize;
      if (bombTileX < 0) continue;
      if (bombTileY < 0) continue;
      if (bombTileX >= game.numTilesX) continue;
      if (bombTileY >= game.numTilesY) continue;

      var bombTime = -b.remainingTime;
      if (bombMap[bombTileX][bombTileY] < 0 &&
          bombMap[bombTileX][bombTileY] > bombTime) {
        bombTime = bombMap[bombTileX][bombTileY];
      }

      var list = getExplosionTiles(game, bombTileX, bombTileY, b.strength);

      for (var explosionTile in list) {
        if (bombMap[explosionTile[0]][explosionTile[1]] < bombTime ||
            bombMap[explosionTile[0]][explosionTile[1]] >= 0) {
          bombMap[explosionTile[0]][explosionTile[1]] = bombTime;
          var neighbours =
              getNeighbouringTiles(game, explosionTile[0], explosionTile[1]);
          for (var neighbour in neighbours) {
            if ((bombMap[neighbour[0]][neighbour[1]] == 0 ||
                    -bombTime < bombMap[neighbour[0]][neighbour[1]]) &&
                game.blockstates[neighbour[0]][neighbour[1]] < 100) {
              bombMap[neighbour[0]][neighbour[1]] = -bombTime;
            }
          }
        }
      }
    }
  }

  /// Returns a list of tiles that are at most [strength] tiles from [tileX],[tileY] away
  /// and are still on the map.
  ///
  /// Also only takes the first wall into the list, tiles behind a wall are not in the list.
  List<List<int>> getExplosionTiles(
      VirusBombermanGame game, int tileX, int tileY, int strength) {
    var list = <List<int>>[];

    list.add([tileX, tileY]);
    // Right of the bomb
    for (var tX = 1; tX <= strength && (tileX + tX) < game.numTilesX; tX++) {
      if (game.blockstates[tileX + tX][tileY] < 100) {
        list.add([tileX + tX, tileY]);
        if (game.blockstates[tileX + tX][tileY] > 0) {
          break;
        }
      }
    }
    // Left of the bomb
    for (var tX = 1; tX <= strength && (tileX - tX) >= 0; tX++) {
      if (game.blockstates[tileX - tX][tileY] < 100) {
        list.add([tileX - tX, tileY]);
        if (game.blockstates[tileX - tX][tileY] > 0) {
          break;
        }
      }
    }
    // Down of the bomb
    for (var tY = 1; tY <= strength && (tileY + tY) < game.numTilesY; tY++) {
      if (game.blockstates[tileX][tileY + tY] < 100) {
        list.add([tileX, tileY + tY]);
        if (game.blockstates[tileX][tileY + tY] > 0) {
          break;
        }
      }
    }
    // Up of the bomb
    for (var tY = 1; tY <= strength && (tileY - tY) >= 0; tY++) {
      if (game.blockstates[tileX][tileY - tY] < 100) {
        list.add([tileX, tileY - tY]);
        if (game.blockstates[tileX][tileY - tY] > 0) {
          break;
        }
      }
    }

    return list;
  }

  /// Returns a list of tiles that are next to [tileX],[tileY] and are still on the map.
  List<List<int>> getNeighbouringTiles(
      VirusBombermanGame game, int tileX, int tileY) {
    var list = <List<int>>[];
    if (tileX > 0 &&
        tileY >= 0 &&
        tileX < game.numTilesX &&
        tileY < game.numTilesY) {
      list.add([tileX - 1, tileY]);
    }
    if (tileX >= 0 &&
        tileY > 0 &&
        tileX < game.numTilesX &&
        tileY < game.numTilesY) {
      list.add([tileX, tileY - 1]);
    }
    if (tileX >= 0 &&
        tileY >= 0 &&
        tileX < game.numTilesX - 1 &&
        tileY < game.numTilesY) {
      list.add([tileX + 1, tileY]);
    }
    if (tileX >= 0 &&
        tileY >= 0 &&
        tileX < game.numTilesX &&
        tileY < game.numTilesY - 1) {
      list.add([tileX, tileY + 1]);
    }
    return list;
  }
}
