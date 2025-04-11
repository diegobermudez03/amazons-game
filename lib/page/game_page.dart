import 'package:amazons_game/page/controller.dart';
import 'package:amazons_game/page/game_states.dart';
import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';


class GamePage extends StatelessWidget{
  const GamePage({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    //this determines the size of a side, which will be the maximum between the height and width
    var maxSide = width < height ? width : height;
    maxSide *= 0.8;

    final cubeSide = maxSide / 10;
    
    return Scaffold(
      body: Row(
        children: [
          const Spacer(),
          BlocBuilder<GameController, GameState>(
            builder: (context, state) {
              final gameController = BlocProvider.of<GameController>(context);
              //first dinamically create the stack children, in this case
              //the board, over that the amazons, and over that optionally the available moves
              //positions depending on the state
              final List<Widget> stackChildren = [
                 Column(
                    children: getRows(cubeSide),
                  ),
                  ...getAmazonsPositions(state, cubeSide, gameController)
              ];
              if(state is PossibleAmazonMovesState || state is PossibleThrowsState){
                List<Position> available = switch(state) {
                  PossibleAmazonMovesState() => state.available,
                  PossibleThrowsState() => state.available,
                  _ => []
                };
                stackChildren.addAll( getAvailableMoves(available, gameController, cubeSide, state is PossibleThrowsState));
              }
              //when we have the stack completed, then we add it to the overall
              //column display, and dinamically we ask for the player
              final List<Widget> columnChildren = [
                 Text("El juego de las amazonas"),
                  Stack(
                    children: stackChildren
                  ),
              ];
              if(state is GameInitialState){
                columnChildren.addAll(getPlayerOptions(gameController));
              }
              return Column(
                children: columnChildren
              );
            },
          ),
          const Spacer(),
        ]
      ),
    );
  }

  List<Widget> getPlayerOptions(GameController gameController) {
    return [
      Text("Quien va a iniciar?"),
      Row(
      children: [
        ElevatedButton(
          onPressed: ()=>selectPlayer(gameController, 1), 
          child: Text("Jugador 1"),
        ),
        ElevatedButton(
          onPressed: ()=>selectPlayer(gameController, 2), 
          child: Text("Jugador 2 (Futuro bot)"),
        )
      ],
    )];
  }

  void selectPlayer(GameController controller, int player){
    controller.startPlay(player);
  }   

  
  //for printing the dots of the available positions to moves
  List<Positioned> getAvailableMoves(List<Position> available, GameController controller, double cubeSide, bool throwing){
    List<Positioned> positions = [];
    final side = cubeSide/3;
    Widget child;
    //depending on if we are throwing or not, then the child will be an x or simply a dot
    if(throwing){
      child = Icon(Icons.dangerous_outlined, color: const Color.fromARGB(115, 58, 22, 19), size: cubeSide);
    }else{
      child =  Container(
        width: side,
        height: side,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.black
        ),
      );
    }
    for(final pos in available){
      //depending on if we are throwing or not we define the callbackl
      void Function() callback;
      if(throwing){
        callback = (){};
      }else{
        callback = ()=>controller.moveAmazon(pos);
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
              child: Center(
                child: child
              ),
            ),
          ),
        )
      ));
    }
    return positions;
  }


  //IMPORTANT METHOD, FOR PRINTING THE AMAZONS
  List<AnimatedPositioned> getAmazonsPositions(GameState state, double cubeSide, GameController controller){
    List<AnimatedPositioned> amazons = [];
    final bool checkingAvailable = state is PossibleAmazonsPlayState;
  
    //iterating over the amazons to print them with animated positions
    for(int i = 0; i < state.amazons.length; i++){
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
              image: AssetImage('player${amazon.player}.png'),
            ),
          ),
      );
      //if we are in the checking available state then we see if the current is available,
      //if its, then we wrrap the child container in an inkwell, also adding the color
      Widget child;
      if(checkingAvailable && state.available.contains(i)){
        child = Material(
          color: Colors.red,
          child: InkWell(
            splashColor: const Color.fromARGB(255, 78, 4, 4),
            onTap: ()=>controller.selectAmazon(i),
            child: container,
          ),
        );
      }else{
        child = container;
      }
      
      amazons.add(AnimatedPositioned(
        duration: Duration(seconds: 1),
        top: amazon.position.y * cubeSide,
        left: amazon.position.x * cubeSide,
        child: child
      ));
    }
    return amazons;
  }




  //METHODS FOR PRINTING THE BOARD
  ////////////////////////////////
   
  
  List<Row> getRows(double cubeSide){
    List<Row> rows = [];
    for(int i = 0; i < 10; i++){
      rows.add(getRow(cubeSide, i % 2 == 0));
    }
    return rows;
  }

  Row getRow(double cubeSide, bool isEven){
    List<Widget> row = [];
    final color1 = const Color.fromARGB(255, 255, 233, 194);
    final color2 = const Color.fromARGB(255, 172, 139, 83);
    for(int i = 0; i < 10; i++){
      Color color;
      //if is even then we check a possibility, if not the inverse
      if(isEven) {
        color = i % 2 == 0 ? color2 : color1;
      } else {
        color = i % 2 == 0 ? color1 : color2;
      }
      row.add(Container(
        width: cubeSide,
        height: cubeSide,
        decoration: BoxDecoration(
          color: color,
          border: Border.all(color: Colors.black),
          borderRadius: BorderRadius.circular(5)
        ),
      ));
    }
    return Row(children: row,);
  }

}