import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../../models/models.dart';
import '../../data/db_helper.dart';

class InventoryPage extends StatefulWidget {
  final bool canEdit;
  const InventoryPage({super.key, this.canEdit = false});

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  bool _menuTab = true;
  List<MenuItem> _menuItems = [];
  List<Ingredient> _ingredients = [];
  List<String> _lowStock = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final menu = await DBHelper.instance.getMenuItems();
    final ing = await DBHelper.instance.getIngredients();
    final low = await DBHelper.instance.getLowStockIngredientNames();
    if (!mounted) return;
    setState(() {
      _menuItems = menu;
      _ingredients = ing;
      _lowStock = low;
      _loading = false;
    });
  }

  Future<void> _editMenuItem(MenuItem? item) async {
    final result = await showDialog<MenuItem>(
      context: context,
      builder: (_) => _MenuItemDialog(item: item),
    );
    if (result == null) return;
    if (item == null) {
      await DBHelper.instance.addMenuItem(result);
    } else {
      await DBHelper.instance.updateMenuItem(result);
    }
    _load();
  }

  Future<void> _deleteMenuItem(MenuItem item) async {
    final ok = await _confirm(context, 'Delete "${item.name}"?');
    if (ok && item.id != null) {
      await DBHelper.instance.deleteMenuItem(item.id!);
      _load();
    }
  }

  Future<void> _editIngredient(Ingredient? ing) async {
    final result = await showDialog<Ingredient>(
      context: context,
      builder: (_) => _IngredientDialog(ingredient: ing),
    );
    if (result == null) return;
    if (ing == null) {
      await DBHelper.instance.addIngredient(result);
    } else {
      await DBHelper.instance.updateIngredient(result);
    }
    _load();
  }

  Future<void> _deleteIngredient(Ingredient ing) async {
    final ok = await _confirm(context, 'Delete "${ing.name}"?');
    if (ok && ing.id != null) {
      await DBHelper.instance.deleteIngredient(ing.id!);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Inventory', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 22)),
              const Spacer(),
              if (widget.canEdit)
                ElevatedButton.icon(
                  onPressed: () => _menuTab ? _editMenuItem(null) : _editIngredient(null),
                  icon: const Icon(Icons.add, size: 16),
                  label: Text(_menuTab ? 'Add Item' : 'Add Ingredient'),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (!widget.canEdit)
            _NoticeBanner(
              icon: Icons.visibility,
              color: AppColors.accentBlue,
              text: 'View Only — Contact the owner to make changes to inventory.',
            ),
          if (_lowStock.isNotEmpty) ...[
            const SizedBox(height: 8),
            _NoticeBanner(
              icon: Icons.warning_amber,
              color: AppColors.warning,
              text: 'Low Stock: ${_lowStock.join(', ')} — Inform the owner.',
            ),
          ],
          const SizedBox(height: 14),
          BistroCard(
            padding: const EdgeInsets.all(6),
            child: Row(
              children: [
                Expanded(
                  child: _TabButton(
                    label: 'Menu Items',
                    selected: _menuTab,
                    onTap: () => setState(() => _menuTab = true),
                  ),
                ),
                Expanded(
                  child: _TabButton(
                    label: 'Raw Ingredients',
                    selected: !_menuTab,
                    onTap: () => setState(() => _menuTab = false),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
                : (_menuTab
                    ? _MenuTable(
                        items: _menuItems,
                        canEdit: widget.canEdit,
                        onEdit: _editMenuItem,
                        onDelete: _deleteMenuItem,
                      )
                    : _IngredientTable(
                        ingredients: _ingredients,
                        canEdit: widget.canEdit,
                        onEdit: _editIngredient,
                        onDelete: _deleteIngredient,
                      )),
          ),
        ],
      ),
    );
  }
}

Future<bool> _confirm(BuildContext context, String message) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      backgroundColor: AppColors.bgCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Confirm'),
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Delete', style: TextStyle(color: AppColors.accentRed)),
        ),
      ],
    ),
  );
  return result ?? false;
}

class _NoticeBanner extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;
  const _NoticeBanner({required this.icon, required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: TextStyle(color: color, fontSize: 12))),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _TabButton({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.accent : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Text(label,
            style: TextStyle(
                color: selected ? Colors.white : AppColors.textSecondary,
                fontWeight: FontWeight.w600,
                fontSize: 13)),
      ),
    );
  }
}

class _MenuTable extends StatelessWidget {
  final List<MenuItem> items;
  final bool canEdit;
  final ValueChanged<MenuItem> onEdit;
  final ValueChanged<MenuItem> onDelete;
  const _MenuTable(
      {required this.items, required this.canEdit, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 6),
      itemBuilder: (_, i) {
        final item = items[i];
        return BistroCard(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    Text(item.category, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(peso(item.price),
                    style: const TextStyle(color: AppColors.accent2, fontWeight: FontWeight.w700, fontSize: 13)),
              ),
              Expanded(
                flex: 2,
                child: Text('${item.stock} ${item.unit}', style: const TextStyle(fontSize: 12)),
              ),
              Expanded(flex: 2, child: StatusPill(status: item.status)),
              if (canEdit)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                        onPressed: () => onEdit(item),
                        icon: const Icon(Icons.edit, size: 16, color: AppColors.textSecondary)),
                    IconButton(
                        onPressed: () => onDelete(item),
                        icon: const Icon(Icons.delete_outline, size: 16, color: AppColors.accentRed)),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }
}

class _IngredientTable extends StatelessWidget {
  final List<Ingredient> ingredients;
  final bool canEdit;
  final ValueChanged<Ingredient> onEdit;
  final ValueChanged<Ingredient> onDelete;
  const _IngredientTable(
      {required this.ingredients, required this.canEdit, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: ingredients.length,
      separatorBuilder: (_, __) => const SizedBox(height: 6),
      itemBuilder: (_, i) {
        final ing = ingredients[i];
        final pct = (ing.onHand / ((ing.reorderLevel * 2).clamp(1, double.infinity))).clamp(0.0, 1.0);
        return BistroCard(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(ing.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text('${ing.onHand} ${ing.unit}', style: const TextStyle(fontSize: 12)),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(peso(ing.unitCost), style: const TextStyle(color: AppColors.accent2, fontSize: 12)),
                  ),
                  Expanded(flex: 2, child: StatusPill(status: ing.status)),
                  if (canEdit)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                            onPressed: () => onEdit(ing),
                            icon: const Icon(Icons.edit, size: 16, color: AppColors.textSecondary)),
                        IconButton(
                            onPressed: () => onDelete(ing),
                            icon: const Icon(Icons.delete_outline, size: 16, color: AppColors.accentRed)),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: pct,
                  minHeight: 6,
                  backgroundColor: AppColors.border,
                  valueColor: AlwaysStoppedAnimation(
                    ing.status == 'Good' ? AppColors.accentGreen : (ing.status == 'Low' ? AppColors.warning : AppColors.accentRed),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Edit dialogs ─────────────────────────────────────────────────────────
class _MenuItemDialog extends StatefulWidget {
  final MenuItem? item;
  const _MenuItemDialog({this.item});

  @override
  State<_MenuItemDialog> createState() => _MenuItemDialogState();
}

class _MenuItemDialogState extends State<_MenuItemDialog> {
  late final TextEditingController _name;
  late final TextEditingController _price;
  late final TextEditingController _stock;
  late final TextEditingController _reorder;
  String _category = 'Lomi';
  bool _available = true;

  static const _categories = ['Lomi', 'Pancit', 'Drinks', 'Others'];

  @override
  void initState() {
    super.initState();
    final it = widget.item;
    _name = TextEditingController(text: it?.name ?? '');
    _price = TextEditingController(text: it?.price.toString() ?? '');
    _stock = TextEditingController(text: it?.stock.toString() ?? '');
    _reorder = TextEditingController(text: it?.reorderLevel.toString() ?? '10');
    _category = it?.category ?? 'Lomi';
    _available = it?.isAvailable ?? true;
  }

  void _save() {
    final name = _name.text.trim();
    final price = double.tryParse(_price.text.trim());
    final stock = int.tryParse(_stock.text.trim());
    final reorder = int.tryParse(_reorder.text.trim()) ?? 10;
    if (name.isEmpty || price == null || stock == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Please fill in all fields correctly.')));
      return;
    }
    Navigator.pop(
      context,
      MenuItem(
        id: widget.item?.id,
        name: name,
        category: _category,
        price: price,
        stock: stock,
        reorderLevel: reorder,
        isAvailable: _available,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.bgCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.item == null ? 'Add Menu Item' : 'Edit Menu Item',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              TextField(controller: _name, decoration: const InputDecoration(labelText: 'Name')),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _category,
                dropdownColor: AppColors.bgCard,
                decoration: const InputDecoration(labelText: 'Category'),
                items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (v) => setState(() => _category = v ?? _category),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _price,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Price (₱)'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _stock,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Stock'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _reorder,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Reorder Level'),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Available for sale', style: TextStyle(fontSize: 13)),
                value: _available,
                activeColor: AppColors.accent,
                onChanged: (v) => setState(() => _available = v),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                      child: OutlinedButton(
                          onPressed: () => Navigator.pop(context), child: const Text('Cancel'))),
                  const SizedBox(width: 10),
                  Expanded(child: GradientButton(text: 'Save', height: 46, onPressed: _save)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IngredientDialog extends StatefulWidget {
  final Ingredient? ingredient;
  const _IngredientDialog({this.ingredient});

  @override
  State<_IngredientDialog> createState() => _IngredientDialogState();
}

class _IngredientDialogState extends State<_IngredientDialog> {
  late final TextEditingController _name;
  late final TextEditingController _unit;
  late final TextEditingController _onHand;
  late final TextEditingController _reorder;
  late final TextEditingController _cost;

  @override
  void initState() {
    super.initState();
    final ing = widget.ingredient;
    _name = TextEditingController(text: ing?.name ?? '');
    _unit = TextEditingController(text: ing?.unit ?? 'kg');
    _onHand = TextEditingController(text: ing?.onHand.toString() ?? '');
    _reorder = TextEditingController(text: ing?.reorderLevel.toString() ?? '');
    _cost = TextEditingController(text: ing?.unitCost.toString() ?? '');
  }

  void _save() {
    final name = _name.text.trim();
    final unit = _unit.text.trim();
    final onHand = double.tryParse(_onHand.text.trim());
    final reorder = double.tryParse(_reorder.text.trim());
    final cost = double.tryParse(_cost.text.trim());
    if (name.isEmpty || unit.isEmpty || onHand == null || reorder == null || cost == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Please fill in all fields correctly.')));
      return;
    }
    Navigator.pop(
      context,
      Ingredient(
        id: widget.ingredient?.id,
        name: name,
        unit: unit,
        onHand: onHand,
        reorderLevel: reorder,
        unitCost: cost,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.bgCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.ingredient == null ? 'Add Ingredient' : 'Edit Ingredient',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              TextField(controller: _name, decoration: const InputDecoration(labelText: 'Name')),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                      child:
                          TextField(controller: _unit, decoration: const InputDecoration(labelText: 'Unit (kg/pcs)'))),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _onHand,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'On Hand'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _reorder,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Reorder Level'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _cost,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Unit Cost (₱)'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                      child: OutlinedButton(
                          onPressed: () => Navigator.pop(context), child: const Text('Cancel'))),
                  const SizedBox(width: 10),
                  Expanded(child: GradientButton(text: 'Save', height: 46, onPressed: _save)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
