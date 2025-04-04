import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../model/appstate.dart';
import '../../model/category.dart';
import '../../utils/utils.dart';
import '../widgets/section.dart';
import 'input.dart';
import 'settings.dart';

class CategoryView extends StatefulWidget {
  const CategoryView({super.key});

  @override
  State<CategoryView> createState() => _CategoryViewState();
}

class _CategoryViewState extends State<CategoryView> {
  var isHover = false;

  @override
  Widget build(BuildContext context) {
    var state = context.watch<AppState>();
    var textStyle = Theme.of(context).textTheme.headlineSmall;

    // Categories sorted by name
    var categories = state.categories;
    categories.sort((x, y) => x.name.compareTo(y.name));

    return Section(title: 'Categories',
      onBack: () => { state.setCurrentView(const SettingsView()) },

      // Categories sorted by name
      child: ListView.builder(
        itemCount: categories.length,
        itemBuilder: (_, index) {
          var category = categories[index];
          return ListTile(
            leading: Icon(size: 30, Icons.category),
            title: Text(category.name, style: textStyle),
            onTap: () => showDialog<String>(context: context,
              builder: (dialogContext) => InputView(
                title: 'Edit Category',
                inputLabel: 'Category Name',
                buttonName: 'Save',
                onSubmit: (val) {
                  updateCategory(dialogContext, state,
                    category.copyWith(name: val.trim()));
                },
              ),
            ),
            trailing: IconButton(
              icon: Icon(Icons.delete, color: Colors.red),
              onPressed: () {
                state.removeCategory(category.name);
              },
            ),
          );
        },
      ),
      trailing: Padding(
        padding: const EdgeInsets.all(10),
        child: TextButton(
          child: const Text('Add Category', style: TextStyle(fontSize: 18)),
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.all(Colors.green),
            foregroundColor: WidgetStateProperty.all(Colors.white),
          ),
          onPressed: () => showDialog<String>(context: context,
            builder: (dialogContext) => InputView(
              title: 'Create a new category',
              inputLabel: 'Category Name',
              buttonName: 'Save',
              onSubmit: (val) {
                addCategory(dialogContext, state, val.trim());
              },
            ),
          ),
        ),
      ),
    );
  }
}

// Example of a custom animated delete button
// --------------------------------------------------------------------------
// AnimatedContainer(
//   duration: const Duration(milliseconds: 200),
//   decoration: BoxDecoration(
//     color: Colors.red,
//     borderRadius: BorderRadius.circular(10),
//     border: Border.all(color: isHover ? Colors.white : Colors.red, width: 2),
//   ),
//   child: InkWell(
//     child: Icon(
//       Icons.close,
//       color: Colors.white,
//       size: isHover ? 26 : 20,
//     ),
//     onHover: (val) {
//       setState(() { isHover = val; });
//     },
//     onTap: () {
//       // Don't allow deleteing categories if there are associated points
//       state.removeCategory(widget.category.name);
//     },
//   ),
// ),

// Add the new category or show a snackbar if it already exists
void addCategory(BuildContext context, AppState state, String name) {
  if (utils.notEmptyAndNoSymbols(context, state, name)) {
    if (!state.addCategory(name)) {
      utils.showSnackBarFailure(context, 'Category "$name" already exists!');
    } else {
      Navigator.pop(context);
      utils.showSnackBarSuccess(context, 'Category "$name" created successfully!');
    }
  }
}

// Add the new user or show a snackbar if it already exists
void updateCategory(BuildContext context, AppState state, Category category) {
  if (utils.notEmptyAndNoSymbols(context, state, category.name)) {
    if (!state.updateCategory(category)) {
      utils.showSnackBarFailure(context, 'Category "${category.name}" already exists!');
    } else {
      Navigator.pop(context);
      utils.showSnackBarSuccess(context, 'Category "${category.name}" updated successfully!');
    }
  }
}
