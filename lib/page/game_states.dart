//states
abstract class GameState{
  final List<Amazon> amazons;
  final Set<Position> barriers;

  GameState(this.amazons, this.barriers);
}

//initial state, all amazons in initial positions, no barriers
class GameInitialState extends GameState{

  GameInitialState() : super(
    [Amazon(1, Position(0, 3)), Amazon(1,Position(3, 0)), Amazon(1,Position(6, 0)), Amazon(1,Position(9, 3)), 
     Amazon(2,Position(0, 6)), Amazon(2,Position(3, 9)), Amazon(2,Position(6, 9)), Amazon(2,Position(9, 6))], 
    {}
  );
}

//state for when a new turn started, it shows the 
class PossibleAmazonsPlayState extends GameState{
  final List<int> availableAmazons;
  PossibleAmazonsPlayState(super.amazons, super.barriers, this.availableAmazons);
}


//state for when an amazon is selected, so then it shows the available positions to move
class PossibleAmazonMovesState extends GameState{
  final List<Position> available;
  final int selectedAmazon;
  PossibleAmazonMovesState(super.amazons, super.barriers, this.available, this.selectedAmazon);
  
}

//class for normal state with amazons positioned
class PositionedAmazonsState extends GameState{
  PositionedAmazonsState(super.amazons, super.barrier);
}

//class for show available positions to throw barrier
class PossibleThrowsState extends GameState{
  final List<Position> available;
  final int selectedAmazon;
  PossibleThrowsState(super.amazons, super.barriers, this.available, this.selectedAmazon);
}

//class for when a barrier was just added, this is for being able to create the animation in the frontend
class JustThrowedState extends GameState{
  final Position thrownFrom;
  final Position thrownTo;
  JustThrowedState(super.amazons, super.barriers, this.thrownFrom, this.thrownTo);
}

//state for when someone won the game
class GameOver extends GameState{
  final int winner;
  GameOver(super.amazons, super.barriers, this.winner);
}

//models
class Amazon{
  int player;
  Position position;
  Amazon(this.player,this.position);
}


class Position{
  int x;
  int y;
  Position(this.x, this.y);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is Position && other.x == x && other.y == y);
  }

  @override
  int get hashCode => Object.hash(x, y);
}

