import 'package:amazons_game/page/game_states.dart';
import 'package:amazons_game/page/global.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// Helper class for the bot's decision making
class BotMove {
  final int amazonIndex;
  final Position amazonMovePos;
  final Position arrowShotPos;
  double score;

  BotMove(this.amazonIndex, this.amazonMovePos, this.arrowShotPos, {this.score = 0.0});
}
class GameController extends Cubit<GameState>{

  int playerMove = 0;
  int bot = 0;
  GameController(): super(GameInitialState());

  void startPlay(int player){
    bot = player == 1 ? 2 : 1;
    playerMove = 1;
    _nextPlay();
  }

  //method for when the game is reseted
  void resetGame(){
    emit(GameInitialState());
    playerMove = 0;
  }

  //method for when a position is selected to throw a barrier
  void throwBarrier(Position pos)async{
    final amazonIndex = (state as PossibleThrowsState).selectedAmazon;
    final initialPos = state.amazons[amazonIndex].position;
    emit(JustThrowedState(state.amazons, state.barriers, initialPos, pos));
    //allow the frontend to reproduce the animation
    await Future.delayed(animationDuration);
    state.barriers.add(pos);
    //change player turn
    playerMove = playerMove == 1 ? 2 : 1;
    //here we move to the next player turn
    _nextPlay();
  }

  //method to move the amazon to the selected position
  void moveAmazon(Position position) async{
    final selectedAmazon = (state as PossibleAmazonMovesState).selectedAmazon;
    state.amazons[selectedAmazon].position = position;
    emit(PositionedAmazonsState(state.amazons, state.barriers));
    //wait for animation to show the movement
    await Future.delayed(animationDuration);
    final possibleThrows = _getAvailablePositions(position, _getOccupiedPositions());
    emit(PossibleThrowsState(state.amazons, state.barriers, possibleThrows, selectedAmazon));
  }
  
  //method when a new turn is started, it shows the available amazons to select and move
  void showPossiblePlays(){
    final List<int> possibleAmazons = [];
    for(int i = 0; i < state.amazons.length; i++){
      final amazon = state.amazons[i];
      if(amazon.player == playerMove && _ableToMove(i)){
        possibleAmazons.add(i);
      }
    }
    //if no possible amazons to move, then the game is over, we declare the winner as the opponent
    if(possibleAmazons.isEmpty){
      int winner = playerMove == 1 ? 2 : 1;
      emit(GameOver(state.amazons, state.barriers, winner));
      return;
    }
    emit(PossibleAmazonsPlayState(state.amazons, state.barriers, possibleAmazons));
  }
  
  //method for when an amazon to move was selected
  void selectAmazon(int index)async{
    await Future.delayed(Duration(milliseconds: 500));
    final amazon = state.amazons[index];
    final availableMoves = _getAvailablePositions(amazon.position, _getOccupiedPositions());
    emit(PossibleAmazonMovesState(state.amazons, state.barriers, availableMoves, index));
  }

  //to get all the occupied positions by either amazons or barriers
  Set<Position> _getOccupiedPositions(){
    final Set<Position> occupied = state.amazons.map((a)=>a.position).toSet();
    occupied.addAll(state.barriers);
    return occupied;
  }

  //function to get available positions based on an starting one, either for amazons or barriers
  List<Position> _getAvailablePositions(Position position, Set<Position> nonAvailable) {
    final List<Position> availablePositions = [];
    const List<List<int>> directions = [
      [0, 1], [0, -1], [1, 0], [-1, 0], [1, 1], 
      [1, -1], [-1, 1], [-1, -1]
    ];
    for (final dir in directions) {
      final dx = dir[0];
      final dy = dir[1];
      for (int i = 1; ; i++) {
        final nextX = position.x + i * dx;
        final nextY = position.y + i * dy;
        final nextPos = Position(nextX, nextY);
        //check Board Boundaries
        if (nextX < 0 || nextX > 9 || nextY < 0 || nextY > 9) {
          break;
        }
        //check for Barriers
        if (nonAvailable.contains(nextPos)) {
          break; 
        }
        availablePositions.add(nextPos);
      }
    }
    return availablePositions;
  }

  //internal method to check if a specific amazon is able to move
  bool _ableToMove(int index){
    // Corrected: An amazon is able to move if _getAvailablePositions returns any valid moves.
    // _getOccupiedPositions() correctly provides all amazons and barriers as obstacles.
    final amazon = state.amazons[index];
    return _getAvailablePositions(amazon.position, _getOccupiedPositions()).isNotEmpty;
  }

  // Helper for deep copying amazons
  List<Amazon> _cloneAmazons(List<Amazon> amazons) {
    return amazons.map((a) => Amazon(a.player, Position(a.position.x, a.position.y))).toList();
  }

  // Helper for deep copying barriers
  Set<Position> _cloneBarriers(Set<Position> barriers) {
    return barriers.map((p) => Position(p.x, p.y)).toSet();
  }

  /*
    METHOD FOR EVALUATING THE SCORE OF A GIVEN STATE
  */
  double _evaluateBoardState(List<Amazon> amazons, Set<Position> barriers) {
    double botPlayerMobility = 0;
    double opponentPlayerMobility = 0;

    final Set<Position> occupiedPositions = _cloneBarriers(barriers);
    for (final amazon in amazons) {
      occupiedPositions.add(amazon.position);
    }

    //iterate over all amazons, and get the possible moves of each one, then sum with the corresponding player
    for (int i = 0; i < amazons.length; i++) {
      final amazon = amazons[i];
      // Pass the cloned occupiedPositions which includes all pieces for accurate mobility check
      final List<Position> moves = _getAvailablePositions(amazon.position, occupiedPositions);
      if (amazon.player == bot) {
        botPlayerMobility += moves.length;
      } else {
        opponentPlayerMobility += moves.length;
      }
    }

    //heuristic is BOT MOVEMENTS - PLAYER MOVEMENTS. the more movements the bot has and the less the player has, the best
    return botPlayerMobility - opponentPlayerMobility;
  }


  /*
    ALGORITHM METHOD
  */
  Future<BotMove?> _findBestBotMove() async {
    BotMove? bestMoveFound;
    //define the initial scroe value
    double maxScore = double.negativeInfinity;
    

    //extract the amazons of the bot
    final List<int> botAmazonIndices = [];
    for (int i = 0; i < state.amazons.length; i++) {
      if (state.amazons[i].player == bot) {
        botAmazonIndices.add(i);
      }
    }

    if (botAmazonIndices.isEmpty) return null;

    //HERE WE ITERATE OVER all possible amazons and simulate their shots
    for (final amazonIdx in botAmazonIndices) {
      final currentAmazon = state.amazons[amazonIdx];
      final occupiedForAmazonMove = _getOccupiedPositions(); 
      //we obtain all possible moves for the current amazon
      final List<Position> possibleMovesForAmazon = _getAvailablePositions(currentAmazon.position, occupiedForAmazonMove);
      //here we iterate over all possible moves of the given amazon

      for (final newAmazonPos in possibleMovesForAmazon) {
        List<Amazon> amazonsAfterMove = _cloneAmazons(state.amazons);
        amazonsAfterMove[amazonIdx].position = Position(newAmazonPos.x, newAmazonPos.y);
        Set<Position> barriersForShotSim = _cloneBarriers(state.barriers);
        // Calculate occupied positions for the arrow shot
        final Set<Position> occupiedForShot = _cloneBarriers(barriersForShotSim);
        for (final amz in amazonsAfterMove) {
          occupiedForShot.add(amz.position); // Includes the moved amazon at its new spot
        }
        //we get the available shot positions from the amazons simulated position
        final List<Position> possibleShots = _getAvailablePositions(newAmazonPos, occupiedForShot);
        // An arrow shot is mandatory. If no shots are possible from newAmazonPos, this move is invalid.
        if (possibleShots.isEmpty) continue; 
        //we evaluate all possible shots if moved the amazon on this position
        
        for (final shotPos in possibleShots) {
          // Simulate the shot by creating the board state *after* this shot
          Set<Position> barriersAfterShot = _cloneBarriers(barriersForShotSim);
          barriersAfterShot.add(Position(shotPos.x, shotPos.y));
          //get the score if this exact move (amazon, position, and thrown) is done
          double currentScore = _evaluateBoardState(amazonsAfterMove, barriersAfterShot);
          //update if this has best score than the already had
          if (currentScore > maxScore) {
            maxScore = currentScore;
            bestMoveFound = BotMove(amazonIdx, newAmazonPos, shotPos, score: currentScore);
          }
        }
      }
    }
    return bestMoveFound;
  }


  void _nextPlay() async {
    //if the next play is not the bots one, then we continue with the normal player flow
    if(playerMove != bot){
      showPossiblePlays();
      return;
    }
    //we emit this state only to reset animations
    emit(PossibleAmazonsPlayState(_cloneAmazons(state.amazons), _cloneBarriers(state.barriers), []));
    await Future.delayed(animationDuration); 

    //////////////////////////////////////////////////////////////////////////////////////////
    //THIS IS WHERE WE CALL THE FIND BEST BOT MOVE, HERE WE DECIDE WHAT TO MOVE (ALGORITHM)
    final BotMove? bestBotMove = await _findBestBotMove();
    //////////////////////////////////////////////////////////////////////////////////////////

    //if no bot move was returned, means the bot lost
    if (bestBotMove == null) {
      int winner = playerMove == 1 ? 2 : 1; // Opponent wins
      emit(GameOver(_cloneAmazons(state.amazons), _cloneBarriers(state.barriers), winner));
      return;
    }

    //extract bot moves attributes
    final selectedAmazonIndex = bestBotMove.amazonIndex;
    final amazonTargetPos = bestBotMove.amazonMovePos;
    final shotTargetPos = bestBotMove.arrowShotPos;

    //we move the amazon and emit the new state with the amazon moved
    state.amazons[selectedAmazonIndex].position = Position(amazonTargetPos.x, amazonTargetPos.y);
    emit(PositionedAmazonsState(_cloneAmazons(state.amazons), _cloneBarriers(state.barriers)));
    await Future.delayed(animationDuration);
   
    //just to simulate thinking of what to throw, and after that we emit the state and add the barrier to the state
    emit(PossibleThrowsState(_cloneAmazons(state.amazons), _cloneBarriers(state.barriers), [], selectedAmazonIndex));
    await Future.delayed(Duration(seconds: 1)); 
    emit(JustThrowedState(_cloneAmazons(state.amazons), _cloneBarriers(state.barriers), Position(amazonTargetPos.x, amazonTargetPos.y), Position(shotTargetPos.x, shotTargetPos.y)));
    await Future.delayed(Duration(seconds: 1)); 
    state.barriers.add(Position(shotTargetPos.x, shotTargetPos.y)); 

    // Change player turn
    playerMove = playerMove == 1 ? 2 : 1;
    _nextPlay(); 
  }

}
