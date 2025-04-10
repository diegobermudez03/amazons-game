import 'package:flutter_bloc/flutter_bloc.dart';

class GameController extends Cubit<GameState>{

  GameController(): super(GameInitialState());

}


//states
abstract class GameState{
  final List<Amazon> amazons;

  GameState(this.amazons);
}

class GameInitialState extends GameState{

  GameInitialState() : super(
    [Amazon(1,0, 3), Amazon(1,3, 0), Amazon(1,6, 0), Amazon(1,9, 3), 
     Amazon(2,0, 6), Amazon(2,3, 9), Amazon(2,6, 9), Amazon(2,9, 6)], 
  );
}


//models
class Amazon{
  int player;
  int x;
  int y;
  Amazon(this.player,this.x, this.y);
}

