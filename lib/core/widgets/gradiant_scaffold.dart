import 'package:flutter/material.dart';
import 'package:pampa/core/widgets/custom_header.dart';
import 'package:pampa/core/utils/functional_component.dart';
class GradiantScaffold extends StatelessWidget {
  final bool homeBack;
  final Widget? verticalWidget;
  final Widget? horiZontalWidget;
  final Widget body;
  final Widget? bottomNavigationBar ;
  final String title;
  final VoidCallback? callback;
  final int currentTab;

  const GradiantScaffold({
    super.key,
    this.homeBack = false,
    this.verticalWidget,
    this.bottomNavigationBar,
    this.callback,
    this.horiZontalWidget,
    required this.body,
    required this.title,
    this.currentTab = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      bottomNavigationBar:bottomNavigationBar ,
      floatingActionButton: callback!=null?FunctionalComponent.floatingActionButton(onTap:callback!):null,
      body: Column(
        children: [
          CustomHeader(
            title: title,
            homeBack: homeBack,
            horiZontalWidget: horiZontalWidget,
            verticalWidget: verticalWidget,
          ),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child:body ,
            ),
          ),
        ],
      ),
    );
  }
}
