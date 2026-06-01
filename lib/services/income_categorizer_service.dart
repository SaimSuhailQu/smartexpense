import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class IncomeCategorizerService with ChangeNotifier {
  final Map<String, List<String>> _categories = {};
  final List<String> _personNames = [];
  
  static const String _categoriesKey = 'income_categories_data';
  static const String _personNamesKey = 'income_person_names_data';
  
  IncomeCategorizerService() {
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load categories
      final categoriesJson = prefs.getString(_categoriesKey);
      if (categoriesJson != null) {
        final categoriesData = json.decode(categoriesJson) as Map<String, dynamic>;
        _categories.clear();
        for (var entry in categoriesData.entries) {
          _categories[entry.key] = List<String>.from(entry.value);
        }
      } else {
        _setDefaultCategories();
      }
      
      // Load person names
      final personNamesJson = prefs.getString(_personNamesKey);
      if (personNamesJson != null) {
        final personNamesData = json.decode(personNamesJson) as List<dynamic>;
        _personNames.clear();
        _personNames.addAll(List<String>.from(personNamesData));
      } else {
        _setDefaultPersonNames();
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading income categories data: $e');
      _setDefaultCategories();
      _setDefaultPersonNames();
      notifyListeners();
    }
  }

  Future<void> _saveData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final categoriesJson = json.encode(_categories);
      await prefs.setString(_categoriesKey, categoriesJson);

      final personNamesJson = json.encode(_personNames);
      await prefs.setString(_personNamesKey, personNamesJson);

    } catch (e) {
      debugPrint('Error saving income categories data: $e');
    }
  }

  void _setDefaultCategories() {
    _categories.clear();
    _categories.addAll({
      'Salary': ['salary', 'paycheck'],
      'Committee': ['committee', 'kmiti'],
      'Freelance': ['freelance', 'contract'],
      'Other': [],
    });
  }

  void _setDefaultPersonNames() {
    _personNames.clear();
    _personNames.addAll([
      'saim', 'shamikh', 'suhail', 'shoaib', 'mother', 'sister', 'baji', 'father', 'brother', 'mom', 'dad', 'uncle', 'aunt'
    ]);
  }

  String categorizeIncome(String description) {
    final descLower = description.toLowerCase();

    for (var personName in _personNames) {
      if (descLower.contains(personName)) {
        return personName[0].toUpperCase() + personName.substring(1);
      }
    }
    
    for (var category in _categories.entries) {
      for (var keyword in category.value) {
        if (descLower.contains(keyword)) {
          return category.key;
        }
      }
    }
    
    return 'Uncategorized';
  }

  bool shouldCreateNewCategory(String description) {
    final descLower = description.toLowerCase();
    
    for (var personName in _personNames) {
      if (descLower.contains(personName) && 
          !_categories.containsKey(personName[0].toUpperCase() + personName.substring(1))) {
        return true;
      }
    }
    
    return false;
  }

  String getSuggestedCategoryName(String description) {
    final descLower = description.toLowerCase();
    
    for (var personName in _personNames) {
      if (descLower.contains(personName)) {
        return personName[0].toUpperCase() + personName.substring(1);
      }
    }
    
    return 'New Category';
  }

  void addCategory(String category) {
    if (!_categories.containsKey(category)) {
      _categories[category] = [];
      _saveData();
      notifyListeners();
    }
  }

  void removeCategory(String category) {
    if (_categories.remove(category) != null) {
      _saveData();
      notifyListeners();
    }
  }

  void addKeywordToCategory(String category, String keyword) {
    if (_categories.containsKey(category)) {
      final normalizedKeyword = keyword.toLowerCase().trim();
      if (!_categories[category]!.contains(normalizedKeyword)) {
        _categories[category]!.add(normalizedKeyword);
        _saveData();
        notifyListeners();
      }
    }
  }

  void removeKeywordFromCategory(String category, String keyword) {
    if (_categories.containsKey(category)) {
      final normalizedKeyword = keyword.toLowerCase().trim();
      if (_categories[category]!.remove(normalizedKeyword)) {
        _saveData();
        notifyListeners();
      }
    }
  }

  Map<String, List<String>> get categories => _categories;
}
