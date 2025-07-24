import 'package:flutter/material.dart';
import '../models/dropdown_option_model.dart';
import '../services/dropdown_service.dart';

class DropdownProvider with ChangeNotifier {
  final DropdownService _dropdownService = DropdownService();
  
  // State variables
  Map<String, List<DropdownOptionModel>> _options = {};
  Map<String, List<String>> _values = {};
  Map<String, bool> _loading = {};
  Map<String, String?> _errors = {};
  Map<String, Map<String, int>> _stats = {};
  
  // Getters
  List<DropdownOptionModel> getOptions(String category) => _options[category] ?? [];
  List<String> getValues(String category) => _values[category] ?? [];
  bool isLoading(String category) => _loading[category] ?? false;
  String? getError(String category) => _errors[category];
  Map<String, int> getStats(String category) => _stats[category] ?? {};
  
  // Load options for a specific category
  Future<void> loadOptions(String category, {bool activeOnly = true, bool forceRefresh = false}) async {
    if (_loading[category] == true && !forceRefresh) return;
    
    _loading[category] = true;
    _errors[category] = null;
    notifyListeners();
    
    try {
      final options = await _dropdownService.getOptions(category, activeOnly: activeOnly);
      final values = await _dropdownService.getValues(category, activeOnly: activeOnly);
      
      _options[category] = options;
      _values[category] = values;
      _errors[category] = null;
    } catch (e) {
      _errors[category] = e.toString();
      _options[category] = [];
      _values[category] = [];
    } finally {
      _loading[category] = false;
      notifyListeners();
    }
  }
  
  // Load all categories
  Future<void> loadAllCategories({bool activeOnly = true}) async {
    for (String category in DropdownCategories.allCategories) {
      await loadOptions(category, activeOnly: activeOnly);
    }
  }
  
  // Add new option
  Future<bool> addOption(String category, String value, {String? description}) async {
    try {
      _errors[category] = null;
      notifyListeners();
      
      final success = await _dropdownService.addOption(category, value, description: description);
      
      if (success) {
        await loadOptions(category, forceRefresh: true);
        await loadStats(category);
      }
      
      return success;
    } catch (e) {
      _errors[category] = e.toString();
      notifyListeners();
      return false;
    }
  }
  
  // Update existing option
  Future<bool> updateOption(int id, String value, {String? description}) async {
    try {
      // Find which category this option belongs to
      String? targetCategory;
      for (String category in _options.keys) {
        if (_options[category]!.any((opt) => opt.id == id)) {
          targetCategory = category;
          break;
        }
      }
      
      if (targetCategory == null) {
        throw Exception('Option not found');
      }
      
      _errors[targetCategory] = null;
      notifyListeners();
      
      final success = await _dropdownService.updateOption(id, value, description: description);
      
      if (success) {
        await loadOptions(targetCategory, forceRefresh: true);
        await loadStats(targetCategory);
      }
      
      return success;
    } catch (e) {
      // Set error for all categories since we don't know which one failed
      for (String category in DropdownCategories.allCategories) {
        _errors[category] = e.toString();
      }
      notifyListeners();
      return false;
    }
  }
  
  // Delete option
  Future<bool> deleteOption(int id) async {
    try {
      // Find which category this option belongs to
      String? targetCategory;
      for (String category in _options.keys) {
        if (_options[category]!.any((opt) => opt.id == id)) {
          targetCategory = category;
          break;
        }
      }
      
      if (targetCategory == null) {
        throw Exception('Option not found');
      }
      
      _errors[targetCategory] = null;
      notifyListeners();
      
      final success = await _dropdownService.deleteOption(id);
      
      if (success) {
        await loadOptions(targetCategory, forceRefresh: true);
        await loadStats(targetCategory);
      }
      
      return success;
    } catch (e) {
      // Set error for all categories since we don't know which one failed
      for (String category in DropdownCategories.allCategories) {
        _errors[category] = e.toString();
      }
      notifyListeners();
      return false;
    }
  }
  
  // Toggle option status
  Future<bool> toggleOptionStatus(int id) async {
    try {
      // Find which category this option belongs to
      String? targetCategory;
      for (String category in _options.keys) {
        if (_options[category]!.any((opt) => opt.id == id)) {
          targetCategory = category;
          break;
        }
      }
      
      if (targetCategory == null) {
        throw Exception('Option not found');
      }
      
      _errors[targetCategory] = null;
      notifyListeners();
      
      final success = await _dropdownService.toggleOptionStatus(id);
      
      if (success) {
        await loadOptions(targetCategory, activeOnly: false, forceRefresh: true);
        await loadStats(targetCategory);
      }
      
      return success;
    } catch (e) {
      // Set error for all categories since we don't know which one failed
      for (String category in DropdownCategories.allCategories) {
        _errors[category] = e.toString();
      }
      notifyListeners();
      return false;
    }
  }
  
  // Load statistics
  Future<void> loadStats(String category) async {
    try {
      final stats = await _dropdownService.getCategoryStats(category);
      _stats[category] = stats;
      notifyListeners();
    } catch (e) {
      _errors[category] = e.toString();
      notifyListeners();
    }
  }
  
  // Load all statistics
  Future<void> loadAllStats() async {
    for (String category in DropdownCategories.allCategories) {
      await loadStats(category);
    }
  }
  
  // Search options
  Future<List<DropdownOptionModel>> searchOptions(String category, String query, {bool activeOnly = true}) async {
    try {
      return await _dropdownService.searchOptions(category, query, activeOnly: activeOnly);
    } catch (e) {
      _errors[category] = e.toString();
      notifyListeners();
      return [];
    }
  }
  
  // Validate option
  String? validateOption(String category, String value) {
    return _dropdownService.validateOption(category, value);
  }
  
  // Add multiple options
  Future<bool> addMultipleOptions(String category, List<String> values) async {
    try {
      _errors[category] = null;
      notifyListeners();
      
      final success = await _dropdownService.addMultipleOptions(category, values);
      
      if (success) {
        await loadOptions(category, forceRefresh: true);
        await loadStats(category);
      }
      
      return success;
    } catch (e) {
      _errors[category] = e.toString();
      notifyListeners();
      return false;
    }
  }
  
  // Clear error for a category
  void clearError(String category) {
    _errors[category] = null;
    notifyListeners();
  }
  
  // Clear all errors
  void clearAllErrors() {
    _errors.clear();
    notifyListeners();
  }
  
  // Refresh all data
  Future<void> refreshAll() async {
    await loadAllCategories(activeOnly: false);
    await loadAllStats();
  }
  
  // Get option by id
  DropdownOptionModel? getOptionById(int id) {
    for (String category in _options.keys) {
      for (DropdownOptionModel option in _options[category]!) {
        if (option.id == id) {
          return option;
        }
      }
    }
    return null;
  }
  
  // Check if value exists in category
  bool isValueExists(String category, String value, {int? excludeId}) {
    final options = _options[category] ?? [];
    return options.any((opt) => 
        opt.value.toLowerCase() == value.toLowerCase() && 
        (excludeId == null || opt.id != excludeId)
    );
  }
  
  // Get total count for all categories
  int get totalOptionsCount {
    int total = 0;
    for (String category in _stats.keys) {
      total += _stats[category]?['total'] ?? 0;
    }
    return total;
  }
  
  // Get active count for all categories
  int get totalActiveCount {
    int total = 0;
    for (String category in _stats.keys) {
      total += _stats[category]?['active'] ?? 0;
    }
    return total;
  }
}