library dashboard;

import 'dart:developer';

import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:final_assignment_front/constans/app_constants.dart';
import 'package:final_assignment_front/shared_components/chatting_card.dart';
import 'package:final_assignment_front/shared_components/police_card.dart';
import 'package:final_assignment_front/shared_components/list_profil_image.dart';
import 'package:final_assignment_front/shared_components/add_car_card.dart';
import 'package:final_assignment_front/shared_components/progress_report_card.dart';
import 'package:final_assignment_front/shared_components/project_card.dart';
import 'package:final_assignment_front/shared_components/responsive_builder.dart';
import 'package:final_assignment_front/shared_components/search_field.dart';
import 'package:final_assignment_front/shared_components/selection_button.dart';
import 'package:final_assignment_front/shared_components/case_card.dart';
import 'package:final_assignment_front/shared_components/today_text.dart';
import 'package:final_assignment_front/shared_components/post_card.dart';
import 'package:final_assignment_front/utils/helpers/app_helpers.dart';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'manager_dashboard_screen.dart';

// binding
part '../../bindings/dashboard_binding.dart';

// controller
part '../../controllers/manager_dashboard_controller.dart';

// models
part '../../models/profile.dart';

// component
part '../components/active_project_card.dart';
part '../components/header.dart';
part '../components/overview_header.dart';
part '../components/profile_tile.dart';
part '../components/recent_messages.dart';
part '../components/sidebar.dart';
part '../components/team_member.dart';


class UserDashboardScreen extends GetView<UserDashboardController> {
  const DashboardScreen({super.key});
}