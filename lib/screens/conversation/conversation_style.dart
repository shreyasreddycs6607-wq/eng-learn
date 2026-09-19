import 'package:flutter/material.dart';
import '../../models/conversation.dart';

/// Icon and colour for each Real-Life Practice situation, shared by the list
/// and the conversation itself so a situation always looks the same.
class ConversationStyle {
  final IconData icon;
  final Color foreground;
  final Color background;

  const ConversationStyle(this.icon, this.foreground, this.background);

  static const _styles = {
    ConversationCategory.home: ConversationStyle(Icons.home_rounded, Color(0xFF0E6B5C), Color(0xFFDDF0EC)),
    ConversationCategory.family: ConversationStyle(Icons.family_restroom_rounded, Color(0xFFC8456B), Color(0xFFFDE7EC)),
    ConversationCategory.shopping: ConversationStyle(Icons.shopping_basket_rounded, Color(0xFFB9770E), Color(0xFFFFF0D6)),
    ConversationCategory.phone: ConversationStyle(Icons.phone_in_talk_rounded, Color(0xFF4453B8), Color(0xFFE6E9FB)),
    ConversationCategory.travel: ConversationStyle(Icons.directions_bus_rounded, Color(0xFF1F7AA8), Color(0xFFE0F1FA)),
    ConversationCategory.doctor: ConversationStyle(Icons.local_hospital_rounded, Color(0xFFC93B3B), Color(0xFFFBE7E7)),
    ConversationCategory.neighbour: ConversationStyle(Icons.waving_hand_rounded, Color(0xFF7A4BB0), Color(0xFFEFE6F7)),
    ConversationCategory.food: ConversationStyle(Icons.restaurant_rounded, Color(0xFFD2601A), Color(0xFFFFE9DC)),
  };

  static ConversationStyle of(ConversationCategory category) => _styles[category]!;
}
