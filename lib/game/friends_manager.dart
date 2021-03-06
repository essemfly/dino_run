import 'dart:math';
import 'dart:ui';

import 'package:dino_run/game/animals.dart';
import 'package:dino_run/game/savana_friends.dart';
import 'package:flame/components/component.dart';
import 'package:flame/components/mixins/has_game_ref.dart';
import 'package:flame/time.dart';

import 'audio_manager.dart';

class FriendsManager extends Component with HasGameRef<SavanaFriends> {
  Random _random;
  Timer _timer;
  int _spawnLevel;

  FriendsManager() {
    _random = Random();
    _spawnLevel = 0;
    _timer = Timer(4, repeat: true, callback: () {
      spawnRandomEnemy();
    });
  }

  void spawnRandomEnemy() {
    final randomNumber = _random.nextInt(AnimalType.values.length);
    final randomEnemyType = AnimalType.values.elementAt(randomNumber);
    final newEnemy = Animal(randomEnemyType);
    AudioManager.instance.playSfx('ES_Lion Roar Long - SFX Producer.mp3');
    gameRef.addLater(newEnemy);
  }

  @override
  void onMount() {
    super.onMount();
    _timer.start();
  }

  @override
  void render(Canvas c) {
    // TODO: implement render
  }

  @override
  void update(double t) {
    _timer.update(t);

    var newSpawnLevel = (gameRef.score ~/ 500);
    if (_spawnLevel < newSpawnLevel) {
      _spawnLevel = newSpawnLevel;

      var newWaitTime = (4 / (1 + (0.1 * _spawnLevel)));

      _timer.stop();
      _timer = Timer(newWaitTime, repeat: true, callback: () {
        spawnRandomEnemy();
      });
      _timer.start();
    }
  }

  void reset() {
    _spawnLevel = 0;
    _timer = Timer(4, repeat: true, callback: () {
      spawnRandomEnemy();
    });
    _timer.start();
  }
}
