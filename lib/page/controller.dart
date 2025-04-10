import 'package:amazons_game/page/game_states.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class GameController extends Cubit<GameState>{

  int playerMove = 0;
  GameController(): super(GameInitialState());

  void startPlay(int player){
    playerMove = player;
    showPossiblePlays();
  }
  
  //method when a new turn is started, it shows the available amazons to select and move
  void showPossiblePlays(){
    final List<int> possibleMoves = [];
    for(int i = 0; i < state.amazons.length; i++){
      final amazon = state.amazons[i];
      if(amazon.player == playerMove && _ableToMove(i)){
        possibleMoves.add(i);
      }
    }
    emit(PossibleAmazonsPlayState(state.amazons, state.barriers, possibleMoves));
  }
  
  //method for when an amazon to move was selected
  void selectAmazon(int index)async{
    await Future.delayed(Duration(milliseconds: 500));
    final availableMoves = _getAvailableMovesForAmazon(index);
    emit(PossibleAmazonMovesState(state.amazons, state.barriers, availableMoves, index));
  }

  List<Position> _getAvailableMovesForAmazon(int index) {
    final List<Position> availableMoves = [];
    final amazon = state.amazons[index];
    final startPos = amazon.position;
    final allAmazonPositions = state.amazons.map((a) => a.position).toSet();

    const List<List<int>> directions = [
      [0, 1], 
      [0, -1],
      [1, 0], 
      [-1, 0],
      [1, 1], 
      [1, -1],
      [-1, 1],
      [-1, -1]
    ];

    for (final dir in directions) {
      final dx = dir[0];
      final dy = dir[1];

      for (int i = 1; ; i++) {
        final nextX = startPos.x + i * dx;
        final nextY = startPos.y + i * dy;
        final nextPos = Position(nextX, nextY);
        //check Board Boundaries
        if (nextX < 0 || nextX > 9 || nextY < 0 || nextY > 9) {
          break;
        }
        //check for Barriers
        if (state.barriers.contains(nextPos)) {
          break; 
        }
        //check for Other Amazons
        if (allAmazonPositions.contains(nextPos)) {
           break; 
        }
        availableMoves.add(nextPos);
      }
    }
    return availableMoves;
  }

  //internal method to check if a specific amazon is able to move
  bool _ableToMove(int index){
    final amazon = state.amazons[index];
    //inner function to check if the amazon can move
    checkPosition(int x, int y){
      if(x < 0 || x > 9 || y < 0 || y > 9) {
        return false;
      } else if(state.barriers.contains(Position(x, y))) {
        return false;
      }
      return true;
    }
    
    bool ableToMove = false;
    ableToMove = ableToMove || checkPosition(amazon.position.x + 1, amazon.position.y);
    ableToMove = ableToMove || checkPosition(amazon.position.x - 1, amazon.position.y);
    ableToMove = ableToMove || checkPosition(amazon.position.x, amazon.position.y + 1);
    ableToMove = ableToMove || checkPosition(amazon.position.x, amazon.position.y - 1);
    return ableToMove;
  }

}


