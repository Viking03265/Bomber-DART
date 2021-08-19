part of dartvirusbomberman;

class Upgrade extends Entity {
  static final int BOMB_UP = 0;
  static final int STRENGTH_UP = 1;

  int type;
  double remainingTime;
  bool taken = false;

  Upgrade(VirusBombermanGame game, double posX, double posY, int type)
      : super(game, posX, posY, game.upgradeHitbox) {
    this.type = type;
    remainingTime = game.bombTimer;
  }

  bool update(VirusBombermanGame game, int deltaMS) {
    if (isInsideExplosion(game, this)) {
      // TODO: The upgrade should be destoryed, when hit by an explosion.
      // For now not implemented, because it would be destroyed right after spawning.
    }

    for (var v in game.virus) {
      if (!taken && touchesPlayer(game, v)) {
        if (type == BOMB_UP) {
          v.maxNumBombs++;
        } else if (type == STRENGTH_UP) {
          v.strength++;
        }
        taken = true;
      }
    }

    return !taken;
  }

  bool touchesPlayer(VirusBombermanGame game, Virus virus) {
    return isColliding(
        posX, posY, size, size, virus.posX, virus.posY, virus.size, virus.size);
  }
}
