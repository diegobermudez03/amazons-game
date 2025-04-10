import 'package:amazons_game/page/controller.dart';
import 'package:flutter/material.dart';
import 'dart:math';

import 'package:flutter_bloc/flutter_bloc.dart';


class GamePage extends StatelessWidget{

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
              return Column(
                children: [
                  Text("El juego de las amazonas"),
                  Stack(
                    children: [
                      Column(
                        children: getRows(cubeSide),
                      ),
                      ...getAmazonsPositions(state, cubeSide)
                    ],
                  )
                ],
              );
            },
          ),
          const Spacer(),
        ]
      ),
    );
  }

  List<Positioned> getAmazonsPositions(GameState state, double cubeSide){
    List<Positioned> amazons = [];
    for(final amazon in state.amazons){
      amazons.add(Positioned(
        top: amazon.y * cubeSide,
        left: amazon.x * cubeSide,
        child: Container(
          width: cubeSide,
          height: cubeSide,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage('player${amazon.player}.png')
            ),
          ),
        )
      ));
    }
    return amazons;
  }

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