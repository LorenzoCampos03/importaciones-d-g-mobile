import 'package:flutter/material.dart';
import '../../models/product.dart';
import '../../models/catalog.dart';
import '../../service/product_service.dart';
import '../../service/catalog_service.dart';
import '../../widgets/role_guard.dart';
import '../../widgets/common_widgets.dart';
import '../../config/theme_config.dart';

class ProductFormPage extends StatefulWidget {
  final Product? product;

  const ProductFormPage({super.key, this.product});

  @override
  State<ProductFormPage> createState() => _ProductFormPageState();
}

class _ProductFormPageState extends State<ProductFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _unitPriceController = TextEditingController();
  final _stockController = TextEditingController();

  List<CatalogOption> _categories = [];
  List<CatalogOption> _brands = [];
  List<CatalogOption> _suppliers = [];

  int? _selectedCategoryId;
  int? _selectedBrandId;
  int? _selectedSupplierId;
  String _selectedStatus = 'A';

  bool _isLoading = false;
  bool _isLoadingData = true;

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      // Verificar si el producto está inactivo
      if (widget.product!.status == 'I') {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          SnackBarHelper.showWarning(
            context,
            'No se pueden editar productos inactivos',
          );
          Navigator.pop(context);
        });
        return;
      }
      _loadProductData();
    }
    _loadCatalogData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _unitPriceController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  void _loadProductData() {
    final product = widget.product!;
    _nameController.text = product.name;
    _descriptionController.text = product.description;
    _unitPriceController.text = product.unitPrice.toString();
    _stockController.text = product.stock.toString();
    _selectedCategoryId = product.categoryId;
    _selectedBrandId = product.brandId;
    _selectedSupplierId = product.supplierId;
    _selectedStatus = product.status;
  }

  Future<void> _loadCatalogData() async {
    setState(() => _isLoadingData = true);

    try {
      final results = await Future.wait([
        CatalogService.getCategories(),
        CatalogService.getBrands(),
        CatalogService.getSuppliers(),
      ]);

      setState(() {
        _categories = results[0];
        _brands = results[1];
        _suppliers = results[2];
      });
    } catch (e) {
      if (mounted) {
        SnackBarHelper.showError(context, 'Error al cargar datos: $e');
      }
    } finally {
      setState(() => _isLoadingData = false);
    }
  }

  Future<void> _saveProduct() async {
    // Validar el formulario primero
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validar que se hayan seleccionado los dropdowns requeridos
    if (_selectedCategoryId == null ||
        _selectedBrandId == null ||
        _selectedSupplierId == null) {
      SnackBarHelper.showWarning(
        context,
        'Por favor selecciona categoría, marca y proveedor',
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final categoryName =
          _categories.firstWhere((c) => c.id == _selectedCategoryId).name;
      final brandName =
          _brands.firstWhere((b) => b.id == _selectedBrandId).name;
      final supplierName =
          _suppliers.firstWhere((s) => s.id == _selectedSupplierId).name;

      final product = Product(
        productId: widget.product?.productId,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        unitPrice: double.parse(_unitPriceController.text),
        stock: int.parse(_stockController.text),
        status: _selectedStatus,
        categoryName: categoryName,
        brandName: brandName,
        supplierName: supplierName,
        categoryId: _selectedCategoryId,
        brandId: _selectedBrandId,
        supplierId: _selectedSupplierId,
      );

      if (widget.product == null) {
        await ProductService.createProduct(product);
        if (mounted) {
          SnackBarHelper.showSuccess(context, 'Producto creado exitosamente');
        }
      } else {
        await ProductService.updateProduct(product);
        if (mounted) {
          SnackBarHelper.showSuccess(
            context,
            'Producto actualizado exitosamente',
          );
        }
      }

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        SnackBarHelper.showError(
          context,
          'Error al ${widget.product == null ? 'crear' : 'actualizar'} producto: $e',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return RoleGuard(
      allowedRoles: ['Administrador'],
      child: Scaffold(
        backgroundColor: ThemeConfig.backgroundColor,
        appBar: ThemeConfig.getCustomAppBar(
          title: widget.product == null ? 'Nuevo Producto' : 'Editar Producto',
        ),
        body:
            _isLoadingData
                ? const LoadingState(
                  message: 'Cargando datos del formulario...',
                )
                : SingleChildScrollView(
                  padding: const EdgeInsets.all(ThemeConfig.paddingMedium),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Información básica
                        InfoCard(
                          title: 'Información del Producto',
                          withGradient: true,
                          items: [],
                        ),

                        const SizedBox(height: ThemeConfig.paddingMedium),

                        // Campos básicos
                        _buildBasicFields(),

                        const SizedBox(height: ThemeConfig.paddingMedium),

                        // Campos de catálogo
                        _buildCatalogFields(),

                        const SizedBox(height: ThemeConfig.paddingMedium),

                        // Campos de precio y stock
                        _buildPriceAndStockFields(),

                        const SizedBox(height: ThemeConfig.paddingMedium),

                        // Estado
                        _buildStatusField(),

                        const SizedBox(height: ThemeConfig.paddingLarge),

                        // Botones de acción
                        _buildActionButtons(),
                      ],
                    ),
                  ),
                ),
      ),
    );
  }

  Widget _buildBasicFields() {
    return Container(
      decoration: ThemeConfig.getCardDecoration(),
      padding: const EdgeInsets.all(ThemeConfig.paddingLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Información Básica', style: ThemeConfig.headingSmall),

          const SizedBox(height: ThemeConfig.paddingMedium),

          // Nombre del producto
          TextFormField(
            controller: _nameController,
            decoration: ThemeConfig.getInputDecoration(
              labelText: 'Nombre del Producto *',
              prefixIcon: Icons.inventory_2,
              hintText: 'Ej: Laptop Dell Inspiron',
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Por favor ingresa el nombre del producto';
              }
              if (value.trim().length < 3) {
                return 'El nombre debe tener al menos 3 caracteres';
              }
              if (value.trim().length > 100) {
                return 'El nombre no puede exceder 100 caracteres';
              }
              return null;
            },
            textInputAction: TextInputAction.next,
            maxLength: 100,
          ),

          const SizedBox(height: ThemeConfig.paddingMedium),

          // Descripción
          TextFormField(
            controller: _descriptionController,
            decoration: ThemeConfig.getInputDecoration(
              labelText: 'Descripción *',
              prefixIcon: Icons.description,
              hintText: 'Describe las características del producto...',
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Por favor ingresa la descripción';
              }
              if (value.trim().length < 10) {
                return 'La descripción debe tener al menos 10 caracteres';
              }
              if (value.trim().length > 500) {
                return 'La descripción no puede exceder 500 caracteres';
              }
              return null;
            },
            textInputAction: TextInputAction.next,
            maxLines: 3,
            maxLength: 500,
          ),

          const SizedBox(height: ThemeConfig.paddingSmall),

          Text('* Campos requeridos', style: ThemeConfig.caption),
        ],
      ),
    );
  }

  Widget _buildCatalogFields() {
    return Container(
      decoration: ThemeConfig.getCardDecoration(),
      padding: const EdgeInsets.all(ThemeConfig.paddingLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Clasificación del Producto', style: ThemeConfig.headingSmall),

          const SizedBox(height: ThemeConfig.paddingMedium),

          // Categoría
          DropdownButtonFormField<int>(
            value: _selectedCategoryId,
            decoration: ThemeConfig.getInputDecoration(
              labelText: 'Categoría *',
              prefixIcon: Icons.category,
            ),
            items:
                _categories.map((item) {
                  return DropdownMenuItem<int>(
                    value: item.id,
                    child: Text(item.name),
                  );
                }).toList(),
            onChanged: (value) {
              setState(() => _selectedCategoryId = value);
            },
            validator: (value) {
              if (value == null) {
                return 'Por favor selecciona una categoría';
              }
              return null;
            },
          ),

          const SizedBox(height: ThemeConfig.paddingMedium),

          // Marca
          DropdownButtonFormField<int>(
            value: _selectedBrandId,
            decoration: ThemeConfig.getInputDecoration(
              labelText: 'Marca *',
              prefixIcon: Icons.branding_watermark,
            ),
            items:
                _brands.map((item) {
                  return DropdownMenuItem<int>(
                    value: item.id,
                    child: Text(item.name),
                  );
                }).toList(),
            onChanged: (value) {
              setState(() => _selectedBrandId = value);
            },
            validator: (value) {
              if (value == null) {
                return 'Por favor selecciona una marca';
              }
              return null;
            },
          ),

          const SizedBox(height: ThemeConfig.paddingMedium),

          // Proveedor
          DropdownButtonFormField<int>(
            value: _selectedSupplierId,
            decoration: ThemeConfig.getInputDecoration(
              labelText: 'Proveedor *',
              prefixIcon: Icons.business,
            ),
            items:
                _suppliers.map((item) {
                  return DropdownMenuItem<int>(
                    value: item.id,
                    child: Text(item.name),
                  );
                }).toList(),
            onChanged: (value) {
              setState(() => _selectedSupplierId = value);
            },
            validator: (value) {
              if (value == null) {
                return 'Por favor selecciona un proveedor';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPriceAndStockFields() {
    return Container(
      decoration: ThemeConfig.getCardDecoration(),
      padding: const EdgeInsets.all(ThemeConfig.paddingLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Precio y Stock', style: ThemeConfig.headingSmall),

          const SizedBox(height: ThemeConfig.paddingMedium),

          Row(
            children: [
              // Precio unitario
              Expanded(
                child: TextFormField(
                  controller: _unitPriceController,
                  decoration: ThemeConfig.getInputDecoration(
                    labelText: 'Precio Unitario *',
                    prefixIcon: Icons.attach_money,
                    hintText: '0.00',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Ingresa el precio';
                    }
                    final price = double.tryParse(value);
                    if (price == null) {
                      return 'Precio inválido';
                    }
                    if (price <= 0) {
                      return 'Debe ser mayor a 0';
                    }
                    if (price > 999999.99) {
                      return 'Precio muy alto';
                    }
                    return null;
                  },
                  textInputAction: TextInputAction.next,
                ),
              ),

              const SizedBox(width: ThemeConfig.paddingMedium),

              // Stock
              Expanded(
                child: TextFormField(
                  controller: _stockController,
                  decoration: ThemeConfig.getInputDecoration(
                    labelText: 'Stock *',
                    prefixIcon: Icons.inventory,
                    hintText: '0',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Ingresa el stock';
                    }
                    final stock = int.tryParse(value);
                    if (stock == null) {
                      return 'Stock inválido';
                    }
                    if (stock < 0) {
                      return 'No puede ser negativo';
                    }
                    if (stock > 999999) {
                      return 'Stock muy alto';
                    }
                    return null;
                  },
                  textInputAction: TextInputAction.done,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusField() {
    return Container(
      decoration: ThemeConfig.getCardDecoration(),
      padding: const EdgeInsets.all(ThemeConfig.paddingLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Estado del Producto', style: ThemeConfig.headingSmall),

          const SizedBox(height: ThemeConfig.paddingMedium),

          DropdownButtonFormField<String>(
            value: _selectedStatus,
            decoration: ThemeConfig.getInputDecoration(
              labelText: 'Estado',
              prefixIcon: Icons.toggle_on,
            ),
            items: const [
              DropdownMenuItem(value: 'A', child: Text('Activo')),
              DropdownMenuItem(value: 'I', child: Text('Inactivo')),
            ],
            onChanged: (value) {
              setState(() => _selectedStatus = value!);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      width: double.infinity,
      decoration: ThemeConfig.getCardDecoration(),
      padding: const EdgeInsets.all(ThemeConfig.paddingLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Acciones', style: ThemeConfig.headingSmall),

          const SizedBox(height: ThemeConfig.paddingMedium),

          Row(
            children: [
              Expanded(
                child: ActionButton(
                  text: 'Cancelar',
                  icon: Icons.cancel,
                  type: ActionButtonType.secondary,
                  onPressed: _isLoading ? () {} : () => Navigator.pop(context),
                ),
              ),

              const SizedBox(width: ThemeConfig.paddingMedium),

              Expanded(
                child: ActionButton(
                  text:
                      widget.product == null ? 'Crear Producto' : 'Actualizar',
                  icon: widget.product == null ? Icons.save : Icons.update,
                  onPressed: _saveProduct,
                  isLoading: _isLoading,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
