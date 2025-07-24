import '../models/dropdown_option_model.dart';
import 'database_helper.dart';

class DropdownService {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  // Get all options for a specific category
  Future<List<DropdownOptionModel>> getOptions(String category, {bool activeOnly = true}) async {
    try {
      return await _dbHelper.getDropdownOptions(category, activeOnly: activeOnly);
    } catch (e) {
      throw Exception('Failed to get dropdown options: $e');
    }
  }

  // Get only values (strings) for dropdown widgets
  Future<List<String>> getValues(String category, {bool activeOnly = true}) async {
    try {
      return await _dbHelper.getDropdownValues(category, activeOnly: activeOnly);
    } catch (e) {
      throw Exception('Failed to get dropdown values: $e');
    }
  }

  // Add new option
  Future<bool> addOption(String category, String value, {String? description}) async {
    try {
      // Check if value already exists
      final exists = await _dbHelper.isValueExists(category, value);
      if (exists) {
        throw Exception('Value "$value" already exists in $category');
      }

      final option = DropdownOptionModel(
        category: category,
        value: value.trim(),
        description: description?.trim(),
        createdAt: DateTime.now(),
      );

      final id = await _dbHelper.insertDropdownOption(option);
      return id > 0;
    } catch (e) {
      throw Exception('Failed to add option: $e');
    }
  }

  // Update existing option
  Future<bool> updateOption(int id, String value, {String? description}) async {
    try {
      // Get current option to preserve category and other data
      final options = await _dbHelper.getDropdownOptions('', activeOnly: false);
      final currentOption = options.firstWhere((opt) => opt.id == id);
      
      // Check if new value already exists (excluding current option)
      final exists = await _dbHelper.isValueExists(currentOption.category, value, excludeId: id);
      if (exists) {
        throw Exception('Value "$value" already exists in ${currentOption.category}');
      }

      final updatedOption = currentOption.copyWith(
        value: value.trim(),
        description: description?.trim(),
        updatedAt: DateTime.now(),
      );

      final rowsAffected = await _dbHelper.updateDropdownOption(updatedOption);
      return rowsAffected > 0;
    } catch (e) {
      throw Exception('Failed to update option: $e');
    }
  }

  // Delete option
  Future<bool> deleteOption(int id) async {
    try {
      final rowsAffected = await _dbHelper.deleteDropdownOption(id);
      return rowsAffected > 0;
    } catch (e) {
      throw Exception('Failed to delete option: $e');
    }
  }

  // Toggle active/inactive status
  Future<bool> toggleOptionStatus(int id) async {
    try {
      final rowsAffected = await _dbHelper.toggleDropdownOptionStatus(id);
      return rowsAffected > 0;
    } catch (e) {
      throw Exception('Failed to toggle option status: $e');
    }
  }

  // Validate option data
  String? validateOption(String category, String value) {
    if (category.isEmpty) {
      return 'Category cannot be empty';
    }
    
    if (value.trim().isEmpty) {
      return 'Value cannot be empty';
    }
    
    if (value.trim().length < 2) {
      return 'Value must be at least 2 characters long';
    }
    
    if (value.trim().length > 100) {
      return 'Value cannot be longer than 100 characters';
    }
    
    if (!DropdownCategories.allCategories.contains(category)) {
      return 'Invalid category';
    }
    
    return null;
  }

  // Get statistics for a category
  Future<Map<String, int>> getCategoryStats(String category) async {
    try {
      final allOptions = await getOptions(category, activeOnly: false);
      final activeOptions = allOptions.where((opt) => opt.isActive).length;
      final inactiveOptions = allOptions.length - activeOptions;
      
      return {
        'total': allOptions.length,
        'active': activeOptions,
        'inactive': inactiveOptions,
      };
    } catch (e) {
      throw Exception('Failed to get category stats: $e');
    }
  }

  // Search options by value
  Future<List<DropdownOptionModel>> searchOptions(String category, String query, {bool activeOnly = true}) async {
    try {
      final allOptions = await getOptions(category, activeOnly: activeOnly);
      final searchQuery = query.toLowerCase().trim();
      
      if (searchQuery.isEmpty) {
        return allOptions;
      }
      
      return allOptions.where((option) {
        return option.value.toLowerCase().contains(searchQuery) ||
               (option.description?.toLowerCase().contains(searchQuery) ?? false);
      }).toList();
    } catch (e) {
      throw Exception('Failed to search options: $e');
    }
  }

  // Bulk operations
  Future<bool> addMultipleOptions(String category, List<String> values) async {
    try {
      int successCount = 0;
      
      for (String value in values) {
        try {
          final success = await addOption(category, value);
          if (success) successCount++;
        } catch (e) {
          // Continue with other values even if one fails
          continue;
        }
      }
      
      return successCount > 0;
    } catch (e) {
      throw Exception('Failed to add multiple options: $e');
    }
  }

  // Export options for backup
  Future<Map<String, List<Map<String, dynamic>>>> exportAllOptions() async {
    try {
      final Map<String, List<Map<String, dynamic>>> exportData = {};
      
      for (String category in DropdownCategories.allCategories) {
        final options = await getOptions(category, activeOnly: false);
        exportData[category] = options.map((opt) => opt.toMap()).toList();
      }
      
      return exportData;
    } catch (e) {
      throw Exception('Failed to export options: $e');
    }
  }
}