import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/cart_item_model.dart';

class CartService {
  static Database? _database;
  static const String _tableName = 'cart_items';

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'cart.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _createTable,
    );
  }

  Future<void> _createTable(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_tableName (
        id TEXT PRIMARY KEY,
        jenis_sayur TEXT NOT NULL,
        harga REAL NOT NULL,
        jumlah REAL NOT NULL,
        satuan TEXT NOT NULL,
        total REAL NOT NULL,
        added_at INTEGER NOT NULL
      )
    ''');
  }

  // Tambah item ke keranjang
  Future<void> addToCart(CartItem item) async {
    final db = await database;
    
    // Cek apakah item sudah ada
    final existing = await db.query(
      _tableName,
      where: 'jenis_sayur = ?',
      whereArgs: [item.jenisSayur],
    );

    if (existing.isNotEmpty) {
      // Update jumlah jika item sudah ada
      final existingItem = CartItem.fromMap(existing.first);
      final newJumlah = existingItem.jumlah + item.jumlah;
      final newTotal = newJumlah * item.harga;
      
      await db.update(
        _tableName,
        {
          'jumlah': newJumlah,
          'total': newTotal,
          'added_at': DateTime.now().millisecondsSinceEpoch,
        },
        where: 'id = ?',
        whereArgs: [existingItem.id],
      );
    } else {
      // Tambah item baru
      await db.insert(_tableName, item.toMap());
    }
  }

  // Ambil semua item di keranjang
  Future<List<CartItem>> getCartItems() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      orderBy: 'added_at DESC',
    );

    return List.generate(maps.length, (i) {
      return CartItem.fromMap(maps[i]);
    });
  }

  // Update item di keranjang
  Future<void> updateCartItem(CartItem item) async {
    final db = await database;
    await db.update(
      _tableName,
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  // Hapus item dari keranjang
  Future<void> removeFromCart(String itemId) async {
    final db = await database;
    await db.delete(
      _tableName,
      where: 'id = ?',
      whereArgs: [itemId],
    );
  }

  // Kosongkan keranjang
  Future<void> clearCart() async {
    final db = await database;
    await db.delete(_tableName);
  }

  // Hitung total keranjang
  Future<double> getCartTotal() async {
    final items = await getCartItems();
    return items.fold<double>(0.0, (sum, item) => sum + item.total);
  }

  // Hitung jumlah item di keranjang
  Future<int> getCartItemCount() async {
    final items = await getCartItems();
    return items.length;
  }
}