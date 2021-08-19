part of dartvirusbomberman;

class VirusBombermanController {
  var model = VirusBombermanGame();
  var view = VirusBombermanView();

  Duration updateSpeed = Duration(milliseconds: 16);
  Duration clockSpeed = Duration(seconds: 1);
  Timer updateTrigger;
  Timer clockTrigger;

  bool moveLeft = false;
  bool moveRight = false;
  bool moveUp = false;
  bool moveDown = false;
  bool plantBomb = false;

  VirusBombermanController() {
    model.loadLevel();
    view.generateTiles(model);

    if (clockTrigger != null) clockTrigger.cancel();
    clockTrigger = Timer.periodic(clockSpeed, (_) => _tickClock());
    if (updateTrigger != null) clockTrigger.cancel();
    updateTrigger = Timer.periodic(updateSpeed, (_) => _update());

    window.onKeyDown.listen((KeyboardEvent ev) {
      switch (ev.keyCode) {
        case KeyCode.LEFT:
          moveLeft = true;
          break;
        case KeyCode.RIGHT:
          moveRight = true;
          break;
        case KeyCode.UP:
          moveUp = true;
          break;
        case KeyCode.DOWN:
          moveDown = true;
          break;
        case KeyCode.B:
          plantBomb = true;
          break;
      }
    });

    window.onKeyUp.listen((KeyboardEvent ev) {
      switch (ev.keyCode) {
        case KeyCode.LEFT:
          moveLeft = false;
          break;
        case KeyCode.RIGHT:
          moveRight = false;
          break;
        case KeyCode.UP:
          moveUp = false;
          break;
        case KeyCode.DOWN:
          moveDown = false;
          break;
        case KeyCode.B:
          plantBomb = false;
          break;
      }
    });
  }

  void _tickClock() {
    model.tickClock(clockSpeed.inSeconds);
    view.updateClock(model);
  }

  void _update() {
    for (var virus in model.virus) {
      if (virus.player) {
        if (moveDown) virus.moveDown(model);
        if (moveUp) virus.moveUp(model);
        if (moveLeft) virus.moveLeft(model);
        if (moveRight) virus.moveRight(model);
        if (plantBomb) {
          virus.plantBomb(model);
          plantBomb = false;
        }
      } else {
        //AI Stuff needs to be called here i guess
        virus.behaviour.update(model, virus);
      }
    }

    model.update(updateSpeed.inMilliseconds);
    view.update(model);
  }
}
