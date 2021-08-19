part of dartvirusbomberman;

class Bomb extends Entity {
  double dx = 0, dy = 0;
  int strength;
  double remainingTime;
  bool detonated = false;

  Bomb(VirusBombermanGame game, double posX, double posY, int strength)
      : super(game, posX, posY, game.bombHitbox) {
    this.strength = strength;
    remainingTime = game.bombTimer;
  }

  bool update(VirusBombermanGame game, int deltaMS, Virus virus) {
    if (detonated) return true;
    move(game);
    // Check if one of the corners is inside an explosion.
    // If so, explode instantly.

    // TODO: Needs to be reworked,
    // putting bombs in a line should not allow the second bomb to destroy a wall behind a wall the first one just destroyed.
    if (isInsideExplosion(game, this)) {
      remainingTime = -1;
    }
    // Explode when the timer runs out.
    if ((remainingTime -= deltaMS) < 0) explode(game, virus);
    return false;
  }

  void push(double dX, double dY) {
    dx = dX;
    dy = dY;
  }

  void move(VirusBombermanGame game) {
    posX += dx;
    posY += dy;
    if (collision(game, dy, dy)) {
      dx = 0;
      dy = 0;
    }
  }

  /// Explodes the tiles in every direction of the bomb, dependant on strength.
  void explode(VirusBombermanGame game, Virus virus) {
    explodeOne(game, posX ~/ game.tileSize, posY ~/ game.tileSize);
    for (var tX = 1; tX <= strength; tX++) {
      var exp =
          explodeOne(game, posX ~/ game.tileSize + tX, posY ~/ game.tileSize);
      if (exp > 0) {
        break;
      } else if (exp == 0) {
        wallDestroyed(
            game, virus, posX ~/ game.tileSize + tX, posY ~/ game.tileSize);
        break;
      }
    }
    for (var mtX = 1; mtX <= strength; mtX++) {
      var exp =
          explodeOne(game, posX ~/ game.tileSize - mtX, posY ~/ game.tileSize);
      if (exp > 0) {
        break;
      } else if (exp == 0) {
        wallDestroyed(
            game, virus, posX ~/ game.tileSize - mtX, posY ~/ game.tileSize);

        break;
      }
    }
    for (var tY = 1; tY <= strength; tY++) {
      var exp =
          explodeOne(game, posX ~/ game.tileSize, posY ~/ game.tileSize + tY);
      if (exp > 0) {
        break;
      } else if (exp == 0) {
        wallDestroyed(
            game, virus, posX ~/ game.tileSize, posY ~/ game.tileSize + tY);
        break;
      }
    }
    for (var mtY = 1; mtY <= strength; mtY++) {
      var exp =
          explodeOne(game, posX ~/ game.tileSize, posY ~/ game.tileSize - mtY);
      if (exp > 0) {
        break;
      } else if (exp == 0) {
        wallDestroyed(
            game, virus, posX ~/ game.tileSize, posY ~/ game.tileSize - mtY);
        break;
      }
    }
    detonated = true;
  }

  /// Calculates the explosion for one tile, returns an int with the following meanings:
  ///
  /// -1: Explosion has hit nothing, keep going.
  ///
  ///  0: Explosion hit and removed a wall. Stop in this direction.
  ///
  ///  1: Explosion hit and did not remove the wall. Stop in this direction.
  int explodeOne(VirusBombermanGame game, int tileX, int tileY) {
    if (tileX < 0 ||
        tileX > game.numTilesX - 1 ||
        tileY < 0 ||
        tileY > game.numTilesY - 1) {
      return 1;
    }
    if (game.blockstates[tileX][tileY] < 100) {
      if (game.blockstates[tileX][tileY] == 1) {
        game.blockstates[tileX][tileY] = -game.explosionTimer;
        return 0;
      } else if (game.blockstates[tileX][tileY] <= 0) {
        game.blockstates[tileX][tileY] = -game.explosionTimer;
        return -1;
      } else {
        game.blockstates[tileX][tileY]--;
        return 1;
      }
    }
    return 1;
  }

  /// Is called when a wall was successfully destroyed.
  /// Summons upgrades and gives points.
  void wallDestroyed(
      VirusBombermanGame game, Virus virus, int tileX, int tileY) {
    game.virus[virus.id].points++;
    if (game.random.nextDouble() < game.chanceStrengthUp) {
      game.summonUpgrade(tileX, tileY, Upgrade.STRENGTH_UP);
    } else if (game.random.nextDouble() < game.chanceBombUp) {
      game.summonUpgrade(tileX, tileY, Upgrade.BOMB_UP);
    }
  }
}
