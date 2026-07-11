import os, re
def remove_unused():
    # 1. notification_service.dart
    path1 = r'lib\features\study_session\application\notification_service.dart'
    if os.path.exists(path1):
        with open(path1, 'r', encoding='utf-8') as f:
            c1 = f.read()
        c1 = re.sub(r"import 'dart:math';\n?", '', c1)
        c1 = re.sub(r"import 'package:flutter/material\.dart';\n?", '', c1)
        with open(path1, 'w', encoding='utf-8') as f:
            f.write(c1)
            
    # 2. topic_controller.dart
    path2 = r'lib\features\study_session\application\topic_controller.dart'
    if os.path.exists(path2):
        with open(path2, 'r', encoding='utf-8') as f:
            c2 = f.read()
        c2 = re.sub(r"import '../../study_session/application/arena_providers\.dart';\n?", '', c2)
        with open(path2, 'w', encoding='utf-8') as f:
            f.write(c2)

    # 3. arena_tab_screen.dart
    path3 = r'lib\features\study_session\presentation\screens\arena_tab_screen.dart'
    if os.path.exists(path3):
        with open(path3, 'r', encoding='utf-8') as f:
            c3 = f.read()
        c3 = re.sub(r"import '../../../../core/providers/database_provider\.dart';\n?", '', c3)
        c3 = re.sub(r"import '../../../../core/providers/sync_provider\.dart';\n?", '', c3)
        c3 = re.sub(r"import '../../../../core/providers/auth_provider\.dart';\n?", '', c3)
        c3 = re.sub(r"import 'package:isar_community/isar\.dart';\n?", '', c3)
        c3 = re.sub(r"import '../../domain/topic\.dart';\n?", '', c3)
        
        # Remove unused _promoteTopic and _demoteTopic
        c3 = re.sub(r'  Future<void> _promoteTopic.*?undoMove.*?\}\n', '', c3, flags=re.DOTALL)
        c3 = re.sub(r'  Future<void> _demoteTopic.*?undoMove.*?\}\n', '', c3, flags=re.DOTALL)
        
        # Remove unused key parameter from _ArenaTopicTile
        c3 = re.sub(r'const _ArenaTopicTile\(\{(?:[\s\S]*?)super\.key,\s*', 'const _ArenaTopicTile({', c3)
        c3 = re.sub(r'const _SettingsSheet\(\{super\.key\}\);', 'const _SettingsSheet();', c3)

        with open(path3, 'w', encoding='utf-8') as f:
            f.write(c3)

    # 4. topic_box_move_screen.dart
    path4 = r'lib\features\study_session\presentation\screens\topic_box_move_screen.dart'
    if os.path.exists(path4):
        with open(path4, 'r', encoding='utf-8') as f:
            c4 = f.read()
        c4 = re.sub(r'\s*late final Animation<double> _scaleIn;\s*', '\n', c4)
        c4 = re.sub(r'\s*_scaleIn = Tween<double>\(.*?;\s*', '\n', c4, flags=re.DOTALL)
        c4 = re.sub(r"import 'dart:ui';\n?", '', c4)
        with open(path4, 'w', encoding='utf-8') as f:
            f.write(c4)

    # 5. topic_study_screen.dart
    path5 = r'lib\features\study_session\presentation\screens\topic_study_screen.dart'
    if os.path.exists(path5):
        with open(path5, 'r', encoding='utf-8') as f:
            c5 = f.read()
        c5 = re.sub(r"import 'dart:ui';\n?", '', c5)
        with open(path5, 'w', encoding='utf-8') as f:
            f.write(c5)

    # 6. vault_screen.dart
    path6 = r'lib\features\vault\presentation\screens\vault_screen.dart'
    if os.path.exists(path6):
        with open(path6, 'r', encoding='utf-8') as f:
            c6 = f.read()
        c6 = re.sub(r"import 'dart:ui';\n?", '', c6)
        with open(path6, 'w', encoding='utf-8') as f:
            f.write(c6)

remove_unused()
