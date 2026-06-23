import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../data/database.dart';
import 'database_provider.dart';

final categoryStreamProvider = StreamProvider<List<Category>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.select(db.categories).watch();
});

class CategoryNotifier extends FamilyNotifier<void, AppDatabase> {
  @override
  void build(AppDatabase arg) {}

  Future<void> addCategory({
    required String name,
    required String icon,
    required String colorHex,
    required String type, // income | expense | both
  }) async {
    final db = arg;
    await db
        .into(db.categories)
        .insert(
          CategoriesCompanion.insert(
            id: const Uuid().v4(),
            name: name,
            icon: icon,
            color: colorHex,
            type: type,
            isDefault: const Value(false),
          ),
        );
  }

  Future<void> updateCategory({
    required String id,
    required String name,
    required String icon,
    required String colorHex,
    required String type,
  }) async {
    final db = arg;
    await (db.update(db.categories)..where((t) => t.id.equals(id))).write(
      CategoriesCompanion(
        name: Value(name),
        icon: Value(icon),
        color: Value(colorHex),
        type: Value(type),
      ),
    );
  }

  Future<void> deleteCategory(String id) async {
    final db = arg;
    await (db.delete(db.categories)..where((t) => t.id.equals(id))).go();
  }
}

final categoryNotifierProvider =
    NotifierProvider.family<CategoryNotifier, void, AppDatabase>(() {
      return CategoryNotifier();
    });
