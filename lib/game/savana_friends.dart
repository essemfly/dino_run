import 'dart:ui';

import 'package:dino_run/game/audio_manager.dart';
import 'package:dino_run/game/constant.dart';
import 'package:dino_run/game/friends_manager.dart';
import 'package:dino_run/game/kid.dart';
import 'package:dino_run/widgets/friends_game_over_menu.dart';
import 'package:dino_run/widgets/hud_friends.dart';
import 'package:dino_run/widgets/pause_menu.dart';
import 'package:flame/components/parallax_component.dart';
import 'package:flame/components/text_component.dart';
import 'package:flame/game.dart';
import 'package:flame/game/base_game.dart';
import 'package:flame/gestures.dart';
import 'package:flame/position.dart';
import 'package:flame/text_config.dart';
import 'package:flutter/material.dart';

import 'animals.dart';

class SavanaFriends extends BaseGame with TapDetector, HasWidgetsOverlay {
  Kid _kid;
  double _elapsedTime = 0.0;
  ParallaxComponent _parallaxComponent;
  int score;
  TextComponent scoreText;
  FriendsManager _friendManager;
  bool _isGameOver = false;
  bool _isGamePaused = false;
  double tileSize;

  SavanaFriends();

  void start() {
    _parallaxComponent = ParallaxComponent([
      ParallaxImage('background/bg.png'),
      ParallaxImage('background/hills@3x 1.png', fill: LayerFill.none),
      ParallaxImage('background/cloud@3x 1.png',
          alignment: Alignment(-0.8, -1.0), fill: LayerFill.none),
      ParallaxImage('background/cloud@3x 2.png',
          alignment: Alignment(0.3, -0.9), fill: LayerFill.none),
      ParallaxImage('background/trees@3x 1.png', fill: LayerFill.none),
      ParallaxImage('background/land.png', fill: LayerFill.none),
    ], baseSpeed: Offset(50, 0), layerDelta: Offset(25, 0));

    add(_parallaxComponent);
    _kid = Kid();
    add(_kid);

    _friendManager = FriendsManager();
    add(_friendManager);

    score = 0;
    scoreText = TextComponent(score.toString(),
        config: TextConfig(
            fontSize: 40, fontFamily: 'Audiowide', color: Colors.white));
    add(scoreText);

    addWidgetOverlay('HudFriends', HUDFriends(onPausePressed: pauseGame));

    AudioManager.instance.startBgm('8Bit Platformer Loop.wav');
  }

  @override
  void resize(Size size) {
    super.resize(size);
    this.tileSize = size.width / numberOfTilesAlongWidth;
    scoreText
        .setByPosition(Position((size.width / 2) - (scoreText.width / 2), 0));
  }

  @override
  void onTapDown(TapDownDetails details) {
    super.onTapDown(details);
    if (!_isGameOver && !_isGamePaused) {
      bool animalClicked = false;
      components.whereType<Animal>().forEach((animal) async {
        if (animal.toRect().contains(details.globalPosition)) {
          animalClicked = true;
          if (animal.status == AnimalStatus.Rushing) {
            animal.jump();
          } else {
            for (final animal in components.whereType<Animal>()) {
              await Future.delayed(Duration(milliseconds: 40));
              if (animal.status == AnimalStatus.Following) {
                animal.jump();
              }
            }
          }
        }
      });

      if (!animalClicked) {
        _kid.jump();
      }
    }
  }

  @override
  void update(double t) {
    super.update(t);

    if (this.score < 10) {
      components.whereType<Animal>().forEach((animal) {
        if (animal.status == AnimalStatus.Rushing) {
          if (_kid.distance(animal) < 70) {
            this.score += 1;
            scoreText.text = this.score.toString();

            _kid.moveLocation(_kid.x + this.tileSize / 2);
            animal.moveLocation(_kid.x - this.tileSize / 1.8);
          }
        }
      });
    } else {
      _elapsedTime += t;
      if (_elapsedTime > 5) {
        this.gameOver();
      }
    }
  }

  @override
  void lifecycleStateChange(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        break;
      case AppLifecycleState.inactive:
        this.pauseGame();
        break;
      case AppLifecycleState.paused:
        this.pauseGame();
        break;
      case AppLifecycleState.detached:
        this.pauseGame();
        break;
    }
  }

  void pauseGame() {
    pauseEngine();
    if (!_isGameOver) {
      _isGamePaused = true;
      addWidgetOverlay('PauseMenu', PauseMenu(onResumePressed: resumeGame));
      AudioManager.instance.pauseBgm();
    }
  }

  void resumeGame() {
    removeWidgetOverlay('PauseMenu');
    resumeEngine();
    AudioManager.instance.resumeBgm();
    _isGamePaused = false;
  }

  void gameOver() {
    _isGameOver = true;
    pauseEngine();
    var summarize = "";
    var animal_counts = {
      'rabbit': 0,
      'elephant': 0,
      'lion': 0,
      'giraffe': 0,
      'deer': 0,
      'bear': 0,
    };
    components.whereType<Animal>().forEach((animal) {
      AnimalType animalType = animal.getAnimalType();
      if (animalType == AnimalType.Rabbit) {
        animal_counts['rabbit'] += 1;
      }
      if (animalType == AnimalType.Elephant) {
        animal_counts['elephant'] += 1;
      }
      if (animalType == AnimalType.Lion) {
        animal_counts['lion'] += 1;
      }
      if (animalType == AnimalType.Giraffe) {
        animal_counts['giraffe'] += 1;
      }
      if (animalType == AnimalType.Bear) {
        animal_counts['bear'] += 1;
      }
      if (animalType == AnimalType.Deer) {
        animal_counts['deer'] += 1;
      }
    });

    animal_counts.forEach((key, value) {
      if (value > 1) {
        summarize += "$value ${key}s, ";
      } else if (value == 1) {
        summarize += "$value $key, ";
      }
    });

    addWidgetOverlay('GameOverMenu',
        FriendsGameOverMenu(score: summarize, onRestartPressed: reset));
    AudioManager.instance.pauseBgm();
  }

  void reset() {
    this.score = 0;
    _kid.moveLocation(this.tileSize * 1.5);
    _kid.run();
    _friendManager.reset();

    components.whereType<Animal>().forEach((animal) {
      this.markToRemove(animal);
    });

    removeWidgetOverlay('GameOverMenu');
    resumeEngine();
    AudioManager.instance.resumeBgm();
    _isGameOver = false;
  }

  @override
  void onDetach() {
    AudioManager.instance.stopBgm();
    super.onDetach();
  }
}
