part of dartvirusbomberman;

class Virus extends Entity {
  bool player = false;
  BehaviourInterface behaviour;

  bool alive = true;
  int maxNumBombs = 1;
  int strength = 1;
  int points = 1;
  List<Bomb> bombs;
  int inactiveTime = 0;

  int get currentBombs => bombs.length;
  int get maxBombs => maxNumBombs;

  Virus(VirusBombermanGame game, int tileX, int tileY, int behavoiurNum)
      : super(game, (tileX + 0.5) * game.tileSize,
            (tileY + 0.5) * game.tileSize, game.playerHitbox) {
    bombs = [];
    inactiveTime = 3000;
    switch (behavoiurNum) {
      // Add other behaviours here.
      default:
        behaviour = Behaviour(game, this);
    }
  }

  void update(VirusBombermanGame game, int deltaMS) {
    inactiveTime += deltaMS;
    if (isInsideExplosion(game, this)) {
      // For now you only lose points, when standing in an explosion.
      points--;
    }
    for (var bomb in bombs) {
      if (bomb.update(game, deltaMS, this)) bombs.remove(bomb);
    }
  }

  /// Moves the virus by the given amount of [dx] on the x axis and [dy] on the y axis.
  /// Returns true if it has collided with something.
  bool move(VirusBombermanGame game, double dx, double dy) {
    inactiveTime = 0;
    posX += dx;
    posY += dy;
    return collision(game, dx, dy);
  }

  bool plantBomb(VirusBombermanGame game) {
    inactiveTime = 0;
    if (bombs.length < maxNumBombs) {
      var tile = game.getTileFromCoord(game, posX, posY);
      if (game.blockstates[tile[0]][tile[1]] == 0) {
        bombs.add(Bomb(game, posX, posY, strength));
        return true;
      }
    }
    return false;
  }

  bool moveDown(VirusBombermanGame game) {
    return move(game, 0.0, 1.0);
  }

  bool moveUp(VirusBombermanGame game) {
    return move(game, 0.0, -1.0);
  }

  bool moveLeft(VirusBombermanGame game) {
    return move(game, -1.0, 0.0);
  }

  bool moveRight(VirusBombermanGame game) {
    return move(game, 1.0, 0.0);
  }
}
