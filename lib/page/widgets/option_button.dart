import 'package:flutter/material.dart';

class OptionButton extends StatelessWidget{

  final void Function() callback;
  final String text;

  const OptionButton({
    super.key, 
    required this.callback,
    required this.text
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal:  8.0),
      child: ElevatedButton(
       onPressed: callback,
       style: ButtonStyle(
        backgroundColor: WidgetStatePropertyAll(Colors.blueGrey[600]),
       ),
      child: Text(text,style: TextStyle(color: Colors.white, fontSize: 18),),
      ),
    );
  }
}