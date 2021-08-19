part of dartvirusbomberman;

class Entity {
  double size = 0;
  double posX = 0, posY = 0;
  int id;

  Entity(VirusBombermanGame game, double posX, double posY, double size) {
    id = game.nextEntityId++;
    this.posX = posX;
    this.posY = posY;
    this.size = size;
  }

  /// This is a collision detection with collision response.
  /// It has problems with diagonal movement against blocks.
  ///
  /// Returns true if it has collided with something.
  bool collision(VirusBombermanGame game, double dx, double dy) {
    bool collidedWithSomething = false;
    for (var x = -1; x <= 1; x++) {
      for (var y = -1; y <= 1; y++) {
        if (!(x == 0 && y == 0) &&
            (dx < 0 && x < 0 ||
                dx > 0 && x > 0 ||
                dy < 0 && y < 0 ||
                dy > 0 && y > 0) &&
            collisionWithWall(game, (posX ~/ game.tileSize) + x,
                (posY ~/ game.tileSize) + y)) {
          // collision response
          collidedWithSomething = true;
          if (x < 0 && dx < 0) {
            posX = (posX ~/ game.tileSize) * game.tileSize + size / 2;
          } else if (x > 0 && dx > 0) {
            posX = (posX ~/ game.tileSize + 1) * game.tileSize - size / 2;
          }
          if (y < 0 && dy < 0) {
            posY = (posY ~/ game.tileSize) * game.tileSize + size / 2;
          } else if (y > 0 && dy > 0) {
            posY = (posY ~/ game.tileSize + 1) * game.tileSize - size / 2;
          }
        }
      }
    }
    for (var v in game.virus) {
      /*
      for (var b in v.bombs) {
        if (collisionWithEntity(game, b, dx, dy)) {
          // collision response
          collidedWithSomething = true;
          if ((b.posX - posX) < 0 && dx < 0) {
            posX = b.posX + b.size / 2 + size / 2;
          } else if ((b.posX - posX) > 0 && dx > 0) {
            posX = b.posX - b.size / 2 - size / 2;
          }
          if ((b.posY - posY) < 0 && dy < 0) {
            posY = b.posY - b.size / 2 - size / 2;
          } else if ((b.posY - posY) > 0 && dy > 0) {
            posY = b.posY - b.size / 2 - size / 2;
          }
        }
      }
      */
      if (collisionWithEntity(game, v, dx, dy)) {
        // collision response
        collidedWithSomething = true;
        if ((v.posX - posX) < 0 && dx < 0) {
          posX = v.posX + v.size / 2 + size / 2;
        } else if ((v.posX - posX) > 0 && dx > 0) {
          posX = v.posX - v.size / 2 - size / 2;
        }
        if ((v.posY - posY) < 0 && dy < 0) {
          posY = v.posY + v.size / 2 + size / 2;
        } else if ((v.posY - posY) > 0 && dy > 0) {
          posY = v.posY - v.size / 2 - size / 2;
        }
      }
    }
    return collidedWithSomething;
  }

  bool collisionWithEntity(
      VirusBombermanGame game, Entity entity, double dx, double dy) {
    return (dx < 0 && (entity.posX - posX) < 0 ||
            dx > 0 && (entity.posX - posX) > 0 ||
            dy < 0 && (entity.posY - posY) < 0 ||
            dy > 0 && (entity.posY - posY) > 0) &&
        isColliding(posX, posY, size, size, entity.posX, entity.posY,
            entity.size, entity.size);
  }

  bool collisionWithWall(VirusBombermanGame game, int tileX, int tileY) {
    if (tileX >= 0 &&
        tileX < game.numTilesX &&
        tileY >= 0 &&
        tileY < game.numTilesY) {
      if (game.blockstates[tileX][tileY] > 0) {
        return isColliding(
            posX,
            posY,
            game.playerHitbox,
            game.playerHitbox,
            (tileX + 0.5) * game.tileSize,
            (tileY + 0.5) * game.tileSize,
            game.tileSize,
            game.tileSize);
      }
    } else {
      return isColliding(
          posX,
          posY,
          game.playerHitbox,
          game.playerHitbox,
          (tileX + 0.5) * game.tileSize,
          (tileY + 0.5) * game.tileSize,
          game.tileSize,
          game.tileSize);
    }
    return false;
  }

  bool isColliding(double ax, double ay, double aw, double ah, double bx,
      double by, double bw, double bh) {
    return ax + aw / 2 > bx - bw / 2 &&
        ax - aw / 2 < bx + bw / 2 &&
        ay + ah / 2 > by - bh / 2 &&
        ay - ah / 2 < by + bh / 2;
  }

  bool isInsideExplosion(VirusBombermanGame game, Entity entity) {
    for (var x = 0; x <= 1; x++) {
      for (var y = 0; y <= 1; y++) {
        var tileX = (posX + (x - 0.5) * size) ~/ game.tileSize;
        var tileY = (posY + (y - 0.5) * size) ~/ game.tileSize;

        if (game.blockstates[max(0, min(tileX, game.numTilesX - 1))]
                [max(0, min(tileY, game.numTilesY - 1))] <
            0) {
          return true;
        }
      }
    }
    return false;
  }
}
