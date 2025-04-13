import 'package:amazons_game/page/controller.dart';
import 'package:amazons_game/page/game_states.dart';
import 'package:amazons_game/page/global.dart';
import 'package:amazons_game/page/widgets/option_button.dart';
import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

class GamePage extends StatefulWidget {
  const GamePage({super.key});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> with SingleTickerProviderStateMixin {
  late final AnimationController throwAnimationController;
  late final Animation<double> throwAnimation;

  @override
  void initState() {
    throwAnimationController = AnimationController(
      vsync: this,
      duration: animationDuration,
    );
    throwAnimation = Tween(begin: 0.0, end: 1.0).animate(throwAnimationController);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    //this determines the size of a side, which will be the maximum between the height and width
    var maxSide = width < height ? width : height;
    maxSide *= 0.8;

    final cubeSide = maxSide / 10;

    return Scaffold(
      body: Row(children: [
        const Spacer(),
        BlocListener<GameController, GameState>(
          listener: (context, state) {
            if(state is GameOver){
              final controller = BlocProvider.of<GameController>(context);
              showDialog(
                barrierDismissible: false,
                context: context, 
                builder: (ctx){
                  return AlertDialog(
                    content: Text("Jugador ${state.winner} ha ganado!"),
                    actions: [TextButton(onPressed: (){
                      controller.resetGame();
                      Navigator.of(ctx).pop();
                    }, 
                    child: Text("Volver a jugar"))],
                  );
                }
              );
            }
          },
          child: BlocBuilder<GameController, GameState>(
            builder: (context, state) {
              //JUST IN CASE, IF AFTER A THROWN, THEN WE RESET THE ANIMATION FOR FURTHER USE
              if (state is PossibleAmazonsPlayState) {
                throwAnimationController.reset();
              }
              final gameController = BlocProvider.of<GameController>(context);
              //first dinamically create the stack children, in this case
              //the board, over that the amazons, and over that optionally the available moves
              //positions depending on the state
              final List<Widget> stackChildren = [
                Column(
                  children: getRows(cubeSide),
                ),
                ...getAmazonsPositions(state, cubeSide, gameController),
                ...getBarriers(state, cubeSide),
              ];
              //if we are in the just thrown barrir, we forward the animation
              if (state is JustThrowedState) {
                throwAnimationController.forward();
                stackChildren.add(AnimatedBuilder(
                    animation: throwAnimationController,
                    child: Icon(Icons.dangerous_outlined, color: const Color.fromARGB(255, 58, 22, 19), size: cubeSide),
                    builder: (ctx, child) {
                      final startX = state.thrownFrom.x * cubeSide;
                      final startY = state.thrownFrom.y * cubeSide;
                      final endX = state.thrownTo.x * cubeSide;
                      final endY = state.thrownTo.y * cubeSide;
                      return Positioned(
                        left: startX + (endX - startX) * throwAnimation.value,
                        top: startY + (endY - startY) * throwAnimation.value,
                        child: child!,
                      );
                    }));
              }

              if (state is PossibleAmazonMovesState || state is PossibleThrowsState) {
                List<Position> available = switch (state) {
                  PossibleAmazonMovesState() => state.available,
                  PossibleThrowsState() => state.available,
                  _ => []
                };
                stackChildren
                    .addAll(getAvailableMoves(available, gameController, cubeSide, state is PossibleThrowsState));
              }
              //when we have the stack completed, then we add it to the overall
              //column display, and dinamically we ask for the player
              final List<Widget> columnChildren = [
                const Spacer(),
                Text("El juego de las amazonas", style: TextStyle(fontSize: 20),),
                const Spacer(),
                Stack(children: stackChildren),
                Spacer(flex: state is GameInitialState ? 1:4,),
              ];
              if (state is GameInitialState) {
                columnChildren.addAll(getPlayerOptions(gameController));
              }

              return Column(children: columnChildren);
            },
          ),
        ),
        const Spacer(),
      ]),
    );
  }

  List<Widget> getPlayerOptions(GameController gameController) {
    return [
      Text("Quien va a iniciar?", style: TextStyle(fontSize: 20),),
      const Spacer(),
      Row(
        children: [
          OptionButton(
            callback: () => selectPlayer(gameController, 1), 
            text: "Jugador 1"
          ),
          OptionButton(
            callback: () => selectPlayer(gameController, 2), 
            text: "Jugador 2"
          ),
        ],
      ),
      const Spacer(flex: 5,),
    ];
  }

  void selectPlayer(GameController controller, int player) {
    controller.startPlay(player);
  }

  //for printing the dots of the available positions to moves
  List<Positioned> getAvailableMoves(
      List<Position> available, GameController controller, double cubeSide, bool throwing) {
    List<Positioned> positions = [];
    final side = cubeSide / 3;
    Widget child;
    //depending on if we are throwing or not, then the child will be an x or simply a dot
    if (throwing) {
      child = Icon(Icons.dangerous_outlined, color: const Color.fromARGB(115, 58, 22, 19), size: cubeSide);
    } else {
      child = Container(
        width: side,
        height: side,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), color: Colors.black),
      );
    }
    for (final pos in available) {
      //depending on if we are throwing or not we define the callbackl
      void Function() callback;
      if (throwing) {
        callback = () => controller.throwBarrier(pos);
      } else {
        callback = () => controller.moveAmazon(pos);
      }
      positions.add(Positioned(
          //formula is (X * side) + (side/2) to center - (half of the width/height, to have it perfectly centered)
          top: (pos.y * cubeSide),
          left: (pos.x * cubeSide),
          //MATERIAL FOR SHOWING THE WELL
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              splashColor: const Color.fromARGB(137, 244, 67, 54),
              onTap: callback,
              //SIZED BOX TO COVER ALL THE SQUARE IN THE TAP AND WELL
              child: SizedBox(
                width: cubeSide,
                height: cubeSide,
                //THE DOT
                child: Center(child: child),
              ),
            ),
          )));
    }
    return positions;
  }

  //IMPORTANT METHOD, FOR PRINTING THE BARRIERS
  List<Positioned> getBarriers(GameState state, double cubeSide) {
    List<Positioned> barriers = [];
    for (final barrier in state.barriers) {
      barriers.add(Positioned(
        top: barrier.y * cubeSide,
        left: barrier.x * cubeSide,
        child: Icon(Icons.dangerous_outlined, color: const Color.fromARGB(255, 58, 22, 19), size: cubeSide),
      ));
    }
    return barriers;
  }

  //IMPORTANT METHOD, FOR PRINTING THE AMAZONS
  List<AnimatedPositioned> getAmazonsPositions(GameState state, double cubeSide, GameController controller) {
    List<AnimatedPositioned> amazons = [];
    final bool checkingAvailable = state is PossibleAmazonsPlayState;

    //iterating over the amazons to print them with animated positions
    for (int i = 0; i < state.amazons.length; i++) {
      final amazon = state.amazons[i];

      //if we are in the already selected state or throw state, then we add the color hardcoded to the container
      bool selectedToMove = state is PossibleAmazonMovesState && state.selectedAmazon == i;
      selectedToMove = selectedToMove || (state is PossibleThrowsState && state.selectedAmazon == i);

      Container container = Container(
        width: cubeSide,
        height: cubeSide,
        decoration: BoxDecoration(
          color: selectedToMove ? Colors.red : Colors.transparent,
          image: DecorationImage(
            image: AssetImage(getAsset('player${amazon.player}.png')),
          ),
        ),
      );
      //if we are in the checking available state then we see if the current is available,
      //if its, then we wrrap the child container in an inkwell, also adding the color
      Widget child;
      if (checkingAvailable && state.availableAmazons.contains(i)) {
        child = Material(
          color: Colors.red,
          child: InkWell(
            splashColor: const Color.fromARGB(255, 78, 4, 4),
            onTap: () => controller.selectAmazon(i),
            child: container,
          ),
        );
      } else {
        child = container;
      }

      amazons.add(AnimatedPositioned(
          duration: animationDuration,
          top: amazon.position.y * cubeSide,
          left: amazon.position.x * cubeSide,
          child: child));
    }
    return amazons;
  }

  ////////////////////////////////

  List<Row> getRows(double cubeSide) {
    List<Row> rows = [];
    for (int i = 0; i < 10; i++) {
      rows.add(getRow(cubeSide, i % 2 == 0));
    }
    return rows;
  }

  Row getRow(double cubeSide, bool isEven) {
    List<Widget> row = [];
    final color1 = const Color.fromARGB(255, 252, 249, 244);
    final color2 = const Color.fromARGB(255, 228, 205, 167);
    for (int i = 0; i < 10; i++) {
      Color color;
      //if is even then we check a possibility, if not the inverse
      if (isEven) {
        color = i % 2 == 0 ? color2 : color1;
      } else {
        color = i % 2 == 0 ? color1 : color2;
      }
      row.add(Container(
        width: cubeSide,
        height: cubeSide,
        decoration: BoxDecoration(
            color: color, border: Border.all(color: Colors.black), borderRadius: BorderRadius.circular(5)),
      ));
    }
    return Row(
      children: row,
    );
  }
}
