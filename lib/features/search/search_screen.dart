import 'package:flutter/material.dart';

import '../../app/aura_controller.dart';
import '../catalog/catalog_screen.dart';
import '../youtube/online_search_screen.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key, required this.controller});
  final AuraController controller;
  @override
  Widget build(BuildContext context) => controller.artistDirectory == null
      ? OnlineSearchScreen(controller: controller, showLocalLink: false)
      : CatalogSearchScreen(controller: controller);
}
